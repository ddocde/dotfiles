# AI 协作入口 / Agent entry point

本项目对应 `ddocde/dotfiles`。先核对 remote；不要修改旁边的上游仓库。

Read [README.md](README.md) / [README.en.md](README.en.md), [CONTRIBUTING.md](CONTRIBUTING.md), and the relevant current docs.

- Shell installs tools; xdotter deploys symlinks. Keep these responsibilities separate.
- Real installation tests use only the documented Ubuntu Docker image and isolated HOME, with the repository mounted read-only. Do not install or deploy onto the host for testing.
- Preserve user configuration, private identity, credentials and unrelated Git changes.
- Keep Chinese and English user documentation consistent. Never report mocked or untested platforms as verified.
- Use focused commits. Push only when the user's current or persistent authorization covers it.

仓库维护 skill / Repository skill: [.agents/skills/dotfiles-maintainer/SKILL.md](.agents/skills/dotfiles-maintainer/SKILL.md).
