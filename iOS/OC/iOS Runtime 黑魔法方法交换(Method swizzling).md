[toc]

在实际开发场景中，有时候我们需要在调用系统方法，或者某个类的方法的时候，增加自己的一些逻辑操作，这时候可以采用 **方法交换** 的方式去实现这个需求。这种方式也被称为 **黑魔法（Method swizzling）或者 hook**，网上也有很多这方面的文档解释，在这里主要是记录一下，`hook` 的时候遇到的问题。

#### 场景一：对某个类自身的方法进行 hook 操作

什么意思呢？举个例子，`NSString` 这个类，有一个 `substringToIndex:` 方法，这个方法是在 `NSString+NSStringExtensionMethods` 这样的一个分类里面。

需求：在使用 `substringToIndex:` 方法的时候，希望能在里面增加一些逻辑判断，比如判断当前传入的 `index` 是否在当前字符串范围之内。

```Objective-C
NSString *string = @"abcd";
NSLog(@"%@", [string substringToIndex:10]);
```

这里传入的 10，字符串没有这么长的长度，如果直接使用系统的方法，程序运行起来，立马发生闪退。

![substringToIndex超出范围](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/substringToIndex%E8%B6%85%E5%87%BA%E8%8C%83%E5%9B%B4.png)

下面，进行 `hook` 操作

* 给 `NSString` 新建一个分类，并在 load 方法中进行 `hook` 操作

    ```Objective-C
    + (void)load {
        
        // 系统方法
        Method system_method = class_getInstanceMethod([self class], @selector(substringToIndex:));
        // 将要替换系统方法
        Method my_method = class_getInstanceMethod([self class], @selector(yxc_substringToIndex:));
        // 进行交换
        method_exchangeImplementations(system_method, my_method);
    }

    - (NSString *)yxc_substringToIndex:(NSUInteger)to {
        
        // 判断传入的数值是否大于当前字符串的范围，如果大于的话，取当前字符串的最大长度
        if (to > self.length) {
            to = self.length;
        }
        
        return [self yxc_substringToIndex:to];
    }
    ```
    这样就 `hook` 完成了，查看结果:

    ![substringToIndex进行 hook 之后结果](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/substringToIndex%E8%BF%9B%E8%A1%8C%20hook%20%E4%B9%8B%E5%90%8E%E7%BB%93%E6%9E%9C.png)

这样看起来，`hook` 操作很简单，没有什么问题，但是这只是一种情况。


#### 场景二：对某个类的父类或者基类的方法进行 hook 操作

下面，对 `init` 这个方法进行 `hook` 操作。

* 因为 `NSString` 特殊性，在这里不再用 `NSString` 进行举例了，新建一个 `Person` 类，继承于 `NSObject`；再给 `Person` 类创建一个分类，然后按照上面的方式对 `Person` 的 `init` 方法进行 `hook`。

    ```Objective-C
    + (void)load {
        
        Class cls = [self class];
        
        Method system_method = class_getInstanceMethod(cls, @selector(init));
        Method my_method = class_getInstanceMethod(cls, @selector(yxc_init));
        
        method_exchangeImplementations(system_method, my_method);
    }

    - (instancetype)yxc_init {
        
        NSLog(@"%s", __func__);
        return [self yxc_init];
    }
    ```

* 通过 `alloc` 和 `init` 创建一个 `Person` 对象，并未出现异常。
* 紧接着创建一个 `NSObject` 对象，这时候问题出现了，程序进入死循环，并且报 `yxc_init:` 方法找不到。

    ![hook init方法报错](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/hook%20init%E6%96%B9%E6%B3%95%E6%8A%A5%E9%94%99.png)

    分析：
    * `init` 方法并不是 `Person` 类本身的实例（对象）方法，而是父类 `NSObject` 的方法。由于 `Person` 本身没有该方法，所以 `class_getInstanceMethod` 获取到的方法是通过 `Person` 的 `superclass` 指针从 `NSObject` 类中获取到了 `init` 这个方法。
    * `method_exchangeImplementations` 操作将 `NSObject` 的 `init` 方法的实现与 `Person` 类的 `yxc_init` 方法的实现进行互换了，这时候调用 `init` 方法实际上是调用了 `yxc_init` 方法。
    * 创建一个 `Person` 对象时，调用 `init` 方法，运行时会去查找 `yxc_init` 的实现，因为 `yxc_init` 方法是 `Person` 自身的方法，所以查找到了直接调用。（消息发送机制）
    * 而创建一个 `NSObject` 对象时，调用 `init` 方法，运行时去查找 `yxc_init` 方法的时候，`NSObject` 是没有这个方法，这个方法存在于 `Person` 类中，所以查找完毕，还是找不到这个方法，就抛异常了。

