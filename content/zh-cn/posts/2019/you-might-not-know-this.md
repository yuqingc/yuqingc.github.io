---
title: "【待迁移】React 和 this"
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

## Motivation

If you are familiar with [React.js](https://reactjs.org), you should know that if you add an event listener to an element like the following, you get a syntax error when you try triggering the `click` event.

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

The browser is expected to warn you: `Uncaught TypeError: Cannot read property 'setState' of undefined` on clicking the `button`.

We know that you can avoid this issue by explicitly binding `this` of the `handleClick` function (or method) to the `Test` class in two ways, either by using an `arrow function` (`() => {}`) or by using JavaScript's `Function.prototype.bind()` built-in method. I'll explain that in later sections.

```jsx
<button onClick={handleClick.bind(this)}></button>
```

or

```javascript
handleClick = () => {
    this.setState({});
}
```

You know that if `this` is not bound to the current object, an error raises. Plus, you know you can solve this issue. However, have you ever considered the following questions:

- What object does `this` refer to in this case? `undefined` or a global object such as `window`? (Apparently `undefined` according to the above *error*)

- Why does the component instance lose the `this` reference to itself?

- Is this a "JavaScript" behavior or a "React" behavior?

## Self exploration

Before our exploration, let's see how React.js [official document](https://reactjs.org/docs/handling-events.html) says:

> This is not React-specific behavior; it is a part of [how functions work in JavaScript](https://www.smashingmagazine.com/2014/01/understanding-javascript-function-prototype-bind/). Generally, if you refer to a method without `()` after it, such as `onClick={this.handleClick}`, you should bind that method.

Thus, the last question in the previous section is solved. *This* is not about React; it's about JavaScript.

Now, take a look at the two snippets of codes below, and consider what the outputs are. If you are not sure what the result is, you might as well test it with [Node.js](https://nodejs.org/en/) or Chrome Browser.

Code snippet One:

```javascript
// javascript with ES6 class syntax
class Cat {
  sayThis () {
    console.log(this); // what is this `this` refer to?
  }

  exec (cb) {
    cb();
  }

  render () {
    this.exec(this.sayThis);
  }
}

const tom = new Cat();
tom.render(); // what is the output?
```

Code snippet Two:

```javascript
const jerry = {
  sayThis: function () {
    console.log(this); // what is this `this` refer to?
  },

  exec: function (cb) {
    cb();
  },

  render: function () {
    this.exec(this.sayThis);
  },
}

jerry.render(); // what is the output?
```

The output of Code snippet One is `undefined`, which is exactly the same as the example in the first section. This indicates that the undefined `this` reference is resulted from JavaScript instead of React.

The output of Code snippet Two is the global object of the runtime environment in which you run your code, which is the `window` object of the browser and the `global` object of Node.js.

You might get confused the first time you saw the output result. What the hell did `this` do?

## `this` in JavaScript

### Simple scenarios where `this` dose not refer to the object in which the  method is defined

Take a look at the following case

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

When `greet` is called with the dot (`.`) operator -- `fish.greet()`, `this` refers to `fish`, which is exactly where the `greet` method is defined. `fish` is called *caller* in this scenario.

In fact, `fish.greet` is just a normal function in the memory. No matter where it is defined, it can be re-assigned to another variable such as `greetCopy` in the above example. If you print `fish.greet` and `greetCopy` with `console.log`, you will get the same thing in the console.

If you call a function without an explicit caller, like `greetCopy`, JavaScript interpreter treats the global object as caller. In this way, `greetCopy()` works exactly the same as `greetCopy.call(window)` in Chrome and `greetCopy.call(global)` in Node.js.

There is an exception. `this` in function calls without a caller are never assigned to the global object in *strict mode*. In *strict mode*, an **Error** raises if you try calling `greetCopy()` because `this` refers to nothing -- `undefined`.

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

Note that in the above case, `greetCopy()` behaves in different ways in Chrome and in Node.js. `this.name` is `undefined` in Node.js as you saw. Variables are automatically assigned to an attribute of the global object if you define them in the most top scope of your code in a browser environment. On the contrary, Node.js does not assign the global variable as an attribute of the global object unless you do it explicitly with the statement `global.name = 'Global'`.

What if you want to call `fish.greet` with another *caller* other than `fish`? `Function.prototype.call` is needed.

```javascript
// In the context of previous code snippet

const pig = {
  name: "Pig"
};

fish.greet.call(pig); // Hello, I am  Pig
```
The `call` method forces to bind `this` inside its `caller`(`fish.greet`) to the `pig` object, which is `call`'s argument.


```javascript
console.log(fish.greet); // function () { … }
console.log(greetCopy); // function () { … }
```

### `this` in callback function

*callback* function is a function as the argument of another function. See the example below.

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

exec(matt.sayName); // `Global` in browser and `undefined` in Node.js
```

If you read the previous section, the output result is easy for you to understand. Let's take a look what happens when the interpreter invokes the `exec()` function.

When the process steps into the `exec` function, the actual argument `matt.sayName` is assigned to the formal argument `cb`. This is just like the assignment statement in the previous section: `const greetCopy = fish.greet;`. There is no explicit caller when `cb` in called, so `this` refers to the global object in *non-strict mode* or `undefined` in *strict mode*.

Let's take a look at another similar example. Consider what the result is.

```javascript
const jerry = {
  sayThis: function () {
    console.log(this); // what is this `this` refer to?
  },

  exec: function (cb) {
    cb();
  },

  render: function () {
    this.exec(this.sayThis);
  },
}

jerry.render(); // what is the output?
```

Yes. You saw this in the last chapter! I think you might know why the output is the global object.

Even if we call `exec` with the dot (`.`) operator explicitly, the `cb` function still does not have a explicit caller. Thus, you will get `this` referring to the global object.

In addition, when you use an ES6 class syntax, all code inside of class declarations runs in strict mode automatically. 

When you bind an event listener with `onClick={this.handleClick}`, the `handleClick` function is actually passed to the `addEventListener()` method as a callback argument. This is why you get `undefined` other than `window` or the Component's instance in the event handler callback functions of a React Component.

### Arrow functions

Arrow functions make `this` more simple and straightforward.

Remembering one rule is enough. You should understand it after you read all above.

> *'this' is always bound to the scope where the function that includes 'this' is defined.*

For more information about `this` in arrow functions, refer to [You Don't Know JS: ES6 & Beyond](https://github.com/getify/You-Dont-Know-JS/blob/master/es6%20%26%20beyond/ch2.md#arrow-functions)

Therefore, we solve the issue at the very beginning with an arrow function.

##  References

- [Chapter: this & Object Prototypes in *You Don't Know JS*, by Kyle Simpson](https://github.com/getify/You-Dont-Know-JS/blob/master/this%20%26%20object%20prototypes/ch2.md)

- [Understanding JavaScript Bind ()](https://www.smashingmagazine.com/2014/01/understanding-javascript-function-prototype-bind/)

- [09-Classes in *Understanding ECMAScript 6*, by Nicholas C. Zakas](https://github.com/nzakas/understandinges6/blob/master/manuscript/09-Classes.md#why-to-use-the-class-syntax)

- [Documentation of *React.js*](https://reactjs.org/docs/handling-events.html)