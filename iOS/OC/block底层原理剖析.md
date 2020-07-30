[toc]

# Block 捕获外部变量

## 4种变量类型

* 自动变量
* 静态变量
* 静态全局变量
* 全局变量

```Objective-C
int global_num = 1; // 全局变量
static int static_global_num = 2; // 静态全局变量

int main(int argc, const char * argv[]) {
        
    int auto_num = 3; // 自动变量
    static int static_num = 4; // 静态变量
    
    void (^block)(void) = ^{
        global_num++;
        static_global_num++;
        // auto_num++; // 自动变量，如果没有加上 __block 是无法修改变量值的，
        static_num++;
        NSLog(@"Block内 global_num = %d, static_global_num = %d, auto_num = %d, static_num = %d", global_num, static_global_num, auto_num, static_num);
    };
    
    global_num++;
    static_global_num++;
    auto_num++;
    static_num++;
    
    NSLog(@"Block外 global_num = %d, static_global_num = %d, auto_num = %d, static_num = %d", global_num, static_global_num, auto_num, static_num);
    
    block();
    
    return 0;
}
```

输出结果

```objective-c
2020-07-28 14:32:34.706529+0800 Block[26862:304493] Block外 global_num = 2, static_global_num = 3, auto_num = 4, static_num = 5
2020-07-28 14:32:34.707679+0800 Block[26862:304493] Block内 global_num = 3, static_global_num = 4, auto_num = 3, static_num = 6
Program ended with exit code: 0
```

在 `block` 里面输出的值，除了自动变量，其他变量的值都发生了改变，即使自动变量（`auto_num`）在 `block` 外面经过 `++` ，但是在 `block` 里面值还是没有发生改变，而且在 `block` 中为什么不能对自动变量进行 `++` 操作（除非使用 `__block`）

为了弄清楚这两个疑问，用 `clang` 转换成 `C++/C` 代码出来分析

```
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc 文件名
```

`C++/C` 代码经过整理如下：

```C++
int global_num = 1;
static int static_global_num = 2;

/// Block 的基本结构
struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};

/// block结构
struct __main_block_impl_0 {
    struct __block_impl impl; // block 基本结构
    struct __main_block_desc_0* Desc;
    int *static_num; // 静态变量，这里是一个指针变量
    int auto_num; // 自动变量
    /// 构造方法
    ///
    /// @param fp Block方法的实现 （将__main_block_func_0传入 impl的FuncPtr）
    /// @param desc __main_block_desc_0 （将 __main_block_desc_0_DATA 传入 desc）
    /// @param _static_num 静态变量地址值 （将外部静态变量 _static_num 的地址传入 static_num）
    /// @param _auto_num 自动变量值（这里是值，不是地址值）
    /// @param flags
    __main_block_impl_0(void *fp,
                        struct __main_block_desc_0 *desc,
                        int *_static_num,
                        int _auto_num,
                        int flags=0) : static_num(_static_num), auto_num(_auto_num) {
        impl.isa = &_NSConcreteStackBlock; // block 基本机构isa 类型
        impl.Flags = flags;
        impl.FuncPtr = fp; // 函数指针，block实现方法，调用block实际上是通过调用 funcPtr 函数
        Desc = desc;
    }
};

/// block 方法内部的实现
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    int *static_num = __cself->static_num; // bound by copy
    int auto_num = __cself->auto_num; // bound by copy
    // 全局变量的自增运算
    global_num++;
    // 静态全局变量的自增运算
    static_global_num++;
    // 静态变量的自增运算
    (*static_num)++;
    // OC 代码输出
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_12374b_mi_0, global_num, static_global_num, auto_num, (*static_num));
}        

/// __main_block_impl_0 结构体中的 Desc 数据结构体
static struct __main_block_desc_0 {
size_t reserved;
size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};


/// Main 函数入口
int main(int argc, const char * argv[]) {

    int auto_num = 3;
    static int static_num = 4;
    
    // block的创建，一个 __main_block_impl_0 的结构体，初始化传入了 __main_block_func_0、&__main_block_desc_0_DATA、&static_num、auto_num 这些参数进去
    void (*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, &static_num, auto_num);
    // block 外全局变量的自增运算
    global_num++;
    // block 外静态全局变量的自增运算
    static_global_num++;
    // block 外自动变量的自增运算
    auto_num++;
    // block 外静态变量的自增运算
    static_num++;
    // block 外输出
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_12374b_mi_1, global_num, static_global_num, auto_num, static_num);
    // 调用 block 内部的 FuncPtr 方法
    ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

    return 0;
}   
```

