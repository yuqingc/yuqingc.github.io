---
title: "StackOverflow 精选 - SSR vs Code Splitting"
date: 2019-07-12T15:08:20+08:00
draft: false
toc: false
lead: "为什么有 WebPack 的 CodeSplitting 还需要 SSR？"
categories:
  - "stackoverflow"
tags:
  - "javascript"
  - "react"
  - "ssr"
---

[*原文地址*](https://stackoverflow.com/questions/53071053/the-pros-and-const-of-react-ssr-with-code-splitting-and-now-react-lazy)

## The pros and cons of react ssr with code splitting and now React.Lazy

I am slightly confused about the merits of ssr and code splitting and and code splitting done solely on the client.

My thoughts are that server rendering the page first will lead to a better experience without all the javascript having to be parsed and then server rendered.

I am confused how code splitting fits into the ssr model, is it that ssr renders the first hit and then code splitting is done thereafter on the client?

React.Lazy makes a point of saying react.client is all done on the client. How would it differ from code splitting on the server. Is that if you go to a specific route then you retrieve that chunk for the first render?

I understand React.Lazy is all done on the clientside and they have made a real point of saying that. How would it differ if it was done on the server.

Is there any real benefit to ssr with code splitting. Does it not just add complexity?

---

## tl;dr

Depending on your usecase you may use only SSR, only code-splitting or combine both as needed.

## Merits of SSR

1. **Better SEO** since search bots have markup to work with (and not necessarily dependent on executing javascript) for indexing.

2. **Faster initial render** since markup is sent from the server, the browser doesn't has to wait on executing the javascript to render it. (Although the markup will still lack interactivity till react is hydrated client side).

3. **Deliver critical CSS first.** The critical CSS for the initial page render can be in-lined, better UX since the loaded markup will already have styles ready.

4. **Simpler route splitting.** SSR imo makes it simpler to reason about route splitting your application. For example, you may have different pages for `/about` and `/home` which you can route split to reduce bundle size (and preload other routes on client side if needed).

## Combining code splitting your components and SSR

It might not be necessary to server render your entire page. For example, consider your homepage (which you wish to server render) includes a `Chat` component so users can directly ask you questions.

If this component is big you may decide to not server render it so the user can get the most important bits of the page first. This would reduce your initial page load by code splitting this component in your homepage component.

When the browser has parsed the markup it would load your Chat component after the main bundle. This way you could identify and keep your bundle sizes in check.

## Only using code splitting

This is a perfectly fine way to build your application imo if you are not interested in the benefits of SSR.

For example, if your application is a user dashboard for authenticated users, it might be better to not worry about SSR at all and just code split your application. Also note that server rendering your application will take more time to send response on server (instead of plain REST APIs) since the markup has to be generated.

Coming to your questions:

> I am confused how code splitting fits into the ssr model, is it that ssr renders the first hit and then code splitting is done thereafter on the client?

Yes, kinda. The browser receives the initial load from server, after that client takes care of loading the necessary bits. Now, you may decide to preload your components server side and send everything as well (please check `react-loadable` which I mention at the end of this answer).

> How would it differ from code splitting on the server. Is that if you go to a specific route then you retrieve that chunk for the first render?

`lazy` is just a cleaner API with support for Suspense for code-splitting. Ideally, when loading a route for the first time you would server render the initial markup and then let the client take care of loading next bits and routing. Imo [Next.js](https://nextjs.org/) does this really well.

> How would it differ if it was done on the server.

You may preload all your components or only the necessary bits. Please check the **Combining code splitting your components and SSR** section.

> Is there any real benefit to ssr with code splitting. Does it not just add complexity?

Everything has its own trade-off here imo. As I mention in the **Only using code splitting** section, its perfectly fine to just use code-splitting if your use case doesn't require the merits of SSR.

> **Note**
> Currently `lazy` (in React v16.6.1) doesn't support SSR completely. You might want to check out [`react-loadable`](https://github.com/jamiebuilds/react-loadable#------------server-side-rendering) to handle the cases where you wish to preload components server side.


