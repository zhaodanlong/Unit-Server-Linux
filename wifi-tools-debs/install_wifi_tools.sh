#!/bin/bash
# WiFi 工具安装脚本
# 在 Unit-Server 上运行

echo "=== 安装 WiFi 工具 ==="

# 安装顺序很重要（先依赖后主包）
PACKAGES=(
    libsystemd0.deb
    libdbus-1-3.deb
    libnl-3-200.deb
    libnl-genl-3-200.deb
    libnl-route-3-200.deb
    libpcsclite1.deb
    libreadline8.deb
    libssl1.1.deb
    libiw30.deb
    wireless-tools.deb
    iw.deb
    wpasupplicant.deb
)

cd /root/wifi-tools

for pkg in "${PACKAGES[@]}"; do
    if [ -f "$pkg" ]; then
        echo "安装 $pkg..."
        dpkg -i "$pkg" 2>/dev/null || dpkg -i --force-depends "$pkg"
    fi
done

echo ""
echo "=== 修复依赖 ==="
apt-get install -f -y 2>/dev/null || true

echo ""
echo "=== 验证安装 ==="
which wpa_supplicant && echo "✓ wpa_supplicant 已安装"
which iw && echo "✓ iw 已安装"
which iwconfig && echo "✓ iwconfig 已安装"

echo ""
echo "=== 完成 ==="
