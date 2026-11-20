# 本机配置迁移清单

[English](configuration-migration.en.md)

本次只读比较了本机实际配置和链接目标，没有切换宿主机链接。

| 本机配置 | 仓库处理 |
| --- | --- |
| WezTerm | 配色、字体、透明度、165 FPS、三/四分屏、导航键已迁入；Nerd Font 锁定安装 |
| Zsh | 共享历史、去重、Emacs 键位、Ctrl+O、Ctrl+Y、补全选择习惯已迁入；Starship 和四插件替代运行时插件管理器 |
| Bash | history append、历史长度、窗口大小检查、系统补全和公共别名已迁入 |
| 公共 Shell | proxy_on/off、ll/la/l/gs/py/cls/mcpp；保留标准命令 |
| Git | main/prune/zdiff3、日志快捷方式、delta、local include；姓名邮箱不复制 |
| tmux | 本机没有 ~/.tmux.conf；保留仓库 vi copy-mode、鼠标、分屏和颜色基线 |
| GNOME | 仅桌面外观、时钟、触控板点击、按钮布局和键盘选项白名单；独立 plan/apply/restore |
| 企业命令/代理、账号、工作区路径 | 排除，归 ~/.config/shell/local.sh 或 ~/.config/git/config.local |
| Powerlevel10k、大型框架、ROS 自动 source | 不迁入默认环境，按既定架构保留本地选择 |

GNOME 示例：

```bash
./setup.sh desktop plan
./setup.sh desktop apply --yes
./setup.sh desktop restore --yes
```

apply 前逐键备份到状态目录，重复执行保留首次备份；restore 会恢复清单内各键原值。没有整份 dconf 导出，也不部署显示器/硬件/登录设置。实际 GNOME 会话未在宿主机写入验证，自动化 round-trip 使用 mock。

Git 私有身份示例（自行填入，不提交）：

```ini
[user]
    name = Your Name
    email = you@example.com
```

放到 ~/.config/git/config.local。仓库克隆目录必须保留；已有链接不会因为 Git pull 自动切换到另一份仓库。
