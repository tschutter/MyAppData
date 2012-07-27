#!/usr/bin/env python

"""
Configure Windows settings via the registry.
"""

import ctypes
import optparse
import os
import sys

if sys.platform != "win32":
    print "Only for Windows (not Cygwin)"
    sys.exit(1)

import _winreg
import ctypes.wintypes

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
    def __init__(self, options):
        self.options = options
        self.created_keys = list()

    @staticmethod
    def hive_key(hive_name):
        """Return the key constant for a hive_name."""
        hive_keys = {
            "HKCR": _winreg.HKEY_CLASSES_ROOT,
            "HKCU": _winreg.HKEY_CURRENT_USER,
            "HKLM": _winreg.HKEY_LOCAL_MACHINE
        }
        return hive_keys[hive_name]

    @staticmethod
    def enum_subkeys(key_path):
        """Generator that yields the names of all subkeys."""

        # Split key_path into hive_name, sub_key.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:])

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = _winreg.OpenKey(root_key, sub_key)
        except WindowsError:
            raise StopIteration

        index = 0
        while True:
            try:
                yield _winreg.EnumKey(key, index)
            except WindowsError, details:
                if details[0] == 259:
                    raise StopIteration
                raise
            index += 1

    def delete_key(self, key_path):
        """Deletes a specified key."""

        # Split key_path into hive_name, sub_key.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:])
        key_name = r"%s\%s" % (hive_name, sub_key)

        # Determine the root_key constant.
        root_key = Reg.hive_key(hive_name)

        # Attempt to open the key.
        try:
            key = _winreg.OpenKey(root_key, sub_key, 0, _winreg.KEY_ALL_ACCESS)
        except WindowsError:
            return

        # Close the key.
        _winreg.CloseKey(key)

        # Delete the key.
        if self.options.verbose:
            print "DeleteKey(%s)" % (key_name)
        if not self.options.dryrun:
            _winreg.DeleteKey(root_key, sub_key)

    def delete_value(self, key_path):
        """Deletes a value associated with a specified key."""

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

    @staticmethod
    def get_value(key_path):
        """Returns a value associated with a specified key."""
        # Split key_path into hive_name, sub_key, value_name.
        key_path = key_path.split("\\")
        hive_name = key_path[0]
        sub_key = "\\".join(key_path[1:-1])
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
                return False
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
        changed = value != orig_value
        if changed:
            if self.options.verbose:
                if vtype == _winreg.REG_DWORD:
                    value_format = "%#08x"
                else:
                    value_format = "%s"
                if orig_value == None:
                    orig_value_str = None
                else:
                    orig_value_str = value_format % orig_value
                print ("SetValue(%s\\%s, " + value_format + ") was %s") % (
                    key_name,
                    value_name,
                    value,
                    orig_value_str
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

        return changed

    def set_value_dword(self, key_path, value, create_key=None):
        """Set a REG_DWORD value."""
        return self.set_value(
            key_path,
            _winreg.REG_DWORD,
            int(value),
            create_key
        )

    def set_value_str(self, key_path, value, create_key=None):
        """Set a REG_SZ value."""
        return self.set_value(
            key_path,
            _winreg.REG_SZ,
            str(value),
            create_key
        )

    def set_value_expand_str(self, key_path, value, create_key=None):
        """Set a REG_EXPAND_SZ value."""
        return self.set_value(
            key_path,
            _winreg.REG_EXPAND_SZ,
            str(value),
            create_key
        )


def notify_explorer(message=None):
    """Notify explorer.exe that something changed."""
    # Constants from WinUser.h
    _HWND_BROADCAST = 0xFFFF
    _WM_SETTINGCHANGE = 0x001A
    _SMTO_ABORTIFHUNG = 0x0002
    result = ctypes.wintypes.DWORD()
    ctypes.windll.user32.SendMessageTimeoutA(
        _HWND_BROADCAST,
        _WM_SETTINGCHANGE,
        0,
        message,
        _SMTO_ABORTIFHUNG,
        2000,
        ctypes.byref(result)
    )


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
            changed |= reg.set_value_dword(volume_key + "\\" + volume + r"\NukeOnDelete", 1, create_key=True)
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


def no_shortcut_suffix(reg):
    """Prevent addition of a "Shortcut to " prefix (WinXP) or a
    " - Shortcut" suffix (Vista) when creating a shortcut."""
    #explorer = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"
    #reg.set_value_dword(explorer + r"\link", 0)


def taskbar_config(reg):
    """Configure taskbar."""
    changed = False
    windowsversion = sys.getwindowsversion()
    explorer = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"

    if windowsversion >= (6, 0):
        # always show all icons and notifications on the taskbar
        changed |= reg.set_value_dword(explorer + r"\EnableAutoTray", 0)

        # never combine taskbar buttons
        changed |= reg.set_value_dword(explorer + r"\Advanced\TaskbarGlomLevel", 2)

        # use small icons
        changed |= reg.set_value_dword(explorer + r"\Advanced\TaskbarSmallIcons", 1)

    else:
        # do not group similar taskbar buttons
        changed |= reg.set_value_dword(explorer + r"\Advanced\TaskbarGlomming", 0)

        # hide inactive icons does not seem to change registry

    # Tell explorer.exe to redraw taskbar.  Currently doesn't do the
    # EnableAutoTray, but a restart of explorer fixes that.
    if changed:
        notify_explorer()


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
        "-q",
        "--quiet",
        action="store_false",
        dest="verbose",
        default=True,
        help="print commands as they are executed"
    )
    (options, args) = option_parser.parse_args()
    if len(args) != 0:
        option_parser.error("invalid argument")
    if options.dryrun:
        options.verbose = True

    if sys.getwindowsversion() >= (6, 0) and not ctypes.windll.shell32.IsUserAnAdmin():
        print "ERROR: This script requires elevated privileges.  Run as Administrator."
        return 1

    # Create a registry access object.
    reg = Reg(options)

    # Update the registry.
    add_appdata_bin_to_user_path(reg)
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
    # [HKEY_CURRENT_USER\SOFTWARE\GNU\Emacs]
    # "Emacs.Face.AttributeFont"="Consolas-11"
    # "Emacs.Geometry"="128x55"
    #
    # ; Disable the Shutdown Event Tracker.
    # ; KB Article(293814): Description of the Shutdown Event Tracker
    # ; http://support.microsoft.com/default.aspx?scid=kb;en-us;293814
    # [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Reliability]
    # "ShutdownReasonUI"=dword:00000000
    #
    # ; Display status messages during startup and shutdown.
    # [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
    # "verbosestatus"=dword:00000001

    # broken, does not work
    #no_language_bar(reg)

    return 0


if __name__ == "__main__":
    sys.exit(main())

# Local Variables:
# whitespace-line-column: 150
# End:
