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

### Update sub modules for themes

```
$ git submodule update --init --recursive --remote
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

This repository has been configured for deployment with GitHub Actions. See [Actions](https://github.com/yuqingc/yuqingc.github.io/actions).

## Known issues

- [An i18n related issue](https://github.com/gohugoio/hugo/issues/7822) causes authorbox breaks when using Hugo of which version is newer than 0.76. Do not upgrade Hugo version in `.env` until this issue is fixed.
