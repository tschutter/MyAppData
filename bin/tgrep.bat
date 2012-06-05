@echo off
rem
rem Directory tree grep
rem
rem
rem Copyright (c) 2006-2012 Tom Schutter
rem All rights reserved.
rem
rem Redistribution and use in source and binary forms, with or without
rem modification, are permitted provided that the following conditions
rem are met:
rem
rem    - Redistributions of source code must retain the above copyright
rem      notice, this list of conditions and the following disclaimer.
rem    - Redistributions in binary form must reproduce the above
rem      copyright notice, this list of conditions and the following
rem      disclaimer in the documentation and/or other materials provided
rem      with the distribution.
rem
rem THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
rem "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
rem LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
rem FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
rem COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
rem INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
rem BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
rem LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
rem CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
rem LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
rem ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
rem POSSIBILITY OF SUCH DAMAGE.
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
  goto end_main
:pattern_ok

if "%FIND_NAMES%" == "" set FIND_NAMES=*

findstr %FINDSTR_OPTS% /c:"%PATTERN%" %FIND_NAMES%

:end_main
endlocal
