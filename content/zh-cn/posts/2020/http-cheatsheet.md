---
title: "Cheatsheet 系列 之 HTTP（一）"
lead: ""
date: 2020-07-22T22:50:17+08:00
draft: false
toc: true
categories:
  - "posts"
tags:
  - "http"
---

*打算开始更新 Sheetsheet 系列。记录一些容易遗漏的知识点。这是第一期：HTTP。*

<!--more-->

---

## 概览

### HTTP 的基本组件

- Client 客户端（user-agent）
- Server 服务端
- Proxy 代理

### HTTP 的特点

- 简单
- 可扩展
- Stateless, but not sessionless（无状态，但是有会话，可以通过 Cookie 存储会话信息和状态）

### HTTP 连接

- 无需关心底层协议（TCP）
- 可以通过 `Connection` 这个 Header 字段来查看连接属性
- HTTP/1.0 默认每个请求一个单独的连接，默认 `Connection: close`
- HTTP/1.1 默认开启 `keep-alive`，即每个会话中每个请求结束之后连接不关闭
- HTTP/2.0 支持连接多路复用，单个连接可以发送多个请求

### HTTP 的控制范围

- 控制缓存。包括缓存的时机、内容、规则等
- 限制/开放同源策略。浏览器默认禁止跨域（源）访问资源。但是 2010 年之后，这个限制放开了。服务端可以通过设置对应的 Header 来放开这些限制
- 认证。通过特定的 Header 如 `WWW-Authenticate` 或 Cookie
- 代理
- Session。通过 Cookie 实现有状态的 Session

### HTTP 流程

1. 开启 TCP 连接。可以开启新连接、复用现有连接、甚至可以开启多个连接
2. 发送 HTTP 报文（message）。HTTP/1.x 中的报文是可阅读的字符串。HTTP/2 中的报文被封装成二进制的**帧（frame）**
3. 服务端响应，客户端读取响应
4. 关闭连接

### HTTP 报文

- HTTP/1.x 的报文可读
- HTTP/2.x 的报文封装成了帧，二进制形式。支持压缩、复用，效率更高，更节省网络资源
- 客户端重新组装 HTTP/2 的报文。组装后的报文格式可以是 HTTP/1.x 的格式。

- **报文分两种**
  - 请求报文
  - 响应报文

#### 请求报文的组成

- method
- URL/Path
- HTTP 协议版本
- Header
- Body

#### 响应报文的组成

- HTTP 协议版本
- Status code
- Status message
- Header
- Body

### 基于 HTTP 的 API

- Ajax (`XMLHttpRequest`)
- `Fetch API`
- Server-sent Event (`EventSource`)
- 注意 WebSocket API 不是基于 HTTP 协议，是基于 WebSocket 协议

---

## HTTP 报文

### 概览

- 分为 Request message 和 Response message
- HTTP/1.1 以前的报文是明文(ASCII)发送的
- HTTP/2 之后的报文是通过 HTTP Frame 发送的

#### Request 和 Response 共同都有的部分

- Start line
- Headers
- 空行
- 可选的 body

### HTTP Request

- Start line

  - method + target + version
  - 如 `POST / HTTP/1.1`

- Headers

  - General Headers
  - Request Headers
  - Entity Headers 给 Body 使用，含有 Body 的某些属性。比如 `Content-Type`

- Body

  - 单资源 Body。使用 `Content-Type` 和 `Content-Length` 定义
  - 多资源 Body。比如使用 HTML Form

### HTTP Response

- Status line `HTTP/1.0 404 Not Found`
- Headers
  - General Headers
  - Request Headers
  - Entity Headers
- Body

### HTTP/2 Frame

#### HTTP/1.x 报文的缺点

- Header 无法像 Body 那样可以压缩
- 不同报文的 header 很多字段都重复了，无法复用
- 无法复用连接

#### HTTP/2 Frame

- 多路复用，高效利用 TCP 连接
- Frame 对于开发者来说是透明的，无需更改 API。客户端和服务端会自动解压


---

## HTTP 缓存

