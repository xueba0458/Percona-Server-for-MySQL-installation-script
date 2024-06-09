#!/bin/bash

set -e

# 捕获 SIGINT 信号（即 Ctrl+C）以中止脚本
trap 'echo "Script aborted."; exit 1' INT

# 函数：输出并执行命令
run_command() {
    echo "$1"
    eval "$2"
}

# 选择语言
DEFAULT_LANGUAGE="en"
read -t 30 -p "请选择语言 (en/cn, 默认: $DEFAULT_LANGUAGE): " USER_LANGUAGE
LANGUAGE=${USER_LANGUAGE:-$DEFAULT_LANGUAGE}

# 文本定义
if [ "$LANGUAGE" == "cn" ]; then
    TEXT_UNSUPPORTED_OS="不支持的 Linux 发行版。"
    TEXT_INPUT_RETRIES="请输入编译重试次数（默认值为"
    TEXT_INPUT_BRANCH="请输入要检出的分支名称（默认值为"
    TEXT_INPUT_COMPRESS="是否压缩 MySQL 安装目录（默认值为 N，输入 Y 进行压缩）: "
    TEXT_UPDATE_PACKAGE_LIST="更新软件包列表..."
    TEXT_INSTALL_DEPENDENCIES="安装必要的软件包..."
    TEXT_CLONE_REPO="克隆 Percona Server 仓库..."
    TEXT_REPO_EXISTS="Percona Server 仓库已存在，跳过克隆。"
    TEXT_CHECKOUT_BRANCH="检出"
    TEXT_INIT_SUBMODULES="分支并初始化子模块..."
    TEXT_CREATE_BUILD_DIR="创建构建目录..."
    TEXT_ATTEMPT_BUILD="尝试第"
    TEXT_ATTEMPT_BUILD_TIMES="次编译 Percona Server"
    TEXT_CONFIGURE_CMAKE="使用 CMake 配置构建..."
    TEXT_BUILD_INSTALL="编译并安装 Percona Server..."
    TEXT_BUILD_FAILED="编译失败。重试中..."
    TEXT_BUILD_FAILED_RETRIES="编译在"
    TEXT_BUILD_FAILED_ATTEMPTS="次尝试后失败。"
    TEXT_COMPRESS_DIR="压缩 MySQL 安装目录..."
    TEXT_CREATE_USER_GROUP="创建 mysql 用户和组..."
    TEXT_USER_GROUP_EXISTS="mysql 用户和组已存在，跳过创建。"
    TEXT_INIT_MYSQL="初始化 MySQL 目录和文件..."
    TEXT_CONFIGURE_ENV="配置环境变量..."
    TEXT_ENV_ALREADY_CONFIGURED="环境变量已配置，跳过。"
    TEXT_CREATE_MYSQL_CONF="创建 MySQL 配置文件..."
    TEXT_MYSQL_CONF_EXISTS="MySQL 配置文件已存在，跳过创建。"
    TEXT_CREATE_SYSTEMD_SERVICE="创建 systemd 服务文件..."
    TEXT_SYSTEMD_SERVICE_EXISTS="systemd 服务文件已存在，跳过创建。"
    TEXT_RELOAD_SYSTEMD="重新加载 systemd 守护进程并启动 MySQL 服务..."
    TEXT_DEPLOY_COMPLETE="MySQL 部署完成"
else
    TEXT_UNSUPPORTED_OS="Unsupported Linux distribution."
    TEXT_INPUT_RETRIES="Please enter the number of compilation retries (default:"
    TEXT_INPUT_BRANCH="Please enter the branch name to checkout (default:"
    TEXT_INPUT_COMPRESS="Do you want to compress the MySQL installation directory (default: N, enter Y to compress): "
    TEXT_UPDATE_PACKAGE_LIST="Updating package list..."
    TEXT_INSTALL_DEPENDENCIES="Installing necessary packages..."
    TEXT_CLONE_REPO="Cloning Percona Server repository..."
    TEXT_REPO_EXISTS="Percona Server repository already exists, skipping clone."
    TEXT_CHECKOUT_BRANCH="Checking out"
    TEXT_INIT_SUBMODULES="branch and initializing submodules..."
    TEXT_CREATE_BUILD_DIR="Creating build directory..."
    TEXT_ATTEMPT_BUILD="Attempting build"
    TEXT_ATTEMPT_BUILD_TIMES="times"
    TEXT_CONFIGURE_CMAKE="Configuring build with CMake..."
    TEXT_BUILD_INSTALL="Building and installing Percona Server..."
    TEXT_BUILD_FAILED="Build failed. Retrying..."
    TEXT_BUILD_FAILED_RETRIES="Build failed after"
    TEXT_BUILD_FAILED_ATTEMPTS="attempts."
    TEXT_COMPRESS_DIR="Compressing MySQL installation directory..."
    TEXT_CREATE_USER_GROUP="Creating mysql user and group..."
    TEXT_USER_GROUP_EXISTS="mysql user and group already exist, skipping creation."
    TEXT_INIT_MYSQL="Initializing MySQL directory and files..."
    TEXT_CONFIGURE_ENV="Configuring environment variables..."
    TEXT_ENV_ALREADY_CONFIGURED="Environment variables already configured, skipping."
    TEXT_CREATE_MYSQL_CONF="Creating MySQL configuration file..."
    TEXT_MYSQL_CONF_EXISTS="MySQL configuration file already exists, skipping."
    TEXT_CREATE_SYSTEMD_SERVICE="Creating systemd service file..."
    TEXT_SYSTEMD_SERVICE_EXISTS="systemd service file already exists, skipping."
    TEXT_RELOAD_SYSTEMD="Reloading systemd daemon and starting MySQL service..."
    TEXT_DEPLOY_COMPLETE="MySQL deployment complete"
