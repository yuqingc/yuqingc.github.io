---
title: "Hooks 实战 & 防坑 & 优化"
date: 2020-10-22T13:50:29+08:00
draft: false
categories:
  - "posts"
tags:
  - "react"
  - "javascript"
---

使用 Hook 需要尝试丢弃 Class 组件开发的思维。本文假设你了解 Hook 的基本用法和 API。如果对 Hook 还不太熟悉，可以先看一下[官网教程](https://zh-hans.reactjs.org/docs/hooks-intro.html)。

<!--more-->

## Think in Hook —— 使用 Hook 的思维

- Class 可以持续的将属性、方法保存在实例中，每次调用 `render()` 并不会影响实例的属性

- 但是，与 Class 组件不同， Function 组件终归是一个函数。每次重新“render”都会重新调用该函数。每次函数的执行，都会创建其独立的上下文。因此，在函数中声明的局部变量的生命周期，也仅仅存在于单次的函数调用中

- 我们需要使用适当的 Hook，把这些“局部变量”保存在 React 内部维护的“全局变量”中，以使数据相对持久化

*如果不理解上述关键点，将会在 Hook 的使用中频繁踩坑。*

本文针对一些实际应用场景做一些分析。

## Hook 与防抖

先看一个[防抖](https://lodash.com/docs/4.17.15#debounce)的例子。防抖操作在实际应用中比较常见，比如用户输入文字时，实时根据用户的输入请求搜索接口。我们监听 `value` 的变化，并在其发生改变时延迟执行一些操作，如 `doSomething()`。

```jsx
const HookExample = () => {
  const [value, setValue] = useState('');

/**
 * 需要在这里插入代码段，监听 `value` 的变化
 */
  useEffect(debounce(() => {
    doSomething(value);
  }, 1000), [value]);

  return (
    <div>
      <p>{value}</p>
      <input onChange={event => setValue(event.target.value)} />
    </div>
  );
};
```

我们希望在一次性输入一些字符串之后，经过 1s 的延迟，读取当前的 `value` 进行一些操作，比如作为接口的参数。为了调试方便，我们可以把 `doSomething()` 替换为 `console.log()` 来看到代码执行的效果。你可能会这样写：

```js
// 无效
useEffect(debounce(() => {
  console.log(value);
}, 1000), [value]);
```

```js
// 无效 +1
const deSomethingDebounced = debounce(() => {
  console.log(value);
}, 1000);

useEffect(deSomethingDebounced, [value]);
```

然而，上述两个代码段的结果是一样的，都没有达到预期的效果。如果我们依次输入 `a`、`b`、`c` 三个字符，我们期望在 1s 的延迟后，控制台打印出 `abc`。然而，在 1s 的延迟后，控制台依次打印出了 `a`, `ab`, `abc` 三个字符串。

这是因为每次输入之后，都会使 `<HookExample>` 组件重新渲染，这样 `HookExample()` 函数就会执行三次。每次执行，在其作用域内，都会创建新的 `deSomethingDebounced` 函数。因此会打印三次。

那么，如果我们使用 `useRef` 来存储这个局部函数，是不是就达到预期了呢？

```js
// 无效 +2
const deSomethingDebounced = useRef(debounce(() => {
  console.log(value);
}, 1000));

useEffect(deSomethingDebounced.current, [value]);
```

然而该代码依然没有达到预期。我们可以看到再依次输入 `abc` 三个字符后的 1s，控制台确实打印了一次，但是却打印了空字符串 `""`。

这是因为，在第一次创建 `deSomethingDebounced` 时，`value` 的值会被计算并保存下来。之后的每次执行，实际上取到的还是 `value` 的初始值，也就是空字符串 `""`。因此我们需要在每次执行的时候，动态获取当前的 state 的值。

```js
// It works
const deSomethingDebounced = useRef(debounce(arg => {
  console.log(arg);
}, 1000));

useEffect(() => deSomethingDebounced.current(value), [value]);
```

这样就符合预期了。

> 其实，上述代码还有优化空间，请参考下文[`useRef` 的初始值](#useref-的初始值)

**注意添加清理函数，避免造成内存泄漏**

```js {linenos=table,hl_lines=["8"]}
const deSomethingDebounced = useRef(debounce(arg => {
  console.log(arg);
}, 1000));

useEffect(() => {
  deSomethingDebounced.current(value);

  return deSomethingDebounced.current.cancel;
}, [value]);
```

除此之外，React 为我们提供了一个专门用来缓存函数的 Hook，使用 `useCallback()` 会更加简单。推荐使用。

```js
const deSomethingDebounced = useCallback(debounce(arg => {
  console.log(arg);
}, 1000), []);

useEffect(() => {
  deSomethingDebounced(value);

  return deSomethingDebounced.cancel;
}, [value]);
```

## 异步获取状态

如果我们需要在异步（比如在一定时间之后）获取当前 state 的值

```js
const [value, setValue] = useState(0);

useEffect(() => {
  setTimeout(() => {
    console.log(value);
  }, 3000);
}, []);
}
```

学习了上面防抖的例子之后，我们可以知道，上述代码打印出来的 `count` 永远是初始值 `0`。如果参照上面的例子，你可能会这样改造代码：

```js
const timeoutFnRef = useRef(arg => {
  setTimeout(() => {
    console.log(arg);
  }, 2000);
});

useEffect(() => {
  timeoutFnRef.current(value);
}, []);
```

事情并没有变得简单，打印出来的依然是空字符串。因为，`useEffect()` 的回调，在初始渲染就执行了，此时就会传入当时的 `value`，即空字符串 `""`。那么不管多少时间之后异步执行，打印出来的永远是空字符串。解决方案如下。

我们使用 `useRef` 来实时保存当前的值。

> 注意，需要保持好习惯，如果有 `setTimeout`、`setInterval` 或者添加事件的监听函数，一定要添加清理函数，以免造成内存泄漏。

```js {linenos=table,hl_lines=["13"]}
const prefValueRef = useRef();

// 实时保存 value 的值
useEffect(() => {
  prevValueRef.current = value;
}, [value]);

useEffect(() => {
  const id = setTimeout(() => {
    console.log(prevValueRef.current);
  }, 3000);

  return () => clearTimeout(id);
}, []);
```

> **注意：**
>
> 这里保存值的变量名为 `prevValueRef` 其实是有用意的。虽然保存的是当前的值，但是如果在返回的 element 中展示这个值，会呈现上次渲染的值。可以用[这种方法](https://reactjs.org/docs/hooks-faq.html#how-to-get-the-previous-props-or-state)来获取*上一次* state 的值。

除此之外，还有另一种思虑可以解决。可以了解一下（并不推荐使用，后面会说具体原因）

```js {linenos=table,hl_lines=["5"]}
useEffect(() => {
  const timeoutId = setTimeout(() => {
    setValue(state => {
      console.log('value', state);
      return state;
    });
  }, 3000);

  return () => {
    clearTimeout(timeoutId);
  };
}, []);
```

我们需要使用在 `setValue` 中传入回调函数，确保获取的值是最新的。注意，我们需要把 `state` 返回出去，以免造成数据被意外的更改。

但是，非常**不推荐**使用这种方法！因为虽然这样能解决问题，但是比较 Hack。`useState` 的回调尽量使用**纯函数**，即不要带有其他的副作用操作，这样不符合 React 设计的思想。

## 计时器问题

实现一个可以自增的定时器并不难：

### 简单版

```jsx
const IntervalExample = () => {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let id = setInterval(() => {
      setCount(count => count + 1);
    }, 1000);

    return () => {
      clearInterval(id);
    };
  }, []);

  return (
    <div>
      <div>{count}</div>
    </div>
  );
};
```

### 进阶：倒计时

如果我们想实现倒计时功能，并且在倒计时结束的时候实现一些附加的功能，比如提示用户时间已到。我们可能会这么实现代码。这个代码实现比较直观：

```jsx
const IntervalExample = () => {
  const [restTime, setRestTime] = useState(3);
  const lastRestTimeRef = useRef(3);

  // 实时保存 restTime，以方便读取
  useEffect(() => {
    lastRestTimeRef.current = restTime;
  }, [restTime]);

  // 初始化一个计时器
  useEffect(() => {
    const id = setInterval(() => {
      if (lastRestTimeRef.current <= 1) {
        clearInterval(id);
        console.log('时间到');
      }
      setRestTime(state => state - 1);
    }, 1000);
    return () => {
      console.log('定时器终止');
      clearInterval(id);
    };
  }, []);

  return (
    <div>
      <p>{restTime}</p>
    </div>
  );
};
```

上述代码确实可以实现一个倒计时的定时器，但是，有太多的重复代码，比如两次出现了 `clearInterval`。如果需要添加额外功能，比如支持暂停，这样的思路就会使得代码变得更加复杂。我们能否利用 `useEffect` 的特性来优化我们的代码呢？

看一下优化后的代码：

```jsx
const IntervalExample = () => {
  const [restTime, setRestTime] = useState(3);

  const isRunning = restTime >= 1;

  useEffect(() => {
    if (isRunning) {
      const id = setInterval(() => {
        setRestTime(state => state - 1);
      }, 1000);
      return () => {
        console.log('时间到', id);
        clearInterval(id);
      };
    }
  }, [isRunning]);

  return (
    <div>
      <p>{restTime}</p>
    </div>
  );
};
```

我们引入了一个额外的变量 `isRunning` 来控制是否继续执行定时器。每次 `isRunning` 的值改变时，就会触发 `useEffect()` 的回调，同时也会清理之前的定时器。按照同样的思虑，我们可以支持手动暂停和恢复计时器。

### 进阶：支持暂停/恢复

按照上面的思路，支持暂停和恢复功能就简单了。我们只需要手动设置 `isRunning` 即可。

```jsx
const IntervalExample = () => {
  const [restTime, setRestTime] = useState(0);
  const [isRunning, setIsRunning] = useState(true);

  useEffect(() => {
    if (isRunning) {
      const id = setInterval(() => {
        setRestTime(state => state + 1);
      }, 1000);
      return () => {
        console.log('暂停', id);
        clearInterval(id);
      };
    }
  }, [isRunning]);

  return (
    <div>
      <p>{restTime}</p>
      <button onClick={() => setIsRunning(isRunning => !isRunning)}>
        {
          isRunning ? '暂停' : '恢复'
        }
      </button>
    </div>
  );
};
```

## 使用 `useCallback` 和 `ref` 来获取 DOM 元素

一般情况下，使用 `React.createRef()` 或者 `React.useRef()` 没有问题。我们在 `componentDidMount()` 或 `useEffect()`（把依赖设为 `[]`）中就可以获取 DOM 元素。但是，如果需要获取 DOM 元素的组件不是刚开始就 render 出来的，比如手动触发显示，那么处理起来就比较棘手。我们可以使用 `useCallback` 和 `ref` 来获取 DOM 元素。举例：

```jsx
function Example () {
  const [height, setHeight] = useState(0);
  const [show, setShow] = useState(false);

  const measuredRef = useCallback(node => {
    if (node !== null) {
      setHeight(node.getBoundingClientRect().height);
    }
  }, []);

  return (
    <>
      {show && <h1 ref={measuredRef}>Hello, world</h1>}
      <h2>The above header is {Math.round(height)}px tall</h2>
      <button onClick={() => setShow(true)}>Show</button>
    </>
  );
}
```

使用 `useCallback` 并设置依赖为 `[]` 可以保证回调函数只执行一次。参考 https://reactjs.org/docs/hooks-faq.html#how-can-i-measure-a-dom-node

## Function 组件不能使用 Ref？

一般来说，无法给 Function 组件设置 Ref。但是我们结合使用下列 API 来达到和 Class 组件类似的效果

- [`React.forwardRef`](https://reactjs.org/docs/react-api.html#reactforwardref) 用来暴露 Function 组件内部的 Ref 给父组件

- [`useImperativeHandle`](https://reactjs.org/docs/hooks-reference.html#useimperativehandle) 用来实现“classInstance.method()” 调用 Class 组件实例方法类似的效果

详情点击上面的链接查看文档 👆

## 懒加载 `useState` 和 `useRef` 的初始值

### 懒加载 `useState`

- 当 state 的初始值需要通过复杂计算得出，或者数据结构比较复杂，可以使用返回初始值的函数，作为其参数。详情参考 `useState` 的 API。

```js
function Table(props) {
  // createRows() 只会执行一次
  const [rows, setRows] = useState(() => createRows(props.count));
  // ...
}
```

上述代码中的 `createRows()` 只会执行并计算一次。

### `useRef` 的初始值

`useRef` 不用于 `useState`，不能传入一个回调函数来懒加载初始值。如果传入一个函数的调用，那么每次 render 都会调用。我们来验证一下：

```js
let v = 0;

function foo() {
  v = v + 1;
  console.log('执行 foo', v);
  return v;
}

const Example = () => {
  const someRef = useRef(foo());
  console.log('当前值', someRef.current);

  // 剩下的代码省略
}
```

我们可以看到，每次 render 时，`foo` 函数都会执行，但是 `someRef.current` 的值永远是第一次计算获取的值，即 `1`。

来看一下前面提到过防抖例子的代码：

```js {linenos=table,hl_lines=["1-3"]}
const deSomethingDebounced = useRef(debounce(arg => {
  console.log(arg);
}, 1000));

useEffect(() => deSomethingDebounced.current(value), [value]);
```

其实，在每次 render 时，伴随着组件函数的执行，`debounce` 函数都会执行，只是后面执行的返回结果会被丢弃。`useRef` 仅仅保留第一次执行的结果。其实，这样会造成无用的函数调用，影响性能。我们可以手动初始化 `deSomethingDebounced` 的值，来对代码进行优化。

```js
const deSomethingDebounced: any = useRef();

// 手动初始化，避免重复计算
useEffect(() => {
  deSomethingDebounced.current = debounce(arg => {
    console.log(arg);
  }, 1000);
}, []);

useEffect(() => deSomethingDebounced.current(value), [value]);
```

## n. 使用自定义 Hook 抽离可复用逻辑

> 待更新

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
