[toc]

![iOS 箭头弹窗样式](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/iOS%20%E7%AE%AD%E5%A4%B4%E5%BC%B9%E7%AA%97%E6%A0%B7%E5%BC%8F.png)

`iOS` 在日常开发中，可能会遇到这种箭头弹窗，于是自己手撸了一个这样的控件。

### 要求

* 箭头的位置，始终对着被点击的 `view` 的中心位置（箭头位置不确定性）
* 弹窗显示完全（不能超出界面）

### 创建类，并且声明属性

#### `.h` 文件

在 `.h` 文件中，声明一个 `showForm:` 方法，传入的参数是当前被点击的 `view`。

```Objective-C
//
//  YXCPopOverView.h
//  YXCTools
//
//  Created by GGT on 2020/10/23.
//  Copyright © 2020 GGT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YXCPopOverView : UIView

#pragma mark - Property


#pragma mark - Method

/// 从 view 展示弹窗
/// @param view 被点击的 view
- (void)showForm:(UIView *)view;

@end
```

#### `.m` 文件

在 .m 文件中进行属性的声明和逻辑实现

##### 属性声明

```Objective-C
@property (nonatomic, strong) UIView *contentView; /**< 真实的黑色部分 view */
@property (nonatomic, strong) UIColor *yxc_backgroundColor; /**< 背景颜色 */
@property (nonatomic, assign) CGFloat triangleWidth; /**< 三角形宽度 */
@property (nonatomic, assign) CGFloat triangleHeight; /**< 三角形高度 */
@property (nonatomic, assign) CGPoint startPoint; /**< 三角形起始位置 */
@property (nonatomic, assign) CGPoint middlePoint; /**< 三角形中点位置 */
@property (nonatomic, assign) CGPoint endPoint; /**< 三角形结束位置 */
@property (nonatomic, strong) UITableView *tableView; /**< tableView */
```

##### 逻辑实现

###### 绘制**三角形**

利用 `CoreGraphic` 在 `drawRect:` 进行绘制三角形

```Objective-C
- (void)drawRect:(CGRect)rect {
    
    // 获取当前上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 起始位置
    CGContextMoveToPoint(context, self.startPoint.x, self.startPoint.y);
    // 中点位置
    CGContextAddLineToPoint(context, self.middlePoint.x, self.middlePoint.y);
    // 结束位置
    CGContextAddLineToPoint(context, self.endPoint.x, self.endPoint.y);
    CGContextClosePath(context);
    // 设置线的颜色
    [self.yxc_backgroundColor setStroke];
    // 设置填充颜色
    [self.yxc_backgroundColor setFill];
    // 绘画
    CGContextDrawPath(context, kCGPathFillStroke);
}
```

###### 展示逻辑

在 `showForm:` 方法中，进行逻辑操作，展示出效果

