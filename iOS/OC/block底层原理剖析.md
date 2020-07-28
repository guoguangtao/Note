[toc]

#### Block 捕获外部变量

##### 4种变量类型

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

    为了弄清楚这两个疑问，用 `clang` 转换成 `C++/C` 代码出来分析分析

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

##### 变量捕获 clang 代码解析

###### 1.`main` 函数
```C++
void (*block)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, &static_num, auto_num);
```
创建一个 `__main_block_impl_0` 类型的结构体，并且将 `__main_block_func_0`、`__main_block_desc_0_DATA`的地址、`static_num`变量的地址、`auto_num`的值通过 `__main_block_impl_0` 的构造方法作为参数传入进去.

```C++
// 调用 block 内部的 FuncPtr 方法
((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
```
调用 `block`，实际上是通过当前 `block` （__block_impl结构体）中的  `FuncPtr` 方法

###### 2.`__main_block_impl_0` 结构体

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

###### 3.`__main_block_func_0` 结构体

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

    `__main_block_impl_0` 中有两个属性 `static_num`、 `auto_num`，其中 `static_num` 是一个指针变量，这里将 static_num 指向 `__main_block_impl_0` 中的 `static_num`，并且使用 （`*static_num`）进行自增操作，从而修改了 `static_num` 里面的值(地址传递，可以修改指向该空间里面的值)；`auto_num` 只是一个 `int` 类型的基本数据，它只是一个值，所以很好理解，为什么 `auto_num` 在 `block` 中输出仍然是 `3`，而不是 `4`，因为一开始创建 `block` 到时候，`block` 就已经将 `4` 这个值捕获到内部结构中的 `auto_num`去了，而 `static_num` 是一个指针变量，指向了 `static_num` 所在的这块存储空间，通过这个存储空间地址从而修改了这块空间地址的值。

* `global_num` 和 `static_global_num`
    由于这两个是全局变量，作用域的原因，在 `block` 中可以直接被修改，存在全局区

    ![内存分布区](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200728201852.png)

##### 总结

全局变量、静态全局变量因为作用域的原因，都是放在全局区中，所以在 block 内部可以直接修改；
静态变量是通过地址捕获进去的，通过修改该空间的值也能直接修改；
自动变量是通过 **值传递** 进行捕获，传入进去就是一个数值，所以无法修改






