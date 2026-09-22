# 手动 Docker 验证指南

这份指南用于在一个可保留、可重复进入的 Docker 容器中，手动验证 `workstation` 的完整安装、幂等性、配置链接和 doctor。

## 安全边界

- 不要在宿主机上运行 `./setup.sh install workstation`。
- 真实安装只在项目规定的 `glcr.rd.ubtrobot.com/rosa/images/rust:ubuntu24.04` 基础镜像内执行。
- 不要为测试容器加 `--rm`；失败后需要保留容器查看日志。
- 测试使用容器内的独立 HOME，不挂载宿主机 HOME，不传入 Token、SSH 密钥或 Git 身份。
- 容器内的 `sudo` 仅作用于这个临时容器。

## 1. 准备仓库

```bash
git clone git@github.com:ddocde/dotfiles.git
cd dotfiles
git switch main
git pull --ff-only
git status --short --branch
```

如果已经有本地仓库，从 `cd dotfiles` 开始即可。`git status` 应当显示工作区干净且与 `origin/main` 同步。

## 2. 检查 Docker 和代理环境

```bash
docker version
docker info >/dev/null
env | grep -iE '^(http|https|all|no)_proxy=' || true
```

测试命令会继承已存在的大小写代理环境变量。如果宿主机的代理只监听 `127.0.0.1`，Linux 上的 `--network host` 可让容器共享宿主机网络。不需要代理时无需额外设置。

## 3. 构建验证镜像

```bash
./scripts/docker-build-test.sh
```

构建过程会在镜像内执行：

- Shell 语法检查；
- 22 项单元和 Mock 测试；
- ShellCheck。

期望结果为 `22 passed, 0 failed`，镜像名为 `dotfiles-test:local`。

```bash
docker image inspect dotfiles-test:local --format '{{.RepoTags}} {{.Id}}'
```

## 4. 创建可保留的手动测试容器

先检查同名容器：

```bash
docker ps -a --filter name=dotfiles-manual-test
```

如果同名容器是上一次测试留下的，先查看日志，确认不再需要后再删除这一个明确的容器：

```bash
docker logs --tail 200 dotfiles-manual-test
docker rm dotfiles-manual-test
```

创建新容器：

```bash
docker run --name dotfiles-manual-test -it \
  --network host \
  --env HTTP_PROXY --env HTTPS_PROXY --env ALL_PROXY \
  --env http_proxy --env https_proxy --env all_proxy \
  dotfiles-test:local bash
```

进入容器后，先设置独立目录：

```bash
set -Eeuo pipefail

verify_home=/home/tester/dotfiles-test-home
mkdir -p "$verify_home"
export HOME="$verify_home"
export XDG_CONFIG_HOME="$verify_home/.config"
export XDG_DATA_HOME="$verify_home/.local/share"
export XDG_STATE_HOME="$verify_home/.local/state"
export XDG_CACHE_HOME="$verify_home/.cache"

printf 'HOME=%s\n' "$HOME"
```

Rustup 可能提示当前 `HOME` 与容器账号的 passwd HOME 不同。在这个隔离测试中这是预期提示，只要最终 Rust 模块返回 `success` 即可。

## 5. 预览安装计划

```bash
./setup.sh plan workstation --network china
./setup.sh install workstation --yes --network china --dry-run
```

这两条命令不应安装包、下载文件或调用 `sudo`。计划中应包含 `workstation` 的全部模块，`helix` 标记为 `optional`。

## 6. 第一次完整安装

```bash
time ./setup.sh install workstation --yes --network china --verbose
```

首次安装会包含大体积 apt 包、Node/Python/Go/Rust 工具链、VS Code、WezTerm、Codex 和 Claude Code。下载速度受当前网络影响，长时间无新日志并不一定代表卡死。

在宿主机的另一个终端中可以检查：

```bash
docker stats --no-stream dotfiles-manual-test
docker exec dotfiles-manual-test sh -c \
  'ps -eo pid,etime,stat,cmd | grep -E "apt|curl|npm|mise|rustup|setup.sh" | grep -v grep'
```

判断依据：

- apt 出现 `Ign` 后又出现对应的 `Get`，通常是重试后继续下载；
- 下载字节数在增长、CPU 或网络有活动时，不要中断；
- 脚本为 apt 配置了 8 次重试和 30 秒 HTTP/HTTPS 超时；
- npm 安装 Codex/Claude 时可能数分钟无输出，它们受 600 秒超时保护；
- 真正失败会有非零退出码和 `failure` 记录。

安装结束时，required 模块应全部为 `success`，并自动完成配置部署与 doctor。

