@echo off
rem
rem Install or update Cygwin.
rem
rem Features of this batch file:
rem   * Mostly hands-free, except for stopping of running Cygwin
rem     processes and configuration of newly installed services.
rem   * Stops and starts Cygwin services.
rem   * Lists running Cygwin processes (setup-PLATFORM.exe informs you
rem     that they are running, but does not list them).
rem   * Fetches latest setup-PLATFORM.exe from cygwin.com.
rem   * Installs standard set of packages.
rem   * Updates all installed packages.
rem   * Runs rebaseall.
rem   * Installs standard services (syslog-ng, sshd).
rem   * Installs cyglsa.
rem
rem Copyright (c) 2012 Tom Schutter
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
rem COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
rem INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
rem BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
rem LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
rem CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
rem LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
rem ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
rem POSSIBILITY OF SUCH DAMAGE.
rem

setlocal
goto :main

:load_config
    set _CONFFILE=%~dp0\cygwin_setup_config.bat
    if exist "%_CONFFILE%" goto :endif_check_conffile
        echo %_PREFIX% ERROR: Configuration file "%_CONFFILE%" not found.
        exit /b 1
    :endif_check_conffile
    set _PACKAGES=
    set _ROOTDIR=
    set _SITE=
    set _CONFIG_SYSLOG_NG=
    set _CONFIG_SSHD=
    set _CONFIG_LSA=
    call "%_CONFFILE%"
    if "%_PACKAGES%" == "" (
        echo %_PREFIX% ERROR: _PACKAGES not defined in "%_CONFFILE%"
        exit /b 1
    )
    if "%_ROOTDIR%" == "" (
        echo %_PREFIX% ERROR: _ROOTDIR not defined in "%_CONFFILE%"
        exit /b 1
    )
    if "%_SITE%" == "" (
        echo %_PREFIX% ERROR: _SITE not defined in "%_CONFFILE%"
        exit /b 1
    )
    if "%_CONFIG_SYSLOG_NG%" == "" (
        echo %_PREFIX% ERROR: _CONFIG_SYSLOG_NG not defined in "%_CONFFILE%"
        exit /b 1
    )
    if "%_CONFIG_SSHD%" == "" (
        echo %_PREFIX% ERROR: _CONFIG_SSHD not defined in "%_CONFFILE%"
        exit /b 1
    )
    if "%_CONFIG_LSA%" == "" (
        echo %_PREFIX% ERROR: _CONFIG_LSA not defined in "%_CONFFILE%"
        exit /b 1
    )
exit /b 0


:check_admin
    rem Check for ADMIN privileges
    rem https://sites.google.com/site/eneerge/home/BatchGotAdmin

    "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system" >nul 2>&1
    if not ERRORLEVEL 1 goto :endif_check_admin
        echo %_PREFIX% ERROR: You do not have Administrator privileges
        echo %_PREFIX% Rerun from a "Run as Administrator" command prompt
        exit /b 1
    :endif_check_admin
exit /b 0


:check_for_wget_exe
    rem wget.exe is used to fetch setup-PLATFORM.exe
    if exist wget.exe exit /b 0
    for /f %%i in ("wget.exe") do if not "%%~$PATH:i" == "" exit /b 0
    echo %_PREFIX% ERROR: wget.exe not found in PATH
    echo %_PREFIX% One source is http://users.ugent.be/~bpuype/wget/
exit /b 1


:stop_services
    rem Stop all Cygwin services.
    if not exist "%_ROOTDIR%\bin\cygrunsrv.exe" goto :eof
    for /f "usebackq" %%s in (`"%_ROOTDIR%\bin\cygrunsrv.exe" --list`) do (
        echo %_PREFIX% Stopping %%s
        "%_ROOTDIR%\bin\cygrunsrv.exe" --stop %%s
    )
goto :eof


:start_service
    rem Start a single Cygwin service.
    echo %_PREFIX% Starting %1
    "%_ROOTDIR%\bin\cygrunsrv.exe" --start %1
goto :eof


:start_services
    rem Start all Cygwin services.

    rem Start syslog-ng first.
    for /f "usebackq" %%s in (`"%_ROOTDIR%\bin\cygrunsrv.exe" --list`) do (
        if "%%s" == "syslog-ng" call :start_service %%s
    )
    rem Start rest of services.
    for /f "usebackq" %%s in (`"%_ROOTDIR%\bin\cygrunsrv.exe" --list`) do (
        if not "%%s" == "syslog-ng" call :start_service %%s
    )
goto :eof


