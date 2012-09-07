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
    git branch master origin/master (probably optional)
    git checkout master
    git submodule update --init
    bin\windows_config

Update::

    cd %AppData%
    git pull
    git submodule update --init
    windows_config

To create a distribution zipfile on Linux::

    zip -r /tmp/AppData.zip . --exclude .git\*
