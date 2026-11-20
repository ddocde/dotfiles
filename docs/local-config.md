# 本地配置

[English](local-config.en.md)

~/.config/shell/local.sh 仅在当前用户拥有且不可被组/其他用户写入时加载。~/.config/git/config.local 用于用户名、邮箱、签名等。~/.config/dotfiles/network.env 用于私有代理与镜像覆盖。

network.env 只解析允许的 DOTFILES_* 字段，不 source 任意 Shell 代码。可设置 DOTFILES_NETWORK_MODE=china 和 DOTFILES_PROXY_URL。完整键列表见[网络文档](network-and-mirrors.md)。不要把 Token、认证头、私有地址或密钥放入跟踪文件。
