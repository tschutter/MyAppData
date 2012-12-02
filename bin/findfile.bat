@echo off
rem
rem Directory tree file search
rem

if "%1" == "" goto print_usage

dir /s /b %1 | findstr /l /v "\.svn\ \CVS\"

goto :eof

:print_usage
  echo Searches for a file in the current directory and all subdirectories. >&2
  echo. >&2
  echo USAGE: >&2
  echo   findfile FILENAME >&2
  echo. >&2
  echo EXAMPLES: >&2
  echo   findfile foo.c >&2
  echo   findfile *.a >&2
  goto :eof