**正确的 `hook` 做法是，先将 `init` 方法添加到 `Person` 类中，如果这个类当前有这个方法（而不是父类），则不添加，直接 `exchange`，否则添加了 `init` 方法，然后再将 `yxc_init` 方法的实现设置成 `init` 方法的实现。**

```Objective-C
+ (void)load {

    Class cls = [self class];

    // 1. 获取到父类的 init 方法
    Method system_method = class_getInstanceMethod(cls, @selector(init));
    // 2. 获取到当前类的 yxc_init 方法
    Method my_method = class_getInstanceMethod(cls, @selector(yxc_init));
    // 3. 先将 init 方法添加到当前类中,并且将 yxc_init 作为 init 方法的实现
    BOOL addSuccess = class_addMethod(cls,
                                      @selector(init),
                                      method_getImplementation(my_method),
                                      method_getTypeEncoding(my_method));
    // 4. 判断 init 添加到当前类中是否成功
    if (addSuccess) {
        // 4.1 方法添加成功,则意味着当前类在添加之前并没有 init 方法,添加成功后就进行方法替换,将 init 方法的实现替换成 yxc_init 方法的实现
        class_replaceMethod(cls,
                            @selector(yxc_init),
                            method_getImplementation(system_method),
                            method_getTypeEncoding(system_method));
    } else {
        // 4.2 方法添加失败,说明当前类已存在该方法,直接进行方法交换
        method_exchangeImplementations(system_method, my_method);
    }
}

- (instancetype)yxc_init {
    
    NSLog(@"%s", __func__);
    return [self yxc_init];
}
```

运行结果显示：

![正确 hook init方法结果](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/%E6%AD%A3%E7%A1%AE%20hook%20init%E6%96%B9%E6%B3%95%E7%BB%93%E6%9E%9C.png)


通过这样的方式进行对 **父类或者基类** 方法的 `hook`，最终没有发现其他异常，以此记录。

最后封装一下 `hook` 逻辑操作

```Objective-C
/// hook 方法 （主要是为了 hook 某个类的 簇类 方法）
/// @param originCls 需要 hook 的类
/// @param currentCls 当前类
/// @param originSelector 将要 hook 掉的方法
/// @param swizzledSelector 新的方法
/// @param clsMethod 是否是类方法
+ (void)hookOriginClass:(Class)originCls
           currentClass:(Class)currentCls
         originSelector:(SEL)originSelector
       swizzledSelector:(SEL)swizzledSelector
            classMethod:(BOOL)clsMethod {
    
    Method origin_method;
    Method swizzled_method;
    
    if (clsMethod) {
        // 类方法
        origin_method = class_getClassMethod(originCls, originSelector);
        swizzled_method = class_getClassMethod(currentCls, swizzledSelector);
    } else {
        // 实例(对象)方法
        origin_method = class_getInstanceMethod(originCls, originSelector);
        swizzled_method = class_getInstanceMethod(currentCls, swizzledSelector);
    }
    
    // 给当前类添加 originSelector 方法，方法实现为 swizzled_method
    // 如果传入的是一个类方法，在这里需要将 元类对象传进去
    Class addCls = clsMethod ? object_getClass(currentCls) : currentCls;
    
    BOOL addSuccess = class_addMethod(addCls,
                                      originSelector,
                                      method_getImplementation(swizzled_method),
                                      method_getTypeEncoding(swizzled_method)
                                      );
    
    if (addSuccess) {
        // 将当前类的 swizzledSelector 的实现替换成 origin_method
        class_replaceMethod(addCls,
                            swizzledSelector,
                            method_getImplementation(origin_method),
                            method_getTypeEncoding(origin_method)
                            );
    } else {
        method_exchangeImplementations(origin_method, swizzled_method);
    }
}
```

