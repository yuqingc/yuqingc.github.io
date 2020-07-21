---
title: "Flutter 防坑日记"
lead: ""
date: 2020-07-20T10:50:17+08:00
draft: false
toc: true
categories:
  - "blogs"
tags:
  - "flutter"
---

*我所用的环境为 Manjaro Linux x64*

## Flutter 环境准备

由于众所周知的原因，Flutter 的官网 (https://flutter.dev/) 大概率是访问不了的，就算能访问，也很慢。官方很贴心地为 QIANG 内用户准备了中文官网：

- https://flutter.cn


按照官网的步骤下载 Flutter 包之后，需要根据国情，设置一些环境变量，用来设置镜像源。也可以设置其他地址，请参考 https://flutter.cn/community/china

```sh
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## Android SDK 和 IDE 准备


检查环境是否 ok 我们可以随时使用下面的命令来判断

```
$ flutter doctor -v
```

### SDK

需要安装 Android SDK 和模拟器，所以我们需要安装 Android Studio （以下简称 AS）。又由于众所周知的原因，我们无法访问 Android 的官网 https://www.android.com。我们可以在阉割版的中文官网下载安装包

- https://developer.android.google.cn/

也可以通过发行版 Linux 对应的包管理工具（如 Deb、Rpm、AUR 等）进行安装。安装完成之后，坑就来了。

首次运行的时候，Setup Wizard 会带你完成使用前的设置。再次由于众所周知的原因，会出现第一个报错

```
Unable to access Android SDK add-on list
```

下面会有两个按钮，一个是 `Setup Proxy`，另一个是 `Cancel`。网上的一些文章会让你设置代理，比如东软的源（`mirrors.neusoft.edu.cn:80`）。但是，**千万不要**设置这个代理，因为这些源是有问题了，设置之后根本获取不到 Android SDK 的列表，会导致后面的安装步骤无法进行。这里选择 `Cancel` 就可以了。

后面，AS 会自动从 `dl.google.com` 下载 SDK，目前看到的情况是不用 FQ 是可以正常自动安装的。所以一直“Next”就可以了。

安装完成之后，最好再设置下面的环境变量。因为 VSCode 可能会 依赖这个环境变量去定位 Android SDK


```sh
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
```

### 模拟器

在 AS 中运行 AVD 一直打不开模拟器。原来，电脑离还运行这 VBox。关掉 VBox 之后，模拟器就可以正常运行了。目前 VBox 和 AVD 无法同时运行网上也有解决方案，可以自行搜索。


### VSCode

按照官网的指南，在 VSCode 中安装了 Flutter 插件之后，运行 Demo。第一次会卡在 `Running Gradle task 'assembleDebug'...` 这个步骤。原因有 2 个，需要一一排查。

**原因一 Maven 源问题**

我们需要修改 `android/build.gradle` 中 `buildscript/repositories` 和 `allprojects/repositories` 的 Maven 源：


```
  // 需要注释掉原有的
  // google()
  // jcenter()
  maven { url 'https://maven.aliyun.com/repository/google' }
  maven { url 'https://maven.aliyun.com/repository/jcenter' }
  maven { url 'http://maven.aliyun.com/nexus/content/groups/public' }
```

查看网上的资料，也许要修改 Flutter 安装目录下 `packages/flutter_tools/gradle/flutter.gradle` 文件对应的 `buildscript/repositories` （同上）

也许要修改下面的字段

```java
// private static final String MAVEN_REPO      = "https://storage.googleapis.com/download.flutter.io";
private static final String MAVEN_REPO      = "https://storage.flutter-io.cn/download.flutter.io";
```

没有试过不改会不会不生效，可以先改改看

**原因二 Gradle 安装失败**

在改完上述代码之后，仍然还卡在 `Running Gradle task 'assembleDebug'...` 这个步骤。而且会报网络的 Exception。在求助了 Android 开发同学之后，终于找到了原因。原来 VSCode 并没有显示完整的报错信息。使用 AS 就可以看到原来是 Gradle 的包没有找到。

**所以并不推荐使用 VSCode。**

由于 IDE 自动安装 Gradle 会非常慢。推荐手动安装。首先在 `android/gradle/wrapper/gradle-wrapper.properties` 可以看到本项目使用的 Gradle 版本。在 Gradle 的官网（https://gradle.org/）就可以下载到完整的包。

在 https://services.gradle.org/distributions/ 下载对应版本的包，如 `gradle-5.6.2-all.zip`。

下载完成之后解压到 `～/.gradle/wrapper/dists/gradle-5.6.2-all/xxx` 下。其中 `xxx` 为一串如 `9st6wgf78h16so49nn74lgtbb` 的字符串。

### AS

推荐使用 AS 来编译运行。在完成上述步骤之后，就可以在 AS 运行项目了。运行之前打开模拟器。

## iOS 环境

TODO 待续

