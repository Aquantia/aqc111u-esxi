
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 25)
#include <linux/usb/usbnet.h>
#else
#include <../drivers/usb/net/usbnet.h>
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 20, 0)
#include <linux/linkmode.h>
#endif

#if LINUX_VERSION_CODE <= KERNEL_VERSION(2, 6, 10)
typedef u32 pm_message_t;
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 12, 0)
#define usbnet_get_stats64 NULL
#endif

#ifndef RHEL_RELEASE_VERSION
#define RHEL_RELEASE_VERSION(a,b) (((a) << 8) + (b))
#endif

#ifndef RHEL_RELEASE_CODE
#define RHEL_RELEASE_CODE 0
#endif


#if LINUX_VERSION_CODE < KERNEL_VERSION(3, 8, 0)
int usbnet_read_cmd(struct usbnet *dev, u8 cmd, u8 reqtype, u16 value, u16 index,
		    void *data, u16 size)
{
	return usb_control_msg(dev->udev, usb_rcvctrlpipe(dev->udev, 0),
			       cmd, reqtype, value, index, data, size,
			       USB_CTRL_GET_TIMEOUT);
}

int usbnet_read_cmd_nopm(struct usbnet *dev, u8 cmd, u8 reqtype, u16 value,
			 u16 index, void *data, u16 size)
{
	 return usbnet_read_cmd(dev, cmd, reqtype, value,
				index, data, size);
}
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 2, 0)
#define SPEED_5000 5000
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(3, 16, 0)
#define usbnet_set_skb_tx_stats(skb, packets, bytes_delta)
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(3, 14, 0) && !(RHEL_RELEASE_CODE)
static inline void ether_addr_copy(u8 *dst, const u8 *src)
{
	u16 *a = (u16 *)dst;
	const u16 *b = (const u16 *)src;

	a[0] = b[0];
	a[1] = b[1];
	a[2] = b[2];
}
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 20, 0) && \
    LINUX_VERSION_CODE >= KERNEL_VERSION(4, 6, 0)
static inline void linkmode_copy(unsigned long *dst, const unsigned long *src)
{
	bitmap_copy(dst, src, __ETHTOOL_LINK_MODE_MASK_NBITS);
}
#endif

#ifdef __VMKLNX__

#ifndef __packed
#define __packed __attribute__((packed))
#endif /*__packed*/

#define netdev_dbg(netdev, ...) printk(KERN_DEBUG __VA_ARGS__)
#define netdev_warn(netdev, ...) printk(KERN_WARNING __VA_ARGS__)
#define netdev_err(netdev, ...) printk(KERN_ERR __VA_ARGS__)
#define netdev_info(netdev, ...) printk(KERN_INFO __VA_ARGS__)

static void *kmemdup(const void *src, size_t len, gfp_t gfp)
{
	void *p;

	p = kzalloc(len, gfp);
	if (p)
		memcpy(p, src, len);
	return p;
}

static void usbnet_async_cmd_cb(struct urb *urb)
{
	struct usb_ctrlrequest *req = (struct usb_ctrlrequest *)urb->context;
	int status = urb->status;

	if (status < 0)
		dev_dbg(&urb->dev->dev, "%s failed with %d",
			__func__, status);

	kfree(req);
	kfree(urb->transfer_buffer);
	usb_put_urb(urb);
}

static int usbnet_write_cmd_async(struct usbnet *dev, u8 cmd, u8 reqtype,
			   u16 value, u16 index, const void *data, u16 size)
{
	struct usb_ctrlrequest *req = NULL;
	struct urb *urb;
	int err = -ENOMEM;
	void *buf = NULL;

	netdev_dbg(dev->net, "usbnet_write_cmd_async cmd=0x%02x reqtype=%02x"
		   " value=0x%04x index=0x%04x size=%d\n",
		   cmd, reqtype, value, index, size);

	urb = usb_alloc_urb(0, GFP_ATOMIC);
	if (!urb)
		goto fail;

	if (data) {
		buf = kmemdup(data, size, GFP_ATOMIC);
		if (!buf) {
			netdev_err(dev->net, "Error allocating buffer"
				   " in %s!\n", __func__);
			goto fail_free_urb;
		}
	}

	req = kmalloc(sizeof(struct usb_ctrlrequest), GFP_ATOMIC);
	if (!req)
		goto fail_free_buf;

	req->bRequestType = reqtype;
	req->bRequest = cmd;
	req->wValue = cpu_to_le16(value);
	req->wIndex = cpu_to_le16(index);
	req->wLength = cpu_to_le16(size);

	usb_fill_control_urb(urb, dev->udev,
			     usb_sndctrlpipe(dev->udev, 0),
			     (void *)req, buf, size,
			     usbnet_async_cmd_cb, req);

	err = usb_submit_urb(urb, GFP_ATOMIC);
	if (err < 0) {
		netdev_err(dev->net, "Error submitting the control"
			   " message: status=%d\n", err);
		goto fail_free_req;
	}
	return 0;

fail_free_req:
	kfree(req);
fail_free_buf:
	kfree(buf);
fail_free_urb:
	usb_free_urb(urb);
fail:
	return err;
}

static inline void ethtool_cmd_speed_set(struct ethtool_cmd *ep,
					 __u32 speed)
{
	ep->speed = (__u16)(speed & 0xFFFF);
}

static inline __u32 ethtool_cmd_speed(const struct ethtool_cmd *ep)
{
	return ep->speed;
}

static void eth_commit_mac_addr_change(struct net_device *dev, void *p)
{
	struct sockaddr *addr = p;

	memcpy(dev->dev_addr, addr->sa_data, ETH_ALEN);
}

static int eth_mac_addr(struct net_device *dev, void *p)
{
	eth_commit_mac_addr_change(dev, p);
	return 0;
}

#define netdev_mc_count(dev) dev->mc_count

#define netdev_for_each_mc_addr(ha, dev) \
	for (ha = dev->mc_list; ha; ha = ha->next)

#define netdev_mc_empty(dev) (dev->mc_count == 0)

#define NETIF_F_RXCSUM NETIF_F_HW_CSUM
#define NETIF_F_HW_VLAN_CTAG_FILTER NETIF_F_HW_VLAN_FILTER
#define NETIF_F_HW_VLAN_CTAG_RX NETIF_F_HW_VLAN_RX
#define NETIF_F_HW_VLAN_CTAG_TX NETIF_F_HW_VLAN_TX

#define skb_tail_pointer(skb) skb->tail

#define skb_set_tail_pointer(skb, offset) \
	do { \
		skb->tail = skb->data + offset; \
	} while (0)

#define __vlan_hwaccel_put_tag(skb, proto, tag) \
	__vlan_hwaccel_put_tag(skb, tag)

#define USB_DEVICE_INTERFACE_CLASS(vend, prod, cl) \
	.match_flags = USB_DEVICE_ID_MATCH_DEVICE | \
		       USB_DEVICE_ID_MATCH_INT_CLASS, \
	.idVendor = (vend), \
	.idProduct = (prod), \
	.bInterfaceClass = (cl)

#endif /*__VMKLNX__*/