fi

# 检测发行版并设置包管理器
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
else
    echo "$TEXT_UNSUPPORTED_OS"
    exit 1
fi

# 用户输入的重试次数，默认为6次，30秒超时
DEFAULT_RETRIES=6
read -t 30 -p "$TEXT_INPUT_RETRIES $DEFAULT_RETRIES): " USER_RETRIES
RETRIES=${USER_RETRIES:-$DEFAULT_RETRIES}

# 用户输入的分支名称，默认为8.0分支，30秒超时
DEFAULT_BRANCH="8.0"
read -t 30 -p "$TEXT_INPUT_BRANCH $DEFAULT_BRANCH): " USER_BRANCH
BRANCH=${USER_BRANCH:-$DEFAULT_BRANCH}

# 用户输入是否压缩安装目录，默认为N，30秒超时
DEFAULT_COMPRESS="N"
read -t 30 -p "$TEXT_INPUT_COMPRESS" USER_COMPRESS
COMPRESS=${USER_COMPRESS:-$DEFAULT_COMPRESS}

# 检查并安装必要的软件包
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    run_command "$TEXT_UPDATE_PACKAGE_LIST" "apt-get update"
    DEPS="git sudo g++ cmake make build-essential libssl-dev libldap2-dev libsasl2-dev krb5-multidev libncurses5-dev libreadline-dev bison libcurl4-openssl-dev libudev-dev libtirpc-dev rpcbind libaio-dev"
    run_command "$TEXT_INSTALL_DEPENDENCIES" "apt-get install -y $DEPS"
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    DEPS="git sudo c++ cmake make gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc openssl-devel openldap-devel cyrus-sasl-devel cyrus-sasl-scram krb5-devel ncurses-devel readline-devel bison libcurl-devel libudev-devel libtirpc-devel rpcgen libaio-devel"
    run_command "$TEXT_INSTALL_DEPENDENCIES" "yum install -y $DEPS"
else
    echo "$TEXT_UNSUPPORTED_OS"
    exit 1
fi

# 获取 CPU 核心数量的一半，至少为1
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
MAKE_J=$((CPU_CORES / 2))
if [ $MAKE_J -lt 1 ]; then
    MAKE_J=1
fi

# 克隆 Percona Server 仓库
if [ ! -d "/root/percona-server" ]; then
    run_command "$TEXT_CLONE_REPO" "cd /root && git config --global http.postBuffer 524288000 && git clone https://github.com/percona/percona-server.git"
else
    echo "$TEXT_REPO_EXISTS"
fi

# 切换到用户指定的分支并初始化子模块
run_command "$TEXT_CHECKOUT_BRANCH $BRANCH $TEXT_INIT_SUBMODULES" "cd /root/percona-server && git checkout $BRANCH && git submodule init && git submodule update"

# 创建构建目录
if [ ! -d "/root/percona-server-build" ]; then
    run_command "$TEXT_CREATE_BUILD_DIR" "mkdir -p /root/percona-server-build"
fi
cd /root/percona-server-build

# 编译并安装 Percona Server，重试用户指定次数
retry_count=0
success=false

while [ $retry_count -lt $RETRIES ]; do
    echo "$TEXT_ATTEMPT_BUILD $((retry_count + 1)) $TEXT_ATTEMPT_BUILD_TIMES"
    run_command "$TEXT_CONFIGURE_CMAKE" "cmake ../percona-server -DDOWNLOAD_BOOST=1 -DWITH_BOOST=./boost -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CONFIG=mysql_release -DFEATURE_SET=community"
    if run_command "$TEXT_BUILD_INSTALL" "make -j$MAKE_J && make install -j$MAKE_J"; then
        success=true
        break
    else
        echo "$TEXT_BUILD_FAILED"
        retry_count=$((retry_count + 1))
    fi
done

if [ $success = false ]; then
    echo "$TEXT_BUILD_FAILED_RETRIES $RETRIES $TEXT_BUILD_FAILED_ATTEMPTS"
    exit 1
fi

# 检查是否需要压缩安装目录
if [ "$COMPRESS" == "Y" ]; then
    run_command "$TEXT_COMPRESS_DIR" "tar -czvf /
