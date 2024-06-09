# Percona-Server-for-MySQL-installation-script
Percona Server for MySQL installation script
Percona Server for MySQL安装脚本
# 为什么我要写这个脚本？
1，官方文档没有提供需要的依赖，需要等编译报错之后才知道需要哪个依赖，很麻烦！
2，方便我自己快速编译安装Percona Server for MySQL
# 存在的问题？
## PVE无论是kvm虚拟化，还是LXC容器化的debian和ubuntu都没办法正常编译。
我安装了openldap但是，cmake死活无法识别到，我试过手动编译安装openldap，手动使用参数强制指定库文件，还是不行....（我不会编程，不知道咋解决）
ps：我也不知道是不是只有我才有问题，还是官方的代码有问题！
## 脚本是GPT4o写的，我没有测试过能否正常使用！理论上可能也应允许没有问题，有问题就问GPT4o！
# 手动安装流程
## RHEL9安装教学
1，安装依赖
'''
yum install git sudo gcc cmake make gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc openssl-devel openldap-devel cyrus-sasl-devel cyrus-sasl-scram krb5-devel ncurses-devel readline-devel bison libcurl-devel libudev-devel libtirpc-devel rpcgen libaio-devel libtirpc-devel
'''
