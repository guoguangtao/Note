[toc]

# `Runtime` 的介绍与使用

## 1. `Runtime` 简介

`Runtime` 在 `OC` 中又称为 `运行时`.它是一套底层的 `C` 语言 `API`,是 `iOS` 系统的核心之一.开发者在编码过程中,可以给任意一个对象发送消息,在编译阶段只要是确定了要向接受者发送这条消息,而接受者将要如何响应和处理这条消息,就要运行时来决定了.所以 `OC` 是一门动态语言.

`C`语言中,在编译期间,函数的调用就会决定调用哪个函数.而 `OC` 的函数调用,属于动态调用,在编译期间并不能决定真正调用哪个函数,只有在真正运行的时候才会根据函数的名称找到对应的函数来调用.当然,也有可能发生`方法交换`,`消息转发`情况.

`OC` 是一门动态语言,这意味着它不仅需要一个编译器,也需要一个运行时系统来动态创建类、对象、消息传递和转发.

`OC` 在三种层面上与 `Runtime` 系统进行交互:

![OC 与 Runtime](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200829104645.png)

## 2. 在工程中使用 `Runtime`

关于 `Runtime`函数可以直接查看官方文档 [Runtime 函数详细文档](https://developer.apple.com/documentation/objectivec/objective-c_runtime?language=objc)

在导入 `objc/runtime.h` 和 `objc/message.h` 两个头文件的时候,有时候希望使用消息发送函数,但是没有代码提示.

![Runtime没有代码提示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/Runtime%E6%B2%A1%E6%9C%89%E4%BB%A3%E7%A0%81%E6%8F%90%E7%A4%BA.gif)

这时候需要去工程设置一下,将以下的配置值修改成 `NO`.

![Runtime 代码提示工程设置](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200829105935.png)

![Runtime设置后有代码提示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/Runtime%E8%AE%BE%E7%BD%AE%E5%90%8E%E6%9C%89%E4%BB%A3%E7%A0%81%E6%8F%90%E7%A4%BA.gif)

这样设置之后,就有代码提示了.

## 3.