# Profile

[English](profiles.en.md)

profiles/*.list 是按顺序读取的文本；空行和 # 注释被忽略，@include developer 包含其他清单。工具名为 required，?工具名为 optional。重复项去重并保持首次顺序，任何 required 声明优先于 optional。

--enable MODULE 将工具作为 required 加入，--disable MODULE 移除直接选择；仍被其他工具依赖时会自动补回。注释不会卸载已有工具。修改后先执行 ./setup.sh plan workstation 检查最终依赖。
