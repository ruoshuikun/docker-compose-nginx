#!/bin/bash

# Nginx 多项目管理工具
# 适用于 CentOS/Ubuntu 服务器
# 作者: AI Assistant
# 版本: 2.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目信息
PROJECT_NAME="nginx-project-manager"
VERSION="2.0"
HTML_DIR="nginx/html"
BACKUP_DIR="backup"

# 打印函数
print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  Nginx 多项目管理工具                      ║"
    echo "║                     版本: $VERSION                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 检查系统环境
check_system() {
    print_step "检查系统环境..."
    
    # 检查操作系统
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        print_info "检测到 CentOS/RHEL 系统"
    elif [[ -f /etc/debian_version ]]; then
        OS="ubuntu"
        print_info "检测到 Ubuntu/Debian 系统"
    else
        print_warn "未能识别操作系统类型，继续执行..."
        OS="unknown"
    fi
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装"
        echo "安装命令："
        if [[ "$OS" == "centos" ]]; then
            echo "  sudo yum install -y docker-ce"
        else
            echo "  sudo apt update && sudo apt install -y docker.io"
        fi
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装"
        echo "安装命令："
        echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        echo "  sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi
    
    # 检查 Docker 服务
    if ! docker info &> /dev/null; then
        print_error "Docker 服务未运行"
        echo "启动命令："
        echo "  sudo systemctl start docker"
        echo "  sudo systemctl enable docker"
        exit 1
    fi
    
    print_success "系统环境检查通过"
}

# 显示帮助信息
show_help() {
    print_banner
    echo "使用方法: $0 [命令] [选项]"
    echo ""
    echo "基础命令:"
    echo "  start              启动 nginx 服务"
    echo "  stop               停止 nginx 服务"
    echo "  restart            重启 nginx 服务"
    echo "  status             查看服务状态"
    echo "  logs               查看服务日志"
    echo ""
    echo "项目管理:"
    echo "  deploy <项目名> <源目录>    部署新项目"
    echo "  list               列出所有项目"
    echo "  remove <项目名>    删除项目"
    echo "  backup <项目名>    备份项目"
    echo "  shared             管理共享静态资源"
    echo ""
    echo "配置管理:"
    echo "  reload             重新加载 nginx 配置"
    echo "  test               测试 nginx 配置"
    echo "  edit               编辑 nginx 配置"
    echo ""
    echo "系统维护:"
    echo "  clean              清理系统（停止服务并删除容器）"
    echo "  update             更新项目配置"
    echo "  health             健康检查"
    echo ""
    echo "示例:"
    echo "  $0 deploy web /path/to/dist     # 部署 web 项目"
    echo "  $0 deploy admin /path/to/admin  # 部署 admin 项目"
    echo "  $0 list                         # 查看所有项目"
    echo "  $0 shared upload /path/to/tiles tiles  # 上传地图瓦片"
    echo "  $0 status                       # 查看服务状态"
}

# 创建必要目录
setup_directories() {
    print_step "创建项目目录..."
    mkdir -p nginx/{conf.d,html,logs,ssl,static} $BACKUP_DIR
    
    # 创建共享资源目录
    mkdir -p nginx/html/shared/{maps,tiles,images,fonts,icons,libs}
    
    # 设置环境变量
    if [[ ! -f .env ]]; then
        if [[ -f env.example ]]; then
            cp env.example .env
            print_info "创建 .env 文件"
        fi
    fi
}

# 启动服务
start_service() {
    print_step "启动 nginx 服务..."
    setup_directories
    
    docker-compose up -d
    if [[ $? -eq 0 ]]; then
        print_success "服务启动成功！"
        show_service_info
    else
        print_error "服务启动失败"
        exit 1
    fi
}

# 停止服务
stop_service() {
    print_step "停止 nginx 服务..."
    docker-compose down
    print_success "服务已停止"
}

# 重启服务
restart_service() {
    print_step "重启 nginx 服务..."
    docker-compose restart nginx
    print_success "服务已重启"
    show_service_info
}

# 查看服务状态
show_status() {
    print_step "服务状态："
    docker-compose ps
    echo ""
    
    # 检查端口
    local port=$(grep NGINX_PORT .env 2>/dev/null | cut -d'=' -f2 || echo "80")
    if netstat -tlnp 2>/dev/null | grep ":$port " > /dev/null; then
        print_success "端口 $port 正在监听"
    else
        print_warn "端口 $port 未在监听"
    fi
}

# 查看日志
show_logs() {
    local lines=${1:-50}
    print_step "显示最近 $lines 行日志："
    docker-compose logs --tail=$lines nginx
}

