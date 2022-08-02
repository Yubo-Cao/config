#!/usr/bin/python

import json
import asyncio
import logging
from argparse import ArgumentParser, Namespace
from pathlib import Path
from asyncio.subprocess import PIPE, create_subprocess_shell
from typing import Dict, Any
from uuid import uuid4


ABSOLUTE_PATH = Path(__file__).resolve().parent
DEFAULT_TIMEOUT = 5


def parse_args() -> Namespace:
    parser = ArgumentParser(
        description="A program to help virtualization process", prog="virt_helper"
    )
    parser.add_argument(
        "--config",
        "-C",
        default=ABSOLUTE_PATH / "config.json",
        help="set configuration file",
    )
    subparsers = parser.add_subparsers(help = "sub-command help")
    gvt = subparsers.add_parser('gvt', help='create intel_gvt vCPU')
    subparsers.add_argument(
        "--create",
        "-c",
        action="store_true",
        default=False,
        help="create virtual gpu",
    )
    subparsers.add_argument(
        "--destroy",
        "-d",
        action="store_true",
        default=False,
        help="destroy virtual gpu",
    )
    subparsers.add_argument(
        "--status",
        "-s",
        action="store_true",
        default=False,
        help="print virtual gpu status",
    )
    return parser.parse_args()


async def get_config(config_path: str) -> Dict[str, Any]:
    config_path = Path(config_path)
    if config_path.exists():
        with open(config_path, "r") as config:
            return json.loads(config.read())
    else:
        logging.info(f"Config file {config_path} does not exists. Creating")

        gvt_pci = create_subprocess_shell(
            "sleep 1; lspci -D -nn | rg 'HD Graphics' | awk '{printf(\"%s\", $1)}'",
            stdout=PIPE,
        )
        gvt_pci, _ = await asyncio.wait_for(gvt_pci.communicate(), DEFAULT_TIMEOUT)
        gvt_dom = ":".join(gvt_pci.split(":")[:2])
        gvt_type = min(
            Path(f"/sys/devices/pci{gvt_dom}/{gvt_pci}/mdev_supported_types").glob("*")
        ).name
        uuid = str(uuid4())
        result = {
            "gvt_pci": gvt_pci,
            "gvt_dom": gvt_dom,
            "gvt_type": gvt_type,
            "uuid": uuid,
        }
        try:
            with open(config_path, "w+") as config:
                config.write(json.dumps(result, indent=4))
            return result
        except PermissionError as e:
            logging.error(
                f"Config file {config_path} can not be read due to permission error"
            )
            raise e
        except IOError as e:
            logging.error(f"{e!r}")
            raise e


async def main():
    args = parse_args()
    config = await get_config(ABSOLUTE_PATH / "config.json")


if __name__ == "__main__":
    asyncio.run(main())
