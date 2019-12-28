---
title: "使用 Node.js 实现一个简单的 SSE 服务"
date: 2019-12-28T15:27:12+08:00
draft: false
toc: false
---

网上有很多 Demo 介绍了如何使用 SSE。但是真正向客户端发送请求是一个持续的过程，因此需要有一个很好的解决方案来管理这些长链接。目前网上的一些 Demo 和博客基本上都是在请求的 Controller 中直接向客户端发送。所以它们也只能是 Demo。

<!--more-->

## 什么是 SSE？

互联网可以轻松搜索到关于 SSE 的标准，因此不赘述。本文主要介绍 Node.js 的实现

> 见 [MDN 文档](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)

## 客户端示例

```js
const sse = new EventSource('/sse');
sse.onerror = (err) => {
  console.error('An error occurred!!', err);
};
sse.onmessage = (e) => {
  console.log('Received message: ', e.data);
};
```

## 服务端实现

### 准备

#### Framework

- 本文使用 Express.js 为服务端框架，其他框架原理相似

#### 安装 `ssestream`

需安装 NPM 包 [`ssestream`](https://www.npmjs.com/package/ssestream)。该包封装了对 HTTP Header 的一些简单的处理。以下是其代码核心片段。

```js {linenos=table,hl_lines=["4-7","9"]}
pipe(destination, options) {
  if (typeof destination.writeHead === 'function') {
    destination.writeHead(200, {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Transfer-Encoding': 'identity',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    })
    destination.flushHeaders()
  }
  // Some clients (Safari) don't trigger onopen until the first frame is received.
  destination.write(':ok\n\n')
  return super.pipe(destination, options)
}
```

可以看出，SSE 需要在在 HTTP 响应的 Header 为

```
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
```

需要注意这里使用了 [`flushHeaders()`](https://nodejs.org/dist/latest-v12.x/docs/api/http.html#http_request_flushheaders) 来设置 Header。如果不调用这个函数，在第一条响应返回客户端之前或者调用 `response.end()` 之前是不会写入真正的响应 Header 的，而是把这些 Header 缓存起来。因为我们不需要立即向客户端发送消息，所以我们先把 Response Header 返回给客户端。

### 使用

```js {linenos=table,hl_lines=["5-9"]}
'use strict'
const express = require('express');
const app = express();

const mySseServer = new SseServer(
  {
    maxConnections: 3, // 设置最大链接数量
  }
)

app.use('/sse', mySseServer.middleWare());

const port = 8888;
app.listen(port, () => {
  console.log(`App is listening to port :${port}`);
});

// 模拟向客户端推送消息
setInterval(() => {
  // 当前链接的数量
  console.log('current connect number:', mySseServer.sseConnections.size);
  mySseServer.announce(`It is ${new Date()} now!`);
}, 2000);
```
<br>

### 实现 `SseSever` 类

下面就看一下这个 `SseServer` 是如何实现的

```js
const SseStream = require('ssestream');
class SseServer {
  constructor (options) {
    // 用来缓存当前所有的链接用来之后发送消息
    this.sseConnections = new Set()
    // 设置最大链接数
    this.maxConnections = options.maxConnections || Infinity;
    this.middleWare = this.middleWare.bind(this);
    this.announce = this.announce.bind(this);
  }
  middleWare () {
    return (req, res) => {
      const sseConnections =  this.sseConnections;
      // 超过最大链接数的时候需要拒绝客户端请求
      if (sseConnections.size >= this.maxConnections) {
        return res.status(429).send()
      }
      const sse = new SseStream(req);
      // 详见 ssestream 的 api
      sse.pipe(res);
      const metaData = [sse, req, res];
      // 写入链接缓存
      sseConnections.add(metaData)
      // 与客户端链接断开时需要清除链接缓存
      req.on('close', function () {
        console.log('CONNECTION CLOSED!!!')
        sseConnections.delete(metaData)
      })
    }
  }
  // 向客户端广播消息
  announce (data) {
    this.sseConnections.forEach((meta) => {
      const [sse, req, res] = meta
      const message = {
        data,
      };
      meta[0].write(message);
    })
  }
}
```

本文仅展示核心原理。如需提高代码健壮性，需要有更多的错误处理以及缓存长度检查机制以防止内存泄漏。

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
