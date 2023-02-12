# Show a preview on a jekyll-bootstrapped local server.
preview:
    bundle exec jekyll serve

# Perform a publish-level build (preparing the text for publication)
build:
    bundle exec jekyll build --destination docs/

# Publish new page on Github blog
publish: build
    git push
