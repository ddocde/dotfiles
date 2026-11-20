# WezTerm

[简体中文](README.md)

The current laptop preferences are preserved: Gruvbox Material colors, 16.5 font size, 0.8 opacity, 165 FPS, bottom tabs, login Zsh, three/four-pane layouts and Alt+h/j/k/l navigation. Ctrl+Shift+P opens the command palette, Ctrl+Shift+R reloads configuration, Super+F toggles fullscreen, and F20/F21 emit layout events.

Dependencies include Zsh and fonts. The fonts module installs SHA256-verified FiraCode Nerd Font 3.4.0 with Fira Code fallback. Doctor checks font matching and configuration parsing; final rendering needs a live desktop session.

xdotter links ~/.config/wezterm/wezterm.lua into this module. Editing the repository does not switch the current host's old symlink. Preview with module status wezterm before migrating existing files. Install with module install wezterm --yes, or use workstation.
