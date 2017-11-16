rem cygwin_setup.bat configuration.

rem Select 32-bit or 64-bit installer.
set _SETUP_EXE=setup-x86_64.exe

rem Package list.
set _PACKAGES=bc,cron,diffutils,dos2unix,git,nc,ncurses,openssh,p7zip,python2-pip,python3-pip,procps,python,python3,rsync,screen,ssmtp,syslog-ng,tmux,unzip,vim,w3m,wget,zip

rem Root directory of installation.
set _ROOTDIR=C:\cygwin64

rem Mirror site.
set _SITE=http://mirrors.kernel.org/sourceware/cygwin

rem Enable logging of sshd and it's ilk to /var/log.
set _CONFIG_SYSLOG_NG=True

rem Enable OpenSSH server.
set _CONFIG_SSHD=True

rem Enable cron daemon.
set _CONFIG_CRON=True

rem Enable LSA authentication.
rem See http://cygwin.com/cygwin-ug-net/ntsec.html
set _CONFIG_LSA=True
