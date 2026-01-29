# U-Boot 启动脚本
# 重新编译: mkimage -C none -A arm -T script -d boot.cmd boot.scr
#
# Unit-Server Linux 启动配置
# 基于 Allwinner H3 + ST7789VW SPI LCD

echo "Unit-Server Linux booting..."

# 文件系统检查修复
setenv fsck.repair yes

# 文件名配置
setenv ramdisk rootfs.cpio.gz
setenv kernel zImage
setenv dtb sun8i-h3-unit-server.dtb

# 内存地址配置
setenv env_addr 0x45000000
setenv kernel_addr 0x46000000
setenv ramdisk_addr 0x47000000
setenv dtb_addr 0x48000000

# 从 boot 分区加载文件
fatload mmc 0 ${kernel_addr} ${kernel}
fatload mmc 0 ${ramdisk_addr} ${ramdisk}
setenv ramdisk_size ${filesize}
fatload mmc 0 ${dtb_addr} ${dtb}

# 设置设备树
fdt addr ${dtb_addr}

# 控制台映射到 SPI LCD (fb0)
setenv fbcon map:0

# 内核启动参数
# - console=ttyS0,115200: 串口控制台
# - console=tty0: LCD 控制台
# - root=/dev/mmcblk0p2: SD 卡根分区
# - rootfstype=ext4: 根文件系统类型
# - rw: 可读写挂载
# - rootwait: 等待根设备就绪
# - panic=10: 内核崩溃后 10 秒重启
# - fbcon=${fbcon}: 控制台映射到 fb0 (SPI LCD)
setenv bootargs console=ttyS0,115200 console=tty0 root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair} panic=10 fbcon=${fbcon}

# 启动内核
bootz ${kernel_addr} ${ramdisk_addr}:${ramdisk_size} ${dtb_addr}
