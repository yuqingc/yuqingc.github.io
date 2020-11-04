---
title: "使用 Go Modules"
lead: ""
date: 2020-08-31T10:50:17+08:00
draft: false
toc: true
categories:
  - "posts"
tags:
  - "go"
---

## 背景

Go 1.11 之前，包管理不太方便，所有的项目需要在 `GOPATH` 目录下统一管理。我们还可以同时使用 [`vendor`](https://golang.org/cmd/go/#hdr-Vendor_Directories) 目录来保存所有的依赖。可用的包管理工具有官方的 [dep](https://github.com/golang/dep) 或第三方的 [govendor](https://github.com/kardianos/govendor) 等。

从 Go 1.11 开始，Go 引入了新的版本管理机制 —— Go Modules。从 1.13 开始，Go Modules 成为了 Go 的默认包管理工具（在此之前是 `GOPATH`）。因此现在推荐使用 Go Modules 来管理所有的依赖。

使用 Go Modules，我们的代码就可以不必全部放在 `GOPATH` 下，并按照包的路径来存放代码目录了。我们可以把代码放在 `GOPATH` 之外的目录。

本文为 Go Modules 的初级使用指南。

## 开始使用

### 初始化

- 在使用 Go Modules 之前，我们需要把代码目录放在 `GOPATH` 之外

- 进入代码根目录执行 `go mod init 包路径`

  ```txt
  $ go mod init github.com/yuqingc/hello
  ```

- 执行完成命令之后，代码根目录会生成 `go.mod`。类似 Node.js 项目中的 `package.json`

  ```txt
  module github.com/yuqingc/hello

  go 1.15
  ```

### 添加依赖

- 如果代码中有外部依赖的包，在执行会触发编译 go 命令的时候（如 `go run`, `go build`, `go install`, `go test` 等）会自动在 `go.mod` 中自动添加依赖

  ```txt {hl_lines=["5"]}
  module github.com/yuqingc/hello
  
  go 1.15

  require rsc.io/quote/v3 v3.1.0
  ```

- 同时会生成 `go.sum` 文件。`go.sum` 文件类似 `package-lock.json`，记录了依赖树的版本及其 Hash

- `go.mod` 和 `go.sum` 需要包含在版本管理中 （不要写入 `.gitignore`）

- 下载下来的依赖，会保存在 `$GOPATH/pkg/mod` 目录下

### 安装和升级依赖

在 Go Module 模式下，`go get` 的行为会发生改变。在 GOPATH 模式下，`go get` 会把代码下载到 `GOPATH` 下对应的 `src` 目录下。而在 Go Module 模式下，`go get` 会给当前的项目下载最新版本的依赖，并写入 `go.mod` 和 `go.sum`

如果下载的依赖没有被项目的代码直接 import，则会在 `go.mod` 的对应项目中自动添加注释 `// indirect`

```txt {hl_lines=["6"]}
module example.com/hello

go 1.15

require (
	golang.org/x/text v0.3.3 // indirect
	rsc.io/quote/v3 v3.1.0
)
```

### 依赖版本规则

所有的版本遵循 [semantic](https://semver.org/) 版本号规则。不论是通过代码中 `import` 自动解析的依赖，还是通过 `go get` 手动安装的依赖，都遵循如下规则

- 默认安装最新版本（`@latest`），包括

  - 最新带有 tag 的稳定版
  - 或者最新带有 tag 的 pre-release 版
  - 或最新不带 tag 的版本（pseudo-version，则版本号为 git 最新提交记录的 Hash）

- 可以通过包名后加 `@版本号` 来手动下载指定的版本的依赖

  ```txt
  $ go get rsc.io/sampler@v1.3.1
  ```

- 如果某个包有含多个 Major 版本，则使用默认包路径下载的版本最大为 `v1.x` 的版本

- 为了使项目同时兼容多个包的 Major 版本，`v2.x` 之后的包名需要在结尾添加形如 `v3` 的后缀

  代码：

  ```go {hl_lines=["3"]}
  package hello

  import "rsc.io/quote/v3"
  ```

  命令：

  ```txt
  $ go get rsc.io/quote/v3
  ```

### 依赖管理的相关命令

- `go list -m` `m` 代表 `modules`，此命令集用来列出与 Modules 相关信息

  - `go list -m all` 列出项目中的所有依赖及其依赖树

  - `go list -m -versions 包名` 列出指定包的所有版本号

- `go mod tidy` 用来移除无用的依赖

---

## 参考资料

- https://blog.golang.org/using-go-modules

- https://golang.org/doc/code.html

- https://golang.org/ref/mod