### 缓存的种类

- Private cache （浏览器缓存）
- Shared cache （proxy 缓存）
- 其他缓存
  - gateway caches
  - CDN
  - reverse proxy caches
  - load balancers

### 缓存控制

#### `Cache-Control` Header

- `no-store` 完全不缓存
- `no-cache` 发送缓存之前，服务端先验证该缓存
- `public` 可以缓存在公共缓存代理服务器上
- `private` 只能缓存在浏览器
- `max-age=10000` 秒，相对于请求发起的时间
- `must-revalidate` 缓存必须先验证过期资源的状态是否有效

#### `Pragma` Header

- 这是 HTTP/1.0 的字段

### 缓存 freshness

- 在过期时间之前，缓存是 fresh
- 过期时间之后，缓存是 stale
- Stele 的缓存不会直接被清除或者忽略，而是会带上 `If-None-Match` 查询缓存是否仍然 fresh
- 若缓存 fresh，服务端返回 `304(Not Modified)`

#### 缓存寿命计算顺序

- `Cache-Control: max-age=N` `N` 就是缓存寿命
- `Expires - Date`
- `(Date - Last-Modified) / 10` 优先级最低，这个是一个估计的时间

### 缓存验证

#### `ETag`

- `ETag` 是服务端返回的服务端定义的一个用来标识资源的额字符串。客户端无需知道其意义
- 如果响应 Header 有 `ETag`，则客户端需要使用 `If-None-Match` 来进行缓存验证
- `Last-Modified` 可以用来弱验证。通过 `If-Modified-Since` 向服务端发起验证
- 服务端可以返回 `200 Ok` 和新的资源，也可以返回 `304 Not Modified`; `304` 可以带上新的 Header 来更新缓存的过期时间

### Vary 缓存

- 利用 `Vary` 字段区分缓存是否需要更新
- 只有当缓存的 `Vary` 字段中规定的项目和新请求的 `Vary` 的字段匹配的时候，才会使用缓存资源
- 比如 `Vary: User-Agent` 时，只有当缓存的 `User-Agent` 和请求的 `User-Agent` 匹配时，才会返回缓存的资源

---

## Cookie

### 概述

- Session 管理
- 个性化
- 跟踪用户行为（记录、统计）
- 如果需要在客户端大量存储数据，建议使用 Web Storage API 和 IndexedDB


### 创建 Cookie

#### 字段

- 服务端响应带上 `Set-Cookie`
- 客户端发送请求带上 `Cookie`

#### 有效期

- 在 Cookie 中设置 `Expires`
- `Set-Cookie: id=a3fWa; Expires=Wed, 31 Oct 2021 07:28:00 GMT;`
- 如果没有设置，则默认值为 `session`，仅在浏览器关闭之前有效

### Cookie 访问限制

- Cookie 中的 Secure 字段只允许 HTTPS 请求带上该 Cookie；HTTP 的服务器无法设置 Secure 字段
- 设置了 `HttpOnly` 字段的 Cookie 无法被 JS 的 `Document.cookie` API 访问。可以有效预防 XSS 攻击
- 示例 `Set-Cookie: id=a3fWa; Expires=Wed, 21 Oct 2021 07:28:00 GMT; Secure; HttpOnly`

### 域名和路径

#### `Domain` 字段

- 默认为设置该 Cookie 的域名，并且**不包含**子域名
- 如果指定了 Domain，会包含子域名

#### `Path`

- 指定了 `Path=/a`，则 `/a` 及其子路径都可以匹配

#### `SameSite`

- 可以限制跨与请求发送 Cookie。（这里的注册的子域名 a.b.com 和 b.com 是同一个网站 site）
- 可以防止 CSRF 攻击
- 可以有以下值
  - `Strict` 值允许同一个网站的请求
  - `Lax` 和 `Strict` 类似，但是从其他网站点链接导航到这个网站除外，这时候可以发送 Cookie
  - `None` 没有限制。但是现在的浏览器规定 `None` 只有在设置了 `Secure` 才会生效

