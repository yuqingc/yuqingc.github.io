---
title: "Cheatsheet 系列 之 HTTP"
lead: ""
date: 2020-07-22T22:50:17+08:00
draft: false
toc: true
categories:
  - "blogs"
tags:
  - "http"
  - "cheatsheet"
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
