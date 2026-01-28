#!/bin/bash
# ============================================================
# U-Boot 构建脚本
# 用于 Allwinner H3 Unit-Server
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/output"
UBOOT_VERSION="v2024.10"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  U-Boot 构建脚本 - Unit-Server${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查依赖
echo -e "\n${YELLOW}[1/5] 检查构建依赖...${NC}"
DEPS="git make gcc arm-linux-gnueabihf-gcc python3 bison flex libssl-dev"
for dep in $DEPS; do
    if ! command -v $dep &> /dev/null && ! dpkg -l | grep -q $dep; then
        echo -e "${RED}缺少依赖: $dep${NC}"
        echo "请运行: sudo apt install gcc-arm-linux-gnueabihf build-essential bison flex libssl-dev python3 swig"
        exit 1
    fi
done
echo -e "${GREEN}✓ 依赖检查通过${NC}"

# 下载 U-Boot
UBOOT_DIR="$PROJECT_DIR/bootloader/u-boot-src"
if [ ! -d "$UBOOT_DIR" ]; then
    echo -e "\n${YELLOW}[2/5] 下载 U-Boot $UBOOT_VERSION...${NC}"
    git clone --depth 1 --branch $UBOOT_VERSION https://github.com/u-boot/u-boot.git "$UBOOT_DIR"
else
    echo -e "\n${YELLOW}[2/5] U-Boot 源码已存在，跳过下载${NC}"
fi

# 应用配置
echo -e "\n${YELLOW}[3/5] 配置 U-Boot...${NC}"
cd "$UBOOT_DIR"

# 使用 NanoPi NEO 配置作为基础
make CROSS_COMPILE=arm-linux-gnueabihf- nanopi_neo_defconfig

# 应用自定义修改：禁用 CD 引脚检测
if [ -f "$PROJECT_DIR/bootloader/config/sun8i-h3-nanopi.dtsi" ]; then
    cp "$PROJECT_DIR/bootloader/config/sun8i-h3-nanopi.dtsi" arch/arm/dts/
    echo -e "${GREEN}✓ 已应用自定义设备树配置${NC}"
fi

# 编译
echo -e "\n${YELLOW}[4/5] 编译 U-Boot...${NC}"
make -j$(nproc) CROSS_COMPILE=arm-linux-gnueabihf-

# 复制输出
echo -e "\n${YELLOW}[5/5] 复制输出文件...${NC}"
mkdir -p "$OUTPUT_DIR"
cp u-boot-sunxi-with-spl.bin "$OUTPUT_DIR/"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  U-Boot 构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "输出文件: $OUTPUT_DIR/u-boot-sunxi-with-spl.bin"
ls -lh "$OUTPUT_DIR/u-boot-sunxi-with-spl.bin"