### 变量捕获 clang 代码解析

#### 1.`main` 函数
```C++
void (*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, &static_num, auto_num);
```
创建一个 `__main_block_impl_0` 类型的结构体，并且将 `__main_block_func_0`、`__main_block_desc_0_DATA`的地址、`static_num`变量的地址、`auto_num`的值通过 `__main_block_impl_0` 的构造方法作为参数传入进去.

```C++
// 调用 block 内部的 FuncPtr 方法
((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
```
调用 `block`，实际上是通过当前 `block` （__block_impl结构体）中的  `FuncPtr` 方法

#### 2.`__main_block_impl_0` 结构体

```C++
/// block结构
struct __main_block_impl_0 {
    struct __block_impl impl; // block 基本结构
    struct __main_block_desc_0* Desc;
    int *static_num; // 静态变量，这里是一个指针变量
    int auto_num; // 自动变量
    /// 构造方法
    ///
    /// @param fp Block方法的实现 （将__main_block_func_0传入 impl的FuncPtr）
    /// @param desc __main_block_desc_0 （将 __main_block_desc_0_DATA 传入 desc）
    /// @param _static_num 静态变量地址值 （将外部静态变量 _static_num 的地址传入 static_num）
    /// @param _auto_num 自动变量值（这里是值，不是地址值）
    /// @param flags
    __main_block_impl_0(void *fp,
                        struct __main_block_desc_0 *desc,
                        int *_static_num,
                        int _auto_num,
                        int flags=0) : static_num(_static_num), auto_num(_auto_num) {
        impl.isa = &_NSConcreteStackBlock; // block 基本机构isa 类型
        impl.Flags = flags;
        impl.FuncPtr = fp; // 函数指针，block实现方法，调用block实际上是通过调用 funcPtr 函数
        Desc = desc;
    }
};
```
通过构造方法（跟结构体同名的方法）将传入的 `*fp`(方法地址)赋值给了 `impl.FuncPtr`,在 `main` 函数中调用 `block` 时，就是通过 调用 `impl.Funcptr` 的方式.

#### 3.`__main_block_func_0` 结构体

```C++
/// block 方法内部的实现
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    int *static_num = __cself->static_num; // bound by copy
    int auto_num = __cself->auto_num; // bound by copy
    // 全局变量的自增运算
    global_num++;
    // 静态全局变量的自增运算
    static_global_num++;
    // 静态变量的自增运算
    (*static_num)++;
    // OC 代码输出
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_12374b_mi_0, global_num, static_global_num, auto_num, (*static_num));
} 
```

这段代码就是 block 方法实现转成 C++/C 之后的代码，重点分析这块代码

* `__cself`
    在`main`函数中，通过 `block->FuncPtr()` 调用 block 里面的方法，从 `__main_block_impl_0` 这个结构体第一个属性是  `struct __block_impl impl`, 根据结构体的内存分布原理，这里使用 `__cself` 实际上是通过 `impl` 调用 `FuncPtr` 方法。

