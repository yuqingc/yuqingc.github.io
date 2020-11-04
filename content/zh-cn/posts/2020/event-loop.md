---
title: "JS 异步背后的故事 —— Event Loop"
date: 2020-10-05T16:04:16+08:00
draft: false
categories:
  - "posts"
tags:
  - "javascript"
---

*异步*、*Event Loop*、*Microtask* 这些词语对于一个 JavaScript 开发者来说并不陌生，今天专门抽出一篇文章来聊一聊这些东西。

## 从一段代码说起

下面的一段代码，频繁出现在网络上。`console.log` 打印的顺序似乎暗示着 JS 内部事件循环的一些机制。来看一下这段代码：

```js
setTimeout(() => {
  console.log('timer1');
  Promise.resolve().then(() => console.log('promise1'));
}, 0);

setTimeout(() => {
  console.log('timer2');
  Promise.resolve().then(() => console.log('promise2'));
}, 0);
```

在浏览器中，结果如下

```txt
timer1
promise1
timer2
promise2
```

在 Node.js 中运行，结果会不一样：

```txt
timer1
timer1
promise1
promise1
```

其实，当我自己运行这段代码的时候，发现其实上面的说法不完全准确。当 Node 版本为 11 及以上时，输出的结果就和浏览器的行为一致了。

同样都是 JS，而且引擎都是 V8（Chrome），是什么造成了这些差异呢？

## 基本概念

在聊事件循环之前，先看一些基本概念：

### 调用栈（Call Stack）

来看下面的代码

```js
function foo() {
  console.log('Foo');
}

function bar() {
  foo();
}

bar();
```

运行 JS 程序时，内存中会有两块区域会被初始化，并被进程所使用。其中一个是 FILO（First In Last Out 先进后出） 的栈（Stack），另一个是堆（Heap）。代码运行过程中，调用栈发生了如下变化：（如果学过汇编，对这个过程应该会比较了解）

- 当代码运行至 `bar()` 时，第一个栈帧（Frame）会被 push 到栈中，Frame 中包含了 `bar()` 的参数及其局部变量。

- 当代码运行到 `bar()` 中的 `foo()` 时，第二个 Frame 会被 push 到栈中。同样的当代码运行到 `foo` 中的 `console.log()` 时，第三个 Frame 会被 push 到栈中。

- 等到 `console.log()` 函数执行完毕，函数返回，栈顶部的 Frame 会被 pop 出栈。以此类推，各个函数依次返回，直到调用栈所有的 Frame 都被 pop 出栈，调用栈清空。

如果我们在 `foo` 函数中抛出错误，我们在浏览器中就可以看到调用栈信息了

代码：

```js
function foo() {
  throw new Error('抛出错误了');
}
```

打印出来的调用栈信息（简化）

```txt
Uncaught Error: 抛出错误了
    at foo
    at bar
    at <anonymous>
```

其中 `anonymous` 可以理解为一个匿名函数，这个函数在整个脚本的最外层。虽然代码没有显式写出这个函数，但是解释器执行代码的时候，最外层是有这么一个函数的。

<img style="text-align:center; margin: 10px;" src="/images/js-memory-model.svg">

