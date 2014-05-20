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
    git submodule update --init --recursive
    bin\windows_config

Update::

    cd %AppData%
    git pull
    git submodule update --init --recursive
    windows_config

To create a distribution zipfile on Linux::

    zip -r /tmp/AppData.zip . --exclude\
        .git\*\
        .emacs.d/.git\*\
        .emacs.d/elisp/yasnippet/.git\*\
        .emacs.d/elisp/yasnippet/extras/bundles/html-tmbundle/.git\*\
        .emacs.d/elisp/yasnippet/extras/bundles/rails-tmbundle/.git\*\
        .emacs.d/elisp/yasnippet/extras/bundles/ruby-tmbundle/.git\*

TODO
----

* Win7 do not merge toolbar icons.

* Do not hide unused tooltray icons.
