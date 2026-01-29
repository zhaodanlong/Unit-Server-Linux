#!/bin/bash
#
# cleanup_disk.sh - 清理 Unit-Server 磁盘空间
# 用于解决 "No space left on device" 问题
#

echo "=== Unit-Server 磁盘清理脚本 ==="
echo ""

# 显示当前磁盘使用情况
echo "当前磁盘使用情况:"
df -h /
echo ""

# 1. 清理 apt 缓存
echo "清理 apt 缓存..."
apt-get clean 2>/dev/null || true
rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true

# 2. 清理旧的日志文件
echo "清理旧日志文件..."
journalctl --vacuum-size=10M 2>/dev/null || true
rm -rf /var/log/*.gz 2>/dev/null || true
rm -rf /var/log/*.1 2>/dev/null || true
rm -rf /var/log/journal/*/*.journal~ 2>/dev/null || true

# 3. 清理损坏的 journal 文件
echo "清理损坏的 journal 文件..."
rm -rf /var/log/journal/*/system.journal 2>/dev/null || true
rm -rf /var/log/journal/*/user-*.journal 2>/dev/null || true

# 4. 清理临时文件
echo "清理临时文件..."
rm -rf /tmp/* 2>/dev/null || true
rm -rf /var/tmp/* 2>/dev/null || true

# 5. 清理 dpkg 缓存
echo "清理 dpkg 缓存..."
rm -rf /var/cache/debconf/*.dat-old 2>/dev/null || true

# 6. 查找大文件
echo ""
echo "查找大文件 (>5MB):"
find / -xdev -type f -size +5M -exec ls -lh {} \; 2>/dev/null | head -20

echo ""
echo "清理完成！当前磁盘使用情况:"
df -h /