## 7. 第二次安装：验证幂等性

```bash
time ./setup.sh install workstation --yes --network china --verbose
```

期望现象：

- apt 显示 `0 newly installed`；
- mise 的 Node、Python 和 Go 显示 `already installed`；
- 固定 Release 文件显示 `verified existing download`；
- xdotter 部署项显示 `already correct`；
- 不会覆盖普通文件，不会执行 `apt autoremove`；
- 命令最终返回 0。

## 8. 独立执行 doctor

```bash
./setup.sh doctor workstation --yes --network china --verbose
```

然后补充检查关键命令：

```bash
for command_name in \
  bash git zsh starship fzf rg fdfind batcat eza jq zoxide delta gh \
  shellcheck tmux yazi ya gitui hx code wezterm navi; do
  command -v "$command_name"
done

"$HOME/.cargo/bin/rustc" --version
"$XDG_DATA_HOME/dotfiles/bin/mise" x node@24.8.0 -- node --version
"$XDG_DATA_HOME/dotfiles/bin/mise" x python@3.13.7 -- python --version
"$XDG_DATA_HOME/dotfiles/bin/mise" x go@1.25.1 -- go version
"$XDG_DATA_HOME/dotfiles/npm/bin/codex" --version
"$XDG_DATA_HOME/dotfiles/npm/bin/claude" --version
```

Codex 和 Claude Code 只检查命令及版本；测试不应登录账号或配置 API key。

## 9. 检查配置链接和状态

```bash
test -L "$HOME/.bashrc"
test -L "$HOME/.zshrc"
test -L "$XDG_CONFIG_HOME/git/config"
test -L "$XDG_CONFIG_HOME/tmux/tmux.conf"
test -L "$XDG_CONFIG_HOME/wezterm/wezterm.lua"

readlink -f "$HOME/.bashrc"
readlink -f "$XDG_CONFIG_HOME/git/config"

find "$XDG_STATE_HOME/dotfiles" -maxdepth 1 -type f -print -exec tail -n 5 {} \;
```

链接应指向容器内的 `/opt/dotfiles/modules/.../config/...`。状态文件只用于记录；最终结果以 doctor 的实际检查为准。

## 10. 验证冲突不会被覆盖

下面的检查使用另一个隔离 HOME，不影响前面的安装：

```bash
set +e
(
  conflict_home=/home/tester/dotfiles-conflict-home
  mkdir -p "$conflict_home"
  printf '%s\n' 'user-owned-content' > "$conflict_home/.bashrc"
  export HOME="$conflict_home"
  export XDG_CONFIG_HOME="$conflict_home/.config"
  export XDG_DATA_HOME="$conflict_home/.local/share"
  export XDG_STATE_HOME="$conflict_home/.local/state"
  export XDG_CACHE_HOME="$conflict_home/.cache"
  ./setup.sh module deploy bash --yes
)
conflict_rc=$?
set -e

test "$conflict_rc" -ne 0
grep -qx 'user-owned-content' /home/tester/dotfiles-conflict-home/.bashrc
printf 'conflict protection passed, rc=%s\n' "$conflict_rc"
```

预期部署返回非零，且原文件内容保持不变。

## 11. 退出、重新进入与查看日志

容器内执行：

```bash
exit
```

宿主机检查容器状态：

```bash
docker ps -a --filter name=dotfiles-manual-test
docker inspect dotfiles-manual-test \
  --format 'status={{.State.Status}} exit={{.State.ExitCode}}'
docker logs --tail 200 dotfiles-manual-test
```

因为容器的主命令是 Bash，可以重新进入，文件仍会保留：

```bash
docker start -ai dotfiles-manual-test
```

重新进入后如需继续执行 `setup.sh`，重新执行第 4 步中的 HOME/XDG `export` 即可。

## 12. 清理

确认不再需要日志和现场后，只删除这个明确命名的测试容器：

```bash
docker rm dotfiles-manual-test
```

如果容器仍在运行，先回到容器执行 `exit`，不要对不明确的容器或镜像执行批量删除。

## 通过标准

同时满足以下条件即可认为手动验证通过：

- Docker 构建中 22 项测试和 ShellCheck 通过；
- `workstation` 首次安装返回 0；
- 第二次安装返回 0，且已有配置均为 `already correct`；
- 独立 doctor 返回 0；
- 关键命令、语言运行时和 AI CLI 可执行；
- xdotter 链接指向正确；
- 已有普通文件的冲突测试被拒绝，内容未被覆盖；
- 没有运行 `apt autoremove`，没有写入任何凭据或私有身份。
