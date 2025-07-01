# Git 使用说明

本文档说明如何在这个 nginx docker-compose 项目中使用 Git 进行版本控制。

## 初始化设置

项目已经初始化了 Git 仓库，并配置了合适的 `.gitignore` 文件。

## .gitignore 配置说明

### 被忽略的文件类型：

1. **环境变量文件**
   - `.env` - 包含敏感信息的环境变量
   - `.env.local`, `.env.production` - 不同环境的配置

2. **日志文件**
   - `nginx/logs/*` - 运行时生成的日志文件
   - 保留 `.gitkeep` 文件维持目录结构

3. **SSL证书**
   - `nginx/ssl/*` - 敏感的SSL证书文件
   - 保留 `.gitkeep` 文件维持目录结构

4. **用户自定义内容**
   - `nginx/html/*` - 网站文件（保留默认的index.html和50x.html）
   - `nginx/static/*` - 静态资源文件
   - 保留 `.gitkeep` 文件维持目录结构

5. **系统文件**
   - `.DS_Store`, `Thumbs.db` - 系统生成的文件
   - `*.swp`, `*.swo` - 编辑器临时文件

6. **其他**
   - 临时文件、备份文件、压缩文件等

## 常用 Git 命令

### 查看状态
```bash
# 查看当前状态
git status

# 查看修改的文件
git diff

# 查看提交历史
git log --oneline
```

### 提交更改
```bash
# 添加所有更改
git add .

# 添加特定文件
git add nginx/conf.d/default.conf

# 提交更改
git commit -m "描述你的更改"

# 查看提交历史
git log
```

### 分支管理
```bash
# 创建新分支
git checkout -b feature/new-config

# 切换分支
git checkout main

# 合并分支
git merge feature/new-config

# 删除分支
git branch -d feature/new-config
```

### 远程仓库
```bash
# 添加远程仓库
git remote add origin <repository-url>

# 推送到远程
git push origin main

# 从远程拉取
git pull origin main
```

## 推荐的提交规范

### 提交信息格式
```
类型: 简短描述

详细描述（可选）

- 功能点1
- 功能点2
```

### 提交类型
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

### 示例
```bash
# 添加新站点配置
git commit -m "feat: 添加新的站点配置

- 新增 example.com 站点配置
- 配置 SSL 证书路径
- 添加反向代理设置"

# 修复配置错误
git commit -m "fix: 修复 nginx 配置语法错误

- 修正 location 块语法
- 更新 server_name 配置"

# 更新文档
git commit -m "docs: 更新 README 使用说明

- 添加故障排除章节
- 更新环境变量说明"
```

## 工作流程建议

### 1. 开发新功能
```bash
# 创建功能分支
git checkout -b feature/new-site

# 进行开发
# ... 修改文件 ...

# 提交更改
git add .
git commit -m "feat: 添加新站点配置"

# 合并到主分支
git checkout main
git merge feature/new-site
```

### 2. 修复问题
```bash
# 创建修复分支
git checkout -b fix/ssl-config

# 修复问题
# ... 修改文件 ...

# 提交修复
git add .
git commit -m "fix: 修复 SSL 配置问题"

# 合并到主分支
git checkout main
git merge fix/ssl-config
```

### 3. 版本发布
```bash
# 创建标签
git tag -a v1.0.0 -m "发布版本 1.0.0"

# 推送标签
git push origin v1.0.0
```

## 注意事项

1. **敏感信息**：确保 `.env` 文件不会被提交到版本控制
2. **大文件**：避免提交大型日志文件或二进制文件
3. **配置分离**：将环境特定的配置放在 `.env` 文件中
4. **定期提交**：经常提交小的、有意义的更改
5. **备份**：定期推送到远程仓库作为备份

## 有用的别名

可以在 `~/.gitconfig` 中添加以下别名：

```ini
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate
    unstage = reset HEAD --
    last = log -1 HEAD
```

这样可以使用更短的命令：
```bash
git st    # git status
git co    # git checkout
git lg    # git log --oneline --graph --decorate
``` 