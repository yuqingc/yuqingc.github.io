---
title: "A solution for downloading CORS images"
lead: "When \"download\" attribute of \"a\" tag does not work..."
date: 2019-07-24T15:42:31+08:00
draft: false
toc: false
tags:
  - javascript
categories:
  - notes
---

<!--more--> 
## Code

```js
export function downloadImage (imgsrc, name) {
    const image = new Image()
    // Cors Canvas pollution
    image.setAttribute('crossOrigin', 'anonymous')
    image.onload = function () {
        const canvas = document.createElement('canvas')
        canvas.width = image.width
        canvas.height = image.height
        const context = canvas.getContext('2d')
        context.drawImage(image, 0, 0, image.width, image.height);
        const _dataURL = canvas.toDataURL('image/png') // get base64 of image

        const blob_ = dataURLtoBlob(_dataURL) // 用到 Blob 是因为图片文件过大时，在一部分浏览器上会下载失败，而 Blob 就不会

        const url = {
            name: name || '图片', // 图片名称不需要加 .png 后缀名
            src: blob_
        };

        if (window.navigator.msSaveOrOpenBlob) { // if browser is IE
            navigator.msSaveBlob(url.src, url.name) // filename文件名包括扩展名，下载路径为浏览器默认路径
        } else {
            const link = document.createElement('a');
            link.setAttribute('href', window.URL.createObjectURL(url.src));
            link.setAttribute('download', url.name + '.png')
            document.body.appendChild(link)
            link.click();
        }
    };
    image.src = imgsrc;

    function dataURLtoBlob (dataurl) {
        let arr = dataurl.split(','), mime = arr[0].match(/:(.*?);/)[1],
            bstr = atob(arr[1]), n = bstr.length, u8arr = new Uint8Array(n)
        while (n--) {
            u8arr[n] = bstr.charCodeAt(n)
        }
        return new Blob([u8arr], { type: mime })
    }
}
```