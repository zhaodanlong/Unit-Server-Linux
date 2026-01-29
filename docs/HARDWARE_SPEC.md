# Unit-Server 硬件规格与设备清单

## 📋 硬件概览

Unit-Server 是基于 Quark 核心板（Allwinner H3）的超迷你 Linux 卡片电脑。

| 项目 | 规格 |
|------|------|
| SoC | Allwinner H3 (4x Cortex-A7 @ 1.2GHz) |
| 内存 | 512MB DDR3 |
| 存储 | TF 卡 (microSD) |
| 显示 | 1.14" IPS LCD (240x135) |
| 无线 | WiFi 802.11n + Bluetooth 4.0 |
| 接口 | USB Type-C (串口/OTG 二合一) |
| 电源 | 锂电池供电，Type-C 充电 |
| 尺寸 | 超迷你 |

---

## 🔌 硬件模块详细清单

### 1. CORE - Quark 核心板

核心板通过邮票孔连接，引出以下资源：

| 接口 | 数量 | 说明 |
|------|------|------|
| USB | 4 | USB 2.0 Host |
| I2C | 2 | I2C0, I2C1 |
| SPI | 2 | SPI0, SPI1 |
| UART | 3 | UART0, UART1, UART2 |
| SDIO | 1 | SD/TF 卡 |
| HDMI | 1 | 未引出 |
| CSI | 1 | 摄像头接口，未引出 |
| GPIO | 多个 | 部分引出 |

### 2. LCD - 1.14" IPS 显示屏

| 参数 | 值 |
|------|-----|
| 型号 | ST7789VW |
| 分辨率 | 240 x 135 |
| 接口 | SPI (SPI0) |
| 驱动 | fb_st7789vw (fbtft) |

**引脚连接：**

| LCD 引脚 | H3 GPIO | 说明 |
|----------|---------|------|
| SDA (MOSI) | SPI0_MOSI | SPI 数据 |
| SCL (CLK) | SPI0_CLK | SPI 时钟 |
| CS | SPI0_CS | 片选 |
| DC | GPIO12 (PA12) | 数据/命令选择 |
| RES | GPIO11 (PA11) | 复位 |
| LEDK | - | 背光 (常亮或 PWM) |

**状态：✅ 已使用**

### 3. WiFi/蓝牙 - RTL8723BU

| 参数 | 值 |
|------|-----|
| 芯片 | RTL8723BU |
| WiFi | 802.11 b/g/n 2.4GHz |
| 蓝牙 | Bluetooth 4.0 BLE |
| 接口 | USB |

**引脚连接：**

| RTL8723BU | 连接 |
|-----------|------|
| D+ | USB-WIFI-DP |
| D- | USB-WIFI-DM |
| VCC | VDD_3V3 |

**状态：**
- WiFi: ✅ 已使用
- 蓝牙: ❌ 未使用（需配置 hciattach）

### 4. TF-CARD - SD 卡槽

| 参数 | 值 |
|------|-----|
| 接口 | SDIO (MMC1) |
| 设备 | /dev/mmcblk1 |

**引脚连接：**

| SD 卡 | H3 |
|-------|-----|
| DATA0-3 | SDMMC_D0-D3 |
| CMD | SDMMC_CMD |
| CLK | SDMMC_CLK |
| DET | SDMMC_DET |

**状态：✅ 已使用**

### 5. USB Type-C - 双功能接口

**创新设计：** 通过 Type-C 正反插实现两种功能！

| 插入方向 | 功能 | 芯片 | 设备 |
|----------|------|------|------|
| 正插 | USB 串口 | CP2102 | /dev/ttyUSB0 (主机侧) |
| 反插 | USB OTG | H3 USB0 | USB 设备/主机 |

**CP2102 连接：**

| CP2102 | 连接 |
|--------|------|
| TXD | CP_Tx → UART |
| RXD | CP_Rx → UART |
| D+ | USB-CP-DP |
| D- | USB-CP-DM |

**H3 USB0 连接：**

| H3 USB0 | Type-C |
|---------|--------|
| USB0-DP | D+ |
| USB0-DM | D- |
| USB0-OTGID | OTGID |

**状态：✅ CP2102 串口已使用，USB OTG 可用**

### 6. POWER - 电源管理

| 功能 | 说明 |
|------|------|
| 输入 | Type-C 5V 或锂电池 |
| 锂电池充电 | 支持 VBAT 充放电管理 |
| 电源指示 | PWR_STAT LED |

**电源引脚：**

| 信号 | 说明 |
|------|------|
| VBAT_IN | 电池输入 |
| VBAT_CHARGE | 充电控制 |
| VDD_USB_5V | USB 5V |
| VDD_3V3 | 3.3V 供电 |
| EN_3V3 | 3.3V 使能 |

**状态：✅ 已使用**

### 7. MIC - 麦克风

| 参数 | 值 |
|------|-----|
| 类型 | 驻极体麦克风 |
| 接口 | H3 内置 Audio Codec |

**引脚连接：**

| MIC | H3 Audio Codec |
|-----|----------------|
| MIC+ | MICIN1P |
| MIC- | MICIN1N |

**说明：** 连接到 H3 内置音频 Codec 的麦克风输入通道 1，为差分输入。

**状态：⚠️ 硬件就绪，需 ALSA 配置**

### 8. KEY - 用户按键

