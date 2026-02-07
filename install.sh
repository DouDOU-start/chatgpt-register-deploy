#!/usr/bin/env bash
set -euo pipefail

# 颜色输出
info() { echo -e "\033[1;32m[信息]\033[0m $*"; }
warn() { echo -e "\033[1;33m[警告]\033[0m $*" >&2; }
err() { echo -e "\033[1;31m[错误]\033[0m $*" >&2; }
ask() { echo -e "\033[1;36m[询问]\033[0m $*"; }

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    err "请使用 sudo 执行该脚本"
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_docker() {
  info "开始安装 Docker..."
  if ! curl -fsSL https://get.docker.com | sh; then
    err "Docker 安装失败"
    exit 1
  fi

  info "启动 Docker 服务..."
  systemctl enable docker
  systemctl start docker
}

check_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif need_cmd docker-compose; then
    echo "docker-compose"
  else
    err "未检测到 docker compose 命令"
    err "请升级 Docker 或安装 docker-compose 插件"
    exit 1
  fi
}

generate_api_key() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
  fi
}

# 显示欢迎信息
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ChatGPT 注册机 - 一键部署"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

require_root

# 检查 curl
if ! need_cmd curl; then
  err "未检测到 curl，请先安装"
  exit 1
fi

# 检查并安装 Docker
if ! need_cmd docker; then
  warn "未检测到 Docker"
  ask "是否自动安装 Docker? (y/n) [y]: "
  read -r INSTALL_DOCKER
  INSTALL_DOCKER=${INSTALL_DOCKER:-y}

  if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
    install_docker
  else
    err "请先安装 Docker: curl -fsSL https://get.docker.com | sh"
    exit 1
  fi
fi

# 检查 Docker 服务
if ! docker info >/dev/null 2>&1; then
  err "Docker 服务未运行"
  info "正在启动 Docker 服务..."
  systemctl start docker
  sleep 2

  if ! docker info >/dev/null 2>&1; then
    err "Docker 服务启动失败，请手动启动: sudo systemctl start docker"
    exit 1
  fi
fi

# 检查 docker compose
COMPOSE_CMD=$(check_docker_compose)

echo ""
info "开始配置安装参数..."
echo ""

# 1. 安装目录
ask "请输入安装目录 [/opt/chatgpt-register]: "
read -r INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-/opt/chatgpt-register}

# 2. 服务端口
ask "请输入服务端口 [8082]: "
read -r PORT
PORT=${PORT:-8082}