```Objective-C
- (void)showForm:(UIView *)view {
    
    // 在这里展示逻辑
    // 1. self 添加到一个 Windows 上面
    // 2. contentView 作为实际展示黑色部分
    // 3. 箭头的中心位置始终对着传入的 view 的中心 x
    // 4. contentView 的 x 如果超过界线,那么直接设置成界线值
    // 5. contentView 的 y 如果超过界线,那么将弹窗的方向改变,默认是在上面,如果 y 小于界限值,则弹窗在 view 的下方
    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        if (window.height == IPHONE_HEIGHT && window.width == IPHONE_WIDTH) {
            // 先将弹窗的大小,放入中间变量
            CGSize contentSize = self.size;
            // 将 self 的 frame 直接设置成 window 的 bounds
            // 为什么要这么做?
            // 为了实现点击位置在 contentView 外,移除当前界面(在这之前,直接使用一个 view 添加到 windows,然后再将 self 添加到 view 上面,并且给 view 增加了一个点击手势,最后发现 tableView 的点击方法不再调用,所以采用了这种方式)
            self.frame = window.bounds;
            // 设置 contentView 的 size
            self.contentView.size = CGSizeMake(contentSize.width, contentSize.height - self.triangleHeight);
            // 将传入的 view 进行坐标系转换,转换成相对于 Windows 的坐标
            CGRect convertFrame = [view convertRect:view.bounds toView:window];
            // 获取到传入的 view 在 Windows 上面的 centerX,作为三角形箭头的 centerX
            CGFloat centerX = convertFrame.size.width * 0.5 + convertFrame.origin.x;
            // 获取到 contentView 的 y 值
            CGFloat y = convertFrame.origin.y - contentSize.height - 2;
            // contentView 的 centerX 与 传入的 view 对齐
            self.contentView.centerX = centerX;
            CGFloat xGap = 5;
            // 判断当前 x 是否小于 xGap,如果小于 xGap ,x 直接设置成 xGap;
            if (self.contentView.x < xGap) {
                self.contentView.x = xGap;
            }
            // 判断当前视图右边是否超过 IPHONE_WIDTH - 20
            if (self.contentView.right > IPHONE_WIDTH - xGap) {
                self.contentView.right = IPHONE_WIDTH - xGap;
            }
            CGFloat yGap = 10;
            // 设置 Y 值
            self.contentView.y = y;
            // 判断当前 y 是否小于 yGap,如果小于 yGap,在下方显示
            if (self.contentView.y < yGap) {
                y = CGRectGetMaxY(convertFrame) + 2 + self.triangleHeight;
                self.contentView.y = y;
                // 计算三角形的三个点
                self.middlePoint  = CGPointMake(centerX, CGRectGetMaxY(convertFrame) + 2);
                self.startPoint = CGPointMake(centerX - self.triangleWidth * 0.5, self.middlePoint.y + self.triangleHeight);
                self.endPoint = CGPointMake(centerX + self.triangleWidth * 0.5, self.middlePoint.y + self.triangleHeight);
            } else {
                self.middlePoint = CGPointMake(centerX, convertFrame.origin.y - 2);
                self.startPoint = CGPointMake(centerX - self.triangleWidth * 0.5, self.middlePoint.y - self.triangleHeight);
                self.endPoint = CGPointMake(centerX + self.triangleWidth * 0.5, self.middlePoint.y - self.triangleHeight);
            }
            
            [window addSubview:self];
            return;
        }
        
    }
}
```

以上就是主要代码

看下效果

![三角箭头弹窗最终展示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/%E4%B8%89%E8%A7%92%E7%AE%AD%E5%A4%B4%E5%BC%B9%E7%AA%97%E6%9C%80%E7%BB%88%E5%B1%95%E7%A4%BA.gif)


最后附上 `.m` 代码

