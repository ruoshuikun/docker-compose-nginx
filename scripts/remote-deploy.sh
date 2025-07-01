#!/bin/bash

# 远程服务器部署脚本
# 适用于 CentOS/Ubuntu 服务器
# 使用方法: ./scripts/remote-deploy.sh <服务器IP> <用户名> [项目名] [源目录]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# 显示帮助
show_help() {
    echo "远程部署脚本 - 适用于 CentOS/Ubuntu 服务器"
    echo ""
    echo "使用方法:"
    echo "  $0 <服务器IP> <用户名>                    # 仅部署项目框架"
    echo "  $0 <服务器IP> <用户名> <项目名> <源目录>   # 部署框架+前端项目"
    echo ""
    echo "示例:"
    echo "  $0 192.168.1.100 root                    # 部署到服务器"
    echo "  $0 192.168.1.100 root web /path/to/dist  # 部署框架+web项目"
    echo ""
    echo "环境要求:"
    echo "  - 服务器已安装 Docker 和 Docker Compose"
    echo "  - 已配置 SSH 密钥认证或密码认证"
    echo "  - 防火墙已开放 80 端口"
}

# 检查参数
if [[ $# -lt 2 ]]; then
    show_help
    exit 1
fi

SERVER_IP="$1"
USERNAME="$2"
PROJECT_NAME="$3"
SOURCE_DIR="$4"
REMOTE_DIR="/opt/nginx-project-manager"

# 检查源目录（如果提供了项目参数）
if [[ -n "$PROJECT_NAME" && -n "$SOURCE_DIR" ]]; then
    if [[ ! -d "$SOURCE_DIR" ]]; then
        print_error "源目录不存在: $SOURCE_DIR"
        exit 1
    fi
    
    if [[ ! -f "$SOURCE_DIR/index.html" ]]; then
        print_error "源目录中未找到 index.html"
        exit 1
    fi
fi

print_step "开始部署到服务器 $SERVER_IP..."

# 检查 SSH 连接
print_info "检查 SSH 连接..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$USERNAME@$SERVER_IP" exit 2>/dev/null; then
    print_error "无法连接到服务器 $SERVER_IP"
    print_warn "请确保 SSH 连接正常"
    exit 1
fi

# 检查服务器环境
print_info "检查服务器环境..."
ssh "$USERNAME@$SERVER_IP" << 'EOF'
    # 检查操作系统
    if [[ -f /etc/redhat-release ]]; then
        echo "检测到 CentOS/RHEL 系统"
        OS="centos"
    elif [[ -f /etc/debian_version ]]; then
        echo "检测到 Ubuntu/Debian 系统"  
        OS="ubuntu"
    else
        echo "未能识别操作系统"
    fi
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker 未安装"
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "ERROR: Docker Compose 未安装"
        exit 1
    fi
    
    # 检查 Docker 服务
    if ! docker info &> /dev/null; then
        echo "ERROR: Docker 服务未运行"
        exit 1
    fi
    
    echo "环境检查通过"
EOF

if [[ $? -ne 0 ]]; then
    print_error "服务器环境检查失败"
    exit 1
fi

# 创建远程目录
print_info "创建远程目录..."
ssh "$USERNAME@$SERVER_IP" "sudo mkdir -p $REMOTE_DIR && sudo chown $USERNAME:$USERNAME $REMOTE_DIR"

# 上传项目文件
print_info "上传项目文件..."
rsync -avz --exclude='.git' --exclude='backup' --exclude='nginx/logs/*' --exclude='nginx/html/web' \
    ./ "$USERNAME@$SERVER_IP:$REMOTE_DIR/"

# 如果提供了前端项目，上传前端代码
if [[ -n "$PROJECT_NAME" && -n "$SOURCE_DIR" ]]; then
    print_info "上传前端项目: $PROJECT_NAME"
    ssh "$USERNAME@$SERVER_IP" "mkdir -p /tmp/frontend-dist"
    rsync -avz "$SOURCE_DIR/" "$USERNAME@$SERVER_IP:/tmp/frontend-dist/"
fi

# 在服务器上执行部署
print_info "在服务器上执行部署..."
ssh "$USERNAME@$SERVER_IP" << EOF
    cd $REMOTE_DIR
    
    # 设置脚本权限
    chmod +x nginx-manager.sh
    chmod +x scripts/*.sh
    
    # 配置环境变量
    if [[ ! -f .env ]]; then
        cp env.example .env
        echo "已创建 .env 文件"
    fi
    
    # 启动基础服务
    ./nginx-manager.sh start
    
    # 如果有前端项目，进行部署
    if [[ -n "$PROJECT_NAME" && -d /tmp/frontend-dist ]]; then
        ./nginx-manager.sh deploy "$PROJECT_NAME" /tmp/frontend-dist
        rm -rf /tmp/frontend-dist
    fi
    
    # 检查服务状态
    ./nginx-manager.sh status
EOF

# 配置防火墙
print_info "配置防火墙..."
ssh "$USERNAME@$SERVER_IP" << 'EOF'
    # CentOS/RHEL 防火墙
    if command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
        echo "CentOS 防火墙配置完成"
    fi
    
    # Ubuntu 防火墙
    if command -v ufw &> /dev/null; then
        sudo ufw allow 80/tcp 2>/dev/null || true
        echo "Ubuntu 防火墙配置完成"
    fi
EOF

# 等待服务启动
print_info "等待服务启动..."
sleep 5

# 测试访问
print_info "测试服务访问..."
if curl -f -s "http://$SERVER_IP" > /dev/null; then
    print_info "✅ 服务启动成功！"
else
    print_warn "⚠️  服务可能还在启动中"
fi

# 显示部署结果
echo ""
print_info "🎉 部署完成！"
echo ""
echo "服务器信息:"
echo "  IP 地址: $SERVER_IP"
echo "  项目目录: $REMOTE_DIR"
echo "  访问地址: http://$SERVER_IP"
echo ""

if [[ -n "$PROJECT_NAME" ]]; then
    echo "项目信息:"
    echo "  项目名称: $PROJECT_NAME"
    echo "  访问地址: http://$SERVER_IP/$PROJECT_NAME/"
    echo ""
fi

echo "管理命令:"
echo "  查看状态: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && ./nginx-manager.sh status'"
echo "  查看日志: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && ./nginx-manager.sh logs'"
echo "  部署项目: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && ./nginx-manager.sh deploy <项目名> <源目录>'"
echo "  重启服务: ssh $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && ./nginx-manager.sh restart'"
echo ""

print_info "远程部署完成！" 