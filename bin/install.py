#!/usr/bin/env python

"""
Installs files in tschutter/homefiles using symbolic links.
"""

# Registry paths are frequently > 80 chars.
# pylint: disable=C0302

import ctypes
import ctypes.wintypes
import optparse
import os
import sys

if sys.platform != "win32":
    print "Only for Windows"
    sys.exit(1)

import _winreg

class Reg():
    """Registry access class."""
    def __init__(self, options):
        self.options = options
        self.created_keys = list()

    @staticmethod
    def hive_key(hive_name):
        """Return the key constant for a hive_name."""
        hive_keys = {
            "HKCU": _winreg.HKEY_CURRENT_USER,
            "HKLM": _winreg.HKEY_LOCAL_MACHINE
        }
        return hive_keys[hive_name]

    def delete_value(self, key_path):
        """Deletes a value associated, with a specified key."""

        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
        key_name = r"%s\%s" % (hive_name, sub_key)
        value_name = key_path[-1]

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = _winreg.OpenKey(root_key, sub_key, 0, _winreg.KEY_ALL_ACCESS)
        except WindowsError:
            return

        # Attempt to get the current value.
        try:
            _winreg.QueryValueEx(key, value_name)
        except WindowsError:
            return

        # Delete the value.
        if self.options.verbose:
            print "DeleteValue(%s\\%s)" % (key_name, value_name)
        if not self.options.dryrun:
            _winreg.DeleteValue(key, value_name)

        # Close the key.
        _winreg.CloseKey(key)

    def get_value(self, key_path):
        """Returns a value associated with a specified key."""
        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
        key_name = r"%s\%s" % (hive_name, sub_key)
        value_name = key_path[-1]

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = _winreg.OpenKey(root_key, sub_key, 0, _winreg.KEY_READ)
        except WindowsError:
            return None

        # Attempt to get the current value.
        try:
            value, _ = _winreg.QueryValueEx(key, value_name)
        except WindowsError:
            value = None

        # Close the key.
        _winreg.CloseKey(key)

        return value

    def set_value(self, key_path, vtype, value, create_key=None):
        """Associates a string value with a specified key."""
        if create_key == None:
            create_key = False

        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
        key_name = r"%s\%s" % (hive_name, sub_key)
        value_name = key_path[-1]

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = _winreg.OpenKey(root_key, sub_key, 0, _winreg.KEY_ALL_ACCESS)
        except WindowsError:
            if not create_key:
                return
            if self.options.verbose:
                if key_name not in self.created_keys:
                    print "CreateKey(%s)" % key_name
                    self.created_keys.append(key_name)
                key = None
            if not self.options.dryrun:
                key = _winreg.CreateKey(root_key, sub_key)

        # Attempt to get the current value.
        if key == None:
            orig_value = None
        else:
            try:
                orig_value, _ = _winreg.QueryValueEx(key, value_name)
            except WindowsError:
                orig_value = None

        # Set the value if it is different.
        if value != orig_value:
            if self.options.verbose:
                print "SetValue(%s\\%s, %s) was %s" % (
                    key_name,
                    value_name,
                    value,
                    orig_value
                )
            if not self.options.dryrun:
                _winreg.SetValueEx(
                    key,
                    value_name,
                    0,
                    vtype,
                    value
                )

        # Close the key.
        _winreg.CloseKey(key)

    def set_value_dword(self, key_path, value, create_key=None):
        self.set_value(key_path, _winreg.REG_DWORD, int(value), create_key)

    def set_value_str(self, key_path, value, create_key=None):
        self.set_value(key_path, _winreg.REG_SZ, str(value), create_key)

    def set_value_expand_str(self, key_path, value, create_key=None):
        self.set_value(key_path, _winreg.REG_EXPAND_SZ, str(value), create_key)


