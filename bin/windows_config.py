#!/usr/bin/env python3

"""
Configure Windows settings via the registry.

Use Regshot to determine which registry keys to change.
"""

import ctypes
import argparse
import os
import sys

if sys.platform != "win32":
    print("Only for Windows (not Cygwin)")
    sys.exit(1)

import winreg

# pylint: disable=line-too-long

#
# Registry paths are frequently > 80 chars.
# pylint: disable=C0302
#
# See http://msdn.microsoft.com/en-us/library/ms724833(VS.85).aspx for
# windowsversion info.
# 6.2 Windows 8
# 6.2 Windows Server 2012
# 6.1 Windows 7
# 6.1 Windows Server 2008 R2
# 6.0 Windows Server 2008
# 6.0 Windows Vista
# 5.2 Windows Server 2003
# 5.1 Windows XP
# 5.0 Windows 2000
#


class Reg():
    """Registry access class."""

    def __init__(self, args):
        self.args = args
        self.created_keys = list()

    @staticmethod
    def hive_key(hive_name):
        """Return the key constant for a hive_name."""
        hive_keys = {
            "HKCR": winreg.HKEY_CLASSES_ROOT,
            "HKCU": winreg.HKEY_CURRENT_USER,
            "HKLM": winreg.HKEY_LOCAL_MACHINE
        }
        return hive_keys[hive_name]

    @staticmethod
    def enum_subkeys(key_path):
        """Generate the names of all subkeys."""

        # Split key_path into hive_name, sub_key.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:])

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = winreg.OpenKey(root_key, sub_key)
        except WindowsError:
            raise StopIteration

        index = 0
        while True:
            try:
                yield winreg.EnumKey(key, index)
            except WindowsError:
                break
            index += 1

    def delete_key(self, key_path):
        """Delete a specified key."""

        # Split key_path into hive_name, sub_key.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:])
        key_name = f"{hive_name}\\{sub_key}"

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = winreg.OpenKey(root_key, sub_key, 0, winreg.KEY_ALL_ACCESS)
        except WindowsError:
            return

        # Close the key.
        winreg.CloseKey(key)

        # Delete the key.
        if self.args.verbose:
            print(f"DeleteKey({key_name})")
        if not self.args.dryrun:
            winreg.DeleteKey(root_key, sub_key)

    def delete_value(self, key_path):
        """Delete a value associated with a specified key."""

        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
        key_name = f"{hive_name}\\{sub_key}"
        value_name = key_path[-1]

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = winreg.OpenKey(root_key, sub_key, 0, winreg.KEY_ALL_ACCESS)
        except WindowsError:
            return

        # Attempt to get the current value.
        try:
            winreg.QueryValueEx(key, value_name)
        except WindowsError:
            return

        # Delete the value.
        if self.args.verbose:
            print(f"DeleteValue({key_name}\\{value_name}")
        if not self.args.dryrun:
            winreg.DeleteValue(key, value_name)

        # Close the key.
        winreg.CloseKey(key)

    @staticmethod
    def get_value(key_path):
        """Return a value associated with a specified key."""

        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
        value_name = key_path[-1]

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = winreg.OpenKey(root_key, sub_key, 0, winreg.KEY_READ)
        except WindowsError:
            return None

        # Attempt to get the current value.
        try:
            value, _ = winreg.QueryValueEx(key, value_name)
        except WindowsError:
            value = None

        # Close the key.
        winreg.CloseKey(key)

        return value

    def set_value(self, key_path, vtype, value, create_key=None):
        """Associate a string value with a specified key."""

        # pylint: disable=too-many-branches

        if create_key is None:
            create_key = False

        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
        key_name = f"{hive_name}\\{sub_key}"
        value_name = key_path[-1]

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = winreg.OpenKey(root_key, sub_key, 0, winreg.KEY_ALL_ACCESS)
        except WindowsError:
            if not create_key:
                return False
            if self.args.verbose:
                if key_name not in self.created_keys:
                    print(f"CreateKey({key_name}")
                    self.created_keys.append(key_name)
                key = None
            if not self.args.dryrun:
                key = winreg.CreateKey(root_key, sub_key)

        # Attempt to get the current value.
        if key is None:
            orig_value = None
        else:
            try:
                orig_value, _ = winreg.QueryValueEx(key, value_name)
            except WindowsError:
                orig_value = None

        # Set the value if it is different.
        changed = value != orig_value
        if changed:
            if self.args.verbose:
                if vtype == winreg.REG_DWORD:
                    value_format = "{:#010x}"
                else:
                    value_format = "{}"
                value_str = value_format.format(value)
                if orig_value is None:
                    orig_value_str = None
                else:
                    orig_value_str = value_format.format(orig_value)
                print(
                    f"SetValue({key_name}\\{value_name}, {value_str})"
                    f" was {orig_value_str}"
                )
            if not self.args.dryrun:
                winreg.SetValueEx(
                    key,
                    value_name,
                    0,
                    vtype,
                    value
                )

        # Close the key.
        winreg.CloseKey(key)

        return changed

    def set_value_dword(self, key_path, value, create_key=None):
        """Set a REG_DWORD value."""
        return self.set_value(
            key_path,
            winreg.REG_DWORD,
            int(value),
            create_key
        )

    def set_value_str(self, key_path, value, create_key=None):
        """Set a REG_SZ value."""
        return self.set_value(
            key_path,
            winreg.REG_SZ,
            str(value),
            create_key
        )

    def set_value_expand_str(self, key_path, value, create_key=None):
        """Set a REG_EXPAND_SZ value."""
        return self.set_value(
            key_path,
            winreg.REG_EXPAND_SZ,
            str(value),
            create_key
        )


