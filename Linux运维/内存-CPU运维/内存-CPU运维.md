# 使用内存最多的5个进程

```bash
ps -aux | sort -k4nr | head 5
```

或者

```bash
top （然后按下M，注意大写）
```

# 使用CPU最多的5个进程

```bash
ps -aux | sort -k3nr | head 5
```

或者

```bash
top （然后按下P，注意大写）
```