---
title: "YI every day"
date: 2020-5-20T20:08:20+08:00
draft: false
toc: false
categories:
  - "quotes"
---

<button id="TkYZTfu6n2ZEzWTE">Start</button>

### Result

<div id="TkYZTfu6n2ZEzWTE-result"></div>

<script type="text/javascript">
const btn = document.querySelector("#TkYZTfu6n2ZEzWTE");
const getRandomIntBetween = (min, max) => {
  if (!(min < max)) {
    throw new Error('min must be smaller than max');
  }
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
};
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
  const ele = document.createElement('h3');;
  const content = document.createTextNode(text);
  ele.appendChild(content);
  ele.style.color = color;
  return ele
}
const onClickFn = () => {
  const resultBox = document.querySelector("#TkYZTfu6n2ZEzWTE-result");
  // Remove all child nodes
  while (resultBox.firstChild) {
    resultBox.removeChild(resultBox.firstChild);
  }
  const weights = {
    6: 1,
    7: 5,
    8: 7,
    9: 3,
  };
  const yaoPics = {
    6: () => createTextNodeWithColor('- - (6)', '#f00'),
    7: () => createTextNodeWithColor('--- (7)', '#000'),
    8: () => createTextNodeWithColor('- - (8)', '#000'),
    9: () => createTextNodeWithColor('--- (9)', '#f00'),
  };
  const result = [];
  for (let i = 0; i < 6; i ++) {
    result.unshift(getYao(weights));
  }
  result.forEach(yao => {
    resultBox.appendChild(yaoPics[yao]());
  });
};
btn.addEventListener('click', onClickFn);
</script>
