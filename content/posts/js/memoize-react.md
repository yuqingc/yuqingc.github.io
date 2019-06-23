---
title: "记忆化技术介绍"
lead: "使用闭包提升你的 React 性能"
date: 2019-03-18T12:22:37+08:00
thumbnail: "images/react-logo.jpg"
draft: false
categories:
  - "blogs"
tags:
  - "javascript"
  - "react"
---

## 动机

在开发 React 项目中，有一种场景很常见：从服务器中请求了一个数据结构，这个结构非常复杂，甚至还有一些垃圾字段。这个数据结构一般通过 React 组件的 props 传入组件。而我们在 render 的时候需要对这个很复杂的数据结构要做处理，比如过滤一些无用的信息，或者重新组合这个数据结构以便更方便的 render。

来看一下这个例子：

```jsx
class Example extends PureComponent {
  // 当前的过滤文本:
  state = {
    filterText: ""
  };

  handleChange = event => {
    this.setState({ filterText: event.target.value });
  };

  render() {
    // 在 PureComponent 中，render 方发只有在 state.filterText 和 props.list
    // 变化的时候才会重新调用
    const filteredList = this.props.list.filter(
      item => item.text.includes(this.state.filterText)
    )

    return (
      <Fragment>
        <input onChange={this.handleChange} value={this.state.filterText} />
        <ul>{filteredList.map(item => <li key={item.id}>{item.text}</li>)}</ul>
      </Fragment>
    );
  }
}
```

在上面这个例子中，`filter` 这一段代码的逻辑其实就是我们所说的，对 从服务器拿来的数据结构 进行处理的过程。每一次调用 `render` 方法都会调用 `filter` 这段逻辑。我们在一个组件中更新其实是比较频繁的，而 `filter` 的逻辑其实也相当占用CPU资源以及时间。如果每次更新调用 `render` 方法都要走一次这一段 `filter` 的逻辑，其实是非常消耗时间的。这对 App 的性能也会造成影响。

而在实际的开发中，数据结构往往更加复杂，有时候甚至会有多次的循环。有时候组件的更新并不是因为从服务器拿来的这一段数据结构发生变化造成的（组件中的其他部分更新造成的），但是这一段很重的逻辑因为是写在 `render` 中的，所以不可避免的在每次 `render` 会调用一次。如果这段逻辑在两次调用的时候，输入参数是一样的，那么输出结果必然一样，所以再次计算是一种十分浪费资源的行为。

那么有没有一种方法可以避免这种行为呢？确实是有的，下面我们介绍一种名为 *memoization* 的技术，中文翻译叫 “记忆化技术”

## 记忆化技术

记忆化，顾名思义，就是把函数的调用结果记下来，或者缓存下来。如果下次调用这个函数的时候，输入的参数和上一次的完全一致，那么我们就不需要再次进行计算，而是把上一此的结果直接返回。

看一下维基百科对记忆化的定义：

> 在计算机科学中，记忆化（英語：memoization 而非 memorization）是一种提高程序运行速度的优化技术。通过储存大计算量函数的返回值，当这个结果再次被需要时将其从缓存提取，而不用再次计算来节省计算时间。记忆化是一种典型的时间存储平衡方案。

## React 中使用 memoize-one

根据 "memoize-one" 的名字可以知道，这个库缓存了一个结果 *ONE* ， 而不是 *TWO* 或者其他数字。缓存一次而不是多次，可以节约内存。虽然只有一次，但不失为一个很好的折中方案。

在上一节的 React 的场景中，如果把之前计算的结果缓存起来，这样每次 `render` 的时候，如果从服务器拿到的数据结构和上一次 `render` 的时候一样，就可以非常快的把结果渲染出来。这样本来需要 O(n) ，O(n2) 甚至更高复杂度的算法，我们瞬间可以以 O(1) 的效率把结果直接从缓存中读取出来。

说了这么多，我们来看一下这个 *memoize-one* 到底是怎么用的呢？

### 1. 安装

```
$ npm install memoize-one
```

### 2. API 简介以及用例

```js
import memoizeOne from 'memoize-one';
 
const add = (a, b) => a + b;
const memoizedAdd = memoizeOne(add);
 
memoizedAdd(1, 2); // 3
 
memoizedAdd(1, 2); // 3
// Add 函数并没有执行: 前一次执行的结果被返回
 
memoizedAdd(2, 3); // 5
// Add 函数再次被调用以获得新的结果
 
memoizedAdd(2, 3); // 5
// Add 函数并没有执行: 前一次执行的结果被返回
 
memoizedAdd(1, 2); // 3
// Add 函数再次被调用以获得新的结果
// 虽然之前调用过
// 但是不是上一次调用的，所以结果丢失了
```

### 3. 在 React 中使用 memoize-one

