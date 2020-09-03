[toc]

# `NSObject` 底层研究

在 `OC` 中,除了 `NSProxy` 类以外,所有的类都是 `NSObject` 的子类.在 `Foundation` 框架中, `NSProxy` 和 `NSObject` 是两个基类,定义了类层次结构,和该类所有子类的公共接口和行为.
`NSProxy` 是专门实现代理对象的类,这个类本篇文章不提.这两个类都遵守了 `NSObject` 协议.在 `NSObject` 协议中,声明了所有 `OC` 对象的公共方法.

```Objective-C
@class NSString, NSMethodSignature, NSInvocation;

@protocol NSObject

- (BOOL)isEqual:(id)object;
@property (readonly) NSUInteger hash;

@property (readonly) Class superclass;
- (Class)class OBJC_SWIFT_UNAVAILABLE("use 'type(of: anObject)' instead");
- (instancetype)self;

- (id)performSelector:(SEL)aSelector;
- (id)performSelector:(SEL)aSelector withObject:(id)object;
- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

- (BOOL)isProxy;

- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;

- (BOOL)respondsToSelector:(SEL)aSelector;

- (instancetype)retain OBJC_ARC_UNAVAILABLE;
- (oneway void)release OBJC_ARC_UNAVAILABLE;
- (instancetype)autorelease OBJC_ARC_UNAVAILABLE;
- (NSUInteger)retainCount OBJC_ARC_UNAVAILABLE;

- (struct _NSZone *)zone OBJC_ARC_UNAVAILABLE;

@property (readonly, copy) NSString *description;
@optional
@property (readonly, copy) NSString *debugDescription;

@end
```

## `NSObject` 定义

```Objective-C
@interface NSObject <NSObject> {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
    Class isa  OBJC_ISA_AVAILABILITY;
#pragma clang diagnostic pop
}
```

而 `Class` 在 `OC` 中的定义为

```Objective-C
typedef struct objc_class *Class;
```

紧接着看 `objc_class` 这个结构体,通过查看源码 [objc4-781.tar.gz](https://opensource.apple.com/tarballs/objc4/) 了解 `objc_class` 这个结构体的组成结构(`objc-runtime-new.h` 文件,搜索 `struct objc_class :`),
在这里主要是粘贴了属性.

```C++
struct objc_class : objc_object {
    // Class ISA;
    Class superclass;
    cache_t cache;             // formerly cache pointer and vtable
    class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags
}
```
再查看 `objc_object` 结构

```C++
struct objc_object {
private:
    isa_t isa;

public:

    // ISA() assumes this is NOT a tagged pointer object
    Class ISA();
    ...
}
```


