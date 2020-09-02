---
title: "了解一下 GitHub Actions"
date: 2020-09-02T11:11:49+08:00
draft: false
toc: false
categories:
  - notes
---

GitHub 推出了 Actions 之后，我们可以直接在 GitHub 上实现自动集成和部署，而不需要依赖第三方 CI 工具例如 TravisCI、CircleCI 等。

<!--more-->

## 一些基础概念

在玩 Action 之前，需要先了解一下基础概念：

```
                        +-------------+
                        |             |
                        |  Workflow   |
                        |             |
                        +------+------+
                               |
                               |
                               |
      +-------------------------------------------------+
      |                        |                        |
      |                        |                        |
      |                        |                        |
 +----v-----+             +----v-----+             +----v-----+
 |          +------------>+          +------------>+          |
 |   Job    |             |   Job    |             |    Job   |
 |          +------------>+          +------------>+          |
 +----------+             +----+-----+             +----------+
                               |
                               |
                               |
                               |
      +---------------------------------------------------+
      |                        |                          |
      |                        |                          |
      |                        |                          |
      |                        |                          |
+-----v-----+     +------------v--------------+      +----v-----+
|           |     |                           |      |          |
|   Step    +---->+          Step             +----->+  Step    |
|           |     | +---------+ +----------+  |      |          |
|           +---->+ | Command | |  Action  |  +----->+          |
+-----------+     | |         | |          |  |      +----------+
                  | +---------+ +----------+  |
                  +---------------------------+

```

### TL;DR

Workflow 可以在仓库根目录的 `.github/workflows` 目录下配置。一个 Workflow 至少需要包含一个 Job。一个 Job 包含了多个 Step。每个 Step 可以执行命令和脚本，也可以使用 Action。可以自己创建 Action，也可以使用社区开源的 Action。

### CI

CI 为持续集成（Continuous integration）。持续提交到代码仓库的代码，可以在每次提交的时候触发一些 CI 操作，例如构建、测试，以保证代码的质量。可以在 CI 提供的控制台查看日志等信息。

### CD

CD 为持续部署（Continuous deployment）。利用 CD 工作流，可以在代码通过 CI 测试之后，自动部署到生产环境。

### Workflow

