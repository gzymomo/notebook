- [docker 发布应用时添加 git revision](https://www.cnblogs.com/wang_yb/p/10934407.html)

## 1 概要

docker 发布应用时, 将 git revision 注入到应用中, 在问题出现时, 可以迅速定位代码版本.

## 2 实施步骤

1. 获取 git revision
2. 将 git revision 传入具体的应用中
	- 前端的 revision 通过 yarn build 传入
	- 后端的 revision 通过 环境变量传入

### 2.1 获取 git revision

```bash
GIT_TAG=`git describe --tags`
IFS='-' read -r -a tags <<< $GIT_TAG
if [ "${#tags[@]}" = "1" ]; then
    GIT_COMMIT=$tags
else
    GIT_COMMIT=`git rev-parse HEAD | cut -c 1-8`
fi
```

上面的代码是获取最新的 git revision 的前 8 位, 如果最新的 git revision 有 tag, 则使用 tag 获取的 git revision 放在 **GIT_COMMIT** 中.

### 2.2 前端 git revision 注入

首先是 docker build 命令中传入 git revision

```bash
docker build -t xxx.latest --build-arg VERSION=${GIT_COMMIT} . 
```

然后在 docker file 中获取 VERSION, 并将其传给 yarn build 命令

```bash
ARG VERSION=no-version          # 默认值 no-version
RUN yarn
RUN yarn build --VERSION=${VERSION}
```

最后是前端工程中获取此变量, 并在页面的 footer 处显示 git revision

```js
     process.argv
       .filter(str => /^--/.test(str))
       .map(str => str.replace('--', ''))
       .forEach(str => {
         let sub = str.match(/([\s\S]*)\=([\s\S]*)/)

         sub ? (TYPE[sub[1]] = sub[2]) : (TYPE[str] = true)
       })

const mergeWebpackConfig = () => (config, env) => {
  // ...省略...

  config.plugins = (config.plugins || []).concat([
    new webpack.DefinePlugin({
      'process.env.VERSION': JSON.stringify(TYPE['VERSION'])
    })
  ])
  // ...省略...
}
<Footer>
  <div
    style={{ textAlign: 'center' }}
    className="gx-layout-footer-content"
  >
    Copyright © 2019 {process.env.VERSION}
  </div>
</Footer>
```

### 2.3 后端 git revision 注入

本文的例子是基于 golang 的 API 后端, 获取 git revision 的方法和上面类似.

获取 git revision 之后, 在 docker file 中获取 VERSION, 并设置环境变量 VERSION

```bash
ARG VERSION=no-version
ENV VERSION=${VERSION} 
```

API 服务添加 -v 参数, 用来显示服务的版本

```go
ver := flag.Bool("v", false, "verify version")
flag.Parse()

if *ver {
        fmt.Println(os.Getenv("VERSION"))
        return
}
```