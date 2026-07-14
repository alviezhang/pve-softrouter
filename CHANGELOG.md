# Changelog

## v1.1.0

- 安全加固(外部 codex 审查):回滚不再使用 --destroy-unreferenced-disks(不碰既有孤儿卷);回滚需匹配本次运行标记(并发安全);回滚失败不再被吞掉;同名但缺启动盘或启动顺序的半成品 VM 会报错而非被跳过。
- apt_mirror:legacy sources.list 改为带时间戳备份(.bak)而非删除,检测到第三方源或带选项([arch=…])/deb-src 条目时跳过迁移;enterprise 源只看活跃行、且须全部指向 enterprise.proxmox.com 才删除,不再按文件名误删自定义 ceph 源或仅注释提及的文件。
- 入口防呆:site.yml / provision / quickstart 先校验 /etc/pve,非 PVE 主机直接拒绝。
- quickstart:默认直连 GitHub,镜像加速改为显式 GH_MIRROR= opt-in;脚本包入 main() 并以花括号组收尾,下载截断只会报语法错误、零执行;checksum_url 成为必填字段("" 显式跳过)。
- collection 包收入 examples/ 与 vars.example.yml。
- quickstart.sh:系统名改为必选(不再隐式默认 OpenWrt),`-h` 显示用法;其余选项以 `key=value` 透传 ansible(`bridges=vmbr0,vmbr1` 自动展开为网卡列表),一条命令零交互。
- vars.example.yml:三个系统示例全部注释,由用户显式选择。

## v1.0.0 (2026-07-13)

- 首个版本:`proxmox_vm`(create-only VM provisioning)+ `apt_mirror`(TUNA 换源)
  两个 role;quickstart 一键脚本;clone / collection 双形态。
