- [深入解析 Kubebuilder：让编写 CRD 变得更简单](https://www.cnblogs.com/alisystemsoftware/p/11580202.html)

> **导读：**自定义资源 CRD（Custom Resource Definition）可以扩展 Kubernetes API，掌握 CRD 是成为 Kubernetes 高级玩家的必备技能，本文将介绍 CRD 和 Controller 的概念，并对 CRD  编写框架 Kubebuilder 进行深入分析，让您真正理解并能快速开发 CRD。

# 1 概览

## 1.1 控制器模式与声明式 API


在正式介绍 Kubebuidler 之前，我们需要先了解下 K8s 底层实现大量使用的控制器模式，以及让用户大呼过瘾的声明式 API，这是介绍 CRDs 和 Kubebuidler 的基础。

### 1.1.1 控制器模式

K8s 作为一个“容器编排”平台，其核心的功能是编排，Pod 作为 K8s 调度的最小单位,具备很多属性和字段，K8s 的编排正是通过一个个控制器根据被控制对象的属性和字段来实现。

 下面我们看一个例子：

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
spec:
  selector:
    matchLabels:
      app: test
  replicas: 2
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```


K8s 集群在部署时包含了 Controllers 组件，里面对于每个 build-in 的资源类型（比如  Deployments, Statefulset, CronJob, ...）都有对应的 Controller，基本是 1:1  的关系。上面的例子中，Deployment 资源创建之后，对应的 Deployment Controller 编排动作很简单，确保携带了  app=test 的 Pod 个数永远等于 2，Pod 由 template 部分定义，具体来说，K8s 里面是  kube-controller-manager 这个组件在做这件事，可以看下 K8s 项目的 pkg/controller  目录，里面包含了所有控制器，都以独有的方式负责某种编排功能，但是它们都遵循一个通用编排模式，即：调谐循环（Reconcile  loop），其伪代码逻辑为：

```
for {
actualState := GetResourceActualState(rsvc)
expectState := GetResourceExpectState(rsvc)
if actualState == expectState {
// do nothing
} else {
Reconcile(rsvc)
}
}
```

就是一个无限循环（实际是事件驱动+定时同步来实现，不是无脑循环）不断地对比期望状态和实际状态，如果有出入则进行  Reconcile（调谐）逻辑将实际状态调整为期望状态。期望状态就是我们的对象定义（通常是 YAML  文件），实际状态是集群里面当前的运行状态（通常来自于 K8s  集群内外相关资源的状态汇总），控制器的编排逻辑主要是第三步做的，这个操作被称为调谐（Reconcile），整个控制器调谐的过程称为“Reconcile Loop”，调谐的最终结果一般是对被控制对象的某种写操作，比如增/删/改 Pod。

 在控制器中定义被控制对象是通过“模板”完成的，比如 Deployment 里面的 template 字段里的内容跟一个标准的 Pod  对象的 API 定义一样，所有被这个 Deployment 管理的 Pod 实例，都是根据这个 template 字段的创建的，这就是  PodTemplate，一个控制对象的定义一般是由上半部分的控制定义（期望状态），加上下半部分的被控制对象的模板组成。

### 1.1.2 声明式 API

所谓声明式就是“告诉 K8s 你要什么，而不是告诉它怎么做的命令”，一个很熟悉的例子就是 SQL，你“告诉 DB  根据条件和各类算子返回数据，而不是告诉它怎么遍历，过滤，聚合”。在 K8s 里面，声明式的体现就是 kubectl apply  命令，在对象创建和后续更新中一直使用相同的 apply 命令，告诉 K8s 对象的终态即可，底层是通过执行了一个对原有 API 对象的  PATCH 操作来实现的，可以一次性处理多个写操作，具备 Merge 能力 diff 出最终的 PATCH，而命令式一次只能处理一个写请求。
 
声明式 API 让 K8s  的“容器编排”世界看起来温柔美好，而控制器（以及容器运行时，存储，网络模型等）才是这太平盛世的幕后英雄。说到这里，就会有人希望也能像  build-in 资源一样构建自己的自定义资源（CRD-Customize Resource  Definition），然后为自定义资源写一个对应的控制器，推出自己的声明式 API。K8s 提供了 CRD  的扩展方式来满足用户这一需求，而且由于这种扩展方式十分灵活，在最新的 [1.15 版本对 CRD 做了相当大的增强](https://kubernetes.io/blog/2019/06/19/kubernetes-1-15-release-announcement/)。对于用户来说，实现 CRD 扩展主要做两件事：

1. 编写 CRD 并将其部署到 K8s 集群里；

这一步的作用就是让 K8s 知道有这个资源及其结构属性，在用户提交该自定义资源的定义时（通常是 YAML 文件定义），K8s 能够成功校验该资源并创建出对应的 Go struct 进行持久化，同时触发控制器的调谐逻辑。

1. 编写 Controller 并将其部署到 K8s 集群里。

这一步的作用就是实现调谐逻辑。

 Kubebuilder 就是帮我们简化这两件事的工具，现在我们开始介绍主角。

## 1.2 Kubebuilder 是什么？

### 1.2.1 摘要

[Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder) 是一个使用 CRDs 构建 K8s API 的 SDK，主要是：

- 提供脚手架工具初始化 CRDs 工程，自动生成 boilerplate 代码和配置；
- 提供代码库封装底层的 K8s go-client；


方便用户从零开始开发 CRDs，Controllers 和 Admission Webhooks 来扩展 K8s。

### 1.2.2 核心概念

##### 1. GVKs&GVRs

GVK = GroupVersionKind，GVR = GroupVersionResource。

##### 2. API Group & Versions（GV）

API Group 是相关 API 功能的集合，每个 Group 拥有一或多个 Versions，用于接口的演进。

##### 3. Kinds & Resources

每个 GV 都包含多个 API 类型，称为 Kinds，在不同的 Versions 之间同一个 Kind 定义可能不同， Resource 是 Kind 的对象标识（[resource type](https://kubernetes.io/docs/reference/kubectl/overview/#resource-types)），一般来说 Kinds 和 Resources 是 1:1 的，比如 pods Resource 对应 Pod Kind，但是有时候相同的 Kind  可能对应多个 Resources，比如 Scale Kind 可能对应很多  Resources：deployments/scale，replicasets/scale，对于 CRD 来说，只会是 1:1 的关系。
 
每一个 GVK 都关联着一个 package 中给定的 root Go type，比如 apps/v1/Deployment 就关联着 K8s  源码里面 k8s.io/api/apps/v1 package 中的 Deployment struct，我们提交的各类资源定义 YAML  文件都需要写：

- apiVersion：这个就是 GV 。
- kind：这个就是 K。

根据 GVK K8s 就能找到你到底要创建什么类型的资源，根据你定义的 Spec 创建好资源之后就成为了 Resource，也就是 GVR。GVK/GVR 就是 K8s 资源的坐标，是我们创建/删除/修改/读取资源的基础。

#### Scheme

每一组 Controllers 都需要一个 Scheme，提供了 Kinds 与对应 Go types 的映射，也就是说给定 Go  type 就知道他的 GVK，给定 GVK 就知道他的 Go type，比如说我们给定一个 Scheme:  "tutotial.kubebuilder.io/api/v1".CronJob{} 这个 Go type 映射到  batch.tutotial.kubebuilder.io/v1 的 CronJob GVK，那么从 Api Server 获取到下面的  JSON:

```
{
    "kind": "CronJob",
    "apiVersion": "batch.tutorial.kubebuilder.io/v1",
    ...
}
```

就能构造出对应的 Go type了，通过这个 Go type 也能正确地获取 GVR 的一些信息，控制器可以通过该 Go type 获取到期望状态以及其他辅助信息进行调谐逻辑。

#### Manager

Kubebuilder 的核心组件，具有 3 个职责：

- 负责运行所有的 Controllers；
- 初始化共享 caches，包含 listAndWatch 功能；
- 初始化 clients 用于与 Api Server 通信。

#### Cache

Kubebuilder 的核心组件，负责在 Controller 进程里面根据 Scheme 同步 Api Server 中所有该  Controller 关心 GVKs 的 GVRs，其核心是 GVK -> Informer 的映射，Informer 会负责监听对应  GVK 的 GVRs 的创建/删除/更新操作，以触发 Controller 的 Reconcile 逻辑。

#### Controller

Kubebuidler 为我们生成的脚手架文件，我们只需要实现 Reconcile 方法即可。

#### Clients

在实现 Controller 的时候不可避免地需要对某些资源类型进行创建/删除/更新，就是通过该 Clients 实现的，其中查询功能实际查询是本地的 Cache，写操作直接访问 Api Server。

#### Index

由于 Controller 经常要对 Cache 进行查询，Kubebuilder 提供 Index utility 给 Cache 加索引提升查询效率。

#### Finalizer

在一般情况下，如果资源被删除之后，我们虽然能够被触发删除事件，但是这个时候从 Cache  里面无法读取任何被删除对象的信息，这样一来，导致很多垃圾清理工作因为信息不足无法进行，K8s 的 Finalizer 字段用于处理这种情况。在  K8s 中，只要对象 ObjectMeta 里面的 Finalizers 不为空，对该对象的 delete 操作就会转变为 update  操作，具体说就是 update deletionTimestamp 字段，其意义就是告诉 K8s 的  GC“在deletionTimestamp 这个时刻之后，只要 Finalizers 为空，就立马删除掉该对象”。

 所以一般的使用姿势就是在创建对象时把 Finalizers 设置好（任意 string），然后处理 DeletionTimestamp  不为空的 update 操作（实际是 delete），根据 Finalizers 的值执行完所有的 pre-delete hook（此时可以在  Cache 里面读取到被删除对象的任何信息）之后将 Finalizers 置为空即可。

#### OwnerReference

K8s GC 在删除一个对象时，任何 ownerReference 是该对象的对象都会被清除，与此同时，Kubebuidler 支持所有对象的变更都会触发 Owner 对象 controller 的 Reconcile 方法。

 所有概念集合在一起如图 1 所示：

 ![file](https://img2018.cnblogs.com/blog/1411156/201909/1411156-20190924185512492-2023344045.jpg)

图 1-Kubebuilder 核心概念
 Kubebuilder 怎么用？

### 1. 创建脚手架工程

```
kubebuilder init --domain edas.io
```

这一步创建了一个 Go module 工程，引入了必要的依赖，创建了一些模板文件。

### 2. 创建 API

```
kubebuilder create api --group apps --version v1alpha1 --kind Application
```

这一步创建了对应的 CRD 和 Controller 模板文件，经过 1、2 两步，现有的工程结构如图 2 所示：

 ![file](https://img2018.cnblogs.com/blog/1411156/201909/1411156-20190924185512721-2072096262.jpg)
 
图 2-Kubebuilder 生成的工程结构说明

### 3. 定义 CRD

在图 2 中对应的文件定义 Spec 和 Status。

### 4. 编写 Controller 逻辑

在图 3 中对应的文件实现 Reconcile 逻辑。

### 5. 测试发布

本地测试完之后使用 Kubebuilder 的 Makefile 构建镜像，部署我们的 CRDs 和 Controller 即可。

## 1.3 Kubebuilder 出现的意义？

让扩展 K8s 变得更简单，K8s 扩展的方式很多，Kubebuilder 目前专注于 CRD 扩展方式。
 深入

在使用 Kubebuilder 的过程中有些问题困扰着我：

- 如何同步自定义资源以及 K8s build-in 资源？
- Controller 的 Reconcile 方法是如何被触发的？
- Cache 的工作原理是什么？
- ...

带着这些问题我们去看看源码 😄。

## 1.4 源码阅读

### 1.4.1 从 main.go 开始

Kubebuilder 创建的 main.go 是整个项目的入口，逻辑十分简单：

```
var (
	scheme   = runtime.NewScheme()
	setupLog = ctrl.Log.WithName("setup")
)
func init() {
	appsv1alpha1.AddToScheme(scheme)
	// +kubebuilder:scaffold:scheme
}
func main() {
	...
        // 1、init Manager
	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{Scheme: scheme, MetricsBindAddress: metricsAddr})
	if err != nil {
		setupLog.Error(err, "unable to start manager")
		os.Exit(1)
	}
        // 2、init Reconciler（Controller）
	err = (&controllers.ApplicationReconciler{
		Client: mgr.GetClient(),
		Log:    ctrl.Log.WithName("controllers").WithName("Application"),
		Scheme: mgr.GetScheme(),
	}).SetupWithManager(mgr)
	if err != nil {
		setupLog.Error(err, "unable to create controller", "controller", "EDASApplication")
		os.Exit(1)
	}
	// +kubebuilder:scaffold:builder
	setupLog.Info("starting manager")
        // 3、start Manager
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		setupLog.Error(err, "problem running manager")
		os.Exit(1)
	}