* `__cself->static_num` 和 `__cself->auto_num`

    `__main_block_impl_0` 中有两个属性 `static_num`、 `auto_num`，其中 `static_num` 是一个指针变量，这里将 static_num 指向 `__main_block_impl_0` 中的 `static_num`，并且使用 （`*static_num`）进行自增操作，从而修改了 `static_num` 里面的值(地址传递，可以修改指向该空间里面的值)；`auto_num` 只是一个 `int` 类型的基本数据，它只是一个值，所以很好理解，为什么 `auto_num` 在 `block` 中输出仍然是 `3`，而不是 `4`，因为一开始创建 `block` 到时候，`block` 就已经将 `3` 这个值捕获到内部结构中的 `auto_num`去了，而 `static_num` 是一个指针变量，指向了 `static_num` 所在的这块存储空间，通过这个存储空间地址从而修改了这块空间地址的值。

* `global_num` 和 `static_global_num`
    由于这两个是全局变量，作用域的原因，在 `block` 中可以直接被修改，存在全局区

    ![内存分布区](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200728201852.png)

## `Block` 改变变量的 2 种方式
### 1.传递内存地址指针到 `Block` 中

```Objective-c
int main(int argc, const char * argv[]) {
    
    NSMutableString *mutableString = [NSMutableString stringWithString:@"Block内存地址传递（地址捕获）"];
    void (^block)(void) = ^{
        [mutableString appendString:@", Block根据内存地址传递修改指向该内存地址空间的值"];
        NSLog(@"block 内 :%@, 内存地址:%p", mutableString, mutableString);
    };
    NSLog(@"block 前 :%@, 内存地址:%p", mutableString, mutableString);
    block();
    NSLog(@"block 后 :%@, 内存地址:%p", mutableString, mutableString);
}
```

输出结果

![传递内存地址到Block中修改变量](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200729100302.png)

经过 `clang` 代码转换

```C++
/// block的结构
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    NSMutableString *mutableString; // 捕获外部变量的指针变量
    
    /*
    * __main_block_impl_0 的构造方法
    * @param fp Block实现方法指针，在这里是 __main_block_func_0 方法
    * @param desc block描述，在这里是 __main_block_desc_0_DATA（__main_block_desc_0 类型的结构体）
    * @param _mutableString block捕获外部变量的字符串
    * @param flags 默认值为0，此处传入的是 570425344
    */
    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, NSMutableString *_mutableString, int flags=0) : mutableString(_mutableString) {
        impl.isa = &_NSConcreteStackBlock; // block的类型，
        impl.Flags = flags;
        impl.FuncPtr = fp; // block的实现方法
        Desc = desc;
    }
};

/// block的实现方法
/// @param __cself 当前block对象
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    // 根据内存分配的原理，block最开始的地址就是内部第一个变量的地址，也就是 __cself 的地址同时也是内部变量 impl 的地址，所以这里直接使用 __cself 取得 mutableString
    NSMutableString *mutableString = __cself->mutableString; // bound by copy
    // 对可变字符串进行字符串拼接
    objc_msgSend(mutableString, sel_registerName("appendString:"), &__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_b8880d_mi_1);
    // 输出
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_b8880d_mi_2, mutableString, mutableString);
}

/// Block copy方法
/// @param dst
/// @param src
static void __main_block_copy_0(struct __main_block_impl_0* dst, struct __main_block_impl_0* src) {
    // 系统自己调用，不需要自己调用，在这里看情况是否需要进行引数计数器+1
    _Block_object_assign((void*)&dst->mutableString, (void*)src->mutableString, 3/*BLOCK_FIELD_IS_OBJECT*/);
}

/// Block的释放方法（析构方法）
/// @param src block
static void __main_block_dispose_0(struct __main_block_impl_0*src) {
    _Block_object_dispose((void*)src->mutableString, 3/*BLOCK_FIELD_IS_OBJECT*/);
}

/// 描述
static struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
    void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};

int main(int argc, const char * argv[]) {
    
    // 创建一个可变字符串
    NSMutableString *mutableString = objc_msgSend(objc_getClass("NSMutableString"), sel_registerName("stringWithString:"), &__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_b8880d_mi_0);
    // block 的底层实现方式 __main_block_impl_0 类型
    void (*block)(void) = ((void (*)())&__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, mutableString, 570425344));
    // 输出日志
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_b8880d_mi_3, mutableString, mutableString);
    // 调用Block的实现方法，将当前 block 作为参数传入到 __main_block_func_0 静态方法中
    ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
    // 输出日志
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_b8880d_mi_4, mutableString, mutableString);
}
```
在这里相比之前 `clang` 的代码，会发现多了两个方法 `__main_block_copy_0` 、`__main_block_dispose_0`,这两个方法都被传入到了 `__main_block_desc_0` 这样的结构体中。关于 `__main_block_copy_0` 和 `__main_block_dispose_0` 在后面讲解。

