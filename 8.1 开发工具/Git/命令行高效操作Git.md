- [命令行高效操作Git，看这篇就够了](https://www.cnblogs.com/spec-dog/p/11037743.html)

对于软件开发人员来说，git几乎是每天都需要接触的工具。但对于相处如此亲密的工作伙伴，你对它的了解又有多少，是不是还在傻瓜式地打开一个GUI工具，点击提交按钮，然后“卧槽，又冲突了”，一脸懵逼到不知所措，责怪谁又在你前面提交了，谁又改了你的代码。

博主从一开始接触git，就没用过任何GUI工具，都是通过命令行进行操作，发现这种方式不仅对git的理解更深，效率也更高，遇到问题时一般都知道如何来处理，故做此分享。本文所有知识与操作只涉及日常使用场景，更多详细内容可自行查阅其它资料。本文Git版本为 windows-2.20.1版。

### 基础理论

git的理论知识，对使用者来说只需要知道它是分布式版本控制系统，了解如下三个概念即可，

- 工作区：就是你直接操作的文件目录与内容
- 暂存区：暂时为你保存还没将内容提交到版本库的一个区域，对应.git目录下的stage或index文件
- 版本库：分本地版本库与远程版本库，本地版本库就理解为对应.git目录即可，远程版本库就是远程仓库，如gitlab或github的repository。

如下图，我们平时提交代码的过程基本都是从工作区`add`到暂存区，然后再`commit`到本地仓库，最后`push`到远程仓库。

![image-20220212094619540](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220212094619540.png)

### 基本命令

对于日常工作，掌握如下几个基本命令一般就够了

- `git status` 查看修改状态
- `git pull origin master` 拉取远程仓库master分支合并到本地，master根据场景换成其它分支名
- `git add file` 添加文件到暂存区，可用 * 添加所有
- `git commit -m "commit message"` 提交到本地版本库，并添加注释，注释表明此次修改内容，要清晰准确
- `git push origin master` 将本地版本提交到远程仓库的master分支，master根据场景换成其它分支名

对大部分日常工作来说， 上面几个命令基本就够用了。

### 新建项目

**1. 从本地到远程**

项目开发的时候，有时候是先在本地建一个项目，再提交到远程仓库的。

1. 创建项目目录（或通过IDE创建），命令行cd到项目目录
2. 执行`git init` ， 将在项目目录创建.git目录
3. 执行`git add *` ，将所有文件添加到暂存区，这里要先创建一个.gitignore文件，将不需要版本维护的文件添加进去忽略，不然各种IDE编译文件夹，环境相关文件都加到版本库去了。删除文件用`git rm file_name`
4. 执行`git commit -m "upload project"` ，提交到本地仓库
5. 在gitlab或github上创建一个仓库，并将仓库地址复制下来
6. 执行`git remote add origin git@server-name:path/repo-name.git` ，关联远程仓库，仓库地址如果是http开头则要用户名密码，如果是git开头，则是走的ssh协议，需要将你本机的ssh公钥添加到远程仓库服务上。
7. 执行`git push -u origin master` ，推送本地仓库内容到远程仓库

这样在远程仓库目录，就能看到你提交上去的文件内容了。

**2. 从远程到本地**
更多的时候，是远程仓库已有项目了，需要下载到本地开发。

1. `git clone git@server-name:path/repo-name.git` ， 将远程仓库的内容下载到本地，这里仓库地址的处理同上
2. 修改内容
3. `git add *` ，将修改的内容添加到暂存区
4. `git commit -m "fix xxx issue"` ，提交到本地仓库
5. `git push -u origin master` ， 推送本地仓库内容至远程仓库

### 版本回退

有时候改了文件，想反悔怎么办，git给你“后悔药”。

单个文件的还原：

- `git checkout file_name` ，丢弃工作区的修改，还原到上次提交（commit）的版本，
- `git reset HEAD file_name` ，把暂存区的修改撤销掉（unstage），重新放回工作区。即还原到上次添加到暂存区（add）的版本

这里涉及几个场景

- 场景1：当你改乱了工作区某个文件的内容，想直接丢弃工作区的修改时，用命令`git checkout file_name`。
- 场景2：当你不但改乱了工作区某个文件的内容，还添加到了暂存区时（执行了add，但没执行commit），想丢弃修改，分两步，第一步用命令`git reset HEAD file_name`，就回到了场景1，第二步按场景1操作。
- 场景3：已经提交了不合适的修改到版本库时，想要撤销本次的全部提交，参考下面的整个版本的还原，不过前提是没有推送到远程库。

整个版本的还原：

- `git reset --hard HEAD^^`， 回退到上上个版本
- `git reset --hard 3628164`， 回退到具体某个版本 3628164 是具体某个commit_id缩写

> 找不到commit_id？ `git reflog` 可查看每一个命令的历史记录，获取对应操作的commit_id。`git log [--pretty=oneline]`， 可查看commit记录

> 上一个版本就是HEAD^，上上一个版本就是HEAD^^，往上100个版本写成HEAD~100。3628164  是具体某个commit_id，不需要写全，只需要唯一确定就行，可往前进也可往后退。（git  windows2.20.1版貌似不支持对HEAD^的操作）

### 多人协作

1. 首先，可以试图用 `git push origin branch_name` 推送自己的修改；
2. 如果推送失败，则因为远程分支比你的本地更新，需要先用 `git pull` 试图合并；
3. 如果合并有冲突，则手动解决冲突，并在本地提交；
4. 没有冲突或者解决掉冲突后，再用 `git push origin branch-name` 推送就能成功！

### 分支管理

平时开发时需要创建子分支来实现你的功能模块，然后再合并到主分支中。

- `git checkout -b your_branch_name` ， 创建并切换分支
- `git branch` ， 查看分支，标有*号表示当前所在分支
- `git merge dev` ， 合并指定dev分支到当前分支
- `git merge --no-ff -m "merge with no-ff" dev` ， 合并分支并生成commit记录
- `git branch -d dev` ， 删除分支

> ```
> git checkout -b dev = git branch dev + git checkout dev
> ```

> Fast-forward合并，“快进模式”，也就是直接把master指向dev的当前提交，所以合并速度非常快。存在冲突的不能fast forward。`git merge --no-ff -m "merge with no-ff" dev` Fast forward模式下，删除分支后，会丢掉分支信息。如果强制禁用Fast forward模式，Git就会在merge时生成一个新的commit，这样，从分支历史上就可以看出分支信息

### 标签管理

当发布版本时，一般需要对当前版本进行标签记录，以便后续进行版本查看或回退。

- `git tag tag_name` ， 对当前分支打标签
- `git tag` ， 查看所有标签
- `git tag v0.9 6224937` ，针对某个具体commit id打标签
- `git show tag_name` ， 查看标签信息
- `git tag -a v0.1 -m "version 0.1 released" 3628164` ， 带有说明的标签
- `git tag -d v0.1` ， 删除标签
- `git push origin tag_name` ， 推送标签到远程
- `git push origin --tags` ， 一次性推送所有标签

删除已经推送到远程的标签：

- `git tag -d v0.9` ， 先本地删除
- `git push origin :refs/tags/v0.9` ， 然后从远程删除

### 提高效率的Tips

1. 配置命令别名

   ```
   git config --global alias.st status # 后面可以用git st 来代替git status了
   git config --global alias.ck checkout  # 后面可以用 git ck 来代替 git checkout了
   git config --global alias.cm 'commit -m' # 后面可以用git cm 来代替 git commit -m 了
   ```

2. `git pull origin master` 或 `git push origin master`， 可直接 `git pull` 或 `git push`， 如果出现“no tracking information”的提示，则说明本地分支和远程分支的链接关系没有创建，用命令 `git branch --set-upstream-to=origin/master master` 建立关联即可。