#### Cookie 前缀规则

- 带有 `__Host-` 只有同时满足以下条件才会 `Set-Cookie` 生效
  - 设置了 `Secure`
  - 来自 https
  - 没有设置 `Domain`
  - `Path=/`

- `__Secure-` 宽松一些
  - 设置了 `Secure`
  - 来自 https

- 上述条件如果不满足，就会被浏览器拒绝

#### JS 操作 Cookie
- JS 通过 `document.cookie` 读取和创建 Cookie
- JS 不能读取 `HttpOnly` 的 Cookie
- JS 不能创建带有 `HttpOnly` 的 Cookie

### 安全问题

#### 第三方 Cookie

- 同一个域名的 Cookie 被成为第一方 Cookie
- 不同域名的 Cookie 被成为第三方 Cookie
- 第三方 Cookie 可以用来构建用户画像
- 火狐默认阻止含有 tracker 的第三方 cookie

#### 隐私政策

- 欧盟相关法律规定了必须告知用户 Cookie 的使用并且用户可以拒绝使用

## HTTP 连接管理

### 种类

- 短连接 short-lived connection 每次请求都要开一个新的 TCP 连接，性能不好
- 长连接 persistent connection 多个请求之后才关闭连接
- 流水线 pipelining 不需要等响应，可以先发送多个请求

### 链接管理

- 使用了 Hop-by-hop 的 Header，比如 `Connection`。这种 Header 不允许通过 proxy 透传到最终的服务器（或反过来）。每一跳的连接都是不同的（我自己的理解）。不允许代理和缓存。
- 另一种 Header 是 End-to-end 的。要求从客户端需要通过一层层代理，传到最终的服务器。proxy 需要转发，缓存也必须存下来。


## HTTP 协议升级

- 使用 `Upgrade` Header，允许把当前的连接转为另一个协议
- HTTP/1.1 的特性，一般用来启动 WebSocket
- HTTP/2 禁用了此特性

### 步骤

- 客户端发起一个请求 `Connection: upgrade` 和 `Upgrade: 新协议名`
- 如果服务端可以，则返回 `101 Switching Protocols` 然后开始新的协议的连接
- 如果服务端不支持，则返回普通的 `200 Ok`

### WebSocket

#### 开启 WebSocket

```js
webSocket = new WebSocket("ws://destination.server.ext", "optionalProtocol");
```

- 调用这个 API，浏览器会自动处理由 HTTP/1 到 WebSocket 的升级。如果需要自己处理，那就要自己处理 TCP 握手。
- 需要包含下列 Header

  ```
  Connection: Upgrade
  Upgrade: websocket
  ```

#### WebSocket 相关的其他 Header

- 参考 https://developer.mozilla.org/en-US/docs/Web/HTTP/Protocol_upgrade_mechanism#Upgrading_to_a_WebSocket_connection

## CORS

如果 CORS 失败了，JS 无法捕获错，只能通过控制台看到错误日志

### 什么算 Cross-Origin

只要下列有一项不同，即为 Cross-Origin（所谓的“跨域”，其实我认为翻译成“跨源”更为准确）

- 协议
- 域名
- 端口号

### 哪些请求适用 CORS

- Ajax 或 `Fetch API` 发送的请求

- Web Fonts （在 CSS 中使用 `@font-face` 定义的字体）

- WebGL Texture

- 使用 `drawImage()` 的 Canvas

- 使用图片的 CSS Shapes


### 同时满足下列条件浏览器不会发送 Preflight（OPTION 请求）

- Method 为下列之一

  - GET

  - HEAD

  - POST

- 手动设置的 Header 只能是：

  ```
  Accept
  Accept-Language
  Content-Language
  Content-Type (but note the additional requirements below)
  DPR
  Downlink
  Save-Data
  Viewport-Width
  Width
  ```

- `Content-Type` 只允许：

  - `application/x-www-form-urlencoded`

  - `multipart/form-data`

  - `text/plain`

- 不能监听任何 `XMLHttpRequestUpload` 对象，即 `XMLHttpRequest.upload`

