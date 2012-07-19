=========================
Windows Batch Programming
=========================

Terminate a windows batch file
------------------------------

Calling ``exit`` closes the command prompt.  Calling ``exit /b 1``
will exit the current function.  There is no command in between.  The
solution is to check the errorlevel after every function call using
this pattern::

    :func
        echo In func
        if something bad then exit /b 1
    goto :eof

    call :func || exit /b 1

See `How to to terminate a windows batch file from within a 'call'ed
routine?
<http://stackoverflow.com/questions/934030/how-to-to-terminate-a-windows-batch-file-from-within-a-called-routine>`__
