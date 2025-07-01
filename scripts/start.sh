#!/bin/bash

# 通用 Nginx Docker Compose 启动脚本

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

# 检查 Docker 是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker 未运行，请先启动 Docker"
        exit 1
    fi
}

# 检查 Docker Compose 是否可用
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        print_error "Docker Compose 未安装"
        exit 1
    fi
}

# 创建必要的目录
create_directories() {
    print_message "创建必要的目录..."
    mkdir -p nginx/html nginx/static nginx/ssl nginx/logs nginx/conf.d
}

# 复制环境变量文件
setup_env() {
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            print_message "复制环境变量文件..."
            cp env.example .env
            print_warning "请编辑 .env 文件配置您的环境变量"
        else
            print_warning "未找到 env.example 文件，请手动创建 .env 文件"
        fi
    fi
}

# 启动服务
start_services() {
    print_message "启动 Nginx 服务..."
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_message "Nginx 服务启动成功！"
        print_message "访问地址: http://localhost:${NGINX_PORT:-80}"
        print_message "健康检查: http://localhost:${NGINX_PORT:-80}/health"
    else
        print_error "Nginx 服务启动失败"
        exit 1
    fi
}

# 显示服务状态
show_status() {
    print_message "服务状态："
    docker-compose ps
    
    print_message "最近日志："
    docker-compose logs --tail=10 nginx
}

# 主函数
main() {
    print_message "开始启动通用 Nginx 服务..."
    
    check_docker
    check_docker_compose
    create_directories
    setup_env
    start_services
    show_status
    
    print_message "启动完成！"
}

# 脚本入口
main "$@" 