# 安全边界

[English](security.en.md)

项目不管理 SSH/GPG 密钥、API key、登录状态、Git 身份或 npm token。固定下载需 SHA256，插件按提交核对。不会使用 curl 管道执行脚本、sudo npm、apt autoremove 或强制配置覆盖。

apt 默认清华源仍保留签名验证；原文件旁保留 .dotfiles-original 备份，可通过 apt-mirror restore 恢复。手动改动后拒绝自动覆盖。

写操作使用 run.flock 内核锁。锁文件保持原 inode，禁止删除“解锁”。并发操作会失败，进程退出自动释放。插件有本地修改时不更新或删除。

日志仅应包含工具版本、阶段和退出码；不提交凭据、整份 dconf、历史记录或公司地址。
