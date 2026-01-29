#!/bin/bash
# ============================================================
# SD 卡镜像创建脚本
# 创建可启动的 SD 卡镜像
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/output"
KERNEL_DIR="$PROJECT_DIR/kernel"
BOOTLOADER_DIR="$PROJECT_DIR/bootloader"
ROOTFS_DIR="$OUTPUT_DIR/rootfs"
OVERLAY_DIR="$PROJECT_DIR/rootfs/overlay"

# 配置
IMAGE_NAME="unit-server-linux.img"
IMAGE_SIZE="2G"
BOOT_SIZE="64M"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SD 卡镜像创建脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 检查必要文件
echo -e "\n${YELLOW}[1/8] 检查必要文件...${NC}"

UBOOT_BIN="$BOOTLOADER_DIR/u-boot-sunxi-with-spl.bin"
KERNEL_IMG="$KERNEL_DIR/zImage"
DTB_FILE="$KERNEL_DIR/dts/sun8i-h3-unit-server.dtb"
MODULES_DIR="$KERNEL_DIR/modules/4.14.111"
BOOT_SCR="$BOOTLOADER_DIR/boot/boot.scr"
BOOT_CMD="$BOOTLOADER_DIR/boot/boot.cmd"
INITRD="$BOOTLOADER_DIR/boot/rootfs.cpio.gz"

for file in "$UBOOT_BIN" "$KERNEL_IMG" "$DTB_FILE"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}缺少文件: $file${NC}"
        exit 1
    fi
done

if [ ! -d "$ROOTFS_DIR" ]; then
    echo -e "${RED}Rootfs 不存在，请先运行 02_build_rootfs.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 文件检查通过${NC}"

# 创建空镜像
echo -e "\n${YELLOW}[2/8] 创建 $IMAGE_SIZE 镜像文件...${NC}"
IMAGE_PATH="$OUTPUT_DIR/$IMAGE_NAME"
dd if=/dev/zero of="$IMAGE_PATH" bs=1M count=2048 status=progress

# 设置 loop 设备
echo -e "\n${YELLOW}[3/8] 设置 loop 设备...${NC}"
LOOP_DEV=$(losetup -f --show "$IMAGE_PATH")
echo "使用 loop 设备: $LOOP_DEV"

# 清理函数
cleanup() {
    echo "清理..."
    umount /mnt/sdboot 2>/dev/null || true
    umount /mnt/sdroot 2>/dev/null || true
    losetup -d "$LOOP_DEV" 2>/dev/null || true
}
trap cleanup EXIT

# 分区 (boot 分区从 4MB 开始，给 U-Boot 留空间)
echo -e "\n${YELLOW}[4/8] 创建分区...${NC}"
parted -s "$LOOP_DEV" mklabel msdos
parted -s "$LOOP_DEV" mkpart primary fat32 4MiB 68MiB
parted -s "$LOOP_DEV" mkpart primary ext4 68MiB 100%
parted -s "$LOOP_DEV" set 1 boot on

# 重新读取分区表
partprobe "$LOOP_DEV"
sleep 1

# 格式化分区
echo -e "\n${YELLOW}[5/8] 格式化分区...${NC}"
mkfs.vfat -F 32 -n "BOOT" "${LOOP_DEV}p1"
mkfs.ext4 -L "rootfs" "${LOOP_DEV}p2"

# 挂载分区
mkdir -p /mnt/sdboot /mnt/sdroot
mount "${LOOP_DEV}p1" /mnt/sdboot
mount "${LOOP_DEV}p2" /mnt/sdroot

# 写入 U-Boot
echo -e "\n${YELLOW}[6/8] 写入 U-Boot 和启动文件...${NC}"
dd if="$UBOOT_BIN" of="$LOOP_DEV" bs=1024 seek=8 conv=notrunc

# 复制内核和设备树
cp "$KERNEL_IMG" /mnt/sdboot/
cp "$DTB_FILE" /mnt/sdboot/

# 复制 boot.scr 和 initrd (如果存在)
if [ -f "$BOOT_SCR" ]; then
    cp "$BOOT_SCR" /mnt/sdboot/
    echo -e "${GREEN}✓ 复制 boot.scr${NC}"
fi

if [ -f "$BOOT_CMD" ]; then
    cp "$BOOT_CMD" /mnt/sdboot/
    echo -e "${GREEN}✓ 复制 boot.cmd${NC}"
fi

if [ -f "$INITRD" ]; then
    cp "$INITRD" /mnt/sdboot/
    echo -e "${GREEN}✓ 复制 rootfs.cpio.gz (initrd)${NC}"
fi

# 创建 extlinux 配置 (备用启动方式)
mkdir -p /mnt/sdboot/extlinux
cat > /mnt/sdboot/extlinux/extlinux.conf << EOF
DEFAULT linux
TIMEOUT 10

LABEL linux
    LINUX /zImage
    FDT /sun8i-h3-unit-server.dtb
    APPEND console=ttyS0,115200 root=/dev/mmcblk1p2 rootwait rw panic=10 fbcon=map:1
EOF

echo -e "${GREEN}✓ 创建 extlinux.conf${NC}"

# 复制 rootfs
echo -e "\n${YELLOW}[7/8] 复制 rootfs (这可能需要几分钟)...${NC}"
cp -a "$ROOTFS_DIR"/* /mnt/sdroot/

# 复制内核模块
if [ -d "$MODULES_DIR" ]; then
    mkdir -p /mnt/sdroot/lib/modules/
    cp -r "$MODULES_DIR" /mnt/sdroot/lib/modules/
    echo -e "${GREEN}✓ 复制内核模块${NC}"
fi

# 应用 overlay 配置
echo -e "\n${YELLOW}[8/8] 应用 overlay 配置...${NC}"
if [ -d "$OVERLAY_DIR" ]; then
    cp -a "$OVERLAY_DIR"/* /mnt/sdroot/
    echo -e "${GREEN}✓ 复制 overlay 文件 (rc.local, fstab 等)${NC}"
    
    # 确保 rc.local 可执行
    if [ -f /mnt/sdroot/etc/rc.local ]; then
        chmod +x /mnt/sdroot/etc/rc.local
    fi
fi

# 同步
sync

# 显示结果
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  镜像创建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "镜像文件: $IMAGE_PATH"
ls -lh "$IMAGE_PATH"

echo -e "\n${YELLOW}启动文件:${NC}"
ls -la /mnt/sdboot/

echo -e "\n${YELLOW}写入 SD 卡命令:${NC}"
echo -e "  sudo dd if=$IMAGE_PATH of=/dev/sdX bs=4M status=progress"
echo -e "  (请将 /dev/sdX 替换为实际的 SD 卡设备)"
