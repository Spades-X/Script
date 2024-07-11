#!/bin/bash

# 检查 Snell 服务是否正在运行
if sudo systemctl is-active --quiet snell; then
    echo "Snell 服务已在运行，取消安装。"
    exit 0
fi

# 打印欢迎信息并显示选项
echo "欢迎使用 Snell 和 Shadow TLS 安装脚本！请选择:"
echo "1. 安装 Snell"
echo "2. 安装 Snell 和 Shadow TLS"
echo "3. 退出脚本"
read -p "请输入您的选择(1/2/3): " choice

install_prerequisites() {
    if ! command -v wget &> /dev/null || ! command -v unzip &> /dev/null; then
        echo "安装 wget 和 unzip..."
        sudo apt-get update
        sudo apt-get install -y wget unzip
    fi
}

install_snell() {
    echo "开始安装 Snell..."
    
    # 下载并安装 Snell
    wget https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip
    sudo unzip -o snell-server-v4.0.1-linux-amd64.zip -d /usr/local/bin

    # 创建配置文件
    echo -e "[snell-server]\nlisten = 0.0.0.0:11807\npsk = AijHCeos15IvqDZTb1cJMX5GcgZzIVE\nipv6 = false\nobfs = off" | sudo tee /etc/snell-server.conf

    # 配置 Systemd 服务文件
    echo -e "[Unit]\nDescription=Snell Proxy Service\nAfter=network.target\n\n[Service]\nType=simple\nUser=nobody\nGroup=nogroup\nLimitNOFILE=32768\nExecStart=/usr/local/bin/snell-server -c /etc/snell-server.conf\n\n[Install]\nWantedBy=multi-user.target" | sudo tee /lib/systemd/system/snell.service

    # 启动和启用 Snell 服务
    sudo systemctl start snell
    sudo systemctl enable snell
}

install_docker() {
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        echo "安装 Docker 和 Docker Compose..."
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
}

install_shadow_tls() {
    echo "开始安装 Shadow TLS..."

    # 安装 Docker 和 Docker Compose
    install_docker

    # 创建 dockers 文件夹和 shadow-tls-v3 文件夹
    sudo mkdir -p /dockers/shadow-tls-v3

    # 创建 docker-compose.yml
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
      - LISTEN=0.0.0.0:54321
      - SERVER=127.0.0.1:11807
      - TLS=captive.apple.com:443
      - PASSWORD=5463364@5463364
EOF

    # 启动 Docker Compose
    sudo docker-compose -f /dockers/shadow-tls-v3/docker-compose.yml up -d
}

case $choice in
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
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "无效的选择。"
        ;;
esac

echo "安装完成！"
