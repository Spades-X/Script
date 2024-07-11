# Snell 和 Shadow TLS 一键安装脚本

## 简介

这是一个用于安装 Snell 和 Shadow TLS 的一键脚本。该脚本可以自动检测 Snell 服务的运行状态，并根据用户的选择进行相应的软件安装。提供了三个选项：仅安装 Snell，安装 Snell 和 Shadow TLS，以及退出脚本。

## 功能

1. 检查 Snell 服务是否正在运行。
2. 根据用户选择安装 Snell 或 Snell 和 Shadow TLS。
3. 自动安装所需的依赖项（如 wget、unzip、docker 和 docker-compose）。
4. 自动配置 Snell 和 Shadow TLS 的服务文件。

## 使用方法

### 克隆项目

```bash
git clone <项目地址>
cd <项目目录>


## 运行脚本
chmod +x install.sh
sudo ./install.sh

选项说明
运行脚本后，会出现以下选项：

安装 Snell：安装 Snell 代理服务。
安装 Snell 和 Shadow TLS：安装 Snell 代理服务和 Shadow TLS。
退出脚本：退出安装脚本。
配置文件
Snell 配置文件
安装 Snell 后，配置文件位于 /etc/snell-server.conf。默认配置如下：

[snell-server]
listen = 0.0.0.0:11807
psk = AijHCeos15IvqDZTb1cJMX5GcgZzIVE
ipv6 = false
obfs = off
Shadow TLS 配置文件
安装 Shadow TLS 后，配置文件位于 /dockers/shadow-tls-v3/docker-compose.yml。默认配置如下：

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
      - LISTEN=0.0.0.0:54321  # IPv6 改为 [::]:54321
      - SERVER=127.0.0.1:11807  # IPv6 改为 [::1]:xxx，xxx 是 Snell 节点端口
      - TLS=captive.apple.com:443
      - PASSWORD=5463364@5463364
注意事项
请确保在运行脚本前具有 sudo 权限。
安装 Docker 和 Docker Compose 可能需要一定的时间，请耐心等待。
如果需要使用 IPv6，请根据注释修改相应配置。
常见问题
1. 如何检查 Snell 服务状态？
可以使用以下命令检查 Snell 服务的状态：

sudo systemctl status snell
2. 如何查看 Docker 容器日志？
可以使用以下命令查看 Shadow TLS Docker 容器的日志：

sudo docker logs shadow-tls-v3
3. 如何更新 Snell 和 Shadow TLS？
可以删除旧版本并重新运行脚本进行更新。删除 Snell 和 Shadow TLS 的命令如下：

sudo systemctl stop snell
sudo systemctl disable snell
sudo rm /usr/local/bin/snell-server
sudo rm /etc/snell-server.conf
sudo rm /lib/systemd/system/snell.service

sudo docker-compose -f /dockers/shadow-tls-v3/docker-compose.yml down
sudo rm -r /dockers/shadow-tls-v3
然后重新运行安装脚本即可。

感谢
在编写 Snell 安装部分时，参考了 DivineEngine 的 Snell 安装教程。非常感谢 DivineEngine 提供的详细教程。

贡献
欢迎提交 Issue 和 Pull Request 来改进本项目。如果有任何问题或建议，请联系我。

许可
本项目采用 MIT 许可。

这个 `README.md` 文件包含了所有必要的信息，帮助用户理解和使用一键安装脚本，包括简介、功能、使用方法、配置文件、注意事项、常见问题、感谢、贡献和许可部分。
