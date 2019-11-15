---
title: "Data Bindings in React and Vue"
lead: "Designing components the graceful way"
date: 2019-08-13T10:50:17+08:00
draft: false
toc: true
categories:
  - "blogs"
tags:
  - "javascript"
  - "react"
  - "vue"
---

Months ago, I started working for an enterprise which uses *Vue.js* for most of its web projects. The other day, I was trapped in a problem when I was trying to implement a *checkbox*-like component with Vue, for which I need to implement a two-way binding pattern(known as *v-model*). Were this component written with React, under the design of *controlled component*, this would definitely not be a problem to me. I realized there's still a long way to go before I master this framework and that I should ask for help from the Internet. Finally, I figured that out, of course.

This article describes how to implement a two-way binding Vue component, as is part of my study note. Then, I will compare both ways for data bindings in Vue and React as well. I will also mention my points of the decent design standard for React components. Let's get started.

## tl;dr

- The two-way binding in Vue.js is implemented by a similar way to React.js, which combines a single-way and an event-based data flow to pass data from bottom to up (from child to parent)
- Your React component *MUST* be able to behave both *controlled* and *uncontrolled*, so as to satisfy the needs of your users

## Writing your customized two-way binding component

### Interface

The known directive `v-model` is often used when there is a two-way binding scenario. Here's how the parent component looks like

```html
<!-- parent.vue -->

<template>
  <my-checkbox v-model="checked">
</template>
<script>
export default {
  data () {
    return {
      checked: true,
    };
  }
};
</script>
```

In fact, `v-model` is just a syntax sugar for an event-driven data flow where data goes from child up to its parent component, very similar to React's *Controlled Component*, which we'll discuss later. Here's how you bind your parent component's local data without `v-model`:

```html
<!-- parent.vue -->

<template>
  <my-checkbox :checked="checked" @change="handleChange">
</template>
<script>
export default {
  data () {
    return {
      checked: true,
    };
  },
  methods: {
    // We listen to the `change` event of `my-checkbox` component
    // and change the local data `checked` read from the argument
    // of the event listener/handler
    handleChange (checked) {
      // Some developers prefer changing `checked` by
      // `this.checked = !this.checked`,
      // which is completely okay in this case.
      // However, reading from callback param meets general scenarios.
      this.checked = checked;
    },
  },
};
</script>
```

### Implementation

Here's the implementation of the preceding `my-checkbox` component.

```html
<!-- my-checkbox.vue -->

<template>
  <div
    :class="{'checked-class': checked, 'unchecked-class': !checked}"
    @click="handleClick"></div>
</template>
<script>
  export default {
    data () {
      return {
        localChecked: this.checked,
      }
    },
    props: {
      checked: Boolean,
    },
    model: {
      prop: 'checked',
      event: 'change',
    },
    methods: {
      handleClick () {
        this.localChecked = !this.localChecked;
        this.$emit('change', this.localChecked);
      }
    },
  }
</script>
```

As we saw in the above code snippet, a `model` property is defined for binding a event with the bound prop `checked`. Note that we initialize a local state named `localChecked` because we should not modify a prop of a component directly, otherwise Vue raises a warning in the console. The `model` property offers a bridge joining the local `localChecked` with the prop passed from outside world.

This could be confusing since we did nothing except for the `model` property in the default exported module. Neither did we listen to the `change` event nor assign another value to the `checked` prop in the parent component. How does the prop of `checked` change with the local `localChecked`?? However, with no doubt, we *did* listen and we *did* re-assign the prop, with the help of `v-model` and `model` field of the child component. It could be verbose but more clear that we write the second snippet in the preceding section, which is exactly the core idea of React's data flow management.

## What can be called a *good* component?

### Is this a *good* component?

Let's take a normal React component for an example. Most people would write a component like this:

```jsx
// MyCheckbox.jsx

export class MyCheckbox extends React.Component {
  handleClick = () => {
    const { onChange } = this.props;
    onChange();
  }
  render () {
    const { checked } = this.props;
    return (
      <div
        className={checked ? 'checked-class' : 'unchecked-class'}
        onClick={this.handleClick}
      ></div>
    )
  }
}
```

Or like this:

```jsx
// MyCheckbox.jsx

export class MyCheckbox extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      checked: false,
    }
  }
  handleClick = () => {
    const { onChange } = this.props;
    onChange(this.state.checked);
  }
  render () {
    const { checked } = this.state;
    return (
      <div
        className={checked ? 'checked-class' : 'unchecked-class'}
        onClick={this.handleClick}
      ></div>
    )
  }
}
```

