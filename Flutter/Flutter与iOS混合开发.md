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

### 5. iOS 与 Flutter 的通信(界面跳转)

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

@property (nonatomic, strong) FlutterMethodChannel *messageChannel;
@property (nonatomic, strong) UILabel *resultLabel;

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

    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 250, self.view.bounds.size.width, 50)];
    self.resultLabel.font = [UIFont systemFontOfSize:14.0f];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.resultLabel];
}

- (void)buttonClicked {
    
    // 获取全局的 flutterEngine,防止跳转的时候卡顿
    FlutterEngine *flutterEngine = ((AppDelegate *)UIApplication.sharedApplication.delegate).flutterEngine;
    // 跳转的界面控制器
    FlutterViewController *flutterController = [[FlutterViewController alloc] initWithEngine:flutterEngine nibName:nil bundle:nil];
    // 设置标记,需要跟 dart 中的 main.dart 一致
    NSString *channelName = @"com.pages.your/native_get";
    // 创建 FlutterMethodChannel
    _messageChannel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:flutterController.binaryMessenger];
    // 设置当前 FlutterMethodChannel 的方法名和需要传递过去的参数
    [_messageChannel invokeMethod:@"NativeToFlutter" arguments:@[@"原生调用Flutter参数1", @"原生调用Flutter参数2"]];
    // 跳转界面
    [self.navigationController pushViewController:flutterController animated:YES];
    // Flutter 回调
    __weak typeof(self) weakSelf = self;
    [_messageChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [flutterController.navigationController popViewControllerAnimated:YES];
        NSArray *array = (NSArray *)call.arguments;
        NSMutableString *mutableString = [NSMutableString string];
        for (NSString *string in array) {
            [mutableString appendFormat:@"%@ ", string];
        }
        weakSelf.resultLabel.text = mutableString;
    }];
}
```

**Dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: _HomePage()
    );
  }
}

class _HomePage extends StatefulWidget {
  @override
  __HomePageState createState() => __HomePageState();
}

class __HomePageState extends State<_HomePage> {

  String title = "Flutter to Native";
  Color backgroundColor = Colors.red;
  // 创建 MethodChannel 这里的标志跟 ios 中设置要一致
  static const MethodChannel methodChannel = const MethodChannel('com.pages.your/native_get');
  // Flutter 调用原生
  _iOSPushToVC() {
    methodChannel.invokeMethod('FlutterToNative', ["Flutter 调用原生参数 1", "Flutter 调用原生参数 2"]);
  }

  @override
  void initState() {
    super.initState();
    // 设置原生调用 Flutter 回调,获取到方法名和参数
    methodChannel.setMethodCallHandler((MethodCall call){
      if (call.method == "NativeToFlutter") {
        setState(() {
          List<dynamic> arguments = call.arguments;
          String str = "";
          for (dynamic string in arguments) {
            str = str + " " + string;
          }
          title = str;
          backgroundColor = Colors.orange;
        });
      }
      return Future<dynamic>.value();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Text(title),
          onTap: (){
            _iOSPushToVC();
          },
        ),
      ),
    );
  }
}
```

运行结果为:

![iOS与Flutter通信](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/iOS%E4%B8%8EFlutter%E9%80%9A%E4%BF%A1.gif)


这样一个原生与 `Flutter` 的通信就完成了,原生调用 `Flutter` 界面并且传递参数过去,`Flutter` 回到原生带回参数.

### 6. 热加载

1. 关闭 `App`
2. 在 `terminal` 中运行 `flutter attach` 命令。(**这里需要进入到 Flutter module 工程路径,不然会报找不到 lib/main.dart 错误**)

    2.1 如果当前有多台设备,会出现如下提示

   ![多台设备提示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200814161736.png)

   2.2 使用以下命令

   ```
   flutter attach -d {设备标识}
   ```

   2.3 启动 `App`

   ![启动 App 之后,终端显示](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200814162103.png)

   2.4 这样就可以在终端使用热加载了

    ```
    r : 热加载；
    R : 热重启；
    h : 获取帮助；
    d : 断开连接；
    q : 退出
    ```

