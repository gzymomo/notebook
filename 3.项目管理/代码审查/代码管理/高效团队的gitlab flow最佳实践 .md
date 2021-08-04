- [高效团队的gitlab flow最佳实践](https://www.cnblogs.com/xiaoqi/p/gitlab-flow.html)             



当前git是大部分开发团队的首选版本管理工具，一个好的流程规范可以让大家有效地合作，像流水线一样有条不紊地进行团队协作。

业界包含三种flow：

- Git flow
- Github flow
- Gitlab flow

下面我们先来分析，然后再基于gitlab flow来设计一个适合我们团队的git规范。

## 从git flow到gitlab flow

### git flow

先说git flow，大概是这样的。

![gitflow](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612267487337.png)

然后，我们老的git规范是参考git flow实现的。

![当前git流程](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612267545738.png)

综合考虑了开发、测试、新功能开发、临时需求、热修复，理想很丰满，现实很骨干，这一套运行起来实在是太复杂了。那么如何精简流程呢？

我们来看业界的做法，首先是github flow。

### github flow

Github flow 是Git flow的简化版，专门配合”持续发布”。它是 Github.com 使用的工作流程。

![github flow](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612267831741.png)

整个流程：

![流程](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612267888369.png)

- 第一步：根据需求，从master拉出新分支，不区分功能分支或补丁分支。
- 第二步：新分支开发完成后，或者需要讨论的时候，就向master发起一个pull request（简称PR）。
- 第三步：Pull Request既是一个通知，让别人注意到你的请求，又是一种对话机制，大家一起评审和讨论你的代码。对话过程中，你还可以不断提交代码。
- 第四步：你的Pull Request被接受，合并进master，重新部署后，原来你拉出来的那个分支就被删除。（先部署再合并也可。）

github flow这种方式，要保证高质量，对于贡献者的素质要求很高，换句话说，如果代码贡献者素质不那么高，质量就无法得到保证。

### gitlab flow

Gitlab flow 是 Git flow 与 Github flow 的综合。它吸取了两者的优点，既有适应不同开发环境的弹性，又有单一主分支的简单和便利。它是 Gitlab.com 推荐的做法。

Gitlab flow 的最大原则叫做”上游优先”（upsteam first），即只存在一个主分支master，它是所有其他分支的”上游”。只有上游分支采纳的代码变化，才能应用到其他分支。

对于”持续发布”的项目，它建议在master分支以外，再建立不同的环境分支。比如，”开发环境”的分支是master，”预发环境”的分支是pre-production，”生产环境”的分支是production。

![gitlab flow](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612268052916.png)

只有紧急情况，才允许跳过上游，直接合并到下游分支。

对于”版本发布”的项目，建议的做法是每一个稳定版本，都要从master分支拉出一个分支，比如2-3-stable、2-4-stable等等。

![版本发布](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612268111739.png)

gitlab flow 如何处理hotfix？ git flow之所以这么复杂，一大半原因就是把hotfix考虑得太周全了。hotfix的意思是，当代码部署到产品环境之后发现的问题，需要火速fix。gitlab flow 可以基于后续分支，修改后上线。

## 团队git规范

综合上面的介绍，我们决定采用gitlab flow，按照版本发布的模式实施，具体来说：

1. 新的迭代开始，所有开发人员从主干master拉个人分支开发特性, 分支命名规范 feature-name
2. 开发完成后，在迭代结束前，合入master分支
3. master分支合并后，自动cicd到dev环境
4. 开发自测通过后，从master拉取要发布的分支，release-$version，将这个分支部署到测试环境进行测试
5. 测出的bug，通过从release-$versio拉出分支进行修复，修复完成后，再合入release-$versio
6. 正式发布版本，如果上线后，又有bug，根据5的方式处理
7. 等发布版本稳定后，将release-$versio反合入主干

## 最佳实践

### 开发feature功能

新建分支，比如`feat-test`

![新分支](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612263756008.png)

开发代码，增加新功能，提交：

```java
Copy@GetMapping(path = "/test", produces = "application/json")
	@ResponseBody
	public Map<String, Object> test() {
		return singletonMap("test", "test");
	}
Copygit commit -m "feat: add test code"
git push origin feat-test
```

### 提交MR

提交代码后，可以提交`mr`到`master`，申请合并代码

![mr](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612264109605.png)

**Note**：

- 这里可以增加自动代码审查,

### 合并代码

研发组长，打开mr，review代码，可以添加建议：

![添加评论](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612264544465.png)

开发同学根据建议修复代码，或者线下修改后commit代码。

![应用建议](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612264598028.png)

研发组长确认没有问题后，可以合并到master。

![合并](https://gitee.com/jadepeng/pic/raw/master/pic/2021/2/2/1612264745987.png)

合并完成，可以删除feat分支。

新功能开发好，可以进行提测。

### 发布版本

#### 语义化版本号

版本格式：主版本号.次版本号.修订号，版本号递增规则如下：

主版本号：当你做了不兼容的 API 修改，
 次版本号：当你做了向下兼容的功能性新增，
 修订号：当你做了向下兼容的问题修正。
 先行版本号及版本编译元数据可以加到“主版本号.次版本号.修订号”的后面，作为延伸。

主版本号为0，代表还未发布正式版本。

#### 测试发布

master分支，自动部署到开发环境（dev）

功能开发完成，并自测通过后，代码合并到待发布版本，

分支规则：

```
Copyrelease-version
```

版本规则

```
Copy主版本号.次版本号
```

构建时，自动增加修订号：

```
Copy主版本号.次版本号.修订号
```

从最新的master新拉一个分支`release-$version`，比如`release-0.1`

```
Copygit checkout -b release-0.1
release-$version`会自动构建，版本号为`$version.$buildNumber
```

设定`release-$version` 分支为保护分支，不允许直接推送，只能通过merge不允许直接提交代码，接受`MR`。

#### bug修复

需要修改bug时，从`release-$version`新拉分支，修改完成后再合并到`release-$version`分支.

- Q: 从`release-$version`拉的分支，如何测试？
- A:  这个节点定义为bug修复节点，建议开发同学优先本地测试验证，严重通过再合并到release分支。
- Q: `release-$version`太多怎么办？
- A:  可以保留最近的10个版本。历史的打tag后，删除分支。