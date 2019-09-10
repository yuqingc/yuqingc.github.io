---
title: "笔记： navigator.sendBeacon"
lead: "如何在监听关闭页面时发送请求？"
date: 2019-09-10T11:07:17+08:00
toc: false
draft: false
tags:
  - javascript
categories:
  - notes
---

## 用途

- 关闭时的数据统计、数据分析和埋点

## 监听事件
### `beforeunload`
- 以下代码可以使用户在关闭、刷新、切换路由页面的时候弹出弹框，询问用户是否关闭。
- 必须在用户和页面发生过交互才会触发，比如点击过页面
```js
window.addEventListener("beforeunload", function (event) {
  event.preventDefault();
  // 有些浏览器需要设置 returnedValue
  event.returnValue = '';
});
```
### `unload`
```js
window.addEventListener("unload", logData, false);

function logData() {
  // ...
}
```

### 两个都监听？

为了避免有些浏览器不支持，保证函数的执行，我们可以两个事件都监听。但是，为了避免重复，我们只想要函数执行一次，可以对函数做一些处理，比如

```js
function once (fn) {
  let hasRun = false;
  return function () {
    if (!hasRun) {
      hasRun = true;
      fn();
    }
  };
}
const sendOnce = once(function () {
  //  这个函数只执行一次
});
window.addEventListener("beforeunload", sendOnce);
window.addEventListener("unload", sendOnce);
```

## 页面都关闭了还怎么发请求？

### 发送同步请求，推荐指数 👎 

如果直接发异步请求，页面关闭了，请求会被 abort 掉。所以传统的方法，是发同步请求。缺点是，请求会阻塞监听函数，导致页面的关闭和跳转十分缓慢。发同步请求一般有两种方案

- 发送同步 ajax 请求
- 创建一个 `<img>` 元素，然后把该元素的 `src` 属性设置为请求的地址

### 使用 [`Navigator.sendBeacon()`](https://developer.mozilla.org/zh-CN/docs/Web/API/Navigator/sendBeacon) 👍

> 使用 `sendBeacon()` 方法会使用户代理在有机会时异步地向服务器发送数据，同时不会延迟页面的卸载或影响下一导航的载入性能。这就解决了提交分析数据时的所有的问题：数据可靠，传输异步并且不会影响下一页面的加载。此外，代码实际上还要比其他技术简单许多！

```js
window.addEventListener('unload', logData, false);

function logData() {
    navigator.sendBeacon("/log", analyticsData);
}
```

- 👉 阅读 [MDN 文档](https://developer.mozilla.org/zh-CN/docs/Web/API/Navigator/sendBeacon)
