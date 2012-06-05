#!/usr/bin/env python

"""
Installs files in tschutter/homefiles using symbolic links.
"""

# Registry paths are frequently > 80 chars.
# pylint: disable=C0302

import optparse
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


def no_screen_saver(reg):
    """Disable the screen saver."""
    reg.set_value_str(r"HKCU\Control Panel\Desktop\ScreenSaveActive", "0")
    reg.delete_value(r"HKCU\Control Panel\Desktop\SCRNSAVE.EXE")

    reg.set_value_str(
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaveActive",
        "0",
        create_key = False
    )
    reg.delete_value(
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop\SCRNSAVE.EXE"
    )
    reg.set_value_str(
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaveTimeOut",
        "36000",
        create_key = False
    )


def no_hide_known_file_extensions(reg):
    """Disable "Hide known file extensions" in Windows Explorer."""
    reg.set_value_dword(
        r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt",
        0
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
    no_hide_known_file_extensions(reg)
    no_screen_saver(reg)

    return 0


if __name__ == "__main__":
    sys.exit(main())
