# 通用 Nginx Docker Compose 配置

这是一个通用的 Nginx Docker Compose 配置模板，支持多种使用场景，方便在不同项目中复用。

## 目录结构

```
nginx/
├── docker-compose.yml          # Docker Compose 配置文件
├── docker-compose.override.yml # 开发环境覆盖配置
├── env.example                 # 环境变量示例文件
├── README.md                   # 详细说明文档
├── scripts/
│   ├── start.sh               # 启动脚本
│   └── stop.sh                # 停止脚本
└── nginx/
    ├── nginx.conf             # Nginx 主配置文件
    ├── conf.d/                # 站点配置文件目录
    │   ├── default.conf       # 默认站点配置
    │   └── ssl.conf           # SSL 配置模板
    ├── html/                  # 网站文件目录
    ├── static/                # 静态资源目录
    ├── ssl/                   # SSL 证书目录
    └── logs/                  # 日志文件目录
```

## 快速开始

### 1. 复制配置到新项目

```bash
# 复制整个目录到新项目
cp -r nginx/ your-project/
cd your-project/
```

### 2. 配置环境变量

```bash
# 复制环境变量示例文件
cp env.example .env

# 编辑环境变量
vim .env
```

### 3. 启动服务

```bash
# 方式一：使用启动脚本（推荐）
./scripts/start.sh

# 方式二：直接使用 docker-compose
docker-compose up -d

# 查看日志
docker-compose logs -f nginx

# 停止服务
./scripts/stop.sh
# 或者
docker-compose down
```

## 环境变量配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NGINX_CONTAINER_NAME` | `nginx-server` | 容器名称 |
| `NGINX_PORT` | `80` | HTTP 端口 |
| `NGINX_SSL_PORT` | `443` | HTTPS 端口 |
| `NGINX_HOST` | `localhost` | 服务器名称 |
| `SITE_NAME` | `my-website` | 网站名称 |
| `SITE_DOMAIN` | `example.com` | 域名 |

## 功能特性

### 1. 基础功能
- ✅ 静态文件服务
- ✅ 目录浏览
- ✅ Gzip 压缩
- ✅ 缓存控制
- ✅ 健康检查
- ✅ 错误页面

### 2. 安全特性
- ✅ 安全头设置
- ✅ XSS 防护
- ✅ 点击劫持防护
- ✅ 内容类型嗅探防护

### 3. 性能优化
- ✅ 静态资源缓存
- ✅ 连接优化
- ✅ 文件传输优化

### 4. 便捷工具
- ✅ 一键启动/停止脚本
- ✅ 环境变量配置
- ✅ 多环境支持（开发/生产）
- ✅ 健康检查监控

## 使用场景

### 1. 静态网站托管

```bash
# 将网站文件放入 html 目录
cp -r your-website/* nginx/html/

# 启动服务
docker-compose up -d
```

### 2. 静态资源服务

```bash
# 将静态资源放入 static 目录
cp -r your-assets/* nginx/static/

# 访问地址：http://localhost/static/
```

### 3. API 代理

编辑 `nginx/conf.d/default.conf`，配置 API 代理：

```nginx
location /api/ {
    proxy_pass http://your-backend:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### 4. HTTPS 配置

1. 将 SSL 证书放入 `nginx/ssl/` 目录
2. 编辑 `nginx/conf.d/ssl.conf`，取消注释并配置证书路径
3. 重启服务

## 常用命令

### 基础操作
```bash
# 启动服务
./scripts/start.sh
# 或者
docker-compose up -d

# 停止服务
./scripts/stop.sh
# 或者
docker-compose down

# 重启服务
docker-compose restart

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f nginx
```

### 容器操作
```bash
# 进入容器
docker-compose exec nginx sh

# 重新加载配置
docker-compose exec nginx nginx -s reload

# 测试配置
docker-compose exec nginx nginx -t

# 查看容器资源使用
docker-compose exec nginx top
```

### 开发环境
```bash
# 使用开发环境配置
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# 清理容器和网络
./scripts/stop.sh --clean
```

## 监控和日志

### 健康检查
访问 `http://localhost/health` 检查服务状态

### 日志查看
```bash
# 查看访问日志
docker-compose exec nginx tail -f /var/log/nginx/access.log

# 查看错误日志
docker-compose exec nginx tail -f /var/log/nginx/error.log

# 查看实时日志
docker-compose logs -f nginx

# 查看最近日志
docker-compose logs --tail=50 nginx
```

### 性能监控
```bash
# 查看容器资源使用情况
docker stats nginx-server

# 查看nginx进程状态
docker-compose exec nginx ps aux

# 查看连接数
docker-compose exec nginx netstat -an | grep :80
```

## 故障排除

### 1. 端口冲突
修改 `.env` 文件中的端口配置：
```
NGINX_PORT=8080
```

### 2. 权限问题
确保目录权限正确：
```bash
chmod -R 755 nginx/html/
chmod -R 755 nginx/static/
chmod +x scripts/*.sh
```

### 3. 配置错误
测试配置文件：
```bash
docker-compose exec nginx nginx -t
```

### 4. 容器启动失败
```bash
# 查看详细错误信息
docker-compose logs nginx

# 检查端口占用
netstat -tlnp | grep :80

# 重新构建并启动
docker-compose down
docker-compose up --build -d
```

### 5. 脚本执行权限
```bash
# 确保脚本有执行权限
chmod +x scripts/start.sh scripts/stop.sh
```

## 扩展配置

### 添加新的站点配置

1. 在 `nginx/conf.d/` 目录下创建新的 `.conf` 文件
2. 配置新的 server 块
3. 重启服务

### 自定义 Nginx 配置

编辑 `nginx/nginx.conf` 文件，添加自定义配置。

### 多站点配置示例

创建 `nginx/conf.d/site1.conf`：
```nginx
server {
    listen 80;
    server_name site1.example.com;
    root /usr/share/nginx/html/site1;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 负载均衡配置示例

创建 `nginx/conf.d/load-balancer.conf`：
```nginx
upstream backend {
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}

server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 最佳实践

### 1. 环境管理
- 使用 `.env` 文件管理环境变量
- 不同环境使用不同的配置文件
- 敏感信息不要提交到版本控制

### 2. 安全配置
- 定期更新 nginx 镜像
- 配置 SSL 证书
- 启用安全头
- 限制文件上传大小

### 3. 性能优化
- 启用 Gzip 压缩
- 配置静态资源缓存
- 使用 CDN 加速
- 监控服务器性能

### 4. 日志管理
- 定期清理日志文件
- 配置日志轮转
- 监控错误日志
- 设置日志告警

## 许可证

MIT License 