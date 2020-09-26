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

在 iOS 14 环境下，`UITableViewCell` 的结构如下：

![iOS 14 UITableViewCell 结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920184327.png)

而在 iOS 14 之前，`UITableViewCell` 的结构如下：

![iOS 14 之前 UITableViewCell 结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200920184751.png)

对比可以发现，iOS14 多了一个 `_UISystemBackgroundView` 和一个子视图
如果我们在`cell` 中创建新的 UI 控件，然后直接添加到 `cell` 中,所以在 iOS14 下,如果直接讲 UI 空间添加到 `cell` 上面,默认会放在 `contentView` 下面,如果有一些交互事件,这时候是无法响应的,因为被 `contentView` 给挡住了,所以需要添加到 `contentView` 上面.

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


### CALayer 的 mask

公司所在的项目中,聊天界面利用`CALayer`的 `mask`方式将背景弄成一个气泡的样式,在 `iOS 14` 之前是好的,但是在 `iOS 14` 上就显示不出来了.具体的方式是将一个气泡图片,用一个 `UIImageView` 加载出来,然后将这个气泡的 `ImageView` 的 `layer` 作为一个遮罩,放在图片消息上面去.
代码类似下面的:

```Objective-C
UIImageView *imageView = [UIImageView new];
imageView.image = [UIImage imageNamed:@"calendar"];
imageView.size = CGSizeMake(200, 200);
imageView.center = self.center;
[self addSubview:imageView];
    
UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 80)];
imgView.image = [UIImage imageNamed:@"green_pop"];
imageView.layer.mask = imgView.layer;
```

以上代码运行结果,在不同的环境下,显示出来的效果不一样

![20200922182808](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200922182808.png)

![20200922182937](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200922182937.png)

`iOS14` 显示不出来,但是在 `iOS12.4` 却能显示出来

后面在添加到 `imageView.layer.mask` 之前,将 `imgView` 添加到某个视图上去,发现在 `iOS 14` 上又能显示出来,所以想是不是在 `iOS14` 上的渲染逻辑发生了改变

![20200922190031](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200922190031.png)

```Objective-C
UIImageView *imageView = [UIImageView new];
imageView.image = [UIImage imageNamed:@"calendar"];
imageView.size = CGSizeMake(200, 200);
imageView.center = self.center;
[self addSubview:imageView];

UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 80)];
imgView.image = [UIImage imageNamed:@"green_pop"];
[imageView addSubview:imgView];
imageView.layer.mask = imgView.layer;
```

其实可以直接使用 `layer` 的 `content` 进行设置图片

![将图片赋值到 content.png](https://upload-images.jianshu.io/upload_images/662079-66fcc5463bd462ce.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```Objective-C
UIImageView *imageView = [UIImageView new];
imageView.image = [UIImage imageNamed:@"calendar"];
imageView.size = CGSizeMake(200, 200);
imageView.center = self.center;
[self addSubview:imageView];
CALayer *maskLayer = [[CALayer alloc] init];
maskLayer.frame = CGRectMake(0, 0, 180, 90);
maskLayer.contents = (__bridge id)[UIImage imageNamed:@"green_pop"].CGImage;
imageView.layer.mask = maskLayer;
```
这样也能显示出来


### AssetsLibrary

`AssetsLibrary` 在 iOS9 已经开始被弃用了，但是一些老的项目还在使用这个库进行相册访问，经过测试，同样的代码，在 iOS 14 下拿到相册中的图片之后，获取图片的大小已经获取不到了

iOS14 之前获取图片大小情况

![iOS14之前AssetsLibrary获取图片大小](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/iOS14%E4%B9%8B%E5%89%8DAssetsLibrary%E8%8E%B7%E5%8F%96%E5%9B%BE%E7%89%87%E5%A4%A7%E5%B0%8F.png)

iOS 14 获取图片大小情况

![iOS14 AssetsLibrary获取图片大小](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/iOS14%20AssetsLibrary%E8%8E%B7%E5%8F%96%E5%9B%BE%E7%89%87%E5%A4%A7%E5%B0%8F.png)