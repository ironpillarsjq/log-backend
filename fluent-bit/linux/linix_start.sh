#!/usr/bin/env bash
set -euo pipefail

echo "===================================================="
echo "          正在准备启动 Fluent Bit（Linux）..."
echo "===================================================="

# 1. Fluent Bit 执行引擎路径；默认使用系统 PATH 中的 fluent-bit。
if [[ -n "${FB_BIN:-}" ]]; then
  FLUENT_BIT_BIN="${FB_BIN}"
elif command -v fluent-bit >/dev/null 2>&1; then
  FLUENT_BIT_BIN="$(command -v fluent-bit)"
elif [[ -x "/opt/fluent-bit/bin/fluent-bit" ]]; then
  FLUENT_BIT_BIN="/opt/fluent-bit/bin/fluent-bit"
else
  echo "[错误] 未找到 fluent-bit。请先安装 Fluent Bit，或设置 FB_BIN=/path/to/fluent-bit。"
  exit 1
fi

# 2. 锁定当前脚本所在的 Linux 配置目录。
CURRENT_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${CURRENT_PROJECT_DIR}/env.conf"
CONFIG_FILE="${CURRENT_PROJECT_DIR}/fluent-bit_linux.conf"
LOG_TRANSFER_FILE="${CURRENT_PROJECT_DIR}/log_transfer.conf"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[错误] 找不到 Linux 环境配置文件：${ENV_FILE}"
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "[错误] 找不到 Fluent Bit 主配置文件：${CONFIG_FILE}"
  exit 1
fi

if [[ ! -f "${LOG_TRANSFER_FILE}" ]]; then
  echo "[错误] 找不到 Linux 日志采集配置文件：${LOG_TRANSFER_FILE}"
  exit 1
fi

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "[错误] 当前操作需要管理员权限，但系统中没有 sudo：$*"
    exit 1
  fi
}

read_env_value() {
  local name="$1"
  grep -E "^[[:space:]]*@SET[[:space:]]+${name}=" "${ENV_FILE}" \
    | tail -n 1 \
    | sed -E "s/^[[:space:]]*@SET[[:space:]]+${name}=//" \
    | tr -d '\r'
}

FLB_BUFFER_PATH="$(read_env_value "FLB_BUFFER_PATH" || true)"
FLB_AUDIT_DB_PATH="$(read_env_value "FLB_AUDIT_DB_PATH" || true)"
FLB_AUTH_DB_PATH="$(read_env_value "FLB_AUTH_DB_PATH" || true)"

echo "[信息] 正在检查 Linux 配置文件..."
echo "[信息] 主配置文件：${CONFIG_FILE}"
echo "[信息] 环境配置文件：${ENV_FILE}"
echo "[信息] 日志采集配置：${LOG_TRANSFER_FILE}"

echo "[信息] 正在准备 Fluent Bit 本地目录..."
if [[ -n "${FLB_BUFFER_PATH}" ]]; then
  run_as_root mkdir -p "${FLB_BUFFER_PATH}"
fi

if [[ -n "${FLB_AUDIT_DB_PATH}" ]]; then
  run_as_root mkdir -p "$(dirname -- "${FLB_AUDIT_DB_PATH}")"
fi

if [[ -n "${FLB_AUTH_DB_PATH}" ]]; then
  run_as_root mkdir -p "$(dirname -- "${FLB_AUTH_DB_PATH}")"
fi

run_as_root mkdir -p /var/lib/fluent-bit

echo "[信息] 正在停止旧的 Fluent Bit 进程..."
run_as_root pkill -x fluent-bit >/dev/null 2>&1 || true

if [[ "${1:-}" == "--clean-buffer" ]]; then
  if [[ -z "${FLB_BUFFER_PATH}" ]]; then
    echo "[警告] FLB_BUFFER_PATH 为空，跳过缓冲区清理。"
  else
    echo "[信息] 正在清理本地缓冲区：${FLB_BUFFER_PATH}"
    run_as_root rm -rf "${FLB_BUFFER_PATH}"
    run_as_root mkdir -p "${FLB_BUFFER_PATH}"
  fi
fi

echo "[成功] 准备工作就绪，正在调起 Fluent Bit 引擎..."
echo "----------------------------------------------------"

if [[ "${EUID}" -eq 0 ]]; then
  exec "${FLUENT_BIT_BIN}" -c "${CONFIG_FILE}"
else
  exec sudo "${FLUENT_BIT_BIN}" -c "${CONFIG_FILE}"
fi
