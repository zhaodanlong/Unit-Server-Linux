# Unit-Server Linux 详细构建指南

本文档详细介绍了从零开始为 Unit-Server 构建完整 Linux 系统的全过程。

## 目录

1. [概述](#1-概述)
2. [开发环境准备](#2-开发环境准备)
3. [U-Boot 构建](#3-u-boot-构建)
4. [Linux 内核](#4-linux-内核)
5. [根文件系统构建](#5-根文件系统构建)
6. [SD 卡镜像制作](#6-sd-卡镜像制作)
7. [调试与问题排查](#7-调试与问题排查)

---

## 1. 概述

### 1.1 系统架构

Unit-Server Linux 系统由以下组件组成：

```
┌─────────────────────────────────────────────────────────────┐
│                      应用层                                  │
│  (SSH, systemd, 网络服务, 用户程序)                          │
├─────────────────────────────────────────────────────────────┤
│                   根文件系统 (Rootfs)                        │
│  Debian Bullseye armhf (/dev/mmcblk1p2, ext4)               │
├─────────────────────────────────────────────────────────────┤
│                   Linux 内核 4.14.111                        │
│  - sunxi-mmc (SD卡驱动)                                     │
│  - fb_st7789vw (SPI显示屏)                                  │
│  - rtl8723bu (WiFi/蓝牙)                                    │
├─────────────────────────────────────────────────────────────┤
│                   U-Boot v2024.10                           │
│  - SPL (Secondary Program Loader)                           │
│  - 主 U-Boot (加载内核和设备树)                              │
├─────────────────────────────────────────────────────────────┤
│                   硬件 (Allwinner H3)                        │
│  - 4x Cortex-A7 @ 1.2GHz                                    │
│  - 512MB DDR3                                               │
│  - SD卡/eMMC 存储                                           │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 SD 卡分区布局

```
┌──────────────────────────────────────────────────────────────┐
│ 偏移量    │ 大小    │ 内容                                    │
├──────────────────────────────────────────────────────────────┤
│ 0KB       │ 8KB     │ 保留 (分区表)                           │
│ 8KB       │ ~500KB  │ U-Boot (u-boot-sunxi-with-spl.bin)     │
│ 4MB       │ 64MB    │ boot 分区 (FAT32)                       │
│           │         │   - zImage                              │
│           │         │   - sun8i-h3-unit.dtb                   │
│           │         │   - extlinux/extlinux.conf              │
│ 68MB      │ 剩余    │ rootfs 分区 (ext4)                      │
└──────────────────────────────────────────────────────────────┘
```

### 1.3 启动流程

```
1. 上电复位
      ↓
2. BootROM 从 SD 卡加载 SPL (偏移 8KB)
      ↓
3. SPL 初始化 DRAM，加载主 U-Boot
      ↓
4. U-Boot 初始化设备，加载 extlinux.conf
      ↓
5. U-Boot 加载 zImage 和 DTB 到内存
      ↓
6. 跳转到 Linux 内核
      ↓
7. 内核初始化，挂载 rootfs (/dev/mmcblk1p2)
      ↓
8. 启动 systemd，运行 getty
      ↓
9. 显示登录提示符
```

---

## 2. 开发环境准备

### 2.1 系统要求

- **操作系统**: Ubuntu 20.04/22.04 LTS 或 Debian 11/12
- **处理器**: x86_64 (支持 ARM 交叉编译)
- **内存**: 至少 4GB RAM
- **磁盘**: 至少 20GB 可用空间
- **网络**: 需要访问互联网下载软件包

### 2.2 安装依赖

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础构建工具
sudo apt install -y build-essential git wget curl

# 安装 ARM 交叉编译工具链
sudo apt install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

# 安装 U-Boot 构建依赖
sudo apt install -y bison flex libssl-dev python3 python3-dev swig

# 安装内核构建依赖
sudo apt install -y bc libncurses5-dev device-tree-compiler u-boot-tools

# 安装 rootfs 构建依赖
sudo apt install -y debootstrap qemu-user-static binfmt-support

# 安装镜像工具
sudo apt install -y parted dosfstools e2fsprogs kpartx

# 安装串口调试工具
sudo apt install -y picocom minicom
```

### 2.3 验证工具链

```bash
# 检查 ARM GCC 版本
arm-linux-gnueabihf-gcc --version
# 输出: arm-linux-gnueabihf-gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0

# 检查 debootstrap
debootstrap --version
# 输出: debootstrap 1.0.126+nmu1ubuntu0.5
```

---

## 3. U-Boot 构建

### 3.1 概述

U-Boot (Universal Boot Loader) 是嵌入式系统常用的引导程序。对于 Allwinner H3，U-Boot 包含两部分：
- **SPL (Secondary Program Loader)**: 初始化 DRAM
- **主 U-Boot**: 加载内核和设备树

### 3.2 下载源码

```bash
# 下载 mainline U-Boot
git clone --depth 1 --branch v2024.10 https://github.com/u-boot/u-boot.git
cd u-boot
```

### 3.3 配置

```bash
# 使用 NanoPi NEO 配置作为基础 (与 Unit-Server 硬件兼容)
make CROSS_COMPILE=arm-linux-gnueabihf- nanopi_neo_defconfig
```

### 3.4 关键修改

**问题**: 默认配置使用 PF6 作为 SD 卡检测引脚，但 Unit-Server 使用 PH13 或没有检测引脚。

**解决方案**: 修改设备树，添加 `broken-cd` 属性禁用卡检测：

编辑 `arch/arm/dts/sun8i-h3-nanopi.dtsi`:

```dts
&mmc0 {
    bus-width = <4>;
    broken-cd;  /* 禁用卡检测，假设卡始终存在 */
    status = "okay";
    vmmc-supply = <&reg_vcc3v3>;
};
```

### 3.5 编译

```bash
make -j$(nproc) CROSS_COMPILE=arm-linux-gnueabihf-
```

### 3.6 输出文件

编译成功后，关键输出文件：

- `u-boot-sunxi-with-spl.bin` - 包含 SPL 和主 U-Boot 的合并镜像

### 3.7 写入 SD 卡

```bash
# 写入到 SD 卡偏移 8KB 位置
sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sdX bs=1024 seek=8
```

---

## 4. Linux 内核

### 4.1 内核来源

本项目使用 Project-Quantum 原始项目提供的定制内核 4.14.111，该内核包含：
- Allwinner H3 平台支持
- ST7789VW SPI 显示屏驱动 (fbtft)
- RTL8723BU WiFi/蓝牙驱动
- Unit-Server 专用设备树

### 4.2 关键配置

内核配置 (`.config`) 中的关键选项：

```
# SD 卡支持 (内置，非模块)
CONFIG_MMC=y
CONFIG_MMC_SUNXI=y

# 显示屏支持
CONFIG_FB=y
CONFIG_FB_TFT=m
CONFIG_FB_TFT_ST7789V=m

# WiFi 支持
CONFIG_RTL8723BU=m

# 串口控制台
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
```

### 4.3 设备树

设备树文件 `sun8i-h3-unit.dts` 定义了硬件配置：

```dts
/ {
    model = "Pengzhihui Unit-Sever";
    compatible = "allwinner,sun8i-h3";
    
    /* SPI 显示屏配置 */
    fbtft_device {
        compatible = "fbtft,device";
        spi = <&spi0>;
        model = "ips_114inch_240_135";
        /* GPIO 配置 */
        reset = <&pio 0 1 GPIO_ACTIVE_LOW>;  /* PA1 */
        dc = <&pio 0 0 GPIO_ACTIVE_HIGH>;    /* PA0 */
    };
};
```

### 4.4 内核模块

重要的内核模块位于 `kernel/modules/4.14.111/`:

```
drivers/
├── net/
│   └── wireless/
│       └── rtl8723bu/    # WiFi 驱动
├── staging/
│   └── fbtft/
│       └── fb_st7789vw.ko  # 显示屏驱动
└── bluetooth/
    └── btusb.ko          # 蓝牙驱动
```

---

## 5. 根文件系统构建

### 5.1 使用 debootstrap

```bash
# 创建目标目录
sudo mkdir -p /tmp/rootfs

# 运行 debootstrap 第一阶段
sudo debootstrap --arch=armhf --foreign bullseye /tmp/rootfs http://mirrors.tuna.tsinghua.edu.cn/debian

# 复制 QEMU 模拟器
sudo cp /usr/bin/qemu-arm-static /tmp/rootfs/usr/bin/

# 运行第二阶段
sudo chroot /tmp/rootfs /debootstrap/debootstrap --second-stage
```

### 5.2 系统配置

进入 chroot 环境进行配置：

```bash
sudo chroot /tmp/rootfs /bin/bash
```

#### 5.2.1 设置主机名

```bash
echo "unit-server" > /etc/hostname
```

#### 5.2.2 配置 fstab

```bash
cat > /etc/fstab << EOF
/dev/mmcblk1p2  /       ext4    defaults,noatime  0 1
/dev/mmcblk1p1  /boot   vfat    defaults          0 2
EOF
```

**注意**: 使用 `mmcblk1` 而不是 `mmcblk0`，因为 SD 卡在此硬件上被识别为 mmc1。

#### 5.2.3 配置串口登录

```bash
# 启用串口 getty
ln -sf /lib/systemd/system/serial-getty@.service \
    /etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service

# 配置 securetty
cat > /etc/securetty << EOF
ttyS0
tty1
console
EOF
```

#### 5.2.4 设置 root 密码

```bash
# 清空 root 密码 (首次登录无需密码)
sed -i 's/^root:[^:]*:/root::/' /etc/shadow
```

#### 5.2.5 安装基础软件包

```bash
apt update
apt install -y systemd systemd-sysv udev kmod sudo openssh-server \
    net-tools iputils-ping wget curl vim-tiny wpasupplicant wireless-tools
```

### 5.3 清理

```bash
# 退出 chroot
exit

# 清理 QEMU
sudo rm /tmp/rootfs/usr/bin/qemu-arm-static

# 清理 APT 缓存
sudo rm -rf /tmp/rootfs/var/cache/apt/*
```

---

## 6. SD 卡镜像制作

### 6.1 创建镜像文件

```bash
# 创建 512MB 镜像
dd if=/dev/zero of=sdcard.img bs=1M count=512

# 设置 loop 设备
LOOP=$(sudo losetup -f --show sdcard.img)
```

### 6.2 分区

```bash
# 创建分区表
sudo parted -s $LOOP mklabel msdos

# boot 分区 (4MB - 68MB, FAT32)
sudo parted -s $LOOP mkpart primary fat32 4MiB 68MiB

# rootfs 分区 (68MB - 结束, ext4)
sudo parted -s $LOOP mkpart primary ext4 68MiB 100%

# 设置 boot 标志
sudo parted -s $LOOP set 1 boot on
```

### 6.3 格式化

```bash
# 重新读取分区表
sudo partprobe $LOOP

# 格式化
sudo mkfs.vfat -F 32 -n "BOOT" ${LOOP}p1
sudo mkfs.ext4 -L "rootfs" ${LOOP}p2
```

### 6.4 复制文件

```bash
# 挂载分区
sudo mkdir -p /mnt/boot /mnt/rootfs
sudo mount ${LOOP}p1 /mnt/boot
sudo mount ${LOOP}p2 /mnt/rootfs

# 写入 U-Boot
sudo dd if=u-boot-sunxi-with-spl.bin of=$LOOP bs=1024 seek=8

# 复制启动文件
sudo cp zImage /mnt/boot/
sudo cp sun8i-h3-unit.dtb /mnt/boot/

# 创建 extlinux 配置
sudo mkdir -p /mnt/boot/extlinux
cat << EOF | sudo tee /mnt/boot/extlinux/extlinux.conf
DEFAULT linux
TIMEOUT 10

LABEL linux
    LINUX /zImage
    FDT /sun8i-h3-unit.dtb
    APPEND console=ttyS0,115200 root=/dev/mmcblk1p2 rootwait rw panic=10
EOF

# 复制 rootfs
sudo cp -a /tmp/rootfs/* /mnt/rootfs/

# 复制内核模块
sudo cp -r modules/4.14.111 /mnt/rootfs/lib/modules/

# 卸载
sudo umount /mnt/boot /mnt/rootfs
sudo losetup -d $LOOP
```

### 6.5 写入 SD 卡

```bash
sudo dd if=sdcard.img of=/dev/sdX bs=4M status=progress
sudo sync
```

---

## 7. 调试与问题排查

### 7.1 串口调试

```bash
# 连接串口 (115200 8N1)
sudo picocom -b 115200 /dev/ttyUSB0
```

### 7.2 常见问题

#### 问题: U-Boot 显示 "MMC: no card present"

**原因**: SD 卡检测引脚配置不正确

**解决**: 在设备树中添加 `broken-cd` 属性

#### 问题: 内核启动后等待 `/dev/mmcblk0p2`

**原因**: SD 卡被识别为 `mmcblk1` 而非 `mmcblk0`

**解决**: 修改 extlinux.conf 和 fstab 中的设备路径为 `mmcblk1p2`

#### 问题: 系统启动但没有登录提示

**原因**: 串口 getty 未启用

**解决**: 确保 `serial-getty@ttyS0.service` 已启用

### 7.3 U-Boot 命令行调试

在 U-Boot 启动时按任意键进入命令行：

```
# 检查 MMC
=> mmc list
=> mmc dev 0
=> mmc info

# 检查分区
=> mmc part

# 手动启动
=> load mmc 0:1 0x42000000 zImage
=> load mmc 0:1 0x43000000 sun8i-h3-unit.dtb
=> setenv bootargs console=ttyS0,115200 root=/dev/mmcblk1p2 rootwait rw
=> bootz 0x42000000 - 0x43000000
```

### 7.4 内核调试

添加启动参数增加日志输出：

```
APPEND console=ttyS0,115200 root=/dev/mmcblk1p2 rootwait rw panic=10 loglevel=8 earlycon
```

---

## 8. LCD 显示屏配置 (关键!)

### 8.1 问题背景

Unit-Server 配备 1.14 寸 IPS LCD (240x135)，使用 ST7789VW 控制器，通过 SPI0 连接。

**常见问题**: 屏幕初始化成功但不显示内容。

**根本原因**: GPIO 配置不正确。LCD 需要正确的 DC (Data/Command) 和 Reset 引脚配置。

### 8.2 正确的 GPIO 配置

| LCD 引脚 | H3 引脚 | GPIO 编号 | 说明 |
|---------|--------|----------|------|
| DC | PA12 | **12** | 数据/命令选择 |
| RST | PA11 | **11** | 复位 |

### 8.3 两种启动方式

#### 方式一: boot.scr (推荐)

使用 `bootloader/boot/boot.cmd` 和 `boot.scr`:

```bash
# boot.cmd 关键配置
setenv fbcon map:1
setenv bootargs console=ttyS0,115200 ... fbcon=${fbcon}
```

编译 boot.scr:
```bash
mkimage -C none -A arm -T script -d boot.cmd boot.scr
```

#### 方式二: extlinux.conf

创建 `boot/extlinux/extlinux.conf`:

```
DEFAULT linux
TIMEOUT 10

LABEL linux
    LINUX /zImage
    FDT /sun8i-h3-unit.dtb
    APPEND console=ttyS0,115200 root=/dev/mmcblk1p2 rootwait rw panic=10 fbcon=map:1
```

### 8.4 驱动加载 (rc.local)

**重要**: 必须使用模块方式加载 fbtft，以便指定正确的 GPIO。

创建 `/etc/rc.local`:

```bash
#!/bin/sh -e
# 加载 SPI LCD 驱动 - 关键是 GPIO 配置!
modprobe fbtft_device custom name=fb_st7789vw busnum=0 mode=3 speed=50000000 gpios=dc:12,reset:11
exit 0
```

参数说明:

| 参数 | 值 | 说明 |
|-----|-----|------|
| custom | - | 使用自定义配置 |
| name | fb_st7789vw | LCD 控制器驱动 |
| busnum | 0 | SPI0 总线 |
| mode | 3 | SPI 模式 3 |
| speed | 50000000 | 50MHz |
| gpios | dc:12,reset:11 | **关键!** GPIO 配置 |

### 8.5 常见错误

#### 错误 1: 内核内置 fbtft_device 使用错误的 GPIO

**症状**: 
```
fbtft_device: GPIOS used by 'ips_114inch_240_135':
fbtft_device: 'reset' = GPIO1
fbtft_device: 'dc' = GPIO0
```

**问题**: 内核内置的配置使用 GPIO0/GPIO1，而硬件实际使用 GPIO12/GPIO11。

**解决**: 使用支持模块加载的内核 (本项目提供的 `kernel/zImage`)，通过 rc.local 加载正确配置。

#### 错误 2: Driver already registered

**症状**:
```
Error: Driver 'fb_st7789vw' is already registered, aborting...
```

**原因**: 内核已内置了 fbtft_device，rc.local 尝试再次加载失败。

**解决**: 这种情况下，需要更换为支持模块加载的内核。

### 8.6 验证显示屏

```bash
# 检查 framebuffer 设备
ls -la /dev/fb*
# 应该有 fb0 (HDMI) 和 fb1 (SPI LCD)

# 检查驱动加载
lsmod | grep fbtft
dmesg | grep st7789

# 测试显示
cat /dev/urandom > /dev/fb1  # 显示随机像素
dd if=/dev/zero of=/dev/fb1 bs=1024 count=64  # 清屏

# 查看 fb1 信息
fbset -fb /dev/fb1
```

---

## 附录

### A. 有用的命令

```bash
# 检查系统信息
uname -a
cat /proc/cpuinfo
free -h
df -h

# 检查显示设备
ls /dev/fb*
cat /dev/urandom > /dev/fb1  # 测试显示屏

# 检查网络
ip addr
iwconfig

# 检查内核模块
lsmod
modprobe fb_st7789vw
```

### B. 参考链接

- [Linux Sunxi Wiki](https://linux-sunxi.org/)
- [U-Boot Documentation](https://u-boot.readthedocs.io/)
- [Debian Wiki - Debootstrap](https://wiki.debian.org/Debootstrap)
- [Project-Quantum GitHub](https://github.com/peng-zhihui/Project-Quantum)