### 2.改变存储区方式(`__block` 方式)

研究 __block 从以下两点进行研究
1. **普通非对象变量(基本数据类型)**
2. **对象变量**

#### 2.1 普通非对象变量(基本数据类型)

```Objective-c
int main(int argc, const char * argv[]) {
    
    __block int auto_num = 1;
    NSLog(@"auto_num 初始值 %d, auto_num 的初始内存地址为:%p", auto_num, &auto_num);
    
    void (^myBlock)(void) = ^{
        auto_num++;
        NSLog(@"Block 内 auto_num = %d, auto_num 的内存地址为:%p", auto_num, &auto_num);
    };
    
    auto_num++;
    NSLog(@"Block 外 auto_num = %d, auto_num 的内存地址为:%p", auto_num, &auto_num);
    myBlock();
}
```

输出结果:

```Objective-c
2020-07-29 14:01:05.941034+0800 Block[85215:1119239] auto_num 初始值 1, auto_num 的初始内存地址为:0x7ffeefbff5a8
2020-07-29 14:01:05.941859+0800 Block[85215:1119239] Block 外 auto_num = 2, auto_num 的内存地址为:0x10060c8f8
2020-07-29 14:01:05.941962+0800 Block[85215:1119239] Block 内 auto_num = 3, auto_num 的内存地址为:0x10060c8f8
Program ended with exit code: 0
```

经过   `clang` 代码如下:

```C++
/// 外部普通非对象变量在底层实现的结构
struct __Block_byref_auto_num_0 {
    void *__isa; // isa 指针
    __Block_byref_auto_num_0 *__forwarding; // 一个指向自己本身的指针变量
    int __flags; // 标记flag
    int __size; // 大小
    int auto_num; // 变量值,跟外部普通非对象变量名同名
};

/// block 底层结构
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    __Block_byref_auto_num_0 *auto_num; // by ref
    /// 将 传入的 auto_num 的 __forwarding 赋值给 auto_num 指针变量
    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_auto_num_0 *_auto_num, int flags=0) : auto_num(_auto_num->__forwarding) {
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    // 拿到 __Block_byref_auto_num_0 类型的 auto_num 变量
    __Block_byref_auto_num_0 *auto_num = __cself->auto_num; // bound by ref
    // 自增运算,使用的__forwarding去获取auto_num这个值
    (auto_num->__forwarding->auto_num)++;
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_89b0e5_mi_1, (auto_num->__forwarding->auto_num), &(auto_num->__forwarding->auto_num));
}
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {
    _Block_object_assign((void*)&dst->auto_num, (void*)src->auto_num, 8/*BLOCK_FIELD_IS_BYREF*/);
}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {
    _Block_object_dispose((void*)src->auto_num, 8/*BLOCK_FIELD_IS_BYREF*/);
}

static struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
    void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};

int main(int argc, const char * argv[]) {
    // __block int auto_num = 1 转换成了一个 __Block_byref_auto_num_0 类型的结构体( C++ 中也可以称为对象),并且将 auto_num 的值传入到 auto_num 中,本身的地址传入到 __forwarding 指针变量
    __attribute__((__blocks__(byref))) __Block_byref_auto_num_0 auto_num = {(void*)0,(__Block_byref_auto_num_0 *)&auto_num, 0, sizeof(__Block_byref_auto_num_0), 1};
    // 输出还未创建 block 是 auto_num 的值和内存地址,都是通过 __forwarding 这个指针变量去取的
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_89b0e5_mi_0, (auto_num.__forwarding->auto_num), &(auto_num.__forwarding->auto_num));
    // 创建 block,这里 auto_num 传入进去的是一个地址值,也就是 auto_num 指向的内存空间的地址值
    void (*myBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_auto_num_0 *)&auto_num, 570425344));
    // auto_num 自增运算
    (auto_num.__forwarding->auto_num)++;
    // 输出 auto_num 变量
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_6l_fbpz14xx3y9cm2rh9591kd740000gn_T_main_89b0e5_mi_2, (auto_num.__forwarding->auto_num), &(auto_num.__forwarding->auto_num));
    // 调用 block
    ((void (*)(__block_impl *))((__block_impl *)myBlock)->FuncPtr)((__block_impl *)myBlock);
}
```

