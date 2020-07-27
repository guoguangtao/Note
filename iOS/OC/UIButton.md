#### 1.去除默认内边距

默认情况：

```Objective-C
UIButton *button = [[UIButton alloc] init];
button.titleLabel.font = [UIFont systemFontOfSize:25];
button.backgroundColor = [UIColor orangeColor];
[button setTitle:@"去除Button默认的内边距" forState:UIControlStateNormal];
[self.view addSubview:button];
    
button.size = [button sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
button.center = self.view.center;
```

![默认状态](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200727200517.png)

去除顶部和底部默认间距

* 第一种方式：设置 `ContentInsets`

```Objective-C
button.contentEdgeInsets = UIEdgeInsetsMake(-2, 0, -2, 0);
```
![使用contentEdgeInsets去除默认内边距](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200727200931.png)

* 第二种方式：直接使用 `Button` 的 `titleLabel` 的`frame`，如果有图片再加上图片的 `frame`

```Objective-C
UIButton *button = [[UIButton alloc] init];
button.titleLabel.font = [UIFont systemFontOfSize:25];
button.backgroundColor = [UIColor orangeColor];
[button setTitle:@"去除Button默认的内边距" forState:UIControlStateNormal];
[self.view addSubview:button];
    
button.size = [button.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
button.center = self.view.center;
```
![使用`Frame`的方式](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200727201333.png)
