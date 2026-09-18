# Dependency analysis findings

The upstream deployment tool was also installed by a later tool group, creating a bootstrap cycle. Shell startup invoked multiple dynamic initializers and plugin updates. This project vendors and verifies xdotter, resolves a module DAG before mutation, and generates shell initialization only during install/update.