def add_appdata_bin_to_user_path(reg):
    """Add %AppData%/bin to user PATH."""
    # Get the current user PATH.
    key_path = r"HKCU\Environment\PATH"
    path = reg.get_value(key_path)
    if path == None:
        path_components = list()
    else:
        path_components = path.split(";")

    # Check to see if the new path component is already in the existing PATH.
    appdata_bin = os.path.join(os.environ["AppData"], "bin")
    for component in path_components:
        if component.lower() == appdata_bin.lower():
            return

    # Add the new path component and put it back in the registry.
    path_components.insert(0, appdata_bin)
    path = ";".join(path_components)
    reg.set_value_expand_str(key_path, path, create_key=True)

    # Notify explorer.exe of the environment change so that it will
    # reload it's copy of the environment.  That way newly launched
    # shells will see the change.
    # Constants from WinUser.h
    _HWND_BROADCAST = 0xFFFF
    _WM_SETTINGCHANGE = 0x001A
    _SMTO_ABORTIFHUNG = 0x0002
    result = ctypes.wintypes.DWORD()
    ctypes.windll.user32.SendMessageTimeoutA(
        _HWND_BROADCAST,
        _WM_SETTINGCHANGE,
        0,
        "Environment",
        _SMTO_ABORTIFHUNG,
        2000,
        ctypes.byref(result)
    )


def no_hide_known_file_extensions(reg):
    """Disable "Hide known file extensions" in Windows Explorer."""
    reg.set_value_dword(
        r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt",
        0
    )


def no_recycle_bin(reg):
    """Disable the recycle bin."""

    # Do not move files to the recycle bin.
    reg.set_value_dword(
        r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\NukeOnDelete",
        1
    )

    # Remove the recycle bin from the desktop.
    # XP style start menu.
    reg.set_value_dword(
        r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\{645FF040-5081-101B-9F08-00AA002F954E}",
        1,
        create_key = True
    )
    # Classic style start menu.
    reg.set_value_dword(
        r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu\{645FF040-5081-101B-9F08-00AA002F954E}",
        1,
        create_key = True
    )


def no_screen_saver(reg):
    """Disable the screen saver."""
    reg.set_value_str(r"HKCU\Control Panel\Desktop\ScreenSaveActive", "0")
    reg.delete_value(r"HKCU\Control Panel\Desktop\SCRNSAVE.EXE")

    reg.set_value_str(
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaveActive",
        "0"
    )
    reg.delete_value(
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop\SCRNSAVE.EXE"
    )
    reg.set_value_str(
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaveTimeOut",
        "36000"
    )


def main():
    """main"""

    # Parse command line options.
    option_parser = optparse.OptionParser(
        usage="usage: %prog [options]\n" +
            "  Modifies Windows registry to sane settings."
    )
    option_parser.add_option(
        "-n",
        "--dry-run",
        action="store_true",
        dest="dryrun",
        default=False,
        help="print commands that would be executed, but do not execute them"
    )
    option_parser.add_option(
        "-v",
        "--verbose",
        action="store_true",
        dest="verbose",
        default=False,
        help="print commands as they are executed"
    )
    (options, args) = option_parser.parse_args()
    if len(args) != 0:
        option_parser.error("invalid argument")
    if options.dryrun:
        options.verbose = True

    # Create a registry access object.
    reg = Reg(options)

    # Update the registry.
    add_appdata_bin_to_user_path(reg)
    no_hide_known_file_extensions(reg)
    no_recycle_bin(reg)
    no_screen_saver(reg)

    # ; Disable? the language bar.
    # [HKEY_CURRENT_USER\Software\Microsoft\CTF\LangBar]
    # "ShowStatus"=dword:00000003
    #
    # ; Prevent addition of "Shortcut to " prefix (WinXP) or " - Shortcut"
    # ; suffix (Vista) when creating a shortcut.
    # [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer]
    # "link"=hex:00,00,00,00
    #
    # ; Setting the font in init.el is problematic because it triggers a
    # ; window resize, which usually pushes the window off of the screen.
    # [HKEY_CURRENT_USER\SOFTWARE\GNU\Emacs]
    # "Emacs.Face.AttributeFont"="Consolas-11"
    # "Emacs.Geometry"="128x55"
    #
    # ; Disable the Shutdown Event Tracker.
    # ; KB Article(293814): Description of the Shutdown Event Tracker
    # ; http://support.microsoft.com/default.aspx?scid=kb;en-us;293814
    # [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Reliability]
    # "ShutdownReasonUI"=dword:00000000
    # ; Needs verification!
    #
    # ; Display status messages during startup and shutdown.
    # [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
    # "verbosestatus"=dword:00000001

    return 0


if __name__ == "__main__":
    sys.exit(main())
