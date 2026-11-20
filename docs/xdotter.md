# xdotter 部署

[English](xdotter.en.md)

Linux x86_64 使用 vendored xdotter 0.5.2 musl 二进制，每次使用检查 SHA256 和版本。来源与许可证在 vendor/xdotter/。

每个模块拥有自己的 xdotter.toml。0.5.2 没有 validate 子命令，使用 deploy --dry-run 进行校验和预览。status 是只读预览，deploy 执行链接。默认不强制覆盖；已有用户文件冲突需先审阅。

部署后配置指向仓库，移动/删除仓库会导致链接失效。卸载仅撤销受管理链接，失败不得继续删除模块文件。当前版本要求标准 HOME/.config 和 HOME/.local/share 路径。
