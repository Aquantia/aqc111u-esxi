#!/bin/sh

if [ "$#" -eq 1 -a -n $1 ]
then
BUILD_TARGET=$1
else
BUILD_TARGET=esxi-670
fi

# Use gcc 
# Below is the internal VMWare location.  Please change as required for your
# installed location.
CC=/build/toolchain/lin64/gcc-4.8.0/bin/gcc

# Use ld from binutils
# Below is the internal VMWare location.  Please change as required for your
# installed location.
LD=/build/toolchain/lin64/binutils-2.19.1/x86_64-linux5.0/bin/ld
# Use binary strip
STRIP=/build/toolchain/lin64/binutils-2.19.1/x86_64-linux5.0/bin/strip
# PR# 976913 requested that OSS binaries be stripped of debug
STRIP_OPTS=--strip-debug

SYS_ROOT=/nowhere

I_SYSTEM=/build/toolchain/lin64/gcc-4.8.0/lib/gcc/x86_64-linux5.0/4.8.0/include

SRC_PATH=pacific
OUT_PATH=.build-pacific
OBJ_PATH=$OUT_PATH/objs
BIN_PATH=$OUT_PATH/bin
mkdir $OUT_PATH
mkdir $OBJ_PATH
mkdir $BIN_PATH

# Compiler flags assume being compiled natively on a x86-64 machine
FLAGS="--sysroot=$SYS_ROOT -fwrapv -pipe -fno-strict-aliasing -Wno-unused-but-set-variable "
FLAGS=$FLAGS"-fno-working-directory -g -ggdb3 -O2 -mcmodel=smallhigh -Wall -Werror -Wstrict-prototypes "
FLAGS=$FLAGS"-fno-strict-aliasing -freg-struct-return -falign-jumps=1 -falign-functions=4 -falign-loops=1 "
FLAGS=$FLAGS"-m64 -mno-red-zone -mpreferred-stack-boundary=4 -minline-all-stringops -mno-mmx -mno-3dnow -mno-sse -mno-sse2 "
FLAGS=$FLAGS"-mcld -finline-limit=2000 -fno-common -ffreestanding -nostdinc -fomit-frame-pointer -nostdlib "
FLAGS=$FLAGS"-Wno-error -Wdeclaration-after-statement -Wno-pointer-sign -Wno-strict-prototypes "
FLAGS=$FLAGS"-Wno-enum-compare -Wno-switch "
FLAGS=$FLAGS"-Wno-unused-function "
FLAGS=$FLAGS"-isystem $I_SYSTEM "
FLAGS=$FLAGS"-DCONFIG_COMPAT "
FLAGS=$FLAGS"-DCONFIG_PM "
FLAGS=$FLAGS"-DCONFIG_PM_RUNTIME "
FLAGS=$FLAGS"-DCONFIG_USB_SUSPEND "
FLAGS=$FLAGS"-DCPU=x86-64 "
FLAGS=$FLAGS"-DESX3_NETWORKING_NOT_DONE_YET "
FLAGS=$FLAGS"-DEXPORT_SYMTAB "
FLAGS=$FLAGS"-DGPLED_CODE "
FLAGS=$FLAGS"-DKBUILD_MODNAME=\"aqc111\" "
FLAGS=$FLAGS"-DLINUX_MODULE_AUX_HEAP_NAME=vmklnx_aqc111 "
FLAGS=$FLAGS"-DLINUX_MODULE_HEAP_INITIAL=512*1024 "
FLAGS=$FLAGS"-DLINUX_MODULE_HEAP_MAX=4*1024*1024 "
FLAGS=$FLAGS"-DLINUX_MODULE_HEAP_NAME=vmklnx_aqc111 "
FLAGS=$FLAGS"-DLINUX_MODULE_SKB_HEAP "
FLAGS=$FLAGS"-DLINUX_MODULE_SKB_HEAP_INITIAL=512*1024 "
FLAGS=$FLAGS"-DLINUX_MODULE_SKB_HEAP_MAX=22*1024*1024 "
FLAGS=$FLAGS"-DLINUX_MODULE_VERSION=\"1.0\" "
FLAGS=$FLAGS"-DMODULE "
FLAGS=$FLAGS"-DNET_DRIVER "
FLAGS=$FLAGS"-DNO_FLOATING_POINT "
FLAGS=$FLAGS"-DUSB_DRIVER "
FLAGS=$FLAGS"-DVMKERNEL "
FLAGS=$FLAGS"-DVMKERNEL_MODULE "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_BASE "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_DEVICE "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_ISCSI "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_NET "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_RDMA "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_SCSI "
FLAGS=$FLAGS"-DVMK_DEVKIT_HAS_API_VMKAPI_SOCKETS "
FLAGS=$FLAGS"-DVMK_DEVKIT_IS_DDK "
FLAGS=$FLAGS"-DVMK_DEVKIT_USES_BINARY_COMPATIBLE_APIS "
FLAGS=$FLAGS"-DVMK_DEVKIT_USES_PUBLIC_APIS "
FLAGS=$FLAGS"-DVMNIX "
FLAGS=$FLAGS"-DVMX86_RELEASE "
FLAGS=$FLAGS"-DVMX86_SERVER "
FLAGS=$FLAGS"-D_LINUX "
FLAGS=$FLAGS"-D_VMKDRVEI "
FLAGS=$FLAGS"-D__KERNEL__ "
FLAGS=$FLAGS"-D__VMKERNEL_MODULE__ "
FLAGS=$FLAGS"-D__VMKERNEL__ "
FLAGS=$FLAGS"-D__VMKLNX__ "
FLAGS=$FLAGS"-D__VMK_GCC_BUG_ALIGNMENT_PADDING__ "
FLAGS=$FLAGS"-D__VMWARE__ "

INCLUDES="-I$BUILD_TARGET/BLD/build/version "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/BLD/build/HEADERS/vmkdrivers-vmkernel/vmkernel64/release "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/BLD/build/HEADERS/9-vmkdrivers-namespace/vmkernel64/release/aqc "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/BLD/build/HEADERS/92-vmkdrivers-asm-x64/vmkernel64/release "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/BLD/build/HEADERS/vmkapi-v2_3_0_0-all-public-bincomp/generic/release "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/BLD/build/HEADERS/vmkapi-current-all-public-bincomp/generic/release "
INCLUDES=$INCLUDES"-I$SRC_PATH "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/vmkdrivers/src_92/include "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/vmkdrivers/src_92/include/vmklinux_92 "
INCLUDES=$INCLUDES"-I$BUILD_TARGET/vmkdrivers/src_92/drivers/net "
INCLUDES=$INCLUDES"-include $BUILD_TARGET/vmkdrivers/src_92/include/linux/autoconf.h "

$CC $FLAGS $INCLUDES -c -o $OBJ_PATH/aqc111.o $SRC_PATH/aqc111.c
$CC $FLAGS $INCLUDES -c -o $OBJ_PATH/vmklinux_module.o $BUILD_TARGET/vmkdrivers/src_92/common/vmklinux_module.c

$LD $LD_OPTS -r -o \
    $BIN_PATH/aqc111 --whole-archive \
    $OBJ_PATH/aqc111.o \
    $OBJ_PATH/vmklinux_module.o

$STRIP $STRIP_OPTS $BIN_PATH/aqc111
