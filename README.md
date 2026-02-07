# ChatGPT 注册机 🚀

> ChatGPT 账号自动注册与管理服务

## 一键部署

```bash
curl -sSL https://raw.githubusercontent.com/DouDOU-start/chatgpt-register-deploy/main/install.sh | sudo bash
```

脚本会交互式引导你完成配置：
- ✅ 安装目录（默认 `/opt/chatgpt-register`）
- ✅ 服务端口（默认 `8082`）
- ✅ API Key（自动生成，请妥善保存）
- ✅ 验证码平台（可选）

安装完成后，访问 `http://<你的服务器IP>:8082`

## 系统要求

- Linux (Ubuntu 20.04+, Debian 10+, CentOS 7+)
- 2 核 CPU / 2 GB 内存 / 10 GB 磁盘
- Docker 20.10+（脚本会自动安装）

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