```

可以看到在 init 方法里面我们将 appsv1alpha1 注册到 Scheme 里面去了，这样一来 Cache 就知道 watch 谁了，main 方法里面的逻辑基本都是 Manager 的：

1. 初始化了一个 Manager；
2. 将 Manager 的 Client 传给 Controller，并且调用 SetupWithManager 方法传入 Manager 进行 Controller 的初始化；
3. 启动 Manager。

我们的核心就是看这 3 个流程。

### 1.4.2 Manager 初始化

Manager 初始化代码如下：

```
// New returns a new Manager for creating Controllers.
func New(config *rest.Config, options Options) (Manager, error) {
	...
	// Create the cache for the cached read client and registering informers
	cache, err := options.NewCache(config, cache.Options{Scheme: options.Scheme, Mapper: mapper, Resync: options.SyncPeriod, Namespace: options.Namespace})
	if err != nil {
		return nil, err
	}
	apiReader, err := client.New(config, client.Options{Scheme: options.Scheme, Mapper: mapper})
	if err != nil {
		return nil, err
	}
	writeObj, err := options.NewClient(cache, config, client.Options{Scheme: options.Scheme, Mapper: mapper})
	if err != nil {
		return nil, err
	}
	...
	return &controllerManager{
		config:           config,
		scheme:           options.Scheme,
		errChan:          make(chan error),
		cache:            cache,
		fieldIndexes:     cache,
		client:           writeObj,
		apiReader:        apiReader,
		recorderProvider: recorderProvider,
		resourceLock:     resourceLock,
		mapper:           mapper,
		metricsListener:  metricsListener,
		internalStop:     stop,
		internalStopper:  stop,
		port:             options.Port,
		host:             options.Host,
		leaseDuration:    *options.LeaseDuration,
		renewDeadline:    *options.RenewDeadline,
		retryPeriod:      *options.RetryPeriod,
	}, nil
}
```

可以看到主要是创建 Cache 与 Clients：

#### 创建 Cache

Cache 初始化代码如下：

```
// New initializes and returns a new Cache.
func New(config *rest.Config, opts Options) (Cache, error) {
	opts, err := defaultOpts(config, opts)
	if err != nil {
		return nil, err
	}
	im := internal.NewInformersMap(config, opts.Scheme, opts.Mapper, *opts.Resync, opts.Namespace)
	return &informerCache{InformersMap: im}, nil
}
// newSpecificInformersMap returns a new specificInformersMap (like
// the generical InformersMap, except that it doesn't implement WaitForCacheSync).
func newSpecificInformersMap(...) *specificInformersMap {
	ip := &specificInformersMap{
		Scheme:            scheme,
		mapper:            mapper,
		informersByGVK:    make(map[schema.GroupVersionKind]*MapEntry),
		codecs:            serializer.NewCodecFactory(scheme),
		resync:            resync,
		createListWatcher: createListWatcher,
		namespace:         namespace,
	}
	return ip
}
// MapEntry contains the cached data for an Informer
type MapEntry struct {
	// Informer is the cached informer
	Informer cache.SharedIndexInformer
	// CacheReader wraps Informer and implements the CacheReader interface for a single type
	Reader CacheReader
}
func createUnstructuredListWatch(gvk schema.GroupVersionKind, ip *specificInformersMap) (*cache.ListWatch, error) {
        ...
	// Create a new ListWatch for the obj
	return &cache.ListWatch{
		ListFunc: func(opts metav1.ListOptions) (runtime.Object, error) {
			if ip.namespace != "" && mapping.Scope.Name() != meta.RESTScopeNameRoot {
				return dynamicClient.Resource(mapping.Resource).Namespace(ip.namespace).List(opts)
			}
			return dynamicClient.Resource(mapping.Resource).List(opts)
		},
		// Setup the watch function
		WatchFunc: func(opts metav1.ListOptions) (watch.Interface, error) {
			// Watch needs to be set to true separately
			opts.Watch = true
			if ip.namespace != "" && mapping.Scope.Name() != meta.RESTScopeNameRoot {
				return dynamicClient.Resource(mapping.Resource).Namespace(ip.namespace).Watch(opts)
			}
			return dynamicClient.Resource(mapping.Resource).Watch(opts)
		},
	}, nil
}
```

可以看到 Cache 主要就是创建了 InformersMap，Scheme 里面的每个 GVK 都创建了对应的  Informer，通过 informersByGVK 这个 map 做 GVK 到 Informer 的映射，每个 Informer 会根据  ListWatch 函数对对应的 GVK 进行 List 和 Watch。

#### 创建 Clients

创建 Clients 很简单：

```
// defaultNewClient creates the default caching client
func defaultNewClient(cache cache.Cache, config *rest.Config, options client.Options) (client.Client, error) {
	// Create the Client for Write operations.
	c, err := client.New(config, options)
	if err != nil {
		return nil, err
	}
	return &client.DelegatingClient{
		Reader: &client.DelegatingReader{
			CacheReader:  cache,
			ClientReader: c,
		},
		Writer:       c,
		StatusClient: c,
	}, nil
}
```

读操作使用上面创建的 Cache，写操作使用 K8s go-client 直连。

### 1.4.3 Controller 初始化

下面看看 Controller 的启动：

```
func (r *EDASApplicationReconciler) SetupWithManager(mgr ctrl.Manager) error {
	err := ctrl.NewControllerManagedBy(mgr).
		For(&appsv1alpha1.EDASApplication{}).
		Complete(r)
return err
}
```

使用的是 Builder 模式，NewControllerManagerBy 和 For 方法都是给 Builder 传参，最重要的是最后一个方法 Complete，其逻辑是：

```
func (blder *Builder) Build(r reconcile.Reconciler) (manager.Manager, error) {
...
	// Set the Manager
	if err := blder.doManager(); err != nil {
		return nil, err
	}
	// Set the ControllerManagedBy
	if err := blder.doController(r); err != nil {
		return nil, err
	}
	// Set the Watch
	if err := blder.doWatch(); err != nil {
		return nil, err
	}
...
	return blder.mgr, nil
}
```

主要是看看 doController 和 doWatch 方法：

#### doController 方法

```
func New(name string, mgr manager.Manager, options Options) (Controller, error) {
	if options.Reconciler == nil {
		return nil, fmt.Errorf("must specify Reconciler")
	}
	if len(name) == 0 {
		return nil, fmt.Errorf("must specify Name for Controller")
	}
	if options.MaxConcurrentReconciles <= 0 {
		options.MaxConcurrentReconciles = 1
	}
	// Inject dependencies into Reconciler
	if err := mgr.SetFields(options.Reconciler); err != nil {
		return nil, err
	}
	// Create controller with dependencies set
	c := &controller.Controller{
		Do:                      options.Reconciler,
		Cache:                   mgr.GetCache(),
		Config:                  mgr.GetConfig(),
		Scheme:                  mgr.GetScheme(),
		Client:                  mgr.GetClient(),
		Recorder:                mgr.GetEventRecorderFor(name),
		Queue:                   workqueue.NewNamedRateLimitingQueue(workqueue.DefaultControllerRateLimiter(), name),
		MaxConcurrentReconciles: options.MaxConcurrentReconciles,
		Name:                    name,
	}
	// Add the controller as a Manager components
	return c, mgr.Add(c)
}
```

该方法初始化了一个 Controller，传入了一些很重要的参数：

- Do：Reconcile 逻辑；
- Cache：找 Informer 注册 Watch；
- Client：对 K8s 资源进行 CRUD；
- Queue：Watch 资源的 CUD 事件缓存；
- Recorder：事件收集。

#### doWatch 方法

```
func (blder *Builder) doWatch() error {
	// Reconcile type
	src := &source.Kind{Type: blder.apiType}
	hdler := &handler.EnqueueRequestForObject{}
	err := blder.ctrl.Watch(src, hdler, blder.predicates...)
	if err != nil {
		return err
	}
	// Watches the managed types
	for _, obj := range blder.managedObjects {
		src := &source.Kind{Type: obj}
		hdler := &handler.EnqueueRequestForOwner{
			OwnerType:    blder.apiType,
			IsController: true,
		}
		if err := blder.ctrl.Watch(src, hdler, blder.predicates...); err != nil {
			return err
		}
	}
	// Do the watch requests
	for _, w := range blder.watchRequest {
		if err := blder.ctrl.Watch(w.src, w.eventhandler, blder.predicates...); err != nil {
			return err
		}
	}
	return nil
}
```

可以看到该方法对本 Controller 负责的 CRD 进行了 watch，同时底下还会 watch 本 CRD  管理的其他资源，这个 managedObjects 可以通过 Controller 初始化 Buidler 的 Owns 方法传入，说到  Watch 我们关心两个逻辑：

1. 注册的 handler

```
type EnqueueRequestForObject struct{}
// Create implements EventHandler
func (e *EnqueueRequestForObject) Create(evt event.CreateEvent, q workqueue.RateLimitingInterface) {
        ...
	q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
		Name:      evt.Meta.GetName(),
		Namespace: evt.Meta.GetNamespace(),
	}})
}
// Update implements EventHandler
func (e *EnqueueRequestForObject) Update(evt event.UpdateEvent, q workqueue.RateLimitingInterface) {
	if evt.MetaOld != nil {
		q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
			Name:      evt.MetaOld.GetName(),
			Namespace: evt.MetaOld.GetNamespace(),
		}})
	} else {
		enqueueLog.Error(nil, "UpdateEvent received with no old metadata", "event", evt)
	}
	if evt.MetaNew != nil {
		q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
			Name:      evt.MetaNew.GetName(),
			Namespace: evt.MetaNew.GetNamespace(),
		}})
	} else {
		enqueueLog.Error(nil, "UpdateEvent received with no new metadata", "event", evt)
	}
}
// Delete implements EventHandler
func (e *EnqueueRequestForObject) Delete(evt event.DeleteEvent, q workqueue.RateLimitingInterface) {
        ...
	q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
		Name:      evt.Meta.GetName(),
		Namespace: evt.Meta.GetNamespace(),
	}})
}
```

可以看到 Kubebuidler 为我们注册的 Handler 就是将发生变更的对象的 NamespacedName 入队列，如果在 Reconcile 逻辑中需要判断创建/更新/删除，需要有自己的判断逻辑。

1. 注册的流程

```
// Watch implements controller.Controller
func (c *Controller) Watch(src source.Source, evthdler handler.EventHandler, prct ...predicate.Predicate) error {
	...
	log.Info("Starting EventSource", "controller", c.Name, "source", src)
	return src.Start(evthdler, c.Queue, prct...)
}
// Start is internal and should be called only by the Controller to register an EventHandler with the Informer
// to enqueue reconcile.Requests.
func (is *Informer) Start(handler handler.EventHandler, queue workqueue.RateLimitingInterface,
	...
	is.Informer.AddEventHandler(internal.EventHandler{Queue: queue, EventHandler: handler, Predicates: prct})
	return nil
}
```

我们的 Handler 实际注册到 Informer 上面，这样整个逻辑就串起来了，通过 Cache 我们创建了所有 Scheme 里面 GVKs 的 Informers，然后对应 GVK 的 Controller 注册了 Watch Handler 到对应的  Informer，这样一来对应的 GVK 里面的资源有变更都会触发 Handler，将变更事件写到 Controller  的事件队列中，之后触发我们的 Reconcile 方法。

### 1.4.4 Manager 启动

```
func (cm *controllerManager) Start(stop <-chan struct{}) error {
	...
	go cm.startNonLeaderElectionRunnables()
	...
}
func (cm *controllerManager) startNonLeaderElectionRunnables() {
	...
	// Start the Cache. Allow the function to start the cache to be mocked out for testing
	if cm.startCache == nil {
		cm.startCache = cm.cache.Start
	}
	go func() {
		if err := cm.startCache(cm.internalStop); err != nil {
			cm.errChan <- err
		}
	}()
        ...
        // Start Controllers
	for _, c := range cm.nonLeaderElectionRunnables {
		ctrl := c
		go func() {
			cm.errChan <- ctrl.Start(cm.internalStop)
		}()
	}
	cm.started = true
}
```

主要就是启动 Cache，Controller，将整个事件流运转起来，我们下面来看看启动逻辑。

#### Cache 启动

```
func (ip *specificInformersMap) Start(stop <-chan struct{}) {
	func() {
		...
		// Start each informer
		for _, informer := range ip.informersByGVK {
			go informer.Informer.Run(stop)
		}
	}()
}
func (s *sharedIndexInformer) Run(stopCh <-chan struct{}) {
        ...
        // informer push resource obj CUD delta to this fifo queue
	fifo := NewDeltaFIFO(MetaNamespaceKeyFunc, s.indexer)
	cfg := &Config{
		Queue:            fifo,
		ListerWatcher:    s.listerWatcher,
		ObjectType:       s.objectType,
		FullResyncPeriod: s.resyncCheckPeriod,
		RetryOnError:     false,
		ShouldResync:     s.processor.shouldResync,
                // handler to process delta
		Process: s.HandleDeltas,
	}
	func() {
		s.startedLock.Lock()
		defer s.startedLock.Unlock()
                // this is internal controller process delta generate by reflector
		s.controller = New(cfg)
		s.controller.(*controller).clock = s.clock
		s.started = true
	}()
        ...
	wg.StartWithChannel(processorStopCh, s.processor.run)
	s.controller.Run(stopCh)
}
func (c *controller) Run(stopCh <-chan struct{}) {
	...
	r := NewReflector(
		c.config.ListerWatcher,
		c.config.ObjectType,
		c.config.Queue,
		c.config.FullResyncPeriod,
	)
	...
        // reflector is delta producer
	wg.StartWithChannel(stopCh, r.Run)
        // internal controller's processLoop is comsume logic
	wait.Until(c.processLoop, time.Second, stopCh)
}
```

Cache 的初始化核心是初始化所有的 Informer，Informer 的初始化核心是创建了 reflector 和内部  controller，reflector 负责监听 Api Server 上指定的 GVK，将变更写入 delta  队列中，可以理解为变更事件的生产者，内部 controller 是变更事件的消费者，他会负责更新本地 indexer，以及计算出 CUD  事件推给我们之前注册的 Watch Handler。

#### Controller 启动

```
// Start implements controller.Controller
func (c *Controller) Start(stop <-chan struct{}) error {
	...
	for i := 0; i < c.MaxConcurrentReconciles; i++ {
		// Process work items
		go wait.Until(func() {
			for c.processNextWorkItem() {
			}
		}, c.JitterPeriod, stop)
	}
	...
}
func (c *Controller) processNextWorkItem() bool {
	...
	obj, shutdown := c.Queue.Get()
	...
	var req reconcile.Request
	var ok bool
	if req, ok = obj.(reconcile.Request); 
        ...
	// RunInformersAndControllers the syncHandler, passing it the namespace/Name string of the
	// resource to be synced.
	if result, err := c.Do.Reconcile(req); err != nil {
		c.Queue.AddRateLimited(req)
		...
	} 
        ...
}
```

Controller 的初始化是启动 goroutine 不断地查询队列，如果有变更消息则触发到我们自定义的 Reconcile 逻辑。

## 1.5 整体逻辑串连

上面我们通过源码阅读已经十分清楚整个流程，但是正所谓一图胜千言，我制作了一张整体逻辑串连图（图 3）来帮助大家理解：

 ![file](https://img2018.cnblogs.com/blog/1411156/201909/1411156-20190924185513180-1213819369.jpg)
 
图 3-Kubebuidler 整体逻辑串连图

 Kubebuilder 作为脚手架工具已经为我们做了很多，到最后我们只需要实现 Reconcile 方法即可，这里不再赘述。

## 1.6 守得云开见月明

刚开始使用 Kubebuilder 的时候，因为封装程度很高，很多事情都是懵逼状态，剖析完之后很多问题就很明白了，比如开头提出的几个：

- 如何同步自定义资源以及 K8s build-in 资源？

需要将自定义资源和想要 Watch 的 K8s build-in 资源的 GVKs 注册到 Scheme 上，Cache 会自动帮我们同步。

- Controller 的 Reconcile 方法是如何被触发的？

通过 Cache 里面的 Informer 获取资源的变更事件，然后通过两个内置的 Controller 以生产者消费者模式传递事件，最终触发 Reconcile 方法。

- Cache 的工作原理是什么？

GVK -> Informer 的映射，Informer 包含 Reflector 和 Indexer 来做事件监听和本地缓存。

 还有很多问题我就不一一说了，总之，现在 Kubebuilder 现在不再是黑盒。

## 1.7 同类工具对比

[Operator Framework](https://github.com/operator-framework/operator-sdk) 与 Kubebuilder 很类似，这里因为篇幅关系不再展开。

# 2 最佳实践

## 2.1 模式

1. 使用 OwnerRefrence 来做资源关联，有两个特性：

- Owner 资源被删除，被 Own 的资源会被级联删除，这利用了 K8s 的 GC；
- 被 Own 的资源对象的事件变更可以触发 Owner 对象的 Reconcile 方法；

1. 使用 Finalizer 来做资源的清理。

## 2.2 注意点

- 不使用 Finalizer 时，资源被删除无法获取任何信息；
- 对象的 Status 字段变化也会触发 Reconcile 方法；
- Reconcile 逻辑需要幂等；

## 2.3 优化

使用 IndexFunc 来优化资源查询的效率

# 3 总结

通过深入分析，我们可以看到 Kubebuilder 提供的功能对于快速编写 CRD 和 Controller 是十分有帮助的，无论是  Istio、Knative 等知名项目还是各种自定义 Operators，都大量使用了 CRD，将各种组件抽象为 CRD，Kubernetes  变成控制面板将成为一个趋势，希望本文能够帮助大家理解和把握这个趋势。