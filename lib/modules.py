#!/usr/bin/env python3

import argparse
import ast
import os
from collections import deque


# to avoid ruff warning
class PathException(Exception):
    pass


def colorize(text: str, color_code: int) -> str:
    return f"\033[38;5;{color_code}m{text}\033[0m"


def purple(s: str) -> str:
    return colorize(s, 141)


def blue(s: str) -> str:
    return colorize(s, 39)


def pink(s: str) -> str:
    return colorize(s, 206)

def cyan(s: str) -> str:
    return colorize(s, 51)


def read_manifest_content(manifest_path: str) -> dict:
    with open(manifest_path, encoding='utf8') as f:
        return ast.literal_eval(f.read())


# returns a map of this format: {module_name: manifest_file_content}
def get_manifest_map(directories) -> dict[str, dict]:
    manifest_map = {}
    for directory in directories:
        if not os.path.isdir(directory):
            raise PathException(f"{directory} is not a valid directory")
        for item in os.listdir(directory):
            item_path = os.path.join(directory, item)
            if os.path.isdir(item_path):
                manifest_path = os.path.join(item_path, "__manifest__.py")
                if os.path.exists(manifest_path):
                    manifest_map[item] = read_manifest_content(manifest_path)
                else:
                    manifest_map[item] = {}
    return manifest_map


def get_args():
    parser = argparse.ArgumentParser(
        description="Visualize odoo modules relations",
        epilog="Example usage:"
                "  ./modules.py ./community/addons ./enterprise -m web,iot",
    )
    parser.add_argument(
        "directories",
        nargs='+',
        help="List of addon directories to process",
    )
    parser.add_argument(
        "-m",
        "--module",
        required=True,
        type=str,
        help="Simulate the comma-separated modules as if they were installed"
            "(e.g., 'web,hr_test')",
    )
    parser.add_argument(
        "--installed",
        action="store_true",
        default=True,
        help="Show modules installed by \"-m\" (default: True)",
    )
    parser.add_argument(
        "--installers",
        action="store_false",
        dest="installed",  # links to the same variable as --installs
        help="Disable the default --installed flag",
    )
    parser.add_argument(
        "--legend",
        action="store_true",
        default=True,
        help="Enable legend (default: True)",
    )
    parser.add_argument(
        "--no-legend",
        action="store_false",
        dest="legend",  # links to the same variable as --legend
        help="Disable the default --legend flag",
    )
    return parser.parse_args()


# returns the modules installed by arg modules
def get_installed(
    modules: list[str],
    manifest_map: dict[str, dict],
) -> list[dict]:
    installed = []
    memo = dict()
    d = deque([{'name': module} for module in modules])
    while d:
        m = d.popleft()
        if m['name'] in memo:
            continue
        memo[m['name']] = m
        installed.append(m)
        if (
            m['name'] not in manifest_map
            or 'depends' not in manifest_map[m['name']]
        ):
            continue
        for dep in manifest_map[m['name']]['depends']:
            d.append(
                {
                    'name': dep,
                    'parent': m,
                },
            )

    # add auto-installed modules
    n_installed = len(installed)
    while True:  # added auto installed modules can intsall other modules again
        for module_name, manifest in manifest_map.items():
            if module_name in memo:
                continue  # already in installs list
            auto_install = manifest.get('auto_install')
            if auto_install == True:  # noqa: E712
                auto_install = manifest.get('depends', False)
            if not auto_install:
                continue
            is_auto_installed = True
            for auto_installer in auto_install:
                if auto_installer not in memo:
                    is_auto_installed = False
                    break
            if is_auto_installed:
                auto_install = [memo[ai] for ai in auto_install]
                m = {'name': module_name, 'auto_install': auto_install}
                installed.append(m)
                memo[m['name']] = m
        if len(installed) == n_installed:
            break
        n_installed = len(installed)
    return installed


# to colorize output
def color_module_level(mod) -> str:
    if isinstance(mod, list):
        return ', '.join(color_module_level(i) for i in mod)
    name = mod.get('name', 'You')
    if mod.get('auto_install'):
        return cyan(name)
    if name == 'You':
        return name
    if 'parent' not in mod:
        return purple(name)
    if 'parent' not in mod['parent']:
        return blue(name)
    return pink(name)


# format and print modules installed by modules arg
def print_installed(installed: list, show_legend: bool):
    if show_legend:
        print(
            f"""
{purple('■')} Base module
{blue('■')} Modules directly installed by base modules
{pink('■')} Modules indirectly installed by base modules
{cyan('■')} Modules installed by auto_install
""",
        )

    for i in installed:
        name = color_module_level(i)
        auto_install = i.get('auto_install')
        if auto_install:
            auto_install = color_module_level(auto_install)
            print(
                f"""{name}
    Installed by: auto_install[{auto_install}]""",
            )
        else:
            installed_by = color_module_level(i.get('parent', {}))
            print(
                f"""{name}
    Installed by: {installed_by}""",
            )


# get all modules that (in)directly install modules arg
def get_installers(
    modules: list[str],
    manifest_map: dict[str, dict],
) -> list[dict]:
    # None if does not install, else {name, module_that_name_installs}
    memo: dict[str, dict | None] = {}

    def dfs(module_name: str) -> bool:
        if module_name in memo:
            return memo[module_name] is not None
        memo[module_name] = None
        manifest = manifest_map.get(module_name, {})
        for dep in manifest.get('depends', []):
            if dfs(dep):
                memo[module_name] = {'name': module_name, 'parent': memo[dep]}
                return True
        return False

    for module in modules:
        memo[module] = {'name': module}

    for module_name in manifest_map:
        dfs(module_name)

    installers = []
    for installer in memo.values():
        if installer is None:
            continue
        installers.append(installer)
    return installers


# format and print modules that install modules arg
def print_installers(installers: list[dict], module: str, show_legend: bool):
    def sort_by_n_parents(x):
        if not 'parent' in x:
            return 0, x['name']
        if not 'parent' in x['parent']:
            return 1, x['name']
        return 2, x['name']

    if show_legend:
        print(
            f"""
{purple('■')} Base module
{blue('■')} Modules that directly install base modules
{pink('■')} Modules that indirectly install base modules
""",
        )

    for i in sorted(installers, key=sort_by_n_parents):
        name = color_module_level(i)
        installs = color_module_level(i.get('parent', {}))
        print(
            f"""{name}
  Installs: {installs}""",
        )


def main():
    args = get_args()
    manifest_map = get_manifest_map(args.directories)
    modules = args.module.split(',')
    show_legend = args.legend

    if args.installed:
        installed = get_installed(modules, manifest_map)
        print_installed(installed, show_legend)
    else:
        installers = get_installers(modules, manifest_map)
        print_installers(installers, modules, show_legend)


if __name__ == "__main__":
    main()
