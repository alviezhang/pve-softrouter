.PHONY: provision local

# 远程模式:inventory.yml 指向你的 PVE 节点
provision: vars.yml inventory.yml
	ansible-playbook -i inventory.yml site.yml

# 本机模式:直接在 PVE 节点上执行
local: vars.yml
	ansible-playbook -i 'localhost,' -c local site.yml

vars.yml:
	cp vars.example.yml vars.yml
	@echo "已生成 vars.yml —— 编辑后重新运行"
	@exit 1

inventory.yml:
	cp inventory.example.yml inventory.yml
	@echo "已生成 inventory.yml —— 填入你的 PVE IP 后重新运行"
	@exit 1
