#!/bin/bash
# ============================================================
# 依赖安装脚本
# 安装构建 Linux 系统所需的所有依赖
# ============================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  依赖安装脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

echo -e "\n${YELLOW}更新软件包列表...${NC}"
apt-get update

echo -e "\n${YELLOW}安装基础构建工具...${NC}"
apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    git \
    wget \
    curl

echo -e "\n${YELLOW}安装交叉编译工具链...${NC}"
apt-get install -y \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf

echo -e "\n${YELLOW}安装 U-Boot 构建依赖...${NC}"
apt-get install -y \
    bison \
    flex \
    libssl-dev \
    python3 \
    python3-dev \
    python3-setuptools \
    swig \
    device-tree-compiler

echo -e "\n${YELLOW}安装内核构建依赖...${NC}"
apt-get install -y \
    bc \
    libncurses5-dev \
    libncursesw5-dev \
    u-boot-tools

echo -e "\n${YELLOW}安装 rootfs 构建依赖...${NC}"
apt-get install -y \
    debootstrap \
    qemu-user-static \
    binfmt-support

echo -e "\n${YELLOW}安装镜像创建工具...${NC}"
apt-get install -y \
    parted \
    dosfstools \
    e2fsprogs \
    kpartx

echo -e "\n${YELLOW}安装串口工具...${NC}"
apt-get install -y \
    picocom \
    minicom

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  依赖安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n已安装的关键工具版本:"
echo -n "  GCC: "
gcc --version | head -1
echo -n "  ARM GCC: "
arm-linux-gnueabihf-gcc --version | head -1
echo -n "  debootstrap: "
debootstrap --version
