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

:get_admin
    rem Ensure ADMIN privileges
    rem Adaptation of http://stackoverflow.com/q/4054937 and
    rem https://sites.google.com/site/eneerge/home/BatchGotAdmin

    rem Check for ADMIN privileges
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
    if "%ERRORLEVEL%" NEQ "0" (
        rem Get ADMIN privileges
        echo set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\getadmin.vbs"
        echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
        echo %_PREFIX% Relaunching to get elevated privileges
        "%TEMP%\getadmin.vbs"
        del "%TEMP%\getadmin.vbs"
        exit /B
    )
goto :eof

:stop_services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do (
        echo %_PREFIX% Stopping %%s
        %_ROOTDIR%\bin\cygrunsrv --stop %%s
    )
goto :eof

:start_services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do (
        echo %_PREFIX% Starting %%s
        %_ROOTDIR%\bin\cygrunsrv --start %%s
    )
goto :eof

:get_setup_exe
    if not exist %_ROOTDIR% (
        echo %_PREFIX% Creating %_ROOTDIR%
        mkdir %_ROOTDIR%
    )
    echo %_PREFIX% Fetching latest setup.exe
    wget --quiet -O %_ROOTDIR%\setup.exe http://cygwin.com/setup.exe
goto :eof

:setup
    echo %_PREFIX% Running setup.exe
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

:config_sshd
    sc query sshd | findstr "service does not exist" > NUL:
    if %ERRORLEVEL% NEQ 0 goto :eof
    echo %_PREFIX% Configuring sshd
    if not exist %_ROOTDIR%\bin\ssh-host-config (
        echo %_PREFIX% WARNING: opensshd not installed
        goto :eof
    )
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/ssh-host-config"
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/sshd_config"
    rem%_ROOTDIR%\bin\bash --login -i -c "/usr/bin/chown fdsv-sa-prx-sshdsrvr /etc/ssh* /var/empty /var/log/lastlog"
goto :eof

:config_lsa
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if %ERRORLEVEL% EQU 0 goto :eof
    echo %_PREFIX% Configuring cyglsa
    echo %_PREFIX% WARNING: need administrator priv here
    rem %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/cyglsa-config"
goto :eof

:main
    call :get_admin
    call :get_setup_exe
    call :stop_services
    call :setup
    call :create_passwd
    call :config_sshd
    call :start_services
    call :config_lsa
    pause