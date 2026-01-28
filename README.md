# Unit-Server Linux 构建系统

基于 **Allwinner H3** 处理器的 **Quark-Core / Unit-Server** 开发板 Linux 系统构建工具。

## 📋 目录

- [项目简介](#项目简介)
- [硬件信息](#硬件信息)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
- [详细构建步骤](#详细构建步骤)
- [烧录到 SD 卡](#烧录到-sd-卡)
- [首次启动](#首次启动)
- [LCD 显示屏配置](#lcd-显示屏配置)
- [常见问题](#常见问题)

## 📖 项目简介

本项目提供了完整的 Linux 系统构建工具链，用于为 **稚晖君 (peng-zhihui)** 的 [Project-Quantum](https://github.com/peng-zhihui/Project-Quantum) 开发板构建可启动的 Linux 系统。

### 系统规格

| 组件 | 版本/规格 |
|------|----------|
| U-Boot | v2024.10 (mainline) |
| Linux 内核 | 4.14.111 (原始项目定制版) |
| 根文件系统 | Debian 11 (Bullseye) armhf |
| SPI 显示屏 | ST7789VW 240x135 IPS LCD |

## 🔧 硬件信息

### Quark-Core 核心板

- **处理器**: Allwinner H3 (4x Cortex-A7 @ 1.2GHz)
- **内存**: 512MB DDR3
- **存储**: microSD 卡
- **WiFi/蓝牙**: RTL8723BU

### Unit-Server 底板

- **USB**: USB-C (电源 + 调试串口 CP2102)
- **显示屏**: 1.14 寸 IPS LCD (240x135, SPI 接口, ST7789VW)
- **按键**: 2 个用户按键
- **LED**: 状态指示灯

## 📁 目录结构

```
Unit-Server-Linux/
├── bootloader/             # U-Boot 引导程序
│   ├── config/             # U-Boot 配置文件
│   ├── boot/               # 启动配置
│   │   ├── boot.cmd        # U-Boot 启动脚本源文件
│   │   ├── boot.scr        # 编译后的启动脚本
│   │   └── rootfs.cpio.gz  # initrd 镜像
│   └── u-boot-sunxi-with-spl.bin  # 预编译的 U-Boot
│
├── kernel/                 # Linux 内核
│   ├── zImage              # 内核镜像 (支持 fbtft 模块加载)
│   ├── kernel_config       # 内核配置文件
│   ├── dts/                # 设备树文件
│   │   ├── sun8i-h3-unit.dtb
│   │   └── sun8i-h3-unit.dts
│   └── modules/            # 内核模块
│       └── 4.14.111/
│
├── rootfs/                 # 根文件系统配置
│   └── overlay/            # 覆盖文件
│       └── etc/
│           ├── rc.local    # LCD 驱动加载脚本
│           └── fstab       # 文件系统挂载表
│
├── scripts/                # 构建脚本
│   ├── 00_install_deps.sh  # 安装依赖
│   ├── 01_build_uboot.sh   # 构建 U-Boot
│   ├── 02_build_rootfs.sh  # 构建根文件系统
│   ├── 03_create_image.sh  # 创建 SD 卡镜像
│   ├── 04_flash_sdcard.sh  # 烧录 SD 卡
│   └── build_all.sh        # 一键构建
│
├── docs/                   # 文档
│   └── BUILD_GUIDE.md      # 详细构建指南
│
├── output/                 # 输出目录
│   └── unit-server-linux.img  # SD 卡镜像
│
└── README.md               # 本文件
```

## 🚀 快速开始

### 系统要求

- **操作系统**: Ubuntu 20.04/22.04 或 Debian 11/12
- **磁盘空间**: 至少 10GB
- **内存**: 至少 4GB
- **SD 卡**: 至少 8GB

### 一键构建

```bash
# 1. 安装依赖
sudo ./scripts/00_install_deps.sh

# 2. 一键构建整个系统
sudo ./scripts/build_all.sh

# 3. 烧录到 SD 卡
sudo ./scripts/04_flash_sdcard.sh
```

## 📝 详细构建步骤

### 步骤 1: 安装依赖

```bash
sudo ./scripts/00_install_deps.sh
```

这将安装以下组件：
- ARM 交叉编译工具链 (gcc-arm-linux-gnueabihf)
- U-Boot 构建依赖 (bison, flex, libssl-dev, swig)
- 内核构建依赖 (bc, libncurses)
- Rootfs 构建工具 (debootstrap, qemu-user-static)
- 镜像工具 (parted, dosfstools, u-boot-tools)

### 步骤 2: 构建 U-Boot

```bash
sudo ./scripts/01_build_uboot.sh
```

脚本将：
1. 下载 mainline U-Boot v2024.10
2. 应用 NanoPi NEO 配置
3. 修改设备树禁用 SD 卡检测引脚 (broken-cd)
4. 编译生成 `u-boot-sunxi-with-spl.bin`

### 步骤 3: 构建根文件系统

```bash
sudo ./scripts/02_build_rootfs.sh
```

脚本将：
1. 使用 debootstrap 构建 Debian Bullseye 基础系统
2. 配置网络、串口登录
3. 安装必要的软件包
4. 复制 `rootfs/overlay/` 中的配置文件
5. 配置 systemd 服务

### 步骤 4: 创建 SD 卡镜像

```bash
sudo ./scripts/03_create_image.sh
```

脚本将：
1. 创建 512MB 的镜像文件
2. 分区：boot (64MB FAT32) + rootfs (剩余空间 ext4)
3. 写入 U-Boot 到扇区 8 (偏移 8KB)
4. 复制启动文件 (zImage, dtb, boot.scr, rootfs.cpio.gz)
5. 复制根文件系统和内核模块

## 💾 烧录到 SD 卡

### 使用脚本烧录

```bash
sudo ./scripts/04_flash_sdcard.sh
```

### 手动烧录

```bash
# 查看 SD 卡设备
lsblk

# 烧录镜像 (将 /dev/sdX 替换为实际设备)
sudo dd if=output/unit-server-linux.img of=/dev/sdX bs=4M status=progress
sudo sync
```

⚠️ **警告**: 请确认目标设备是 SD 卡，错误的设备会导致数据丢失！

## 🖥️ 首次启动

### 连接串口

1. 将 SD 卡插入 Unit-Server
2. 使用 USB-C 线连接电脑
3. 打开串口终端：

```bash
# 使用 picocom
sudo picocom -b 115200 /dev/ttyUSB0

# 或使用 minicom
sudo minicom -D /dev/ttyUSB0 -b 115200

# 或简单查看输出
sudo cat /dev/ttyUSB0
```

### 登录系统

- **用户名**: root
- **密码**: (空，直接回车)

### 首次登录后建议操作

```bash
# 设置 root 密码
passwd

# 更新系统
apt update && apt upgrade

# 设置时区
timedatectl set-timezone Asia/Shanghai

# 配置 WiFi
wpa_passphrase "WiFi名称" "WiFi密码" >> /etc/wpa_supplicant/wpa_supplicant.conf
systemctl restart networking
```

## 🖼️ LCD 显示屏配置

### 硬件连接

Unit-Server 配备 1.14 寸 IPS LCD，使用 ST7789VW 控制器，通过 SPI0 接口连接：

| LCD 引脚 | H3 引脚 | GPIO 编号 | 说明 |
|---------|--------|----------|------|
| MOSI | SPI0_MOSI | - | SPI 数据输出 |
| SCK | SPI0_CLK | - | SPI 时钟 |
| CS | SPI0_CS0 | - | 片选 |
| DC | PA12 | 12 | 数据/命令选择 |
| RST | PA11 | 11 | 复位 |
| BL | - | - | 背光 (常亮或由其他电路控制) |

### 关键配置

#### 1. 启动参数 (boot.cmd)

```bash
# 控制台映射到 SPI LCD (fb1)
setenv fbcon map:1

# 内核启动参数
setenv bootargs console=ttyS0,115200 ... fbcon=${fbcon}
```

- `fbcon=map:1`: 将内核控制台映射到 fb1 (SPI LCD)
- fb0 = HDMI 输出, fb1 = SPI LCD

#### 2. 驱动加载 (rc.local)

```bash
modprobe fbtft_device custom name=fb_st7789vw busnum=0 mode=3 speed=50000000 gpios=dc:12,reset:11
```

| 参数 | 值 | 说明 |
|-----|-----|------|
| name | fb_st7789vw | LCD 控制器驱动 |
| busnum | 0 | SPI0 总线 |
| mode | 3 | SPI 模式 3 (CPOL=1, CPHA=1) |
| speed | 50000000 | 50MHz SPI 时钟 |
| dc | 12 | PA12, 数据/命令引脚 |
| reset | 11 | PA11, 复位引脚 |

### 测试显示屏

```bash
# 显示随机像素
cat /dev/urandom > /dev/fb1

# 清屏 (黑色)
dd if=/dev/zero of=/dev/fb1 bs=1024 count=64

# 查看 framebuffer 信息
fbset -fb /dev/fb1

# 查看驱动加载状态
dmesg | grep fb_st7789vw
```

### 注意事项

⚠️ **重要**: 内核必须支持 **模块方式** 加载 fbtft_device。如果内核内置了 fbtft_device 驱动，可能会使用错误的 GPIO 配置，导致屏幕无法显示。

本项目提供的内核 (`kernel/zImage`) 已正确配置，支持通过模块参数指定 GPIO。

## 📶 WiFi 配置

### 硬件信息

- **芯片**: Realtek RTL8723BU
- **接口**: USB
- **驱动**: 8723bu.ko

### 驱动加载

WiFi 驱动在 `rc.local` 中自动加载：

```bash
insmod /lib/modules/4.14.111/kernel/drivers/net/wireless/realtek/rtl8723bu/8723bu.ko
```

加载成功后，WiFi 接口名为 `wlan0` 或 `wlx...`（如 `wlx203233bc8196`）。

### 检查 WiFi 状态

```bash
# 查看接口
ip link show

# 启动接口
ip link set wlan0 up  # 或 wlx... 名称

# 查看驱动加载
lsmod | grep 8723
dmesg | grep RTL871X
```

### 连接 WiFi

需要安装 WiFi 工具：

```bash
apt install wpasupplicant wireless-tools iw
```

然后配置 WPA：

```bash
# 生成配置
wpa_passphrase "WiFi名称" "WiFi密码" >> /etc/wpa_supplicant/wpa_supplicant.conf

# 启动 wpa_supplicant
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf

# 获取 IP
dhclient wlan0
```

或使用 `/etc/network/interfaces`:

```
auto wlan0
iface wlan0 inet dhcp
    wpa-ssid "WiFi名称"
    wpa-psk "WiFi密码"
```

## ❓ 常见问题

### Q: 串口没有输出？

1. 检查 USB 连接
2. 确认串口设备存在: `ls /dev/ttyUSB*`
3. 加载驱动: `sudo modprobe cp210x`
4. 检查波特率是否为 115200

### Q: SD 卡无法识别？

SD 卡在此系统中被识别为 `mmcblk1` 而不是 `mmcblk0`，这是正常的。启动配置和 fstab 已针对此进行调整。

如果系统卡在 "Waiting for root device"：
- 检查 `boot.cmd` 中的 `root=/dev/mmcblk1p2`
- 检查 `/etc/fstab` 中的设备路径

### Q: 显示屏不工作？

1. **检查驱动是否加载**:
   ```bash
   lsmod | grep fbtft
   dmesg | grep fb_st7789vw
   ```

2. **检查 framebuffer 设备**:
   ```bash
   ls -la /dev/fb*
   ```
   应该有 fb0 (HDMI) 和 fb1 (SPI LCD)

3. **手动加载驱动**:
   ```bash
   modprobe fbtft_device custom name=fb_st7789vw busnum=0 mode=3 speed=50000000 gpios=dc:12,reset:11
   ```

4. **检查 GPIO 配置**:
   如果屏幕仍然不显示，可能是 GPIO 配置不正确。确保使用 `dc:12,reset:11`。

### Q: 系统进入 Emergency Mode？

检查以下几点：
1. `/etc/fstab` 中的设备路径是否正确 (`mmcblk1p2`)
2. `/boot` 挂载选项是否包含 `nofail`
3. 根文件系统是否完整

### Q: 如何重新编译 boot.scr？

修改 `bootloader/boot/boot.cmd` 后，运行：

```bash
mkimage -C none -A arm -T script -d bootloader/boot/boot.cmd bootloader/boot/boot.scr
```

## 📚 参考资料

- [Project-Quantum 原始仓库](https://github.com/peng-zhihui/Project-Quantum)
- [U-Boot 官方文档](https://u-boot.readthedocs.io/)
- [Allwinner H3 数据手册](https://linux-sunxi.org/H3)
- [FBTFT 驱动文档](https://github.com/notro/fbtft/wiki)
- [Debian debootstrap 文档](https://wiki.debian.org/Debootstrap)

## 📄 许可证

本项目遵循 MIT 许可证。内核和 U-Boot 遵循各自的许可证 (GPL)。

---

**作者**: 基于 peng-zhihui 的 Project-Quantum 项目整理  
**日期**: 2026-01-28