:check_for_cygwin_proc
    rem Check for any Cygwin processes.
    echo %_PREFIX% Checking for running Cygwin processes
    if not exist "%_ROOTDIR%\bin\ps.exe" exit /b 0
    set _TEMPFILE=%TEMP%\cygwin_setup.txt
    :retry
        "%_ROOTDIR%\bin\ps.exe" -l | findstr /v /c:"/usr/bin/ps" > "%_TEMPFILE%"
        findstr /v /r /c:"PID.*COMMAND" "%_TEMPFILE%" | findstr /r /c:"^..*" > NUL:
        if ERRORLEVEL 1 goto :ignore
        echo %_PREFIX% Found running Cygwin processes using: "%_ROOTDIR%\bin\ps.exe" -l
        type "%_TEMPFILE%"
        del "%_TEMPFILE%"
        :ask_abort_retry_ignore
            set /p _ANSWER=Abort, Retry, or Ignore?
            set _ANSWER=%_ANSWER:~0,1%
            if "%_ANSWER%" == "a" exit /b 1
            if "%_ANSWER%" == "A" exit /b 1
            if "%_ANSWER%" == "r" goto :retry
            if "%_ANSWER%" == "R" goto :retry
            if "%_ANSWER%" == "i" goto :ignore
            if "%_ANSWER%" == "I" goto :ignore
        goto :ask_abort_retry_ignore
    :ignore
exit /b 0


:get_setup_exe
    rem Download latest setup-PLATFORM.exe.
    if not exist %_ROOTDIR% (
        echo %_PREFIX% Creating %_ROOTDIR%
        mkdir "%_ROOTDIR%"
    )
    echo %_PREFIX% Fetching latest %_SETUP_EXE% from cygwin.com
    wget --quiet -O "%_ROOTDIR%\%_SETUP_EXE%" http://cygwin.com/%_SETUP_EXE%
goto :eof


:setup
    rem Run setup-PLATFORM.exe.
    echo %_PREFIX% Running %_SETUP_EXE% for updates
    "%_ROOTDIR%\%_SETUP_EXE%" --site %_SITE% --quiet-mode --no-shortcuts --root "%_ROOTDIR%" --local-package-dir "%_ROOTDIR%\LocalPackageDir"
    echo %_PREFIX% Running %_SETUP_EXE% to install standard package set
    "%_ROOTDIR%\%_SETUP_EXE%" --site %_SITE% --quiet-mode --no-shortcuts --root "%_ROOTDIR%" --local-package-dir "%_ROOTDIR%\LocalPackageDir" --packages %_PACKAGES%
goto :eof


:rebaseall
    rem Run rebaseall.
    rem This should be handled by setup-PLATFORM.exe, but at this time
    rem setup-PLATFORM.exe does not handle all cases.  And running
    rem rebaseall unnecessarily should cause no harm.
    rem See http://cygwin.com/ml/cygwin/2012-08/msg00320.html
    echo %_PREFIX% Running rebaseall
    "%_ROOTDIR%\bin\dash.exe" -c 'cd /usr/bin; PATH=. ; rebaseall'
goto :eof


:config_syslog_ng
    sc query syslog-ng | findstr "service does not exist" > NUL:
    if ERRORLEVEL 1 goto :eof

    echo %_PREFIX% Configuring syslog-ng
    if not exist "%_ROOTDIR%\bin\syslog-ng-config" (
        echo %_PREFIX% ERROR: syslog-ng not installed
        goto :eof
    )
    "%_ROOTDIR%\bin\bash.exe" --login -i -c "/usr/bin/syslog-ng-config --yes"
goto :eof


:config_sshd
    sc query sshd | findstr "service does not exist" > NUL:
    if ERRORLEVEL 1 goto :eof

    echo %_PREFIX% Configuring sshd
    if not exist "%_ROOTDIR%\bin\ssh-host-config" (
        echo %_PREFIX% ERROR: opensshd not installed
        goto :eof
    )
    "%_ROOTDIR%\bin\bash.exe" --login -i -c "/usr/bin/ssh-host-config"
    echo %_PREFIX% Disabling reverse DNS lookup by sshd
    "%_ROOTDIR%\bin\bash.exe" --login -i -c "/usr/bin/sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/sshd_config"
goto :eof


:config_lsa
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if not ERRORLEVEL 1 goto :eof

    echo %_PREFIX% Configuring cyglsa
    "%_ROOTDIR%\bin\bash.exe" --login -i -c "/usr/bin/cyglsa-config"
goto :eof


:main
    rem Global constants.
    set _PREFIX=CYGWIN_SETUP:

    call :load_config ||exit /b 1
    call :check_admin ||exit /b 1
    call :check_for_wget_exe ||exit /b 1
    call :stop_services
    call :check_for_cygwin_proc ||exit /b 1
    call :get_setup_exe
    call :setup
    call :rebaseall
    if "%_CONFIG_SYSLOG_NG%" == "True" call :config_syslog_ng
    if "%_CONFIG_SSHD%" == "True" call :config_sshd
    call :start_services
    rem Do config_lsa last so that reboot message is last
    if "%_CONFIG_LSA%" == "True" call :config_lsa
:exit