def notify_explorer(message=None):
    """Notify explorer.exe that something changed."""
    # Constants from WinUser.h
    _hwnd_broadcast = 0xFFFF
    _wm_settingchange = 0x001A
    _smto_abortifhung = 0x0002
    result = ctypes.c_ulong()  # DWORD
    ctypes.windll.user32.SendMessageTimeoutA(
        _hwnd_broadcast,
        _wm_settingchange,
        0,
        message,
        _smto_abortifhung,
        2000,
        ctypes.byref(result)
    )


def add_bin_dir_to_user_path(reg, bin_dir):
    """Add bin directory to user PATH."""

    # Get the current user PATH.
    key_path = r"HKCU\Environment\PATH"
    path = reg.get_value(key_path)
    if path is None:
        path_components = list()
    else:
        path_components = path.split(";")

    # Check to see if the new path component is already in the existing PATH.
    for component in path_components:
        if component.lower() == bin_dir.lower():
            return

    # Add the new path component and put it back in the registry.
    path_components.insert(0, bin_dir)
    path = ";".join(path_components)
    reg.set_value_expand_str(key_path, path, create_key=True)

    # Notify explorer.exe of the environment change so that it will
    # reload it's copy of the environment.  That way newly launched
    # shells will see the change.
    notify_explorer("Environment")


def console_colors(reg):
    """Set black on white in command prompt."""

    # Second lowest byte is background color, lowest byte is foreground color.
    reg.set_value_dword(r"HKCU\Console\ScreenColors", 0x000000f0)


def console_quickedit(reg):
    """Enable "QuickEdit Mode" in command prompt."""

    reg.set_value_dword(r"HKCU\Console\QuickEdit", 1)


def console_layout(reg):
    """Set windows size of command prompt."""

    # High word is number of lines, low word is number of columns.
    reg.set_value_dword(r"HKCU\Console\ScreenBufferSize", 0x0c000080)
    reg.set_value_dword(r"HKCU\Console\WindowSize", 0x00370080)


def hide_cyg_server_login(reg):
    """Hide "Privileged server" account from login screen on Vista and later."""

    if sys.getwindowsversion() >= (6, 0):
        reg.set_value_dword(
            r"HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList\cyg_server",
            0,
            create_key=True
        )


def no_hide_known_file_extensions(reg):
    """Disable "Hide known file extensions" in Windows Explorer."""

    reg.set_value_dword(
        r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt",
        0
    )


def no_language_bar(reg):
    """Disable the language bar."""

    reg.set_value_dword(
        r"HKCU\Software\Microsoft\CTF\LangBar\ShowStatus",
        3
    )
    reg.delete_value(
        r"HKCR\CLSID\{540D8A8B-1C3F-4E32-8132-530F6A502090}\MenuTextPUI"
    )
    reg.set_value_dword(
        r"HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer",
        0
    )


def no_recycle_bin(reg):
    """Disable the recycle bin."""

    changed = False

    explorer = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"

    # Do not move files to the recycle bin.
    if sys.getwindowsversion() >= (6, 0):
        volume_key = explorer + r"\BitBucket\Volume"
        for volume in reg.enum_subkeys(volume_key):
            changed |= reg.set_value_dword(
                volume_key + "\\" + volume + r"\NukeOnDelete",
                1,
                create_key=True
            )
    else:
        changed |= reg.set_value_dword(
            r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\NukeOnDelete",
            1
        )

    # Remove the recycle bin from the desktop.
    # XP style start menu.
    changed |= reg.set_value_dword(
        explorer + r"\HideDesktopIcons\NewStartPanel\{645FF040-5081-101B-9F08-00AA002F954E}",
        1,
        create_key=True
    )
    # Classic style start menu.
    changed |= reg.set_value_dword(
        explorer + r"\HideDesktopIcons\ClassicStartMenu\{645FF040-5081-101B-9F08-00AA002F954E}",
        1,
        create_key=True
    )

    if changed:
        # Not working for win7.
        notify_explorer()


