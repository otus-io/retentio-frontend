git checkout main
git branch | grep -vE '^\*?\s*main$' | xargs git branch -D
