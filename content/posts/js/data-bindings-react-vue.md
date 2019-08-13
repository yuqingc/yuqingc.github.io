---
title: "Data Bindings in React and Vue"
lead: "Designing components the graceful way"
date: 2019-08-13T10:50:17+08:00
draft: false
toc: false
categories:
  - "blogs"
tags:
  - "javascript"
  - "react"
  - "vue"
---

Months ago, I started working for an enterprise which uses *Vue.js* for most of its web projects. The other day, I was trapped in a problem when I was trying to implement a *checkbox*-like component with Vue, for which I need to implement a two-way binding pattern(known as *v-model*). Were this component written with React, under the design of *controlled component*, this would definitely not be a problem. I realized there's still a long way to go before I master this framework and that I should ask for help from the Internet. Finally, I figured that out, of course.

This article talks about how to implement a two-way binding Vue component, as part of my study note. Then, I will compare both ways for data bindings in Vue and React as well. I will also mention my points of the correct design standard for React components. Let's get started.

## tl;dr

- The two-way binding in Vue.js is implemented by a similar way to React.js, which combines a single-way data flow and an event-based design
- Your React component *MUST* be able to behave both *controlled* and *uncontrolled*, so as to satisfy the needs of your users

## Writing your customized two-way binding component

The known directive `v-model` is often used when there is a two-way binding scenario. Here's how the parent component looks like

```html
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

In fact, `v-model` is just a syntax sugar for an event-driven data modifying, which is very similar to React's *Controlled Component*, which we'll discuss later. Here's how you bind your parent component's local data without `v-model`:

```html
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
      // Some developers like change `checked` by
      // `this.checked = !this.checked`,
      // which is completely okay in this case.
      // However, reading from callback param meets general scenarios.
      this.checked = checked;
    },
  }
};
</script>
```
