# 收尾验收台账

[English](completion-ledger.en.md)

验收范围：Ubuntu 24.04 x86_64 的个人开发环境。原参考项目与宿主机配置保持独立。默认中文，提供英文使用文档与 AI skill。

| 项目 | 负责人 | 当前状态 | 验收证据/下一步 |
| --- | --- | --- | --- |
| 运行锁、卸载失败传播、精确链接所有权 | Codex | 已实现 | 单元/故障注入与完整卸载重装 |
| doctor 版本、链接、缓存、全部 LSP | Codex | 已实现 | 全 workstation doctor |
| 本机 Zsh/Bash/Git/WezTerm 通用习惯 | Codex | 已迁入 | 交互 Shell、配置解析与符号链接验证 |
| Nerd Font | Codex | Docker 已通过 | v3.4.0 真实分段下载、SHA256、fc-match 返回 FiraCode Nerd Font |
| 通用 Git 清单、预览、离线回滚与更新策略 | Codex | 本地及真实 GitHub 测试通过 | fzf-tab 克隆/更新/回滚、修改保护、关闭代理端口模拟断网后保留原提交；timer 仅 mock 和 unit 语法检查 |
| GNOME 偏好 | Codex | 隔离后端通过 | 真实 D-Bus/dconf 应用/重复/恢复；实际图形会话未验收，不在宿主机应用 |
| apt 清华失败后恢复重试 | Codex | 已实现 | Mock 失败传播；真实清华下载 |
| minimal 首装、重复、doctor、卸载、重装 | Codex | Docker 已通过 | 2026-11-20，dotfiles-closeout-minimal；ACCEPTANCE PASSED |
| workstation 首装、重复、doctor、卸载、重装 | Codex | 验收中 | tests/workstation-docker.sh；命名容器保留日志 |
| Shell PTY 启动基线、无网络启动 | Codex | Docker 已通过 | 首轮/后续样本、网络命令拦截与 strace；见下方数据 |
| C/C++/Rust/Go/Node/Python 功能 | Codex | Docker 已通过 | 前四者实际编译并运行，Node/Python 执行示例 |
| 中文/英文文档、AI skill | Codex | 本地校验及首轮 CI 通过 | 47 份文档的配对/链接检查、skill validator；最新修复待 CI |

Ubuntu 20/22/26、ARM、macOS、Termux 没有对应实机验收，不计作已通过。屏幕、指纹、电源、驱动与账号依赖硬件/会话，不能用 Docker 结果冒充整机克隆。台账在最终验收后更新为实测结论。

2026-11-20 静态构建及 38 项测试通过。真实 apt 换源/重复/恢复/手动修改保护在 dotfiles-closeout-apt-safety 通过。workstation 使用 dotfiles-final-lifecycle，复用此前指定 Ubuntu 镜像后代的系统包及经核对的运行时/Release 缓存，隔离 HOME、只读挂载；这是生命周期验收，不是全新联网下载验收。原始日志留在测试环境，不提交包含环境地址的完整日志。

失败与修复：字体归档原 180 秒预算不足，延长并分段后通过；npm 返回 0 但 Codex 原生依赖缺失，被 doctor 检出；中断 npm 留下子进程和 rename 暂存目录，导致 ENOTEMPTY。现增加安装内可执行检查、完整取消测试、限定暂存清理与官方 SHA512 原生包预取。继承代理的官方大文件出现 TLS 错误，当前使用容器直连重跑；不能将这些失败尝试写成完整验收通过。

Shell 基线（同一容器 PTY，交互就绪，毫秒）：Bash 首轮 108.14，后五轮中位数 102.22；Zsh 首轮 6451.10，后五轮中位数 654.42。首轮不等于物理冷启动，未测 GUI 绘制；网络命令拦截与 IPv4/IPv6 socket 检查通过。原始记录在容器 `/tmp/dotfiles-shell-startup.jsonl`。
