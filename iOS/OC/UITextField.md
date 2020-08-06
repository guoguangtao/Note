[toc]

### 1.禁止复制和粘贴功能
有的时候,需要将输入框禁止复制、粘贴等功能的使用.

* 新建一个子类,继承于 `UITextField`,然后重写 `canPerformAction:withSender:` 方法

    ```Objective-C
    - (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
        
        YXCLog(@"%@", NSStringFromSelector(action));
        return NO;
    }
    ```
    将所有的功能都禁用了.

    **在网上,看到某些人的文章,使用分类去重写这个方法,经过测试无效果.**