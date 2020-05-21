---
title: "周易占筮"
date: 2020-5-20T20:08:20+08:00
draft: false
toc: false
categories:
  - "quotes"
---

> 断挂功能建设中敬请期待

<button id="TkYZTfu6n2ZEzWTE" style="height: 50px; width: 100%; outline: none; border-radius: 50px; border: none; color: #fff; background-color: #2a2a2a; font-weight: bold;" >开始占筮</button>

### 卦象

<div id="TkYZTfu6n2ZEzWTE-result" style="width: 100%; height: 300px; background: #eee; padding: 10px; border-radius: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center;"></div>

<script type="text/javascript">
/****** Utils ******/

// get random integer between min and max, including both
const getRandomIntBetween = (min, max) => {
  if (!(min < max)) {
    throw new Error('min must be smaller than max');
  }
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Get number from 6, 7, 8, 9 based on weights
const getYao = (weights) => {
  const weightFor6 = weights[6] || 0;
  const weightFor7 = weights[7] || 0;
  const weightFor8 = weights[8] || 0;
  const weightFor9 = weights[9] || 0;
  const helpArr = new Array(weightFor6).fill(6)
    .concat(new Array(weightFor7).fill(7))
    .concat(new Array(weightFor8).fill(8))
    .concat(new Array(weightFor9).fill(9));
  const randomIndex = getRandomIntBetween(0, helpArr.length - 1);
  return helpArr[randomIndex];
};

// createTextNodeWithColor
const createTextNodeWithColor = (text, color) => {
  const ele = document.createElement('h3');
  const content = document.createTextNode(text);
  ele.appendChild(content);
  ele.style.color = color;
  return ele
}

const createYao = (isYang, isBig, description) => {
  const ele = document.createElement('div');
  ele.style.cssText = "display: flex;"; 
  const yaoPatterns = [];
  if (isYang) {
    const yangPattern = document.createElement('div');
    yangPattern.style.height = '10px'
    yangPattern.style.width = '100px';
    yangPattern.style.margin = '6px';
    yangPattern.style.backgroundColor = isBig ? '#f00' : '#000';
    yaoPatterns.push(yangPattern);
  } else {
    for (let i = 0; i < 2; i++) {
      const yinPattern = document.createElement('div');
      yinPattern.style.height = '10px'
      yinPattern.style.width = '44px';
      yinPattern.style.margin = '6px';
      yinPattern.style.backgroundColor = isBig ? '#f00' : '#000';
      yaoPatterns.push(yinPattern);
    }
  }
  if (description) {
    const content = document.createTextNode(description);
    yaoPatterns.push(content);
    ele.style.color = isBig ? '#f00' : '#000';
  }

  yaoPatterns.forEach(el => {
    ele.appendChild(el)
  })
  
  return ele
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
    const weights = {
      6: 1 * 4,
      7: 5 * 4,
      8: 7 * 4,
      9: 3 * 4,
    };
    const yaoPatterns = {
      6: () => createYao(false, true, '陆'),
      7: () => createYao(true, false, '柒'),
      8: () => createYao(false, false, '捌'),
      9: () => createYao(true, true, '玖'),
    };

    const results = [];
    for (let i = 0; i < 6; i ++) {
      const yao = getYao(weights)
      results.push(yao);
      resultBox.prepend(yaoPatterns[yao]());
      await sleep(500);
    }
    console.log(results);
  };
  btn.addEventListener('click', onClickFn);
}

main();

</script>
