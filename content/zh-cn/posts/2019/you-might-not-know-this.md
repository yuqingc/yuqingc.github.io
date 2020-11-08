---
title: "React 和 this"
date: 2019-06-21T12:13:37+08:00
draft: false
# description: "Example article description"
# thumbnail: "img/placeholder.jpg" # Optional, thumbnail
lead: "令人头疼的 this"
comments: false # Enable/disable Disqus comments. Default value: true
authorbox: true # Enable authorbox for specific post
toc: true # Optional, enable Table of Contents for specific post
# mathjax: true # Optional, enable MathJax for specific post
categories:
  - "posts"
tags:
  - "javascript"
  - "react"
# menu: main # Optional, add page to a menu. Options: main, side, footer
---

<a target="_blank" href="https://zhuanlan.zhihu.com/p/37911534"><h3>中文版请戳我</h3></a>

## 动机

如果你熟悉 [React.js](https://reactjs.org)，你一定知道知道，如果你像下面这样写事件监听函数，浏览器一定会给你报语法错误

```jsx
// JSX
class Test extends React.Component {

  handleClick () {
    this.setState({});
  }

  render () {
    return <button onClick={handleClick}></button>
  }

}
```

此时如果你点击 `<button>` 按钮，浏览器就会告诉你 `Cannot read property 'setState' of undefined`。

我们知道你可以通过 `bind` 方法或者箭头函数来强制绑定 `this` 来避免这个问题。我们在下面的章节中会提到箭头函数。

```jsx
<button onClick={handleClick.bind(this)}></button>
```

或者

```javascript
handleClick = () => {
    this.setState({});
}
```

如果 `this` 没有绑定到当前对象，那么浏览器就会报错。而且你也知道如何来绑定 `this`。但是你考虑过下面几个问题吗？

- 此时 `this` 到底指向了谁？是 `undefined` 还是全局对象，比如 `window`？（根据前面提到的浏览器报错信息，答案显然是 `undefined`）

- 为什么 React 组件的实例会失去指向它本身的 `this` 指向？

- 这是 JavaScript 语言本身导致的还是 React 的内部某些原因导致的呢？

## 自我探索

在进行自我探索之前，让我们看一下[官方文档](https://zh-hans.reactjs.org/docs/handling-events.html)是怎么说的：


> 这并不是 React 特有的行为；这其实与 [JavaScript 函数工作原理](https://www.smashingmagazine.com/2014/01/understanding-javascript-function-prototype-bind/)有关。通常情况下，如果你没有在方法后面添加 `()`，例如 `onClick={this.handleClick}`，你应该为这个方法绑定 `this`。

因此，上一节的最后一个问题解决了。`this` 的行为和 React 无关，这是一个 JS 语言本身的特性。

现在，我们来看一下下面两段代码，然后思考一下输出结果是什么。如果你不确定输出结果是什么，你可以在 Node.js 或者 Chrome 浏览器中跑一下试一试。

代码一：

```javascript
// 使用 ES6 的 class 语法
class Cat {
  sayThis () {
    console.log(this); // 这里的 `this` 指向谁？
  }

  exec (cb) {
    cb();
  }

  render () {
    this.exec(this.sayThis);
  }
}

const tom = new Cat();
tom.render(); // 输出结果是什么？
```

代码一：

```javascript
const jerry = {
  sayThis: function () {
    console.log(this); // 这里的 `this` 指向谁？
  },

  exec: function (cb) {
    cb();
  },

  render: function () {
    this.exec(this.sayThis);
  },
}

jerry.render(); // 输出结果是什么？
```

代第一段代码的结果是 `undefined`，这和第一节中 React 出现的结果完全一致。这代表 `this` 指向了 `undefined`。其实是 JS 的行为而并非 React。

第二段代码的结果是，你所使用的环境里面的全局对象——在浏览器中就是 `window` 对象，在 Node.js 中就是 `global` 对象。

你看到输出结果的时候，一定感到很困惑吧？到底 `this` 干了什么？？

## JS 中的 `this`

### `this` 不指向定义它的函数的那个对象的情形

看下面的例子

```javascript
var name = 'Global'
const fish = {
  name: 'Fish',
  greet: function() {
    console.log('Hello, I am ', this.name);
  }
};

fish.greet(); // Hello, I am  Global

const greetCopy = fish.greet;

greetCopy(); // Chrome: Hello, I am  Fish
// Node.js: Hello, I am undefined
```

当你使用“点”操作符 `.` 来调用 `greet` 函数的时候，`fish.greet()`，`this` 指向了 `fish`，`fish` 正是定义了 `greet` 方法的那个对象。在这种情况下，我们称 `fish` 是这个函数的调用者。

事实上，`fish.greet` 在内存中只是一个普通的函数。不管它是在什么对象中定义的，它都可以和普通的函数一样，赋值给另一个变量，比如前面的 `greetCopy`。如果你用 `console.log` 打印 `console.log(fish.greet)` 或者 `console.log(greetCopy)`，控制台输出的结果都是一样的。

如果你不用调用者显式地调用一个函数，JS 的解释器就会把全局对象当作调用者。所以 `greetCopy()` 这个语句在 Chrome 中的行为就和 `greetCopy.call(window)` 是一样的，在 Node.js 中就和 `greetCopy.call(global)` 是一样的。

但是有一种例外，如果你使用了严格模式，那么没有显式的使用调用者 的情况下，`this` 永远不会自动绑定到全局对象上。如果此时你调用 `greetCopy`，你就会得到报错，因为这时候 `this` 不指向任何对象，`this` 这时候就是 `undefined`。

```javascript
'use strict';

var name = 'Global'
const fish = {
  name: 'Fish',
  greet: function() {
    console.log('Hello, I am ', this.name);
  }
};

fish.greet(); // Hello, I am  Global

const greetCopy = fish.greet;

greetCopy(); // Uncaught TypeError: Cannot read property 'name' of undefined
```

注意，在上面这种情况下，`greetCopy` 在 Chrome 中和在 Node.js 中行为不太一样。正如你看到的那样，在 Node.js 中，`this.name` 的值是 `undefined`。在浏览器中，如果你在最外层作用于定义了一个变量，它就会自动变成全局对象的一个属性。相反，在 Node.js 中，最外层对象不会自动被赋给全局对象，除非你显式地使用 `global.name = 'Global'`。

如果我想使用另一个对象作为调用者来调用 `fish.greet`，我该怎么做？这时候就要用到 `Function.prototype.call`。

```javascript
// 前面代码一的上下文

const pig = {
  name: "Pig"
};

fish.greet.call(pig); // Hello, I am  Pig
```

`call` 方法强制性地把 `fish.greet` 的调用者绑定到了 `pig` 对象上，`pig` 这时候用作 `this` 方法的参数。


```javascript
console.log(fish.greet); // function () { … }
console.log(greetCopy); // function () { … }
```

### 回调函数中的 `this`

*回调函数*简单的来说，就是把一个函数作为另一函数的参数，并且在另一个函数执行的时候调用这个函数。看一下下面的例子：

```javascript
var name = 'Global';

const matt = {
    name: "Matt",
    sayName: function () {
        console.log(this.name);
    }
}

function exec(cb) {
    cb();
}

exec(matt.sayName); // // `Global` (浏览器), `undefined` (Node.js)
```

如果你阅读了上面的章节，这个输出结果对你来说就很好理解了。我们来看一下在解释器调用 `exec()` 函数的时候都做了什么。

当这个程序运行到 exec 函数的时候，实参 `matt.sayName` 被传递给了形参 `cb`。这就和前面的章节中说的赋值语句的情况类似：`const greetCopy = fish.greet;`。这里 `cb` 在调用的时候并没有显式的调用者，所以此时，`this` 在非严格模式下就会指向全局对象，在严格模式下就会指向 `undefined`。

我们来看一下另一个很相似的情形。思考一下结果是什么？

```javascript
const jerry = {
  sayThis: function () {
    console.log(this); // `this` 指向什么？
  },

  exec: function (cb) {
    cb();
  },

  render: function () {
    this.exec(this.sayThis);
  },
}

jerry.render(); // 输出结果是什么？
```

是的！你在上一章中看到了这个例子了。你现在一定知道了为什么输出结果是全局对象了吧！

即使我们使用点操作符. 来显式地调用 exec 方法，然而 cb 函数仍然没有一个显式的调用者。因此，你就会看到 this 指向了全局对象。

> 注意：
>
>如果你使用了 ES6 的 class 语法，所有在 class 中声明的方法都会自动地使用严格模式

当你使用 `onClick={this.handleClick}` 来绑定事件监听函数的时候，`handleClick` 函数实际上会作为回调函数，传入 `addEventListener()`。这就是为什么你在 React 的组件中添加事件处理函数为什么会得到 `undefined` 而不是全局对象或者别的什么东西。

### 箭头函数

箭头函数使得 `this` 更简单和直接。

关于箭头函数的资料其实很多，在这里我就不多说了。你只要记住一个规则就足够了，如果你仔细阅读了上文，你应该能理解这个规则

> `this` 永远绑定了定义箭头函数所在的那个对象

关于箭头函数中 this 的更详细的解说，你可以参考[你不知道的JavaScript 之 ES6 箭头函数](https://github.com/getify/You-Dont-Know-JS/blob/1ed-zh-CN/es6%20&%20beyond/ch2.md#%E7%AE%AD%E5%A4%B4%E5%87%BD%E6%95%B0)

这样我们就可以使用箭头函数来解决文章开头的问题了。

##  参考资料

- [Chapter: this & Object Prototypes in *You Don't Know JS*, by Kyle Simpson](https://github.com/getify/You-Dont-Know-JS/blob/master/this%20%26%20object%20prototypes/ch2.md)

- [Understanding JavaScript Bind ()](https://www.smashingmagazine.com/2014/01/understanding-javascript-function-prototype-bind/)

- [09-Classes in *Understanding ECMAScript 6*, by Nicholas C. Zakas](https://github.com/nzakas/understandinges6/blob/master/manuscript/09-Classes.md#why-to-use-the-class-syntax)

- [Documentation of *React.js*](https://reactjs.org/docs/handling-events.html)