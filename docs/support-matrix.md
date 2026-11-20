# 支持范围

[English](support-matrix.en.md)

| 环境 | 支持状态 |
| --- | --- |
| Ubuntu 24.04 x86_64 + 标准 HOME/XDG 路径 | 完整安装验收目标，Docker 中测试 |
| Ubuntu 20.04+ apt 源 | 自动识别版本/代号，兼容 list/sources；不改变 Ubuntu 版本 |
| 其他 Ubuntu 版本的完整工具集 | 未实装验收，包名和 Release 的 glibc 要求可能不同 |
| ARM、macOS、Termux 完整安装 | 尚不支持；Profile 可供审阅，真实安装在修改系统前拒绝 |
| GNOME 桌面偏好 | 独立显式命令；mock 与隔离真实 dconf 后端通过，图形会话效果未验收 |
| 非标准 XDG config/data | xdotter 0.5.2 不展开目标环境变量，目前提前拒绝；隔离测试改 HOME |

硬件驱动、显示器、指纹、磁盘、VPN、账号、输入法词库、SSH/GPG 密钥和历史数据不属于可公开分发的 dotfiles。不能宣称本仓库能克隆整台电脑。
