#!/usr/bin/env python3

"""Search Windows registry keys, values, and data for a particular string."""

import argparse
import sys

import winreg

# Hive name -> hive handle map
HIVE_ABBR = {
    "HKCR": winreg.HKEY_CLASSES_ROOT,
    "HKCU": winreg.HKEY_CURRENT_USER,
    "HKLM": winreg.HKEY_LOCAL_MACHINE,
    "HKU": winreg.HKEY_USERS,
    "HKCC": winreg.HKEY_CURRENT_CONFIG,
    "HKDD": winreg.HKEY_DYN_DATA,
    "HKEY_CLASSES_ROOT": winreg.HKEY_CLASSES_ROOT,
    "HKEY_CURRENT_USER": winreg.HKEY_CURRENT_USER,
    "HKEY_LOCAL_MACHINE": winreg.HKEY_LOCAL_MACHINE,
    "HKEY_USERS": winreg.HKEY_USERS,
    "HKEY_CURRENT_CONFIG": winreg.HKEY_CURRENT_CONFIG,
    "HKEY_DYN_DATA": winreg.HKEY_DYN_DATA
}

# Hive handle -> hive name map
HIVE_NAME = {
    winreg.HKEY_CLASSES_ROOT: "HKEY_CLASSES_ROOT",
    winreg.HKEY_CURRENT_USER: "HKEY_CURRENT_USER",
    winreg.HKEY_LOCAL_MACHINE: "HKEY_LOCAL_MACHINE",
    winreg.HKEY_USERS: "HKEY_USERS",
    winreg.HKEY_CURRENT_CONFIG: "HKEY_CURRENT_CONFIG",
    winreg.HKEY_DYN_DATA: "HKEY_DYN_DATA"
}


def registry_value_to_string(value, value_type):
    """Convert a registry value to a string."""

    # pylint: disable=too-many-branches,too-many-return-statements

    if value_type == winreg.REG_SZ:
        return value

    if value_type == winreg.REG_EXPAND_SZ:
        return value

    if value_type == winreg.REG_DWORD:
        return f"{value}"

    if value_type == winreg.REG_DWORD_LITTLE_ENDIAN:
        result = 0
        shift = 0
        for char in value:
            result |= (ord(char) << shift)
            shift += 8

        return f"{result}"

    if value_type == winreg.REG_DWORD_BIG_ENDIAN:
        result = 0
        shift = 8 * 3
        for char in value:
            result |= (ord(char) << shift)
            shift -= 8

        return f"{result:#010x}"

    if value_type == winreg.REG_BINARY:
        result = ""
        for char in value:
            result += f"char:02x"
        return result

    # punt:

    if value_type == winreg.REG_LINK:
        return "<<REG_LINK>>"

    if value_type == winreg.REG_MULTI_SZ:
        return "<<REG_MULTI_SZ>>"

    if value_type == winreg.REG_RESOURCE_LIST:
        return "<<REG_RESOURCE_LIST>>"

    if value_type == winreg.REG_FULL_RESOURCE_DESCRIPTOR:
        return "<<REG_FULL_RESOURCE_DESCRIPTOR>>"

    return "Unknown"


