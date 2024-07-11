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
