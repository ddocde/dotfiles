# 安装

[English](installation.en.md)

卸载保留 apt 包、Rust 工具链和下载缓存。Node/Go/Python 如果安装前已经存在，会被接管并保留；只有本项目新安装、记录在 `owned-runtimes.list` 的版本会卸载。其他项目自有工具、npm prefix 与插件按模块清理。

准备 Bash、Git、curl、CA 证书，非 root 用户需要 sudo。先 plan 和 status，再 install PROFILE --yes；按网络预检、apt、模块安装、符号链接、doctor 执行。

```bash
./setup.sh plan workstation
./setup.sh status workstation
./setup.sh install workstation --yes --dry-run
./setup.sh install workstation --yes
```

Ubuntu 20+ 安装默认清华 apt 源，--apt-mirror keep 保留当前源。完整工具验证平台为 Ubuntu 24.04 x86_64，不等于所有 Ubuntu 20+ 全功能保证。

--dry-run 不联网、不创建文件、不执行 sudo。非交互必须指定 Profile 并带 --yes。标准 XDG config/data 目录须位于 HOME；可通过隔离 HOME 测试。宿主机测试不要执行真实安装，按[手动 Docker 指南](manual-verification.md)操作。
