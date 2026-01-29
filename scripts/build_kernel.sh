#!/bin/bash
#
# Unit-Server 内核编译脚本
#

set -e

KERNEL_SRC="${KERNEL_SRC:-/tmp/linux-kernel}"
TOOLCHAIN="$HOME/tools/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

export PATH="$TOOLCHAIN:$PATH"
export CROSS_COMPILE=arm-none-linux-gnueabihf-
export ARCH=arm

echo "=== Unit-Server 内核编译 ==="
echo "内核源码: $KERNEL_SRC"
echo "工具链: $TOOLCHAIN"

# 检查工具链
if ! command -v arm-none-linux-gnueabihf-gcc &> /dev/null; then
    echo "错误: 找不到交叉编译工具链"
    echo "请下载 ARM GCC 10.3 工具链到 ~/tools/"
    exit 1
fi

cd "$KERNEL_SRC"

# 应用配置
if [ -f "$PROJECT_DIR/kernel/config/unit-server_defconfig" ]; then
    echo "=== 应用 Unit-Server 配置 ==="
    cp "$PROJECT_DIR/kernel/config/unit-server_defconfig" .config
    make olddefconfig
fi

# 应用补丁
if [ -d "$PROJECT_DIR/kernel/patches" ]; then
    echo "=== 应用补丁 ==="
    for patch in "$PROJECT_DIR/kernel/patches"/*.patch; do
        if [ -f "$patch" ]; then
            echo "应用: $(basename "$patch")"
            patch -p1 -N < "$patch" || true
        fi
    done
fi

# 复制设备树
if [ -f "$PROJECT_DIR/kernel/dts/sun8i-h3-unit-server.dts" ]; then
    echo "=== 复制设备树 ==="
    cp "$PROJECT_DIR/kernel/dts/sun8i-h3-unit-server.dts" arch/arm/boot/dts/
fi

# 编译
echo "=== 编译内核 ==="
make -j$(nproc) zImage

echo "=== 编译模块 ==="
make -j$(nproc) modules

echo "=== 编译设备树 ==="
make dtbs

echo ""
echo "=== 编译完成 ==="
echo "内核: $KERNEL_SRC/arch/arm/boot/zImage"
echo "设备树: $KERNEL_SRC/arch/arm/boot/dts/sun8i-h3-unit-server.dtb"
