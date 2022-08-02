#!/usr/bin/python

import json
import logging
from argparse import ArgumentParser, Namespace
from pathlib import Path
from subprocess import CalledProcessError, CompletedProcess, TimeoutExpired, run
from typing import Dict, Any
from uuid import uuid4


def parse_args() -> Namespace:
    parser = ArgumentParser(
        description="A program to help virtualization process", prog="virt_helper"
    )
    act = parser.add_mutually_exclusive_group(required=True)
    act.add_argument(
        "--create", "-c", action="store_true", default=False, help="create virtual gpu"
    )
    act.add_argument(
        "--destroy",
        "-d",
        action="store_true",
        default=False,
        help="destroy virtual gpu",
    )
    act.add_argument(
        "--status",
        "-s",
        action="store_true",
        default=False,
        help="print virtual gpu status",
    )
    parser.add_argument(
        "--config",
        "-C",
        default=Path(__file__).resolve().parent / "config.json",
        help="set configuration file",
    )
    return parser.parse_args()


def handled_run(cmd: str) -> CompletedProcess:
    try:
        return run(
            cmd,
            shell=True,
            timeout=5,
            check=True,
            encoding="utf-8",
            capture_output=True,
        )
    except CalledProcessError as e:
        logging.warning(f"Failed to run {cmd}: {e!r}")
    except TimeoutExpired as e:
        logging.warning(f"Time out to run {cmd}: {e!r}")
    except Exception as e:
        logging.warning(f"{e!r}")


def get_config(config_path: str) -> Dict[str, Any]:
    try:
        return json.loads(open(config_path, "r").read())
    except FileNotFoundError:
        logging.info(f"Config file {config_path} does not exists. Creating")

        gvt_pci = handled_run(
            "lspci -D -nn | grep 'HD Graphics' | awk '{printf(\"%s\", $1)}'"
        ).stdout
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


def create(args: Dict[str, Any]) -> None:
    with open(
        "/sys/devices/pci{gvt_dom}/{gvt_pci}/mdev_supported_types/{gvt_type}/create".format(
            **args
        ),
        "w",
    ) as f:
        f.write(args["uuid"])


def destroy(args: Dict[str, Any]) -> None:
    with open(
        "/sys/bus/pci/devices/{gvt_pci}/{uuid}/remove".format(**args),
        "w",
    ) as f:
        f.write("1")


def status(args: Dict[str, Any]) -> None:
    result = dict(args)
    result["gvt_state"] = Path(
        "/sys/bus/pci/devices/{gvt_pci}/{uuid}".format(**args)
    ).exists()
    print(json.dumps(result))


def main() -> None:
    args = parse_args()
    config = get_config(args.config)
    try:
        if args.create:
            create(config)
        if args.destroy:
            destroy(config)
        if args.status:
            status(config)
    except Exception as e:
        logging.error(f"{e!r}")


if __name__ == "__main__":
    main()
