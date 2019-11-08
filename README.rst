MyAppData
=========

Windows dotfiles.

Usage
-----

Initial checkout::

    cd %LOCALAPPDATA%
    git clone git@github.com:tschutter/MyAppData.git
    MyAppData\bin\windows_config

Update::

    cd %LOCALAPPDATA%\MyAppData
    git pull
    windows_config

To create a distribution zipfile on Linux for use on Windows machines
without git::

    cd MyAppData/..
    zip -r /tmp/MyAppData.zip MyAppData --exclude .git\*
