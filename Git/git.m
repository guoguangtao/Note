
#pragma mark - git 普通操作
// 查看git版本（MacPro Xcode自带git）
1.$ git version

// 设置电脑git账号和邮箱
2.$ git config --global user.name "Your Name"
  $ git config --global user.email "email@example.com"

3.$ mkdir learngit   /**< 创建一个文件名为learngit的文件夹 */
  $ cd learngit      /**< 打开文件夹 */
  $ pwd              /**< 查看learngit文件路径 */

#pragma mark - 创建版本库
4.$ git init         /**< 创建一个git仓库 */
  Initialized empty Git repository in /Users/michael/learngit/.git/  /**< 这个仓库为空 */

// 把文件（文件夹）添加到仓库（一定要放在同一个目录下），没有任何显示代表添加成功
5.$ git add readme.txt

// 提交到仓库中 "wrote a readme file" 代表的是本次提交的说明，也可以多次 add 不同文件再commit
6.$ git commit -m "wrote a readme file"

// 查看当前仓库的状态（有没有修改、删除、增加等操作）
7.$ git status

// 查看 readme.txt 的修改部分
8.$ git diff readme.txt

// 查看从最近到以前的提交日志（信息多行）
9.$ git log

// 查看从最近到以前的提交日志（信息只有一行）
10.$ git log --pretty=oneline

#pragma mark - 版本回退
// 在Git中，用HEAD表示当前版本，也就是最新的提交，上一个版本就是HEAD^，上上一个版本就是HEAD^^，当然往上100个版本写100个^比较容易数不过来，所以写成HEAD~100
11.$ git reset --hard HEAD^

// 指定回到哪个版本
12.$ git reset --hard 3628164

// 查看 readme.txt 文件内容
13.$ cat readme.txt

// 查看每一次git操作命令
14.$ git reflog

#pragma mark - 撤销修改
/**
 把 readme.txt文件在工作区的修改全部撤销，这里有两种情况：一种是readme.txt自修改后还没有被放到暂存区，现在，撤销修改就回到和版本库一模一样的状态；一种是readme.txt已经添加到暂存区后，又作了修改，现在，撤销修改就回到添加到暂存区后的状态。总之，就是让这个文件回到最近一次git commit或git add时的状态。
 */
15.$ git checkout -- readme.txt

#pragma mark - 删除文件
/**
 当在文件夹中删除了某个文件时，确实要从版本库中删除该文件，就用 git rm 删掉，并且 git commit 提交
 */
16.$ git rm test.txt

/** 
 当在文件夹中删错了某个文件时，因为版本库里还有该文件，可以通过此命令把误删的文件恢复到最新版本（其实就是用版本库里的版本替换工作区的版本）
 */
17.$ git checkout -- test.txt

#pragma mark - 远程仓库

// 第1步：创建SSH Key。在用户主目录下，看看有没有.ssh目录，如果有，再看看这个目录下有没有id_rsa和id_rsa.pub这两个文件，如果已经有了，可直接跳到下一步。如果没有，打开Shell（Windows下打开Git Bash），创建SSH Key;如果一切顺利的话，可以在用户主目录里找到.ssh目录，里面有id_rsa和id_rsa.pub两个文件，这两个就是SSH Key的秘钥对，id_rsa是私钥，不能泄露出去，id_rsa.pub是公钥，可以放心地告诉任何人. 第2步：登录Github，在SSH Keys 页面 Add SSH Key,在key文本框里粘贴id_rsa.pub文件内容
18.$ ssh-keygen -t rsa -C "youremail@example.com"

#pragma mark - 添加远程仓库

/**
 1.先在Github创建repository（新仓库）
 2.在本地的仓库下运行命令 michaelliao 为自己的Github账户名 origin就是远程库的名字
 */
19.$ git remote add origin git@github.com:michaelliao/learngit.git

/**
 将本地的所有内容推送到远程库上，由于远程库是空的，我们第一次推送master分支时，加上了-u参数，Git不但会把本地的master分支内容推送的远程新的master分支，还会把本地的master分支和远程的master分支关联起来，在以后的推送或者拉取时就可以简化命令。
 
 error:src refspec master does not match any 
 产生这个原因是因为git所在的这个目录中没有文件，空目录是不能提交成功
 */
20.$ git push -u origin master

/**
 通过上述操作，以后本地做了git提交，就可以通过这个命令推送到远程库上
 */
21.$ git push origin master


#pragma mark - 从远程库克隆

/**
 michaelliao:Github账户名
 */
22.$ git clone git@github.com:michaelliao/gitskills.git

#pragma mark - 创建与合并分支

/**
 创建名为Dev分支，然后切换到Dev分支（Dev可以自己命名）
 git checkout命令加上-b参数表示创建并切换，相当于以下两条命令:
 $ git branch dev
 $ git checkout dev
 */
23.$ git checkout -b dev

/**
 查看当前分支
 */
24.$ git branch

/**
 切换分支
 */
25.$ git checkout master

/**
 把dev分支的工作成果合并到master分支上
 */
26.$ git merge dev (使用 rebase 方式:切换到需要合并到的分支, git rebase 需要合并的分支名)

/**
 删除分支
 
 1.查看分支：git branch
 
 2.创建分支：git branch <name>
 
 3.切换分支：git checkout <name>
 
 4.创建+切换分支：git checkout -b <name>
 
 5.合并某分支到当前分支：git merge <name>
 
 6.删除分支：git branch -d <name>
 
 7.删除远程分支：$ git push origin --delete <branchName>
 */
27.$ git branch -d dev

/**
 移除本地远程仓库，添加远程仓库地址
 */
28.$ git remote rm origin
29.$ git remote add origin git@github.com:shuai214/XIBTest.git

/**
 切换远程仓库后，关联远程分支
 */
29.$ git branch --set-upstream-to=origin/<#branch#> develop

#pragma mark - 解决冲突

/**
 示例：
 $ git merge feature1
 Auto-merging readme.txt
 CONFLICT (content): Merge conflict in readme.txt（在readme.txt中合并产生冲突）
 Automatic merge failed; fix conflicts and then commit the result.
 */


#pragma mark - github 客户端合并代码步骤

1.首先切换到 develop 分支,然后同步代码(Syncing),合并分支(Branch → Merge into "develop" → 选择分支来源(自己所要合并的分支) → Merge → 有冲突解决冲突,没有冲突,先运行程序,看看是否能 Build Success → Syncing(提交到远程仓库中))

#pragma mark - tag

1.git checkout -b branch_name tag_name   从 tag 标签开个分支出来


2.删除本地tag  git tag -d tag_name

3.删除远程 tag git push origin --delete tag tag_name

4.创建标签 git tag tag_name 或者 git tag -a tag_name -m "标签描述"

5.推送一个本地标签 git push origin tag_name

6.推送全部未推送过的本地标签 git push origin --tags


#pragma mark - 指定分支克隆远程代码

1. git clone -b 分支名称 远程代码地址

##pragma mark - stash

1.将工作内容暂时保存
2.不需要的话 直接 git stash clear


#pragma mark - 错误

1.The following untracked working tree files would be overwritten by checkout

   使用指令 git clean -d -fx（删除 一些 没有 git add 的 文件）
