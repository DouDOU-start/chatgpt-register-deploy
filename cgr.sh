#!/usr/bin/env bash
# ChatGPT 注册机 - 服务管理脚本

set -e

# 颜色输出
info() { echo -e "\033[1;32m[信息]\033[0m $*"; }
warn() { echo -e "\033[1;33m[警告]\033[0m $*" >&2; }
err() { echo -e "\033[1;31m[错误]\033[0m $*" >&2; }

# 默认安装目录
INSTALL_DIR="${INSTALL_DIR:-/opt/chatgpt-register}"

# 检查安装目录是否存在
if [[ ! -d "$INSTALL_DIR" ]]; then
  err "未找到安装目录: $INSTALL_DIR"
  err "请先安装 ChatGPT 注册机"
  exit 1
fi

cd "$INSTALL_DIR"

# 检测 docker compose 命令
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  err "未找到 docker compose 命令"
  exit 1
fi

# 显示使用帮助
usage() {
  cat <<EOF
ChatGPT 注册机 - 服务管理工具

用法: cgr <命令>

命令:
  start       启动服务
  stop        停止服务
  restart     重启服务
  status      查看服务状态
  logs        查看实时日志
  update      更新到最新版本
  api-key     查看 API Key
  help        显示帮助信息

示例:
  cgr start
  cgr logs
  cgr update
EOF
}

# 启动服务
start_service() {
  info "正在启动服务..."
  $COMPOSE_CMD up -d
  info "✅ 服务已启动"
}

# 停止服务
stop_service() {
  info "正在停止服务..."
  $COMPOSE_CMD down
  info "✅ 服务已停止"
}

# 重启服务
restart_service() {
  info "正在重启服务..."
  $COMPOSE_CMD restart
  info "✅ 服务已重启"
}

# 查看状态
show_status() {
  info "服务状态:"
  $COMPOSE_CMD ps
}

# 查看日志
show_logs() {
  info "实时日志 (按 Ctrl+C 退出):"
  $COMPOSE_CMD logs -f
}

# 更新服务
update_service() {
  info "正在更新服务..."

  # 读取镜像地址
  DOCKER_IMAGE=$(grep "^DOCKER_IMAGE=" .env | cut -d'=' -f2)
  DOCKER_IMAGE=${DOCKER_IMAGE:-ghcr.io/doudou-start/chatgpt-register:latest}

  info "拉取最新镜像: $DOCKER_IMAGE"
  docker pull "$DOCKER_IMAGE"

  info "重启服务..."
  $COMPOSE_CMD up -d

  info "✅ 更新完成！"
}

# 查看 API Key
show_api_key() {
  if [[ -f .env ]]; then
    API_KEY=$(grep "^API_KEY=" .env | cut -d'=' -f2)
    if [[ -n "$API_KEY" ]]; then
      info "API Key: $API_KEY"
    else
      warn "未设置 API Key"
    fi
  else
    err "未找到配置文件 .env"
    exit 1
  fi
}

# 主逻辑
case "${1:-}" in
  start)
    start_service
    ;;
  stop)
    stop_service
    ;;
  restart)
    restart_service
    ;;
  status)
    show_status
    ;;
  logs)
    show_logs
    ;;
  update)
    update_service
    ;;
  api-key)
    show_api_key
    ;;
  help|--help|-h)
    usage
    ;;
  "")
    usage
    exit 1
    ;;
  *)
    err "未知命令: $1"
    echo ""
    usage
    exit 1
    ;;
esac
