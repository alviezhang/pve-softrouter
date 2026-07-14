# pve-softrouter

在 Proxmox VE 上一键创建软路由虚拟机(OpenWrt / ImmortalWrt / RouterOS CHR)。

从官方镜像下载、校验、建 VM、导盘、扩容一条龙;为国内环境做了适配(TUNA 换源、
可选 HTTP 代理下载、GitHub 加速)。幂等:已存在的 VM 自动跳过,可反复执行。

## 快速开始(在 PVE 节点上)

SSH 进你的 PVE 节点(或网页控制台开 Shell),执行——系统名必选(`openwrt` / `chr` / `immortalwrt`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh) openwrt
```

国内访问 GitHub 不畅时,可经第三方镜像加速(注意:脚本与仓库会经该代理传输,存在被篡改的理论风险,请自行评估;也可以先下载脚本审阅后再执行):

```bash
GH_MIRROR=https://ghfast.top/ bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh) openwrt
```

需要调整的选项直接跟在后面(`key=value`,透传给 ansible,优先级最高),全程不需要编辑文件:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh) chr vm_storage=local-btrfs bridges=vmbr0,vmbr1
```

海外机器:`apt_mirror_enabled=false`(不换源;GitHub 默认已直连):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alviezhang/pve-softrouter/main/quickstart.sh) openwrt apt_mirror_enabled=false
```

完成后在 PVE 网页里启动 VM、打开控制台做系统初始化即可。要完全自定义(多台、换版本、改 vmid)用 clone 模式:`git clone` 本仓库,`cp vars.example.yml vars.yml` 编辑后 `make local`(在 PVE 本机)或 `make provision`(远程)。

## 从裸机开始(还没装 PVE?)

1. 下载 PVE ISO(国内推荐 TUNA 镜像):<https://mirrors.tuna.tsinghua.edu.cn/proxmox/iso/>
2. 用 [balenaEtcher](https://etcher.balena.io/) 或 [Ventoy](https://www.ventoy.net/cn/) 写入 U 盘
3. 软路由小主机插 U 盘开机(开机按 F7/F11/DEL 选 U 盘启动),安装向导里选好
   目标磁盘、密码和管理 IP,十分钟装完
4. 回到上面的「快速开始」

> 无人值守安装 ISO(插上 U 盘自动装完 PVE)在路线图上(v2)。

## 配置说明(vars.yml)

| 变量 | 默认 | 说明 |
|---|---|---|
| `proxmox_vms` | — | 要创建的 VM 列表,见下表 |
| `vm_storage` | `local-lvm` | VM 磁盘存储(`pvesm status` 可查) |
| `proxy_url` | 不设 | 镜像下载走的 HTTP 代理,如 `http://192.168.1.100:7890` |
| `apt_mirror_enabled` | `true` | 换 TUNA 源 + 启用 PVE 无订阅源;海外设 `false` |
| `debian_mirror` / `proxmox_mirror` | TUNA | 换源目标,可改其它镜像站 |
| `apt_upgrade_enabled` | `false` | 换源后是否顺带全量升级系统 |
| `vm_networks_default` | `["virtio,bridge=vmbr0"]` | 每台 VM 的默认网卡(旁路由单桥够用;主路由用双桥) |
| `vm_ram_check` | `sum` | 内存预检:`sum` 全部同跑 / `max` 只跑一台 / `off` 跳过 |

`proxmox_vms` 每项字段:

| 字段 | 必填 | 说明 |
|---|---|---|
| `vmid` / `name` | ✓ | VM ID 与名字(同 ID 同名 = 跳过,幂等) |
| `memory` | ✓ | 内存 MB |
| `disk_bus` | ✓ | 启动盘总线:`virtio0` / `sata0` / `scsi0` |
| `disk_size` | ✓ | 扩容目标,如 `"8G"` |
| `image_url` | ✓ | 官方镜像地址(`.img.zip` / `.img.gz` / 裸 `.img`) |
| `archive_format` | ✓ | `zip` / `gz` / `raw` |
| `checksum_url` | ✓ | sha256sums 地址,填 `""` 跳过校验 |
| `onboot` | | `1` = 随宿主机自启(默认 0) |
| `cores` | | vCPU 数(默认宿主机全部 vCPU/逻辑核) |
| `networks` | | 覆盖默认网卡,如 `["virtio,bridge=vmbr0", "virtio,bridge=vmbr1"]` |

`vars.example.yml` 内置三个可直接取消注释的示例:OpenWrt、ImmortalWrt、RouterOS CHR。

## 远程模式(不在 PVE 本机跑)

装有 ansible 的任意机器上:

```bash
git clone https://github.com/alviezhang/pve-softrouter.git && cd pve-softrouter
make provision   # 前两次运行会依次生成 vars.yml、inventory.yml,填好后第三次运行开始创建
```

## 作为 Ansible collection 使用

```bash
ansible-galaxy collection install git+https://github.com/alviezhang/pve-softrouter.git
ansible-playbook -i your-inventory alviezhang.pve_softrouter.provision -e @vars.yml -l <你的PVE主机名>
```

或在自己的 playbook 里引用 role:`alviezhang.pve_softrouter.proxmox_vm`、
`alviezhang.pve_softrouter.apt_mirror`(需 `become: true`)。

## 常见问题

**下载镜像很慢/失败?** 在 vars.yml 里设 `proxy_url` 走代理;OpenWrt/ImmortalWrt
官方源国内直连一般可用但速度一般。

**GitHub 直连很慢/超时?** 国内机器可加个镜像前缀:`GH_MIRROR=https://ghfast.top/ bash <(...)`
(须以 `/` 结尾);失效的话换成其它 GitHub 加速前缀,同样须以 `/` 结尾。

**换源没生效?** apt_mirror 只改指向官方 debian.org 的源;已经用其它镜像(阿里云等)的机器不会被二次修改。

**RouterOS CHR 的授权?** CHR 免费跑,未授权时上传限速 1 Mbps,授权在
MikroTik 官网购买;本项目只负责建 VM。

**VM 建好后怎么配置成路由器?** 本项目管到"官方镜像原样启动"为止;OpenWrt 的
LAN IP 默认 `192.168.1.1`,后续配置请参考各系统官方文档。

**会动我现有的 VM 吗?** 不会。同 vmid 且同名 → 跳过(只校正 onboot);同 vmid
不同名,或同 vmid 同名但缺启动盘(上次中断的半成品),也会报错停止并提示手动清理。

**想删掉重来?** `qm destroy <vmid> --purge 1`(会删除该 VM 及其磁盘),然后重跑。

## License

[MIT](LICENSE)
