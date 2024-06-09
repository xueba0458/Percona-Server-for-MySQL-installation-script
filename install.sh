#!/bin/bash

set -e

# 捕获 SIGINT 信号（即 Ctrl+C）以中止脚本
trap 'echo "脚本被中止。"; exit 1' INT

# 函数：输出并执行命令
run_command() {
    echo "$1"
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
    echo "不支持的 Linux 发行版。"
    exit 1
fi

# 用户输入的重试次数，默认为6次，30秒超时
DEFAULT_RETRIES=6
read -t 30 -p "请输入编译重试次数（默认值为 $DEFAULT_RETRIES）: " USER_RETRIES
RETRIES=${USER_RETRIES:-$DEFAULT_RETRIES}

# 用户输入的分支名称，默认为8.0分支，30秒超时
DEFAULT_BRANCH="8.0"
read -t 30 -p "请输入要检出的分支名称（默认值为 $DEFAULT_BRANCH）: " USER_BRANCH
BRANCH=${USER_BRANCH:-$DEFAULT_BRANCH}

# 用户输入是否压缩安装目录，默认为N，30秒超时
DEFAULT_COMPRESS="N"
read -t 30 -p "是否压缩 MySQL 安装目录（默认值为 $DEFAULT_COMPRESS，输入 Y 进行压缩）: " USER_COMPRESS
COMPRESS=${USER_COMPRESS:-$DEFAULT_COMPRESS}

# 检查并安装必要的软件包
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    run_command "更新软件包列表..." "apt-get update"
    DEPS="git sudo g++ cmake make build-essential libssl-dev libldap2-dev libsasl2-dev krb5-multidev libncurses5-dev libreadline-dev bison libcurl4-openssl-dev libudev-dev libtirpc-dev rpcbind libaio-dev"
    run_command "安装必要的软件包..." "apt-get install -y $DEPS"
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    DEPS="git sudo c++ cmake make gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc openssl-devel openldap-devel cyrus-sasl-devel cyrus-sasl-scram krb5-devel ncurses-devel readline-devel bison libcurl-devel libudev-devel libtirpc-devel rpcgen libaio-devel"
    run_command "安装必要的软件包..." "yum install -y $DEPS"
else
    echo "不支持的 Linux 发行版。"
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
    run_command "克隆 Percona Server 仓库..." "cd /root && git config --global http.postBuffer 524288000 && git clone https://github.com/percona/percona-server.git"
else
    echo "Percona Server 仓库已存在，跳过克隆。"
fi

# 切换到用户指定的分支并初始化子模块
run_command "检出 $BRANCH 分支并初始化子模块..." "cd /root/percona-server && git checkout $BRANCH && git submodule init && git submodule update"

# 创建构建目录
if [ ! -d "/root/percona-server-build" ]; then
    run_command "创建构建目录..." "mkdir -p /root/percona-server-build"
fi
cd /root/percona-server-build

# 编译并安装 Percona Server，重试用户指定次数
retry_count=0
success=false

while [ $retry_count -lt $RETRIES ]; do
    echo "尝试第 $(($retry_count + 1)) 次编译 Percona Server"
    run_command "使用 CMake 配置构建..." "cmake ../percona-server -DDOWNLOAD_BOOST=1 -DWITH_BOOST=./boost -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CONFIG=mysql_release -DFEATURE_SET=community"
    if run_command "编译并安装 Percona Server..." "make -j$MAKE_J && make install -j$MAKE_J"; then
        success=true
        break
    else
        echo "编译失败。重试中..."
        retry_count=$(($retry_count + 1))
    fi
done

if [ $success = false ]; then
    echo "编译在 $RETRIES 次尝试后失败。"
    exit 1
fi

# 检查是否需要压缩安装目录
if [ "$COMPRESS" == "Y" ]; then
    run_command "压缩 MySQL 安装目录..." "tar -czvf /root/mysql-${BRANCH}.tar.gz -C /usr/local mysql"
fi

# 创建 mysql 用户和组
if ! id -u mysql > /dev/null 2>&1; then
    run_command "创建 mysql 用户和组..." "groupadd mysql && useradd -r -g mysql -s /bin/false mysql"
else
    echo "mysql 用户和组已存在，跳过创建。"
fi

# 初始化 MySQL 目录和文件
run_command "初始化 MySQL 目录和文件..." "cd /usr/local/mysql && mkdir -p /usr/local/mysql/etc && mkdir -p mysql-files && chown mysql:mysql mysql-files && chmod 750 mysql-files && bin/mysqld --initialize-insecure --user=mysql"

# 配置环境变量
if ! grep -q "MYSQLPATH=/usr/local/mysql" /etc/profile; then
    run_command "配置环境变量..." "echo 'export MYSQLPATH=/usr/local/mysql' >> /etc/profile && echo 'export PATH=\$MYSQLPATH/bin:\$MYSQLPATH/lib:\$PATH' >> /etc/profile && source /etc/profile"
else
    echo "环境变量已配置，跳过。"
fi

# 创建 MySQL 配置文件
if [ ! -f "/usr/local/mysql/etc/my.cnf" ]; then
    echo "创建 MySQL 配置文件..."
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
    echo "MySQL 配置文件已存在，跳过创建。"
fi

# 创建 systemd 服务文件
if [ ! -f "/usr/lib/systemd/system/mysql.service" ]; then
    echo "创建 systemd 服务文件..."
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
    echo "systemd 服务文件已存在，跳过创建。"
fi

# 重新加载 systemd 服务配置并启动 MySQL 服务
run_command "重新加载 systemd 守护进程并启动 MySQL 服务..." "systemctl daemon-reload && systemctl enable mysql.service && systemctl start mysql.service"

# 清理临时文件和目录（如果需要）
# run_command "清理临时文件和目录..." "rm -rf /root/percona-server /root/percona-server-build"

echo "MySQL 部署完成
