# 查看存储库中的大文件

```bash
git rev-list --objects --all | grep -E `git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -10 | awk '{print$1}' | sed ':a;N;$!ba;s/\n/|/g'`
或
git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -15 | awk '{print$1}')"
```

### 改写历史，去除大文件

注意：下方命令中的 `path/to/large/files` 是大文件所在的路径，千万不要弄错！

```bash
git filter-branch --tree-filter 'rm -f path/to/large/files' --tag-name-filter cat -- --all
git push origin --tags --force
git push origin --all --force
```

如果在 `git filter-branch` 操作过程中遇到如下提示，需要在 `git filter-branch` 后面加上参数 `-f`

并告知所有组员，push 代码前需要 pull rebase，而不是 merge，否则会从该组员的本地仓库再次引入到远程库中，导致仓库在此被 Gitee 系统屏蔽。

