# ChatGPT 注册机 🚀

> ChatGPT 账号自动注册与管理服务

<video src="https://github.com/user-attachments/assets/a0b05d24-3f71-4c42-a159-cccb69a454e2" width="100%" autoplay muted loop></video>

## 一键部署

```bash
curl -sSL https://raw.githubusercontent.com/DouDOU-start/chatgpt-register-deploy/master/install.sh | sudo bash
```

脚本会交互式引导你完成配置：
- ✅ 安装目录（默认 `/opt/chatgpt-register`）
- ✅ 服务端口（默认 `8082`）
- ✅ API Key（自动生成，请妥善保存）

安装完成后，访问 `http://<你的服务器IP>:8082`

## 系统要求

- Linux (Ubuntu 20.04+, Debian 10+, CentOS 7+)
- 2 核 CPU / 2 GB 内存 / 10 GB 磁盘
- Docker 20.10+（脚本会自动安装）

## 邮件接收配置（必需）

注册 ChatGPT 账号需要接收验证邮件。推荐使用 Cloudflare Email Worker 自动接收并转发验证码。

### 前置要求

1. Cloudflare 账号
2. 已配置 Email Routing 的域名
3. Node.js 18+ 环境

### 部署步骤

```bash
# 1. 进入 cf-worker 目录
cd cf-worker

# 2. 安装依赖
npm install

# 3. 配置 API 地址（编辑 wrangler.jsonc）
# 将 API_URL 改为：https://your-domain.com/api/email/receive

# 4. 登录 Cloudflare
npx wrangler login

# 5. 部署
npm run deploy
```

### 配置邮件路由

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 选择域名 → **Email** → **Email Routing** → **Routing rules**
3. 创建规则：
   - **Catch-all** → **Send to Worker** → 选择 `chatgpt-register-email`

### 验证部署

发送测试邮件到你的域名邮箱，检查后端日志：

```bash
cgr logs
```

应该能看到邮件接收和验证码提取的日志。

## 常用命令

安装完成后，可以使用 `cgr` 命令管理服务：

```bash
# 查看服务状态
cgr status

# 查看实时日志
cgr logs

# 重启服务
cgr restart

# 更新到最新版本
cgr update

# 查看 API Key
cgr api-key

# 查看所有命令
cgr help
```

## 配置修改

安装后如需修改配置，编辑 `/opt/chatgpt-register/.env`：

```bash
sudo nano /opt/chatgpt-register/.env
```

查看 API Key：

```bash
cgr api-key
```

修改后重启服务：

```bash
cgr restart
```

## 无法访问？

### 检查防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 8082/tcp

# CentOS/RHEL
sudo firewall-cmd --add-port=8082/tcp --permanent
sudo firewall-cmd --reload
```

### 查看错误日志

```bash
cgr logs
```

## 问题反馈

遇到问题？访问 [GitHub Issues](https://github.com/DouDOU-start/chatgpt-register-deploy/issues)

---

**🎉 祝你使用愉快！**
