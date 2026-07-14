#!/usr/bin/env bash
# pve-softrouter 一键脚本 —— 在 PVE 节点的 shell 里执行。
# 用法:
#   bash <(curl -fsSL https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh) <openwrt|chr|immortalwrt> [选项=值 ...]
# 环境变量:
#   GH_MIRROR  GitHub 加速前缀(须以 / 结尾),默认直连 GitHub(留空);国内访问不畅可设为
#              https://ghfast.top/ 等前缀加速。
#              注意:镜像前缀意味着脚本与仓库经第三方代理传输,内容可能被篡改;请自行评估信任。
#   DIR        仓库检出位置,默认 /root/pve-softrouter
set -euo pipefail

GH_MIRROR="${GH_MIRROR:-}"
DIR="${DIR:-/root/pve-softrouter}"
REPO_URL="${GH_MIRROR}https://github.com/alviezhang/pve-softrouter.git"

usage() {
  cat <<'EOF'
用法: bash <(curl -fsSL https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh) <openwrt|chr|immortalwrt> [选项=值 ...]

示例:
  ... quickstart.sh) openwrt
  ... quickstart.sh) chr vm_storage=local-btrfs bridges=vmbr0,vmbr1
  ... quickstart.sh) openwrt apt_mirror_enabled=false   # 海外机器:不换 apt 源

常用选项(key=value 原样透传给 ansible,优先级最高;完整变量见 README):
  vm_storage=local-lvm       VM 磁盘所在存储(pvesm status 可查)
  proxy_url=http://IP:PORT   镜像下载走的 HTTP 代理
  apt_mirror_enabled=false   海外机器:不换 TUNA 源
  bridges=vmbr0,vmbr1        网卡桥接,逗号分隔,依次接 net0/net1/...

默认直连 GitHub;国内访问不畅可加速(须以 / 结尾):
  GH_MIRROR=https://ghfast.top/ bash <(...)
注意:镜像前缀意味着脚本与仓库经第三方代理传输,内容可能被篡改;请自行评估信任。

想完全自定义(多台/改版本/vmid):
  git clone https://github.com/alviezhang/pve-softrouter.git && cd pve-softrouter
  cp vars.example.yml vars.yml && nano vars.yml && make local
EOF
}

main() {
  PRESET="${1:-}"
  case "$PRESET" in
    openwrt|chr|immortalwrt) shift ;;
    "") : ;;                       # 无系统名:仅当已有 vars.yml 时继续(见下)
    -h|--help) usage; exit 0 ;;
    *=*) echo "请先指定系统名(openwrt | chr | immortalwrt),再跟选项。" >&2; echo >&2; usage >&2; exit 1 ;;
    *) echo "未知系统: $PRESET" >&2; echo >&2; usage >&2; exit 1 ;;
  esac

  # 其余参数:key=value → ansible --extra-vars;bridges= 转成网卡列表
  EXTRA_ARGS=()
  for kv in ${@+"$@"}; do
    case "$kv" in
      bridges=*)
        IFS=',' read -ra _brs <<<"${kv#bridges=}"
        _json='{"vm_networks_default": ['
        for i in "${!_brs[@]}"; do
          [ "$i" -gt 0 ] && _json+=', '
          _json+="\"virtio,bridge=${_brs[$i]}\""
        done
        _json+=']}'
        EXTRA_ARGS+=(-e "$_json")
        ;;
      *=*) EXTRA_ARGS+=(-e "$kv") ;;
      *) echo "无法识别的参数: $kv(应为 key=value)" >&2; echo >&2; usage >&2; exit 1 ;;
    esac
  done

  if [ -z "$PRESET" ] && [ ! -f "$DIR/vars.yml" ]; then
    echo "请指定要安装的系统。" >&2
    echo >&2
    usage >&2
    exit 1
  fi

  if [ ! -d /etc/pve ]; then
    echo "此机器不是 Proxmox VE 节点(缺少 /etc/pve)。本脚本只应在 PVE 节点上运行。" >&2
    exit 1
  fi

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
  if [ -n "$PRESET" ]; then
    if [ -f vars.yml ]; then
      echo "已存在 $DIR/vars.yml,与指定的系统 $PRESET 冲突:" >&2
      echo "  rm $DIR/vars.yml   # 然后重跑本命令用 $PRESET 预设" >&2
      echo "或不带系统名重跑,沿用现有 vars.yml。" >&2
      exit 1
    elif [ ! -f "examples/$PRESET.yml" ]; then
      echo "本地仓库缺少 examples/$PRESET.yml(旧版本 checkout?更新失败时请删除 $DIR 重试)" >&2
      exit 1
    else
      cp "examples/$PRESET.yml" vars.yml
      echo "==> 使用预设 $PRESET"
    fi
  elif [ ! -f vars.yml ]; then
    echo "请指定要安装的系统。" >&2
    echo >&2
    usage >&2
    exit 1
  fi

  exec ansible-playbook -i 'localhost,' -c local site.yml ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
}

main "$@"
