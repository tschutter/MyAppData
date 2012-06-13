@echo off
rem
rem Install or update Cygwin.
rem

setlocal

set _PACKAGES=cron,diffutils,inetutils,ncurses,netcat,openssh,p7zip,procps,python,rsync,screen,unzip,vim,zip,genisoimage,w3m,wodim
set _ROOTDIR=C:\cygwin
set _SITE=http://mirrors.xmission.com/cygwin

goto :main

:stop_service
    echo Stopping %1
    sc stop %1 > NUL:
goto :eof

:start_service
    echo Starting %1
    sc start %1 > NUL:
goto :eof

:stop_services
    sc query sshd | findstr STATE > NUL:
    set _SSHD=%ERRORLEVEL%
    if %_SSHD% EQU 0 call :stop_service sshd

    sc query cron | findstr STATE > NUL:
    set _CRON=%ERRORLEVEL%
    if %_CRON% EQU 0 call :stop_service cron

    sc query rsyncd | findstr STATE > NUL:
    set _RSYNCD=%ERRORLEVEL%
    if %_RSYNCD% EQU 0 call :stop_service rsyncd
goto :eof

:start_services
    if %_RSYNCD% EQU 0 call :start_service rsyncd
    if %_CRON% EQU 0 call :start_service cron
    if %_SSHD% EQU 0 call :start_service sshd
goto :eof

:get_setup_exe
    if not exist %_ROOTDIR% (
        echo Creating %_ROOTDIR%
        mkdir %_ROOTDIR%
    )
    echo Fetching latest setup.exe
    wget --quiet -O %_ROOTDIR%\setup.exe http://cygwin.com/setup.exe
goto :eof

:setup
    echo Running setup.exe
    %_ROOTDIR%\setup.exe --site %_SITE% --quiet-mode --no-shortcuts --root %_ROOTDIR% --local-package-dir %_ROOTDIR%\LocalPackageDir %_PACKAGES%
goto :eof

:create_passwd
    rem echo Creating passwd and group files
    rem C:\cygwin\bin\bash --login -i -c '/usr/bin/mkpasswd --local --domain ^> /etc/passwd'
    rem C:\cygwin\bin\bash --login -i -c '/usr/bin/mkgroup --local --domain ^> /etc/group'
goto :eof

:config_lsa
    rem echo Configuring cyglsa
    rem C:\cygwin\bin\bash --login -i -c "/usr/bin/cyglsa-config"
goto :eof

:config_sshd
    sc query sshd | findstr "service does not exist" > NUL:
    if %ERRORLEVEL% NEQ 0 goto :eof
    echo Configuring sshd
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/ssh-host-config --yes"
    %_ROOTDIR%\bin\bash --login -i -c "/usr/bin/sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/sshd_config"
    rem%_ROOTDIR%\bin\bash --login -i -c "/usr/bin/chown fdsv-sa-prx-sshdsrvr /etc/ssh* /var/empty /var/log/lastlog"
goto :eof

:main
    call :get_setup_exe
    call :stop_services
    call :setup
    call :start_services
    call :create_passwd
    call :config_lsa
    call :config_sshd

endlocal
