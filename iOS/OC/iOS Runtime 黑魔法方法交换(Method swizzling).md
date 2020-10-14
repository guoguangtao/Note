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

最后封装一下 hook 逻辑操作

```Objective-C
/// hook 方法
/// @param cls 类
/// @param originSelector 将要 hook 掉的方法
/// @param swizzledSelector 新的方法
+ (void)hookMethod:(Class)cls originSelector:(SEL)originSelector swizzledSelector:(SEL)swizzledSelector {
    
    Method origin_method = class_getInstanceMethod(cls, originSelector);
    Method swizzled_method = class_getInstanceMethod(cls, swizzledSelector);
    BOOL addSuccess = class_addMethod(cls,
                                      originSelector,
                                      method_getImplementation(swizzled_method),
                                      method_getTypeEncoding(swizzled_method));
    if (addSuccess) {
        class_replaceMethod(cls,
                            swizzledSelector,
                            method_getImplementation(origin_method),
                            method_getTypeEncoding(origin_method));
    } else {
        method_exchangeImplementations(origin_method, swizzled_method);
    }
}
```

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

