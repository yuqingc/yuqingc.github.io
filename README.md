# yuqingc.github.io

![GitHubPages](https://github.com/yuqingc/yuqingc.github.io/workflows/GitHubPages/badge.svg)

The `master` branch contains all source codes for the page. Generated contents are at the [`gh-page`](https://github.com/yuqingc/yuqingc.github.io/tree/gh-pages) branch.

## Get Started

- Clone & update submodules (themes)

    ```
    $ git clone --recursive git@github.com:yuqingc/yuqingc.github.io.git
    ```

- Update submodules for themes

    ```
    $ git submodule update
    ```

- Write new post

    ```
    $ hugo new posts/article.md
    ```

- Start

    ```
    $ hugo server -D
    ```
    
- Build

    ```
    $ hugo
    ```

- Publish

    ```
    $ ./bin/publish_to_ghpages.sh
    ```
