- [刚进公司，不懂GIt工作流的我瑟瑟发抖](https://www.cnblogs.com/YLTFY1998/p/15821130.html)

## 前言

> 不懂git工作流，被辞退了！

之前在看到这句话的时候，我刚实习入职不久，瑟瑟发抖。好巧不巧，今天又看到了类似的文章讲git重要性的。

![image-20220118135322392](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118135322392.png)

眼下，学校导师安排给我的课题组了一个新的工程项目，使用gitee维护，因此我打算写一篇文章总结一下git的工作流（**git工作流就是指单人/多人团队如何使用git命令配合维护一个项目的一些约定的流程，在确保有效迭代的同时，保持高效的协作方式**），相信可以帮助那些使用git停留在单人维护远程`master`分支的同学更进一步。

![image-20220118113156944](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118113156944.png)

下面会讲解**四种git工作流**，无论是在校课题组还是公司内部，都可以以此为基础找到合适的git团队工作模式。

## Centralized Workflow 集中式工作流

### 介绍

![image-20220118120940091](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118120940091.png)

三个开发人员共同维护一份远程仓库的代码，工作方式如下：

1. 每次工作前从`remote`拉取`master`分支到本地的`master`分支，然后处理冲突（使用IDE自带的**GUI图形用户界面**处理冲突会比较方便，如图中的goland内置的git工具）

   ![image-20220118121723074](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118121723074.png)

2. 接着开始编码，编码完成后`add`修改的文件到缓冲区

3. `commit`缓冲区文件到自己`local`仓库，并且`push`本地仓库文件到`remote`仓库

### 评价

**集中式工作流**：这种工作方式简单粗暴，所有人只使用`master`分支维护项目，`master`永远是项目最新版本，编码比较快，立竿见影。但是所有开发者提交日志集中在一起呈单线延伸，难以定位问题，分工不明确，且容易发生冲突，处理冲突成本上升，但是单人开发很便利。

## Feature Branch Workflow 功能分支工作流

### 介绍

![image-20220118164211461](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118164211461.png)

**功能分支工作流**以集中式工作流为基础，在维护`master`分支的基础上，将项目的开发工作拆分为添加一个个的`feature`的形式，工作方式如下：

1. 一旦需要开发新的功能，就在`remote`的`master`分支的基础上创建一个`feature xxx`分支

2. 本地创建对应的`feature xxx`分支

3. 每次开发前将`remote库`的`feature xxx`分支拉取到本地，处理冲突

4. 然后在本地`feature xxx`分支上开发，然后`push`到remote的`feature xxx`分支

5. 在项目主页上发起`pull request`（如果是gitlab则是`merge request`，作用相同），本意是提出将`feature xxx`分支合并入`master`分支的请求

   ![image-20220118163039576](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118163039576.png)

6. 然后你的代码会被review，没通过就本地改，改完之后继续`push`到`remote`（两头都在feature xxx分支），然后负责人继续review你这个PR或者MR，通过之后会将`feature xxx`分支**区别于master的改动**合并入`master`，删除remote的`feature xxx`分支，代表这个功能开发完毕

### 评价

**功能分支工作流**：这种工作方式带来了`code review`的功能，使得推送的代码更符合规范，减少bug产生。并且因为主要还是在master分支基础上根据功能需求创建feature分支，使得开发工作十分灵活，且各个**功能之间隔离**，但是对于大型项目而言**需要为不同分支分配更加具体的角色，只有feature分支是不够的**。

## Gitflow Workflow

### 介绍

![image-20220118190551888](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118190551888.png)

**Gitflow工作流**是我目前尚在熟悉的一种工作流，也是目前非常成熟的git工作流方案。区别于功能分支工作流，**Gitflow工作流**划分分支更有约束性。主要包括：

1. **主分支master**：用于跟踪项目正式发布的版本（tag标签号）
2. **开发分支dev**：用于跟踪代码研发的提交历史
3. **功能研发分支feature**：每次有新的功能需要研发，以`dev`分支为基础，建立`feature`分支，开发完成后按上面**feature branch**工作流的方式提交PR/MR到remote的`dev`分支，完成之后删除对应`feature`分支
4. **热修复分支hotfix**：如上图所示，`master`分支出现bug（线上报bug了），需要马上从master拉取一个`hotfix`分支处理修复bug，并且将代码合并到`master和dev`（这两个分支需要保持bug修复的一致性），修复后给master当前提交打一个`tag（v0.2）`
5. **发布分支release**：在`dev`基础上建立`release`分支，处理一些问题、修复一些bug之后，将代码合并入`master与dev`，并给master打上`tag（v1.0）`表示发布完成

### 评价

约束性更强，发布迭代流程更规范，严谨，开发人员分工更明确，十分推荐学习使用。

## Forking Workflow

### 介绍

![image-20220118201450505](https://gitee.com/yltfy1998/blog-images/raw/master/image-20220118201450505.png)

这种工作流是开源项目维护的工作流，暂作了解即可，通过将他人的项目`fork`到自己的`remote`仓库，就可以将其作为自己拥有的一份副本进行开发，比如想增加一个功能或者修复一个bug。这里A与C都`fork`了B的仓库，在各自开发完成新功能之后可以`提交PR`给B仓库，B仓库的开发者负责`review`代码，并接受PR。

### 评价

具体还未尝试过提交PR给开源项目，但是相信在掌握了上述三个git工作流之后，以后要使用到forking工作流的问题也应该引刃而解。

## 结束

学习了**四种git工作流**之后，并不是要完全照搬某一个模式的所有使用流程，而是应该结合实际的项目规模和人员规模进行合理安排。比如对于校内课题组较小的项目我认为`feature branch`工作流应该足以胜任，或者使用只有`master`、`dev`、`feature`的简化版**Gitflow工作流**。