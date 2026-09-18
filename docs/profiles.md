# Profiles

Profiles live in `profiles/*.list`. Blank lines and `#` comments are ignored. `@include developer` expands another profile, `module` is required, and `?module` is optional. Expansion preserves first occurrence order. Include and dependency cycles are errors.

`--enable MODULE` appends a module; `--disable MODULE` removes a selected module. Dependencies can still reintroduce a disabled module when another selected module requires it: disable its consumer too.
