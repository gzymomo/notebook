- [微信小程序获取cookie以及设置cookie_幻想山外小楼听雨的博客-CSDN博客_微信小程序获取cookie](https://blog.csdn.net/promiseCao/article/details/84564094)
- [微信小程序如何在使用wx.request使用cookie](https://www.cnblogs.com/jerryqi/p/9717925.html)

小程序开发中我们需要获取到后端给的cookie进行请求验证,但是微信并没有帮我们保存cookie,那么我们要维持会话需要自己来保存cookie,并且请求的时候加上cookie

1.获取cookie

在登录请求后读取 返回值的, [header](https://so.csdn.net/so/search?q=header&spm=1001.2101.3001.7020)的cookie,并本地存储

```javascript
//登录请求回来之后,读取res的header的cookie
//这里的sessionid随便写的,就是个唯一标识
 wx.setStorageSync("sessionid", res.header["Set-Cookie"])
```

2.请求带上cookie

```javascript
  //创建header 
  var header;
  header = { 
     'content-type': 'application/x-www-form-urlencoded', 
     'cookie':wx.getStorageSync("sessionid")//读取cookie
  };
  //进行请求,一般外层都有一个封装,然后放在公共类里边
  wx.request({
    url: realURL,
    method: method,
    header: header,//传在请求的header里
    data: datas,
    success(res) {
    //请求成功的处理
    }
  )}
```

3.接下来需要将sessinid在本地管理的方法

```javascript
var sessionkey;
 
var sessiondate;
 
//可以封装一个保存sessinid的方法，将sessionid存储在localstorage中，定为半小时之后清空此sessionid缓存。
function saveSession(sessionId) {
   console.log(" now save sessionid: " + sessionId)
   wx.setStorageSync(“sessionkey” sessionId)//保存sessionid
   wx.setStorageSync(“sessiondate”, Date.parse(new Date()))//保存当前时间，
}
 
// 过期后清除session缓存
function removeLocalSession() {
  wx.removeStorageSync(“sessionid的key”)
  wx.removeStorageSync(sessiondate)
  console.log("remove session!")
}
 
 
 
//检查sessionid是否过期的方法
 
function checkSessionTimeout() {
  var sessionid = wx.getStorageSync(sessionkey)
  if (sessionid == null || sessionid == undefined || sessionid == "") {
    console.log("session is empty")
    return false
  }
  var sessionTime = wx.getStorageSync(sessiondate)
  var aftertimestamp = Date.parse(new Date())
  if (aftertimestamp - sessionTime >= SESSION_TIMEOUT) {
    removeLocalSession()
    return false      
  }
  return true
 
｝
 
//如果sessionid过期，重新获取sessionid
 
function checkSessionOk() {
  console.log("check session ok?...")
  var sessionOk = checkSessionTimeout()
  if (!sessionOk) {
    requestsessionid(function () {
    })
  }}
 
 
 
//定义一个方法每隔一段时间检查sessionid是否过期
 
function checkcrosstime() {
   setInterval(checkSessionTimeout, ----)//这个时间可以自定义。比如25 * 60 * 1000（代表25分钟）
}
```

可以在app.js的onload方法中运行checkcrosstime()方法