- 请求不能使用 `ReadableStream`

### 发送流程

- Request

  - 发送 OPTIONS 请求
  - 发送 `Access-Control-Request-Method` 和 `Access-Control-Request-Headers`

- 响应

  - 响应 Header 包含

  ```
  Access-Control-Allow-Origin: http://foo.example
  Access-Control-Allow-Methods: POST, GET, OPTIONS
  Access-Control-Allow-Headers: X-PINGOTHER, Content-Type
  Access-Control-Max-Age: 86400
  ```

### `withCredentials`

- 浏览器发送任何跨与请求时，默认不会带上 Cookie
- 把 Ajax 或 Fetch 的 `withCredentials` 设置为 `true` 会发送 Cookie
- 如果服务端的返回 Header 没有 `Access-Control-Allow-Credentials: true` 浏览器会拒绝返回的内容

#### 关于 `Access-Control-Allow-Origin` 的通配符

- 服务端在响应带有 Cookie 的跨域请求时，必须指定 `Access-Control-Allow-Origin`，而不能用 `*` 通配符

### 相关 Header

- Response Headers

  ```
  Access-Control-Allow-Origin
  Access-Control-Allow-Methods
  Access-Control-Allow-Headers
  Access-Control-Expose-Headers 允许客户端可以读取到的 Header
  Access-Control-Max-Age
  Access-Control-Allow-Credentials
  ```

- Request Headers

  ```
  Origin
  Access-Control-Request-Method
  Access-Control-Request-Headers
  ```

## HTTP 压缩

HTTP 压缩有三个层面

- 文件格式压缩
- 端到端压缩（end to end）
- 节点之间的压缩（hop by hop）

### 文件格式压缩

- 无损压缩 `gif` 和 `png`
- 有损压缩，Web 视频以及 `jpeg`

有些格式既可以有损，也可以用作无损压缩，比如 `webp`

*已经压缩过的文件不要使用以下的压缩技术*

#### 端到端压缩

- 服务端压缩，中间的 proxy 不动数据，直到客户端解压
- 常用的压缩算法
  - gzip，最常用
  - br，新的

#### 过程

- 客户端请求带上 `Accept-Encoding`
- 服务端带上 `Content-Encoding` 和 `Vary: Accept-Encoding` 的 Header 以及经过压缩的内容
- 建议所有的内容都要这样压缩，除了已经压缩的图片或者视频

### Hop-by-hop 压缩

不同节点之间的压缩协议

- 使用 `Transfer-Encoding` header，一般在代理服务器使用，对于客户端和服务端两个终端来说是透明的

## HTTP 重定向

Redirect 也叫 Forwarding。实现了以下功能：

- 临时 比如服务器暂时不可用的时候
- 永久

### 原理

- 服务端返回 `3xx` 状态码
- Header 中的 `Location` 带有重定向的 URL
- 浏览器收到 URL 之后马上请求新的 URL，用户一般很难察觉

重定向氛围下面的种类

- 永久重定向
- 临时重定向
- 特殊重定向

#### 永久重定向

搜索引擎、RSS 等爬虫会因此更新新的 URL

- `301 Moved Permanently` 重定向，GET 不变，允许 Method 改变
- `308 Permanent Redirect` 不允许 Method 由 POST 改为 GET

#### 临时重定向

- `302 Found` GET 不变，其他方法不能变为 GET
- `303 See Other` GET 不变，其他方法变为 GET（去掉 body）
- `307 Temporary Redirect` Method 不允许改变


#### 特殊重定向

- `300 Multiple Choice`
- `304 Not Modified` 用于重新验证缓存的请求，缓存的资源还没过期

### 其他重定向

#### HTML 重定向

```html
<head> 
  <!-- 0 代表重定向之前等待的时间 -->
  <meta http-equiv="Refresh" content="0; URL=https://example.com/">
</head>
```

#### JS 重定向

```js
window.location = ''
```

### 使用场景

参考 https://developer.mozilla.org/en-US/docs/Web/HTTP/Redirections