#### 类簇（Class Clusters）

`Class Clusters`（类簇）是抽象工厂模式在iOS下的一种实现，众多常用类，如 `NSString`，`NSArray`，`NSDictionary`，`NSNumber`都运作在这一模式下，它是接口简单性和扩展性的权衡体现，在我们完全不知情的情况下，偷偷隐藏了很多具体的实现类，只暴露出简单的接口。

[官方文档讲解类簇](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/ClassClusters/ClassClusters.html)

下面对 `NSArray` 进行类簇讲解

系统会创建 `__NSPlaceholderArray`、 `__NSSingleObjectArrayI`、 `__NSArray0`、 `__NSArrayM` 等一些类簇，下面对这些类簇进行 `hook` 操作

```Objective-C
+ (void)load {
    
    [self hookOriginClass:NSClassFromString(@"__NSPlaceholderArray") currentClass:[NSArray class] originSelector:@selector(initWithObjects:count:) swizzledSelector:@selector(yxc_initWithObjects:count:) classMethod:NO];
    
    [self hookOriginClass:NSClassFromString(@"__NSSingleObjectArrayI") currentClass:[NSArray class] originSelector:@selector(objectAtIndex:) swizzledSelector:@selector(yxc_objectAtIndex:) classMethod:NO];
    
    [self hookOriginClass:NSClassFromString(@"__NSArray0") currentClass:[NSArray class] originSelector:@selector(objectAtIndex:) swizzledSelector:@selector(yxc_objectAtIndex1:) classMethod:NO];
    
    [self hookOriginClass:NSClassFromString(@"__NSArrayM") currentClass:[NSArray class] originSelector:@selector(objectAtIndexedSubscript:) swizzledSelector:@selector(yxc_objectAtIndexedSubscript:) classMethod:NO];
}
```

这样就对数组中的一些方法进行 hook 完了，而且也并没有什么问题。

到这里，就有一个疑问：**在这里替换同一个 `SEL` 为 `objectAtIndex:`，而这个方法是属于 `NSArray` 这个类，为什么这里替换了两次，彼此都没有影响到，按理来说根据同一个 `SEL` 获取到的 `IMP` 进行 `replace` 或者 `exchange`，那么最后生效的应该是最后一次进行 `hook` 的方法实现，但是经过发现，没有受影响。**

首先类簇是需要继承于原来那个类，在原来那个类的基础上衍生了许多类出来，下面我们用代码证明这一点。

```Objective-C
Class __NSArrayM = NSClassFromString(@"__NSArrayM");
Class __NSArray0 = NSClassFromString(@"__NSArray0");
Class __NSSingleObjectArrayI = NSClassFromString(@"__NSSingleObjectArrayI");
Class __NSPlaceholderArray = NSClassFromString(@"__NSPlaceholderArray");

NSLog(@"__NSArrayM -> superclass : %@", class_getSuperclass(__NSArrayM));
NSLog(@"__NSArray0 -> superclass : %@", class_getSuperclass(__NSArray0));
NSLog(@"__NSSingleObjectArrayI -> superclass : %@", class_getSuperclass(__NSSingleObjectArrayI));
NSLog(@"__NSPlaceholderArray -> superclass : %@", class_getSuperclass(__NSPlaceholderArray));
```

输出结果：

![NSArray 的类簇输出父类](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/NSArray%20%E7%9A%84%E7%B1%BB%E7%B0%87%E8%BE%93%E5%87%BA%E7%88%B6%E7%B1%BB.png)

既然 SEL 是 NSArray 的方法，为什么在 hook 的时候，能 hook 到每个类簇对应的想法？

**猜想：是不是每个类簇，都实现了 `objectAtIndex:` 这个方法，导致根据 `SEL` 获取到方法实现是不相同的**

下面进行验证这个猜想

