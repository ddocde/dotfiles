# 自定义

[English](customization.en.md)

常用工具通过 profiles/*.list 增删或注释；配置内容在 modules/*/config/。本机路径、Git 身份、公司设置和私有代理放在本地文件。

共享别名不替换 ls/cat/cd；ll、la、l、gs、py、cls、mcpp 提供明确快捷方式。Zsh 使用本地历史和 fzf，不启用历史云同步。

本地 Shell 配置使用 ~/.config/shell/local.sh，Git 身份使用 ~/.config/git/config.local。文件需自行创建且不提交。详见[迁移清单](configuration-migration.md)。
