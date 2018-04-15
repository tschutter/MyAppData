@echo off
rem
rem Print date/time in ISO 8601 format.
rem

rem Inspired by https://stackoverflow.com/questions/3472631 aschipfl
rem
rem There are two nested for /F loops to work around an issue with the
rem wmic command, whose output is in unicode format; using a single loop
rem results in additional carriage-return characters which impacts proper
rem variable expansion.
rem
rem Since day and month may also consist of a single digit only, we
rem prepend a leading zero 0 in the loop construct. Afterwards, the
rem values are trimmed to always consist of two digits.
rem
rem wmic puts columns in alphabetic order, not requested order

for /F "skip=1 delims=" %%F in ('
    wmic PATH Win32_LocalTime GET Day^,Hour^,^Minute^,Month^,Year /FORMAT:TABLE
') do (
    for /F "tokens=1-5" %%L in ("%%F") do (
        set _DAY=0%%L
        set _HOUR=0%%M
        set _MINUTE=0%%N
        set _MONTH=0%%O
        set _YEAR=%%P
    )
)
set _MONTH=%_MONTH:~-2%
set _DAY=%_DAY:~-2%
set _HOUR=%_HOUR:~-2%
set _MINUTE=%_MINUTE:~-2%
set _DATETIME=%_YEAR%-%_MONTH%-%_DAY%T%_HOUR%:%_MINUTE%

echo %_DATETIME%
