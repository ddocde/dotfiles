# 收尾验收台账

[English](completion-ledger.en.md)

验收范围：Ubuntu 24.04 x86_64 的个人开发环境。原参考项目与宿主机配置保持独立。默认中文，提供英文使用文档与 AI skill。

| 项目 | 负责人 | 当前状态 | 验收证据/下一步 |
| --- | --- | --- | --- |
| 运行锁、卸载失败传播、精确链接所有权 | Codex | 验收通过 | 单元/故障注入与两轮完整卸载重装 |
| doctor 版本、链接、缓存、全部 LSP | Codex | 验收通过 | 全 workstation doctor；YAML LSP initialize/shutdown |
| 本机 Zsh/Bash/Git/WezTerm 通用习惯 | Codex | 验收通过 | 交互/非交互 Shell、配置解析与符号链接验证；未验证 GUI 显示效果 |
| Nerd Font | Codex | Docker 已通过 | v3.4.0 真实分段下载、SHA256、fc-match 返回 FiraCode Nerd Font |
| 通用 Git 清单、预览、离线回滚与更新策略 | Codex | 本地及真实 GitHub 测试通过 | fzf-tab 克隆/更新/回滚、修改保护、关闭代理端口模拟断网后保留原提交；timer 仅 mock 和 unit 语法检查 |
| GNOME 偏好 | Codex | 隔离后端通过 | 真实 D-Bus/dconf 应用/重复/恢复；实际图形会话未验收，不在宿主机应用 |
| apt 清华失败后恢复重试 | Codex | 验收通过 | Mock 失败传播；真实清华索引/下载、备份恢复和手动修改保护 |
| minimal 首装、重复、doctor、卸载、重装 | Codex | Docker 已通过 | 2026-11-20，dotfiles-closeout-minimal；ACCEPTANCE PASSED |
| workstation 安装、重复、doctor、卸载、重装 | Codex | 冻结代码连续两轮通过 | 2026-11-20 11:06:17Z、11:07:42Z，tests/workstation-docker.sh |
| 空配置/空用户工具目录首次引导 | Codex | 通过 | 11:00:08Z–11:09:11Z，dotfiles-fresh-v5；只复制下载缓存，不复制运行时/配置/状态 |
| 单模块卸载及版本选择隔离 | Codex | 通过 | 实际卸载新装 Go，mise/Node/Python 保留，Node 不触发 Go 自动重装；恢复后完整 doctor |
| 用户私有 npmrc | Codex | 通过 | tests/npm-config-docker.sh；scope/token 样本在真实 nrm 模块安装前后字节一致 |
| Shell PTY 启动基线、无网络启动 | Codex | Docker 已通过 | 首轮/后续样本、网络命令拦截与 strace；见下方数据 |
| C/C++/Rust/Go/Node/Python 功能 | Codex | Docker 已通过 | 前四者实际编译并运行，Node/Python 执行示例 |
| 中文/英文文档、AI skill | Codex | 本地校验通过 | 47 份文档配对/链接与 skill validator；发布 CI 见 [Actions](https://github.com/ddocde/dotfiles/actions/workflows/check.yml) 的 main 最新提交 |

未完成的现场验收：真实 GNOME 图形效果、真实 systemd 用户定时器触发与关闭。Ubuntu 20/22/26 完整工具集、ARM、macOS、Termux 没有对应实机验收；后面三者的完整安装目前拒绝执行。屏幕、指纹、电源、驱动与账号不能用 Docker 结果冒充整机克隆。

2026-11-20 静态构建及 39 项测试通过，验收代码为 4248034（后续提交仅文档）。真实 apt 安全测试在 dotfiles-closeout-apt-safety 通过。workstation 使用 dotfiles-final-lifecycle，复用指定 Ubuntu 镜像后代的系统包，隔离 HOME、只读挂载。两轮生命周期采用已有运行时；另用新的 dotfiles-fresh-v5 HOME 从空工具目录安装全部运行时，验证其新装路径。只复用已下载的归档/npm/Rust 下载缓存，不复制任何安装目录；不是无缓存联网速度基准。原始日志留在测试环境，不提交包含环境地址的完整日志。

失败与修复：字体原 180 秒预算不足；npm 可在原生依赖下载失败时返回 0；取消后 npm 子进程和暂存目录导致 ENOTEMPTY；nrm 2 忽略独立配置路径；未版本化 rustup-init 与固定校验和不匹配；Python 动态解析回落到 pyenv 后超时。均已修正。一次测试因运行期间编辑 setup.sh 而读取错位中止，最终冻结代码后从新 HOME 完整重跑，未计入通过次数。继承代理时大文件曾出现 TLS 错误，最终实装使用容器直连；未修改宿主机代理。

最终 Shell 基线（同容器 PTY，交互就绪，毫秒）：Bash 首测 158.66，后五轮中位数 127.95；Zsh 首测 799.69，后五轮中位数 674.27。缓存已由生命周期检查预热，不等于物理冷启动，也不测 GUI 绘制。较早首次测量 Zsh 曾为 6451.10 ms，保留在原始记录，不能与热样本混用。网络命令拦截与 IPv4/IPv6 socket 检查通过，未设置任意绝对性能阈值。

主机保留的原始记录：/tmp/dotfiles-frozen-lifecycle.log、/tmp/dotfiles-fresh-home-v5.log、/tmp/dotfiles-owned-runtime.log、/tmp/dotfiles-npm-config-final.log、/tmp/dotfiles-shell-startup-final-v2.log。容器 /tmp 下会保存对应副本，供本人检查。
