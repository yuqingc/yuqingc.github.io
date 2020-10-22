---
title: "WIP: Hooks 实战 & 防坑（持续更新中）"
date: 2020-10-22T13:50:29+08:00
draft: false
---

使用 Hook 需要切换 Class 组件开发的思维。

<!--more-->

## 使用 Hook 思考问题

### 关键点：

- 与 Class 组件不同，Class 可以持续的将属性、方法保存在实例中，每次调用 `render()` 并不会影响实例的属性

- 但是 Function 组件终归是一个函数，每次重新“render”都相当于重新调用该函数，每次函数的执行，都会创建其独立的上下文，因此，在函数中生命的局部变量的生命周期，也仅仅存在于单次的函数调用

- 所以我们需要使用适当的 Hook，把这些“局部变量”保存在 React 内部维护的全局变量中，以使数据相对持久化

*如果不理解上述关键点，将会在 Hook 的使用中频繁踩坑。从最简单的一个例子入手：*

## Hook 与防抖

```js
// 无效
useEffect(debounce(() => {
  doSomething(data);
}), [data]);
```

```js
// 无效 +1
const deSomethingDebounced = debounce(() => {
  doSomething(data);
};
useEffect(deSomethingDebounced, [data]);
```

```js
// 无效 +2
const deSomethingDebounced = useRef(debounce(() => {
  doSomething(data);
});
useEffect(deSomethingDebounced.current, [data]);
```

```js
// It works
const deSomethingDebounced = useRef(debounce(arg => {
  doSomething(arg);
});
useEffect(() => deSomethingDebounced.current(data), [data]);
```

>先占个坑，有空继续完善和更新

---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
