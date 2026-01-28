#!/bin/bash
# ============================================================
# Rootfs 构建脚本
# 基于 Debian Bullseye 构建 ARM 根文件系统
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/output"
ROOTFS_DIR="$OUTPUT_DIR/rootfs"

# 配置
DEBIAN_RELEASE="bullseye"
DEBIAN_MIRROR="http://mirrors.tuna.tsinghua.edu.cn/debian"
HOSTNAME="unit-server"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Rootfs 构建脚本 - Debian $DEBIAN_RELEASE${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 检查依赖
echo -e "\n${YELLOW}[1/6] 检查依赖...${NC}"
if ! command -v debootstrap &> /dev/null; then
    echo "安装 debootstrap..."
    apt-get update && apt-get install -y debootstrap qemu-user-static
fi
echo -e "${GREEN}✓ 依赖检查通过${NC}"

# 创建 rootfs 目录
echo -e "\n${YELLOW}[2/6] 创建 rootfs 目录...${NC}"
if [ -d "$ROOTFS_DIR" ]; then
    echo "清理旧的 rootfs..."
    rm -rf "$ROOTFS_DIR"
fi
mkdir -p "$ROOTFS_DIR"

# 运行 debootstrap
echo -e "\n${YELLOW}[3/6] 运行 debootstrap (这可能需要 10-20 分钟)...${NC}"
debootstrap --arch=armhf --foreign "$DEBIAN_RELEASE" "$ROOTFS_DIR" "$DEBIAN_MIRROR"

# 复制 qemu
cp /usr/bin/qemu-arm-static "$ROOTFS_DIR/usr/bin/"

# 完成第二阶段
echo -e "\n${YELLOW}[4/6] 完成 debootstrap 第二阶段...${NC}"
chroot "$ROOTFS_DIR" /debootstrap/debootstrap --second-stage

# 配置系统
echo -e "\n${YELLOW}[5/6] 配置系统...${NC}"

# 设置 hostname
echo "$HOSTNAME" > "$ROOTFS_DIR/etc/hostname"

# 配置 hosts
cat > "$ROOTFS_DIR/etc/hosts" << EOF
127.0.0.1       localhost
127.0.1.1       $HOSTNAME

::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

# 配置 fstab (使用 mmcblk1 因为 SD 卡在此设备上)
cat > "$ROOTFS_DIR/etc/fstab" << EOF
# /etc/fstab - Unit-Server
/dev/mmcblk1p2  /       ext4    defaults,noatime  0 1
/dev/mmcblk1p1  /boot   vfat    defaults,nofail,iocharset=utf8  0 2
EOF

# 配置网络
cat > "$ROOTFS_DIR/etc/network/interfaces" << EOF
# Loopback
auto lo
iface lo inet loopback

# Ethernet (如果有)
allow-hotplug eth0
iface eth0 inet dhcp

# WiFi
allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

# 配置 APT 源
cat > "$ROOTFS_DIR/etc/apt/sources.list" << EOF
deb $DEBIAN_MIRROR $DEBIAN_RELEASE main contrib non-free
deb $DEBIAN_MIRROR $DEBIAN_RELEASE-updates main contrib non-free
deb http://security.debian.org/debian-security $DEBIAN_RELEASE-security main contrib non-free
EOF

# 配置串口登录
mkdir -p "$ROOTFS_DIR/etc/systemd/system/getty.target.wants"
ln -sf /lib/systemd/system/serial-getty@.service \
    "$ROOTFS_DIR/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service"

# 配置 securetty
cat > "$ROOTFS_DIR/etc/securetty" << EOF
ttyS0
tty1
console
EOF

# 设置 root 密码为空（首次登录无需密码）
sed -i 's/^root:[^:]*:/root::/' "$ROOTFS_DIR/etc/shadow"

# 安装基础软件包
echo -e "\n${YELLOW}[6/6] 安装基础软件包...${NC}"
chroot "$ROOTFS_DIR" /bin/bash -c "
    apt-get update
    apt-get install -y --no-install-recommends \
        systemd \
        systemd-sysv \
        udev \
        kmod \
        sudo \
        openssh-server \
        net-tools \
        iputils-ping \
        wget \
        curl \
        vim-tiny \
        wpasupplicant \
        wireless-tools \
        iw
    apt-get clean
    rm -rf /var/lib/apt/lists/*
"

# 清理
rm -f "$ROOTFS_DIR/usr/bin/qemu-arm-static"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Rootfs 构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Rootfs 目录: $ROOTFS_DIR"
du -sh "$ROOTFS_DIR"
