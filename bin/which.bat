@echo off
rem
rem Locates a command, whether it is a executable or a batch file.
rem

rem
rem Implementation notes.
rem The original incarnation of this batch file used the % ~$PATH:i
rem syntax of the FOR command.  This works as long as you know the file
rem extension that you are looking for.  But PATHEXT loop must be
rem inside the PATH loop, so that syntax doesn't work.
rem

setlocal

set _ALL_=False
if "%1"=="" goto :usage
if "%1"=="-a" (shift && set _ALL_=True)
if "%1"=="/a" (shift && set _ALL_=True)
if not "%2"=="" (call :usage && goto :end_main)
set _ARG_=%1

goto :main

:usage
    echo USAGE: which [-a] FILENAME
    echo        Searches the directories listed in the PATH environment
    echo        variable for FILENAME.
    echo   -a = Print all located files, not just the first
goto :eof

:check_file
    if not exist "%*" goto :eof
    if "%_ALL_%"=="False" if "%_FOUND_%"=="True" goto :eof
    echo %*
    set _FOUND_=True
goto :eof

:check_pathext
    set _BASENAME_=%*

    rem If extension already given, such as .dll.
    call :check_file %_BASENAME_%
    if "%_ALL_%"=="False" if "%_FOUND_%"=="True" goto :eof

    set _PATHEXT_=%PATHEXT%
    :check_pathext_loop
        for /f "delims=; tokens=1*" %%i in ("%_PATHEXT_%") do (set _EXT_=%%i&set _PATHEXT_=%%j)
        call :check_file %_BASENAME_%%_EXT_%
        if "%_ALL_%"=="False" if "%_FOUND_%"=="True" goto :eof
    if not "%_PATHEXT_%"=="" goto :check_pathext_loop
goto :eof

:check_path
    set _PATH_=%PATH%
    :check_path_loop
        for /f "delims=; tokens=1*" %%i in ("%_PATH_%") do (set _DIR_=%%i&set _PATH_=%%j)
        call :check_pathext %_DIR_%\%_ARG_%
        if "%_ALL_%"=="False" if "%_FOUND_%"=="True" goto :eof
    if not "%_PATH_%"=="" goto :check_path_loop
goto :eof

:main
    set _FOUND_=False
    rem Determine if the argument includes a directory.
    if "%_ARG_%"=="%_ARG_:\=/%" goto :nodir
        rem Check the arg directly, but do not process the PATH.
        call :check_pathext %_ARG_%
        goto :endif_nodir
    :nodir
        rem Check the current directory.
        call :check_pathext %_ARG_%
        rem Check all directories in the path.
        call :check_path
    :endif_nodir
:end_main
