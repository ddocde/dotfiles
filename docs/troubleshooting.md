# 故障排除

[English](troubleshooting.en.md)

AI CLI 安装显示 npm 成功但提示缺少原生依赖时，旧安装器可能忽略了 optional 下载失败。升级本仓库后重新执行对应模块安装；新安装器检查实际命令并回退官方源。中断后出现 ENOTEMPTY 时，先确认没有另一个 setup/npm 安装正在运行；新版本会清理独立 prefix 内对应包的 npm 暂存目录，无需删除整个 ~/.npm 或修改用户 .npmrc。

- 配置冲突：先 status 预览，审阅目标文件后手动备份移动，再 deploy；不要 force。
- 网络失败：检查代理，按网络模式重试；npm/Node/Rust 支持镜像到官方回退，apt 清华失败时恢复备份重试一次。
- optional 失败：查看 ~/.local/state/dotfiles/failures.tsv，修复后重跑；独立模块会继续。
- Shell 缓存缺失/过期：执行 ./setup.sh module update TOOL；启动不联网重建。
- 并发锁：等待另一个操作退出，不删除 run.flock。
- xdotter 校验失败：恢复准确的 v0.5.2 文件并检查 SHA256SUMS。
- 插件脏仓库：先自行提交/保存修改，再 repos update；项目不会 reset。
- GNOME 操作：需在登录的 GNOME 会话中执行，Docker 没有真实桌面会话。
