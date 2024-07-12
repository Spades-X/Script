#!/bin/bash

set -eu

# 定义颜色常量
color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_blue='\033[0;34m'
color_plain='\033[0m'

# 日志文件路径
log_file="/var/log/snell_install.log"

# 记录日志
log() {
    echo -e "$1" | tee -a "$log_file"
}

# 验证端口号有效性
validate_port() {
    local port="$1"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log "${color_red}无效的端口号: $port${color_plain}"
        return 1
    fi
    return 0
}

# 安装前置条件
install_prerequisites() {
    if ! command -v wget &> /dev/null || ! command -v unzip &> /dev/null; then
        log "${color_yellow}安装 wget 和 unzip...${color_plain}"
        sudo apt-get update
        sudo apt-get install -y wget unzip || { log "${color_red}安装 wget 和 unzip 失败。${color_plain}"; exit 1; }
    fi
}

# 安装Snell服务
install_snell() {
    if sudo systemctl is-active --quiet snell; then
        log "${color_red}Snell 服务已在运行，取消安装。${color_plain}"
        exit 0
    fi

    log "${color_yellow}开始安装 Snell V4...${color_plain}"

    SNELL_VERSION="v4.0.1"
    SNELL_URL="https://dl.nssurge.com/snell/snell-server-$SNELL_VERSION-linux-amd64.zip"
    SNELL_BIN="/usr/local/bin/snell-server"
    
    wget $SNELL_URL -O snell-server.zip || { log "${color_red}下载 Snell 失败。${color_plain}"; exit 1; }
    sudo unzip -o snell-server.zip -d /usr/local/bin || { log "${color_red}解压 Snell 失败。${color_plain}"; exit 1; }
    rm snell-server.zip

    configure_snell

    sudo tee /lib/systemd/system/snell.service > /dev/null <<EOF
[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
LimitNOFILE=32768
ExecStart=$SNELL_BIN -c /etc/snell-server.conf

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start snell
    sudo systemctl enable snell

    log "${color_green}Snell 安装并启动完成。${color_plain}"
}

# 删除Snell服务
remove_snell() {
    log "${color_yellow}开始删除 Snell V4...${color_plain}"

    sudo systemctl stop snell
    sudo systemctl disable snell
    sudo rm -f /lib/systemd/system/snell.service
    sudo rm -f /usr/local/bin/snell-server
    sudo rm -f /etc/snell-server.conf
    sudo systemctl daemon-reload

    log "${color_green}Snell 已删除。${color_plain}"
}

# 安装Docker和Docker Compose
install_docker() {
    if ! command -v docker &> /dev/null || ! command -v docker compose &> /dev/null; then
        log "${color_yellow}安装 Docker 和 Docker Compose...${color_plain}"
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose || { log "${color_red}安装 Docker 和 Docker Compose 失败。${color_plain}"; exit 1; }
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
}

# 配置并安装Shadow TLS服务
install_shadow_tls() {
    log "${color_yellow}开始安装 Shadow TLS V3...${color_plain}"

    install_docker

    sudo mkdir -p /dockers/shadow-tls-v3

    shadow_listen_ip="$listen_ip"
    read -p "请输入 Shadow TLS 监听端口 (默认值 54321): " shadow_listen_port
    shadow_listen_port=${shadow_listen_port:-54321}
    validate_port "$shadow_listen_port" || exit 1
    
    if [ "$listen_ip" = "0.0.0.0" ]; then
        shadow_server_ip="127.0.0.1"
    else
        shadow_server_ip="::1"
    fi
    shadow_server="$shadow_server_ip:$listen_port"

    read -p "请输入 Shadow TLS 的 TLS 地址 (默认值 captive.apple.com:443): " shadow_tls
    shadow_tls=${shadow_tls:-captive.apple.com:443}

    read -p "请输入 Shadow TLS 密码 (默认值 5463364@5463364): " shadow_password
    shadow_password=${shadow_password:-5463364@5463364}

    sudo tee /dockers/shadow-tls-v3/docker-compose.yml > /dev/null <<EOF
version: "3.16"
services:
  shadow-tls:
    image: ghcr.io/ihciah/shadow-tls:latest
    container_name: shadow-tls-v3
    restart: always
    network_mode: "host"
    environment:
      - MODE=server
      - V3=1
      - LISTEN=$shadow_listen_ip:$shadow_listen_port
      - SERVER=$shadow_server
      - TLS=$shadow_tls
      - PASSWORD=$shadow_password
EOF

    (cd /dockers/shadow-tls-v3 && sudo docker-compose up -d)

    log "${color_green}Shadow TLS 安装并启动完成。${color_plain}"
}

# 删除Shadow TLS服务
remove_shadow_tls() {
    log "${color_yellow}开始删除 Shadow TLS V3...${color_plain}"

    (cd /dockers/shadow-tls-v3 && sudo docker-compose down --rmi all)
    sudo rm -rf /dockers/shadow-tls-v3

    log "${color_green}Shadow TLS 已删除。${color_plain}"

    # 同时删除 Snell 服务
    remove_snell
}

# 更新脚本
update_script() {
    log "${color_yellow}开始更新脚本...${color_plain}"
    script_url="https://raw.githubusercontent.com/Spades-X/Script/main/Snell/install_snell_shadowtls.sh"
    script_path=$(realpath "$0")
    wget -O "$script_path" "$script_url" || { log "${color_red}更新脚本失败。${color_plain}"; exit 1; }
    chmod +x "$script_path"
    log "${color_green}脚本更新完成，请重新运行脚本。${color_plain}"
    exit 0
}

# 打印菜单并读取用户选择
print_menu_and_read_choice() {
    log "${color_yellow}欢迎使用 Snell V4 和 Shadow TLS V3 安装脚本！请选择:${color_plain}"
    log "--------------------------------------------------"
    log "${color_green}1. 安装 Snell V4${color_plain}"
    log "${color_green}2. 安装 Snell V4 和 Shadow TLS V3${color_plain}"
    log "--------------------------------------------------"
    log "${color_red}3. 删除 Snell V4${color_plain}"
    log "${color_red}4. 删除 Shadow TLS V3${color_plain}"
    log "--------------------------------------------------"
    log "${color_blue}5. 更新脚本${color_plain}"
    log "--------------------------------------------------"
    log "${color_red}0. 退出脚本${color_plain}"
    read -p "请输入您的选择(0/1/2/3/4/5): " selected_option
}

# 验证用户输入的选择
validate_choice() {
    if ! [[ $1 =~ ^[0-5]$ ]]; then
        log "${color_red}无效的选择，只能输入0-5之间的数字。${color_plain}"
        return 1
    fi
    return 0
}

# 根据用户选择执行相应操作
select_action() {
    case "$1" in
        1)
            install_prerequisites
            install_snell
            ;;
        2)
            install_prerequisites
            install_snell
            install_shadow_tls
            ;;
        3)
            remove_snell
            ;;
        4)
            remove_shadow_tls
            ;;
        5)
            update_script
            ;;
        0)
            log "${color_red}退出脚本${color_plain}"
            exit 0
            ;;
        *)
            log "${color_red}无效的选择${color_plain}"
            ;;
    esac
}

# 主流程
print_menu_and_read_choice
if validate_choice "$selected_option"; then
    select_action "$selected_option"
else
    log "${color_red}无效的选择，退出脚本。${color_plain}"
fi
log "${color_green}操作完成！${color_plain}"
