# 收尾验收台账

[English](completion-ledger.en.md)

验收范围：Ubuntu 24.04 x86_64 的个人开发环境。原参考项目与宿主机配置保持独立。默认中文，提供英文使用文档与 AI skill。

| 项目 | 负责人 | 当前状态 | 验收证据/下一步 |
| --- | --- | --- | --- |
| 运行锁、卸载失败传播、精确链接所有权 | Codex | 已实现 | 单元/故障注入与完整卸载重装 |
| doctor 版本、链接、缓存、全部 LSP | Codex | 已实现 | 全 workstation doctor |
| 本机 Zsh/Bash/Git/WezTerm 通用习惯 | Codex | 已迁入 | 交互 Shell、配置解析与符号链接验证 |
| Nerd Font | Codex | Docker 已通过 | v3.4.0 真实分段下载、SHA256、fc-match 返回 FiraCode Nerd Font |
| 通用 Git 清单、预览、离线回滚与更新策略 | Codex | 本地测试通过 | pinned/head/branch、脏仓库保护、路径校验、远端失败；timer 仅 mock 和 unit 语法检查 |
| GNOME 偏好 | Codex | 显式 apply/restore | 白名单与备份；不在宿主机应用，不包含硬件/账号数据 |
| apt 清华失败后恢复重试 | Codex | 已实现 | Mock 失败传播；真实清华下载 |
| minimal 首装、重复、doctor、卸载、重装 | Codex | Docker 已通过 | 2026-11-20，dotfiles-closeout-minimal；ACCEPTANCE PASSED |
| workstation 首装、重复、doctor、卸载、重装 | Codex | 验收中 | tests/workstation-docker.sh；命名容器保留日志 |
| Shell PTY 启动基线、无网络启动 | Codex | 待实测 | 记录同容器冷/热结果，不设任意阈值 |
| 中文/英文文档、AI skill | Codex | 本地校验通过 | 47 份文档的配对/链接检查、skill validator；待 CI |

Ubuntu 20/22/26、ARM、macOS、Termux 没有对应实机验收，不计作已通过。屏幕、指纹、电源、驱动与账号依赖硬件/会话，不能用 Docker 结果冒充整机克隆。台账在最终验收后更新为实测结论。

2026-11-20 静态构建及 37 项测试通过。真实 apt 换源/重复/恢复/手动修改保护在 dotfiles-closeout-apt-safety 通过。workstation 使用 dotfiles-final-lifecycle，复用此前指定 Ubuntu 镜像后代的系统包及经核对的运行时/Release 缓存，隔离 HOME、只读挂载；这是生命周期验收，不是全新联网下载验收。早期字体下载使用 180 秒超时被中止，延长超时并启用分段后下载与校验通过。原始日志留在测试环境，不提交包含环境地址的完整日志。