*NEITHER* component is a decent React component because their data model is not perfect. The first code snippet makes `MyCheckbox` a completely *controlled component*. Users have to write their own logic to control the `checked` prop with a listener function on the `change` event in which `checked` is modified. Even though a *controlled component* model is a pretty good practice and it is even strongly recommended by the React team, sometimes we don't really want to write so many codes if the only line in the listener function is assigning the `checked` variable, and the we just need to fetch the changing data to do something else. The second snippet is apparently an *uncontrolled component*. There is no way to controlled the local state of the component. You should not write such code when your component is for other people to use, especially when *data* really matters.

### Idea for a well-designed component with decent data management

I will name such components as *form components* in the rest content because such components whose data flow plays an important role are widely used in form elements.

The core idea for a form component is that

> A form component should be used as either *controlled* or "uncontrolled" component.

When we do not pass the value props, the component should manage its own state and expose it to its parent component via a event listener. In this case, the component is *uncontrolled*.

When we do pass the value props, the component should take the prop as its driving data and ignore its local state, where this component is *controlled*.

How do we implement a such component?

### Implementation

#### Traditional Class Component

★☆☆ Level I

```jsx
class Checkbox extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      checked: false,
    }
  }
  handleClick = () => {
    const { onChange } = this.props;
    this.setState(state => ({checked: !state.checked}), () => {
      if (typeof onChange === 'function') {
        onChange(this.state.checked);
      }
    })
  }
  render () {
    const { checked: checkedState } = this.state;
    const { checked: checkedProp } = this.props;
    const checkedProp === undefined ? checkedState : checkedProp;
    return <div onClick={this.handleClick}>{checked ? 'checked' : 'unchecked'}</div>
  }
}

```

This actually works but this kind of code is strongly unrecommended. The logic for discarding `checkedState` when `checkedProp` is passed could be confusing in more complicated cases.

★★☆ Level II

React provides us with some lifecycle hook function to handle with props with state. Let's make some improvements and optimization.

```jsx
class Checkbox extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      checked: false,
    }
  }
  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.props.checked !== nextProps.checked) {
      this.setState({checked: nextProps.checked})
    }
  }
  handleClick = () => {
    const { onChange } = this.props;
    this.setState(state => ({checked: !state.checked}), () => {
      if (typeof onChange === 'function') {
        onChange(this.state.checked);
      }
    })
  }
  render () {
    const { checked } = this.state;
    return <div onClick={this.handleClick}>{checked ? 'checked' : 'unchecked'}</div>
  }
}

```

It's notable that there is an `UNSAFE` prefix in the name of the function `UNSAFE_componentWillReceiveProps()`. As the name tells us, this lifecyle function is *not* safe, and we should avoid using this function. React team is deprecating this lifecycle in future versions of React.

Since React 16.3.0, new lifecycles are introduced. We should use those rather than the ones with `UNSAFE` prefix, which will be deleted in the future.

★★★ Level III

The only thing we need to do is to replace the `UNSAFE_componentWillReceiveProps()` method with the following code:

```js
class Checkbox extends React.Component {
  // ...
  static getDerivedStateFromProps(props, state) {
    if (props.checked !== undefined
      && props.checked !== state.checked) {
      return {
        checked: props.checked,
      };
    }
    return null;
  }
  // ...
}

```

#### Function Component with Hooks

```jsx
// CheckboxHook.jsx

import React, { useState, useEffect, useRef } from 'react';

export function CheckboxHook (props) {
  const [checked, setChecked] = useState(false);
  const { onChange, checked: checkedProp } = props;
  const computedChecked = checkedProp !== undefined ? checkedProp : checked;

  // Skip first run of `useEffect`
  const isFirstRun = useRef(true);

  useEffect(() => {
    if (isFirstRun.current) {
      isFirstRun.current = false;
      return;
    }
    if (typeof onChange === 'function') {
      onChange(computedChecked);
    }
  }, [checked])

  function handleClick () {
    setChecked(!checked);
  }

  return <div onClick={handleClick}>{computedChecked ? 'checked' : 'unchecked'}</div>;
}
```

I can't say function Component with Hook is better than Class Component, but it works anyway.

By the way, we use `useRef` to skip the first run of the `useEffect` callback function. (See [the Stackoverflow discussion](https://stackoverflow.com/questions/53351517/react-hooks-skip-first-run-in-useeffect))


---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
