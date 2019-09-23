---
title: "笔记：\"async_hooks\""
date: 2019-09-23T15:36:26+08:00
draft: true
toc: false
---

*关于 API 的细节，查看 [官方文档](https://nodejs.org/api/async_hooks.html)*

## async_hooks 的作用

Node.js 官方文档中的定义

> The async_hooks module provides an API to register callbacks tracking the lifetime of asynchronous resources created inside a Node.js application. 
>
> async_hooks 模块提供了一个可以注册回调函数的 API，这些回调函数可以追踪在 Node.js 应用内创建的异步资源的生命周期

这个定义比较抽象，往后看

## Get started

### 何为异步资源？

当我们使用 Node.js 进行发送网络请求、用作 web 服务器监听端口的数据、向文件中读写数据等操作时，Node.js 可以调用这些资源（网络资源、磁盘资源等待），并且在特定事件触发的时，异步地调用对应的回调函数，比如 `fs.open()` 函数会在文件打开完成或者失败时 *异步* 地调用回调函数。

异步资源 （asynchronous resource）可以表示为一个 js 对象，这个对象可以理解为一个事件监听器，它将一个事件和一个回调函数对应起来，当事件触发的时候，就会调用这个回调函数。有些事件可能会触发多次，有些事件可能会被触发一次，而有些事件可能永远不会被触发。举个例子，`fs.open()` 用来异步地打开文件，当文件打开完成（成功或失败）时，会调用对应的回调函数,这个回调函数只会执行一次。再举个例子，`net.createServer()` 在监听到端口有链接时会触发 `connection` 事件，从而调用对应的回调函数，而这个事件可能会被多次触发。

### 准备工作：实现一个同步在控制台输出日志的函数

由于 async_hooks 的生命周期函数（也可以叫作 hooks、钩子，下文会介绍）会在监听到异步资源被创建的时候调用，而 `console.log()` 函数本身就是一个 *异步* 操作，所以在 async_hooks 生命周期内部调用 `console.log()` 函数会导致生命周期函数被无限循环调用。因此，我们需要手动实现一个同步在控制台打印日志的函数。在生命周期函数内进行其他异步操作同样也会导致无限循环。

```js
function println (...args) {
  let s = ''
  for (let i = 0; i < args.length; i++) {
    if (i < args.length - 1) {
      s += args[i] + ' '
    } else {
      s += args[i] + '\n'
    }
  }
  // 参数 1 是标准输出 stdout 的文件描述符
  fs.writeSync(1, s)
}
```

### async_hooks 生命周期介绍

async_hooks 可以提供一个监听异步资源各个生命周期的 api，在这些异步资源的各个生命周期，可以调用对应的钩子函数

#### `init`

前文提到的异步资源对象在被创建（construction）好的时候会调用 `init` 生命周期函数。当 `init` 钩子被执行的时候，说明这个异步资源对象创建好了，这个对象可以进行上文所述的事件监听和调用回调函数。但是 `init` 被调用仅仅代表这个对象创建好了，并不意味着这个对象代表的 *资源* 已经创建好了。这个生命周期会有一个 `asyncId` 的参数（官网有 API 的各个参数介绍），这时候这个 `asyncId` 代表的资源可能是空的。

#### `before`

在上文所述的回调函数被调用之前调用

#### `after`

在上文所述的回调函数调用、错误处理结束之后调用

#### `destroy`

在资源销毁时调用。注意，有些资源会被 GC （垃圾回收）清理掉，这种资源是不会调用 `destroy` 的，如果这种资源在 `init` 阶段被引用了，那么它可能会无法被释放，从而造成内存泄漏。

#### `promiseResolve`

顾名思义，在一个 Promise resolve 的时候会触发这个生命周期函数

### 代码示例

各个生命周期函数的参数的含义请看 [API 文档](https://nodejs.org/api/async_hooks.html)

```js
// hook 对象用来监听异步资源的各个生命周期
// 我们需要传入各个生命周期函数
const hook = async_hooks.createHook({
  init (asyncId, type, triggerAsyncId, resource) {
    println('init')
  },
  before (asyncId) {
    println('before')
  },
  after (asyncId) {
    println('after')
  },
  destroy (asyncId) {
    println('destroy')
  },
  promiseResolve (asyncId) {
    println('promiseResolve')
  }
})

// 开启监听
hook.enable()

// 结束监听
hook.disable()
```

### 获取上下文相关信息的 API

这两个函数在异步函数内调用，可以获取当前异步函数的上下文信息

#### `async_hooks.executionAsyncId()`

当前异步函数所对应异步资源的 asyncId

#### `async_hooks.triggerAsyncId()`

调用这个异步函数的函数所对应的资源的 asyncId
