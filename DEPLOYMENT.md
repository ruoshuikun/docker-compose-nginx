# CentOS 服务器部署指南

本指南将帮助您在 CentOS 服务器上部署前端应用。

## 前置条件

- ✅ CentOS 7/8/9 系统
- ✅ 已安装 Docker
- ✅ 已安装 Docker Compose
- ✅ 前端代码已打包完成

## 快速部署

### 1. 上传项目文件到服务器

```bash
# 方法一：使用 scp 上传
scp -r nginx/ user@your-server:/home/user/

# 方法二：使用 rsync 上传
rsync -avz nginx/ user@your-server:/home/user/nginx/

# 方法三：使用 git 克隆（推荐）
git clone <your-repository-url> /home/user/nginx
```

### 2. 上传前端代码

```bash
# 上传前端打包后的代码
scp -r dist/ user@your-server:/home/user/frontend-dist/
```

### 3. 登录服务器并部署

```bash
# 登录服务器
ssh user@your-server

# 进入项目目录
cd /home/user/nginx

# 部署前端代码
./scripts/deploy.sh /home/user/frontend-dist

# 启动服务
./scripts/start.sh
```

## 详细部署步骤

### 步骤 1: 准备服务器环境

```bash
# 更新系统
sudo yum update -y

# 安装必要工具
sudo yum install -y git wget curl

# 检查 Docker 版本
docker --version
docker-compose --version
```

### 步骤 2: 创建项目目录

```bash
# 创建项目目录
mkdir -p /home/user/nginx
cd /home/user/nginx

# 设置权限
chmod 755 /home/user/nginx
```

### 步骤 3: 上传项目文件

```bash
# 在本地执行，上传项目文件
scp -r ./* user@your-server:/home/user/nginx/
```

### 步骤 4: 配置环境变量

```bash
# 在服务器上执行
cd /home/user/nginx

# 复制环境变量文件
cp env.example .env

# 编辑环境变量
vim .env
```

环境变量配置示例：
```bash
# Nginx 容器配置
NGINX_CONTAINER_NAME=nginx-server
NGINX_PORT=80
NGINX_SSL_PORT=443
NGINX_HOST=your-domain.com

# 网站配置
SITE_NAME=my-website
SITE_DOMAIN=your-domain.com

# 日志级别
NGINX_LOG_LEVEL=info
```

### 步骤 5: 部署前端代码

```bash
# 上传前端代码到服务器
scp -r dist/ user@your-server:/tmp/frontend-dist/

# 在服务器上部署
./scripts/deploy.sh /tmp/frontend-dist
```

### 步骤 6: 启动服务

```bash
# 启动 nginx 服务
./scripts/start.sh

# 检查服务状态
docker-compose ps

# 查看日志
docker-compose logs -f nginx
```

### 步骤 7: 配置防火墙

```bash
# 开放 HTTP 端口
sudo firewall-cmd --permanent --add-port=80/tcp

# 开放 HTTPS 端口（如果需要）
sudo firewall-cmd --permanent --add-port=443/tcp

# 重新加载防火墙
sudo firewall-cmd --reload

# 查看开放的端口
sudo firewall-cmd --list-ports
```

### 步骤 8: 测试访问

```bash
# 本地测试
curl http://localhost

# 查看容器状态
docker-compose ps

# 查看访问日志
docker-compose exec nginx tail -f /var/log/nginx/access.log
```

## 生产环境配置

### 1. 配置域名

编辑 `nginx/conf.d/default.conf`：
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # 其他配置...
}
```

### 2. 配置 SSL 证书

```bash
# 上传 SSL 证书
scp cert.pem user@your-server:/home/user/nginx/nginx/ssl/
scp key.pem user@your-server:/home/user/nginx/nginx/ssl/

# 编辑 SSL 配置
vim nginx/conf.d/ssl.conf
```

### 3. 配置反向代理

如果需要代理后端 API，编辑 `nginx/conf.d/default.conf`：
```nginx
location /api/ {
    proxy_pass http://your-backend-server:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 监控和维护

### 1. 查看服务状态

```bash
# 查看容器状态
docker-compose ps

# 查看资源使用
docker stats nginx-server

# 查看日志
docker-compose logs -f nginx
```

### 2. 重启服务

```bash
# 重启服务
docker-compose restart

# 重新加载配置
docker-compose exec nginx nginx -s reload
```

### 3. 更新部署

```bash
# 停止服务
./scripts/stop.sh

# 部署新代码
./scripts/deploy.sh /path/to/new-frontend

# 启动服务
./scripts/start.sh
```

### 4. 备份和恢复

```bash
# 备份网站文件
tar -czf backup-$(date +%Y%m%d).tar.gz nginx/html/

# 恢复备份
tar -xzf backup-20240101.tar.gz
```

## 故障排除

### 1. 端口冲突

```bash
# 检查端口占用
netstat -tlnp | grep :80

# 修改端口
vim .env
# 修改 NGINX_PORT=8080
```

### 2. 权限问题

```bash
# 设置目录权限
chmod -R 755 nginx/html/
chmod -R 755 nginx/static/

# 设置脚本权限
chmod +x scripts/*.sh
```

### 3. 容器启动失败

```bash
# 查看详细错误
docker-compose logs nginx

# 重新构建
docker-compose down
docker-compose up --build -d
```

### 4. 配置文件错误

```bash
# 测试配置
docker-compose exec nginx nginx -t

# 查看配置
docker-compose exec nginx nginx -T
```

## 自动化部署

### 1. 创建部署脚本

```bash
#!/bin/bash
# auto-deploy.sh

# 停止服务
./scripts/stop.sh

# 拉取最新代码
git pull origin main

# 部署前端代码
./scripts/deploy.sh /path/to/frontend

# 启动服务
./scripts/start.sh

# 健康检查
sleep 5
curl -f http://localhost/health || exit 1
```

### 2. 设置定时任务

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每天凌晨 2 点更新）
0 2 * * * /home/user/nginx/auto-deploy.sh
```

## 安全建议

1. **定期更新**：定期更新 Docker 镜像和系统
2. **防火墙配置**：只开放必要的端口
3. **SSL 证书**：使用有效的 SSL 证书
4. **访问控制**：配置适当的访问控制
5. **日志监控**：定期检查日志文件
6. **备份策略**：定期备份重要数据

## 性能优化

1. **启用 Gzip**：已在配置中启用
2. **静态资源缓存**：配置适当的缓存策略
3. **CDN 加速**：使用 CDN 加速静态资源
4. **负载均衡**：配置多实例负载均衡

---

*部署完成后，您的网站应该可以通过 http://your-server-ip 访问* 