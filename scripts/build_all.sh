#!/bin/bash
# ============================================================
# 一键构建脚本
# 完整构建 Unit-Server Linux 系统
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║      Unit-Server Linux 一键构建系统                        ║${NC}"
echo -e "${BLUE}║      Allwinner H3 / Quark-Core                             ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    echo "用法: sudo $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all      - 构建所有组件 (默认)"
    echo "  uboot    - 仅构建 U-Boot"
    echo "  rootfs   - 仅构建 Rootfs"
    echo "  image    - 仅创建镜像"
    echo "  flash    - 烧录到 SD 卡"
    exit 1
fi

BUILD_TARGET="${1:-all}"

case "$BUILD_TARGET" in
    all)
        echo -e "\n${GREEN}>>> 步骤 1/3: 构建 U-Boot${NC}"
        bash "$SCRIPT_DIR/01_build_uboot.sh"
        
        echo -e "\n${GREEN}>>> 步骤 2/3: 构建 Rootfs${NC}"
        bash "$SCRIPT_DIR/02_build_rootfs.sh"
        
        echo -e "\n${GREEN}>>> 步骤 3/3: 创建镜像${NC}"
        bash "$SCRIPT_DIR/03_create_image.sh"
        ;;
    uboot)
        bash "$SCRIPT_DIR/01_build_uboot.sh"
        ;;
    rootfs)
        bash "$SCRIPT_DIR/02_build_rootfs.sh"
        ;;
    image)
        bash "$SCRIPT_DIR/03_create_image.sh"
        ;;
    flash)
        bash "$SCRIPT_DIR/04_flash_sdcard.sh"
        ;;
    *)
        echo -e "${RED}未知选项: $BUILD_TARGET${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    构建完成！                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
