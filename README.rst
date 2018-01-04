MyAppData
=========

Windows dotfiles.

Usage
-----

Initial checkout::

    cd %AppData%
    git clone git@github.com:tschutter/MyAppData.git
    MyAppData\bin\windows_config

Update::

    cd %AppData%\MyAppData
    git pull
    windows_config

To create a distribution zipfile on Linux for use on Windows machines
without git::

    cd MyAppData/..
    zip -r /tmp/MyAppData.zip MyAppData --exclude .git\*

TODO
----

* Win7 do not merge toolbar icons.

* Do not hide unused tooltray icons.