```jsx
import memoize from "memoize-one";

class Example extends Component {
  // 当前的过滤文本:
  state = { filterText: "" };

  // 只有在 list 和 filterText 改变的时候才会重新执行 filter 函数
  filter = memoize(
    (list, filterText) => list.filter(item => item.text.includes(filterText))
  );

  handleChange = event => {
    this.setState({ filterText: event.target.value });
  };

  render() {
    // 计算最新的过滤值. 如果参数没有发生改变
    // 之前的一次 render 之后, `memoize-one` 会再次利用上一次的返回结果.
    const filteredList = this.filter(this.props.list, this.state.filterText);

    return (
      <Fragment>
        <input onChange={this.handleChange} value={this.state.filterText} />
        <ul>{filteredList.map(item => <li key={item.id}>{item.text}</li>)}</ul>
      </Fragment>
    );
  }
}
```

这样，我们就在 React 中实现了记忆化，性能也会得到提升。因为这样可以避免 render 的时候，浪费性地调用复杂的数据处理函数。

那么在 JavaScript 中，记忆化函数 *memoize-one* 是如何实现的呢？

## 使用闭包来实现记忆化技术

在前面的代码中，我们并没有看到上一次返回的结果被显式的存在一个缓存变量中。那么究竟是如何实现缓存的呢？其实很简单，缓存技术使用了 JavaScript 中的 *闭包* 。

本文假定你熟悉 JavaScript 中闭包的概念，如果你不熟悉闭包，可以参考[你不知道的JavaScript——作用域与闭包](https://github.com/getify/You-Dont-Know-JS/blob/1ed-zh-CN/scope%20&%20closures/README.md#you-dont-know-js-scope--closures)

momoize-one 的源码可以在 [GitHub](https://github.com/alexreardon/memoize-one/blob/master/src/index.js) 中查看，源码只有三十几行，非常简单，也很好理解。下面我把源码更简化一下，来介绍这个库实现的原理。

```js
export function memoize (resultFn) {
  let lastArgs = []; // 用来存放上一次调用的参数
  let lastResult; // 用来缓存上一次的结果
  let calledOnce: boolean = false; // 是否调用过，刚开始的时候是false

  // 判断两次调用的时候的参数是否相等
  // 这里的 `isEqual` 是一个抽象函数，用来判断两个值是否相等
  const isNewArgEqualToLast = (newArg, index) => isEqual(newArg, lastArgs[index]);

  // 如果上一次的参数和这一次一样，直接返回上一次的结果
  const result = function (...newArgs) {
    if (
      calledOnce &&
      newArgs.length === lastArgs.length &&
      newArgs.every(isNewArgEqualToLast)
    ) {
      // 如果和上次的参数一致， 直接返回缓存的值
      return lastResult;
    }

    // 如果和上一次的参数不一致，我们需要再次调用原来的函数
    calledOnce = true; // 标记为调用过
    lastArgs = newArgs; // 重新缓存参数
    lastResult = resultFn.apply(this, newArgs); //重新缓存返回值

    return lastResult;
  }

  // 返回闭包函数
  return result;
}
```

原理非常简单，可以通过我的注释来理解。

注意，我的代码中有一个 `isEqual` 的抽象函数，用来判断两次的参数是否一致。因为对相等的理解，不同场景不一样，而且参数有时候是复杂的对象，所以我们不能仅仅通过比较操作符 `==` 或者 `===` 来判断。*memoize-one* 允许用户自定义传入判断是否相等的函数，比如我们可以使用 *lodash* 的 `isEqual` 来判断两次参数是否相等。

```js
import memoizeOne from 'memoize-one';
import deepEqual from 'lodash.isEqual';
 
const identity = x => x;
 
const defaultMemoization = memoizeOne(identity);
const customMemoization = memoizeOne(identity, deepEqual);
 
const result1 = defaultMemoization({foo: 'bar'});
const result2 = defaultMemoization({foo: 'bar'});
 
result1 === result2 // false - 索引不同
 
const result3 = customMemoization({foo: 'bar'});
const result4 = customMemoization({foo: 'bar'});
 
result3 === result4 // true - 参数通过 lodash 的 isEqual 判断是相等的
```

## 补充：React Hook 中的记忆化技术提高你的组件性能 (2019 年 3 月 更新)

React 16.8 带来了全新的 Hook。Hook 为我们提供了原生的记忆化 API，我们可以使用 [useMemo](https://reactjs.org/docs/hooks-reference.html#usememo) 来实现上文所说的记忆化技术。具体用法请直接参考 API 文档。也可以阅读 Dan 的这篇文章：[Writing Resilient Components](https://overreacted.io/writing-resilient-components/)

## 参考资料

- [You Probably Don't Need Derived State](https://reactjs.org/blog/2018/06/07/you-probably-dont-need-derived-state.html#what-about-memoization)

- [memoize-one](https://www.npmjs.com/package/memoize-one)