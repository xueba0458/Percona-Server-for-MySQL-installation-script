#!/bin/bash

# 默认语言为英语
language="en"

# 函数：根据用户输入设置语言
set_language() {
  case "$1" in
    cn)
      language="cn"
      ;;
    en)
      language="en"
      ;;
    *)
      echo "不支持的语言: $1"
      exit 1
      ;;
  esac
}

# 函数：获取翻译后的文本
# 使用参数 $1 作为键，从语言文件中查找对应的翻译
# 如果未找到翻译，则返回键本身
_t() {
  local key="$1"
  local translation=$(eval echo \"\$LANG_$language_$key\")
  echo "${translation:-$key}"
}

# 定义语言文件
# 英语
LANG_en_SCRIPT_ABORTED="Script aborted."
LANG_en_UNSUPPORTED_DISTRO="Unsupported Linux distribution."
LANG_en_ENTER_RETRIES="Enter the number of compilation retries (default is %s): "
LANG_en_ENTER_BRANCH="Enter the branch name to checkout (default is %s): "
LANG_en_COMPRESS_INSTALL_DIR="Compress MySQL installation directory (default is %s, enter Y to compress)? "
LANG_en_UPDATING_PACKAGES="Updating package lists..."
LANG_en_INSTALLING_PACKAGES="Installing necessary packages..."
LANG_en_CLONING_REPO="Cloning Percona Server repository..."
LANG_en_REPO_EXISTS="Percona Server repository already exists, skipping cloning."
LANG_en_CHECKOUT_BRANCH="Checking out %s branch and initializing submodules..."
LANG_en_CREATING_BUILD_DIR="Creating build directory..."
LANG_en_ATTEMPT_COMPILATION="Attempting to compile Percona Server (attempt %d)..."
LANG_en_CONFIGURING_BUILD="Configuring build with CMake..."
LANG_en_COMPILING_INSTALLING="Compiling and installing Percona Server..."
LANG_en_COMPILATION_FAILED="Compilation failed. Retrying..."
LANG_en_COMPILATION_FAILED_AFTER_RETRIES="Compilation failed after %d retries."
LANG_en_COMPRESSING_INSTALL_DIR="Compressing MySQL installation directory..."
LANG_en_CREATING_USER_GROUP="Creating mysql user and group..."
LANG_en_USER_GROUP_EXISTS="mysql user and group already exist, skipping creation."
LANG_en_INITIALIZING_MYSQL="Initializing MySQL directory and files..."
LANG_en_CONFIGURING_ENV_VARS="Configuring environment variables..."
LANG_en_ENV_VARS_CONFIGURED="Environment variables already configured, skipping."
LANG_en_CREATING_CONFIG_FILE="Creating MySQL configuration file..."
LANG_en_CONFIG_FILE_EXISTS="MySQL configuration file already exists, skipping creation."
LANG_en_CREATING_SERVICE_FILE="Creating systemd service file..."
LANG_en_SERVICE_FILE_EXISTS="systemd service file already exists, skipping creation."
LANG_en_RELOADING_DAEMON="Reloading systemd daemon and starting MySQL service..."
LANG_en_MYSQL_DEPLOYMENT_COMPLETE="MySQL deployment complete\n"
LANG_en_SELECT_LANGUAGE="Select language (cn/en): "


# 中文
LANG_cn_SCRIPT_ABORTED="脚本被中止。"
LANG_cn_UNSUPPORTED_DISTRO="不支持的 Linux 发行版。"
LANG_cn_ENTER_RETRIES="请输入编译重试次数（默认值为 %s）: "
LANG_cn_ENTER_BRANCH="请输入要检出的分支名称（默认值为 %s）: "
LANG_cn_COMPRESS_INSTALL_DIR="是否压缩 MySQL 安装目录（默认值为 %s，输入 Y 进行压缩）: "
LANG_cn_UPDATING_PACKAGES="更新软件包列表..."
LANG_cn_INSTALLING_PACKAGES="安装必要的软件包..."
LANG_cn_CLONING_REPO="克隆 Percona Server 仓库..."
LANG_cn_REPO_EXISTS="Percona Server 仓库已存在，跳过克隆。"
LANG_cn_CHECKOUT_BRANCH="检出 %s 分支并初始化子模块..."
LANG_cn_CREATING_BUILD_DIR="创建构建目录..."
LANG_cn_ATTEMPT_COMPILATION="尝试第 %d 次编译 Percona Server..."
LANG_cn_CONFIGURING_BUILD="使用 CMake 配置构建..."
LANG_cn_COMPILING_INSTALLING="编译并安装 Percona Server..."
LANG_cn_COMPILATION_FAILED="编译失败。重试中..."
LANG_cn_COMPILATION_FAILED_AFTER_RETRIES="编译在 %d 次尝试后失败。"
LANG_cn_COMPRESSING_INSTALL_DIR="压缩 MySQL 安装目录..."
LANG_cn_CREATING_USER_GROUP="创建 mysql 用户和组..."
LANG_cn_USER_GROUP_EXISTS="mysql 用户和组已存在，跳过创建。"
LANG_cn_INITIALIZING_MYSQL="初始化 MySQL 目录和文件..."
LANG_cn_CONFIGURING_ENV_VARS="配置环境变量..."
LANG_cn_ENV_VARS_CONFIGURED="环境变量已配置，跳过。"
LANG_cn_CREATING_CONFIG_FILE="创建 MySQL 配置文件..."
LANG_cn_CONFIG_FILE_EXISTS="MySQL 配置文件已存在，跳过创建。"
LANG_cn_CREATING_SERVICE_FILE="创建 systemd 服务文件..."
LANG_cn_SERVICE_FILE_EXISTS="systemd 服务文件已存在，跳过创建。"
LANG_cn_RELOADING_DAEMON="重新加载 systemd 守护进程并启动 MySQL 服务..."
LANG_cn_MYSQL_DEPLOYMENT_COMPLETE="MySQL 部署完成\n"
LANG_cn_SELECT_LANGUAGE="请选择语言 (cn/en): "

# 获取用户选择的语言
read -p "$_t(SELECT_LANGUAGE)" language
set_language "$language"

set -e

# 捕获 SIGINT 信号（即 Ctrl+C）以中止脚本
trap 'echo "$_t(SCRIPT_ABORTED)"; exit 1' INT

# 函数：输出并执行命令
run_command() {
  echo "$_t($1)"
  eval "$2"
}

# 检测发行版并设置包管理器
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
elif [ -f /etc/lsb-release ]; then
  . /etc/lsb-release
  OS=$DISTRIB_ID
else
  echo "$_t(UNSUPPORTED_DISTRO)"
  exit 1
fi

# 用户输入的重试次数，默认为6次，30秒超时
DEFAULT_RETRIES=6
read -t 30 -p "$(printf "$_t(ENTER_RETRIES)" "$DEFAULT_RETRIES")" USER_RETRIES
RETRIES=${USER_RETRIES:-$DEFAULT_RETRIES}

# 用户输入的分支名称，默认为8.0分支，30秒超时
DEFAULT_BRANCH="8.0"
read -t 30 -p "$(printf "$_t(ENTER_BRANCH)" "$DEFAULT_BRANCH")" USER_BRANCH
BRANCH=${USER_BRANCH:-$DEFAULT_BRANCH}

# 用户输入是否压缩安装目录，默认为N，30秒超时
DEFAULT_COMPRESS="N"
read -t 30 -p "$(printf "$_t(COMPRESS_INSTALL_DIR)" "$DEFAULT_COMPRESS")" USER_COMPRESS
COMPRESS=${USER_COMPRESS:-$DEFAULT_COMPRESS}

# 检查并安装必要的软件包
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
  run_command "UPDATING_PACKAGES" "apt-get update"
  DEPS="git sudo g++ cmake make build-essential libssl-dev libldap2-dev libsasl2-dev krb5-multidev libncurses5-dev libreadline-dev bison libcurl4-openssl-dev libudev-dev libtirpc-dev rpcbind libaio-dev"
  run_command "INSTALLING_PACKAGES" "apt-get install -y $DEPS"
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
  DEPS="git sudo c++ cmake make gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc openssl-devel openldap-devel cyrus-sasl-devel cyrus-sasl-scram krb5-devel ncurses-devel readline-devel bison libcurl-devel libudev-devel libtirpc-devel rpcgen libaio-devel"
  run_command "INSTALLING_PACKAGES" "yum install -y $DEPS"
else
  echo "$_t(UNSUPPORTED_DISTRO)"
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
  run_command "CLONING_REPO" "cd /root && git config --global http.postBuffer 524288000 && git clone https://github.com/percona/percona-server.git"
else
  echo "$_t(REPO_EXISTS)"
fi

# 切换到用户指定的分支并初始化子模块
run_command "CHECKOUT_BRANCH" "cd /root/percona-server && git checkout $BRANCH && git submodule init && git submodule update"

# 创建构建目录
if [ ! -d "/root/percona-server-build" ]; then
  run_command "CREATING_BUILD_DIR" "mkdir -p /root/percona-server-build"
fi
cd /root/percona-server-build

# 编译并安装 Percona Server，重试用户指定次数
retry_count=0
success=false

while [ $retry_count -lt $RETRIES ]; do
  echo "$(printf "$_t(ATTEMPT_COMPILATION)" "$((retry_count + 1))")"
  run_command "CONFIGURING_BUILD" "cmake ../percona-server -DDOWNLOAD_BOOST=1 -DWITH_BOOST=./boost -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CONFIG=mysql_release -DFEATURE_SET=community"
  if run_command "COMPILING_INSTALLING" "make -j$MAKE_J && make install -j$MAKE_J"; then
    success=true
    break
  else
    echo "$_t(COMPILATION_FAILED)"
    retry_count=$(($retry_count + 1))
  fi
done

if [ $success = false ]; then
  echo "$(printf "$_t(COMPILATION_FAILED_AFTER_RETRIES)" "$RETRIES")"
  exit 1
fi

# 检查是否需要压缩安装目录
if [ "$COMPRESS" == "Y" ]; then
  run_command "COMPRESSING_INSTALL_DIR" "tar -czvf /root/mysql-${BRANCH}.tar.gz -C /usr/local mysql"
fi

# 创建 mysql 用户和组
if ! id -u mysql > /dev/null 2>&1; then
  run_command "CREATING_USER_GROUP" "groupadd mysql && useradd -r -g mysql -s /bin/false mysql"
else
  echo "$_t(USER_GROUP_EXISTS)"
fi

# 初始化 MySQL 目录和文件
run_command "INITIALIZING_MYSQL" "cd /usr/local/mysql && mkdir -p /usr/local/mysql/etc && mkdir -p mysql-files && chown mysql:mysql mysql-files && chmod 750 mysql-files && bin/mysqld --initialize-insecure --user=mysql"

# 配置环境变量
if ! grep -q "MYSQLPATH=/usr/local/mysql" /etc/profile; then
  run_command "CONFIGURING_ENV_VARS" "echo 'export MYSQLPATH=/usr/local/mysql' >> /etc/profile && echo 'export PATH=\$MYSQLPATH/bin:\$MYSQLPATH/lib:\$PATH' >> /etc/profile && source /etc/profile"
else
  echo "$_t(ENV_VARS_CONFIGURED)"
fi

# 创建 MySQL 配置文件
if [ ! -f "/usr/local/mysql/etc/my.cnf" ]; then
  echo "$_t(CREATING_CONFIG_FILE)"
  cat <<EOF > /usr/local/mysql/etc/my.cnf
[mysqld]
port = 3306
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
#socket=/var/run/mysqld/mysqld.sock
secure-file-priv=/usr/local/mysql/mysql-files
user=mysql
log_error_suppression_list='MY-013360'

character_set_server=utf8mb4
lower_case_table_names=1
group_concat_max_len=1024000
log_bin_trust_function_creators=1

#pid-file=/var/run/mysqld/mysqld.pid
key_buffer_size=512M
tmp_table_size=1024M
innodb_buffer_pool_size=1024M
sort_buffer_size=2M
read_buffer_size=2M
read_rnd_buffer_size=1024K
join_buffer_size=4M
thread_stack=384K
binlog_cache_size=192K
thread_cache_size=192
table_open_cache=1024
max_connections=400

[client]
#socket=/var/run/mysqld/mysqld.sock
EOF
else
  echo "$_t(CONFIG_FILE_EXISTS)"
fi

# 创建 systemd 服务文件
if [ ! -f "/usr/lib/systemd/system/mysql.service" ]; then
  echo "$_t(CREATING_SERVICE_FILE)"
  cat <<EOF > /usr/lib/systemd/system/mysql.service
[Unit]
Description=MySQL Server
#Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/etc/my.cnf
PIDFile=/mysql/data/mysqld.pid
Restart=on-failure
RestartPreventExitStatus=1
TimeoutSec=0
PrivateTmp=false
LimitNOFILE=65535
LimitNPROC=65535

[Install]
WantedBy=multi-user.target
EOF
else
  echo "$_t(SERVICE_FILE_EXISTS)"
fi

# 重新加载 systemd 服务配置并启动 MySQL 服务
run_command "RELOADING_DAEMON" "systemctl daemon-reload && systemctl enable mysql.service && systemctl start mysql.service"

# 清理临时文件和目录（如果需要）
# run_command "清理临时文件和目录..." "rm -rf /root/percona-server /root/percona-server-build"

echo "$_t(MYSQL_DEPLOYMENT_COMPLETE)"