```Objective-C
+ (void)load {
    
    [self hookOriginClass:NSClassFromString(@"__NSPlaceholderArray") currentClass:[NSArray class] originSelector:@selector(initWithObjects:count:) swizzledSelector:@selector(yxc_initWithObjects:count:) classMethod:NO];
    
    NSLog(@"交换前");
    [self logInfo];
    
    [self hookOriginClass:NSClassFromString(@"__NSSingleObjectArrayI") currentClass:[NSArray class] originSelector:@selector(objectAtIndex:) swizzledSelector:@selector(yxc_objectAtIndex:) classMethod:NO];
    NSLog(@"__NSSingleObjectArrayI交换后");
    [self logInfo];
    
    [self hookOriginClass:NSClassFromString(@"__NSArray0") currentClass:[NSArray class] originSelector:@selector(objectAtIndex:) swizzledSelector:@selector(yxc_objectAtIndex1:) classMethod:NO];
    NSLog(@"__NSArray0交换后");
    [self logInfo];
    
    [self hookOriginClass:NSClassFromString(@"__NSArrayM") currentClass:[NSArray class] originSelector:@selector(objectAtIndexedSubscript:) swizzledSelector:@selector(yxc_objectAtIndexedSubscript:) classMethod:NO];
    
    
}

+ (void)logInfo {
    
    Class singleObjectCls = NSClassFromString(@"__NSSingleObjectArrayI");
    Class __NSArray0Cls = NSClassFromString(@"__NSArray0");
    Class currentCls = [self class];
    
    SEL selector = @selector(objectAtIndex:);
    
    Method singleObjectClsMethod = class_getInstanceMethod(singleObjectCls, selector);
    Method __NSArray0ClsMethod = class_getInstanceMethod(__NSArray0Cls, selector);
    Method currentMethod = class_getInstanceMethod(currentCls, selector);
    
    
    IMP singleObjectClsMethodIMP = method_getImplementation(singleObjectClsMethod);
    IMP __NSArray0ClsMethodIMP = method_getImplementation(__NSArray0ClsMethod);
    IMP currentIMP = method_getImplementation(currentMethod);
    
    NSLog(@"selector : %p, singleObjectClsMethod : %p, __NSArray0ClsMethod : %p, currentMethod : %p, singleObjectClsMethodIMP : %p, __NSArray0ClsMethodIMP : %p, currentIMP : %p",
          selector, singleObjectClsMethod, __NSArray0ClsMethod, currentMethod, singleObjectClsMethodIMP, __NSArray0ClsMethodIMP, currentIMP);
}
```

以上代码，在 `hook` `objectAtIndex:` 方法之前和 `hook` 完一个、两个之后对 `SEL`、`class`、`Method`、`IMP` 信息输出

>2020-11-02 20:02:42.598040+0800 Block[32615:646190] 交换前==================
>2020-11-02 20:02:42.598612+0800 Block[32615:646190] selector : 0x7fff7256d44e, singleObjectClsMethod : 0x7fff85fe75c0, __NSArray0ClsMethod : 0x7fff85fcd260, currentMethod : 0x7fff85fda938, singleObjectClsMethodIMP : 0x7fff2e31daf6, __NSArray0ClsMethodIMP : 0x7fff2e41e13b, currentIMP : 0x7fff2e4629fe
>2020-11-02 20:02:42.598878+0800 Block[32615:646190] __NSSingleObjectArrayI交换后======================
>2020-11-02 20:02:42.598970+0800 Block[32615:646190] selector : 0x7fff7256d44e, singleObjectClsMethod : 0x7fff85fe75c0, __NSArray0ClsMethod : 0x7fff85fcd260, currentMethod : 0x7fff85fda938, singleObjectClsMethodIMP : 0x100003750, __NSArray0ClsMethodIMP : 0x7fff2e41e13b, currentIMP : 0x7fff2e4629fe
>2020-11-02 20:02:42.599166+0800 Block[32615:646190] __NSArray0交换后===================
>2020-11-02 20:02:42.599275+0800 Block[32615:646190] selector : 0x7fff7256d44e, singleObjectClsMethod : 0x7fff85fe75c0, __NSArray0ClsMethod : 0x7fff85fcd260, currentMethod : 0x7fff85fda938, singleObjectClsMethodIMP : 0x100003750, __NSArray0ClsMethodIMP : 0x1000037d0, currentIMP : 0x7fff2e4629fe

