- [DataX全系列之二 —— DataX 总体架构和原理 - 掘金 (juejin.cn)](https://juejin.cn/post/7006658351375335431)

# 1.DataX的整体架构

  主要分为三个部分，Reader，FrameWork，Writer

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b1c9c3bd58184c7e9d206e59ea4de235~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

## 1.1 Reader

  读数据库内容的插件，一个 job 会根据 json 配置文件调用 对应数据源的 Reader，Reader 根据配置文件将指定内容以 java 代码的方 式获取到数据，例如 mysqlreader 利用的就是 jdbc 的方式对数据进行的读 操作，具体如何实现的需要仔细看源码。

## 1.2 Writer

  将同步内容写入具体某数据源的插件，会根据 json 配置文 件调用对应的数据源 writer，然后往里写数据，说白了就是 insert 操作， 数据自然是做过处理的。

## 1.3 FrameWork

   datax 核心部分，负责初始化、拆分、调度、运行、回 收、监控和汇报，连接 Reader 和 Writer，使得 datax 能够满足不同数据源 之间的高效数据传输工作。

------

# 2. DataX核心流程

## 2.1 核心流程架构图

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ad6a543c97ce48d48a315ca5c29227bb~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

## 2.2 核心流程

1. job 是 Datax 一次任务的统称，DataX JobContainer 是一个运行 job 的容器，是整个同步任务的管理控制中心，承担了插件初始化，数据清理、 数据检测、任务切分、TaskGroup 管理，任务调度，监控，回收等功能。
2. DataX Job 启动后，会根据不同的源端切分策略，将 Job 切分成多个小的 Task(子任务)，实质上是在切分配置文件，以便于并发执行。Task 便是 DataX 同步任务的基础单位，每一个 Task 都会负责一部分数据的同步工 作。
3. 切分后的 task，会根据并发要求，通过 schedule 方法重新组合成 TaskGroup，TaskGroup 线程由一个线程池维护并监控，一个 TaskGroup 默 认并发 5 个 Task。
4. 每一个 Task 都由 TaskGroup 负责启动，Task 启动后，会启动读写两 个线程，并通过 Record 类作为媒介，Reader 不断地读出数据，并往传输中 转站 Channel 中存入信息，还 Writer 则负责从 Channel 中读出 Record 信 息，存入目标数据源。
5. DataX 作业运行时，JobContainer 会监控各个 TaskGroup 模块任务， 直到所有任务完成，并记录日志，当有都成功后会返回 0，不然会有完整的报错机制，异常退出返回非 0。

# 3. DataX的项目模块架构图

## 3.1 总体模块图

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1c7c38e2a91449c9bd8d4e82aec64c17~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

## 3.2 core的项目图

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/25fbe8453e2e443b9f88e1470c600351~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/386133ca241b4f038bcff395bd45e219~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

