# Blog

This is the source code of [my personal blog](https://nlightnfotis.github.io). It is a
statically generated site powered by [Jekyll](https://github.com/jekyll/jekyll).

If you find any issues with the site, please don't hesitate to let me know by [filing
an issue](https://github.com/NlightNFotis/nlightnfotis.github.io/issues/new).

## Technical

The following are notes to self:

* To build use `jekyll build --destination docs/`.
  * That's necessary because the theme I use depends on some plugins that don't
    install on the runners running the default github actions jekyll build action.

    This is why I have to target a different target directory, which github
    only allows for `/` or `/docs` and nothing else.
