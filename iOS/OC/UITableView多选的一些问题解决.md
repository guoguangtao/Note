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