从上面转换的代码中,可以看到 `__block` 修饰的 `auto_num` 变量被转换成了一个 `__Block_byref_auto_num_0` 类型的结构体,这个结构体里面有 `5` 个成员变量

```C++
struct __Block_byref_auto_num_0 {
    void *__isa; // isa 指针
    __Block_byref_auto_num_0 *__forwarding; // 一个指向自己本身的指针变量
    int __flags; // 标记flag
    int __size; // 大小
    int auto_num; // 变量值,跟外部普通非对象变量名同名
};
```

从转换出来代码中,可以看到对 `auto_num` 进行修改都是通过 `__forwarding` 这个指针变量去获取到 `auto_num` 变量值,而不是直接通过 `__Block_byref_auto_num_0` 这个类型直接获取到 `auto_num` 这个变量值.

**为什么要这么操作呢?**

##### 2.1.1 `__forwarding` 指针

提出疑问:
1. 为什么要通过 `__forwarding` 这样的一个指针变量去获取变量值
2. 初始化时传入的是自己的地址,是不是 `__fowarding` 这个指针在后期会发生改变,所以才使用 `__forwarding` 去获取到变量值

为了研究这个 `__forwarding` 指针变量,特意在创建 `__block` 之后打印了 `__block` 变量的初始内存地址,结果发现创建`Block` 之后, `__block` 变量内存地址值跟初始内存地址不一样.

> 一开始 `__block auto_num` 的内存地址是 `0x7ffeefbff5a8`
> 创建 `Block` 之后 `__block auto_num` 的内存地址变成了 `0x10060c8f8`
> 猜想:一开始创建的 `__block auto_num` 变量是存储到**栈区**的,经过`Block`的捕获到了**堆区**,因为在这里发现初始地址比较大(高地址为栈区,低地址为堆区)

为了验证这个问题,将 `main.m` 文件设置成 `MRC` 环境编译(`target` -> `Build Phases` -> `Compile Sources` -> 对应的文件设置 `compile Flags` 为 `-fno-objc-arc`)

