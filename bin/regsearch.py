#
# Copyright (c) 2009-2012 Tom Schutter
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#    - Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    - Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

"""
Search Windows registry keys, values, and data for a particular string.
"""

import _winreg
import optparse
import sys

# Hive name -> hive handle map
HIVE_ABBR = {
    "HKCR": _winreg.HKEY_CLASSES_ROOT,
    "HKCU": _winreg.HKEY_CURRENT_USER,
    "HKLM": _winreg.HKEY_LOCAL_MACHINE,
    "HKU": _winreg.HKEY_USERS,
    "HKCC": _winreg.HKEY_CURRENT_CONFIG,
    "HKDD": _winreg.HKEY_DYN_DATA,
    "HKEY_CLASSES_ROOT": _winreg.HKEY_CLASSES_ROOT,
    "HKEY_CURRENT_USER": _winreg.HKEY_CURRENT_USER,
    "HKEY_LOCAL_MACHINE": _winreg.HKEY_LOCAL_MACHINE,
    "HKEY_USERS": _winreg.HKEY_USERS,
    "HKEY_CURRENT_CONFIG": _winreg.HKEY_CURRENT_CONFIG,
    "HKEY_DYN_DATA": _winreg.HKEY_DYN_DATA
}

# Hive handle -> hive name map
HIVE_NAME = {
    _winreg.HKEY_CLASSES_ROOT: "HKEY_CLASSES_ROOT",
    _winreg.HKEY_CURRENT_USER: "HKEY_CURRENT_USER",
    _winreg.HKEY_LOCAL_MACHINE: "HKEY_LOCAL_MACHINE",
    _winreg.HKEY_USERS: "HKEY_USERS",
    _winreg.HKEY_CURRENT_CONFIG: "HKEY_CURRENT_CONFIG",
    _winreg.HKEY_DYN_DATA: "HKEY_DYN_DATA"
}


def registry_value_to_string(value, value_type):
    """Convert a registry value to a string."""
    if value_type == _winreg.REG_SZ:
        return value

    if value_type == _winreg.REG_EXPAND_SZ:
        return value

    if value_type == _winreg.REG_DWORD:
        return ("%d" % value)

    if value_type == _winreg.REG_DWORD_LITTLE_ENDIAN:
        r = 0
        s = 0
        for ch in value:
            r |= (ord(ch) << s)
            s += 8

        return ("%d" % r)

    if value_type == _winreg.REG_DWORD_BIG_ENDIAN:
        r = 0
        s = 8 * 3
        for ch in value:
            r |= (ord(ch) << s)
            s -= 8

        return ("0x%08x" % r)

    if value_type == _winreg.REG_BINARY:
        r = ""
        for ch in value:
            r += ("%02x " % ord(ch))
        return r

    # punt:

    if value_type == _winreg.REG_LINK:
        return "<<REG_LINK>>"

    if value_type == _winreg.REG_MULTI_SZ:
        return "<<REG_MULTI_SZ>>"

    if value_type == _winreg.REG_RESOURCE_LIST:
        return "<<REG_RESOURCE_LIST>>"

    if value_type == _winreg.REG_FULL_RESOURCE_DESCRIPTOR:
        return "<<REG_FULL_RESOURCE_DESCRIPTOR>>"

    return "Unknown"


