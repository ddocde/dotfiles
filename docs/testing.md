# 测试

[English](testing.en.md)

./tests/run.sh 覆盖 Profile、依赖、网络模式、回退、dry-run、锁、版本状态、冲突、卸载失败、插件更新和桌面 mock。

真实安装只在 glcr.rd.ubtrobot.com/rosa/images/rust:ubuntu24.04 内执行，使用隔离 HOME、标准 XDG 子路径和只读项目挂载。先 ./scripts/docker-build-test.sh 运行语法、单测、ShellCheck，再按[手动指南](manual-verification.md)执行。

完整验收脚本为 tests/workstation-docker.sh，依次首装、重复、doctor、卸载、重装，并检查交互式 Bash/Zsh。保留命名容器、阶段日志与实际退出码。GNOME 设置和 systemd 用户定时器使用 mock 测试；容器结果不是实机桌面验证。

Shell 性能在同容器 PTY 中测量冷/热交互就绪时间，屏蔽网络命令，记录基线而不设任意毫秒阈值。

完整安装后在保留的容器中执行 `bash tests/shell-startup-docker.sh`。输出第一次测量与五次后续样本；这不是清空系统文件缓存的物理冷启动，也不测量 GUI 绘制。测试同时屏蔽 curl/wget/Git 网络命令，并用 strace 检查 Bash/Zsh 启动是否创建 IPv4/IPv6 socket 或连接。
