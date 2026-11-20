# 架构

[English](architecture.en.md)

setup.sh 解析命令，Profile 展开 include 与 optional，依赖解析采用稳定 DFS 排序并拒绝循环。apt 去重后批量安装，模块管理工具，xdotter 部署配置。

required 失败立即停止；optional 失败继续独立模块，依赖项和后续阶段保持 skipped，最终返回非零。卸载按逆依赖顺序，撤销链接失败不得继续删除工具或记录成功。

状态仅记录历史，doctor 检查实际命令、版本、链接和缓存。并发写操作通过内核 flock 串行化；run.flock 文件保留，不能通过删除文件解锁。进程退出后内核释放锁。

repos 命令只管理清单内的插件克隆；desktop 命令显式应用有限 GNOME 偏好。完整安装支持范围见[平台表](support-matrix.md)。
