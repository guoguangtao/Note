[toc]

### UIDatePicker

在 iOS 14 开始,`UIDatePicker` 默认样式为:

![iOS14 下展示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920182248.png)

而在 iOS14 之前的样式是

![iOS14 之前展示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920133038.png)

同样的代码，显示样式不一样

```Objective-c
UIDatePicker *datePicer = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 200, self.width, 100)];
datePicer.backgroundColor = [UIColor whiteColor];
[self addSubview:datePicer];
```
虽然有设置 `UIDatePicker` 的 `frame`，但是在 iOS 14 上完全没有效果,要想在 iOS 14 上显示跟之前一样，还要再设置 `preferredDatePickerStyle` 这个属性为 `UIDatePickerStyleWheels`.

```Objective-C
/// Request a style for the date picker. If the style changed, then the date picker may need to be resized and will generate a layout pass to display correctly.
@property (nonatomic, readwrite, assign) UIDatePickerStyle preferredDatePickerStyle API_AVAILABLE(ios(13.4)) API_UNAVAILABLE(tvos, watchos);
```

**对于这个属性，是 `UIDatePicker` 的样式，如果样式发生了更改，则可能需要调整 `UIDatePicker` 的大小并生成布局展示出来**

所以如果只是单单设置了这个属性还不行，还需要再重新设置 `Frame` 和 `backgroundColor`

```Objective-C
UIDatePicker *datePicer = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 200, self.width, 100)];
    if (@available(iOS 13.4, *)) {
        datePicer.preferredDatePickerStyle = UIDatePickerStyleWheels; // 只设置了 preferredDatePickerStyle 属性
    }
datePicer.backgroundColor = [UIColor whiteColor];
[self addSubview:datePicer];
```

![只设置了preferredDatePickerStyle属性，并未改变 Frame](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920183159.png)

```Objective-C
CGRect frame = CGRectMake(0, 200, self.width, 100);
UIDatePicker *datePicer = [[UIDatePicker alloc] initWithFrame:CGRectZero];
if (@available(iOS 13.4, *)) {
    datePicer.preferredDatePickerStyle = UIDatePickerStyleWheels; // 只设置了 preferredDatePickerStyle 属性
}
datePicer.backgroundColor = [UIColor whiteColor];
datePicer.frame = frame;
[self addSubview:datePicer];
```

![设置并重新设置了 frame](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920183609.png)


### UITableViewCell

在 iOS 14 环境下，UITableViewCell 的结构如下：

![iOS 14 UITableViewCell 结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920184327.png)

而在 iOS 14 之前，UITableViewCell 的结构如下：

![iOS 14 之前 UITableViewCell 结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920184751.png)

对比可以发现，iOS14 多了一个 `_UISystemBackgroundView` 和一个子视图
如果我们在cell 中创建新的 UI 控件，然后直接添加到 cell 中,所以在 iOS14 下,如果直接讲 UI 空间添加到 cell 上面,默认会放在 contentView 下面,如果有一些交互事件,这时候是无法响应的,因为被 contentView 给挡住了,所以需要添加到 contentView 上面.

### UIPageControl

在之前,如果想要修改 UIPageControl 默认图片和选中图片,需要按照如下方式修改:

```Objective-C
[_pageControl setValue:_pageIndicatorImage forKeyPath:@"pageImage"];
[_pageControl setValue:_currentPageIndicatorImage forKeyPath:@"currentPageImage"];
```

但是在 iOS14 开始,这样修改直接一个异常,提示调用过时的私有方法:

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Call to obsolete private method -[UIPageControl _setPageImage:]'
```

![20200921112924](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200921112924.png)

```Objective-C
UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 100, self.view.width, 30)];
pageControl.backgroundColor = [UIColor orangeColor];
pageControl.numberOfPages = 6;
    
if (@available(iOS 14.0, *)) {
    pageControl.backgroundStyle = UIPageControlBackgroundStyleMinimal;
    pageControl.allowsContinuousInteraction = false;
    pageControl.preferredIndicatorImage = [UIImage imageNamed:@"page_currentImage"];
    // 目前发现只能通过这样的方式去设置当前选中的图片颜色
    pageControl.currentPageIndicatorTintColor = [UIColor redColor];
    [pageControl setIndicatorImage:[UIImage imageNamed:@"live"] forPage:2];
} else {
    [pageControl setValue:[UIImage imageNamed:@"page_image"] forKeyPath:@"pageImage"];
    [pageControl setValue:[UIImage imageNamed:@"page_currentImage"] forKeyPath:@"currentPageImage"];
}
[self.view addSubview:pageControl];
```

运行不同环境

iOS 14 之前环境

![20200921113957](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200921113957.png)

iOS 14 之后环境

![20200921114547](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200921114547.png)



