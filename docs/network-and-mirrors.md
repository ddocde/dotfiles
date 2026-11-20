# 网络与镜像

[English](network-and-mirrors.en.md)

优先级：--network > DOTFILES_NETWORK_MODE > ~/.config/dotfiles/network.env > china。

china 默认 npmmirror、RsProxy、goproxy.cn、清华 PyPI 和 GitHub 镜像；official 使用官方源；auto 短超时探测 GitHub，dry-run 不探测并预览 china。这是固定顺序，不是吞吐测速。

继承大小写 HTTP_PROXY/HTTPS_PROXY/ALL_PROXY，不持久化代理。proxy_on/off 由 Bash/Zsh 共享，私有地址放 local.sh 或 network.env。

## apt

Ubuntu 20+ install/update 默认清华源，--apt-mirror keep 保留当前源，独立于 --network。自动保留系统版本、代号、仓库组件、签名键。识别官方地址、Ubuntu archive key 或基础组件的 Ubuntu 仓库，包括公司镜像；第三方软件仓库仍使用各自地址。官方 security.ubuntu.com 保留。

```bash
./setup.sh apt-mirror tuna --yes
./setup.sh apt-mirror restore --yes
```

源是 /etc/apt 系统文件，不是用户符号链接。改动前在旁边保存 .dotfiles-original；重复换源不覆盖首次备份，手动改动后恢复会拒绝覆盖。独立换源后自行 apt-get update，安装流程统一刷新。

apt 有 8 次重试和 30 秒超时。清华下失败后尝试恢复原备份、重新刷新索引并安装一次；原源也失败则非零。第三方仓库故障不会因切换 Ubuntu 源而消失。

## Release 和 Git

GitHub 文件和插件优先 ghfast.top、mirror.ghproxy.com，之后官方。下载检查 SHA256 或 commit；文件使用临时落盘、10 秒连接超时、默认 180 秒传输超时（固定 Release 归档为 900 秒）、1 次重试及相同秒数重试预算、30 秒低速检测（1 KiB/s）。curl 最后一次重试可能超过预算结束时间。

VS Code 可先从官方 CDN 预取，WezTerm 可先从 Release 预取；两者均以已验证签名的 apt 索引中的 SHA256 校验后才交给 apt 安装。大于等于 8 MiB 的包尝试四段并行 Range 请求，要求 HTTP 206、长度正确与合并校验通过；失败后尝试下一源，再回退顺序下载，预取失败最终交给 apt。分段请求每次最多 900 秒，顺序包下载每次最多 1800 秒，另有重试，不保证总时间等于单次超时。

固定 Release 缓存在 `~/.cache/dotfiles/downloads`，重新使用前校验。旧版 data/bin 中的归档只有通过当前锁校验才迁入缓存。卸载不删除下载缓存；mise 配置保留后续下载的运行时归档，已有安装不保证具备离线重装所需缓存。

## npm 与运行时

中国模式 npm/Node/Rust 首次尝试最多 600 秒，失败后官方最多 900 秒，超时允许 10 秒退出后杀掉残余进程。npm 请求超时 30 秒、fetch 重试 1 次。两个源均失败仍非零；固定版本、独立 npm prefix、rustup-init 校验和 AI latest 规则不变。官方回退只改变本次命令环境，不永久修改 nrm 选择。

AI CLI 的 `latest` 包是传输预算例外：镜像最多 180 秒，官方最多 1800 秒；official 模式直接给 1800 秒。原生平台包可能超过 100 MiB。npm 安装后立即执行 CLI 的 `--version`；即使 npm 返回 0，原生依赖缺失也判定失败并进入官方回退，不能等到最后 doctor 才发现。两个源均不可用时仍失败，不记录为安装成功。

官方尝试会先读取当前 latest 的平台依赖与 SHA512 integrity，分段预取后校验并导入 npm 缓存，再执行 npm install latest。8–100 MiB 使用四段，100 MiB 以上使用十六段；不支持 Range 或预取失败时仍由 npm 正常下载。npm 的完整性校验和 CLI 可执行检查保留。超时取消先结束旧尝试；重试前只清理项目独立 prefix 内该 AI 包的 npm rename 暂存目录，避免 ENOTEMPTY，不清理用户全局 npm 目录或 .npmrc。

只有选择 npm 工具时才预检 npm；探测失败只警告，由实际安装回退。minimal 不依赖 npm 联网。Python/Go 运行时仍依赖 mise 自身行为；PyPI/GOPROXY 配置主要加速包/模块，不代表运行时有独立 URL 回退。

## 本机覆盖

```dotenv
DOTFILES_NETWORK_MODE=china
DOTFILES_PROXY_URL=http://127.0.0.1:7897
DOTFILES_GITHUB_MIRRORS="https://ghfast.top https://mirror.ghproxy.com"
DOTFILES_GOPROXY=https://goproxy.cn,direct
DOTFILES_PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
# 第三方仓库可设置经过确认的兼容镜像，不包含凭据：
# DOTFILES_VSCODE_APT_REPO=https://packages.microsoft.com/repos/code
# DOTFILES_WEZTERM_APT_REPO=https://apt.fury.io/wez/
```

字段按白名单解析，不执行 Shell。完整参数来源见英文版所列 npm/mise/rustup 官方文档。