def no_screen_saver(reg):
    """Disable the screen saver."""

    reg.set_value_str(r"HKCU\Control Panel\Desktop\ScreenSaveActive", "0")
    reg.delete_value(r"HKCU\Control Panel\Desktop\SCRNSAVE.EXE")

    desktop_policies = (
        r"HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
    )
    reg.set_value_str(desktop_policies + r"\ScreenSaveActive", "0")
    reg.delete_value(desktop_policies + r"\SCRNSAVE.EXE")
    reg.set_value_str(desktop_policies + r"\ScreenSaveTimeOut", "36000")


def no_shortcut_suffix(_reg):
    """
    Prevent addition of a " - Shortcut" suffix when creating a shortcut.

    In WinXP it was a "Shortcut to " prefix.
    """
    # explorer = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"
    # reg.set_value_dword(explorer + r"\link", 0)


def taskbar_config(reg):
    """Configure the taskbar."""

    changed = False
    windowsversion = sys.getwindowsversion()
    explorer = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"

    if windowsversion >= (6, 0):
        # never combine taskbar buttons
        changed |= reg.set_value_dword(
            explorer + r"\Advanced\TaskbarGlomLevel",
            2
        )

        # use small icons
        changed |= reg.set_value_dword(
            explorer + r"\Advanced\TaskbarSmallIcons",
            1
        )

    else:
        # do not group similar taskbar buttons
        changed |= reg.set_value_dword(
            explorer + r"\Advanced\TaskbarGlomming",
            0
        )

        # hide inactive icons does not seem to change registry

    # Tell explorer.exe to redraw taskbar.  Currently doesn't do the
    # EnableAutoTray, but a restart of explorer fixes that.
    if changed:
        notify_explorer()


def main():
    """Main."""

    # Determine this directory before anyone can chdir().
    bin_dir = os.path.dirname(os.path.abspath(__file__))

    # Parse command line args.
    arg_parser = argparse.ArgumentParser(
        description="Modify Windows to sane settings."
    )
    arg_parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        dest="dryrun",
        default=False,
        help="print commands that would be executed, but do not execute them"
    )
    arg_parser.add_argument(
        "-q",
        "--quiet",
        action="store_false",
        dest="verbose",
        default=True,
        help="print commands as they are executed"
    )
    args = arg_parser.parse_args()
    if args.dryrun:
        args.verbose = True

    if (
        sys.getwindowsversion() >= (6, 0) and not
        ctypes.windll.shell32.IsUserAnAdmin()
    ):
        print(
            "ERROR: This script requires elevated privileges."
            "  Run as Administrator."
        )
        return 1

    # Create a registry access object.
    reg = Reg(args)

    # Update the registry.
    add_bin_dir_to_user_path(reg, bin_dir)
    console_colors(reg)
    console_quickedit(reg)
    console_layout(reg)
    hide_cyg_server_login(reg)
    no_hide_known_file_extensions(reg)
    no_recycle_bin(reg)
    no_screen_saver(reg)
    no_shortcut_suffix(reg)
    taskbar_config(reg)

    # ; Setting the font in init.el is problematic because it triggers a
    # ; window resize, which usually pushes the window off of the screen.
    # [HKCU\SOFTWARE\GNU\Emacs]
    # "Emacs.Face.AttributeFont"="Consolas-11"
    # "Emacs.Geometry"="128x55"
    #
    # ; Disable the Shutdown Event Tracker.
    # ; KB Article(293814): Description of the Shutdown Event Tracker
    # ; http://support.microsoft.com/default.aspx?scid=kb;en-us;293814
    # [HKLM\Software\Microsoft\Windows\CurrentVersion\Reliability]
    # "ShutdownReasonUI"=dword:00000000
    #
    # ; Display status messages during startup and shutdown.
    # [HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
    # "verbosestatus"=dword:00000001

    # broken, does not work
    # no_language_bar(reg)

    return 0


if __name__ == "__main__":
    sys.exit(main())

# Local Variables:
# whitespace-line-column: 150
# End:
