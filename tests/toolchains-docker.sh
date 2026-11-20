#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
export HOME=/home/tester/dotfiles-acceptance
export XDG_DATA_HOME="$HOME/.local/share"
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
printf '#include <stdio.h>\nint main(void) { puts("42"); return 0; }\n' > "$fixture/main.c"
gcc -std=c11 -Wall -Wextra -Werror "$fixture/main.c" -o "$fixture/c"
[[ $("$fixture/c") == 42 ]]
printf '#include <iostream>\nint main() { std::cout << 42; }\n' > "$fixture/main.cpp"
clang++ -std=c++20 -Wall -Wextra -Werror "$fixture/main.cpp" -o "$fixture/cpp"
[[ $("$fixture/cpp") == 42 ]]
printf 'fn main() { println!("42"); }\n' > "$fixture/main.rs"
"$HOME/.cargo/bin/rustc" --edition=2021 -D warnings "$fixture/main.rs" -o "$fixture/rust"
[[ $("$fixture/rust") == 42 ]]
printf 'package main\nimport "fmt"\nfunc main() { fmt.Println(42) }\n' > "$fixture/main.go"
GOPROXY=off GOSUMDB=off "$XDG_DATA_HOME/mise/installs/go/1.25.1/bin/go" build -o "$fixture/go" "$fixture/main.go"
[[ $("$fixture/go") == 42 ]]
[[ $("$XDG_DATA_HOME/mise/installs/node/24.8.0/bin/node" -e 'console.log(42)') == 42 ]]
[[ $("$XDG_DATA_HOME/mise/installs/python/3.13.7/bin/python3" -c 'print(42)') == 42 ]]
printf 'C/C++/Rust/Go compile-and-run and Node/Python execution: passed\n'
