- [Git 开发必备 .gitignore 详解！](https://blog.51cto.com/u_13685039/4770740)

在使用 git 管理项目过程中，.gitignore 文件是必备的文件，下面来详细说一说！

## 一、为什么使用 .gitignore ？

在一些项目中，我们不想让本地仓库的所有文件都上传到远程仓库中，而是有选择的上传，比如：一些依赖文件（node_modules下的依赖）、bin  目录下的文件、测试文件等。一方面将一些依赖、测试文件都上传到远程传输量很大，另一方面，一些文件对于你这边是可用的，在另一个人那可能就不可用了，比如：本地配置文件。

为了解决上述问题，git 引入了 .gitignore 文件，使用该文件来选择性的上传文件。

## 二、使用规则

### 2.1 注释

注释使用 # 开头，后面跟注释内容。如下所示： 

```
linuxy@linuxy:~/linuxGit$ cat .gitignore 
# this is .gitignore file.
# 以下是忽略的文件
out
*.exe
linuxy@linuxy:~/linuxGit$
```

上例中，以 # 开头的便是注释。

### 2.2 忽略文件

**（1）忽略文件和目录**

例如：folderName : 表示忽略 folderName 文件和 folderName 目录，会自动搜索多级目录，比如：*/*/folderName。

来看一个简单的例子，本地仓库的目录结构如下所示： 

```
linuxy@linuxy:~/linuxGit$ tree
.
├── folder
│   └── file1
└── src
    ├── folder
    └── utils
        └── folder
 
3 directories, 3 files
linuxy@linuxy:~/linuxGit$
```

其中，.gitignore 文件内容如下所示：

```
linuxy@linuxy:~/linuxGit$ cat .gitignore 
# this is .gitignore file.
# 以下是忽略的文件
 
folder
linuxy@linuxy:~/linuxGit$ 
```

故在本地仓库中，同名的 folder 目录、src/folder 文件、src/utils/folder 文件都会被忽略，即：不会被提交到远程仓库中。

**（2）仅忽略文件**

模式如下所示：

```
folderName
 
!folderName/
```

仅忽略 folderName 文件，而不忽略 folderName 目录，其中，感叹号**“!”**表示反向操作。

来看一个简单的例子，本地仓库的目录结构如下所示：

```
linuxy@linuxy:~/linuxGit$ tree
.
├── folder
│   └── file1
└── src
    ├── folder
    └── utils
        └── folder
 
3 directories, 3 files
linuxy@linuxy:~/linuxGit$
```

其中，.gitignore 文件内容如下所示：

```
linuxy@linuxy:~/linuxGit$ cat .gitignore 
# this is .gitignore file.
# 以下是忽略的文件
 
folder
!folder/
linuxy@linuxy:~/linuxGit$
```

故在本地仓库中，src/folder 文件、src/utils/folder 文件会被忽略，而同名的 folder 目录不会被忽略。

### 2.3 忽略目录

模式如下所示：

```
folderName/
```

忽略 folderName 目录，包括：

（1）当前目录下的foldernName，例如：folderName/；

（2）多级目录下的 folderName，例如：*/*/folderName/；

来看一个简单的例子，本地仓库的目录结构如下所示：

```
linuxy@linuxy:~/linuxGit$ tree
.
├── folder
│   └── file1
└── src
    ├── folder
    └── utils
        └── folder
 
3 directories, 3 files
linuxy@linuxy:~/linuxGit$
```

其中，.gitignore 文件内容如下所示：

```
linuxy@linuxy:~/linuxGit$ cat .gitignore 
# this is .gitignore file.
# 以下是忽略的文件
 
folder/
linuxy@linuxy:~/linuxGit$
```

故在本地仓库中，folder 目录会被忽略，而同名的 src/folder 文件和 src/utils/folder 文件不会被忽略。

### 2.4 使用通配符

常用的通配符有：

（1）星号“*” ：匹配多个字符；

（2）问号“?”：匹配除 ‘/’外的任意一个字符；

（3）方括号“[xxxx]”：匹配多个列表中的字符；

来看一个简单的例子，本地仓库的目录结构如下所示： 

```
linuxy@linuxy:~/linuxGit$ tree
.
├── src
│   ├── add.c
│   ├── add.i
│   └── add.o
├── test.c
├── test.i
└── test.o
 
1 directory, 6 files
linuxy@linuxy:~/linuxGit$
```

其中，.gitignore 文件内容如下所示：

```
linuxy@linuxy:~/linuxGit$ cat .gitignore 
# this is .gitignore file.
# 以下是忽略的文件
 
*.[io]
linuxy@linuxy:~/linuxGit$
```

故在本地仓库中，test.i文件、test.o文件、src/add.o文件、src/add.i文件会被忽略，而 test.c文件和add.c 文件不会被忽略。注意：这里忽略的匹配模式是多级目录的。

### 2.5 反向操作

模式如下所示：

```
!匹配模式 
```

表示之前忽略的匹配模式再次包含在跟踪内容里。

例如在仅忽略文件时提到的模式：

```
folderName
 
!folderName/
```

表示仅忽略 folderName 文件，而不忽略 folderName 目录。

### 2.6 双星号

斜杠后紧跟两个连续的星号"**"，表示多级目录。

来看一个简单的例子，.gitignore文件的内容如下所示：

```
linuxy@linuxy:~/linuxGit$ cat .gitignore 
# this is .gitignore file.
# 以下是忽略的文件
 
src/**/file
linuxy@linuxy:~/linuxGit$
```

可以表示忽略 src/folder1/file 、src/folder1/folder2/***/foldern/file 等。

### 2.7 其它规则

（1）空行不匹配任何文件；

（2）git 跟踪文件，而不是目录；

（3）在 .gitignore 文件中，每行表示一种模式；

（4）如果本地仓库文件已被跟踪，那么即使在 .gitignore 中设置了忽略，也不起作用。

（5）.gitignore 文件也会被上传的到远程仓库，所以，同一个仓库的人可以使用同一个.gitignore 文件。