# Snell V4 和 Shadow TLS V3 安装脚本

这是一个用于安装、配置和管理Snell V4和Shadow TLS V3服务的Bash脚本。通过该脚本，您可以轻松地安装、配置、更新和删除这些服务。

## 功能

- 安装Snell V4
- 安装Snell V4和Shadow TLS V3
- 删除Snell V4
- 删除Shadow TLS V3（同时删除Snell V4）
- 更新脚本

## 先决条件

在运行脚本之前，请确保您的系统满足以下条件：

- Ubuntu或其他Debian系Linux发行版
- sudo权限
- 网络连接

## 使用方法

1. 下载脚本文件：

    ```sh
   wget https://raw.githubusercontent.com/Spades-X/Script/main/Snell/install_snell_shadowtls.sh
    ```

2. 确保脚本具有可执行权限：

    ```sh
    chmod +x install_snell_shadowtls.sh
    ```

3. 运行脚本：

    ```sh
    sudo ./install_snell_shadowtls.sh
    ```

4. 按照脚本提示选择操作：

    - 1: 安装 Snell V4
    - 2: 安装 Snell V4 和 Shadow TLS V3
    - 3: 删除 Snell V4
    - 4: 删除 Shadow TLS V3（同时删除 Snell V4）
    - 5: 更新脚本
    - 0: 退出脚本

## 脚本功能详解

### 安装前置条件

脚本首先会检查并安装必要的依赖工具 `wget` 和 `unzip`，确保后续操作顺利进行。

### 安装 Snell V4

选择安装Snell V4时，脚本会执行以下步骤：

1. 下载Snell V4的压缩包。
2. 解压并安装Snell V4。
3. 配置Snell V4的服务文件。
4. 启动并启用Snell V4服务。

### 安装 Snell V4 和 Shadow TLS V3

选择安装Snell V4和Shadow TLS V3时，脚本会执行以下步骤：

1. 按上述步骤安装Snell V4。
2. 安装Docker和Docker Compose。
3. 配置并启动Shadow TLS V3的Docker容器。

### 删除 Snell V4

选择删除Snell V4时，脚本会停止并禁用Snell服务，删除相关文件和配置。

### 删除 Shadow TLS V3

选择删除Shadow TLS V3时，脚本会停止并删除Shadow TLS V3的Docker容器及其配置文件，同时删除Snell服务及其相关配置。

### 更新脚本

选择更新脚本时，脚本会从指定的URL下载最新版本的脚本并替换当前脚本。

## 注意事项

- 本脚本仅适用于Debian系Linux发行版。
- 请确保以root或具有sudo权限的用户运行脚本。
- 删除Shadow TLS V3时会同时删除Snell V4，请注意备份相关配置。

## 许可证

此脚本基于MIT许可证开源。详细信息请参阅LICENSE文件。

## 感谢
在编写 Snell 安装部分时，参考了 DivineEngine 的 ([Snell 安装教程](https://divineengine.net/article/deploying-a-snell-server/))。非常感谢 DivineEngine 提供的详细教程。

## 贡献
欢迎提交 Issue 和 Pull Request 来改进本项目。如果有任何问题或建议，请联系我。
