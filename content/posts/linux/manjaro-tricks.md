---
title: "Manjaro 踩坑记"
date: 2019-07-07T15:42:31+08:00
draft: false
toc: false
tags:
  - linux
  - manjaro
categories:
  - blogs
---

## 开工

[Manjaro](https://manjaro.org/) 是一款基于 [Arch Linux](https://www.archlinux.org/) 的系统。它由很多个内置桌面的发行版，本文以 [Gnome 版本](https://manjaro.org/download/gnome/)为例。


## 系统安装

重要事项，第一次安装一定要阅读手册：

> When you are ready, follow ‘First steps’. We also encourage you to read our [MANUAL](https://manjaro.org/support/userguide/).

不要直接用 [Rufus](https://rufus.ie/) 或者 [UltraISO](https://cn.ultraiso.net/) 凭自己想象做镜像，会失败的。一定要：

> Use **dd** as copy option to make a working bootable USB-Stick

*刻录时使用 dd 模式。这和刻录 Ubuntu 盘不一样*

### 刻录启动盘软件

官网推荐以下两款

- [Rufus](https://rufus.ie/) （我使用的是这个，但是只有 Windows 版本）
- [Image Writer](https://launchpad.net/win32-image-writer/)

## 驱动

大部分驱动都已经包含在了系统中，如果发现没有 WIFI，或者没有声音，大部分是因为驱动缺失引起的。以 HP 为例，WIFI 驱动缺失了。在安装驱动之前首先使用 `lshw` 命令确认电脑的硬件型号，然后再去网上搜对应的驱动安装

以 *rtl8821ce* 无线网卡为例，安装步骤如下

```
$ git clone https://aur.archlinux.org/rtl8821ce-dkms-git.git

$ cd rtl8821ce-dkms-git

$ makepkg -sic
```

> 注意：安装时一定要确认自己的系统的内核版本型号，安装对应内核版本的驱动。查看内核版本，使用 `uname -a`

### Nvidia 显卡驱动安装

参考 https://wiki.manjaro.org/index.php?title=Configure_NVIDIA_(non-free)_settings_and_load_them_on_Startup

如果没有游戏或者 GPU 计算的需求，就不必安装了

> 安装完极有可能出现 Gnome 桌面无法启动，卡在启动页面。请勿惊慌，`ctrl + alt + f?` 进入命令行，按照上述文档，手动重装或者卸载 Nvidia 驱动

## 包管理

Arch 系默认使用强大的 pacman 进行包管理。但是因为 *众所周知* 的原因，我们需要国内的镜像源，否则下载安装的速度难以想象。

### 设置国内镜像源

```
$ sudo pacman-mirrors -i -c China -m rank
```

该命令会唤起一个 GUI 界面，在里面可以选择你喜欢的国内源

### 更新 key

装完系统之后切忌强迫症无脑 `pacman -Syu`。为什么要更新 key，这里不细说

```
$ sudo pacman-key --refresh-keys
```

或者指定某个服务器来更新 key

```
$ sudo pacman-key --refresh-keys --keyserver pgp.mit.edu
```

### Syu 🤣

强迫症同学现在可以执行这一步了

```
$ sudo pacman -Syu
```

### AUR

如果想通过系统自带应用管理器安装丰富的应用，在设置里启用 AUR 即可。在 AUR 里，可以找到你想要的几乎所有应用（绝对超过 apt）。至少目前我没有在 AUR 和 Pacman 之外安装过任何软件。

关于 AUR，没有必要使用 *yaourt* 。系统自带的 GUI 包管理工具完全满足了日常需求。如果喜欢 CLI，可以使用系统自带的 *pamac* （用法 `--help` 即可）。

比如你在 VSCode 官网想下载 Linux 包，只看见了 deb 和 rpm，不要惊慌，直接去 AUR 搜索即可。目前 AUR 的软件资源非常丰富，包括但不限于：

- VirtualBox
- VSCode
- Postman
- MongoDB
- ...

## 其他

### 输入法

- 说结论。直接使用原生 fcitx 或者 ibus 即可。体验虽然不如搜狗，但是截至目前搜狗是无法安装的，原因是搜狗依赖的某个 qt 包已经被官方源删除了。
- 建议使用 ibus-rime
- 安装完成输入法之后要在 `.bashrc` 内设置以下环境变量

  ```bash
  export GTK_IM_MODULE=ibus
  export XMODIFIERS=@im=ibus
  export QT_IM_MODULE=ibus
  ```
- 安装完成之后需要在系统设置里面把安装好的输入法添加到 input source 里面

#### ibus 无法修改字体大小的解决方案

1. 下载浏览器插件 [Gnome Shell Extension](https://extensions.gnome.org/extension/1121/ibus-font-setting/)
2. 安装 [IBus Font Setting](https://extensions.gnome.org/extension/2729/ibus-font-setting/) 即可
3. ibus 自带字体设置就可以生效了

### 修改键位

- 把 CapsLocks 改成 Control；把 Shift+CapsLocks 改成 toggle 大小写要注意:
  - 不要把 `xmodmap -pke` 的输出整个放在 `.Xmodmap`，否则执行 xmodmap 的时候会非常卡。
  - 具体原因参[这里](https://unix.stackexchange.com/questions/94336/xmodmap-hanging-the-system-for-20-secs-and-not-sticking/390198#390198)

### nslookup

```
bind-tools
```

### ssh server

这个和 Ubuntu 不太一样，Ubuntu 上安装 `openssh-server`。Manjaro 需要

- 1. 安装 `openssh`
- 2. `$ sudo systemctl enable sshd.service`

### Docker

Docker 安装比较简单，去 AUR 搜索即可。安装之后需要手动允许在后台运行

```
$ sudo systemctl enable docker
```

### Emoji 😁 支持

Firefox 内置了 Emoji 的支持。但是其他浏览器和应用要想显示 Emoji 需要安装 `noto-fonts-emoji`

```
$ sudo pacman -Syu noto-fonts-emoji
```

### 其他

- neofetch 查看系统信息
- [`bat`](https://github.com/sharkdp/bat) 用来取代 `less` 或者 `cat`
- [`lsd`](https://github.com/Peltoche/lsd) 用来取代 `ls`

### 万能的 Tweaks

一定要玩一玩 Gnome 自带的 tweaks 工具，他可以帮助你优化和各种自定义你的桌面


## Last but not least，[论坛](https://forum.manjaro.org/) 是个好东西

---

*最后赠送一组 Manjaro 高清壁纸，点击下方图片名即可预览并下载图片* 👇

- 👉 <a style="text-align: center" target="_blank" href="/images/manjaro/matrix-manjaro.jpg">Matrix Manjaro</a>

- 👉 <a style="text-align: center" target="_blank" href="/images/manjaro/manjaro-cat.jpg">Manjaro Cat</a>

- 👉 <a style="text-align: center" target="_blank" href="/images/manjaro/manjaro-dog.jpg">Manjaro Dog</a>

- 👉 <a style="text-align: center" target="_blank" href="/images/manjaro/light-stripe-maia.jpg">Light Stripe Maia</a>

> 图片位于 `/usr/share/backgrounds` 目录, 版权所有 [@Manjaro Linux](https://manjaro.org/). All above pictures' rights are reserved by [@Manjaro Linux](https://manjaro.org/)


---
*Authored by <a target="_blank" href="https://github.com/yuqingc">@yuqingc</a> 转载请注明出处*
