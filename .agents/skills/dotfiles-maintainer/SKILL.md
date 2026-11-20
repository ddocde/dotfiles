---
name: dotfiles-maintainer
description: 维护 ddocde/dotfiles 的 Shell 安装脚本、Profile、个人配置迁移和 Docker 验收；用于本仓库的安装、排错、配置与更新，不用于任意用户仓库的自动更新。
---

# dotfiles 维护

[English instructions](references/workflow.en.md)

先确定实际仓库根目录和 Git remote。工作区旁可能同时存在 CNCSMonster/dotfiles 上游和 ddocde/dotfiles 项目；只操作用户指定的项目，读取根目录 AGENTS.md、README.md、CONTRIBUTING.md 和相关 docs。

- `setup.sh` 是公开入口，Shell 负责安装与编排，xdotter 0.5.2 负责配置链接。版本校验、镜像回退集中在 lib，模块不要复制网络逻辑。
- Profile 支持注释、include、optional；required 声明优先。修改后用 plan 看最终依赖，而非只看文本清单。
- 真正安装、apt、全局 npm、rustup、配置部署只在指定 Docker 镜像中验收，仓库只读挂载，隔离 HOME。不能把宿主机现有配置当成可覆盖的测试文件。
- 完整验证目标是 Ubuntu 24.04 x86_64。Ubuntu 20+ 换源适配不是全工具跨版本验收；ARM/Termux/macOS 不得标记为通过而没有实际证据。
- 用户配置迁移先比较实际文件和链接目标。提交通用偏好，不提交 Git 身份、企业地址、Token、登录记录、SSH/GPG 或整份 dconf 导出。私有设置归 local.sh/config.local。
- Ubuntu 默认清华 apt 镜像使用系统文件备份恢复，不是 HOME 下的符号链接。保留签名校验，第三方软件仓库不能指向 Ubuntu 镜像。
- 工具默认按锁定版本同步；Codex/Claude 为 latest 例外。`repos` 只管理清单内克隆，包含插件与通用仓库；遵循 pinned/head/branch 策略和 manual/auto 选择。更新保留一个离线回滚点，脏仓库必须停下，不使用 reset/force 清除修改。项目自身由用户授权后 Git pull/push。
- Node/Go/Python 接管的运行时卸载时保留，只移除 owned-runtimes.list 记录的新装版本。不要用测试缓存复用结果冒充全新联网安装。
- 运行锁使用 flock，持久锁文件不能删除。卸载时先撤销链接，失败不得继续删除工具或记录成功。只清理模块明确拥有的路径；apt 包和用户数据按文档保留。
- doctor 检查系统实际情况、链接、锁定工具和缓存，不能把状态日志当成成功证据。缺失时给出可执行的 module install/update/deploy 建议。

验证随修改风险选择：文档差异检查；Shell 语法、测试和 Docker ShellCheck；生命周期改动运行 Docker 全流程（首装、重复、doctor、卸载、重装）；插件更新注入脏仓库和远端失败；桌面操作在 GNOME session 或 mock 中验证，并区分两者。

保持中文默认 README 与英文 README.en.md、文档索引及手动流程一致。记录真实通过、失败、未实测；交付前检查工作区、提交内容、CI。提交和推送遵循当前用户授权，不从 skill 自行扩展外部操作权限。