**根据输出的地址，可以看出根据不同的类簇获取到的 Method 的方法结构体地址也是不同一个，还有方法实现的地址也是不同一块存储空间，那就证明了猜想，根据 SEL 获取到的 Method 和 IMP 不同一个，可能是在每个类簇内部对父类NSArray 的 `objectAtIndex:` 重新实现了一下，导致获取到的并不是同一个。**

为了验证是否**子类重写了父类的方法获取到的并不是同一个**（原理来讲是不同一个的，下面用代码来验证这个想法）

新建一个 `Person` 类，并且声明一个 `test` 对象方法并实现，然后创建一个 `Student` 类，继承于 `Person` 类，先不重写父类的 `test` 方法。

![子类未重写父类方法获取 classMethod和 IMP 地址](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/%E5%AD%90%E7%B1%BB%E6%9C%AA%E9%87%8D%E5%86%99%E7%88%B6%E7%B1%BB%E6%96%B9%E6%B3%95%E8%8E%B7%E5%8F%96%20classMethod%E5%92%8C%20IMP%20%E5%9C%B0%E5%9D%80.png)

`Student` 未重写父类 `Person` 的 `test` 方法，通过各自获取到的 `Method` 和 `IMP` 的地址都是同一个

下面 `Student` 进行重写 `test` 方法

![子类重写父类方法获取 classMethod和 IMP 地址](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/%E5%AD%90%E7%B1%BB%E9%87%8D%E5%86%99%E7%88%B6%E7%B1%BB%E6%96%B9%E6%B3%95%E8%8E%B7%E5%8F%96%20classMethod%E5%92%8C%20IMP%20%E5%9C%B0%E5%9D%80.png)

这时候发现，通过各自获取 `Method` 和 `IMP` 的地址已经不一样了

这就验证了以上的猜想，**在类簇内部中，会对父类的一些方法进行重写。这就导致可能某一个方法，在一个类簇中已经进行了 hook，但是可能还是会出现方法名相同，但是类名不一样的方法报错，就像上面的 `objectAtIndex:` 方法一样，如果只是对 `__NSSingleObjectArrayI` 进行了替换或者交换方法操作，但是并没有对 `__NSArray0` 进行同样的操作，那么还是会出现索引超出界面，没有达到预防的效果。**



`class_addMethod` 函数官方文档描述

```C
/** 
 * Adds a new method to a class with a given name and implementation.
 * 
 * @param cls The class to which to add a method.
 * @param name A selector that specifies the name of the method being added.
 * @param imp A function which is the implementation of the new method. The function must take at least two arguments—self and _cmd.
 * @param types An array of characters that describe the types of the arguments to the method. 
 * 
 * @return YES if the method was added successfully, otherwise NO 
 *  (for example, the class already contains a method implementation with that name).
 *
 * @note class_addMethod will add an override of a superclass's implementation, 
 *  but will not replace an existing implementation in this class. 
 *  To change an existing implementation, use method_setImplementation.
 */
OBJC_EXPORT BOOL
class_addMethod(Class _Nullable cls, SEL _Nonnull name, IMP _Nonnull imp, 
                const char * _Nullable types) 
    OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0, 2.0);
```

下面对 `class_addMethod` 进行源码分析

```C
/// cls 类名
/// name 方法名
/// imp 方法实现 
/// types 方法签名
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types)
{
    // 没有传入 类名 直接返回 NO
    if (!cls) return NO;

    mutex_locker_t lock(runtimeLock);
    // 开始添加方法，对返回的结果进行取反，这里返回的是一个 IMP 类型的结果
    return ! addMethod(cls, name, imp, types ?: "", NO);
}
```

