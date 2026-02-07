# Let's Encrypt Cloudflare 证书自动化管理脚本

这是一个基于 Bash 编写的交互式脚本，旨在简化在 Linux 服务器上通过 Cloudflare DNS 申请、续订及管理 Let's Encrypt 泛域名 SSL 证书的过程。

## 🌟 核心功能

- **全自动环境搭建**：一键安装 Certbot、Snapd 及 Cloudflare DNS 插件。
- **泛域名支持**：支持申请 `*.example.com` 格式的通配符证书。
- **自动续订钩子**：内置 `deploy-hook`，证书续订成功后自动同步到指定文件夹。
- **证书自动提取**：自动将证书从系统保护目录提取到 `/root/certs_download`，解决权限问题，方便下载。
- **交互式菜单**：无需记忆复杂命令，通过数字菜单即可完成增、删、查、改。
- **路径一键查看**：快速查看所有证书存放路径及配套的 Mac 下载命令。

## 🚀 快速开始

### 1. 前提条件
- 拥有一个 Cloudflare 账号，且域名 DNS 已托管在 Cloudflare。
- 在 Cloudflare 后台获取一个具有 **Zone:DNS:Edit** 权限的 **API Token**。
- 一台运行 Ubuntu/Debian（或其他支持 Snap 的 Linux）的服务器，并拥有 **root** 权限。

### 2. 下载并运行
你可以直接在服务器上运行以下命令：

```bash
curl -sSO https://raw.githubusercontent.com/你的用户名/仓库名/main/ssl_mgr.sh && chmod +x ssl_mgr.sh && sudo ./ssl_mgr.sh

## 功能说明
运行脚本后，你将看到以下交互式菜单：
### 完整环境搭建：首次使用必选。安装所有依赖并配置 Cloudflare API Token。
### 增加域名证书：输入域名（如 example.com），自动申请该域名及其泛域名的证书。
### 删除域名证书：安全删除不再需要的证书及相关同步文件。
### 手动同步证书：立即将 /etc/letsencrypt/ 下的最新证书同步到下载文件夹。
### 查看当前证书状态：列出所有证书的域名、到期时间及剩余天数。
### 查看相关文件路径：展示所有配置文件的位置，并自动生成适用于 Mac/本地终端的 scp 下载命令。
## 📂 证书下载 (Mac/本地)
脚本会自动将证书同步到 /root/certs_download/。你可以通过以下命令（在选项 6 中会自动生成）将证书一键下载到 Mac 桌面：

```bash
scp -r root@你的服务器IP:/root/certs_download/ ~/Desktop/

## ⚠️ 安全提示
本脚本会将 Cloudflare API Token 存储在 /root/.secrets/ 目录下，并设置 600 权限。请确保不要将该目录暴露给非 root 用户。
请勿将包含真实 Token 的 cloudflare.ini 文件上传到公共仓库。
建议在 GitHub 仓库中添加 .gitignore 文件以排除临时文件。

