#!/usr/bin/env bash
# pve-softrouter 一键脚本 —— 在 PVE 节点的 shell 里执行:
#   bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh)
# 环境变量:
#   GH_MIRROR  GitHub 加速前缀,默认 https://ghfast.top/;海外机器可置空:GH_MIRROR= bash <(...)
#   DIR        仓库检出位置,默认 /root/pve-softrouter
set -euo pipefail

GH_MIRROR="${GH_MIRROR-https://ghfast.top/}"
DIR="${DIR:-/root/pve-softrouter}"
REPO_URL="${GH_MIRROR}https://github.com/alviezhang/pve-softrouter.git"

if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 运行(PVE 节点 shell 默认就是 root)" >&2
  exit 1
fi

if ! command -v ansible-playbook >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  echo "==> 安装 ansible-core 与 git"
  # 全新 PVE 的 enterprise 源会 401,apt-get update 报错不影响 debian 主源可用
  apt-get update || true
  apt-get install -y ansible-core git
fi

if [ -d "$DIR/.git" ]; then
  echo "==> 更新已有仓库 $DIR"
  git -C "$DIR" pull --ff-only || echo "(pull 失败,继续用本地版本)"
else
  echo "==> 克隆仓库到 $DIR"
  git clone --depth 1 "$REPO_URL" "$DIR"
fi

cd "$DIR"
if [ ! -f vars.yml ]; then
  cp vars.example.yml vars.yml
  echo
  echo "已生成 $DIR/vars.yml —— 请编辑它(例如: nano $DIR/vars.yml),"
  echo "改好后重新运行同一条命令,即开始创建 VM。"
  exit 0
fi

exec ansible-playbook -i 'localhost,' -c local site.yml
