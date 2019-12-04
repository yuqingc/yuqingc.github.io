---
title: "What's New in ECMAScript 2020 (ES11)"
date: 2019-12-03T19:59:01+08:00
draft: false
categories:
  - "notes"
tags:
  - "javascript"
---

The latest draft of [ECMAScript 2020](https://tc39.es/ecma262/) was release on November 27 2019. All proposals in Stage 4 are included in this version of the language.
<!--more-->

Let's take a brief look at what new features are brought into ES11.

- `String.prototype.matchAll`
- Dynamic `import()`
- `BigInt`
- `Promise.allSettled`
- `globalThis`

## `String.prototype.matchAll`

The `matchAll()` method returns an iterator of all results matching a string against a regular expression, including capturing groups.

```js
let regexp = /t(e)(st(\d?))/g;
let str = 'test1test2';

let array = [...str.matchAll(regexp)];

console.log(array[0]);
// expected output: Array ["test1", "e", "st1", "1"]

console.log(array[1]);
// expected output: Array ["test2", "e", "st2", "2"]
```

## Dynamic `import()`

`import()` accepts an arbitrary string (not just string literals), and returns a Promise.

```js
let moduleName = getModuleName()
import(`./section-modules/${moduleName}.js`)
  .then(module => {
    module.loadPageInto(main);
  })
  .catch(err => {
    main.textContent = err.message;
  });
```
Read [Specification](https://github.com/tc39/proposal-dynamic-import)

## `BigInt`

`BigInt` is a new primitive that provides a way to represent whole numbers larger than 253, which is the largest number Javascript can reliably represent with the Number primitive. A BigInt is created by appending n to the end of the integer or by calling the constructor.

```js
const x = Number.MAX_SAFE_INTEGER;
// ↪ 9007199254740991, this is 1 less than 2^53

const y = x + 1;
// ↪ 9007199254740992, ok, checks out

const z = x + 2
// ↪ 9007199254740992, wait, that’s the same as above!


// BigInt
const theBiggestInt = 9007199254740991n;

const alsoHuge = BigInt(9007199254740991);
// ↪ 9007199254740991n

const hugeButString = BigInt('9007199254740991');
// ↪ 9007199254740991n
```

## `Promise.allSettled`

The `Promise.allSettled()` method returns a promise that resolves after all of the given promises have either resolved or rejected, with an array of objects that each describes the outcome of each promise.

```js
const promise1 = Promise.resolve(3);
const promise2 = new Promise((resolve, reject) => setTimeout(reject, 100, 'foo'));
const promises = [promise1, promise2];

Promise.allSettled(promises).
  then((results) => results.forEach((result) => console.log(result.status)));

// expected output:
// "fulfilled"
// "rejected"
```

There is another proposal [`Promise.any`](https://github.com/tc39/proposal-promise-any) which has been in Stage 3.

> See also [`Promise.all`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) and [`Promise.race`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race)


## `globalThis`

Prior to `globalThis`, the only reliable cross-platform way to get the global object for an environment was `Function('return this')()`. However, this causes CSP violations in some settings.

Read [`globalThis` Specification](https://github.com/tc39/proposal-global)
