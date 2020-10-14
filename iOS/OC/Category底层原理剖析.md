[toc]

`Category` 主要作用是在不改变原有类的基础上，动态的给已存在的类添加一些方法和属性。

分类(`Category`)在编译之后的底层结构是 `struct category_t`，里面存储着当前分类的对象方法、类方法、属性、协议信息，程序在运行的时候，运行时（`Runtime`）会将分类（`Category`）中所有的方法、属性、协议数据，合并到类信息中（类对象、元类对象中）

#### 分类编译之后的底层结构

* 1.1 对当前已存在的类，新建一个分类（此处创建的是一个名为 `YXCPerson+Test` 的分类），然后使用 `clang` 将当前创建的分类进行转换
    `YXCPerson+Test.h` 文件
    ```Objective-C
    // 属性：age 、num 还有一个 不同寻常的 custId 
    // 实例方法（对象方法）： test()、eat()
    // 类方法 ： sing()
    // 协议 ： 遵守了 NSCopying, NSCoding 协议
    @interface YXCPerson (Test)<NSCopying, NSCoding>

    @property (nonatomic, assign) int age;
    @property (nonatomic, assign) int num;
    @property (nonatomic, copy, class) NSString *custId;

    - (void)test;

    - (void)eat;

    + (void)sing;

    @end
    ```

    `clang` 指令

    ```shell
    xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc 分类名称.m
    ```

* 1.2 底层结构展示

    ```C++
    struct _category_t {
        const char *name; // 类名
        struct _class_t *cls; // 已存在的类（YXCPerson）
        const struct _method_list_t *instance_methods; // 实例方法（对象方法）列表
        const struct _method_list_t *class_methods; // 类方法列表
        const struct _protocol_list_t *protocols; // 协议列表
        const struct _prop_list_t *properties; // 属性列表
    };
    ```

* 1.3 `_class_t` 底层结构

    ```C++
    struct _class_t {
        struct _class_t *isa; // isa 指针，实例对象指向类对象，类对象指向元类对象，元类对象指向基类的元类对象（一般是 NSObject）
        struct _class_t *superclass; // 父类
        void *cache; // 缓存
        void *vtable;
        struct _class_ro_t *ro; // 存储的原来类（非分类）的一些方法、协议、属性、成员变量等信息
    };
    ```

* 1.4 `_class_ro_t` 底层结构

    ```C++
    struct _class_ro_t {
        unsigned int flags;
        unsigned int instanceStart;
        unsigned int instanceSize;
        const unsigned char *ivarLayout;
        const char *name;
        const struct _method_list_t *baseMethods;
        const struct _objc_protocol_list *baseProtocols;
        const struct _ivar_list_t *ivars;
        const unsigned char *weakIvarLayout;
        const struct _prop_list_t *properties;
    };
    ```

* 1.5 `YXCPerson+Test` 分类在底层结构为

    ```C++
    static struct _category_t _OBJC_$_CATEGORY_YXCPerson_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = 
    {
        "YXCPerson", // 原来的类名
        0, // &OBJC_CLASS_$_YXCPerson,
        (const struct _method_list_t *)&_OBJC_$_CATEGORY_INSTANCE_METHODS_YXCPerson_$_Test, // 实例对象方法列表
        (const struct _method_list_t *)&_OBJC_$_CATEGORY_CLASS_METHODS_YXCPerson_$_Test, // 类对象方法列表
        (const struct _protocol_list_t *)&_OBJC_CATEGORY_PROTOCOLS_$_YXCPerson_$_Test, // 协议信息列表
        (const struct _prop_list_t *)&_OBJC_$_PROP_LIST_YXCPerson_$_Test, // 属性列表
    };
    ```
    可以发现，在编译之后 `YXCPerson+Test` 这个分类，在底层的结构是一个 `_category_t` 类型，并且名称为 `_OBJC_$_CATEGORY_YXCPerson_$_Test` 的结构体。由此可以推测，每个分类在编译之后，都是一个 `_category_t` 类型，并且命名按照 `_OBJC_$_CATEGORY_已存在的类名_$_分类名称` 这样的一个方式。
     
* 1.6 实例（对象）方法

    `_OBJC_$_CATEGORY_INSTANCE_METHODS_YXCPerson_$_Test` 这样的一个结构体，顾名思义这是存储着我们当前这个分类的一些实例方法数据，并且为 `_method_list_t` 类型的结构体

    ```C++
    static struct /*_method_list_t*/ {
        unsigned int entsize;  // sizeof(struct _objc_method)
        unsigned int method_count; // 实例方法的数量
        struct _objc_method method_list[2]; // 方法列表，在这里有两个方法
    } _OBJC_$_CATEGORY_INSTANCE_METHODS_YXCPerson_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = {
        sizeof(_objc_method), // 获取到 _objc_method 结构体的所需要的内存空间大小，赋值到 entsize
        2, // method_count 为 2
        {
            {(struct objc_selector *)"test", "v16@0:8", (void *)_I_YXCPerson_Test_test},
            {(struct objc_selector *)"eat", "v16@0:8", (void *)_I_YXCPerson_Test_eat}
        } // 将 test()、eat() 方法放入一个数组，然后赋值给 method_list
    };
    ```

    `struct objc_selector` 实际上是一个 `SEL`

    ```C++
    typedef struct objc_selector *SEL;
    ```

    `_objc_method` 结构为

    ```C++
    struct _objc_method {
        struct objc_selector * _cmd; // SEL 地址
        const char *method_type; // 方法签名
        void  *_imp; // 方法实现
    };
    ```

    **通过以上分析，可以总结出：**

    > 1. OC 中实例（对象）方法在底层的实现是一个 `_objc_method` 类型的结构体，它包含了方法的声明、签名以及实现，编译器会将方法的声明、签名、实现信息放入到这个结构体当中存储起来。
    >
    > 2. 将一个个的实例（对象）方法通过 `_objc_method` 结构体存储好后，放入一个 `_method_list_t` 结构体中的 `method_list` 数组中(这个数组的个数会根据当前分类的方法个数，分配空间)，同时按照 `_OBJC_$_CATEGORY_INSTANCE_METHODS_原类名称_$_分类名称` 这样的一个格式给这个结构体取名。
    >
    > 3. 最后将 `_method_list_t` 类型的赋值给 `_category_t` 中的 `instance_methods`，这样就将当前分类中的实例（对象）方法存储到了当前分类结构体中去了。

