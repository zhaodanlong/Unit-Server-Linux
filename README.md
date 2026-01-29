# Unit-Server Linux

基于 Allwinner H3 的嵌入式 Linux 系统

## 硬件配置

- **CPU**: Allwinner H3 四核 Cortex-A7 @ 1.2GHz
- **RAM**: 512MB DDR3
- **存储**: TF Card
- **显示**: ST7789VW 240x135 SPI LCD
- **网络**: RTL8723BU WiFi/Bluetooth
- **接口**: Type-C (供电+串口), GPIO 按键/LED

## 目录结构

```
Unit-Server-Linux/
├── kernel/
│   ├── dts/                    # 设备树源文件
│   │   └── sun8i-h3-unit-server.dts
│   ├── config/                 # 内核配置
│   │   └── unit-server_defconfig
│   └── patches/                # 内核补丁
│       └── 0001-fbtft-st7789v-add-offset-for-240x135.patch
├── bootloader/
│   └── extlinux/
│       └── extlinux.conf       # 启动配置
├── rootfs/                     # 根文件系统配置
├── scripts/                    # 构建脚本
│   ├── build_kernel.sh         # 内核编译脚本
│   └── create_image.sh         # 镜像创建脚本
├── docs/                       # 文档
│   └── HARDWARE_SPEC.md        # 硬件规格
└── output/                     # 编译输出
```

## 快速开始

### 1. 准备工具链

```bash
# 下载 ARM GCC 10.3 工具链
wget https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz
mkdir -p ~/tools
tar -xf gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz -C ~/tools/
```

### 2. 获取内核源码

```bash
# 使用 Linux 4.14 内核
git clone --depth 1 -b linux-4.14.y https://github.com/torvalds/linux.git /tmp/linux-kernel
```

### 3. 编译内核

```bash
./scripts/build_kernel.sh
```

### 4. 创建镜像

```bash
./scripts/create_image.sh
```

## 功能状态

| 功能 | 状态 | 说明 |
|------|------|------|
| LCD 显示 | ✅ | ST7789VW 240x135, 启动日志可见 |
| WiFi | ✅ | RTL8723BU, 可扫描网络 |
| 蓝牙 | ⚠️ | 驱动已加载, 未完全测试 |
| GPIO 按键 | ✅ | KEY1/KEY2 |
| LED | ✅ | STATUS_LED/USR_LED |
| 音频 | ⚠️ | Codec 驱动有警告 |
| USB | ✅ | OTG + Host |

## 已知问题

1. **WiFi 连接某些路由器失败** - rtl8xxxu 驱动兼容性问题，可尝试使用专用驱动
2. **音频 Codec 警告** - `Failed to register our card`，不影响基本功能

## 许可证

本项目采用 MIT 许可证
