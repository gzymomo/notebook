- [研发团队如何借助Gitlab来做代码review](https://www.cnblogs.com/spec-dog/p/11050013.html)

代码review是代码质量保障的手段之一，同时开发成员之间代码review也是一种技术交流的方式，虽然会占用一些时间，但对团队而言，总体是个利大于弊的事情。如何借助现有工具在团队内部形成代码review的流程与规范，是team leader或技术管理者需要考虑的问题。本文分享一种基于Gitlab代码merge流程的code  review方法，以供参考与探讨。如有更好的方法，欢迎交流。

## 1. 设置成员角色

首先需要对你团队的成员分配角色，在Gitlab groups里选择一个group，然后左边菜单栏点击 Members，可在 Members 页面添加或编辑成员角色，如下图所示。

 ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729184659096-570185673.png)

其中角色包含如下几类：

- Guest：权限最小，基本查看功能
- Reporter：只能查看，不能push
- Developer：能push，也能merge不受限制的分支
- Master：除了项目的迁移、删除等管理权限没有，其它权限基本都有
- Owner：权限最大，包括项目的迁移、删除等管理权限

详细权限参考： https://docs.gitlab.com/ee/user/permissions.html

确定团队中技术水平、经验较好的成员为Master，负责代码的review与分支的合并；其他成员为Developer，提交合并请求，接受review意见；Master之间可以互相review。

## 2. 配置分支保护

在项目页面左侧菜单栏 Settings -> Repository， 进入“Protected Branches”部分配置分支保护，如下图所示。
![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729184731748-1863127419.png)

在这里可以针对每个分支，设置允许什么角色可以merge，允许什么角色可以push，选项包括三个：“Masters”，  “Developers + Masters”， “No  one”。这里设置成只允许master可以直接push与merge这几个常设分支的代码。（如果更严格一点，可以将“Allowed to  push”设置成“No one”）

## 3. 代码review流程

### 3.1. 开发（开发者负责）

1. 本地切到develop分支， 拉取最新代码（相关命令如下，GUI工具操作自行查相关文档）

   ```
   git branch #查看当前位于哪个分支，前面打星号即为当前分支
   git checkout develop   #切换到develop分支
   git pull  #拉取最新代码
   ```

1. 从develop分支切出子分支

   ```
   git checkout -b feature-1101  #从当前分支切出子分支，命名为"feature-1101"
   ```

1. 编码、本地自测完之后，提交子分支到远程仓库

   ```
   git add *  #加入暂存区
   git commit -m "commit msg" #提交到本地仓库
   git push origin feature-1101 #提交到远程仓库
   ```

### 3.2 发起Merge请求（开发者负责）

1.  在项目主页面，依次点击左侧“Merge Requests”（下图1），“New merge request”（下图2），打开新建Merge请求页面3.2 发起Merge请求（开发者负责）
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729184809061-92910467.png)

 

1. 在新建Merge请求页面，选择merge的源分支，及目标分支，如下图源分支为“feature-1101”，目标分支为“develop”，点击“Compare branches and continue”按钮进入对比与提交页面
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729184837259-1551426251.png)

 

1. 在对比与提交页面，可以点击“Changes” tab查看本次修改（这里我为了演示，只是加了两个换行），确认无误，点击“Submit merge request”按钮，提交merge请求
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729184854196-522134385.png)

1. 提交之后，将结果页面的浏览器地址发到团队即时通讯群（如钉钉），并@相应的同事申请review

### 3.3 代码Review（code reviewer负责）

1. 负责代码Review的同事收到申请后，点击merge请求地址，打开页面，查看“Changes”。这里可通过“Inline”单边查看，也可以通过“Side-by-side”两个版本对比查看
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729184916176-1290718932.png)

 

1. review完成后，若无问题，则可点击”Merge”按钮完成merge，同时可删除对应的子分支“feature-1101”；若有问题，则可点击“Close merge  request”按钮关闭该merge请求（也可以不关闭复用该merge请求），同时通知开发者进行相应调整，重新提交代码发起merge请求（如果之前没关闭merge请求，则刷新即可看到调整）。

### 3.4 冲突解决（开发者负责）

1. merge的时候，可能存在代码冲突，这时，开发者可从develop分支重新拉取最新代码进行本地merge， 解决冲突后重新提交代码进行review

   ```
   git pull origin develop #在当前子分支拉取develop分支的最新代码进行本地merge
   
   # 解决冲突代码
   
   # 提交
   git add *
   git commit -m "fix merge conflict"
   git push origin feature-1101
   ```

1. 自行解决不了时，寻求协助

## 4. 借助阿里钉钉机器人来改善体验

前面流程中提醒code reviewer是需要开发者自己来发消息通知的，可不可以把这个流程自动化。我们可以借助Gitlab的webhook与钉钉机器人来实现。

1. 在钉钉群右上角点击“…”，打开群设置，群机器人中点击添加机器人，会显示可以添加的机器人类型，如下图所示
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729185000651-337577025.png)

1. 选择Gitlab，点击添加，输入机器人名称，如“Gitlab”，点击完成即创建了一个Gitlab的钉钉机器人。回到“群机器人”窗口，将能看到刚刚创建的Gitlab机器人，如图
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729185017386-1646973269.png)

   点击齿轮按钮，进入设置页，可看到webhook地址，点击复制，复制该机器人的webhook地址。如图
     ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729185030311-1348957970.png)

1. 在Gitlab项目主页进入 Settings -> Integrations，  将前面复制的webhook地址填入URL中，Trigger 部分选择“Merge request  events”（不要勾太多，不然提醒太多就有点骚扰了），然后点击“Add webhook”就完成了。如图
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729190552137-2113483658.png)

1. 当有开发人员提交merge请求时，钉钉机器人将在钉钉群里发出通知，code reviewer点击消息里的链接即可进入页面进行code  review， review完成，将分支merge之后，钉钉机器人也会发出消息（所有merge相关的事件都会发出消息）。如图
   ![img](https://img2018.cnblogs.com/blog/632381/201907/632381-20190729190628496-1234331237.png)

## 5. 总结

团队协作，流程、规范很重要，不同的团队可能有不同的适用流程与规范。此文分享了基于Gitlab与阿里钉钉群机器人的代码review流程，希望对团队研发协作有一定参考价值，也欢迎一起探讨、交流。