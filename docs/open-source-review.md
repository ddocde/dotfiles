# Open-source dotfiles comparison review

This project periodically reviews mature dotfiles managers without adopting their frameworks or copying implementation code.

## Projects reviewed

- [chezmoi](https://github.com/twpayne/chezmoi) separates source state from machine-local configuration, provides a review-before-apply workflow, and protects persistent state from concurrent operations.
- [Dotbot](https://github.com/anishathalye/dotbot) emphasizes a self-contained bootstrap, ordered tasks, dry-run support, and idempotent repeated installation.
- [yadm](https://github.com/yadm-dev/yadm) preserves conflicting local files, follows XDG paths, exposes status/introspection, and supports failure-short-circuiting hooks.

## Adopted ideas

- A read-only `setup.sh status PROFILE` command previews every xdotter deployment plan before applying it.
- Repeated installation remains idempotent; locked runtimes, npm tools, release archives, and correct symlinks are reused.
- Mutating commands use an atomic per-user state lock so package operations, downloads, deployment, and state updates cannot race each other.
- Existing files remain untouched on conflict. There is no implicit force or backup policy.
- Optional module failures continue independent work, block downstream dependents, persist across later phases, and produce a final non-zero result.
- Static CI runs syntax checks, ShellCheck, and the project test suite.

## Deliberately not adopted

- No template engine or platform-specific configuration branches: platform differences stay in installation logic and local files.
- No encrypted secret store: credentials remain outside the repository and are owned by dedicated secret managers.
- No general pre/post hook system: lifecycle behavior stays visible inside module contracts.
- No automatic cleanup of unrelated or broken links, and no forced replacement of user files.
- No migration to chezmoi, yadm, Dotbot, Stow, Nix, or Ansible; xdotter remains the sole configuration deployer.

The review influenced architecture only. No source code or configuration payload was copied from these projects.
