# 开源项目对照审查

[English](open-source-review.en.md)

参考 [chezmoi](https://github.com/twpayne/chezmoi) 的预览再应用与状态保护、[Dotbot](https://github.com/anishathalye/dotbot) 的幂等任务和 dry-run、[yadm](https://github.com/yadm-dev/yadm) 的冲突保留与本地状态。

采纳：只读 status、缓存复用、内核锁、默认拒绝覆盖、optional 失败继续独立任务并最终非零、CI 静态检查。参考用户旧项目的插件更新体验，另提供显式 repos update 和每周用户定时器。

没有迁移到这些框架；没有引入模板引擎、加密秘密存储、通用 hook 系统、无条件链接清理或强制替换。配置部署仍由 xdotter 执行。
