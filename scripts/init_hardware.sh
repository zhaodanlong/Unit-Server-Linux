#!/bin/bash
#
# init_hardware.sh - 初始化 Unit-Server 额外硬件
#
# 功能：初始化按键、LED 等 GPIO 设备
#

echo "=== Unit-Server 硬件初始化 ==="

# GPIO 定义
KEY1_GPIO=19      # PA19
KEY2_GPIO=18      # PA18
STATUS_LED=10     # PA10
USR_LED=203       # PG11

# 导出 GPIO
export_gpio() {
    local gpio=$1
    if [ ! -d "/sys/class/gpio/gpio$gpio" ]; then
        echo $gpio > /sys/class/gpio/export 2>/dev/null
        sleep 0.1
    fi
}

# 初始化按键 (输入)
init_keys() {
    echo "初始化按键..."
    
    export_gpio $KEY1_GPIO
    export_gpio $KEY2_GPIO
    
    echo "in" > /sys/class/gpio/gpio$KEY1_GPIO/direction 2>/dev/null
    echo "in" > /sys/class/gpio/gpio$KEY2_GPIO/direction 2>/dev/null
    
    echo "  KEY1 (GPIO $KEY1_GPIO): $(cat /sys/class/gpio/gpio$KEY1_GPIO/value 2>/dev/null || echo 'N/A')"
    echo "  KEY2 (GPIO $KEY2_GPIO): $(cat /sys/class/gpio/gpio$KEY2_GPIO/value 2>/dev/null || echo 'N/A')"
}

# 初始化 LED (输出)
init_leds() {
    echo "初始化 LED..."
    
    export_gpio $STATUS_LED
    export_gpio $USR_LED
    
    echo "out" > /sys/class/gpio/gpio$STATUS_LED/direction 2>/dev/null
    echo "out" > /sys/class/gpio/gpio$USR_LED/direction 2>/dev/null
    
    # 默认关闭
    echo 0 > /sys/class/gpio/gpio$STATUS_LED/value 2>/dev/null
    echo 0 > /sys/class/gpio/gpio$USR_LED/value 2>/dev/null
    
    echo "  STATUS_LED (GPIO $STATUS_LED): 已初始化"
    echo "  USR_LED (GPIO $USR_LED): 已初始化"
}

# LED 控制函数
led_on() {
    local led=$1
    echo 1 > /sys/class/gpio/gpio$led/value 2>/dev/null
}

led_off() {
    local led=$1
    echo 0 > /sys/class/gpio/gpio$led/value 2>/dev/null
}

led_blink() {
    local led=$1
    local count=${2:-3}
    for i in $(seq 1 $count); do
        led_on $led
        sleep 0.2
        led_off $led
        sleep 0.2
    done
}

# 读取按键状态
read_key() {
    local key=$1
    cat /sys/class/gpio/gpio$key/value 2>/dev/null
}

# 主函数
main() {
    case "$1" in
        init)
            init_keys
            init_leds
            echo "✓ 硬件初始化完成"
            ;;
        led-on)
            led_on ${2:-$STATUS_LED}
            ;;
        led-off)
            led_off ${2:-$STATUS_LED}
            ;;
        led-blink)
            led_blink ${2:-$STATUS_LED} ${3:-3}
            ;;
        key-read)
            echo "KEY1: $(read_key $KEY1_GPIO)"
            echo "KEY2: $(read_key $KEY2_GPIO)"
            ;;
        status)
            echo "=== GPIO 状态 ==="
            echo "KEY1 (GPIO $KEY1_GPIO): $(read_key $KEY1_GPIO)"
            echo "KEY2 (GPIO $KEY2_GPIO): $(read_key $KEY2_GPIO)"
            echo "STATUS_LED (GPIO $STATUS_LED): $(cat /sys/class/gpio/gpio$STATUS_LED/value 2>/dev/null || echo 'N/A')"
            echo "USR_LED (GPIO $USR_LED): $(cat /sys/class/gpio/gpio$USR_LED/value 2>/dev/null || echo 'N/A')"
            ;;
        demo)
            echo "=== 硬件演示 ==="
            init_keys
            init_leds
            echo "闪烁 STATUS_LED..."
            led_blink $STATUS_LED 3
            echo "闪烁 USR_LED..."
            led_blink $USR_LED 3
            echo "等待按键... (按 KEY1 或 KEY2，Ctrl+C 退出)"
            while true; do
                k1=$(read_key $KEY1_GPIO)
                k2=$(read_key $KEY2_GPIO)
                if [ "$k1" = "0" ]; then
                    echo "KEY1 按下!"
                    led_on $STATUS_LED
                    sleep 0.3
                    led_off $STATUS_LED
                fi
                if [ "$k2" = "0" ]; then
                    echo "KEY2 按下!"
                    led_on $USR_LED
                    sleep 0.3
                    led_off $USR_LED
                fi
                sleep 0.1
            done
            ;;
        *)
            echo "用法: $0 {init|led-on|led-off|led-blink|key-read|status|demo}"
            echo ""
            echo "命令:"
            echo "  init       - 初始化所有 GPIO"
            echo "  led-on [gpio]   - 点亮 LED (默认 STATUS_LED)"
            echo "  led-off [gpio]  - 熄灭 LED"
            echo "  led-blink [gpio] [次数] - 闪烁 LED"
            echo "  key-read   - 读取按键状态"
            echo "  status     - 显示所有 GPIO 状态"
            echo "  demo       - 硬件演示 (LED + 按键)"
            echo ""
            echo "GPIO 定义:"
            echo "  KEY1 = GPIO $KEY1_GPIO (PA19)"
            echo "  KEY2 = GPIO $KEY2_GPIO (PA18)"
            echo "  STATUS_LED = GPIO $STATUS_LED (PA10)"
            echo "  USR_LED = GPIO $USR_LED (PG11)"
            ;;
    esac
}

main "$@"
