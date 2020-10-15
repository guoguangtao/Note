[toc]

### CocoaPods 介绍

`CocoaPods` 是开发 `OS X` 和 `iOS` 应用程序的一个第三方库的依赖管理工具。利用 `CocoaPods`，可以定义自己的依赖关系（称作 `pods`），并且随着时间的变化，以及在整个开发环境中对第三方库的版本管理非常方便。

在工程中引入第三方代码会涉及到许多内容，工程文件的配置会让人很沮丧，在配置 `build phases` 和 `linker flags` 过程中，会引起许多错误。`CocoaPods` 简化了这些操作，能够自动配置编译选项，通过 `CocoaPods` 可以很方便的查找到第三方库。

### Pod 命令

在安装成功 `CocoaPods` 的前提下，在终端输入 `pod` 获取到 `CocoaPods` 的一些指令。

```shell
    $ pod COMMAND

      CocoaPods, the Cocoa library package manager.

Commands:

    + cache         Manipulate the CocoaPods cache(操作 CocoaPods 的缓存)
    + deintegrate   Deintegrate CocoaPods from your project(从项目中解集成 CocoaPods)
    + env           Display pod environment(显示 pod 环境)
    + init          Generate a Podfile for the current directory(在当前目录生成一个 Podfile 文件，当前目录必须有一个 Xcode project)
    + install       Install project dependencies according to versions from a
                    Podfile.lock （根据 Podfile.lock 中存在的第三方框架版本安装第三方框架）
    + ipc           Inter-process communication （进程间通信）
    + lib           Develop pods
    + list          List pods
    + outdated      Show outdated project dependencies(显示过时的第三方框架)
    + plugins       Show available CocoaPods plugins(显示可用的 CocoaPods 插件)
    + repo          Manage spec-repositories（管理）
    + search        Search for pods
    + setup         Setup the CocoaPods environment
    + spec          Manage pod specs
    + trunk         Interact with the CocoaPods API (e.g. publishing new specs)
    + try           Try a Pod!
    + update        Update outdated project dependencies and create new Podfile.lock

Options:

    --silent        Show nothing
    --version       Show the version of the tool
    --verbose       Show more debugging information
    --no-ansi       Show output without ANSI codes
    --help          Show help banner of specified command
```