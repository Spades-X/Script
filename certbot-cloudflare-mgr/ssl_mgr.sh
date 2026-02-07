#!/bin/bash

# ====================================================
# Let's Encrypt + Cloudflare 证书管理面板
# ====================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径定义
CF_INI="/root/.secrets/certbot/cloudflare.ini"
SYNC_SCRIPT="/usr/local/bin/copy_certs.sh"
DOWNLOAD_DIR="/root/certs_download"
LIVE_DIR="/etc/letsencrypt/live"

# 检查权限
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误: 必须使用 sudo 或 root 用户运行此脚本${NC}"
   exit 1
fi

# 1. 环境搭建函数
setup_env() {
    echo -e "${GREEN}>>> 正在安装基础环境 (Snapd, Curl, Certbot)...${NC}"
    apt update && apt install -y snapd curl
    
    snap install core; snap refresh core
    
    echo -e "${GREEN}>>> 安装 Certbot 官方推荐版本...${NC}"
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    snap set certbot trust-plugin-with-root=ok
    snap install certbot-dns-cloudflare
    
    mkdir -p /root/.secrets/certbot
    if [ ! -f "$CF_INI" ]; then
        echo -e "${YELLOW}==================================================${NC}"
        echo -e "${YELLOW} 注意：此脚本仅支持 DNS 解析托管在 Cloudflare 的域名 ${NC}"
        echo -e "${YELLOW}==================================================${NC}"
        read -p "请输入您的 Cloudflare API Token (需具备 DNS 编辑权限): " CF_TOKEN
        echo "dns_cloudflare_api_token = $CF_TOKEN" > "$CF_INI"
        chmod 600 "$CF_INI"
    else
        echo -e "${BLUE}检测到已存在的 Cloudflare 凭证，跳过配置。${NC}"
    fi

    # 创建同步脚本
    cat << 'EOF' > "$SYNC_SCRIPT"
#!/bin/bash
DEST_BASE="/root/certs_download"
if [ -d "/etc/letsencrypt/live" ]; then
    DOMAINS=$(ls /etc/letsencrypt/live/ | grep -v 'README')
    for DOMAIN in $DOMAINS; do
        TARGET_DIR="$DEST_BASE/$DOMAIN"
        mkdir -p "$TARGET_DIR"
        cp -L /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$TARGET_DIR/"
        cp -L /etc/letsencrypt/live/$DOMAIN/privkey.pem "$TARGET_DIR/"
    done
    chmod -R 700 "$DEST_BASE"
fi
EOF
    chmod +x "$SYNC_SCRIPT"
    
    mkdir -p /etc/letsencrypt/renewal-hooks/deploy
    ln -sf "$SYNC_SCRIPT" /etc/letsencrypt/renewal-hooks/deploy/copy_certs.sh
    
    echo -e "${GREEN}环境搭建完成！${NC}"
}

# 2. 增加域名函数
add_domain() {
    if [ ! -f "$CF_INI" ]; then
        echo -e "${RED}错误: 未检测到 Cloudflare 凭证，请先运行选项 1 搭建环境。${NC}"
        return
    fi
    
    echo -e "\n${YELLOW}--------------------------------------------------${NC}"
    echo -e "${YELLOW} 提示：请确保您要申请的域名 DNS 已经托管在 Cloudflare ${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    read -p "请输入要申请的主域名 (例如 lfboy.me): " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空！${NC}"
        return
    fi

    echo -e "${GREEN}正在为 $DOMAIN 及其泛域名 (*.$DOMAIN) 申请证书...${NC}"
    
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials "$CF_INI" \
        -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        bash "$SYNC_SCRIPT"
        echo -e "${GREEN}域名 $DOMAIN 申请成功！证书已同步至 $DOWNLOAD_DIR/$DOMAIN${NC}"
    else
        echo -e "${RED}申请失败。请确认：${NC}"
        echo -e "1. 该域名的 DNS 解析确实在 Cloudflare 上。"
        echo -e "2. 您提供的 API Token 拥有该域名的 DNS 编辑权限。"
    fi
}

# 3. 删除域名函数
delete_domain() {
    echo -e "\n${YELLOW}当前已有的证书列表：${NC}"
    certbot certificates | grep "Certificate Name"
    
    read -p "请输入要删除的证书全名 (Certificate Name): " CERT_NAME
    if [ -z "$CERT_NAME" ]; then return; fi
    
    echo -e "${RED}警告: 即将删除 $CERT_NAME 的所有证书记录及同步文件。${NC}"
    read -p "确认删除吗？(y/n): " CONFIRM
    if [ "$CONFIRM" == "y" ]; then
        certbot delete --cert-name "$CERT_NAME"
        rm -rf "$DOWNLOAD_DIR/$CERT_NAME"
        echo -e "${GREEN}已彻底清理 $CERT_NAME 相关内容。${NC}"
    fi
}

# 4. 手动同步函数
sync_certs() {
    if [ -f "$SYNC_SCRIPT" ]; then
        bash "$SYNC_SCRIPT"
        echo -e "${GREEN}同步完成！最新证书已提取到 $DOWNLOAD_DIR${NC}"
    else
        echo -e "${RED}错误: 同步脚本不存在，请先运行选项 1。${NC}"
    fi
}

# 5. 查看路径与下载命令
view_paths() {
    echo -e "\n${BLUE}=== 核心配置文件路径 ===${NC}"
    echo -e "Cloudflare 凭证:  ${YELLOW}$CF_INI${NC}"
    echo -e "自动同步脚本:     ${YELLOW}$SYNC_SCRIPT${NC}"
    echo -e "证书下载根目录:   ${YELLOW}$DOWNLOAD_DIR${NC}"
    
    echo -e "\n${BLUE}=== 各域名证书原始路径 (Live) ===${NC}"
    if [ -d "$LIVE_DIR" ]; then
        DOMAINS=$(ls "$LIVE_DIR" | grep -v 'README')
        if [ -z "$DOMAINS" ]; then
            echo "暂无已申请的证书。"
        else
            for DOMAIN in $DOMAINS; do
                echo -e "域名: ${GREEN}$DOMAIN${NC}"
                echo -e "  └─ 证书路径: $LIVE_DIR/$DOMAIN/fullchain.pem"
                echo -e "  └─ 私钥路径: $LIVE_DIR/$DOMAIN/privkey.pem"
            done
        fi
    fi

    echo -e "\n${BLUE}=== Mac/本地终端下载命令 ===${NC}"
    SERVER_IP=$(curl -s --connect-timeout 5 ifconfig.me || echo "您的服务器IP")
    echo -e "${GREEN}scp -r root@${SERVER_IP}:${DOWNLOAD_DIR}/ ~/Desktop/${NC}"
}

# 主菜单
while true; do
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}      Let's Encrypt 证书管理面板        ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo "1) 完整环境搭建 (首次运行必选)"
    echo "2) 增加域名证书 (申请新域名)"
    echo "3) 删除域名证书"
    echo "4) 手动同步证书 (立即提取文件)"
    echo "5) 查看当前证书状态 (有效期)"
    echo "6) 查看文件路径及下载命令"
    echo "q) 退出"
    echo -e "${YELLOW}----------------------------------------${NC}"
    read -p "请选择操作 [1-6/q]: " choice

    case $choice in
        1) setup_env ;;
        2) add_domain ;;
        3) delete_domain ;;
        4) sync_certs ;;
        5) certbot certificates ;;
        6) view_paths ;;
        q) exit 0 ;;
        *) echo -e "${RED}无效选择，请输入 1-6 或 q${NC}" ;;
    esac
done
