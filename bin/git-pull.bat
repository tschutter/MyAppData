@echo off
rem
rem Do a "git pull" wrapped with a stash push/pop.
rem

git stash push --keep-index --message "git-pull temp"^
  | findstr /C:"No local changes to save"^
  > NUL:
set STASHED=%ERRORLEVEL%

git pull

if %STASHED% EQU 1 git stash pop --quiet