| 按键 | H3 引脚 | GPIO 编号 | 说明 |
|------|---------|-----------|------|
| KEY1 | PA19 | GPIO 19 | 用户按键 1 |
| KEY2 | PA18 | GPIO 18 | 用户按键 2 |

**电路设计：** KEY1 和 KEY2 连接到 VDD_3V3，按下接地（低电平有效）。

**状态：❌ 未使用**

### 9. LED - 指示灯

| LED | H3 引脚 | GPIO 编号 | 说明 |
|-----|---------|-----------|------|
| STATUS_LED (D1) | PA10 | GPIO 10 | 状态指示灯 |
| USR_LED (D2) | PG11 | GPIO 203 | 用户指示灯 |

**电路设计：** LED 高电平点亮 (GPIO_ACTIVE_HIGH)

**状态：❌ 未使用**

---

## 📊 硬件使用状态总结

### ✅ 已使用

| 硬件 | 驱动/设备 |
|------|-----------|
| H3 CPU | 4核心全部启用 |
| 512MB RAM | 已使用 |
| LCD (ST7789VW) | /dev/fb1, fbtft |
| WiFi (RTL8723BU) | wlx*, 8723bu.ko |
| TF 卡 | /dev/mmcblk1 |
| CP2102 串口 | /dev/ttyS0 (控制台) |
| 音频 Codec | H3 Audio Codec |
| RTC | rtc-sun6i |

### ❌ 未使用

| 硬件 | 如何启用 |
|------|----------|
| 蓝牙 (RTL8723BU) | `hciattach` 配置 |
| KEY1/KEY2 按键 | GPIO 驱动或 gpio-keys |
| LED 指示灯 | GPIO 控制或 LED 子系统 |
| USB OTG | Type-C 反插使用 |
| MIC 麦克风 | ALSA 配置录音 |

---

## 🔧 启用未使用硬件

### 启用蓝牙

```bash
# 安装蓝牙工具
apt install bluetooth bluez

# 加载蓝牙固件（如需要）
# RTL8723BU 蓝牙通过 USB HCI 接口

# 检查蓝牙设备
hciconfig -a
```

### 启用按键

**方法 1: 通过 sysfs 读取**

```bash
# 导出 GPIO
echo 19 > /sys/class/gpio/export  # KEY1
echo 18 > /sys/class/gpio/export  # KEY2

# 设置为输入
echo in > /sys/class/gpio/gpio19/direction
echo in > /sys/class/gpio/gpio18/direction

# 读取按键状态 (0=按下, 1=释放)
cat /sys/class/gpio/gpio19/value  # KEY1
cat /sys/class/gpio/gpio18/value  # KEY2
```

**方法 2: 设备树 gpio-keys (推荐)**

```dts
gpio-keys {
    compatible = "gpio-keys";
    
    key1 {
        label = "KEY1";
        linux,code = <KEY_F1>;
        gpios = <&pio 0 19 GPIO_ACTIVE_LOW>;  /* PA19 */
    };
    
    key2 {
        label = "KEY2";
        linux,code = <KEY_F2>;
        gpios = <&pio 0 18 GPIO_ACTIVE_LOW>;  /* PA18 */
    };
};
```

### 启用 LED

```bash
# STATUS_LED (PA10 = GPIO 10)
echo 10 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio10/direction
echo 1 > /sys/class/gpio/gpio10/value   # 点亮
echo 0 > /sys/class/gpio/gpio10/value   # 熄灭

# USR_LED (PG11 = GPIO 203)
echo 203 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio203/direction
echo 1 > /sys/class/gpio/gpio203/value  # 点亮
echo 0 > /sys/class/gpio/gpio203/value  # 熄灭
```

**LED 闪烁脚本：**

```bash
#!/bin/bash
# 心跳闪烁 STATUS_LED
while true; do
    echo 1 > /sys/class/gpio/gpio10/value
    sleep 0.5
    echo 0 > /sys/class/gpio/gpio10/value
    sleep 0.5
done
```

### 测试麦克风

```bash
# 查看音频设备
arecord -l

# 录音测试 (H3 Codec 通常是 card 2)
arecord -D hw:2,0 -f S16_LE -r 16000 -c 1 -d 5 test.wav

# 播放测试
aplay test.wav

# 调整麦克风音量
alsamixer -c 2
```

---

## 📐 GPIO 引脚映射

| 功能 | H3 引脚 | GPIO 编号 | 方向 | 电平 |
|------|---------|-----------|------|------|
| LCD DC | PA12 | 12 | OUT | - |
| LCD RES | PA11 | 11 | OUT | - |
| KEY1 | PA19 | 19 | IN | 低有效 |
| KEY2 | PA18 | 18 | IN | 低有效 |
| STATUS_LED | PA10 | 10 | OUT | 高有效 |
| USR_LED | PG11 | 203 | OUT | 高有效 |

**GPIO 编号计算：** `GPIO = 端口号 × 32 + 引脚号`

| 端口 | 编号 | 范围 |
|------|------|------|
| PA | 0 | GPIO 0-31 |
| PB | 1 | GPIO 32-63 |
| PC | 2 | GPIO 64-95 |
| PD | 3 | GPIO 96-127 |
| PE | 4 | GPIO 128-159 |
| PF | 5 | GPIO 160-191 |
| PG | 6 | GPIO 192-223 |
| PL | 0 (r_pio) | 特殊 |

---

*文档版本：2026-01-29*
*项目：Unit-Server-Linux*
