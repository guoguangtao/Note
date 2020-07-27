[toc]

#### 1.字体大小自适应（adjustsFontSizeToFitWidth）

```Objective-C
UILabel *label = [UILabel new];
label.font = [UIFont systemFontOfSize:20.0f];
label.text = @"设置UILabel字体大小自适应";
label.width = 200;
label.height = 30;
label.center = self.view.center;
label.backgroundColor = [UIColor orangeColor];
[self.view addSubview:label];
```
设置了固定的宽高，默认样式

![固定宽高，默认样式](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200727203550.png)

使用 `adjustsFontSizeToFitWidth` 
```Objective-c
label.adjustsFontSizeToFitWidth = YES;
```
变成
![adjustsFontSizeToFitWidth 自适应](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200727203724.png)

**当文本的实际宽高大于设置的Frame宽高，`adjustsFontSizeToFitWidth` 才有效果。**

