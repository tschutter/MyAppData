rem cygwin_setup.bat configuration.

rem Select 32-bit or 64-bit installer.
set _SETUP_EXE=setup-x86_64.exe

rem Package list.
set _PACKAGES=cron,diffutils,git,inetutils,ncurses,netcat,openssh,p7zip,procps,python,python3,rsync,screen,unzip,vim,zip,w3m

rem Root directory of installation.
set _ROOTDIR=C:\cygwin

rem Mirror site.
set _SITE=http://mirrors.kernel.org/sourceware/cygwin

rem Enable logging of sshd and it's ilk to /var/log.
set _CONFIG_SYSLOGD=True

rem Enable OpenSSH server.
set _CONFIG_SSHD=True

rem Enable LSA authentication.
rem See http://cygwin.com/cygwin-ug-net/ntsec.html
set _CONFIG_LSA=True
