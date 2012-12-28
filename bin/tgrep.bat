@echo off
rem
rem Directory tree grep
rem

setlocal

rem /R = Uses search strings as regular expressions
rem /S = Searches for matching files in the current directory and all subdirs
rem /P = Skip files with non-printable characters
set FINDSTR_OPTS=/R /S /P

rem List of names to restrict search to
set FIND_NAMES=

set PATTERN=

goto main

:print_usage
  echo Directory tree grep (uses findstr /s). >&2
  echo. >&2
  echo USAGE: tgrep [findstr-options] pattern [filespec ...] >&2
  echo   Where findstr-options include: >&2
  echo     /i = Ignore case >&2
  echo     /m = Prints only the filename >&2
  echo     /n = Prefix each line of output with the line number >&2
  echo     /v = Prints only lines that do not contain a match >&2
  goto :eof

:main

:argloop_start
  if "%1" == "" goto argloop_end
  set ARG=%1

  set FIRST_CHAR=%ARG:~0,1%
  if "%FIRST_CHAR%" == "-" goto findstr_opt
  if "%FIRST_CHAR%" == "/" goto findstr_opt
  goto try_pattern
  :findstr_opt
    set FINDSTR_OPTS=%FINDSTR_OPTS% %ARG%
    goto argloop_continue

  :try_pattern
  if not "%PATTERN%" == "" goto try_names
    set PATTERN=%ARG%
    goto argloop_continue

  :try_names
    set FIND_NAMES=%FIND_NAMES% %ARG%
    goto argloop_continue

  :argloop_continue
  shift
  goto argloop_start
:argloop_end

if not "%PATTERN%" == "" goto pattern_ok
  goto print_usage
  exit /b 1
:pattern_ok

if "%FIND_NAMES%" == "" set FIND_NAMES=*

findstr %FINDSTR_OPTS% /c:"%PATTERN%" %FIND_NAMES%