def search(options, key_name_stack, key, key_name, search_string):
    """Search a subtree."""
    key_name_stack.append(key_name)

    if options.search_keys:
        if options.ignoreCase:
            key_name = key_name.lower()
        if key_name.find(search_string) != -1:
            print "\\".join(key_name_stack)

    if options.search_values or options.search_data:
        for loop in xrange(sys.maxint):
            try:
                value_name, value_data, value_type = _winreg.EnumValue(
                  key,
                  loop
                )
                value_data = registry_value_to_string(value_data, value_type)
                found = False

                if options.search_values:
                    if options.ignoreCase:
                        value_name = value_name.lower()
                    if value_name.find(search_string) != -1:
                        found = True

                if options.search_data:
                    if options.ignoreCase:
                        value_data = value_data.lower()
                    if value_data.find(search_string) != -1:
                        found = True

                if found:
                    if options.key_values_with_matches:
                        print "\\".join(key_name_stack) + "\\" + value_name
                    else:
                        print "\\".join(key_name_stack) + "\\" + value_name + \
                              " = " + value_data
            except Exception:
                break

    for loop in xrange(sys.maxint):
        try:
            subkey_name = _winreg.EnumKey(key, loop)
        except Exception:
            break

        try:
            subkey = _winreg.OpenKey(key, subkey_name)
            search(options, [], subkey, subkey_name, search_string)
        except Exception:
            pass

        try:
            _winreg.CloseKey(subkey)
        except Exception:
            pass

    key_name_stack.pop()


def search_root(options, root, search_string):
    """Search beginning at a hive root."""
    search(options, [], root, HIVE_NAME[root], search_string)


def main():
    """main"""
    option_parser = optparse.OptionParser(
        usage="usage: %prog [options] PATTERN [STARTKEY]\n" +
        "  If none of -k, -v, -d is specified, then all will be searched.\n" +
        "  STARTKEY must begin with HKCR, HKCU, HKLM, HKU, HKCC, or HKDD."
    )
    option_parser.add_option(
        "-i",
        "--ignore-case",
        action="store_true",
        dest="ignoreCase",
        default=False,
        help="ignore case"
    )
    option_parser.add_option(
        "-k",
        "--search-keys",
        action="store_true",
        dest="search_keys",
        default=False,
        help="search keys"
    )
    option_parser.add_option(
        "-v",
        "--search-values",
        action="store_true",
        dest="search_values",
        default=False,
        help="search values"
    )
    option_parser.add_option(
        "-d",
        "--search-data",
        action="store_true",
        dest="search_data",
        default=False,
        help="search data"
    )
    option_parser.add_option(
        "-l",
        "--key-values-with-matches",
        action="store_true",
        dest="key_values_with_matches",
        default=False,
        help="print matching key/value, do not print data"
    )

    (options, args) = option_parser.parse_args()

    # If no search flag is specified, search everything.
    if not (
        options.search_keys or options.search_values or options.search_data
    ):
        options.search_keys = True
        options.search_values = True
        options.search_data = True

    # Check the number of arguments.
    if len(args) == 0:
        option_parser.error("PATTERN not specified")
        return 1
    elif len(args) > 2:
        option_parser.error("unknown argument")
        return 1

    # Get the search pattern.
    search_string = args[0]
    if options.ignoreCase:
        search_string = search_string.lower()

    if len(args) == 1:
        search_root(options, _winreg.HKEY_CLASSES_ROOT, search_string)
        search_root(options, _winreg.HKEY_CURRENT_USER, search_string)
        search_root(options, _winreg.HKEY_LOCAL_MACHINE, search_string)
        search_root(options, _winreg.HKEY_USERS, search_string)
        search_root(options, _winreg.HKEY_CURRENT_CONFIG, search_string)
        search_root(options, _winreg.HKEY_DYN_DATA, search_string)

    else:
        # Split the keyname at the first \
        hkey_and_subkey = args[1].split("\\", 1)

        # Map the hive name to a hive handle
        try:
            root = HIVE_ABBR[hkey_and_subkey[0]]
        except Exception:
            option_parser.error(
                "unknown HKEY, use HKCR, HKCU, HKLM, HKU, HKCC, or HKDD"
            )
            return 1

        if len(hkey_and_subkey) == 2:
            try:
                key = _winreg.OpenKey(root, hkey_and_subkey[1])
                search(options, [], key, sys.argv[2], search_string)
                _winreg.CloseKey(key)
            except Exception:
                # Be quiet if the starting key does not exist
                return 0

        else:
            search_root(options, root, search_string)

    return 0


if __name__ == "__main__":
    sys.exit(main())
