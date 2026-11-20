# 插件仓库更新

[English](repository-updates.en.md)

参考项目通过 zcomet 在启动时按时间检查插件更新。本项目默认安装清单中的固定提交；显式跟随上游后，将新提交记录为本机覆盖，后续 install/update/重装复用它。

```bash
./setup.sh repos status
./setup.sh repos plan
./setup.sh repos sync --yes
./setup.sh repos update --yes
./setup.sh repos rollback --repo fzf-tab --yes
./setup.sh repos schedule-on --yes
./setup.sh repos schedule-on --interval daily --yes
./setup.sh repos schedule-off --yes
systemctl --user list-timers dotfiles-repos.timer
journalctl --user -u dotfiles-repos.service
```

默认管理 modules/zsh-plugins/repositories.list 中的四个插件：zsh-completions、zsh-autosuggestions、fast-syntax-highlighting、fzf-tab。也读取模块的 `git-repositories.list` 与 `config/repositories.list` 通用清单。不会扫描或更新用户其他 Git 项目，也不会替用户推送代码。

插件更新默认拉取上游 HEAD，通用仓库遵循各自策略，使用镜像回退，逐个保存准确提交。脏仓库拒绝更新、回滚和删除，不 reset/force。若中途失败，已成功更新的仓库保持新版本；不是跨仓库事务。schedule-on 需要 systemd 用户管理器，默认每周，也支持 daily/monthly；登录后 Persistent 补跑。执行日志在 journal，失败摘要在 failures.tsv，下次定时执行重新尝试。未启用时不会后台联网，Shell 启动不执行下载。

## 通用清单与回滚

清单每行七列，用 `|` 分隔，支持空行与行首 `#` 注释：

```text
# 名称|公开 HTTPS URL|data 下相对目录|revision|完整 commit|policy|schedule
extra-suggestions|https://github.com/zsh-users/zsh-autosuggestions.git|repositories/extra-suggestions|v0.7.1|e52ee8ca55bcc56a17c828767a3f98f22a68d4eb|pinned|manual
```

- `pinned` 更新到锁定 commit；`head` 跟随远端默认 HEAD；`branch:main` 跟随指定分支。所有条目都必须提供首次同步的完整提交锁。
- `manual` 只手动更新；`auto` 在用户开启定时器后参与自动更新。固定版本是同步默认值，跟随上游需清单明确选择。
- 目标位于 `~/.local/share/dotfiles/` 下；拒绝重复名称、重叠目录、越界路径、符号链接目标和含凭据的 URL。
- `sync` 安装缺失克隆并同步锁定提交或本机覆盖，不部署配置。常规 Profile 安装仍由对应模块管理插件；额外清单执行显式 `repos sync`。
- `plan` 用 `ls-remote` 查看旧/新提交，不写文件，会联网；`--dry-run` 不联网、不写文件。可加 `--repo NAME` 限定一个仓库。
- 更新前保留 `refs/dotfiles/previous`，`rollback --repo NAME` 无需联网，恢复上一次提交并记录覆盖；再次回滚可切回。仅保留一个回滚点，卸载克隆后该回滚点随之删除。回滚不会删除用户修改，存在修改时拒绝执行。

覆盖提交保存在 ~/.local/state/dotfiles/repo-overrides.tsv。若要回到仓库默认提交，请先禁用定时器并审阅/备份该本地文件，再删除相应覆盖行、执行 module update zsh-plugins。

项目自身升级仍由你执行 git pull --ff-only，再运行 setup.sh update PROFILE。定时器不自动拉取或执行 dotfiles 仓库的新代码。

## 与参考项目的对应关系

参考仓库的 `shells/zsh/config.zsh` 在 Zsh 启动时检查 `.zcomet/update` 的修改时间，超过 7 天执行 `zcomet self-update`、`zcomet update` 和编译。插件声明多数带 tag 或 commit，因此自动更新不等于自动升级所有锁定版本。当前 `.gitmodules` 为空；看到的多个 Git 仓库主要来自插件管理器。

本项目已有固定提交同步、跟随上游、提交预览、离线回滚和可选定时更新实现。本地 Git 测试覆盖更新、回滚、脏仓库保护、失败不切换、清单校验和定时选择；定时器仅通过 mock 验证，尚未完成真实用户 systemd 会话验收。

## 后续实施计划

| 顺序 | 工作 | 验收条件 |
| --- | --- | --- |
| 1 | 完成现有插件更新功能验收 | 真实用户会话中验证定时执行、日志、关闭与失败重试；断网后本地插件仍能加载 |
| 2 | 通用受管仓库清单：已实现 | URL、独立目录、提交锁与分支策略；重复/越界/重叠/符号链接校验测试通过 |
| 3 | 更新预览与逐仓库回滚：已实现 | 旧/新提交、离线回滚与修改保护测试通过 |
| 4 | 自动更新策略：已实现，待真实会话验收 | 按仓库 manual/auto、统一 daily/weekly/monthly 周期、失败记录、运行锁 |

剩余验收为第 1 项的真实用户会话及真实远端异常场景。功能由 `setup.sh` 编排，不在 Shell 启动阶段执行联网更新，也不自动更新项目自身代码。
