# Nginx 配置修改操作指南

## 项目概述
- **项目路径**: `/home/lin/docker/docker-compose/nginx-project-manager`
- **容器名称**: `nginx-project-manager`
- **使用技术**: Docker Compose + Nginx + 多个 Vue 3 SPA 项目
- **架构特点**: 支持多个前端项目的独立部署和访问

## 🏗️ 多项目架构设计

### 推荐的目录结构
```
nginx/html/
├── web/                    # 项目1
│   ├── index.html         # 项目1的入口文件
│   ├── assets/            # 项目1的静态资源
│   │   ├── index-xxx.js
│   │   └── index-xxx.css
│   ├── libs/              # 项目1的第三方库
│   │   └── mathpix-markdown-it/
│   └── favicon.ico        # 项目1的图标
├── web2/                   # 项目2
│   ├── index.html         # 项目2的入口文件
│   ├── assets/            # 项目2的静态资源
│   └── favicon.ico        # 项目2的图标
├── admin/                  # 管理后台项目
│   ├── index.html
│   ├── assets/
│   └── favicon.ico
└── shared/                 # 共享资源（可选）
    └── common-libs/
```

### 访问路径规则
- **项目web**: `http://localhost/web/`
- **项目web2**: `http://localhost/web2/`
- **管理后台**: `http://localhost/admin/`
- **根路径**: `http://localhost/` → 自动重定向到 `/web/`

## 配置修改说明

### 1. Vue 3 History 路由支持配置

#### 问题描述
- 支持多个独立的 Vue 3 项目
- 每个项目使用自己的 `index.html` 和资源目录
- 支持 `createWebHistory('/projectName/')` 配置

#### 解决方案
在 `nginx/conf.d/default.conf` 中配置多项目支持：

```nginx
# 多项目静态资源配置 - assets目录
location ~ ^/([^/]+)/assets/(.*)$ {
    alias /usr/share/nginx/html/$1/assets/$2;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 多项目静态资源配置 - libs目录  
location ~ ^/([^/]+)/libs/(.*)$ {
    alias /usr/share/nginx/html/$1/libs/$2;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 多项目特定文件（favicon等）
location ~ ^/([^/]+)/(favicon\.ico|.*\.(js|css|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot))$ {
    alias /usr/share/nginx/html/$1/$2;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 多项目SPA history路由支持 - 每个项目使用自己的index.html
location ~ ^/([^/]+)/ {
    try_files $uri $uri/ /$1/index.html;
}

# 根路径重定向到默认项目
location = / {
    return 301 /web/;
}
```

#### 配置优势
- ✅ **完全独立**: 每个项目有独立的资源目录和入口文件
- ✅ **无限扩展**: 支持任意数量的项目，无需修改配置
- ✅ **路径清晰**: `/projectName/assets/`, `/projectName/libs/` 等路径直观
- ✅ **避免冲突**: 不同项目的同名文件不会相互影响

### 2. Content Security Policy (CSP) 修复

#### 问题描述
Vue 应用报错：`Refused to evaluate a string as JavaScript because 'unsafe-eval' is not an allowed source`

#### 解决方案
在 `nginx/nginx.conf` 中修改 CSP 头部：

```nginx
# 修改前：
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

# 修改后：
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;
```

## ⚠️ 设计问题分析与修正

### 之前存在的问题

1. **目录结构混乱**:
   - 根目录有零散文件
   - 共享 assets 目录导致冲突
   - 所有项目使用同一个 `index.html`

2. **nginx 配置不匹配**:
   - 静态资源路径映射错误
   - 缺少 libs 目录处理
   - History 路由指向错误的入口文件

3. **MIME 类型问题**:
   - 某些文件类型没有正确的 location 匹配
   - 导致返回 HTML 而不是预期的 JS/CSS

### 修正后的优势

1. **清晰的项目隔离**: 每个项目有独立的目录和资源
2. **正确的路径映射**: nginx 配置精确匹配实际目录结构  
3. **完整的文件类型支持**: assets, libs, favicon 等都有专门处理
4. **灵活的扩展性**: 新增项目只需创建目录，无需修改配置

## 重启操作步骤

### 方法一：重启 nginx 容器（推荐）
```bash
# 进入项目目录
cd /home/lin/docker/docker-compose/nginx-project-manager

# 重启 nginx 服务
docker-compose restart nginx
```

### 方法二：重新加载配置（更快）
```bash
# 测试配置文件语法
docker exec nginx-project-manager nginx -t

# 重新加载配置（无需重启容器）
docker exec nginx-project-manager nginx -s reload
```

### 方法三：完全重新构建（彻底清理）
```bash
# 停止服务
docker-compose down

# 重新启动
docker-compose up -d
```

## 验证步骤

