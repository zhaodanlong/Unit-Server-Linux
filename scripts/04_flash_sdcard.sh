#!/bin/bash
# ============================================================
# SD 卡烧录脚本
# 将镜像写入 SD 卡
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/output"
IMAGE_PATH="$OUTPUT_DIR/unit-server-linux.img"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SD 卡烧录脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 检查镜像文件
if [ ! -f "$IMAGE_PATH" ]; then
    echo -e "${RED}镜像文件不存在: $IMAGE_PATH${NC}"
    echo "请先运行 03_create_image.sh 创建镜像"
    exit 1
fi

# 列出可用的块设备
echo -e "\n${YELLOW}可用的块设备:${NC}"
lsblk -d -o NAME,SIZE,MODEL | grep -E "^sd|^mmcblk"

# 获取目标设备
echo -e "\n${YELLOW}请输入目标 SD 卡设备 (例如: /dev/sdb):${NC}"
read -r TARGET_DEV

# 验证设备
if [ ! -b "$TARGET_DEV" ]; then
    echo -e "${RED}无效的设备: $TARGET_DEV${NC}"
    exit 1
fi

# 确认
echo -e "\n${RED}警告: 这将擦除 $TARGET_DEV 上的所有数据！${NC}"
echo -e "目标设备信息:"
lsblk "$TARGET_DEV"
echo -e "\n${YELLOW}确认继续? (输入 'yes' 确认):${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "已取消"
    exit 0
fi

# 卸载分区
echo -e "\n${YELLOW}[1/3] 卸载分区...${NC}"
umount "${TARGET_DEV}"* 2>/dev/null || true

# 清除旧数据
echo -e "\n${YELLOW}[2/3] 清除分区表...${NC}"
dd if=/dev/zero of="$TARGET_DEV" bs=1M count=10 status=progress

# 写入镜像
echo -e "\n${YELLOW}[3/3] 写入镜像...${NC}"
dd if="$IMAGE_PATH" of="$TARGET_DEV" bs=4M status=progress
sync

# 弹出
eject "$TARGET_DEV" 2>/dev/null || true

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  烧录完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "请取出 SD 卡并插入 Unit-Server 测试"