```C
/// cls 类名
/// name 方法名
/// imp 方法实现
/// types 方法签名
/// replace 是否直接替换，这里传入的是 NO
static IMP addMethod(Class cls, SEL name, IMP imp, const char *types, bool replace)
{
    IMP result = nil;
    
    runtimeLock.assertLocked();

    checkIsKnownClass(cls);
    
    ASSERT(types);
    ASSERT(cls->isRealized());

    method_t *m;
    // 查找该方法
    if ((m = getMethodNoSuper_nolock(cls, name))) {
        // already exists 已经存在该方法
        if (!replace) {
            // 当 replace 为 NO 时，直接返回该方法的实现
            result = m->imp;
        } else {
            // 当 replace 为 YES 时，通过 _method_setImplementation，直接将方法进行替换
            result = _method_setImplementation(cls, m, imp);
        }
    } else {
        // 该方法不存在，对传入的类进行动态添加方法
        auto rwe = cls->data()->extAllocIfNeeded();

        // fixme optimize
        // 创建一个方法列表
        method_list_t *newlist;
        // 分配内存，并设置好 method_list_t 的值
        newlist = (method_list_t *)calloc(sizeof(*newlist), 1);
        newlist->entsizeAndFlags = 
            (uint32_t)sizeof(method_t) | fixed_up_method_list;
        newlist->count = 1;
        newlist->first.name = name;
        newlist->first.types = strdupIfMutable(types);
        newlist->first.imp = imp;
        // 准备方法合并到该类中
        prepareMethodLists(cls, &newlist, 1, NO, NO);
        // 开始合并
        rwe->methods.attachLists(&newlist, 1);
        flushCaches(cls);

        result = nil;
    }

    return result;
}
```

```C
/// cls 类名
/// sel 方法名
static method_t *getMethodNoSuper_nolock(Class cls, SEL sel)
{
    runtimeLock.assertLocked();

    ASSERT(cls->isRealized());
    // fixme nil cls? 
    // fixme nil sel?
    // for 循环遍历，根据传入的 sel 方法进行查找当前类是否有该方法
    auto const methods = cls->data()->methods();
    for (auto mlists = methods.beginLists(),
              end = methods.endLists();
         mlists != end;
         ++mlists)
    {
        // <rdar://problem/46904873> getMethodNoSuper_nolock is the hottest
        // caller of search_method_list, inlining it turns
        // getMethodNoSuper_nolock into a frame-less function and eliminates
        // any store from this codepath.
        // 查找传入的方法列表是否有 sel 方法
        method_t *m = search_method_list_inline(*mlists, sel);
        // 找到了返回
        if (m) return m;
    }

    return nil;
}
```

```C
ALWAYS_INLINE static method_t *search_method_list_inline(const method_list_t *mlist, SEL sel)
{
    int methodListIsFixedUp = mlist->isFixedUp();
    int methodListHasExpectedSize = mlist->entsize() == sizeof(method_t);
    
    // 根据不同方式进行查找
    if (fastpath(methodListIsFixedUp && methodListHasExpectedSize)) {
        // 有序查找
        return findMethodInSortedMethodList(sel, mlist);
    } else {
        // Linear search of unsorted method list
        // 无序查找
        for (auto& meth : *mlist) {
            if (meth.name == sel) return &meth;
        }
    }

#if DEBUG
    // sanity-check negative results
    if (mlist->isFixedUp()) {
        for (auto& meth : *mlist) {
            if (meth.name == sel) {
                _objc_fatal("linear search worked when binary search did not");
            }
        }
    }
#endif

    return nil;
}
```


```C
// 二分查找方法
ALWAYS_INLINE static method_t *findMethodInSortedMethodList(SEL key, const method_list_t *list)
{
    ASSERT(list);

    const method_t * const first = &list->first;
    const method_t *base = first;
    const method_t *probe;
    uintptr_t keyValue = (uintptr_t)key;
    uint32_t count;
    
    for (count = list->count; count != 0; count >>= 1) {
        probe = base + (count >> 1);
        
        uintptr_t probeValue = (uintptr_t)probe->name;
        
        if (keyValue == probeValue) {
            // `probe` is a match.
            // Rewind looking for the *first* occurrence of this value.
            // This is required for correct category overrides.
            while (probe > first && keyValue == (uintptr_t)probe[-1].name) {
                probe--;
            }
            return (method_t *)probe;
        }
        
        if (keyValue > probeValue) {
            base = probe + 1;
            count--;
        }
    }
    
    return nil;
}
```

