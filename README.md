# dotfiles

> Shell-first 的个人 Linux 环境管理器：可重复、可审计，并且默认不覆盖现有配置。

[English](README.en.md) · [架构](docs/architecture.md) · [安装说明](docs/installation.md) · [贡献指南](CONTRIBUTING.md)

`dotfiles` 用 Profile 描述一台机器需要什么，用独立 Module 管理每个工具，并由 [xdotter](docs/xdotter.md) 只负责符号链接部署。安装工具与部署配置是两件独立的事，因此可以分别预览、执行和排错。

## 为什么使用它

- 一条公开入口：`./setup.sh`。
- Profile 表达使用场景，Module 表达工具的安装、更新、卸载、配置和检查。
- 下载的固定二进制采用版本和 SHA-256 锁定；Codex 与 Claude Code 是有意保留的 `latest` 例外。
- Shell 启动不联网，也不动态生成初始化脚本。
- 默认拒绝覆盖已有文件、拒绝强制部署，也不会自动移除 apt 软件包。
- 身份、密钥、Token、登录状态和私有代理均不进入仓库。

## 工作方式

```text
Profile
  └─ 解析 Module 与依赖
       ├─ 批量安装系统包
       ├─ 安装模块管理的工具
       ├─ xdotter 部署配置链接
       └─ doctor 按实际系统状态检查
```

```text
安装工具：模块 install/update 脚本
部署配置：模块 xdotter.toml
本地私有配置：~/.config 下的 local 文件
```

更多设计说明见[架构](docs/architecture.md)、[模块](docs/modules.md)与[部署模型](docs/xdotter.md)。

## Profile

Profile 是按顺序读取的纯文本清单，位于 `profiles/*.list`。支持注释、`@include` 和可选模块：

```text
@include developer
wezterm
?helix
```

| Profile | 适用场景 |
| --- | --- |
| `minimal` | 基础 Shell、Git、网络与核心配置 |
| `developer` | 常用 CLI、语言工具链、tmux、yazi、gitui；Helix 可选 |
| `workstation` | `developer` 加桌面终端、字体、navi、nrm、Codex 与 Claude Code |
| `server` | `minimal` 加 tmux |
| `termux` | 面向 Termux 的轻量工具组合 |

交互式运行未指定 Profile 时默认使用 `workstation`。脚本、CI 或其他非交互场景必须显式指定 Profile，并附带 `--yes`。

## 安装

先查看计划；这一步不会修改系统：

```bash
git clone <你的仓库地址> dotfiles
cd dotfiles

./setup.sh plan workstation --network china
./setup.sh install workstation --yes --network china
```

首次运行需要 Bash、Git、curl、CA 证书；在非 root 的 Linux 上，安装系统包还需要 `sudo`。`install` 会依次完成网络预检、系统依赖安装、模块安装、配置部署和 `doctor`。

仅想验证将要发生的事情时使用：

```bash
./setup.sh install developer --yes --dry-run
```

`--dry-run` 不会下载、不写文件、不执行 `sudo`。

## 常用命令

```bash
# 查看所有 Profile 与 Module
./setup.sh list

# 展开 Profile、依赖和执行顺序
./setup.sh plan developer

# 只部署配置，或只检查当前机器状态
./setup.sh deploy minimal --yes
./setup.sh doctor developer --yes

# 依据当前锁定配置更新并重新部署
./setup.sh update workstation --yes

# 以逆依赖顺序移除模块自身文件；默认保留 apt 包
./setup.sh uninstall workstation --yes

# 仅操作单个模块
./setup.sh module plan zsh
./setup.sh module install zsh --yes
./setup.sh module deploy zsh --yes
./setup.sh module doctor zsh --yes
```

| 选项 | 作用 |
| --- | --- |
| `--dry-run` | 只打印操作，不产生副作用 |
| `--yes` | 非交互执行；遇到配置冲突直接失败 |
| `--network auto\|china\|official` | 选择网络与镜像策略 |
| `--enable MODULE` | 在当前 Profile 末尾加入模块 |
| `--disable MODULE` | 从当前 Profile 移除模块 |
| `--purge-packages` | 仅在 uninstall 时考虑删除选中 apt 包 |
| `--verbose` | 输出执行的命令 |

禁用模块时，请同时禁用依赖它的上游模块；被其他模块依赖的模块会被重新加入计划。

## 网络与镜像

默认网络模式是 `china`，优先级如下：

```text
--network > DOTFILES_NETWORK_MODE > ~/.config/dotfiles/network.env > china
```

- `china`：npm 使用 npmmirror；Rust 使用 RsProxy；Node 使用 npmmirror；Go 使用 goproxy.cn；Python 使用清华 PyPI；GitHub 下载使用已验证的镜像 fallback。
- `official`：仅使用官方 npm、Rust 和 Node 源。
- `auto`：用短超时探测 GitHub，稳定时使用官方源，否则使用国内镜像。

脚本会继承 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 及其小写形式，并为 apt 增加重试和超时。GitHub Release 和固定 Git 仓库在中国模式下会先尝试已验证的镜像，校验通过后才会写入。完整细节见[网络与镜像](docs/network-and-mirrors.md)。

Bash 和 Zsh 共享 `proxy_on` / `proxy_off` 代理开关，默认连接 `http://127.0.0.1:7897`：

```bash
proxy_on
proxy_off

# 临时使用其他地址，不写入仓库
DOTFILES_PROXY_URL=socks5://127.0.0.1:1080 proxy_on
```

可通过 `DOTFILES_PROXY_URL` 和 `DOTFILES_NO_PROXY` 自定义。仓库默认的 `NO_PROXY` 仅包含标准本机地址，不包含公司域名或私有网络配置。

## 本地化与自定义

以下文件由你自行创建，项目会读取但绝不会部署或提交它们：

```text
~/.config/shell/local.sh           # 私有 Shell 配置
~/.config/git/config.local         # user.name、user.email、公司 Git 设置等
~/.config/dotfiles/network.env     # 本机网络、代理与镜像覆盖
```

`local.sh` 仅在所有者与权限安全时才会被加载。不要把 SSH/GPG 密钥、API Token、npm Token 或 GitHub Token 放入仓库。参见[本地配置](docs/local-config.md)、[自定义](docs/customization.md)和[安全说明](docs/security.md)。

## 冲突、卸载与状态

- xdotter 发现目标文件已存在时默认拒绝覆盖；请先审阅并手动移动该文件，再重新部署。
- `uninstall` 只撤销链接并清理模块自己创建的文件；apt 包默认保留，且项目绝不自动运行 `apt autoremove`。
- 状态、失败记录和安装版本保存在 XDG 状态目录，供排错使用；`doctor` 始终以实际系统为准。

遇到问题先运行：

```bash
./setup.sh plan workstation --verbose
./setup.sh doctor workstation --yes --verbose
```

更具体的恢复步骤请看[故障排除](docs/troubleshooting.md)。

## 开发与验证

```bash
./tests/run.sh
./scripts/docker-build-test.sh
```

真实安装验证仅应在文档规定的 Docker 环境中进行，不要在开发宿主机直接运行完整安装。测试策略与容器命令见[测试说明](docs/testing.md)和[贡献指南](CONTRIBUTING.md)。

## 许可证与致谢

本项目采用 MIT License。第三方来源与归属见 [LICENSE](LICENSE)、[NOTICE](NOTICE) 和[致谢](docs/attribution.md)。
