====================
VBScript Programming
====================

Preamble
--------

    Option Explicit

When you use the Option Explicit statement, you must explicitly
declare all variables using the Dim, Private, Public, or ReDim
statements. If you attempt to use an undeclared variable name, an
error occurs. If used, the Option Explicit statement must appear in a
script before any procedures.

    On Error Resume Next

If present, then errors cause the Err object to be modified and
continue to the next line of the script.  Properties of the Err object
are Number, Source, and Description.

    On Error Goto 0

If present, disable error handling.
