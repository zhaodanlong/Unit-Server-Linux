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
| 接口 | 模拟音频 (MICN/MICP) |

**引脚连接：**

| MIC | H3 |
|-----|-----|
| MICP | MICP (音频正) |
| MICN | MICN (音频负) |

**状态：❓ 需确认（H3 Audio Codec 已加载）**

### 8. KEY - 用户按键

| 按键 | GPIO | 说明 |
|------|------|------|
| KEY1 | GPIO (需确认) | 用户按键 1 |
| KEY2 | GPIO (需确认) | 用户按键 2 |

**原理图显示：** KEY1 和 KEY2 连接到 VDD_3V3，按下接地。

**状态：❌ 未使用**

### 9. LED - 指示灯

| LED | 信号 | 说明 |
|-----|------|------|
| D1 | STATUS_LED | 状态指示灯 |
| D2 | USR_LED (PWR_STAT) | 用户/电源指示灯 |
| D3 | - | 其他指示灯 |

**状态：❌ 未使用（PWR_STAT 可能硬件控制）**

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

### 启用按键 (gpio-keys)

需要在设备树中添加：

```dts
gpio-keys {
    compatible = "gpio-keys";
    
    key1 {
        label = "KEY1";
        linux,code = <KEY_F1>;
        gpios = <&pio X XX GPIO_ACTIVE_LOW>;
    };
    
    key2 {
        label = "KEY2";
        linux,code = <KEY_F2>;
        gpios = <&pio X XX GPIO_ACTIVE_LOW>;
    };
};
```

### 启用 LED

```bash
# 通过 sysfs 控制 GPIO
echo XX > /sys/class/gpio/export
echo out > /sys/class/gpio/gpioXX/direction
echo 1 > /sys/class/gpio/gpioXX/value  # 点亮
echo 0 > /sys/class/gpio/gpioXX/value  # 熄灭
```

### 测试麦克风

```bash
# 录音测试
arecord -D hw:2,0 -f S16_LE -r 16000 -c 1 test.wav

# 播放测试
aplay test.wav
```

---

## 📐 GPIO 引脚映射

> 注：具体 GPIO 编号需要根据原理图确认

| 功能 | GPIO | 计算方法 |
|------|------|----------|
| LCD DC | GPIO12 | PA12 = 0*32 + 12 = 12 |
| LCD RES | GPIO11 | PA11 = 0*32 + 11 = 11 |
| KEY1 | TBD | 待确认 |
| KEY2 | TBD | 待确认 |
| STATUS_LED | TBD | 待确认 |
| USR_LED | TBD | 待确认 |

**GPIO 编号计算：** `GPIO = 端口号 * 32 + 引脚号`
- PA = 0, PB = 1, PC = 2, PD = 3, PE = 4, PF = 5, PG = 6

---

*文档版本：2026-01-29*
*项目：Unit-Server-Linux*
