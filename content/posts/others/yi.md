---
title: "周易筮算 ☯️"
leading: "本页算法模拟“大衍筮法”的流程得到卦象，在客户端直接进行计算。用你自己设备的 CPU 和内存代替筮草，算上一挂吧！"
date: 2020-05-20T20:08:20+08:00
draft: false
toc: false
---

本页算法模拟“大衍筮法”得到卦象，在客户端直接进行计算。用你自己设备的 CPU 和内存代替筮草，算上一挂吧！

> 大衍之数五十，其用四十有九。分而为二以象两，挂一以象三，揲之以四以象四时，归奇于扐以象闰，五岁再闰，故再扐而后挂。

<button id="TkYZTfu6n2ZEzWTE" style="height: 50px; width: 100%; outline: none; border-radius: 50px; border: none; color: #fff; background-color: #2a2a2a; font-weight: bold;" >开始占筮</button>

### ☯️ 卦象

<div id="TkYZTfu6n2ZEzWTE-result" style="width: 100%; height: 300px; background: #eee; padding: 10px; margin: 10px 0; border-radius: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center;"></div>

_断挂功能建设中，敬请期待_

### ☯️ 附：大衍筮法 模拟算法

```js
// get random integer between min and max, including both
const getRandomIntBetween = (min, max) => {
  if (!(min < max)) {
    throw new Error('min must be smaller than max');
  }
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

// 大衍筮法 算出单个爻 算法
const getYao = () => {
  let leftPoints = 0;
  let rightPoints = 0;
  //大衍之数五十，其用四十有九
  let remainedPoints = 50 -1;
  for (let i = 0; i < 3; i++) {
    // 分而为二以象两
    leftPoints = getRandomIntBetween(1, remainedPoints - 1);
    rightPoints = remainedPoints - leftPoints;
    // 挂一以象三
    rightPoints -= 1;
    // 揲之以四以象四时，归奇于扐以象闰
    const leftRemainder = (leftPoints % 4) || 4;
    const rightRemainder = (rightPoints % 4) || 4;
    // 五岁再闰，故再扐而后挂
    remainedPoints = remainedPoints - leftRemainder - rightRemainder - 1;
  }
  return (remainedPoints) / 4;
};
```

<script type="text/javascript">
/****** Utils ******/

const RED_COLOR = '#e22d30';
const DARK_COLOR = '#2a2a2a';

// get random integer between min and max, including both
const getRandomIntBetween = (min, max) => {
  if (!(min < max)) {
    throw new Error('min must be smaller than max');
  }
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Get number from 6, 7, 8, 9
// 大衍筮法算法
const getYao = () => {
  let leftPoints = 0;
  let rightPoints = 0;
  //大衍之数五十，其用四十有九
  let remainedPoints = 50 -1;
  for (let i = 0; i < 3; i++) {
    // 分而为二以象两
    leftPoints = getRandomIntBetween(1, remainedPoints - 1);
    rightPoints = remainedPoints - leftPoints;
    // 挂一以象三
    rightPoints -= 1;
    // 揲之以四以象四时，归奇于扐以象闰
    const leftRemainder = (leftPoints % 4) || 4;
    const rightRemainder = (rightPoints % 4) || 4;
    // 五岁再闰，故再扐而后挂
    remainedPoints = remainedPoints - leftRemainder - rightRemainder - 1;
  }
  return (remainedPoints) / 4;
};

// createTextNodeWithColor
const createTextNodeWithColor = (text, color) => {
  const ele = document.createElement('h3');
  const content = document.createTextNode(text);
  ele.appendChild(content);
  ele.style.color = color;
  return ele
}

// isBig 代表老阳或者老阴
const createYao = (isYang, isBig, description) => {
  const ele = document.createElement('div');
  ele.style.cssText = "display: flex;"; 
  const yaoPatterns = [];
  if (isYang) {
    const yangPattern = document.createElement('div');
    yangPattern.style.height = '10px'
    yangPattern.style.width = '100px';
    yangPattern.style.margin = '6px';
    yangPattern.style.backgroundColor = isBig ? RED_COLOR : DARK_COLOR;
    yaoPatterns.push(yangPattern);
  } else {
    for (let i = 0; i < 2; i++) {
      const yinPattern = document.createElement('div');
      yinPattern.style.height = '10px'
      yinPattern.style.width = '44px';
      yinPattern.style.margin = '6px';
      yinPattern.style.backgroundColor = isBig ? RED_COLOR : DARK_COLOR;
      yaoPatterns.push(yinPattern);
    }
  }
  if (description) {
    const content = document.createTextNode(description);
    yaoPatterns.push(content);
    ele.style.color = isBig ? RED_COLOR : DARK_COLOR;
  }

  yaoPatterns.forEach(el => {
    ele.appendChild(el)
  })
  
  return ele
}

const getYaoPattern = (yaoNumber) => {
  const yaoPatterns = {
    6: () => createYao(false, true, '六'),
    7: () => createYao(true, false, '七'),
    8: () => createYao(false, false, '八'),
    9: () => createYao(true, true, '九'),
  };
  return yaoPatterns[yaoNumber]();
}

const sleep = m => new Promise(res => setTimeout(res, m));

const main = () => {
  const btn = document.querySelector("#TkYZTfu6n2ZEzWTE");
  const onClickFn = async () => {
    const resultBox = document.querySelector("#TkYZTfu6n2ZEzWTE-result");
    // Remove all child nodes
    while (resultBox.firstChild) {
      resultBox.removeChild(resultBox.firstChild);
    }
    resultBox.append(createTextNodeWithColor('占筮中 请稍候...', '#000'));
    await sleep(1000);
    resultBox.removeChild(resultBox.firstChild);
    const yaoPatterns = {
      6: () => createYao(false, true, '六'),
      7: () => createYao(true, false, '七'),
      8: () => createYao(false, false, '八'),
      9: () => createYao(true, true, '九'),
    };

    const results = [];
    for (let i = 0; i < 6; i ++) {
      const yao = getYao()
      results.push(yao);
      resultBox.prepend(getYaoPattern(yao));
      await sleep(500);
    }
    console.log(results);
  };
  btn.addEventListener('click', onClickFn);
}

main();

</script>
