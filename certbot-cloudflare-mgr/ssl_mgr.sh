#!/bin/bash

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
    echo -e "${GREEN}>>> 正在安装基础环境...${NC}"
    apt update && apt install -y snapd
    snap install core; snap refresh core
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    snap set certbot trust-plugin-with-root=ok
    snap install certbot-dns-cloudflare
    
    mkdir -p /root/.secrets/certbot
    if [ ! -f "$CF_INI" ]; then
        read -p "请输入您的 Cloudflare API Token: " CF_TOKEN
        echo "dns_cloudflare_api_token = $CF_TOKEN" > "$CF_INI"
        chmod 600 "$CF_INI"
    fi

    # 创建同步脚本
    cat << 'EOF' > "$SYNC_SCRIPT"
#!/bin/bash
DEST_BASE="/root/certs_download"
DOMAINS=$(ls /etc/letsencrypt/live/ | grep -v 'README')
for DOMAIN in $DOMAINS; do
    TARGET_DIR="$DEST_BASE/$DOMAIN"
    mkdir -p "$TARGET_DIR"
    cp -L /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$TARGET_DIR/"
    cp -L /etc/letsencrypt/live/$DOMAIN/privkey.pem "$TARGET_DIR/"
done
chmod -R 700 "$DEST_BASE"
EOF
    chmod +x "$SYNC_SCRIPT"
    
    # 挂载钩子
    mkdir -p /etc/letsencrypt/renewal-hooks/deploy
    ln -sf "$SYNC_SCRIPT" /etc/letsencrypt/renewal-hooks/deploy/copy_certs.sh
    
    echo -e "${GREEN}环境搭建完成！${NC}"
}

# 2. 增加域名函数
add_domain() {
    read -p "请输入要申请的域名 (例如 lfboy.me): " DOMAIN
    echo -e "${GREEN}正在为 $DOMAIN 及其泛域名申请证书...${NC}"
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials "$CF_INI" \
        -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        bash "$SYNC_SCRIPT"
        echo -e "${GREEN}域名 $DOMAIN 申请成功并已同步到下载文件夹。${NC}"
    else
        echo -e "${RED}申请失败，请检查 Token 或域名 DNS 是否在 Cloudflare。${NC}"
    fi
}

# 3. 删除域名函数
delete_domain() {
    echo -e "${YELLOW}当前已有的证书：${NC}"
    certbot certificates | grep "Certificate Name"
    read -p "请输入要删除的证书名称: " CERT_NAME
    certbot delete --cert-name "$CERT_NAME"
    rm -rf "$DOWNLOAD_DIR/$CERT_NAME"
    echo -e "${GREEN}证书 $CERT_NAME 已删除，相关同步文件夹已清理。${NC}"
}

# 4. 手动同步函数
sync_certs() {
    bash "$SYNC_SCRIPT"
    echo -e "${GREEN}证书已手动同步到 $DOWNLOAD_DIR${NC}"
}

# 5. 查看路径函数
view_paths() {
    echo -e "\n${BLUE}=== 核心配置文件路径 ===${NC}"
    echo -e "Cloudflare 凭证:  ${YELLOW}$CF_INI${NC}"
    echo -e "自动同步脚本:     ${YELLOW}$SYNC_SCRIPT${NC}"
    echo -e "证书下载根目录:   ${YELLOW}$DOWNLOAD_DIR${NC}"
    echo -e "自动续订钩子目录: ${YELLOW}/etc/letsencrypt/renewal-hooks/deploy/${NC}"
    
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

    echo -e "\n${BLUE}=== Mac 下载命令参考 ===${NC}"
    echo -e "${GREEN}scp -r root@$(curl -s ifconfig.me):$DOWNLOAD_DIR/ ~/Desktop/${NC}"
}

# 主菜单
while true; do
    echo -e "\n${YELLOW}=== Let's Encrypt 证书管理面板 ===${NC}"
    echo "1) 完整环境搭建 (首次运行)"
    echo "2) 增加域名证书 (申请新域名)"
    echo "3) 删除域名证书"
    echo "4) 手动同步证书到下载文件夹"
    echo "5) 查看当前证书状态 (有效期)"
    echo "6) 查看相关文件路径 (及下载命令)"
    echo "q) 退出"
    read -p "请选择操作 [1-6/q]: " choice

    case $choice in
        1) setup_env ;;
        2) add_domain ;;
        3) delete_domain ;;
        4) sync_certs ;;
        5) certbot certificates ;;
        6) view_paths ;;
        q) exit 0 ;;
        *) echo -e "${RED}无效选择${NC}" ;;
    esac
done
