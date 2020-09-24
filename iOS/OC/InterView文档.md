[toc]

1. 一个 `NSObject` 对象占用多少内存?

> 一个 `NSObject` 对象,系统分配了 16 个字节给 `NSObject` 对象 (可以通过 malloc_size 函数获得)
> 但是 `NSObject` 对象内部只使用了 8 个字节的空间(64 位环境下,可以通过 `class_getInstanceSize` 函数获得)
> 可以查看源码,在通过获取到实际需要字节空间大小之后,如果小于 16 个字节,系统默认分配 16 个字节空间

2. 对象的 `isa` 指针指向哪里?

> * 实例对象(`instance` 对象)的 `isa` 指针指向类(`class`)对象
> * 类(`class`)对象的 `isa` 指针指向元类(`meta-class`)对象
> * 元类(`meta-class`)对象的 `isa` 指针指向基类的 `meta-class` 对象,而基类的 `meta-class` 对象的 `isa` 指针指向自己

![isa_superClass关系图](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/isa_superClass%E5%85%B3%E7%B3%BB%E5%9B%BE.png)

3. OC 的类信息存放在哪里?

> * 对象方法、属性、成员变量、协议信息,存放在 类对象中
> * 类方法存放在元类对象中
> * 成员变量的具体指存放在实例对象中

4. KVO 的本质是什么

> 1. 利用 `Runtime API` 动态生成一个子类,并且让实例对象的 `isa` 指针指向这个全新的子类
> 2. 当修改实例对象的属性时,会调用 `Fundation` 的 `_NSSetXXXValueAndNotify` 函数
    * `willChangeValueForKey:`
    * 父类原来的 `setter` 方法
    * `didChangeValueForKey:`
> 3. 内部会出发监听器(`Oberser`)的监听方法 (`observeValueForKeyPath:ofObject:change:context`)
> 4. 手动触发 KVO 
    * 手动调用 `willChangeValueForKey:` 和 `didChangeValueForKey:` 方法
> 5. 直接修改成员变量并不会触发 KVO 

5. 版本号的含义

> 比如 2.3.0
> * 第一位: 表示大版本变化,如果经过一个大版本就加 1,如果是 SDK,则意味着可能之前的一些方法名发生了改变,在新的版本受影响
> * 第二位: 表示一些小的改动,如果是 SDK 则意味着增加了一个功能,方法名没有改动过,不影响之前的使用
> * 第三位: 表示对一些 BUG 的修复

6. CocoaPods 的理解?

7. CocoaPods 中的 pod install 和 pod update 的区别?

8. KVC?

9. 消息机制?

10. NSRunLoop? NSRunLoop 的组成?

11. 如何查找项目中使用到了 UIWebView?

12. WKWebView 与 H5 交互到底做了什么事情?

13. emoji 表情的截取?

14. Socket 如果发送过长的文本需要做什么处理?

15. 如何查找 ViewA 和 ViewB 两个视图第一个共同的父视图?

16. 事件响应链?

17. iOS 多线程?

18. block 为什么 __strong 能延迟释放?

19. block 的循环引用? 为什么 __weak 就能避免循环引用,做了什么?