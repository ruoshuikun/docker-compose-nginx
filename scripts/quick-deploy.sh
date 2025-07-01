#!/bin/bash

# 快速部署脚本 - 一键部署前端应用到 CentOS 服务器
# 使用方法: ./scripts/quick-deploy.sh [服务器IP] [用户名] [前端代码目录]

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
if [ $# -lt 3 ]; then
    print_error "参数不足"
    echo "使用方法: $0 <服务器IP> <用户名> <前端代码目录>"
    echo "示例: $0 192.168.1.100 root /path/to/dist"
    exit 1
fi

SERVER_IP="$1"
USERNAME="$2"
FRONTEND_DIR="$3"
REMOTE_DIR="/home/$USERNAME/nginx"

# 检查前端代码目录
if [ ! -d "$FRONTEND_DIR" ]; then
    print_error "前端代码目录不存在: $FRONTEND_DIR"
    exit 1
fi

if [ ! -f "$FRONTEND_DIR/index.html" ]; then
    print_error "前端代码目录中没有找到 index.html 文件"
    exit 1
fi

print_step "开始快速部署到服务器 $SERVER_IP..."

# 1. 检查 SSH 连接
print_message "检查 SSH 连接..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$USERNAME@$SERVER_IP" exit 2>/dev/null; then
    print_error "无法连接到服务器 $SERVER_IP"
    print_warning "请确保："
    echo "  1. 服务器 IP 地址正确"
    echo "  2. 用户名正确"
    echo "  3. SSH 密钥已配置或密码认证已启用"
    exit 1
fi

# 2. 检查服务器环境
print_message "检查服务器环境..."
ssh "$USERNAME@$SERVER_IP" << 'EOF'
    # 检查 Docker
    if ! command -v docker > /dev/null 2>&1; then
        echo "Docker 未安装"
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose > /dev/null 2>&1; then
        echo "Docker Compose 未安装"
        exit 1
    fi
    
    echo "环境检查通过"
EOF

# 3. 创建远程目录
print_message "创建远程目录..."
ssh "$USERNAME@$SERVER_IP" "mkdir -p $REMOTE_DIR"

# 4. 上传项目文件
print_message "上传项目文件..."
rsync -avz --exclude='.git' --exclude='backup' --exclude='nginx/logs/*' --exclude='nginx/ssl/*' \
    ./ "$USERNAME@$SERVER_IP:$REMOTE_DIR/"

# 5. 上传前端代码
print_message "上传前端代码..."
ssh "$USERNAME@$SERVER_IP" "mkdir -p /tmp/frontend-dist"
rsync -avz "$FRONTEND_DIR/" "$USERNAME@$SERVER_IP:/tmp/frontend-dist/"

# 6. 在服务器上执行部署
print_message "在服务器上执行部署..."
ssh "$USERNAME@$SERVER_IP" << EOF
    cd $REMOTE_DIR
    
    # 设置脚本权限
    chmod +x scripts/*.sh
    
    # 配置环境变量
    if [ ! -f .env ]; then
        cp env.example .env
        echo "已创建 .env 文件，请根据需要编辑配置"
    fi
    
    # 部署前端代码
    ./scripts/deploy.sh /tmp/frontend-dist
    
    # 启动服务
    ./scripts/start.sh
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    docker-compose ps
    
    # 清理临时文件
    rm -rf /tmp/frontend-dist
EOF

# 7. 配置防火墙
print_message "配置防火墙..."
ssh "$USERNAME@$SERVER_IP" << 'EOF'
    # 开放 HTTP 端口
    sudo firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "防火墙配置完成"
EOF

# 8. 测试访问
print_message "测试服务访问..."
sleep 3
if curl -f -s "http://$SERVER_IP" > /dev/null; then
    print_message "✅ 服务启动成功！"
else
    print_warning "⚠️  服务可能还在启动中，请稍后测试"
fi

# 9. 显示部署结果
print_message "部署完成！"
echo ""
print_message "部署信息:"
echo "  - 服务器: $SERVER_IP"
echo "  - 项目目录: $REMOTE_DIR"
echo "  - 前端代码: $FRONTEND_DIR"
echo "  - 访问地址: http://$SERVER_IP"
echo ""

print_step "后续操作:"
echo "  1. 查看服务状态: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && docker-compose ps'"
echo "  2. 查看日志: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && docker-compose logs -f nginx'"
echo "  3. 更新配置: 编辑 $REMOTE_DIR/.env 文件"
echo "  4. 重新部署: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && ./scripts/deploy.sh /path/to/new-frontend'"
echo ""

print_message "快速部署脚本执行完成！" 