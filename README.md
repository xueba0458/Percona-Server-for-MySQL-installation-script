# Percona Server for MySQL 安装脚本

这个脚本可以帮助您快速安装 Percona Server for MySQL。

## 快速执行脚本
您可以使用以下命令快速下载并执行安装脚本：
### 使用 `curl`
```sh
curl -fsSL https://raw.githubusercontent.com/xueba0458/Percona-Server-for-MySQL-installation-script/main/install.sh | bash
```

### 使用 `wget`

```shell
wget -qO- https://raw.githubusercontent.com/xueba0458/Percona-Server-for-MySQL-installation-script/main/install.sh | bash
```

## 支持的语言

- [English](#english)
- [简体中文](#简体中文)

## English

### Why did I write this script?

1. The official documentation does not provide the required dependencies. You need to wait for the compilation error to know which dependency is needed, which is very troublesome!
2. It is convenient for me to quickly compile and install Percona Server for MySQL.

### Existing problems?

- **PVE, whether it is KVM virtualization or LXC containerized Debian and Ubuntu, cannot be compiled normally.**  I installed openldap, but cmake could not recognize it. I tried to manually compile and install openldap, and manually use parameters to force the specified library file, but it still doesn't work.... (I don't know how to program, I don't know how to solve it)
ps: I don't know if I'm the only one with this problem, or if there is a problem with the official code!

- **The script was written by GPT4o, I haven't tested if it works properly! In theory it should work, if there are any problems, ask GPT4o!**

### Manual installation process

#### RHEL9 installation tutorial

##### Compile binary

1. Install dependencies:

```shell
yum install git sudo gcc cmake make gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc openssl-devel openldap-devel cyrus-sasl-devel cyrus-sasl-scram krb5-devel ncurses-devel readline-devel bison libcurl-devel libudev-devel libtirpc-devel rpcgen libaio-devel libtirpc-devel
```

2. Pull the Percona Server for MySQL source code:

```
cd /root
git config --global http.postBuffer 524288000
git clone https://github.com/percona/percona-server.git
cd percona-server
```

3. Set the code branch:

```shell
git checkout 8.0
git submodule init
git submodule update
```

4. A lot of files will be generated during the compilation process, create a folder to store them:

```shell
cmake ../percona-server -DDOWNLOAD_BOOST=1 -DWITH_BOOST=./boost -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CONFIG=mysql_release -DFEATURE_SET=community
```

5. Compile:

```shell
make -j4
```
ps: -j4 is configured according to the performance of your own server

6. Install:

```shell
make install
```

##### Configure and start MySQL

1. Create a user named mysql:

```shell
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
```

2. Create directory:

```shell
cd /usr/local/mysql
cd /usr/local/mysql && mkdir -p /usr/local/mysql/etc && mkdir -p mysql-files
```

3. Set permissions:

```shell
chown mysql:mysql mysql-files && chmod 750 mysql-files
```

4. Initialize the database:

```shell
cd /usr/local/mysql
./bin/mysqld --initialize-insecure --user=mysql
```

5. Configure environment variables:

```shell
if ! grep -q "MYSQLPATH=/usr/local/mysql" /etc/profile; then
    run_command "Configuring environment variables..." "echo 'export MYSQLPATH=/usr/local/mysql' >> /etc/profile && echo 'export PATH=\$MYSQLPATH/bin:\$MYSQLPATH/lib:\$PATH' >> /etc/profile && source /etc/profile"
else
    echo "Environment variables have been configured, skip."
fi
```

6. Create a configuration file, remember to modify the parameters yourself, otherwise don't blame me if there is a problem...

```shell
if [ ! -f "/usr/local/mysql/etc/my.cnf" ]; then
    echo "Creating MySQL configuration file..."
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
    echo "MySQL configuration file already exists, skip creation."
fi
```

## 简体中文

### 我为什么要写这个脚本？

1. 官方文档没有提供需要的依赖，需要等编译报错之后才知道需要哪个依赖，很麻烦！
2. 方便我自己快速编译安装 Percona Server for MySQL

### 存在的问题？

- **PVE 无论是 KVM 虚拟化，还是 LXC 容器化的 Debian 和 Ubuntu 都没办法正常编译。** 我安装了 openldap，但是 cmake 死活无法识别到，我试过手动编译安装 openldap，手动使用参数强制指定库文件，还是不行....（我不会编程，不知道咋解决）
ps：我也不知道是不是只有我才有问题，还是官方的代码有问题！

- **脚本是 GPT4o 写的，我没有测试过能否正常使用！理论上可能也应该没有问题，有问题就问 GPT4o！**

### 手动安装流程

#### RHEL9 安装教程

##### 编译二进制

1. 安装依赖：

```shell
yum install git sudo gcc cmake make gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc openssl-devel openldap-devel cyrus-sasl-devel cyrus-sasl-scram krb5-devel ncurses-devel readline-devel bison libcurl-devel libudev-devel libtirpc-devel rpcgen libaio-devel libtirpc-devel
```

2. 拉取 Percona Server for MySQL 源代码：

```
cd /root
git config --global http.postBuffer 524288000
git clone https://github.com/percona/percona-server.git
cd percona-server
```

3. 设置代码分支：

```shell
git checkout 8.0
git submodule init
git submodule update
```

4. 编译过程中会生成很多文件，创建一个文件夹用来存放：

```shell
cmake ../percona-server -DDOWNLOAD_BOOST=1 -DWITH_BOOST=./boost -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_CONFIG=mysql_release -DFEATURE_SET=community
```

5. 编译：

```shell
make -j4
```

ps: -j4 按自己的服务器性能配置

6. 安装：

```shell
make install
```

##### 配置启动 MySQL

1. 创建一个叫 mysql 的用户：

```shell
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
```

2. 创建目录：

```shell
cd /usr/local/mysql
cd /usr/local/mysql && mkdir -p /usr/local/mysql/etc && mkdir -p mysql-files
```

3. 设置权限：

```shell
chown mysql:mysql mysql-files && chmod 750 mysql-files
```

4. 初始化数据库：

```shell
cd /usr/local/mysql
./bin/mysqld --initialize-insecure --user=mysql
```

5. 配置环境变量：

```shell
if ! grep -q "MYSQLPATH=/usr/local/mysql" /etc/profile; then
    run_command "配置环境变量..." "echo 'export MYSQLPATH=/usr/local/mysql' >> /etc/profile && echo 'export PATH=\$MYSQLPATH/bin:\$MYSQLPATH/lib:\$PATH' >> /etc/profile && source /etc/profile"
else
    echo "环境变量已配置，跳过。"
fi
```

6. 创建配置文件，记得自己修改参数，不然出了问题别怪我...

```shell
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
```
