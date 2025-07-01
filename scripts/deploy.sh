#!/bin/bash

# 前端代码部署脚本
# 使用方法: ./scripts/deploy.sh [前端代码目录]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    print_error "请提供前端代码目录路径"
    echo "使用方法: $0 <前端代码目录>"
    echo "示例: $0 /path/to/dist"
    exit 1
fi

FRONTEND_DIR="$1"

# 检查前端代码目录是否存在
if [ ! -d "$FRONTEND_DIR" ]; then
    print_error "前端代码目录不存在: $FRONTEND_DIR"
    exit 1
fi

# 检查是否有 index.html
if [ ! -f "$FRONTEND_DIR/index.html" ]; then
    print_error "前端代码目录中没有找到 index.html 文件"
    print_warning "请确保这是正确的前端打包目录"
    exit 1
fi

print_step "开始部署前端代码..."

# 1. 备份当前网站文件
print_message "备份当前网站文件..."
if [ -d "nginx/html" ] && [ "$(ls -A nginx/html)" ]; then
    BACKUP_DIR="backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r nginx/html/* "$BACKUP_DIR/"
    print_message "备份完成: $BACKUP_DIR"
fi

# 2. 清理网站目录
print_message "清理网站目录..."
rm -rf nginx/html/*
rm -f nginx/html/.gitkeep

# 3. 复制前端代码
print_message "复制前端代码到 nginx/html/..."
cp -r "$FRONTEND_DIR"/* nginx/html/

# 4. 检查复制结果
print_message "检查部署结果..."
if [ -f "nginx/html/index.html" ]; then
    print_message "✅ index.html 部署成功"
else
    print_error "❌ index.html 部署失败"
    exit 1
fi

# 5. 设置权限
print_message "设置文件权限..."
chmod -R 755 nginx/html/

# 6. 显示部署信息
print_message "部署完成！"
echo ""
print_message "部署信息:"
echo "  - 前端代码目录: $FRONTEND_DIR"
echo "  - 部署位置: nginx/html/"
echo "  - 文件数量: $(find nginx/html -type f | wc -l)"
echo ""

# 7. 提示下一步操作
print_step "下一步操作:"
echo "  1. 启动服务: ./scripts/start.sh"
echo "  2. 查看状态: docker-compose ps"
echo "  3. 查看日志: docker-compose logs -f nginx"
echo "  4. 访问网站: http://localhost:80"
echo ""

# 8. 询问是否立即启动服务
read -p "是否立即启动 nginx 服务? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "启动 nginx 服务..."
    ./scripts/start.sh
fi

print_message "部署脚本执行完成！" 