### 1. 检查容器状态
```bash
docker-compose ps
```

### 2. 验证多项目静态资源访问
```bash
# 测试 web 项目的资源
curl -I http://localhost/web/assets/index-BMbny2fZ.css
curl -I http://localhost/web/libs/mathpix-markdown-it/bundle.js

# 测试 web2 项目的资源（如果存在）
curl -I http://localhost/web2/assets/main.js

# 期望返回: HTTP/1.1 200 OK
```

### 3. 验证路由重定向
```bash
# 测试根路径重定向
curl -I http://localhost/
# 期望返回: HTTP/1.1 301 Moved Permanently

# 测试项目路由
curl -I http://localhost/web/
curl -I http://localhost/web/some-route
# 期望返回项目的 index.html
```

### 4. 检查 CSP 头部
```bash
curl -I http://localhost/web/ | grep -i content-security
# 期望包含: 'unsafe-eval'
```

### 5. 查看错误日志
```bash
# 查看 nginx 错误日志
docker exec nginx-project-manager tail -20 /var/log/nginx/error.log

# 查看访问日志
docker exec nginx-project-manager tail -20 /var/log/nginx/access.log
```

## 🚀 部署新项目

### 添加新项目的步骤

1. **创建项目目录**:
```bash
mkdir -p nginx/html/new-project/assets
mkdir -p nginx/html/new-project/libs
```

2. **上传项目文件**:
```bash
# 复制构建后的文件到项目目录
cp -r dist/* nginx/html/new-project/
```

3. **Vue Router 配置**:
```javascript
// 在 Vue 项目中配置正确的 base 路径
const router = createRouter({
  history: createWebHistory('/new-project/'),
  routes: [...]
})
```

4. **无需修改 nginx 配置** - 通用规则自动生效！

5. **访问新项目**: `http://localhost/new-project/`

## 常见问题排查

### 问题：404 静态资源无法访问
**排查步骤：**
1. 检查文件是否存在：`docker exec nginx-project-manager ls -la /usr/share/nginx/html/项目名/assets/`
2. 检查 location 规则顺序
3. 验证 alias 路径映射

### 问题：history 路由刷新 404
**排查步骤：**
1. 确认 `try_files` 配置正确
2. 检查项目的 `index.html` 文件存在
3. 验证 location 匹配规则

### 问题：CSP 相关 JavaScript 错误
**排查步骤：**
1. 检查 CSP 头部是否包含 `'unsafe-eval'`
2. 清除浏览器缓存
3. 检查是否有其他 CSP 策略冲突

### 问题：MIME 类型错误
**排查步骤：**
1. 检查文件扩展名是否在 location 规则中
2. 验证 nginx 是否返回正确的 Content-Type
3. 确认文件确实存在且可访问

## 项目文件结构

```
nginx-project-manager/
├── docker-compose.yml          # Docker Compose 配置
├── nginx/
│   ├── nginx.conf             # 主配置文件（包含 CSP 设置）
│   ├── conf.d/
│   │   └── default.conf       # 站点配置文件（多项目支持）
│   ├── html/                  # 网站文件目录
│   │   ├── web/               # Vue 项目1
│   │   ├── web2/              # Vue 项目2（示例）
│   │   └── admin/             # 管理后台项目（示例）
│   ├── static/               # 额外静态资源
│   ├── ssl/                  # SSL 证书
│   └── logs/                 # 日志文件
└── nginx配置修改操作指南.md   # 本文档
```

## 注意事项

1. **配置文件权限**: 确保配置文件有正确的读取权限
2. **端口冲突**: 确认 80 端口没有被其他服务占用
3. **防火墙**: 检查防火墙是否允许 80 端口访问
4. **文件路径**: 注意容器内外路径映射关系
5. **缓存问题**: 浏览器可能缓存旧的资源，清除缓存后重试
6. **项目隔离**: 确保每个项目的资源完全独立，避免路径冲突
7. **Vue Router Base**: 每个项目的 Vue Router 必须配置正确的 base 路径

## 相关命令速查

```bash
# 查看容器日志
docker-compose logs nginx

# 进入容器内部
docker exec -it nginx-project-manager /bin/sh

# 查看 nginx 进程
docker exec nginx-project-manager ps aux | grep nginx

# 检查端口占用
docker exec nginx-project-manager netstat -tulpn | grep :80

# 查看项目目录结构
docker exec nginx-project-manager find /usr/share/nginx/html -maxdepth 2 -type d

# 测试特定项目的资源
docker exec nginx-project-manager ls -la /usr/share/nginx/html/web/assets/ | head -10
```

---
**创建日期**: 2025-07-01  
**最后更新**: 2025-07-01（添加多项目架构设计）  
**作者**: AI Assistant 