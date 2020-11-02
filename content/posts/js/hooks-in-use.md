---
title: "Hooks 实战 & 防坑（WIP，持续更新中）"
date: 2020-10-22T13:50:29+08:00
draft: false
---

使用 Hook 需要尝试丢弃 Class 组件开发的思维。

<!--more-->

## *Think in Hook*

### 关键点：

- Class 可以持续的将属性、方法保存在实例中，每次调用 `render()` 并不会影响实例的属性

- 但是，与 Class 组件不同， Function 组件终归是一个函数，每次重新“render”都会重新调用该函数。每次函数的执行，都会创建其独立的上下文。因此，在函数中声明的局部变量的生命周期，也仅仅存在于单次的函数调用中

- 所以我们需要使用适当的 Hook，把这些“局部变量”保存在 React 内部维护的全局变量中，以使数据相对持久化

*如果不理解上述关键点，将会在 Hook 的使用中频繁踩坑。*

本文针对一些实际应用场景做一些分析。

## 1. Hook 与防抖

先看一个[防抖](https://lodash.com/docs/4.17.15#debounce)的例子。我们监听 `value` 的变化，并在其发生改变时延迟执行一些操作，如 `doSomething()`。

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

我们希望在一次性输入一些字符串之后，经过 1s 的延迟，打印出当前的 `value`。为了调试方便，我们可以把 `doSomething()` 替换为 `console.log()` 来看到代码执行的效果。你可能会这样写：

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

然而，上述两个代码段的结果是一样的，都没有达到预期的效果。如果我们依次输入 `abc` 三个字符，我们将会看到在 1s 的延迟后，控制台依次打印出了 `a`, `ab`, `abc` 三个字符串。

这是因为每次输入之后，都会使 `<HookExample>` 组件重新渲染，这样 `HookExample()` 函数就会执行三次。每次执行，在其作用域内，都会创建新的 `deSomethingDebounced` 函数。因此会打印三次。

那么，如果我们使用 `useRef` 来存储这个局部函数，是不是就达到预期了呢？

```js
// 无效 +2
const deSomethingDebounced = useRef(debounce(() => {
  console.log(value);
}, 1000));
useEffect(deSomethingDebounced.current, [value]);
```

然而该代码依然没有达到预期。我们可以看到再依次输入 `abc` 三个字符后的 1s，控制台确实打印了依次，但是却打印了空字符串 `""`。

这是因为，在第一次创建 `deSomethingDebounced` 时，`value` 的值会被计算并存下来了，之后的每次执行，其实取到的还是第一次 `value` 的值，也就是空字符串 `""`。因此我们需要在每次执行的时候，动态获取当前的 state 的值。

```js
// It works
const deSomethingDebounced = useRef(debounce(arg => {
  console.log(arg);
}, 1000));
useEffect(() => deSomethingDebounced.current(value), [value]);
```

这样就符合预期了。

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

## 2. 异步获取状态

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

根据上面防抖的例子，我们可以知道，上述代码打印出来的 `count` 永远是初始值 `0`。如果参照上面的例子，你可能会这样改造代码：

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

事情并没有变得简单，打印出来的依然是空字符串。因为，`useEffect()` 的回调，在初始渲染就执行了，此时就会传入当时的 `value`，即空字符串 `""`。那么不管多少时间之后异步执行，打印出来的永远是空字符串。解决方案如下：

```js {linenos=table,hl_lines=["5"]}
useEffect(() => {
  setTimeout(() => {
    setValue(state => {
      console.log('value', state);
      return state;
    });
  }, 3000);
}, []);
```

注意，需要保持好习惯，如果有 `setTimeout`、`setInterval` 或者添加事件的监听函数，一定要添加清理函数，以免造成内存泄漏：

```js {linenos=table,hl_lines=["9-11"]}
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

我们需要使用在 `setValue` 中传入回调函数，确保获取的值是最新的。注意，我们需要把 `state` 返回出去，以免造成数据被意外的更改。按照同样的思路，我们可以把第一个防抖的例子改造成这样（重要的事情说 n 遍，注意添加清理函数，避免造成内存泄漏）：

```js
const deSomethingDebounced = useRef(debounce(() => {
  setValue(state => {
    console.log('value is', state);
    return state;
  });
}, 1000));

useEffect(() => {
  deSomethingDebounced.current();

  return deSomethingDebounced.current.cancel;
}, [value]);
```

这样使用同样也是 ok 的（但是比较麻烦，不推荐这样使用）。

## 3. 计时器问题

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

如果我们想实现倒计时功能，并且在倒计时结束的时候实现一些附加的功能，比如提示用户时间已到。我们可能会这么实现代码。这个代码实现也是相当直观的：

```jsx
const IntervalExample = () => {
  const [restTime, setRestTime] = useState(3);

  // 初始化一个计时器
  useEffect(() => {
    const id = setInterval(() => {
      setRestTime(state => {
        // 当时间到 0 时停止计时
        if (state <= 1) {
          clearInterval(id);
          console.log('时间到');
        }
        return state - 1;
      });
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

## 4. 使用自定义 Hook 抽离可复用逻辑

>先占个坑，有空继续完善和更新

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
