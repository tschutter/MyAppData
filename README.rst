AppData
=======

Windows dotfiles.

Usage
-----
::

    cd %AppData%
    git init
    git remote add origin https://github.com/tschutter/AppData.git
    git fetch
    git branch master origin/master (probably optional)
    git checkout master
    git submodule update --init --recursive

To create a zipfile::

    zip -r /tmp/AppData.zip . --exclude .git\*