* 1.7 类方法

    类方法存储到一个名为 `_OBJC_$_CATEGORY_CLASS_METHODS_YXCPerson_$_Test` 的结构体，这个结构体也是一个 `_method_list_t`，跟实例（对象）方法的原理是一致的。

    ```C++

    static struct /*_method_list_t*/ {
        unsigned int entsize;  // sizeof(struct _objc_method)
        unsigned int method_count; // 类方法个数
        struct _objc_method method_list[1]; // 存放着 _objc_method 类型的结构体数组
    } _OBJC_$_CATEGORY_CLASS_METHODS_YXCPerson_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = {
        sizeof(_objc_method),
        1,
        {{(struct objc_selector *)"sing", "v16@0:8", (void *)_C_YXCPerson_Test_sing}}
    };

    ```

* 1.8 协议信息

    协议信息存储到了一个名为 `_OBJC_CATEGORY_PROTOCOLS_$_YXCPerson_$_Test` 的 `_protocol_list_t` 类型的结构体中，`_protocol_list_t` 结构体。

    ```C++
    static struct /*_protocol_list_t*/ {
        long protocol_count;  // Note, this is 32/64 bit
        struct _protocol_t *super_protocols[2];
    } _OBJC_CATEGORY_PROTOCOLS_$_YXCPerson_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = {
        2,
        &_OBJC_PROTOCOL_NSCopying,
        &_OBJC_PROTOCOL_NSCoding
    };
    ```

* 1.9 属性信息

    属性信息存储到了一个名为 `_OBJC_$_PROP_LIST_YXCPerson_$_Test` 的 `_prop_list_t` 类型的结构体，其中这个结构体中有一个 `prop_list` 属性，里面存放的就是当前分类所有的属性，当然在底层的结构是一个 `_prop_t` 结构体。

    ```C++
    static struct /*_prop_list_t*/ {
        unsigned int entsize;  // sizeof(struct _prop_t)
        unsigned int count_of_properties;
        struct _prop_t prop_list[2];
    } _OBJC_$_PROP_LIST_YXCPerson_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = {
        sizeof(_prop_t),
        2,
        {{"age","Ti,N"},
        {"num","Ti,N"}}
    };

    struct _prop_t {
        const char *name;
        const char *attributes;
    };
    ```

#### 分类加载处理过程

 > 1. 通过运行时（Runtime）加载某个类的所有分类数据
 > 2. 把所有分类的方法、属性、协议数据，合并到一个数组中，后参与编译的分类数据，会在数组的最前面
 > 3. 将合并后的分类数据（方法、属性、协议），插入到类原来数据的前面

 下面通过源码来查看这个过程，下载[最新的源码](https://opensource.apple.com/tarballs/objc4/) 

 1. 找到 `objc-os.mm` 文件，并且找到 `_objc_init` 函数，在 `_objc_init` 函数中有一个 `_dyld_objc_notify_register` 函数，这个函数第一个参数传入了一个镜像（`map_images`）

 ```C++
 /***********************************************************************
* _objc_init
* Bootstrap initialization. Registers our image notifier with dyld.
* Called by libSystem BEFORE library initialization time
**********************************************************************/

void _objc_init(void)
{
    static bool initialized = false;
    if (initialized) return;
    initialized = true;
    
    // fixme defer initialization until an objc-using image is found?
    environ_init();
    tls_init();
    static_init();
    runtime_init();
    exception_init();
    cache_init();
    _imp_implementationWithBlock_init();

    _dyld_objc_notify_register(&map_images, load_images, unmap_image);

    #if __OBJC2__
    didCallDyldNotifyRegister = true;
    #endif
}
 ```

 2. 在 `objc-runtime-new.mm` 文件中，找到 `map_images` 函数，发现返回的结果是通过调用 `map_images_nolock` 函数得到的结果

 ```C++
 /***********************************************************************
* map_images
* Process the given images which are being mapped in by dyld.
* Calls ABI-agnostic code after taking ABI-specific locks.
*
* Locking: write-locks runtimeLock
**********************************************************************/
void
map_images(unsigned count, const char * const paths[],
           const struct mach_header * const mhdrs[])
{
    mutex_locker_t lock(runtimeLock);
    return map_images_nolock(count, paths, mhdrs);
}
 ```

 3. 在 `objc-os.mm` 文件中找到 `map_images_nolock` 函数，查看该函数

 ```C++
 ...
 if (hCount > 0) {
    _read_images(hList, hCount, totalClasses, unoptimizedTotalClasses);
 }
 ```

 4. 跳转到 _read_images 函数中查看，位于 `objc-runtime-new.mm`





