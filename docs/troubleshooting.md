# 故障排除

[English](troubleshooting.en.md)

- 配置冲突：先 status 预览，审阅目标文件后手动备份移动，再 deploy；不要 force。
- 网络失败：检查代理，按网络模式重试；npm/Node/Rust 支持镜像到官方回退，apt 清华失败时恢复备份重试一次。
- optional 失败：查看 ~/.local/state/dotfiles/failures.tsv，修复后重跑；独立模块会继续。
- Shell 缓存缺失/过期：执行 ./setup.sh module update TOOL；启动不联网重建。
- 并发锁：等待另一个操作退出，不删除 run.flock。
- xdotter 校验失败：恢复准确的 v0.5.2 文件并检查 SHA256SUMS。
- 插件脏仓库：先自行提交/保存修改，再 repos update；项目不会 reset。
- GNOME 操作：需在登录的 GNOME 会话中执行，Docker 没有真实桌面会话。
