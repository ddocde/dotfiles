# 模块

[English](modules.en.md)

模块可包含 depends.list、packages.apt、artifacts.lock、生命周期脚本、xdotter.toml 和 config/。锁文件为制表符分隔的名称、版本、URL、SHA256、目标文件名，可选第六列记录字节大小以启用大文件分段下载。

install/update 管工具，xdotter 管配置链接。镜像、代理、校验与回退集中在 lib/network.sh。Profile 只组合模块。

Starship、Yazi、GitUI、Navi 使用锁定 Release，避免 Cargo 编译。mise 管 Node/Python/Go；rustup 管固定 Rust；Codex/Claude 为 npm latest 例外。

zsh-plugins/repositories.list 定义插件仓库和锁定提交；明确执行 repos update 后记录本机覆盖提交，后续安装复用该版本，不覆盖脏仓库。fonts 安装带上游 SHA256 的 FiraCode Nerd Font，随下载包保留许可证。
