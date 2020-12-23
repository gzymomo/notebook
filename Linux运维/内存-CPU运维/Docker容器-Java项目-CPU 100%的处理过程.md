[CPU 100%的处理过程](https://www.cnblogs.com/spec-dog/p/13278877.html)

## 定位

1. 使用 `docker stats` 命令查看本节点容器资源使用情况，对占用CPU很高的容器使用 `docker exec -it <容器ID> bash` 进入。
2. 在容器内部执行 `top` 命令查看，定位到占用CPU高的进程ID，使用 `top -Hp <进程ID>` 定位到占用CPU高的线程ID。
3. 使用 `jstack <进程ID> > jstack.txt` 将进程的线程栈打印输出。
4. 退出容器， 使用 `docker cp <容器ID>:/usr/local/tomcat/jstack.txt ./` 命令将jstack文件复制到宿主机，便于查看。获取到jstack信息后，赶紧重启服务让服务恢复可用。
5. 将2中占用CPU高的线程ID使用 `pringf '%x\n' <线程ID>` 命令将线程ID转换为十六进制形式。假设线程ID为133，则得到十六进制85。在jstack.txt文件中定位到 `nid=0x85`的位置，该位置即为占用CPU高线程的执行栈信息。如下图所示，

![jstack](https://img2020.cnblogs.com/other/632381/202007/632381-20200710140028833-1764817705.png)

 