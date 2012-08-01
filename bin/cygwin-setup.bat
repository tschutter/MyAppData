@echo off
rem
rem Install or update Cygwin.
rem

setlocal

set _PACKAGES=cron,diffutils,inetutils,ncurses,netcat,openssh,p7zip,procps,python,rsync,screen,unzip,vim,zip,genisoimage,w3m,wodim
set _ROOTDIR=C:\cygwin
set _SITE=http://mirrors.xmission.com/cygwin
set _PREFIX=CYGWIN-SETUP:

goto :main

:check_admin
    rem Check for ADMIN privileges
    rem https://sites.google.com/site/eneerge/home/BatchGotAdmin

    echo %_PREFIX% Checking for Administrator privileges
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
    if "%ERRORLEVEL%" EQU "0" goto :endif_check_admin
        echo %_PREFIX% ERROR: You do not have Administrator privileges
        echo %_PREFIX% Rerun from a "Run as Administrator" command prompt
        exit /b 1
    :endif_check_admin
goto :eof


:stop_services
    if not exist "%_ROOTDIR%\bin\cygrunsrv.exe" goto :eof
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do (
        echo %_PREFIX% Stopping %%s
        %_ROOTDIR%\bin\cygrunsrv --stop %%s
    )
goto :eof


:start_service
    echo %_PREFIX% Starting %1
    %_ROOTDIR%\bin\cygrunsrv --start %1
goto :eof


:start_services
    rem Start syslogd first.
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do (
        if "%%s" == "syslogd" call :start_service %%s
    )
    rem Start rest of services.
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do (
        if not "%%s" == "syslogd" call :start_service %%s
    )
goto :eof


:get_setup_exe
    if not exist %_ROOTDIR% (
        echo %_PREFIX% Creating %_ROOTDIR%
        mkdir %_ROOTDIR%
    )
    echo %_PREFIX% Fetching latest setup.exe from cygwin.com
    wget --quiet -O %_ROOTDIR%\setup.exe http://cygwin.com/setup.exe
goto :eof


:setup
    echo %_PREFIX% Running setup.exe for updates
    %_ROOTDIR%\setup.exe --site %_SITE% --quiet-mode --no-shortcuts --root %_ROOTDIR% --local-package-dir %_ROOTDIR%\LocalPackageDir
    echo %_PREFIX% Running setup.exe to install standard package set
    %_ROOTDIR%\setup.exe --site %_SITE% --quiet-mode --no-shortcuts --root %_ROOTDIR% --local-package-dir %_ROOTDIR%\LocalPackageDir --packages %_PACKAGES%
goto :eof


:create_passwd
    if not exist %_ROOTDIR%\etc\passwd (
        echo %_PREFIX% Creating /etc/passwd
        %_ROOTDIR%\bin\bash --login -i -c '/usr/bin/mkpasswd --local > /etc/passwd'
    )
    if not exist %_ROOTDIR%\etc\group (
        echo %_PREFIX% Creating /etc/group
        %_ROOTDIR%\bin\bash --login -i -c '/usr/bin/mkgroup --local > /etc/group'
    )
goto :eof


:config_syslogd
    sc query syslogd | findstr "service does not exist" > NUL:
    if %ERRORLEVEL% NEQ 0 goto :eof

    echo %_PREFIX% Configuring syslogd
    if not exist %_ROOTDIR%\bin\syslogd-config (
        echo %_PREFIX% ERROR: inetutils not installed
        goto :eof
    )
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/syslogd-config"
goto :eof


:config_sshd
    sc query sshd | findstr "service does not exist" > NUL:
    if %ERRORLEVEL% NEQ 0 goto :eof

    echo %_PREFIX% Configuring sshd
    if not exist %_ROOTDIR%\bin\ssh-host-config (
        echo %_PREFIX% ERROR: opensshd not installed
        goto :eof
    )
    findstr /r "^sshd:" %_ROOTDIR%\etc\passwd
    if %ERRORLEVEL% EQU 0 (
        echo %_PREFIX% ERROR: sshd account found in /etc/passwd
        goto :eof
    )
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/ssh-host-config"
    echo %_PREFIX% Disabling reverse DNS lookup by sshd
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/sshd_config"
goto :eof


:config_lsa
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if %ERRORLEVEL% EQU 0 goto :eof

    echo %_PREFIX% Configuring cyglsa
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/cyglsa-config"
goto :eof


:main
    call :check_admin ||exit /b 1
    call :get_setup_exe
    call :stop_services
    call :setup
    call :create_passwd
    call :config_syslogd
    call :config_sshd
    call :start_services
    rem Do config_lsa last so that reboot message is last
    call :config_lsa
:exit
