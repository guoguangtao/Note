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
如果我们在cell 中创建新的 UI 控件，然后直接添加到 cell 中，

