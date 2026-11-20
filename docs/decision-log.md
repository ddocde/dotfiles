# 决策记录

[English](decision-log.en.md)

- Shell 负责编排，xdotter 管符号链接；不使用 Rust CLI 核心。
- Profile 组合稳定依赖 DAG，工具安装和配置部署分离。
- 中国网络模式和 Ubuntu 清华 apt 为默认，集中处理代理、校验、回退。
- Codex/Claude 保留 npm latest 例外；其他锁定工具同步已选版本。
- 默认安装不在 Shell 启动时联网。插件跟随上游更新为显式操作，可启用用户级每周定时器。
- 不引入大型 Shell 框架、历史云服务、KDE/窗口管理器分支或通用 hook 系统。
- 本机通用偏好可迁移；账号、公司配置、硬件专用设置保留本地。
- Claude npm 分发方式沿用用户选择，实际分发策略可能变化，按实装结果报告。
