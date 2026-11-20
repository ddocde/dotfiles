# WezTerm

配置已按当前电脑的使用习惯迁入：Gruvbox Material 配色、16.5 字号、0.8 透明度、165 FPS、底部标签栏和登录 Zsh。

| 操作 | 快捷键 |
| --- | --- |
| 命令面板 | Ctrl+Shift+P |
| 重新加载配置 | Ctrl+Shift+R |
| 全屏 | Super+F |
| 切换分屏 | Alt+h/j/k/l |
| 三等分布局 | F20，或命令面板中的对应事件 |
| 四等分布局 | F21，或命令面板中的对应事件 |

模块依赖 Zsh 和 fonts。fonts 模块安装经上游 SHA256 校验的 FiraCode Nerd Font 3.4.0，并提供 apt 的 Fira Code 回退。doctor 检查字体匹配和配置解析；图形窗口的最终视觉效果仍需桌面会话核对。

xdotter 将 `~/.config/wezterm/wezterm.lua` 链接到此模块的 `config/wezterm.lua`。当前电脑上的旧链接不会因为编辑仓库而切换。已有配置冲突时先运行 `./setup.sh module status wezterm --network official` 查看计划，再审阅和手动迁移。

在新机器上可通过 `./setup.sh module install wezterm --yes` 安装，或使用完整的 workstation Profile。
