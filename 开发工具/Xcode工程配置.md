[toc]

### 1. pch 文件配置
1. `target` → `Build Settings` → 搜索 `Prefix Header`
2. 设置 `Precomile Prefix Header` 为 `YES`
3. 设置 `Prefix Header` 为 `pch` 文件路径.(最好的方式是通过 `$(SRCROOT)`来获取当前工程的绝对路径,以便于多人合作,拉取代码后运行找不到 `pch` 文件)

![设置 PCH 文件](https://raw.githubusercontent.com/guoguangtao/VSCodePicGoImages/master/20200806141221.png)

### 2.代码块路径

```
~/Library/Developer/Xcode/UserData/CodeSnippets
```