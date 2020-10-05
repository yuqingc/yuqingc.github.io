---
title: "JS 异步背后的故事 —— Event Loop"
date: 2020-10-05T16:04:16+08:00
draft: true
---

*异步*、*Event Loop*、*Micro Task* 这些词语对于一个 JavaScript 开发者来说并不陌生，今天专门抽出一篇文章来聊一聊这些东西。

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

我们把每次函数的一次执行，直到调用栈被清空的过程称为**任务**。任务可以是一个 JS 程序最开始执行的代码，或者是事件的回调，也可以是定时器（`setTimeout`, `setInterval`）的回调函数。“任务”是相对于 Micro Task 的一个概念，因此任务会被某些文章称为“Macro Task（宏任务）”。所有的任务都被任务队列所调用。下列场景下，任务会被添加至任务队列。

- 新的 JS 程序的执行，如在控制台执行的代码，或者是 `<script>` 标签中的代码

- 事件触发时，回调函数会被加入任务队列

- 当 `setTimeout()` 或 `setInterval()` 到达预定的时间时，其回调函数也会被加入任务队列

任务队列和上文所说的消息队列，在某些角度可以理解为同一个（或相似）概念。

Event Loop 会检查当前的任务队列中是否有任务，如果有会依次执行。在本轮 Event Loop 中，新加入队列的任务不会被执行。这些新加入的任务会在下一轮 Event Loop 被执行。

### Micro Task

Micro Task 又被称为微任务。JS 中的 Promise 和 [Mutation Observer API](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver) 使用了 Micro Task。与任务的区别：

- 每次每个任务结束时，Event Loop 会检查当前的任务是否将会把控制权交给其他 JS 代码，如果没有，则会执行 Micro Task 队列中的所有 Micro Task

- 在执行 Micro Task 队列中的 Micro Task 时，如果有新的 Micro Task 被添加进队列（使用 `queueMicrotask()`），这些 Micro Task 会在本次 Event Loop 全部执行，直到没有新的 Micro Task 被添加到队列为止

### Web API

其实，如 `setTimeout()`, `setInterval()`, `Fetch API`, `XHR` 等 API 都是浏览器提供的 API（并非 v8 自带）。V8 仅仅负责语言的解析和执行，Event Loop 处理异步的行为，其实也是浏览器自己实现的。

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

- 第二个 ``setTimeout()` 返回时，调用栈清空，此时 Event Loop 会检查任务队列是否为空

- 任务队列不为空，取出并执行第一个任务，打印 `"timer1"`

- `Promise.resolve().then()` 的回调函数会被推送至 Micro Task 队列

- `.then()` 函数返回，调用栈再次清空

- Event Loop 在执行下一个任务前，检查 Micro Task 队列不为空，则执行 Micro Task 队列中的函数，打印 `"promise1"`

- Micro Task 队列空，Event Loop 继续执行下一个任务队列中的任务

- 同理，依次打印出 `"timer2"` 和 `promise2`

### `setTimeout(fn, 0)` 的问题

其实现在的浏览器在执行 `setTimeout()` 和 `setInterval` 时，会设定一个最小的时间阀值，一般是 4ms。

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

可以通过 `queueMicrotask()` 直接将函数推入 Micro Task 队列。注意，因为 Micro Task 队列中如果新增了函数，队列会一直执行，直到队列为空，所以，当递归的调用 `queueMicrotask()` 时，需要小心，避免 Micro Task 队列永远执行不完。

具体 API 可以参考[文档](https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/queueMicrotask)

### 视图渲染、`requestAnimationFrame`、`requestIdleCallback`

在浏览器中，尽管网络请求可以与 JS 代码并行执行，但是 JS 本身是单线程的。视图的渲染也需要 JS 引擎来完成，因此当视图渲染时，会阻塞 JS 的线程；反之，密集 CPU 操作的 JS 代码也会阻塞视图的渲染过程。

当每次 Event Loop 执行完任务队列和 Micro Task 队列中所有函数时，就会检查视图是否需要渲染，如果需要，则会进入视图渲染的过程。

如果浏览器的刷新率是 60 fps（每秒 60 帧），那么理论上每 1/60 秒（约等于 16.67ms）就会进行一次视图渲染（不一定完全是，浏览器会有优化）。在每次渲染之前，浏览器会执行 `requestAnimationFrame()` 的回调，简称 `rAF`。

> 注意，有些浏览器（如 Edge 和 Safari 的某些版本）会在渲染完成之后执行 `requestAnimationFrame()` 回调，不符合标准。

如果在 1/60 秒之内，浏览器完成了视图渲染，那么浏览器就会处于空闲状态，此时就会执行 `requestIdleCallback()` 的回调，简称 `rIC`。值得一提的是，React 的 Fiber 就是利用了该 API，在浏览器的空闲时间进行了 Reconciliation 的操作。

更多细节请参考：

- [MDN `requestAnimationFrame()`](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)

- [MDN `requestIdleCallback()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback)

- [React Fiber Architecture](https://github.com/acdlite/react-fiber-architecture/blob/master/README.md)

- [Lin Clark - A Cartoon Intro to Fiber - React Conf 2017](https://www.youtube.com/watch?v=ZCuYPiUIONs)

## Node.js 中的 Event Loop 概述

### Node.js 中 `setTimeout()` 阀值

### `process.nextTick()`, `setImmediate()`, `queueMicrotask()`

## Node.js 11 中 Event Loop 的一些变化

## 参考

- [Jake Archibald: In The Loop - JSConf.Asia](https://www.youtube.com/watch?v=cCOL7MC4Pl0)

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
