#!/usr/bin/python
import argparse
from concurrent.futures import ThreadPoolExecutor
from email.policy import default
from itertools import chain
import sys
from collections.abc import Mapping, Sequence
from functools import lru_cache, partial
from logging import DEBUG, INFO, WARNING, ERROR, Logger, Formatter, StreamHandler
import shutil
from subprocess import PIPE, CalledProcessError, Popen
from collections.abc import Sequence
from types import SimpleNamespace
from colorama import Fore, Style


class ColoredFormatter(Formatter):
    FORMATS = {
        DEBUG: Fore.WHITE + "{msg}" + Fore.RESET,
        INFO: Fore.GREEN + "{msg}" + Fore.RESET,
        WARNING: Fore.YELLOW + "{msg}" + Fore.RESET,
        ERROR: Fore.RED + "{msg}" + Fore.RESET,
    }

    def format(self, record):
        msg = super().format(record)
        return self.FORMATS.get(record.levelno, "{msg}").format(msg=msg)


def get_logger():
    logger = Logger("package manager", INFO)
    sh = StreamHandler(sys.stdout)
    sh.setFormatter(ColoredFormatter("%(levelname)s %(message)s"))
    logger.addHandler(sh)
    return logger


logger = get_logger()

from yaml import YAMLError, load

try:
    from yaml import CLoader as loader
except ImportError:
    from yaml import Loader as loader


class Package:
    def __init__(self, name, exe="yay"):
        self.name = name
        self.exe = Package.get_executable(exe)

    @classmethod
    @lru_cache(maxsize=2)
    def get_executable(cls, exe):
        try:
            return shutil.which(exe)
        except FileNotFoundError:
            logger.error(f"{exe} not found")
            raise

    @property
    def installed(self):
        return self.run(["-Qi", self.name], "get info").returncode == 0

    @installed.setter
    def installed(self, val):
        on_fail = lambda exc: logger.error(
            (
                Style.BRIGHT + "\nStdout:\n" + Style.NORMAL + exc.stdout
                if exc.stdout
                else ""
            )
            + (
                Style.BRIGHT + "\nError:\n" + Style.NORMAL + exc.stderr
                if exc.stderr
                else ""
            )
        )

        if val:
            self.run(["-S", self.name], "install", checked=True, onfail=on_fail)
        else:
            self.run(["-R", self.name], "uninstall", checked=True, onfail=on_fail)

    @property
    def exists(self):
        return self.run(["-Ssq", "^" + self.name + "$"], "get info").returncode == 0

    def run(
        self,
        cmd,
        msg,
        noconfirm=True,
        checked=False,
        onfail=lambda p: None,
        *args,
        **kwargs,
    ) -> Popen:
        logger.debug(f"Running {self.exe} {cmd}")

        if noconfirm:
            cmd[1:1] = ["--noconfirm"]
        cmd = [self.exe] + cmd

        try:
            process = Popen(
                cmd, stdout=PIPE, stderr=PIPE, encoding="utf-8", *args, **kwargs
            )
            stdout, stderr = process.communicate()
            if checked and process.returncode != 0:
                raise CalledProcessError(
                    process.returncode, cmd, output=stdout, stderr=stderr
                )
        except CalledProcessError as e:
            logger.error(f"Failed to {msg} for {self.name!r} [{e.returncode}]")
            onfail(
                SimpleNamespace(
                    returncode=process.returncode, cmd=cmd, stdout=stdout, stderr=stderr
                )
            )
        return process

    def __repr__(self):
        return f"<{self.exe}:{self.name}>"

    def __str__(self) -> str:
        return self.name


def process(args, config: dict[str, str]):
    stack = [config]
    pkgs = {}
    idx = 0
    pk = partial(Package, exe=args.backend)

    def handle_one(pkg, indent=False) -> list[Package]:
        indent = ("   " + Style.DIM) if indent else ""
        if (pkg := pk(pkg)).exists:
            if pkg.installed:
                logger.info(indent + f"{pkg} is already installed" + Style.NORMAL)
                return []
            else:
                return [pkg]
        else:
            logger.warn(indent + f"{pkg} does not exists in repository" + Style.NORMAL)
            return []

    while idx < len(stack):
        e = stack[idx]
        match e:
            case str():
                pkgs.setdefault(default, []).extend(handle_one(e))
            case Mapping():
                if (
                    args.batch
                    and len(e) == 1
                    and (k := next(iter(e.keys()), None))
                    and all(isinstance(e, str) for e in e[k])
                ):
                    logger.info(f"Processing {k}")
                    with ThreadPoolExecutor(max_workers=len(e[k])) as executor:
                        pkgs[k] = list(
                            chain(*executor.map(partial(handle_one, indent=True), e[k]))
                        )
                else:
                    stack.extend(e.values())
            case Sequence():
                stack.extend(e)
        idx += 1

    for group, group_pkgs in pkgs.items():
        if group_pkgs:
            logger.info(f"Installing {group}")
            for pkg in group_pkgs:
                logger.info(Style.DIM + f"    Installing {pkg}" + Style.NORMAL)
                pkg.installed = True


def main():
    args = parse_args()
    print(Style.BRIGHT + f"Installing {args.yaml}" + Style.NORMAL)
    try:
        with open(args.yaml) as yaml:
            config = load(yaml, loader)
    except (YAMLError, IOError) as e:
        logger.error(f"Failed to read config file {args.yaml}")
        sys.exit()

    process(args, config)


def parse_args(args=sys.argv[1:]):
    parser = argparse.ArgumentParser("package manager")
    parser.add_argument("yaml", help="yaml file position")
    parser.add_argument(
        "--backend",
        help="backend to detect",
        choices=["yay", "pacman"],
        default="yay",
    )
    parser.add_argument(
        "--batch",
        help="install a bunch",
        action="store_true",
        default=True,
    )
    args = parser.parse_args(args)
    return args


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"{e!r}")
        sys.exit(1)
