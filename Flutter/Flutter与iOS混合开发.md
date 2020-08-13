[toc]

### 1.系统要求
* 安装了 `Flutter`
* 安装了 `Xcode`

### 2.创建 `Flutter module`

1. 终端进入某个路径,创建 `Flutter module`
```shell
cd some/path/
flutter create --template module {moduleName}
```
运行结果:
![创建 module 结果](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200807160637.png)

这样就创建了一个 名为 `my_flutter` 的 `Flutter module` 项目

![my_flutter 目录结构](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200807161048.png)

### 3.创建一个 `iOS` 工程
创建一个名为 `MyApp` 的 `iOS` 工程项目,创建的路径最好跟创建的`Flutter module`在同一个路径下面

### 4.在现有应用程序中嵌入 `Flutter module`
有两种方法嵌入`module`到现有的应用程序中

1. 使用 `CocoaPods` 依赖管理器和已安装的 `Flutter SDK`(官网推荐使用该方式,在这里也只介绍这一种方式)
2. 通过手动编译 `Flutter engine`、`dart`代码和所有 `Flutter plugin` 成 `framework`,用 `Xcode` 手动集成到你的应用中,并更新编译设置([官网介绍](https://flutter.dev/docs/development/add-to-app/ios/project-setup))

#### 4.1 使用 `CocoaPods` 方式
1. 给现有的 `MyApp` 创建一个 `Podfile`,并且在里面加入以下代码
    ```Objective-C

    platform :ios,'10.0'
    inhibit_all_warnings!

    # flutter module 文件路径
    flutter_application_path = '../my_flutter' 
    load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')


    target 'MyApp' do
    
    install_all_flutter_pods(flutter_application_path)

    end
    ``` 

2. 执行 `pod install`
![执行 pod install 结果](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200807163711.png)

### 5. `OC` 调用 `Flutter` 界面

为了在既有的`iOS`应用中展示`Flutter`页面，需要启动 `Flutter Engine` 和 `FlutterViewController`,通常建议为我们的应用预热一个长时间存活的 `FlutterEngine`,我们将在应用启动的 `appdelegate` 中创建一个 `FlutterEngine`，并作为属性暴露给外界.

**AppDelegate.h**

```Objective-C
@import UIKit;
@import Flutter;

@interface AppDelegate : FlutterAppDelegate

@property (nonatomic, strong) FlutterEngine *flutterEngine;

@end
```

**AppDelegate.m**

```Objective-C
#import "AppDelegate.h"
#import <FlutterPluginRegistrant/GeneratedPluginRegistrant.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    
    self.flutterEngine = [[FlutterEngine alloc] initWithName:@"my flutter engine"];
    [self.flutterEngine run];
    [GeneratedPluginRegistrant registerWithRegistry:self.flutterEngine];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
```

下面的示例显示一个通用的 `ViewController`，其中有一个 `UIButton` 用于显示 `FlutterViewController`。`FlutterViewController` 使用在 `AppDelegate` 中创建的 `FlutterEngine` 实例。

**ViewController.m**

```Objective-C
#import "ViewController.h"
#import "AppDelegate.h"
@import Flutter;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton new];
    button.backgroundColor = UIColor.blueColor;
    button.frame = CGRectMake(80, 210, 160, 40);
    [button addTarget:self
               action:@selector(buttonClicked)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"OC 调用 Flutter" forState:UIControlStateNormal];
    [self.view addSubview:button];
}

- (void)buttonClicked {
    
    FlutterEngine *flutterEngine = ((AppDelegate *)UIApplication.sharedApplication.delegate).flutterEngine;
    FlutterViewController *flutterViewController = [[FlutterViewController alloc] initWithEngine:flutterEngine
                                                                                         nibName:nil
                                                                                          bundle:nil];
    [self presentViewController:flutterViewController
                       animated:YES
                     completion:nil];
}
```

这样就在 `iOS` 工程调用了 `Flutter` 界面.

![OC调用Flutter界面](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/OC%E8%B0%83%E7%94%A8Flutter%E7%95%8C%E9%9D%A2.gif)

