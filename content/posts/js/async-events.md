---
title: "关于 JS 的事件，你可能忽略了这件事"
lead: "当面试官问你：手动触发点击事件和通过 dispatchEvent 触发有何不同？"
date: 2020-10-02T10:50:17+08:00
draft: false
toc: false
categories:
  - "blogs"
tags:
  - "javascript"
---


先看这一段代码

```js
const btn = document.getElementById('btn');
btn.addEventListener('click', () => {
  Promise.resolve().then(() => console.log('1a'));
  console.log('1b');
});
btn.addEventListener('click', () => {
  Promise.resolve().then(() => console.log('2a'));
  console.log('2b');
});
```

思考一下，当鼠标点击 `btn` 元素时，控制台会打印什么？

答案是

```
1b
1a
2b
2a
```

如果我们加上这一行代码，让 JS 模拟点击事件。这时候会打印什么呢？

```js {linenos=table,hl_lines=["10"]}
const btn = document.getElementById('btn');
btn.addEventListener('click', () => {
  Promise.resolve().then(() => console.log('1a'));
  console.log('1b');
});
btn.addEventListener('click', () => {
  Promise.resolve().then(() => console.log('2a'));
  console.log('2b');
});
btn.click();
```

此时浏览器会打印

```
1b
2b
1a
2a
```

这是为什么呢？

<div style="text-align:center; margin: 10px;"><img src="/images/memes/confusing.jpg" width="400px"/></div>

我们先看一下第一种情况——手动触发。当手动触发一个 click 事件时，事件当回调函数会被**异步**执行。此时绑定在这个事件上的所有回调函数会依次被加入任务队列。

首先，执行第一个任务，即下列代码：

```js
Promise.resolve().then(() => console.log('1a'));
console.log('1b');
```

因为 `Promise.prototype.then()` 的回调是通过 Micro Task 执行的，因此会在执行完成 `console.log('1b')` 之后立即执行 `console.log('1a')`。至此，主任务的调用栈上已经是空的了，这时候 Event Loop 就会执行下一个任务。同理，会依次打印 `2b` 和 `2a`。

再来看第二种情况，我们通过 JS 代码 `btn.click()` 手动触发了 click 事件。那么这种场景会有何不同呢？

通过 JS 触发的事件，和 `EventTarget.dispatchEvent()` 一样，是**同步**触发的。我们先看一下[文档](https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent)的描述：

>Unlike "native" events, which are fired by the DOM and invoke event handlers asynchronously via the [event loop](https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop), `dispatchEvent()` invokes event handlers synchronously. All applicable event handlers will execute and return before the code continues on after the call to `dispatchEvent()`.
>
> 不像“原生”事件被 DOM 触发，然后通过事件循环来异步执行处理函数，`dispatchEvent()` 同步地调用事件处理函数。所有的可以执行的回调函数会在调用 `dispatchEvent()` 后执行，然后在代码继续之前返回。

那么回调函数为什么分同步执行和异步执行呢？这两者究竟有什么区别呢？我们来看下面的两段代码：

**代码一：同步执行回调**

```js
function invokeFnSync(fn) {
  fn();
}

console.log('1');
invokeFnSync(() => console.log('2'));
console.log('3');
```

该段代码的回调函数 `() => console.log('2')` 是同步执行的，因此代码执行的顺序会按照 `1, 2, 3` 的打印顺序进行。也就是说，回调函数会阻塞当前的任务的执行，执行完返回之后，才会继续执行下面的代码。

**代码二：异步执行回调**


```js
function invokeFnAsync(fn) {
  setTimeout(fn, 0);
}

console.log('1');
invokeFnAsync(() => console.log('2'));
console.log('3');
```

这段代码中的回调函数 `() => console.log('2')` 会异步执行。也就是说，会被加入任务队列，等当前所有的任务执行完，调用栈清空时，才会调用这个回调函数。因此打印的顺序将是 `1, 3, 2`。

我们再回头看一下 `dispatchEvent()` 函数。该函数执行时，不像手动点击触发事件那样把回调函数一次加入任务队列。该函数会同步执行所有的回调函数，等所有的函数同步地执行完毕之后，`dispatchEvent()` 才会返回。因此调用 `btn.click()` 时，相当于直接执行了以下代码：

```js
Promise.resolve().then(() => console.log('1a'));
console.log('1b');
Promise.resolve().then(() => console.log('2a'));
console.log('2b');
```

因为 `.then()` 后的回调是异步执行的（Micro Task），因此必须要等到 `1b` 和 `2b` 的内容执行完毕之后，才会调用当前的 Micro Task。

---

如果有疑问，欢迎在下方评论区交流讨论。

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
