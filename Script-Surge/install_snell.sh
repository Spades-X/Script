#!/bin/bash

# 打印欢迎信息并显示选项
echo "欢迎使用 Snell 安装脚本！请选择:"
echo "1. 安装 Snell"
echo "2. 安装 Snell + stls"

read -p "请输入您的选择(1/2): " choice

case $choice in
    1)
        echo "开始安装 Snell..."
        
        # 安装 wget 和 unzip（如果未预装）
        if ! command -v wget &> /dev/null || ! command -v unzip &> /dev/null; then
            echo "安装 wget 和 unzip..."
            sudo apt-get update
            sudo apt-get install -y wget unzip
        fi
        
        # 下载并安装 Snell
        wget https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip
        sudo unzip snell-server-v4.0.1-linux-amd64.zip -d /usr/local/bin
        
        # 创建配置文件
        echo -e "[snell-server]\nlisten = ::0:54633\npsk = 5463364@5463364\nipv6 = true\nobfs = off" | sudo tee /etc/snell-server.conf
        
        # 配置 Systemd 服务文件
        echo -e "[Unit]\nDescription=Snell Proxy Service\nAfter=network.target\n\n[Service]\nType=simple\nUser=nobody\nGroup=nogroup\nLimitNOFILE=32768\nExecStart=/usr/local/bin/snell-server -c /etc/snell-server.conf\n\n[Install]\nWantedBy=multi-user.target" | sudo tee /lib/systemd/system/snell.service
        
        # 启动和启用 Snell 服务
        sudo systemctl start snell
        sudo systemctl enable snell
        ;;
    2)
        echo "安装 Snell + stls 的选项尚未实现。请手动安装 stls。"
        ;;
    *)
        echo "无效的选择。"
        ;;
esac

echo "安装完成！"