@echo off
rem
rem Do a "git pull" wrapped with a stash push/pop.
rem

git stash push --keep-index --message "git-pull temp" --quiet
git pull
git stash pop --quiet
