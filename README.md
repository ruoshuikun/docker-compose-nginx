# Nginx 多项目管理解决方案

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=flat&logo=nginx&logoColor=white)](https://nginx.org/)
[![CentOS](https://img.shields.io/badge/CentOS-262577?style=flat&logo=centos&logoColor=white)](https://www.centos.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

> 基于 Docker Compose 的 Nginx 多项目管理解决方案，支持多前端项目部署、共享静态资源管理和远程自动化部署。

## 🚀 项目特色

- **🏗️ 多项目支持** - 在同一服务器上部署多个前端项目，项目间完全隔离
- **📦 共享资源管理** - 统一管理地图瓦片、通用图片、字体等静态资源
- **🌐 远程一键部署** - 自动化部署到 CentOS/Ubuntu 服务器
- **🔧 可视化管理** - 提供命令行工具进行项目生命周期管理
- **🔒 安全优化** - 内置安全头配置和性能优化
- **📊 健康监控** - 内置健康检查和日志管理
- **🔄 版本控制** - 自动备份和版本回滚支持

## 📁 项目结构

```
nginx-project-manager/
├── nginx-manager.sh           # 🎛️ 主管理脚本
├── docker-compose.yml         # 🐳 Docker Compose 配置
├── docker-compose.override.yml# 🛠️ 开发环境配置
├── env.example               # ⚙️ 环境变量模板
├── .gitignore               # 📝 Git 忽略配置
├── scripts/
│   └── remote-deploy.sh     # 🌐 远程部署脚本
├── nginx/
│   ├── nginx.conf           # 📋 Nginx 主配置
│   ├── conf.d/              # 📂 站点配置目录
│   │   ├── default.conf     # 🏠 默认站点配置
│   │   └── ssl.conf         # 🔐 SSL 配置模板
│   ├── html/                # 🌍 多项目网站目录
│   │   ├── shared/          # 📦 共享静态资源
│   │   │   ├── maps/        # 🗺️ 地图数据
│   │   │   ├── tiles/       # 🧩 地图瓦片
│   │   │   ├── images/      # 🖼️ 通用图片
│   │   │   ├── fonts/       # 🔤 字体文件
│   │   │   └── libs/        # 📚 共享JS库
│   │   ├── web/             # 💻 Web项目
│   │   ├── admin/           # 👨‍💼 管理后台
│   │   └── mobile/          # 📱 移动端项目
│   ├── ssl/                 # 🔐 SSL证书目录
│   └── logs/                # 📊 日志文件目录
├── backup/                  # 💾 项目备份目录
├── temp-deploy/             # 🚀 临时部署目录（自动创建和清理）
└── docs/                    # 📚 文档目录
    ├── 部署方式总览.md       # 📖 部署指南总览
    ├── nginx配置修改操作指南.md # 🔧 配置修改指南
    ├── 快速开始指南.md       # ⚡ 快速入门文档
    ├── 项目架构优化方案.md   # 🏗️ 架构优化方案
    ├── DEPLOYMENT.md        # 🚀 详细部署文档
    ├── GIT_USAGE.md         # 📝 Git使用说明
    └── blog-gitkeep.md      # 📄 .gitkeep技术博客
```

## ⚡ 快速开始

### 1. 克隆项目

```bash
git clone <repository-url> nginx-project-manager
cd nginx-project-manager
```

### 2. 配置环境

```bash
# 复制环境变量文件
cp env.example .env

# 编辑配置（可选）
vim .env
```

### 3. 启动服务

```bash
# 启动基础服务
./nginx-manager.sh start
```

### 4. 部署第一个项目

```bash
# 部署前端项目
./nginx-manager.sh deploy web /path/to/your/dist

# 访问项目
curl http://localhost/web/
```

## 🎛️ 管理命令

### 基础服务管理

```bash
./nginx-manager.sh start      # 启动服务
./nginx-manager.sh stop       # 停止服务
./nginx-manager.sh restart    # 重启服务
./nginx-manager.sh status     # 查看状态
./nginx-manager.sh logs       # 查看日志
./nginx-manager.sh health     # 健康检查
```

### 项目管理

```bash
./nginx-manager.sh deploy <项目名> <源目录>  # 部署项目
./nginx-manager.sh list                     # 列出所有项目
./nginx-manager.sh remove <项目名>          # 删除项目
./nginx-manager.sh backup <项目名>          # 备份项目
```

### 共享资源管理

```bash
./nginx-manager.sh shared create                    # 初始化共享资源
./nginx-manager.sh shared upload <源目录> <类型>    # 上传资源
./nginx-manager.sh shared list                      # 列出资源
./nginx-manager.sh shared info                      # 资源信息
```

### 配置管理

```bash
./nginx-manager.sh reload     # 重新加载配置
./nginx-manager.sh test       # 测试配置
./nginx-manager.sh edit       # 编辑配置
./nginx-manager.sh clean      # 清理系统
./nginx-manager.sh clean-temp # 清理临时部署目录
```

## 🌐 远程部署

### 部署到服务器

```bash
# 仅部署框架
./scripts/remote-deploy.sh <服务器IP> <用户名>

# 部署框架+项目
./scripts/remote-deploy.sh <服务器IP> <用户名> <项目名> <源目录>
```

### 示例

```bash
# 部署到 CentOS 服务器
./scripts/remote-deploy.sh 192.168.1.100 root

# 部署 web 项目到 Ubuntu 服务器
./scripts/remote-deploy.sh example.com ubuntu web /path/to/dist
```

## 📋 使用场景

### 1. 单项目部署

```bash
# 部署个人博客
./nginx-manager.sh deploy blog /path/to/blog-dist
# 访问: http://localhost/blog/
```

### 2. 多项目部署

```bash
# 部署主应用
./nginx-manager.sh deploy web /path/to/web-dist

# 部署管理后台
./nginx-manager.sh deploy admin /path/to/admin-dist

# 部署移动端
./nginx-manager.sh deploy mobile /path/to/mobile-dist

# 访问地址:
# http://localhost/web/     - 主应用
# http://localhost/admin/   - 管理后台  
# http://localhost/mobile/  - 移动端
```

### 3. 地图应用部署

```bash
# 上传地图瓦片
./nginx-manager.sh shared upload /path/to/tiles tiles

# 上传地图数据
./nginx-manager.sh shared upload /path/to/maps maps

# 部署地图应用
./nginx-manager.sh deploy map-app /path/to/map-dist

# 在应用中使用:
# http://localhost/shared/tiles/{z}/{x}/{y}.png
# http://localhost/shared/maps/world.geojson
```

### 4. 企业级部署

```bash
# 远程部署到生产服务器
./scripts/remote-deploy.sh prod-server.com root

# 部署各个子系统
ssh root@prod-server.com 'cd /opt/nginx-project-manager && ./nginx-manager.sh deploy portal /tmp/portal-dist'
ssh root@prod-server.com 'cd /opt/nginx-project-manager && ./nginx-manager.sh deploy crm /tmp/crm-dist'
ssh root@prod-server.com 'cd /opt/nginx-project-manager && ./nginx-manager.sh deploy oa /tmp/oa-dist'
```

## 📁 目录说明

### temp-deploy 临时部署目录

`temp-deploy/` 目录用于临时存放部署文件，支持多项目并行部署：

```bash
# 目录结构示例
temp-deploy/
├── web/          # Web项目临时文件
├── admin/        # 管理后台临时文件
├── mobile/       # 移动端临时文件
└── portal/       # 门户项目临时文件
```

#### 使用方式

```bash
# 方式一：直接指定临时目录
./nginx-manager.sh deploy web temp-deploy/web

# 方式二：使用默认临时目录（推荐）
./nginx-manager.sh deploy web /path/to/dist
# 脚本会自动将文件复制到 temp-deploy/web/ 然后部署

# 方式三：多项目并行部署
./nginx-manager.sh deploy web temp-deploy/web
./nginx-manager.sh deploy admin temp-deploy/admin
./nginx-manager.sh deploy mobile temp-deploy/mobile
```

#### 自动管理特性

- ✅ **自动创建** - 部署时自动创建必要的目录结构
- ✅ **自动清理** - 部署完成后询问是否清理临时文件
- ✅ **手动清理** - 支持 `clean-temp` 命令手动清理
- ✅ **并行支持** - 支持多个项目同时使用不同子目录
- ✅ **版本隔离** - 每个项目使用独立的临时空间
- ✅ **错误恢复** - 部署失败时保留临时文件便于排查

## 🔧 配置说明

### 环境变量配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NGINX_CONTAINER_NAME` | `nginx-project-manager` | 容器名称 |
| `NGINX_PORT` | `80` | HTTP 端口 |
| `NGINX_SSL_PORT` | `443` | HTTPS 端口 |
| `NGINX_HOST` | `localhost` | 服务器名称 |
| `SITE_NAME` | `nginx-project-manager` | 网站名称 |
| `SITE_DOMAIN` | `example.com` | 域名 |

### Nginx 配置特性

- ✅ **Gzip 压缩** - 自动压缩静态资源
- ✅ **缓存控制** - 智能缓存策略
- ✅ **安全头** - XSS、CSRF、点击劫持防护
- ✅ **健康检查** - `/health` 端点监控
- ✅ **错误页面** - 自定义错误页面
- ✅ **SSL 支持** - HTTPS 配置模板

## 🌍 访问路径

| 资源类型 | 访问路径 | 示例 |
|---------|---------|------|
| 默认页面 | `http://domain/` | `http://localhost/` |
| 项目访问 | `http://domain/<项目名>/` | `http://localhost/web/` |
| 共享资源 | `http://domain/shared/<类型>/` | `http://localhost/shared/tiles/` |
| 健康检查 | `http://domain/health` | `http://localhost/health` |

## 📊 监控和维护

### 健康检查

```bash
# 执行健康检查
./nginx-manager.sh health

# 查看服务状态
./nginx-manager.sh status

# 查看最近日志
./nginx-manager.sh logs 50
```

### 性能监控

```bash
# 查看容器资源使用
docker stats nginx-project-manager

# 查看磁盘使用
df -h

# 查看网络连接
netstat -tlnp | grep :80
```

### 日志管理

```bash
# 查看访问日志
docker exec nginx-project-manager tail -f /var/log/nginx/access.log

# 查看错误日志
docker exec nginx-project-manager tail -f /var/log/nginx/error.log

# 日志清理
./nginx-manager.sh clean
```

## 🔒 安全建议

1. **定期更新** - 定期更新 Docker 镜像和系统包
2. **防火墙配置** - 只开放必要的端口（80, 443）
3. **SSL 证书** - 生产环境使用有效的 SSL 证书
4. **访问控制** - 配置适当的访问控制规则
5. **日志监控** - 定期检查和分析日志文件
6. **备份策略** - 定期备份重要数据和配置

## 🚀 性能优化

1. **启用 Gzip** - 已默认启用，可压缩 60-80% 的文件大小
2. **静态资源缓存** - 设置合理的缓存过期时间
3. **CDN 集成** - 配置 CDN 加速静态资源访问
4. **负载均衡** - 多实例部署时配置负载均衡
5. **HTTP/2** - 启用 HTTP/2 协议提升性能

## 📚 文档索引

- [部署方式总览](docs/部署方式总览.md) - 详细的部署方式说明
- [快速开始指南](docs/快速开始指南.md) - 项目快速入门文档
- [配置修改指南](docs/nginx配置修改操作指南.md) - Nginx配置修改操作说明
- [架构优化方案](docs/项目架构优化方案.md) - 项目架构优化建议
- [详细部署指南](docs/DEPLOYMENT.md) - CentOS/Ubuntu 服务器部署
- [Git 使用指南](docs/GIT_USAGE.md) - 版本控制最佳实践
- [.gitkeep 技术博客](docs/blog-gitkeep.md) - Git 空目录管理技术

## 🔧 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 修改端口配置
   echo "NGINX_PORT=8080" >> .env
   ./nginx-manager.sh restart
   ```

2. **容器启动失败**
   ```bash
   # 查看详细错误
   ./nginx-manager.sh logs
   
   # 清理并重启
   ./nginx-manager.sh clean
   ./nginx-manager.sh start
   ```

3. **项目访问 404**
   ```bash
   # 检查项目列表
   ./nginx-manager.sh list
   
   # 测试配置
   ./nginx-manager.sh test
   ```

4. **远程部署失败**
   ```bash
   # 检查 SSH 连接
   ssh user@server 'echo "连接正常"'
   
   # 检查服务器环境
   ssh user@server 'docker --version && docker-compose --version'
   ```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目基于 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Nginx](https://nginx.org/) - 高性能的 Web 服务器
- [Docker](https://www.docker.com/) - 容器化平台
- [Docker Compose](https://docs.docker.com/compose/) - 容器编排工具

---

**⭐ 如果这个项目对您有帮助，请给个星标支持！**

*最后更新：2024-12-19* 