[toc]

`Category` 主要作用是在不改变原有类的基础上，动态的给已存在的类添加一些方法和属性。

分类(`Category`)在编译之后的底层结构是 `struct category_t`，里面存储着当前分类的对象方法、类方法、属性、协议信息，程序在运行的时候，运行时（`Runtime`）会将分类（`Category`）中所有的方法、属性、协议数据，合并到类信息中（类对象、元类对象中）

#### 分类编译之后的底层结构

* 对当前已存在的类，新建一个分类（此处创建的是一个名为 `YXCPerson+Test` 的分类），然后使用 `clang` 将当前创建的分类进行转换
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

* 底层结构展示

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

    `_class_t` 底层结构

    ```C++
    struct _class_t {
        struct _class_t *isa; // isa 指针，实例对象指向类对象，类对象指向元类对象，元类对象指向基类的元类对象（一般是 NSObject）
        struct _class_t *superclass; // 父类
        void *cache; // 缓存
        void *vtable;
        struct _class_ro_t *ro; // 存储的原来类（非分类）的一些方法、协议、属性、成员变量等信息
    };
    ```

    `_class_ro_t` 底层结构

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

    `YXCPerson+Test` 分类在底层结构为

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

    首先看 `_OBJC_$_CATEGORY_INSTANCE_METHODS_YXCPerson_$_Test` 这样的一个结构体，顾名思义这是存储着我们当前这个分类的一些实例方法数据，并且为 _method_list_t 类型的结构体

    ```C++
    static struct /*_method_list_t*/ {
        unsigned int entsize;  // sizeof(struct _objc_method)
        unsigned int method_count;
        struct _objc_method method_list[2];
    } _OBJC_$_CATEGORY_INSTANCE_METHODS_YXCPerson_$_Test __attribute__ ((used, section ("__DATA,__objc_const"))) = {
        sizeof(_objc_method),
        2,
        {{(struct objc_selector *)"test", "v16@0:8", (void *)_I_YXCPerson_Test_test},
        {(struct objc_selector *)"eat", "v16@0:8", (void *)_I_YXCPerson_Test_eat}}
    };
    ```

