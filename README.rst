AppData
=======

Windows dotfiles.

Usage
-----

Initial checkout::

    cd %AppData%
    git init
    git remote add origin https://github.com/tschutter/AppData.git
    git fetch
    git checkout --track origin/master
    bin\windows_config

Update::

    cd %AppData%
    git pull
    windows_config

To create a distribution zipfile on Linux::

    zip -r /tmp/AppData.zip . --exclude .git\*

TODO
----

* Win7 do not merge toolbar icons.

* Do not hide unused tooltray icons.
