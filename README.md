# [yuqingc.github.io](https://yuqingc.github.io/)

[![GitHubPages](https://github.com/yuqingc/yuqingc.github.io/workflows/GitHubPages/badge.svg)](https://github.com/yuqingc/yuqingc.github.io/actions)

The `master` branch contains all source codes for the page. Generated contents are deployed to the [`gh-page`](https://github.com/yuqingc/yuqingc.github.io/tree/gh-pages) branch.

## Get Started

### Prerequisite

Install [**Hugo**](https://github.com/gohugoio/hugo/) first.

### Clone & update submodules (themes)

```
$ git clone --recursive git@github.com:yuqingc/yuqingc.github.io.git
```

### Update submodules for themes

```
$ git submodule update
```

### Write new post

```
$ hugo new posts/article.md
```

### Start server locally

```
$ hugo server -D
```
    
### Build

```
$ hugo
```

## Deployment

### Deploy manually

```
$ ./bin/publish_to_ghpages.sh
```

### Deploy with GitHub Actions

This Repository has been configured for deployment with GitHub Actions. See [Actions](https://github.com/yuqingc/yuqingc.github.io/actions).