```Objective-C
//
//  YXCPopOverView.m
//  YXCTools
//
//  Created by GGT on 2020/10/23.
//  Copyright © 2020 GGT. All rights reserved.
//

#import "YXCPopOverView.h"

@interface YXCPopOverView ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *contentView; /**< 真实的黑色部分 view */
@property (nonatomic, strong) UIColor *yxc_backgroundColor; /**< 背景颜色 */
@property (nonatomic, assign) CGFloat triangleWidth; /**< 三角形宽度 */
@property (nonatomic, assign) CGFloat triangleHeight; /**< 三角形高度 */
@property (nonatomic, assign) CGPoint startPoint; /**< 三角形起始位置 */
@property (nonatomic, assign) CGPoint middlePoint; /**< 三角形中点位置 */
@property (nonatomic, assign) CGPoint endPoint; /**< 三角形结束位置 */
@property (nonatomic, strong) UITableView *tableView; /**< tableView */

@end

@implementation YXCPopOverView

#pragma mark - Lifecycle

/// 刷新UI
- (void)injected {
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.triangleWidth = 10.0f;
        self.triangleHeight = 10.0f;
        self.backgroundColor = UIColor.clearColor;
        self.yxc_backgroundColor = kColorFromHexCode(0x0E0F10);

        [self setupUI];
        [self setupConstraints];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // 获取当前上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 起始位置
    CGContextMoveToPoint(context, self.startPoint.x, self.startPoint.y);
    // 中点位置
    CGContextAddLineToPoint(context, self.middlePoint.x, self.middlePoint.y);
    // 结束位置
    CGContextAddLineToPoint(context, self.endPoint.x, self.endPoint.y);
    CGContextClosePath(context);
    // 设置线的颜色
    [self.yxc_backgroundColor setStroke];
    // 设置填充颜色
    [self.yxc_backgroundColor setFill];
    // 绘画
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self dismiss];
}

- (void)dealloc {
    
    YXCLog(@"%s", __func__);
}

#pragma mark - Custom Accessors (Setter 与 Getter 方法)


#pragma mark - IBActions


#pragma mark - Public

- (void)showForm:(UIView *)view {
    
    // 在这里展示逻辑
    // 1. self 添加到一个 Windows 上面
    // 2. contentView 作为实际展示黑色部分
    // 3. 箭头的中心位置始终对着传入的 view 的中心 x
    // 4. contentView 的 x 如果超过界线,那么直接设置成界线值
    // 5. contentView 的 y 如果超过界线,那么将弹窗的方向改变,默认是在上面,如果 y 小于界限值,则弹窗在 view 的下方
    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        if (window.height == IPHONE_HEIGHT && window.width == IPHONE_WIDTH) {
            // 先将弹窗的大小,放入中间变量
            CGSize contentSize = self.size;
            // 将 self 的 frame 直接设置成 window 的 bounds
            // 为什么要这么做?
            // 为了实现点击位置在 contentView 外,移除当前界面(在这之前,直接使用一个 view 添加到 windows,然后再将 self 添加到 view 上面,并且给 view 增加了一个点击手势,最后发现 tableView 的点击方法不再调用,所以采用了这种方式)
            self.frame = window.bounds;
            // 设置 contentView 的 size
            self.contentView.size = CGSizeMake(contentSize.width, contentSize.height - self.triangleHeight);
            // 将传入的 view 进行坐标系转换,转换成相对于 Windows 的坐标
            CGRect convertFrame = [view convertRect:view.bounds toView:window];
            // 获取到传入的 view 在 Windows 上面的 centerX,作为三角形箭头的 centerX
            CGFloat centerX = convertFrame.size.width * 0.5 + convertFrame.origin.x;
            // 获取到 contentView 的 y 值
            CGFloat y = convertFrame.origin.y - contentSize.height - 2;
            // contentView 的 centerX 与 传入的 view 对齐
            self.contentView.centerX = centerX;
            CGFloat xGap = 5;
            // 判断当前 x 是否小于 xGap,如果小于 xGap ,x 直接设置成 xGap;
            if (self.contentView.x < xGap) {
                self.contentView.x = xGap;
            }
            // 判断当前视图右边是否超过 IPHONE_WIDTH - 20
            if (self.contentView.right > IPHONE_WIDTH - xGap) {
                self.contentView.right = IPHONE_WIDTH - xGap;
            }
            CGFloat yGap = 10;
            // 设置 Y 值
            self.contentView.y = y;
            // 判断当前 y 是否小于 yGap,如果小于 yGap,在下方显示
            if (self.contentView.y < yGap) {
                y = CGRectGetMaxY(convertFrame) + 2 + self.triangleHeight;
                self.contentView.y = y;
                // 计算三角形的三个点
                self.middlePoint  = CGPointMake(centerX, CGRectGetMaxY(convertFrame) + 2);
                self.startPoint = CGPointMake(centerX - self.triangleWidth * 0.5, self.middlePoint.y + self.triangleHeight);
                self.endPoint = CGPointMake(centerX + self.triangleWidth * 0.5, self.middlePoint.y + self.triangleHeight);
            } else {
                self.middlePoint = CGPointMake(centerX, convertFrame.origin.y - 2);
                self.startPoint = CGPointMake(centerX - self.triangleWidth * 0.5, self.middlePoint.y - self.triangleHeight);
                self.endPoint = CGPointMake(centerX + self.triangleWidth * 0.5, self.middlePoint.y - self.triangleHeight);
            }
            
            [window addSubview:self];
            return;
        }
        
    }
}


#pragma mark - Private

- (void)dismiss {
    
    [self removeFromSuperview];
}


#pragma mark - Protocol

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = UIColor.whiteColor;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YXCLog(@"%s", __func__);
}

#pragma mark - UI

- (void)setupUI {
    
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = self.yxc_backgroundColor;
    self.contentView.layer.cornerRadius = 10.0f;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.clipsToBounds = YES;
    [self addSubview:self.contentView];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.rowHeight = 30;
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"Cell"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.tableView];
}


#pragma mark - Constraints

- (void)setupConstraints {
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}


#pragma mark - 懒加载

@end

```
