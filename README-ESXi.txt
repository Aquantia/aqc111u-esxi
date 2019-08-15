Aquantia's AQtion USB(AQC111/2U based devices) VmWare ESXi driver
===============================================

This is a VmWare vmklinux layer adaptation of standard linux.

ESXi versions supported: 6.0 and higher

Binary installation
--------------------
Preparation:
 - change acceptance level: esxcli software acceptance set -level=CommunitySupported
Installation:
  - esxcli software vib install -f -v <full_path_to_vib>/<vib_name>
    e.g esxcli software vib install -f -v /tmp/net670-pacific-v1.3.2.0-esxi1.0.x86_x64.vib
    e.g esxcli software vib install -f -v $(pwd)/net670-pacific-v1.3.2.0-esxi1.0.x86_x64.vib
  - reboot

Binary removal
--------------------
  - esxcli software vib remove -f -n net-aqc111
  - reboot

Conflicts
--------------------
 - vmkusb_nic_fling driver (Native Non Officially supported USB driver)
    remove .vib with vmkusb_nic_fling before using
 - standart native driver for USB controllers.
    need to set parameter `VMkernel.Boot.preferVmklinux` to `true`

Download latest VIB binary from release area:
https://github.com/Aquantia/aqc111u-esxi/releases

Install as a standalone VIB or integrate offline bundle into your ESXi image.

Source build
--------------------
Please use `esxi/build-pacific.sh` to rebuild the driver.
Notice you have to download and install VmWare Open Source disclosure and toolchain packages

Command line tools
--------------------
 - `esxcfg-nics -l` - show status
    Name    PCI          Driver      Link Speed      Duplex MAC Address       MTU    Description
    vusb0   Pseudo       aqc111      Up   5000Mbps   Full   xx:xx:xx:xx:xx:xx 1500   Unknown Unknown

 - `ethtool -i vusbX` - show driver information
    driver: aqc111
    version: 1.3.2.0-esxi1.0
    firmware-version: X.X.X
    bus-info: usb-0000:00:14.0-1

 - `ethtool vusbX` - show settings
    Settings for vusbX:
         Supported ports: [ TP MII ]
         Supported link modes:   100baseT/Full
                                 1000baseT/Full
         Supports auto-negotiation: Yes
         Advertised link modes:  100baseT/Full
                                 1000baseT/Full
         Advertised auto-negotiation: Yes
         Speed: 5000
         Duplex: Full
         Port: MII
         PHYAD: 0
         Transceiver: internal
         Auto-negotiation: on
         Supports Wake-on: g
         Wake-on: g
         Current message level: 0x00000007 (7)
         Link detected: yes

  - `ethtool -k vusbX` - get offload parameters
     Offload parameters for vusbX:
     rx-checksumming: on
     tx-checksumming: on
     scatter-gather: on
     tcp segmentation offload: on
     udp fragmentation offload: off
     generic segmentation offload: off

  - `ethtool -K vusbX <offload> on/off` - enable/disable offload
     e.g: `ethtool -K vusb0 rx off` - disable rx checksumming
     Note: only RX checksumming on/off is supported
  - `ethtool -s vusbX speed/autoneg/wol` - set/change speed/autoneg/wake-on-lan
     e.g: `ethtool -s vusb0 autoneg off` - disable autonegotiation 