# yuqingc.github.io

- Clone & update submodules (themes)

    ```
    $ git clone --recursive git@github.com:yuqingc/homepage-src.git
    ```

- Update submodules (This is important)

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
    $ cd public
    $ git add . && git commit -m "message"
    $ git push

    $ cd ..
    $ git add . && git commit -m "message"
    ```
