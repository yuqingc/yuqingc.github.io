---
title: "An Implementation for Limited-concurrency Promise Runner"
date: 2019-06-23T12:22:37+08:00
draft: false
categories:
  - "blogs"
tags:
  - "javascript"
---

## Introduction

When you call `Promise.prototype.all()`, there is no approach to controlling the number of concurrent promise tasks. This can cause a large usage of OS resources if the number of the tasks array is really large.

There are some excellent packages aiming to solve this problem. For example, [p-limit](https://www.npmjs.com/package/p-limit). *p-limit* uses an `activeCount` variable to control the current running tasks.
The implementation I am introducing for solving this issue is a little bit different.

## An infinite loop watching the size of the running queue

### Design Philosophy
- Once the size of the running queue is less than the configured limitation, we move the next task from the waiting queue to the running queue
- Once any one of the running tasks fulfills, it is removed from the running queue, causing the length of the running queue to reducing by `1`
- The reduction of the running tasks is watching by the infinite loop mentioned above, hence a new task is pushed to the running queue

### "Talk is cheap. Show me the code"

```js
function sleep(n) {
  return new Promise(res => setTimeout(res, n))
}

class LimitPromise {
  constructor(limit) {
    this.limit = limit;
  }
  async run(tasks) {
    console.time('run');
    if (!Array.isArray(tasks)) {
      throw new Error('Task to run must be an array');
    }
    const runningQueue= new Set();
    while(!(tasks.length === 0 && runningQueue.size === 0)) {
      if (runningQueue.size < this.limit && tasks.length > 0) {
        const nextTask = tasks.shift();
        runningQueue.add(nextTask);
        nextTask().then(() => runningQueue.delete(nextTask), () => runningQueue.delete(nextTask));
      }
      // JS is single threaded. Here, `sleep(0) yields the current thread to other tasks.`
      await sleep(0);
    }
    // All tasks fulfill here
    console.timeEnd('run');
  }
}
```

Note that we use `runningQueue` to store current running tasks. Using a `activeCount` for the number of running tasks is sufficient (this is what *p-limit* does) unless you want to export the running tasks to users.

### Usage

```js
const my_runner = new LimitPromise(3);
my_runner.run([
  () => fetchSomething(),
  () => fetchSomething(),
  () => fetchSomething(),
  () => fetchSomething(),
  () => fetchSomething(),
]);
```

### Pros & Cons

- Thumbs up 👍
    - Few code
    - Easy to understand
    - Stable

- Thumbs down 👎
    - Infinite loop is not a decent way to watch data's change, which uses a lot of CPU resource

## Informing data changing actively

Sometimes we don't want to use the infinite loop. In the following implementation, We inform our program that our running queue has changed. This is just like what `p-limit` does. Here is a snippet of demo code for this implementation.

```js
anotherRun(tasks) {
    return new Promise(res => {
      const _this = this;
      console.time('anotherrun');
      if (!Array.isArray(tasks)) {
        throw new Error('Task to run must be an array');
      }
      const runningQueue= new Set();
      function onRunningQueueChange() {
        if (tasks.length === 0 && runningQueue.size === 0) {
          // All tasks fulfill here
          console.timeEnd('anotherrun');
          return res();
        }
        if (tasks.length === 0) {
          return;
        };
        if (runningQueue.size < _this.limit) {
          const task = tasks.shift();
          runningQueue.add(task);
          task().then(() => {
            runningQueue.delete(task);
            onRunningQueueChange();
          });
        }
      }
      for (const i in new Array(this.limit).fill(0)) {
        if (tasks.length > 0) {
          const task = tasks.shift();
          runningQueue.add(task);
          task().then(() => {
            runningQueue.delete(task);
            onRunningQueueChange();
          });
        }
      }
    });
  }
```

### Why I don't like this 😒

Publishing the change of running queue actively saves more CPU resources than the infinite loop watching. However there are potential risks that some task is not able to inform the outside world the change of running queue, or that a new task cannot be pushed to the running queue in time due to some system error. An infinite loop keeps track of the change of all data structures in the program. (The code above is a demo which indicates how the program works. We still need to work on boundaries conditions where errors might occur)


---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
