@echo off
rem
rem $Id: uuuu.bat 10380 2012-01-24 21:21:47Z tschutter $
rem
rem Directory tree navigation
rem
rem Copyright (c) 2006-2008 Tom Schutter
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

set _DIR_=..\..\..\..
set _ARGS_=%*
:loop
  if "%_ARGS_%" == "" goto endloop
  for /f "tokens=1,* delims=\\/ " %%i in ("%_ARGS_%") do set _ARGS_=%%j&&set _DIR_=%_DIR_%\%%i
goto loop
:endloop
set _ARGS_=
if "%UDOESPUSHD%" == "" cd %_DIR_%
if not "%UDOESPUSHD%" == "" pushd %_DIR_%
set _DIR_=
