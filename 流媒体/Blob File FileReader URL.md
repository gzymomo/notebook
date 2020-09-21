参考
 [[HTML5\] Blob对象](https://www.cnblogs.com/hhhyaaon/p/5928152.html)
 [理解DOMString、Document、FormData、Blob、File、ArrayBuffer数据类型](http://www.zhangxinxu.com/wordpress/?p=3725)
 [HTML5 File API — 让前端操作文件变的可能](https://www.cnblogs.com/zichi/p/html5-file-api.html)

简书：作者：合肥懒皮：链接：[H5直播系列一 Blob File FileReader URL](https://www.jianshu.com/p/04a9227a5af2)

# 一、Blob与ArrayBuffer

在[jsmpeg系列一 基础知识 字节序 ArrayBuffer TypedArray](https://www.jianshu.com/p/b9a77b1891a7)中介绍了处理二进制数组ArrayBuffer，现在来看一下Blob。Blob是Binary large object的缩写，它与ArrayBuffer的区别是除了raw bytes以外它还提供了mime type作为元数据。但它依然是无法直接被读写的。看一下构造函数：



```php
var aBlob = new Blob( array[, options])
// array可以为ArrayBuffer、ArrayBufferView、Blob、DOMStrings这些，或者他们的各种组合
// options： 包含type(如：MIME类型)和ending。
```

在[ArrayBuffer vs Blob and XHR2](https://stackoverflow.com/questions/7778115/arraybuffer-vs-blob-and-xhr2)中有如下回复：

> Blobs (according to spec anyway) have space for a MIME and easier to put into the HTML5 file API than other formats (it's more native to it).
>  You would use an ArrayBuffer when you need a typed array because you intend to work with the data, and a blob when you just need the data of the file

在[Binary World：ArrayBuffer、Blob以及他们的应用](https://github.com/abbshr/abbshr.github.io/issues/28)中有描述：

> ArrayBuffer似乎是Blob的底层，Blob内部使用了ArrayBuffer。并且构造好的一个Blob实体就是一个raw data。既然用途差不多，那为什么一个Blob一个ArrayBuffer呢？当然，设计Blob和ArrayBuffer的目的是不同的。因为ArrayBuffer更底层，所以它专注的是细节，比如说按字节读写文件。相反，Blob更像一个整体，它不在意细节：就是那么一个原始的Binary Data，你只要来回传输就行了。

# 二、Blob构造方式

## 1、创建一个装填DOMString对象的Blob对象



![img](https:////upload-images.jianshu.io/upload_images/2354823-2f5b8c1b2df5cf72.png?imageMogr2/auto-orient/strip|imageView2/2/w/313/format/webp)

## 2、创建一个装填ArrayBuffer对象的Blob对象



![img](https:////upload-images.jianshu.io/upload_images/2354823-7ddba30bb464a3e5.png?imageMogr2/auto-orient/strip|imageView2/2/w/339/format/webp)

##  3、创建一个装填ArrayBufferView对象的Blob对象（ArrayBufferView可基于ArrayBuffer创建，返回值是一个类数组。如下：创建一个8字节的ArrayBuffer，在其上创建一个每个数组元素为2字节的“视图”）

![img](https:////upload-images.jianshu.io/upload_images/2354823-6840e18e669bd694.png?imageMogr2/auto-orient/strip|imageView2/2/w/325/format/webp)

## 4.通过Blob.slice()

 此方法返回一个新的Blob对象，包含了原Blob对象中指定范围内的数据



```css
Blob.slice(start:number, end:number, contentType:string)
start：开始索引，默认为0
end：截取结束索引（不包括end）
contentType：新Blob的MIME类型，默认为空字符串
```

![img](https:////upload-images.jianshu.io/upload_images/2354823-7260def4c2297048.png?imageMogr2/auto-orient/strip|imageView2/2/w/404/format/webp)

## 5.通过canvas.toBlob()

```jsx
var canvas = document.getElementById("canvas");
canvas.toBlob(function(blob){
    console.log(blob);
});
```

![img](https:////upload-images.jianshu.io/upload_images/2354823-8fbfe2cb71d89748.png?imageMogr2/auto-orient/strip|imageView2/2/w/542/format/webp)

# 三、DOMString

跟着XMLHttpRequest闯南走北很多年，看名字似乎很嚣张且高深莫测。实际上，在JavaScript中，DOMString就是String。规范解释说DOMString指的是UTF-16字符串，而JavaScript正是使用了这种编码的字符串，因此，在Ajax中，DOMString就等同于JS中的普通字符串。

大家应该都与XMLHttpRequest中数据返回属性之responseText打过交道吧，按照我的理解，这厮就是与DOMString数据类型发生关系的，表明返回的数据是常规字符串。

# 四、File

FileList 对象针对表单的 file 控件。当用户通过 file 控件选取文件后，这个控件的 files 属性值就是 FileList 对象。它在结构上类似于数组，包含用户选取的多个文件。如果 file 控件没有设置 multiple 属性，那么用户只能选择一个文件，FileList 对象也就只有一个元素了。

```xml
<input type='file' multiple />
<script>
    document.querySelector('input').onchange = function() {
      console.log(this.files);
    };
</script>
```

比如我选择了两个文件，控制台打印：

```dart
FileList {0: File, 1: File, length: 2}
0: File
1: File
  length:2
__proto__: Object
```

![img](https:////upload-images.jianshu.io/upload_images/2354823-d07c71c3416c44fd.png?imageMogr2/auto-orient/strip|imageView2/2/w/797/format/webp)

- name：文件名，该属性只读。
- size：文件大小，单位为字节，该属性只读。
- type：文件的 MIME 类型，如果分辨不出类型，则为空字符串，该属性只读。
- lastModified：文件的上次修改时间，格式为时间戳。
- lastModifiedDate：文件的上次修改时间，格式为 Date 对象实例。

# 五、FileReader

FileReader 的实例拥有 4 个方法，其中 3 个用以读取文件，另一个用来中断读取。下面的表格列出了这些方法以及他们的参数和功能，需要注意的是 ，无论读取成功或失败，方法并不会返回读取结果，这一结果存储在 result属性中。

|       方法名       |       参数       |         描述         |
| :----------------: | :--------------: | :------------------: |
|       abort        |       none       |       中断读取       |
| readAsBinaryString |       file       | 将文件读取为二进制码 |
|   readAsDataURL    |       file       | 将文件读取为 DataURL |
|     readAsText     | file, [encoding] |   将文件读取为文本   |

readAsText：该方法有两个参数，其中第二个参数是文本的编码方式，默认值为 UTF-8。这个方法非常容易理解，将文件以文本方式读取，读取的结果即是这个文本文件中的内容。

readAsBinaryString：该方法将文件读取为二进制字符串，通常我们将它传送到后端，后端可以通过这段字符串存储文件。

readAsDataURL：这是例子程序中用到的方法，该方法将文件读取为一段以 data: 开头的字符串，这段字符串的实质就是 Data URL，Data URL是一种将小文件直接嵌入文档的方案。这里的小文件通常是指图像与 html 等格式的文件。

```jsx
// 填充选择的图片到展示区
var img = document.createElement("img");
img.classList.add("obj");
img.file = file;
preview.appendChild(img);

// 读取File对象中的内容
var reader = new FileReader();
reader.onload = (function (aImg) {
    return function (e) {
        aImg.src = e.target.result;
    };
})(img);
reader.readAsDataURL(file);
```

# 六、URL

```dart
//blob参数是一个File对象或者Blob对象.
var objecturl =  window.URL.createObjectURL(blob);
```

上面的代码会对二进制数据生成一个 URL，这个 URL 可以放置于任何通常可以放置 URL 的地方，比如 img 标签的 src 属性。需要注意的是，即使是同样的二进制数据，每调用一次 URL.createObjectURL 方法，就会得到一个不一样的 URL。

这个 URL 的存在时间，等同于网页的存在时间，一旦网页刷新或卸载，这个 URL 就失效。（File 和 Blob 又何尝不是这样呢）除此之外，也可以手动调用 URL.revokeObjectURL 方法，使 URL 失效。



```css
window.URL.revokeObjectURL(objectURL);
```

举个简单的例子。

```dart
var blob = new Blob(["Hello hanzichi"]);
var a = document.createElement("a");
a.href = window.URL.createObjectURL(blob);
a.download = "a.txt";
a.textContent = "Download";

document.body.appendChild(a);
```

页面上生成了一个超链接，点击它就能下载一个名为 a.txt 的文件，里面的内容是 Hello hanzichi。

这里插点题外话，简单介绍下 H5 新增的 download 属性。对于一些诸如 exe，rar 等浏览器不能直接打开的文件类型，我们一般可以直接用一个 a 标签，将其指向文件在服务端的地址，点击即可下载。但是如果是一些浏览器能直接打开的文件，比如 txt，js 等，如果这样设置一个超链接，点击会直接打开文件，一般我们可以配合后端实现，比如用 PHP。

我们再回到 URL 上来。对于 File 或者 Blob 对象，我们可以这样理解，它们的存在，依赖于页面，而 URL 能给这些 "转瞬即逝" 的二进制对象一个临时的指向地址。这个临时的地址还有什么用呢？也能做图片预览。

```xml
<input type='file' multiple /><br/>
<img />
<script>
document.querySelector("input").onchange = function() {
  var files = this.files;
  document.querySelector("img").src = window.URL.createObjectURL(files[0]);
}
</script>
```

# 七、Blob应用场景

## 1.分片上传

 File接口基于Blob，继承了Blob的功能并进行了扩展，故我们可以像使用Blob一样使用File对象。通过Blob.slice方法，可以将大文件分片，轮循向后台提交各文件片段，即可实现文件的分片上传。分片上传逻辑如下：

- 获取要上传文件的File对象，根据chunk（每片大小）对文件进行分片
- 通过post方法轮循上传每片文件，其中url中拼接querystring用于描述当前上传的文件信息；post body中存放本次要上传的二进制数据片段
- 接口每次返回offset，用于执行下次上传

```jsx
initUpload();

//初始化上传
function initUpload() {
    var chunk = 100 * 1024;   //每片大小
    var input = document.getElementById("file");    //input file
    input.onchange = function (e) {
        var file = this.files[0];
        var query = {};
        var chunks = [];
        if (!!file) {
            var start = 0;
            //文件分片
            for (var i = 0; i < Math.ceil(file.size / chunk); i++) {
                var end = start + chunk;
                chunks[i] = file.slice(start , end);
                start = end;
            }
            
            // 采用post方法上传文件
            // url query上拼接以下参数，用于记录上传偏移
            // post body中存放本次要上传的二进制数据
            query = {
                fileSize: file.size,
                dataSize: chunk,
                nextOffset: 0
            }

            upload(chunks, query, successPerUpload);
        }
    }
}

// 执行上传
function upload(chunks, query, cb) {
    var queryStr = Object.getOwnPropertyNames(query).map(key => {
        return key + "=" + query[key];
    }).join("&");
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "http://xxxx/opload?" + queryStr);
    xhr.overrideMimeType("application/octet-stream");
    
    //获取post body中二进制数据
    var index = Math.floor(query.nextOffset / query.dataSize);
    getFileBinary(chunks[index], function (binary) {
        if (xhr.sendAsBinary) {
            xhr.sendAsBinary(binary);
        } else {
            xhr.send(binary);
        }

    });

    xhr.onreadystatechange = function (e) {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                var resp = JSON.parse(xhr.responseText);
                // 接口返回nextoffset
                // resp = {
                //     isFinish:false,
                //     offset:100*1024
                // }
                if (typeof cb === "function") {
                    cb.call(this, resp, chunks, query)
                }
            }
        }
    }
}

// 每片上传成功后执行
function successPerUpload(resp, chunks, query) {
    if (resp.isFinish === true) {
        alert("上传成功");
    } else {
        //未上传完毕
        query.offset = resp.offset;
        upload(chunks, query, successPerUpload);
    }
}

// 获取文件二进制数据
function getFileBinary(file, cb) {
    var reader = new FileReader();
    reader.readAsArrayBuffer(file);
    reader.onload = function (e) {
        if (typeof cb === "function") {
            cb.call(this, this.result);
        }
    }
}
```

以上是文件分片上传前端的简单实现，当然，此功能还可以更加完善，如后台需要对合并后的文件大小进行校验；或者前端加密文件，全部上传完毕后后端解密校验等，此处不做赘述。

## 2.通过url下载文件

 window.URL对象可以为Blob对象生成一个网络地址，结合a标签的download属性，可以实现点击url下载文件
 实现如下：



```jsx
createDownload("download.txt","download file");

function createDownload(fileName, content){
    var blob = new Blob([content]);
    var link = document.createElement("a");
    link.innerHTML = fileName;
    link.download = fileName;
    link.href = URL.createObjectURL(blob);
    document.getElementsByTagName("body")[0].appendChild(link);
}
```

执行后页面上会生成此Blob对象的地址，点击后可下载：



![img](https:////upload-images.jianshu.io/upload_images/2354823-5995e017bdd197a9.png?imageMogr2/auto-orient/strip|imageView2/2/w/215/format/webp)

## 3.通过XHR请求显示图片

```jsx
var xhr = new XMLHttpRequest();    
xhr.open("get", "mm1.jpg", true);
xhr.responseType = "blob";
xhr.onload = function() {
    if (this.status == 200) {
        var blob = this.response;  // this.response也就是请求的返回就是Blob对象
        var img = document.createElement("img");
        img.onload = function(e) {
          window.URL.revokeObjectURL(img.src); // 清除释放
        };
        img.src = window.URL.createObjectURL(blob);
        eleAppend.appendChild(img);    
    }
}
xhr.send();
```

## 4.通过input type=File显示图片



```xml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>Document</title>
</head>
<body>
  <input type="file" id="fileElem" multiple accept="image/*"
  style="display:none" onchange="handleFiles(this.files)">
  <a href="#" id="fileSelect">Select some files</a> 
  <div id="fileList">
    <p>No files selected!</p>
  </div>

  <script>
    window.URL = window.URL || window.webkitURL;

    var fileSelect = document.getElementById("fileSelect"),
        fileElem = document.getElementById("fileElem"),
        fileList = document.getElementById("fileList");

    fileSelect.addEventListener("click", function (e) {
      if (fileElem) {
        fileElem.click();
      }
      e.preventDefault(); // prevent navigation to "#"
    }, false);

    function handleFiles(files) {
      if (!files.length) {
        fileList.innerHTML = "<p>No files selected!</p>";
      } else {
        fileList.innerHTML = "";
        var list = document.createElement("ul");
        fileList.appendChild(list);
        for (var i = 0; i < files.length; i++) {
          var li = document.createElement("li");
          list.appendChild(li);
          
          var img = document.createElement("img");
          img.src = window.URL.createObjectURL(files[i]);
          img.height = 60;
          img.onload = function() {
            window.URL.revokeObjectURL(this.src);
          }
          li.appendChild(img);
          var info = document.createElement("span");
          info.innerHTML = files[i].name + ": " + files[i].size + " bytes";
          li.appendChild(info);
        }
      }
    }
  </script>
</body>
</html>
```

