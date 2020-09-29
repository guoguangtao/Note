[toc]

`UITableView` 多选

创建一个 `UITableView`

```Objective-C
self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
self.tableView.dataSource = self;
self.tableView.delegate = self;
self.tableView.tableFooterView = [UIView new];
self.tableView.rowHeight = 100;
self.tableView.allowsMultipleSelectionDuringEditing = YES; // 设置多选
[self.view addSubview:self.tableView];
```

进入多选模式,调用 `TableView` 的 `setEditing:animated:` 方法进入编辑模式,这里设置的是多选模式.

然后选中一些 `Cell` , 默认情况下是这样的:

![UITableView多选](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/UITableView%E5%A4%9A%E9%80%89.gif)

选中 `cell` 时,左边的颜色跟右边有点不协调,下面就是需要将左边的颜色也改成白色.

首先自定义一个 `Cell` , 然后重写 `setEditing:animated:` 方法

```Objective-C
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    UIColor *color = UIColor.whiteColor;
    self.contentView.backgroundColor = color; // 内容显示部分设置颜色
    self.backgroundColor = color; // 左边选中部分设置颜色
}
```

通过这样设置，发现左边颜色灰色只是变浅了一点，还是存在不协调的感觉

![TableViewCell重写SetEditing方法](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/TableViewCell%E9%87%8D%E5%86%99SetEditing%E6%96%B9%E6%B3%95.png)

查看 `TableViewCell` 的层次结构

首先查看选中的层次结构
![TableViewCell层次结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/TableViewCell%E5%B1%82%E6%AC%A1%E7%BB%93%E6%9E%84.png)

紧接着查看未选中层次结构

![TableViewCell未选中层次结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/TableViewCell%E6%9C%AA%E9%80%89%E4%B8%AD%E5%B1%82%E6%AC%A1%E7%BB%93%E6%9E%84.png)

对比发现，选中的时候在 `Cell` 中多了 `UITableViewCellSelectedBackground`,而在 `UITableViewCell` 中确实有一个 `selectedBackgroundView` 属性,同时也有一个 `multipleSelectionBackgroundView` 属性，经过尝试，发现在多选模式下，`multipleSelectionBackgroundView` 一般为 `nil`,可以在初始化 `Cell` 的时候，创建一个 `View` 赋值给 `multipleSelectionBackgroundView` ,这个属性会优先于 `selectedBackgroundView`。
关于这两个属性的解释

```Objective-C
// Always nil when a non-nil `backgroundConfiguration` is set. The 'selectedBackgroundView' will be added as a subview directly above the backgroundView if not nil, or behind all other views. It is added as a subview only when the cell is selected. Calling -setSelected:animated: will cause the 'selectedBackgroundView' to animate in and out with an alpha fade.
@property (nonatomic, strong, nullable) UIView *selectedBackgroundView;
// Always nil when a non-nil `backgroundConfiguration` is set. If not nil, takes the place of the selectedBackgroundView when using multiple selection.
@property (nonatomic, strong, nullable) UIView *multipleSelectionBackgroundView API_AVAILABLE(ios(5.0));
```

所以通过这两个可以让选中状态看起来更加和谐

1. `selectedBackgroundView`

```Objective-C
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.selectedBackgroundView.backgroundColor = [UIColor whiteColor];
}
```

![UITableViewCell中selectedBackgroundView方式.gif](https://upload-images.jianshu.io/upload_images/662079-25dea588b014a27a.gif?imageMogr2/auto-orient/strip)

2. 在初始化 `Cell` 的时候创建 `multipleSelectionBackgroundView`


```Objective-C
self.multipleSelectionBackgroundView = [UIView new];
self.multipleSelectionBackgroundView.backgroundColor = [UIColor redColor]; // 为了区分 selectedBackgroundView 方式，这里使用红色背景
```

![UITableViewCell中multipleSelectionBackgroundView方式.gif](https://upload-images.jianshu.io/upload_images/662079-0ad4867c000b5ae6.gif?imageMogr2/auto-orient/strip)



