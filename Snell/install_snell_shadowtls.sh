#!/bin/bash

# 定义颜色常量用于终端输出
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
plain='\033[0m'

# 日志文件路径
log_file="/var/log/snell_install.log"

# 打印并记录日志
log() {
    echo -e "$1" | tee -a "$log_file"
}

# 显示主菜单并读取用户选择
print_menu_and_read_choice() {
    log "${yellow}欢迎使用 Snell V4 和 Shadow TLS V3 安装脚本！请选择:${plain}"
    log "${green}1. 安装 Snell V4${plain}"
    log "${green}2. 安装 Snell V4 和 Shadow TLS V3${plain}"
    log "--------------------------------------------------"
    log "${red}3. 删除 Snell V4${plain}"
    log "--------------------------------------------------"
    log "${red}4. 删除 Shadow TLS V3${plain}"
    log "--------------------------------------------------"
    log "${blue}5. 更新脚本${plain}"
    log "--------------------------------------------------"
    log "${red}0. 退出脚本${plain}"
    read -p "请输入您的选择(0/1/2/3/4/5): " choice
}

# 安装前置条件，如 wget 和 unzip
install_prerequisites() {
    if ! command -v wget &> /dev/null || ! command -v unzip &> /dev/null; then
        log "${yellow}安装 wget 和 unzip...${plain}"
        sudo apt-get update
        sudo apt-get install -y wget unzip || { log "${red}安装 wget 和 unzip 失败。${plain}"; exit 1; }
    fi
}

# 验证端口号是否合法
validate_port() {
    if ! [[ $1 =~ ^[0-9]+$ ]] || [ "$1" -lt 1 ] || [ "$1" -gt 65535 ]; then
        log "${red}无效的端口号: $1${plain}"
        return 1
    fi
    return 0
}

# 配置 Snell 服务
configure_snell() {
    read -p "请选择监听 IP 地址 (1. ::0, 2. 0.0.0.0) [默认: 1]: " ip_choice
    case $ip_choice in
        2)
            listen_ip="0.0.0.0"
            ;;
        *)
            listen_ip="::0"
            ;;
    esac

    read -p "请输入监听端口 (默认值 54633): " listen_port
    listen_port=${listen_port:-54633}
    validate_port "$listen_port" || exit 1
    
    read -p "是否启用 IPv6 (true/false) [默认: true]: " ipv6
    ipv6=${ipv6:-true}
    if ! [[ "$ipv6" =~ ^(true|false)$ ]]; then
        log "${red}无效的 IPv6 选项: $ipv6${plain}"
        exit 1
    fi
    
    read -p "选择 obfs 模式 (off/http) [默认: off]: " obfs
    obfs=${obfs:-off}
    if ! [[ "$obfs" =~ ^(off|http)$ ]]; then
        log "${red}无效的 obfs 模式: $obfs${plain}"
        exit 1
    fi

    read -p "请输入 PSK (默认值 5463364@5463364): " psk
    psk=${psk:-5463364@5463364}

    sudo tee /etc/snell-server.conf > /dev/null <<EOF
[snell-server]
listen = $listen_ip:$listen_port
psk = $psk
ipv6 = $ipv6
obfs = $obfs
EOF

    log "${green}Snell 配置文件已生成: /etc/snell-server.conf${plain}"
}

# 安装 Snell 服务
install_snell() {
    if sudo systemctl is-active --quiet snell; then
        log "${red}Snell 服务已在运行，取消安装。${plain}"
        exit 0
    fi

    log "${yellow}开始安装 Snell V4...${plain}"

    SNELL_VERSION="v4.0.1"
    SNELL_URL="https://dl.nssurge.com/snell/snell-server-$SNELL_VERSION-linux-amd64.zip"
    SNELL_BIN="/usr/local/bin/snell-server"
    
    wget $SNELL_URL -O snell-server.zip || { log "${red}下载 Snell 失败。${plain}"; exit 1; }
    sudo unzip -o snell-server.zip -d /usr/local/bin || { log "${red}解压 Snell 失败。${plain}"; exit 1; }
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

    log "${green}Snell 安装并启动完成。${plain}"
}

# 删除 Snell 服务
remove_snell() {
    log "${yellow}开始删除 Snell V4...${plain}"

    sudo systemctl stop snell
    sudo systemctl disable snell
    sudo rm -f /lib/systemd/system/snell.service
    sudo rm -f /usr/local/bin/snell-server
    sudo rm -f /etc/snell-server.conf
    sudo systemctl daemon-reload

    log "${green}Snell 已删除。${plain}"
}

# 安装 Docker 和 Docker Compose
install_docker() {
    if ! command -v docker &> /dev/null || ! command -v docker compose &> /dev/null; then
        log "${yellow}安装 Docker 和 Docker Compose...${plain}"
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose || { log "${red}安装 Docker 和 Docker Compose 失败。${plain}"; exit 1; }
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
}

# 配置并安装 Shadow TLS 服务
install_shadow_tls() {
    log "${yellow}开始安装 Shadow TLS V3...${plain}"

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

    (cd /dockers/shadow-tls-v3 && sudo docker compose up -d)

    log "${green}Shadow TLS 安装并启动完成。${plain}"
}

# 删除 Shadow TLS 服务
remove_shadow_tls() {
    log "${yellow}开始删除 Shadow TLS V3...${plain}"

    (cd /dockers/shadow-tls-v3 && sudo docker compose down --rmi all)
    sudo rm -rf /dockers/shadow-tls-v3

    log "${green}Shadow TLS 已删除。${plain}"
}

# 更新脚本
update_script() {
    log "${yellow}开始更新脚本...${plain}"
    script_url="https://raw.githubusercontent.com/Spades-X/Script/main/Snell/install_snell_shadowtls.sh"
    script_path=$(realpath "$0")
    wget -O "$script_path" "$script_url" || { log "${red}更新脚本失败。${plain}"; exit 1; }
    chmod +x "$script_path"
    log "${green}脚本更新完成，请重新运行脚本。${plain}"
    exit
