@echo off
rem
rem Do a "git pull" wrapped with a stash push/pop.
rem

git stash push --keep-index --message "git-pull temp"^
  | findstr /C:"No local changes to save"^
  > NUL:
set STASHED=%ERRORLEVEL%

git pull

rem git version 2.24.0.windows.2 will delete .git/index if we specify
rem --quiet
if %STASHED% EQU 1 git stash pop