在使用 `class_addMethod` 添加方法时，只会在当前的类进行查找方法，并不会像 `消息机制` 那样在当前类找不到，就去父类查找。在当前类查找不到，就在当前类动态添加方法并设置实现；如果查找到了就不做操作，返回查找到的方法实现，然后通过取反操作，返回添加结果。

`class_replaceMethod` 函数官方文档描述

```C
/** 
 * Replaces the implementation of a method for a given class.
 * 
 * @param cls The class you want to modify.
 * @param name A selector that identifies the method whose implementation you want to replace.
 * @param imp The new implementation for the method identified by name for the class identified by cls.
 * @param types An array of characters that describe the types of the arguments to the method. 
 *  Since the function must take at least two arguments—self and _cmd, the second and third characters
 *  must be “@:” (the first character is the return type).
 * 
 * @return The previous implementation of the method identified by \e name for the class identified by \e cls.
 * 
 * @note This function behaves in two different ways:
 *  - If the method identified by \e name does not yet exist, it is added as if \c class_addMethod were called. 
 *    The type encoding specified by \e types is used as given.
 *  - If the method identified by \e name does exist, its \c IMP is replaced as if \c method_setImplementation were called.
 *    The type encoding specified by \e types is ignored.
 */
OBJC_EXPORT IMP _Nullable
class_replaceMethod(Class _Nullable cls, SEL _Nonnull name, IMP _Nonnull imp, 
                    const char * _Nullable types) 
    OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0, 2.0);
```

查看 `` 源码

```C
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
{
    if (!cls) return nil;

    mutex_locker_t lock(runtimeLock);
    // 调用 addMethod 方法，但是此时 addMethod 方法中的 replace 参数传入的是 YES
    return addMethod(cls, name, imp, types ?: "", YES);
}
```

通过上面的 `addMethod` 源码分析

* 当查找到方法已存在，直接通过 `_method_setImplementation` 方法将传入的方法实现，设置为查找目标方法的实现
* 当查找到方法不存在，动态添加到当前类中


下面查看一下 `_method_setImplementation` 方法的实现原理

```C
static IMP _method_setImplementation(Class cls, method_t *m, IMP imp)
{
    runtimeLock.assertLocked();

    if (!m) return nil;
    if (!imp) return nil;
    // 将旧的实现取出
    IMP old = m->imp;
    // 直接将新的实现方法设置到 method_t 的imp
    m->imp = imp;

    // Cache updates are slow if cls is nil (i.e. unknown)
    // RR/AWZ updates are slow if cls is nil (i.e. unknown)
    // fixme build list of classes whose Methods are known externally?

    flushCaches(cls);

    adjustCustomFlagsForMethodChange(cls, m);

    // 返回旧的实现
    return old;
}
```

查看 `method_exchangeImplementations` 的方法实现原理

```C
void method_exchangeImplementations(Method m1, Method m2) {
    if (!m1  ||  !m2) return;

    mutex_locker_t lock(runtimeLock);
    // 直接将传入的两个 Method 方法实现进行互换
    IMP m1_imp = m1->imp;
    m1->imp = m2->imp;
    m2->imp = m1_imp;


    // RR/AWZ updates are slow because class is unknown
    // Cache updates are slow because class is unknown
    // fixme build list of classes whose Methods are known externally?

    flushCaches(nil);

    adjustCustomFlagsForMethodChange(nil, m1);
    adjustCustomFlagsForMethodChange(nil, m2);
}
```

查看 `class_getInstanceMethod` 方法底层实现原理

```C
Method class_getInstanceMethod(Class cls, SEL sel)
{
    if (!cls  ||  !sel) return nil;

    // This deliberately avoids +initialize because it historically did so.

    // This implementation is a bit weird because it's the only place that 
    // wants a Method instead of an IMP.

#warning fixme build and search caches
        
    // Search method lists, try method resolver, etc.
    lookUpImpOrForward(nil, sel, cls, LOOKUP_RESOLVER);

#warning fixme build and search caches

    return _class_getMethod(cls, sel);
}
```