def search(args, key_name_stack, key, key_name, pattern):
    """Search a subtree."""

    # pylint: disable=too-many-branches

    key_name_stack.append(key_name)

    if args.search_keys:
        if args.ignore_case:
            key_name = key_name.lower()
        if key_name.find(pattern) != -1:
            print("\\".join(key_name_stack))

    if args.search_values or args.search_data:
        for loop in range(sys.maxsize):
            try:
                value_name, value_data, value_type = winreg.EnumValue(
                    key,
                    loop
                )
                value_data = registry_value_to_string(value_data, value_type)
                found = False

                if args.search_values:
                    if args.ignore_case:
                        value_name = value_name.lower()
                    if value_name.find(pattern) != -1:
                        found = True

                if args.search_data:
                    if args.ignore_case:
                        value_data = value_data.lower()
                    if value_data.find(pattern) != -1:
                        found = True

                if found:
                    if args.key_values_with_matches:
                        print("\\".join(key_name_stack) + "\\" + value_name)
                    else:
                        print(
                            "\\".join(key_name_stack) + "\\" + value_name +
                            " = " + value_data
                        )
            except Exception:
                break

    for loop in range(sys.maxsize):
        try:
            subkey_name = winreg.EnumKey(key, loop)
        except WindowsError:
            break

        try:
            subkey = winreg.OpenKey(key, subkey_name)
            search(args, [], subkey, subkey_name, pattern)
        except Exception:
            pass

        try:
            winreg.CloseKey(subkey)
        except Exception:
            pass

    key_name_stack.pop()


def search_root(args, root, pattern):
    """Search beginning at a hive root."""
    search(args, [], root, HIVE_NAME[root], pattern)


def main():
    """Main."""

    arg_parser = argparse.ArgumentParser(
        description="Search the registry.",
        epilog="If none of -k, -v, -d is specified, then all will be searched."
    )
    arg_parser.add_argument(
        "-i",
        "--ignore-case",
        action="store_true",
        dest="ignore_case",
        default=False,
        help="ignore case"
    )
    arg_parser.add_argument(
        "-k",
        "--search-keys",
        action="store_true",
        dest="search_keys",
        default=False,
        help="search keys"
    )
    arg_parser.add_argument(
        "-v",
        "--search-values",
        action="store_true",
        dest="search_values",
        default=False,
        help="search values"
    )
    arg_parser.add_argument(
        "-d",
        "--search-data",
        action="store_true",
        dest="search_data",
        default=False,
        help="search data"
    )
    arg_parser.add_argument(
        "-l",
        "--key-values-with-matches",
        action="store_true",
        dest="key_values_with_matches",
        default=False,
        help="print matching key/value, do not print data"
    )
    arg_parser.add_argument(
        "pattern",
        help="string to search for"
    )
    arg_parser.add_argument(
        "startkey",
        nargs="?",
        default=None,
        help=(
            "tree to search in;"
            " must begin with HKCR, HKCU, HKLM, HKU, HKCC, or HKDD"
        )
    )

    args = arg_parser.parse_args()

    # If no search flag is specified, then search everything.
    if not (
        args.search_keys or args.search_values or args.search_data
    ):
        args.search_keys = True
        args.search_values = True
        args.search_data = True

    # Get the search pattern.
    pattern = args.pattern
    if args.ignore_case:
        pattern = pattern.lower()

    if args.startkey:
        # Split the keyname at the first \
        hkey_and_subkey = args.startkey.split("\\", 1)

        # Map the hive name to a hive handle
        try:
            root = HIVE_ABBR[hkey_and_subkey[0]]
        except Exception:
            arg_parser.error(
                "unknown HKEY, use HKCR, HKCU, HKLM, HKU, HKCC, or HKDD"
            )
            return 1

        if len(hkey_and_subkey) == 2:
            try:
                key = winreg.OpenKey(root, hkey_and_subkey[1])
                search(args, [], key, sys.argv[2], pattern)
                winreg.CloseKey(key)
            except Exception:
                # Be quiet if the starting key does not exist
                return 0

        else:
            search_root(args, root, pattern)
    else:
        search_root(args, winreg.HKEY_CLASSES_ROOT, pattern)
        search_root(args, winreg.HKEY_CURRENT_USER, pattern)
        search_root(args, winreg.HKEY_LOCAL_MACHINE, pattern)
        search_root(args, winreg.HKEY_USERS, pattern)
        search_root(args, winreg.HKEY_CURRENT_CONFIG, pattern)
        search_root(args, winreg.HKEY_DYN_DATA, pattern)

    return 0


if __name__ == "__main__":
    sys.exit(main())
