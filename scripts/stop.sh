#!/bin/bash

# 通用 Nginx Docker Compose 停止脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 停止服务
stop_services() {
    print_message "停止 Nginx 服务..."
    docker-compose down
    
    if [ $? -eq 0 ]; then
        print_message "Nginx 服务已停止"
    else
        print_error "停止服务时发生错误"
        exit 1
    fi
}

# 清理容器和网络（可选）
cleanup() {
    if [ "$1" = "--clean" ]; then
        print_warning "清理容器和网络..."
        docker-compose down --volumes --remove-orphans
        print_message "清理完成"
    fi
}

# 主函数
main() {
    print_message "开始停止通用 Nginx 服务..."
    
    stop_services
    cleanup "$1"
    
    print_message "停止完成！"
}

# 脚本入口
main "$@" 