# 验证端口范围
if [[ ! "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1 ]] || [[ "$PORT" -gt 65535 ]]; then
  err "无效的端口号，使用默认端口 8082"
  PORT=8082
fi

# 3. API Key（自动生成）
echo ""
info "正在生成随机 API Key..."
API_KEY=$(generate_api_key)
info "已生成 API Key: $API_KEY"
warn "请妥善保存此密钥，用于 Web 界面和 API 访问认证"

# 4. 验证码平台
echo ""
ask "是否配置验证码平台? (y/n) [n]: "
read -r SET_PHONE_API
SET_PHONE_API=${SET_PHONE_API:-n}

SMS_ACTIVATE_KEY=""
FIVESIM_KEY=""
if [[ "$SET_PHONE_API" =~ ^[Yy]$ ]]; then
  ask "请输入 SMS-Activate API Key (留空跳过): "
  read -r SMS_ACTIVATE_KEY

  ask "请输入 5SIM API Key (留空跳过): "
  read -r FIVESIM_KEY
fi

# 确认配置
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "配置确认"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "安装目录: $INSTALL_DIR"
info "服务端口: $PORT"
info "API Key: $API_KEY"
info "SMS-Activate: $([ -n "$SMS_ACTIVATE_KEY" ] && echo '已设置' || echo '未设置')"
info "5SIM: $([ -n "$FIVESIM_KEY" ] && echo '已设置' || echo '未设置')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
ask "确认开始安装? (y/n) [y]: "
read -r CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  warn "已取消安装"
  exit 0
fi

echo ""
info "开始安装..."
echo ""

# 创建安装目录
info "📁 准备安装目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# GitHub Raw 文件基础 URL
REPO_BASE_URL="https://raw.githubusercontent.com/DouDOU-start/chatgpt-register-deploy/main"

# 下载配置文件
info "📥 下载配置文件..."
curl -fsSL "${REPO_BASE_URL}/docker-compose.yml" -o docker-compose.yml
curl -fsSL "${REPO_BASE_URL}/config.yaml.example" -o config.yaml.example
curl -fsSL "${REPO_BASE_URL}/.env.example" -o .env.example

# 初始化配置文件
if [[ ! -f config.yaml ]]; then
  info "📝 初始化 config.yaml"
  cp config.yaml.example config.yaml
else
  info "✓ 保留已有的 config.yaml"
fi

if [[ ! -f .env ]]; then
  info "📝 初始化 .env"
  cp .env.example .env
else
  info "✓ 保留已有的 .env"
fi

# 更新环境变量
info "⚙️  配置环境变量..."
sed -i.bak "s|^PORT=.*|PORT=${PORT}|" .env

if [[ -n "$API_KEY" ]]; then
  sed -i.bak "s|^API_KEY=.*|API_KEY=${API_KEY}|" .env
fi

if [[ -n "$SMS_ACTIVATE_KEY" ]]; then
  sed -i.bak "s|^PHONE_API_KEY_SMS_ACTIVATE=.*|PHONE_API_KEY_SMS_ACTIVATE=${SMS_ACTIVATE_KEY}|" .env
fi

if [[ -n "$FIVESIM_KEY" ]]; then
  sed -i.bak "s|^PHONE_API_KEY_5SIM=.*|PHONE_API_KEY_5SIM=${FIVESIM_KEY}|" .env
fi

# 删除备份文件
rm -f .env.bak

# 创建数据和日志目录
info "📂 创建数据和日志目录..."
mkdir -p data logs

# 拉取镜像
DOCKER_IMAGE="ghcr.io/doudou-start/chatgpt-register:latest"
info "🐳 拉取 Docker 镜像: $DOCKER_IMAGE"
docker pull "$DOCKER_IMAGE"

# 停止旧容器（如果存在）
if docker ps -a --format '{{.Names}}' | grep -q '^chatgpt-register$'; then
  info "🛑 停止旧容器..."
  $COMPOSE_CMD down
fi

# 启动服务
info "🚀 启动服务..."
$COMPOSE_CMD up -d

# 等待服务启动
info "⏳ 等待服务启动..."
sleep 3

# 安装管理命令
info "📦 安装管理命令..."
curl -fsSL "${REPO_BASE_URL}/cgr.sh" -o /usr/local/bin/cgr
chmod +x /usr/local/bin/cgr
info "✓ 已安装管理命令: cgr"

# 检查服务状态
if docker ps --format '{{.Names}}' | grep -q '^chatgpt-register$'; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info "✅ 安装完成！"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  info "📁 安装目录: $INSTALL_DIR"
  info "🌐 访问地址: http://<服务器IP>:${PORT}"
  echo ""
  warn "🔑 API Key（请妥善保存）"
  info "   $API_KEY"
  info ""
  info "   Web 界面登录和 API 请求都需要此密钥"
  info "   如忘记密钥，可查看: cgr api-key"
  info "   API 请求示例: curl -H \"X-API-Key: $API_KEY\" http://localhost:${PORT}/api/accounts"
  echo ""
  info "常用命令:"
  info "  cgr status   # 查看服务状态"
  info "  cgr logs     # 查看实时日志"
  info "  cgr restart  # 重启服务"
  info "  cgr update   # 更新到最新版本"
  info "  cgr help     # 查看所有命令"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  err "❌ 服务启动失败"
  err "请查看日志: cd $INSTALL_DIR && $COMPOSE_CMD logs"
  exit 1
fi