# 部署项目
deploy_project() {
    local project_name="$1"
    local source_dir="$2"
    
    if [[ -z "$project_name" || -z "$source_dir" ]]; then
        print_error "参数错误"
        echo "使用方法: $0 deploy <项目名> <源目录>"
        echo "示例: $0 deploy web /path/to/dist"
        exit 1
    fi
    
    if [[ ! -d "$source_dir" ]]; then
        print_error "源目录不存在: $source_dir"
        exit 1
    fi
    
    if [[ ! -f "$source_dir/index.html" ]]; then
        print_error "源目录中未找到 index.html"
        exit 1
    fi
    
    local target_dir="$HTML_DIR/$project_name"
    
    print_step "部署项目 '$project_name'..."
    
    # 备份现有项目
    if [[ -d "$target_dir" ]]; then
        backup_project "$project_name"
    fi
    
    # 创建目录并复制文件
    mkdir -p "$target_dir"
    cp -r "$source_dir"/* "$target_dir/"
    chmod -R 755 "$target_dir"
    
    print_success "项目 '$project_name' 部署成功"
    echo "访问地址: http://localhost/$project_name/"
    
    # 重新加载 nginx 配置
    reload_config
}

# 列出所有项目
list_projects() {
    print_step "已部署的项目："
    if [[ -d "$HTML_DIR" ]]; then
        for project in "$HTML_DIR"/*; do
            if [[ -d "$project" ]]; then
                local name=$(basename "$project")
                local size=$(du -sh "$project" 2>/dev/null | cut -f1)
                local files=$(find "$project" -type f | wc -l)
                printf "  %-15s 大小: %-8s 文件数: %s\n" "$name" "$size" "$files"
            fi
        done
    else
        print_warn "未找到项目目录"
    fi
}

# 删除项目
remove_project() {
    local project_name="$1"
    
    if [[ -z "$project_name" ]]; then
        print_error "请指定项目名称"
        echo "使用方法: $0 remove <项目名>"
        exit 1
    fi
    
    local target_dir="$HTML_DIR/$project_name"
    
    if [[ ! -d "$target_dir" ]]; then
        print_error "项目不存在: $project_name"
        exit 1
    fi
    
    # 确认删除
    read -p "确定要删除项目 '$project_name' 吗? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_project "$project_name"
        rm -rf "$target_dir"
        print_success "项目 '$project_name' 已删除"
    else
        print_info "取消删除操作"
    fi
}

# 备份项目
backup_project() {
    local project_name="$1"
    local target_dir="$HTML_DIR/$project_name"
    
    if [[ ! -d "$target_dir" ]]; then
        print_warn "项目不存在，跳过备份: $project_name"
        return
    fi
    
    local backup_path="$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)_$project_name"
    mkdir -p "$backup_path"
    cp -r "$target_dir"/* "$backup_path/"
    print_info "项目备份完成: $backup_path"
}

# 管理共享静态资源
manage_shared_resources() {
    local action="$1"
    local shared_dir="$HTML_DIR/shared"
    
    case "$action" in
        "list"|"ls")
            print_step "共享静态资源目录结构："
            if [[ -d "$shared_dir" ]]; then
                tree "$shared_dir" 2>/dev/null || find "$shared_dir" -type f | sort
            else
                print_warn "共享资源目录不存在"
            fi
            ;;
        "info")
            print_step "共享资源信息："
            if [[ -d "$shared_dir" ]]; then
                echo "  位置: $shared_dir"
                echo "  访问: http://localhost/shared/"
                echo "  大小: $(du -sh "$shared_dir" 2>/dev/null | cut -f1)"
                echo "  文件数: $(find "$shared_dir" -type f 2>/dev/null | wc -l)"
                echo ""
                echo "  子目录："
                echo "    /shared/maps/     - 地图相关文件"
                echo "    /shared/tiles/    - 地图瓦片"
                echo "    /shared/images/   - 通用图片"
                echo "    /shared/fonts/    - 字体文件"
                echo "    /shared/icons/    - 图标文件"
                echo "    /shared/libs/     - 共享JS库"
            else
                print_warn "共享资源目录不存在"
            fi
            ;;
        "create"|"init")
            print_step "初始化共享资源目录..."
            mkdir -p "$shared_dir"/{maps,tiles,images,fonts,icons,libs}
            
            # 创建说明文件
            cat > "$shared_dir/README.md" << 'EOF'
# 共享静态资源目录

该目录用于存放所有项目都可能用到的静态资源。

## 目录结构

- `maps/` - 地图相关文件
- `tiles/` - 地图瓦片 (如：{z}/{x}/{y}.png)
- `images/` - 通用图片资源
- `fonts/` - 字体文件
- `icons/` - 图标文件
- `libs/` - 共享JavaScript库

## 访问方式

所有资源都可以通过 `/shared/` 路径访问：

```
http://域名/shared/maps/world.json
http://域名/shared/tiles/0/0/0.png
http://域名/shared/images/logo.png
http://域名/shared/fonts/custom.woff2
```

## 使用示例

### 地图瓦片
```javascript
const tileUrl = '/shared/tiles/{z}/{x}/{y}.png';
```

### 共享图片
```html
<img src="/shared/images/common-logo.png" alt="Logo">
```

### 字体文件
```css
@font-face {
    font-family: 'CustomFont';
    src: url('/shared/fonts/custom.woff2') format('woff2');
}
```
EOF
            
            print_success "共享资源目录初始化完成"
            print_info "访问地址: http://localhost/shared/"
            ;;
        "upload")
            local source_dir="$2"
            local target_subdir="$3"
            
            if [[ -z "$source_dir" ]]; then
                print_error "请指定源目录"
                echo "使用方法: $0 shared upload <源目录> [目标子目录]"
                echo "示例: $0 shared upload /path/to/tiles tiles"
                return 1
            fi
            
            if [[ ! -d "$source_dir" ]]; then
                print_error "源目录不存在: $source_dir"
                return 1
            fi
            
            local target_dir="$shared_dir"
            if [[ -n "$target_subdir" ]]; then
                target_dir="$shared_dir/$target_subdir"
                mkdir -p "$target_dir"
            fi
            
            print_step "上传共享资源..."
            cp -r "$source_dir"/* "$target_dir/"
            chmod -R 755 "$target_dir"
            
            print_success "共享资源上传完成"
            print_info "目标位置: $target_dir"
            ;;
        *)
            print_error "未知操作: $action"
            echo ""
            echo "共享资源管理命令:"
            echo "  shared list        - 列出共享资源"
            echo "  shared info        - 显示共享资源信息"
            echo "  shared create      - 初始化共享资源目录"
            echo "  shared upload <源目录> [子目录] - 上传资源"
            echo ""
            echo "示例:"
            echo "  $0 shared create"
            echo "  $0 shared upload /path/to/tiles tiles"
            echo "  $0 shared upload /path/to/maps maps"
            echo "  $0 shared list"
            ;;
    esac
}

# 重新加载配置
reload_config() {
    print_step "重新加载 nginx 配置..."
    if docker-compose ps | grep nginx | grep Up > /dev/null; then
        docker exec $(docker-compose ps -q nginx) nginx -s reload
        print_success "配置重新加载成功"
    else
        print_warn "nginx 服务未运行"
    fi
}

# 测试配置
test_config() {
    print_step "测试 nginx 配置..."
    if docker-compose ps | grep nginx | grep Up > /dev/null; then
        docker exec $(docker-compose ps -q nginx) nginx -t
        print_success "配置测试通过"
    else
        print_warn "nginx 服务未运行"
    fi
}

# 编辑配置
edit_config() {
    local editor=${EDITOR:-nano}
    print_step "编辑 nginx 配置..."
    $editor nginx/conf.d/default.conf
    
    read -p "是否重新加载配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reload_config
    fi
}

# 清理系统
clean_system() {
    print_step "清理系统..."
    read -p "这将停止服务并删除容器，确定继续? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down --volumes --remove-orphans
        docker system prune -f
        print_success "系统清理完成"
    else
        print_info "取消清理操作"
    fi
}

# 健康检查
health_check() {
    print_step "执行健康检查..."
    
    # 检查服务状态
    if ! docker-compose ps | grep nginx | grep Up > /dev/null; then
        print_error "nginx 服务未运行"
        return 1
    fi
    
    # 检查端口
    local port=$(grep NGINX_PORT .env 2>/dev/null | cut -d'=' -f2 || echo "80")
    if ! curl -f -s "http://localhost:$port/health" > /dev/null; then
        print_warn "健康检查端点无响应"
    fi
    
    # 检查项目
    local project_count=$(find "$HTML_DIR" -maxdepth 1 -type d | wc -l)
    print_info "发现 $((project_count - 1)) 个项目"
    
    # 检查磁盘空间
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 80 ]]; then
        print_warn "磁盘使用率: $disk_usage%"
    else
        print_info "磁盘使用率: $disk_usage%"
    fi
    
    print_success "健康检查完成"
}

# 显示服务信息
show_service_info() {
    local port=$(grep NGINX_PORT .env 2>/dev/null | cut -d'=' -f2 || echo "80")
    echo ""
    print_info "服务信息:"
    echo "  访问地址: http://localhost:$port"
    echo "  健康检查: http://localhost:$port/health"
    echo "  配置文件: nginx/conf.d/default.conf"
    echo "  日志目录: nginx/logs/"
    echo ""
}

# 主函数
main() {
    case "${1:-help}" in
        "start")
            check_system
            start_service
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            check_system
            restart_service
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "${2:-50}"
            ;;
        "deploy")
            check_system
            deploy_project "$2" "$3"
            ;;
        "list")
            list_projects
            ;;
        "remove")
            remove_project "$2"
            ;;
        "backup")
            backup_project "$2"
            ;;
        "shared")
            manage_shared_resources "$2" "$3" "$4"
            ;;
        "reload")
            reload_config
            ;;
        "test")
            test_config
            ;;
        "edit")
            edit_config
            ;;
        "clean")
            clean_system
            ;;
        "health")
            health_check
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
main "$@" 