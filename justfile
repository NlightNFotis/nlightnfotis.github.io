# Show a preview on a jekyll-bootstrapped local server.
preview:
    bundle exec jekyll serve

# Perform a publish-level build (preparing the text for publication)
build:
    bundle exec jekyll build --destination docs/

# Publish new page on Github blog
publish message="""sync: syncing a new version of the site""": build
    git add docs/
    git commit -m """{{message}}"""
    git push

# Bootstrap local development environment
bootstrap:
    bundle install

# List changes
log:
    git log --pretty=oneline --grep="sync:*" --invert-grep --graph --left-right

# Update installed gems
gem-update:
    bundle update
