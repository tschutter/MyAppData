@echo off
rem
rem Directory tree navigation
rem

set _DIR_=%HOMEDRIVE%%HOMEPATH%\src
if defined HOME set _DIR_=%HOME%\src
if defined SRC_TREE set _DIR_=%SRC_TREE%

set _ARGS_=%*
:loop
  if "%_ARGS_%" == "" goto endloop
  for /f "tokens=1,* delims=\\/ " %%i in ("%_ARGS_%") do set _ARGS_=%%j&&set _DIR_=%_DIR_%\%%i
goto loop
:endloop
set _ARGS_=
if "%UDOESPUSHD%" == "" cd /d %_DIR_%
if not "%UDOESPUSHD%" == "" pushd %_DIR_%
set _DIR_=