*图片来自 [MDN](https://mdn.mozillademos.org/files/17124/The_Javascript_Runtime_Environment_Example.svg)*

### 堆（Heap）

JS 中的对象一般在堆区分配。“堆”这个词和数据结构课程中的“堆”不一样。因为一般存储大数据结构，因此起了一个名字，用以区分栈。

### 消息队列（Message Queue）

JS 使用 FIFO（First In First Out 先进先出）的消息队列来处理异步事件循环。消息队列中的每个消息会绑定一个函数，这些函数会按队列的顺序被调用。

在 JS 的 Event Loop 中，每个消息队列会把所谓的“消息”作为参数，来依次调用队列中的函数。每调用一个函数，一个消息就会出队列（从队列中移除）。每个函数执行的时候，就会创建一个新的 Frame，并被 push 到调用栈中。

等到调用栈再次清空时，Event Loop 会处理下一个消息队列，直到所有的消息队列处理完毕。

## 浏览器中的 Event Loop 概述

### 任务（Task）

我们把每次函数的一次执行，直到调用栈被清空的过程称为**任务**。任务可以是一个 JS 程序最开始执行的代码，或者是事件的回调，也可以是定时器（`setTimeout`, `setInterval`）的回调函数。“任务”是相对于 Microtask 的一个概念，因此任务会被某些文章称为“Macro Task（宏任务）”。所有的任务都被任务队列所调用。下列场景下，任务会被添加至任务队列。

- 新的 JS 程序的执行，如在控制台执行的代码，或者是 `<script>` 标签中的代码

- 事件触发时，回调函数会被加入任务队列

- 当 `setTimeout()` 或 `setInterval()` 到达预定的时间时，其回调函数也会被加入任务队列

任务队列和上文所说的消息队列，在某些角度可以理解为同一个（或相似）概念。

Event Loop 会检查当前的任务队列中是否有任务，如果有会依次执行。在本轮 Event Loop 中，新加入队列的任务不会被执行。这些新加入的任务会在下一轮 Event Loop 被执行。

### Microtask

Microtask 又被称为微任务。JS 中的 Promise 和 [Mutation Observer API](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver) 使用了 Microtask。与任务的区别：

- 每次每个任务结束时，Event Loop 会检查当前的任务是否将会把控制权交给其他 JS 代码，如果没有，则会执行 Microtask 队列中的所有 Microtask

- 在执行 Microtask 队列中的 Microtask 时，如果有新的 Microtask 被添加进队列（使用 `queueMicrotask()`），这些 Microtask 会在本次 Event Loop 全部执行，直到没有新的 Microtask 被添加到队列为止

### Web API

其实，如 `setTimeout()`, `setInterval()`, `Fetch API`, `XHR` 等 API 都是浏览器提供的 API（并非 V8 自带）。V8 仅仅负责语言的解析和执行，Event Loop 处理异步的行为，其实也是浏览器自己实现的。

这些 API 都需要提供回调函数，每当特定的事件触发，这些回调函数就会被送入相应的任务队列。

### 代码分析

回头看文章开头的代码

```js
setTimeout(() => {
  console.log('timer1');
  Promise.resolve().then(() => console.log('promise1'));
}, 0);

setTimeout(() => {
  console.log('timer2');
  Promise.resolve().then(() => console.log('promise2'));
}, 0);
```

执行这段代码时，浏览器处理过程如下

- 运行至第一个 `setTimeout()` 函数，并设置定时器。因为设置的时间为 0（事实会有些不一样，下文会说），所以直接将回调函数推送到任务队列中

- 运行至第二个 `setTimeout()` 函数，同理，将回调函数推送至任务队列

- 第二个 `setTimeout()` 返回时，调用栈清空，此时 Event Loop 会检查任务队列是否为空

- 任务队列不为空，取出并执行第一个任务，打印 `"timer1"`

- `Promise.resolve().then()` 的回调函数会被推送至 Microtask 队列

- `.then()` 函数返回，调用栈再次清空

- Event Loop 在执行下一个任务前，检查 Microtask 队列不为空，则执行 Microtask 队列中的函数，打印 `"promise1"`

- Microtask 队列空，Event Loop 继续执行下一个任务队列中的任务

- 同理，依次打印出 `"timer2"` 和 `"promise2"`

### `setTimeout(fn, 0)` 的问题

其实现在的浏览器在执行 `setTimeout()` 和 `setInterval()` 时，会设定一个最小的时间阀值，一般是 4ms。

浏览器的不活跃标签内的时间阀值，有些浏览器会设置为 1000ms。

可以通过 `window.postMessage()` 来模拟实现真正的 0 秒延迟的 `setTimeout`。实现代码可以参考 https://dbaron.org/log/20100309-faster-timeouts

代码我复制在这：

```js
// Only add setZeroTimeout to the window object, and hide everything
// else in a closure.
(function() {
    var timeouts = [];
    var messageName = "zero-timeout-message";

    // Like setTimeout, but only takes a function argument.  There's
    // no time argument (always zero) and no arguments (you have to
    // use a closure).
    function setZeroTimeout(fn) {
        timeouts.push(fn);
        window.postMessage(messageName, "*");
    }

    function handleMessage(event) {
        if (event.source == window && event.data == messageName) {
            event.stopPropagation();
            if (timeouts.length > 0) {
                var fn = timeouts.shift();
                fn();
            }
        }
    }

    window.addEventListener("message", handleMessage, true);

    // Add the one thing we want added to the window object.
    window.setZeroTimeout = setZeroTimeout;
})();
```

### `queueMicrotask()`

可以通过 `queueMicrotask()` 直接将函数推入 Microtask 队列。注意，因为 Microtask 队列中如果新增了函数，队列会一直执行，直到队列为空，所以，当递归的调用 `queueMicrotask()` 时，需要小心，避免 Microtask 队列永远执行不完。

具体 API 可以参考[文档](https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/queueMicrotask)

### 视图渲染、`requestAnimationFrame`、`requestIdleCallback`

在浏览器中，尽管网络请求可以与 JS 代码并行执行，但是 JS 本身是单线程的。视图的渲染也需要 JS 引擎来完成，因此当视图渲染时，会阻塞 JS 的线程；反之，密集 CPU 操作的 JS 代码也会阻塞视图的渲染过程。

当每次 Event Loop 执行完任务队列和 Microtask 队列中所有函数时，就会检查视图是否需要渲染，如果需要，则会进入视图渲染的过程。

如果浏览器的刷新率是 60 fps（每秒 60 帧），那么理论上每 1/60 秒（约等于 16.67ms）就会进行一次视图渲染（不一定完全是，浏览器会有优化）。在每次渲染之前，浏览器会执行 `requestAnimationFrame()` 的回调，简称 `rAF`。

> 注意，有些浏览器（如 Edge 和 Safari 的某些版本）会在渲染完成之后执行 `requestAnimationFrame()` 回调，不符合标准。

如果在 1/60 秒之内，浏览器完成了视图渲染，那么浏览器就会处于空闲状态，此时就会执行 `requestIdleCallback()` 的回调，简称 `rIC`。值得一提的是，React 的 Fiber 就是利用了该 API，在浏览器的空闲时间进行了 Reconciliation 的操作。

更多细节请参考：

- [MDN `requestAnimationFrame()`](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)

- [MDN `requestIdleCallback()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback)

- [React Fiber Architecture](https://github.com/acdlite/react-fiber-architecture/blob/master/README.md)

- [Lin Clark - A Cartoon Intro to Fiber - React Conf 2017](https://www.youtube.com/watch?v=ZCuYPiUIONs)

## Node.js 中的 Event Loop 概述

### Node.js 的基本架构

在了解 Node.js 的异步机制之前，先了解以下 Node.js 的大致架构。

Node.js 和 Chrome 浏览器一样，使用了 V8 作为 JS 的解释器。但使用了 [libuv](https://libuv.org/) 管理其异步流程。下图大致展示了 Node.js 的基本架构

<img src="/images/node-sections.jpg" style="margin: 15px;">

- [V8](https://v8.dev/) - 用来解释执行 JS 代码

- [libuv](https://libuv.org/) - 主要用 C 语言编写，提供了异步 I/O，Event Loop，异步 DNS 解析，文件系统读写等

- 底层模块 - 主要用 C/C++ 编写，比如 c-ares, http parser, OpenSSL, zlib 等

- JS 模块 - 使用 JS 编写的一些模块或内部模块，Node API 等

- Binding - 用来使用一个语言来调用另一个语言，使得 JS 和 C/C++ 可以互相调用

如果想学习 libuv 的内部更细节的知识，可以参考 [An Introduction to libuv](https://nikhilm.github.io/uvbook/index.html#)

### Node.js 中 Event Loop 流程概述

```
   ┌───────────────────────────┐
┌─>│           timers          │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │     pending callbacks     │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │       idle, prepare       │
│  └─────────────┬─────────────┘      ┌───────────────┐
│  ┌─────────────┴─────────────┐      │   incoming:   │
│  │           poll            │<─────┤  connections, │
│  └─────────────┬─────────────┘      │   data, etc.  │
│  ┌─────────────┴─────────────┐      └───────────────┘
│  │           check           │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
└──┤      close callbacks      │
   └───────────────────────────┘
```
*流程图来自 https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick/*

上图是 Node.js 中 Event Loop 的一个基本流程，使用 libuv 实现。其中每个方框代表一个阶段（phase）：

- Event Loop 首先会进入 *timer* 阶段，在此阶段执行定时器 `setTimeout()` 和 `setInterval()` 的回调。查看设定的时间阀值是否已经超时，如果超时，则会依次执行回调。注意实际运行的时间往往比设定的阀值要大。如果到达时间阀值，其他任务没有完成，那么回调会等待当前任务结束之后才会执行。

- *pending callbacks* 阶段主要执行一些系统触发的时间，例如 TCP 连接异常错误 `ECONNREFUSED` 的通知

- *idle, prepare* 仅仅在 libuv 内部调用

- *poll* 是一个重要的阶段，会处理 I/O 相关的事件回调

- *check* 阶段会执行 `setImmediate()` 的回调

- *close callbacks* 阶段会执行一些关闭的回调，比如 `socket.on('close', ...)`

#### 具体流程

- Node.js 会依次执行各个阶段的回调函数，

- 到达 poll 阶段

  - 首先会判断 poll 队列是否为空，如果不为空，则会依次执行队列中的任务

  - 如果 poll 队列为空，则会判断是否有 `setImmediate()` 的任务，如果有，则进入 check 阶段执行 `setImmediate` 的回调

  - 检查是否有定时器（`setTimeout`, `setInterval`）任务，如果有，则会返回 timer 阶段执行定时器任务

  - 如果又没其他任务，则会等待新的任务被添加至 poll 队列

    下图大致描绘了 poll 阶段的一个过程

    <img src="/images/node-poll-phase.svg" style="margin: 15px;">

- 在每个阶段之间，会首先执行 `process.nextTick()` 的回调，然后执行 Microtask 队列中的回调

  ```
     ┌───────────────────────────┐
  ┌─>│           timers          │
  │  └─────────────┬─────────────┘
  │                | <─────────────── process.nextTick(), MicroTasks
  │  ┌─────────────┴─────────────┐
  │  │     pending callbacks     │
  │  └─────────────┬─────────────┘
  │                | <─────────────── process.nextTick(), MicroTasks
  │  ┌─────────────┴─────────────┐
  │  │       idle, prepare       │
  │  └─────────────┬─────────────┘
  │                | <─────────────── process.nextTick(), MicroTasks
  │  ┌─────────────┴─────────────┐
  │  │           poll            │
  │  └─────────────┬─────────────┘
  │                | <─────────────── process.nextTick(), MicroTasks
  │  ┌─────────────┴─────────────┐
  │  │           check           │
  │  └─────────────┬─────────────┘
  │                | <─────────────── process.nextTick(), MicroTasks
  │  ┌─────────────┴─────────────┐
  └──┤      close callbacks      │
     └───────────────────────────┘
  ```

### 代码分析

回头看文章开头的代码

```js
setTimeout(() => {
  console.log('timer1');
  Promise.resolve().then(() => console.log('promise1'));
}, 0);

setTimeout(() => {
  console.log('timer2');
  Promise.resolve().then(() => console.log('promise2'));
}, 0);
```

Node 10 及以下版本基本是按照上述流程处理代码的，当执行该段代码时，Event Loop 的大致流程如下

- 执行两个 `setTimeout`，依次将回调函数添加至 timer 队列

- Event Loop 运行到 timer 阶段

- 执行第一个 timer 回调，首先打印 `"timer1"`

- 执行到 `Promise.resolve().then()`，将其回调添加至 Microtask 队列

- 执行第二个 timer 回调，打印 `"timer2"`，并将回调添加至 Microtask 队列

- timer 阶段执行完毕，执行 Microtask 队列

- 依次打印 `"promise1"`、 `"promise2"`

可是从 Node 11 开始，为了使 Event Loop 的行为和浏览器一致，timer 和 Event Loop 进行了较大的调整。

### Node.js 11 中 Event Loop 的一些变化

摘自：[[翻译]Node v11.0.0 中 Timers 和 Microtasks 的新变化 -  知乎专栏](https://zhuanlan.zhihu.com/p/88770385)

> 在 Node v11 中，nextTick 和 microtasks 会在每个单独的 setTimeout 之间 或每个 setImmediate 之间执行。尽管此时 timers queue 或 immediates queue 不为空。在 node v11 版本中，setTimeout 和 promise的行为 与浏览器一致，使浏览器 javascript 代码的运行结果跟 Node 一致。然而，这种新的改变可能会打破现有的 Nodejs 应用程序，这些应用程序显然依赖于旧的行为。因此，如果您要升级到节点 v11 或更高版本（最好是 LTS v12），您要认真考虑。

### Node.js 中 `setTimeout()` 阀值

在 Node.js 中，`setTimeout()` 和 `setInterval()` 的设定的时间如果大于 2147483647 或小于 1，则会被强制设定为 1ms。因此，可以理解为，在 Node.js 中，`setTimeout()` 的最小时间阀值是 1 ms。

### `setTimeout(fn, 0)` 和 `setImmediate()` 的回调谁先执行？

看下面的代码

```js
setTimeout(() => console.log('1'), 0);

setImmediate(() => console.log('2'));
```

实际运行会发现，打印的顺序并不是固定的。代码执行的过程可以理解为下列步骤：

- `setTimeout()` 会设定定时器，时间阀值为 1ms

- `setImmediate()` 会把函数放入 immediate 队列

- 当 Event Loop 执行到 timer 阶段时，此时有 2 种情况

  - 1ms 的时间阀值已经过去，将回调放入 timer 队列并执行

  - 1ms 时间尚未达到，进入后面的阶段，直至 check 阶段执行 immediate 回调

因此，不难看出，是否会先执行 `setTimeout()` 完全取决于代码执行的够不够快，换句话说，和机器和系统的性能有关。

可是，如果异步调用这两个函数，会怎样呢？

```js
setTimeout(() => {
  setTimeout(() => console.log('1'), 0);
  setImmediate(() => console.log('2'));
}, 0);
```

执行发现，输出的顺序总是 `2`、`1`。我们来分析一下执行过程：

- 代码运行至外层 `setTimeout()`，将回调函数放入 timer 队列（1ms 后执行）

- 1ms 后（可忽略），Event Loop 进入 timer 阶段，执行回调

- 代码执行到内层的 `setTimeout()`，将其回调放入 timer 队列

- 代码执行到内层 `setImmediate`，将其放入 immediate 队列

- Event Loop 依次到达 poll 阶段和 check 阶段，执行 immediate 队列的任务，打印 `"2"`（对此阶段有疑问，可以回头查看 [Node.js 中 Event Loop 流程概述](#nodejs-中-event-loop-流程概述)）

- Event Loop 回到 timer 阶段，执行队列，打印 `"1"`

### `process.nextTick()` vs `queueMicrotask()`

`queueMicrotask()` 和浏览器的 Web API 类似，可以直接将任务防止 Microtask 队列。在 Event Loop 的每个阶段之间，执行 Microtask 队列中的任务。

注意，Microtask 队列是直接被 V8 管理的，`process.nextTick()` 是被 Node.js 管理的，两者都在每次 Event Loop 阶段开始之前执行。`process.nextTick()` **总是先于** `Microtask` 的任务。


## 参考资料

- [Concurrency model and the event loop - MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop)

- [Using microtasks in JavaScript with queueMicrotask()](https://developer.mozilla.org/en-US/docs/Web/API/HTML_DOM_API/Microtask_guide)

- [In depth: Microtasks and the JavaScript runtime environment - MDN](https://developer.mozilla.org/en-US/docs/Web/API/HTML_DOM_API/Microtask_guide/In_depth)

- https://github.com/nodejs/help/issues/1118

- [Jake Archibald: In The Loop - JSConf.Asia](https://www.youtube.com/watch?v=cCOL7MC4Pl0)

- [The Node.js Event Loop, Timers, and `process.nextTick()`](https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick/)

- https://nodejs.org/api/timers.html

- https://stackoverflow.com/questions/36766696/which-is-correct-node-js-architecture

- [[翻译]Node v11.0.0 中 Timers 和 Microtasks 的新变化 -  知乎专栏](https://zhuanlan.zhihu.com/p/88770385)

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
