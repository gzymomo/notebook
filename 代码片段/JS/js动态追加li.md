[TOC]

# js动态ul追加li
```javascript
var li = "<li><span style=\"width: 15%;;\">" + ym.project_type + "</span>\n”;

document.getElementById("ultable").innerHTML += li;

//清空方法
$("#ultable").html('');
```

# +操作符
使用+运算符将字符串转换为数字。 除非你想解析为特定的数字类型，否则不需要使用诸如 parseInt() 或 parseFloat() 之类的函数。

```javascript
const nr = +'1.5';
nr + 1; // 2.5
```