Workflow 是你为你的代码仓库配置的一套流水线的流程，包括了构建、测试、打包、发布、部署等工作。一个 Workflow 可以由若干个 [Job](#job) 组成。Workflow 可以定时触发，也可以通过 [GitHub Event](#event) 触发.

Workflow 包含两个概念

- Workflow file 在代码仓库根目录的 `.github/workflows` 下的 YAML 配置文件

- Workflow run 一次 Workflow 运行的实例

### Runner

Runner 是安装了 GitHub Actions runner 应用程序的机器（可以是虚拟机）。每个 Runner 从等待被执行的 Job 队列中选择 Job 来执行。当 Runner 选择了一个 Job 时，Runner 会执行 Job 内的 [Action](#action) 并上报执行过程、日志和结果。Runner 每次只执行一个 Job。

Runner 分为 GitHub 自带的 Runner 和用户自己的私人 Runner。

### Job

Job 可以由若干个 [Step](#step) 组成。这些 Step 在同一个 Runner 上执行。你可以在 Workflow 的配置文件定义 Job 的执行顺序和依赖关系。不同的 Job 可以同时并行运行，也可以按顺序依次执行。

### Step

每个 Step 是一个独立的任务，可以是执行命令，也可以执行 [Action](#action)。每个 Job 可以配置一个或多个 Step。在一个 Job 中的所有的 Step 都在一个 Runner 内执行。这样就可以使得 Job 内的 Action 可以通过文件系统来共享信息了。

### Action

Action 是一个独立的任务，可以把多个 Action 组装成一个 Job。Action
是 Workflow 的最小组成单元。你可以自己创建 Action，也可以使用 Action 商店内开源的 Action。*必须*要把 Action 封装在 Step 中使用。

### Event

Event 是一些 GitHub 的事件。比如当用户 push 到代码仓库，或者发起 PR 或 Issue 时，会触发特定的 Event，从而触发 Workflow 的执行。

### Artifact

Artifact 是 Workflow run 产出的文件。比如打包生成的二进制文件、测试报告、快照、日志等。产生的 Artifact 可以给另一个 Job 使用，也可以用来部署。

## Workflow

### 创建配置文件

1. 在仓库根目录创建 `.github/workflows` 文件夹用以存放配置文件

2. 配置文件必须是 YAML 文件。后缀名是 `.yml` 或 `.yaml`

3. 配置文件的语法和格式 API 参考 [语法文档](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

4. 保存提交代码

配置文件示例

```yaml
# .github/workflows/continuous-integration-workflow.yml

name: Greet Everyone
# push 到仓库会触发此 Workflow
on: [push]

jobs:
  build:
    # 设置 Job 名称
    # Job name is Greeting
    name: Greeting
    # This job runs on Linux
    runs-on: ubuntu-latest
    steps:
      # 使用第三方 Action
      # This step uses GitHub's hello-world-javascript-action: https://github.com/actions/hello-world-javascript-action
      - name: Hello world
        uses: actions/hello-world-javascript-action@v1
        with:
          who-to-greet: 'Mona the Octocat'
        id: hello
      # This step prints an output (time) from the previous step's action.
      - name: Echo the greeting's time
        run: echo 'The time was ${{ steps.hello.outputs.time }}.'

```

以下是基础配置，完整配置，查看 [语法文档](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)


### 触发 Workflow

- 可以监听 GitHub Event，如 push

  ```yaml
  on: push
  ```
- 可以配置 Cron 来定时触发

  ```yaml
  on:
    schedule:
      - cron: '0 * * * *'
  ```

- 可以手动触发（可以点击 GitHub UI 上的按钮，也可以调用 webhook 来触发），请参考文档

### 指定分支、Tag 或路径发生改变时触发

```yaml
on:
  push:
    branches:
      - master
    tags:
      - v1
    # 默认监听所有的文件
    paths:
      - 'test/*'
```

### 指定运行环境

```yaml
runs-on: ubuntu-latest
```

### 配 Matrix

使用 Matrix 可以使 Workflow 同时在不同的机器、系统、版本、语言下运行。详情请参考文档。

### 使用 `checkout` Action

GitHub 内置了一些标准的 Action。在下列情况下必须在你的其他 Action 之前使用 `checkout` Action

- Workflow 需要使用代码的副本，比如需要构建、测试或使用 CI 时
- 至少有一个该仓库定义的 Action

```yaml
- uses: actions/checkout@v2
```

### 选择 Workflow 类型

可以选择以下类型的 Workflow。详情参考文档。

- Docker container actions
- JavaScript actions
- Composite run steps actions

### 引用 Action

可以在 Workflow 中引用已经定义好的 Action，如

- 一个 public 仓库

  - 语法 `{owner}/{repo}@{ref}` 或 `{owner}/{repo}/{path}@{ref}`

- 当前 Workflow 文件所在仓库

  - 同一个仓库下，可以使用相对路径，如 `./.github/actions/hello-world-action`

- 在 Docker Hub 上的 Docker 镜像
  - 语法 `docker://{image}:{tag}`

### 给仓库添加 Workflow 状态的图标（Badge）

如果 name 使用了空格等特殊字符，需要转义，如空格对应 `%20`

```
https://github.com/<OWNER>/<REPOSITORY>/workflows/<WORKFLOW_NAME>/badge.svg
```

示例

```md
![example workflow name](https://github.com/actions/hello-world/workflows/Greet%20Everyone/badge.svg)
```

更多示例和参数，请参考文档

---

待续。。。

---

本文流程图由 http://asciiflow.com/ 生成