```Objective-c
int main(int argc, const char * argv[]) {
    // MRC 环境运行
    // 设置一个 __block 自动变量
    __block int auto_num = 1;
    // 输出初始化时 auto_num 的内存地址
    NSLog(@"auto_num 初始值 %d, auto_num 的初始内存地址为:%p", auto_num, &auto_num);
    // 创建一个 myBlock ,此时的 myBlock 应该是在栈上的
    void (^myBlock)(NSString *string) = ^(NSString *string) {
        auto_num++;
        NSLog(@"Block 内 %@ auto_num = %d, auto_num 的内存地址为:%p", string, auto_num, &auto_num);
    };
    // auto_num 自增运算
    auto_num++;
    // myBlock 没有经过 copy 操作是,调用 myBlock 方法,输出 auto_num 的值和内存地址
    myBlock(@"myBlock 未经过 copy 操作");
    
    NSLog(@"------ Copy 操作 ------");
    // 将 myBlock 经过 copy 操作,赋值给 copyBlock,此时 myBlock 还是在栈区上,而 copyBlock 是在堆区上
    void (^copyBlock)(NSString *string) = [myBlock copy];
    // myBlock 经过 copy 操作是,调用 myBlock 方法,输出 auto_num 的值和内存地址
    myBlock(@"myBlock 经过 copy 操作");
    // 调用 copyBlock
    copyBlock(@"copyBlock");
    // 打印 myBlock 和 copyBlock 类型
    NSLog(@"myBlock = %@, copyBlock = %@", myBlock, copyBlock);
    
    return 0;
}
```
输出结果
```Objective-C
Block[90411:1232567] auto_num 初始值 1, auto_num 的初始内存地址为:0x7ffeefbff5a8
Block[90411:1232567] Block 内 myBlock 未经过 copy 操作 auto_num = 3, auto_num 的内存地址为:0x7ffeefbff5a8
Block[90411:1232567] ------ Copy 操作 ------
Block[90411:1232567] Block 内 myBlock 经过 copy 操作 auto_num = 4, auto_num 的内存地址为:0x100509538
Block[90411:1232567] Block 内 copyBlock auto_num = 5, auto_num 的内存地址为:0x100509538
Block[90411:1232567] myBlock = <__NSStackBlock__: 0x7ffeefbff550>, copyBlock = <__NSMallocBlock__: 0x1005094f0>
Program ended with exit code: 0
```
> 经过打印输出发现 `myBlock` 始终在 **栈区** ,经过 `copy` 操作的 `copyBlock` 则是在 **堆区**
> `myBlock` 未经过 `copy` 操作时 `auto_num` 的内存地址跟初始值的内存地址一致,没有发生改变;经过 `copy` 操作之后,再次调用 `myBlock` 发现 `auto_num` 的地址已经发生了改变而且跟 `copyBlock` 的地址相差 **72**,所以猜测此时的 `auto_num` 已经经过 `copy` 复制到**堆区**上了,`myBlock`中的 `auto_num` 中的 `__forwarding` 这时候指向了堆区上的存储空间,所以导致 `auto_num` 本身的内存地址值和 `__forwarding` 指向的存储空间不一致.

下面来证实一下上面的猜想:

```Objective-C
/// block 的基本结构
struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};
/// __block 修饰的 auto_num 变量结构
struct __Block_byref_auto_num_0 {
    void *__isa;
    struct __Block_byref_auto_num_0 *__forwarding;
    int __flags;
    int __size;
    int auto_num;
};
/// block 中的 Desc 结构
struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    void (*copy)(void);
    void (*dispose)(void);
};
/// block 的结构
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    struct __Block_byref_auto_num_0 *auto_num; // by ref
};

int main(int argc, const char * argv[]) {
    
    // 设置一个 __block 自动变量
    __block int auto_num = 1;
    // 输出初始化时 auto_num 的内存地址
    NSLog(@"auto_num 初始值 %d, auto_num 的初始内存地址为:%p", auto_num, &auto_num);
    // 创建一个 myBlock ,此时的 myBlock 应该是在栈上的
    void (^myBlock)(NSString *string) = ^(NSString *string) {
        auto_num++;
        NSLog(@"Block 内 %@ auto_num = %d, auto_num 的内存地址为:%p", string, auto_num, &auto_num);
    };
    // auto_num 自增运算
    auto_num++;
    // myBlock 没有经过 copy 操作是,调用 myBlock 方法,输出 auto_num 的值和内存地址
    myBlock(@"myBlock 未经过 copy 操作");
    // 将未经过 copy 操作的 myBlock 赋值给 __main_block_impl_0 类型的结构体,查看数据结构
    struct __main_block_impl_0 *noCopyMyBlock = (__bridge struct __main_block_impl_0 *)myBlock;
    
    NSLog(@"------ Copy 操作 ------");
    // 将 myBlock 经过 copy 操作,赋值给 copyBlock,此时 myBlock 还是在栈区上,而 copyBlock 是在堆区上
    void (^copyBlock)(NSString *string) = [myBlock copy];
    // myBlock 经过 copy 操作是,调用 myBlock 方法,输出 auto_num 的值和内存地址
    myBlock(@"myBlock 经过 copy 操作");
    // 调用 copyBlock
    copyBlock(@"copyBlock");
    // 打印 myBlock 和 copyBlock 类型
    NSLog(@"myBlock = %@, copyBlock = %@", myBlock, copyBlock);
    // 将经过 copy 操作的 myBlock 赋值给 __main_block_impl_0 类型的结构体,查看数据结构
    struct __main_block_impl_0 *myBlockImpl = (__bridge struct __main_block_impl_0 *)myBlock;
    // 将经过 copy 操作的所得的 copyBlock 赋值给 __main_block_impl_0 类型的结构体,查看数据结构
    struct __main_block_impl_0 *copyBlockImpl = (__bridge struct __main_block_impl_0 *)copyBlock;
    
    NSLog(@"%s", __func__);
    
    return 0;
}
```

