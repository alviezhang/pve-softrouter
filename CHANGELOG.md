# Changelog

## Unreleased

- quickstart.sh:系统名改为必选(不再隐式默认 OpenWrt),`-h` 显示用法;其余选项以 `key=value` 透传 ansible(`bridges=vmbr0,vmbr1` 自动展开为网卡列表),一条命令零交互。
- vars.example.yml:三个系统示例全部注释,由用户显式选择。

## v1.0.0 (2026-07-13)

- 首个版本:`proxmox_vm`(create-only VM provisioning)+ `apt_mirror`(TUNA 换源)
  两个 role;quickstart 一键脚本;clone / collection 双形态。
