# 贡献与验证

[English](CONTRIBUTING.en.md)

先读取 README、相关文档并运行 ./setup.sh plan PROFILE。保持 Shell 安装与 xdotter 部署分离，保留用户改动、私有配置和上游许可。

```bash
bash scripts/check-shell.sh
./tests/run.sh
./scripts/docker-build-test.sh
python3 tests/check-docs.py
git diff --check
```

Docker 构建执行 ShellCheck；生命周期改动按 tests/workstation-docker.sh 完整验收。真实安装只在指定 Ubuntu 镜像、隔离 HOME、只读仓库挂载中进行，不在宿主机执行。桌面与定时器 mock 结果不能写成实机通过。

中文默认文档和英文版本同时维护；skill 在 .agents/skills/dotfiles-maintainer。版本、测试日志、平台、CI 与未验证范围需可追溯。保持提交聚焦，推送遵循用户授权。