![未经过Copy查看结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200729224627.png)

![经过 copy 操作的myBlock结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200729225055.png)

![经过copy操作得到的copyBlock结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200729225154.png)

经过断点调试,查看 `noCopyMyBlock` `myBlockImpl` `copyBlockImpl` 这三个结构体变化:

1. 在 `myBlock` 还未经过 `copy` 操作的时候,转化成 `__main_block_impl_0` 的结构体 `noCopyMyBlock`,会发现此时的 `noCopyMyBlock` 中的 `auto_num` 指针变量中的 `__forwarding` 指针变量指向的是自己本身的地址空间
2. 经过 `copy` 之后, `myBlock` 转化成 `myBlockImpl` ,发现 `auto_num` 指针变量的地址没有发生改变,但是其 `__forwarding` 已经指向了 **堆区** 上的一块空间了.
3. `myBlock` 经过 `copy` 操作,重新得到了一个 `copyBlockImpl`,其 `auto_num` 变量的地址值就是 `myBlockImpl` 中 `__forwarding` 所指向的那块内存空间.

通过以上代码,证实了刚才的猜想,**栈区**上的 `myBlock` 经过 `copy` 操作后,复制到了 **堆区** 上,这时候 **堆区** 上的 `copyBlock` 重新分配了内存空间,并且**栈区**上的 `myBlock` 中的 `__forwarding` 指针变量指向了`copyBlock`中的 `auto_num` 这块内存空间.

接下来,说说 **为什么要使用 __forwarding 这个去取值,而不是直接使用 auto_num 去取值呢**,我的看法是:

> 一开始 `myBlock` 是分配在 **栈** 上的,经过 **copy** 操作后,在 **堆** 上重新分配了一块内存空间得到一个新的 `copyBlock`, 深拷贝行为,这样就算 `myBlock` 释放了, 也不会影响到 `copyBlock`,**栈** 因为作用域的问题,出了作用域就会被释放,而 **堆** 则需程序员自己管理(ARC不用程序员手动管理内存,是因为编译器会自动插入对应的内存管理代码),如果 `myBlock` 和 `copyBlock` 都是指向自己本身,那么修改 `auto_num` 变量值,只会修改其中一个,而不会同时修改另外一个,因为这两个 `block` 已经不再是同一个对象了,所以就很好理解 **为什么 `myBlock` 和 `copyBlock` 为什么 __forwarding 要同时指向一块内存空间**,同时也能理解为什么要使用 **`__forwarding` 这样一个指针变量去取值了**

#### 2.2 对象变量



## 总结

全局变量、静态全局变量因为作用域的原因，都是放在全局区中，所以在 block 内部可以直接修改；
静态变量是通过地址捕获进去的，通过修改该空间的值也能直接修改；
自动变量是通过 **值传递** 进行捕获，传入进去就是一个数值，所以无法修改







