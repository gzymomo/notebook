- [docker 通过中间镜像加速部署](https://www.cnblogs.com/wang_yb/p/11013550.html)

## 1 概要

使用 docker 打包镜像的时候, 每次耗费时间最多的就是 **docker build** 的过程. 特别是对于前端工程的打包, 有时候下载依赖包的时间就要 10 几分钟, 这就导致发布版本的效率极低.

针对前端工程的打包慢的问题, 目前能想到的有效解决办法就是, 在官方 node 的镜像基础上, 把当前项目用到的 packages 下载好再做个镜像用于编译前端工程用.

## 2 实施

根据上面的方案, 尝试如下.

### 2.1 修改前的实施时间

修改前, 是在 node 镜像中编译前端, 然后将编译之后的代码放入后端的静态文件目录中.

```bash
FROM node:10.15-alpine as front-builder

WORKDIR /user
ADD ./frontend/application .
RUN yarn                        #  这一步耗费的时间最长
RUN yarn build


FROM golang:1.12.5-alpine3.9 as back-builder

WORKDIR /go
RUN mkdir -p ./src/xxx
ADD ./backend/src/xxx ./src/xxx
RUN go install xxx


FROM golang:1.12.5-alpine3.9

WORKDIR /app
COPY --from=front-builder /user/build ./public
COPY --from=back-builder /go/bin/xxx .

CMD ["./xxx"]
```

这种方式的编译时间如下:

```
real    14m27.639s
user    0m0.812s
sys     0m0.108s
```

### 2.2 制作编译用的镜像

前端编译用的镜像 Dockerfile 如下:

```bash
FROM node:10.15-alpine

WORKDIR /user
ADD ./frontend/application .
RUN yarn
RUN rm -rf `grep -v "node_modules" | grep -v "yarn.lock"`
```

docker build 命令: ( 目录结构根据具体的项目调整 )

```bash
# 这里的 Dockerfile 就是上面的内容, 编译后会生成名称为 node-application-cache 的 image
docker build -f ./Dockerfile -t node-application-cache .
```

### 2.3 测试修改后的实施时间

dockerfile 和修改前的基本一样, 只改了第一行

```bash
# FROM node:10.15-alpine as front-builder
FROM node-application-cache:latest as front-builder
```

编译时间如下:

```
real    1m17.399s
user    0m0.836s
sys     0m0.136s
```

使用了带前端缓存的 image, 整体时间缩短了 14 倍左右 中途编译用的镜像(node-application-cache)比之前的(node:10.15-alpine)大很多, 但是最终发布的镜像还是一样大.