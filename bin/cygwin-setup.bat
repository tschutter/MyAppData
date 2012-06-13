@echo off
rem
rem Install or update Cygwin.
rem

setlocal

set _PACKAGES=cron,diffutils,inetutils,ncurses,netcat,openssh,p7zip,procps,python,rsync,screen,unzip,vim,zip,genisoimage,w3m,wodim
set _ROOTDIR=C:\cygwin
set _SITE=http://mirrors.xmission.com/cygwin

goto :main

:stop_services
    sc query sshd | findstr STATE > NUL:
    set _SSHD=%ERRORLEVEL%
    if %_SSHD% EQU 0 sc stop sshd > NUL:

    sc query cron | findstr STATE > NUL:
    set _CRON=%ERRORLEVEL%
    if %_CRON% EQU 0 sc stop cron > NUL:

    sc query rsyncd | findstr STATE > NUL:
    set _RSYNCD=%ERRORLEVEL%
    if %_RSYNCD% EQU 0 sc stop rsyncd > NUL:
goto :eof

:start_services
    if %_RSYNCD% EQU 0 sc start rsyncd > NUL:
    if %_CRON% EQU 0 sc start cron > NUL:
    if %_SSHD% EQU 0 sc start sshd > NUL:
goto :eof

:get_setup_exe
    if not exist %_ROOTDIR% mkdir %_ROOTDIR%
    wget --quiet -O %_ROOTDIR%\setup.exe http://cygwin.com/setup.exe
goto :eof

:setup
    %_ROOTDIR%\setup.exe --site %_SITE% --quiet-mode --no-shortcuts --root %_ROOTDIR% --local-package-dir %_ROOTDIR%\LocalPackageDir %_PACKAGES%
goto :eof

:main
    call :get_setup_exe
    call :stop_services
    call :setup
    call :start_services

rem echo Creating passwd and group files...
rem C:\cygwin\bin\bash --login -i -c '/usr/bin/mkpasswd --local --domain ^> /etc/passwd'
rem C:\cygwin\bin\bash --login -i -c '/usr/bin/mkgroup --local --domain ^> /etc/group'
rem
rem echo Configuring cyglsa...
rem C:\cygwin\bin\bash --login -i -c "/usr/bin/cyglsa-config"
rem
rem echo Configuring sshd...
rem C:\cygwin\bin\bash --login -i -c "/usr/bin/ssh-host-config --yes"
rem C:\cygwin\bin\bash --login -i -c "/usr/bin/sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/sshd_config"
rem C:\cygwin\bin\bash --login -i -c "/usr/bin/chown fdsv-sa-prx-sshdsrvr /etc/ssh* /var/empty /var/log/lastlog"

endlocal
