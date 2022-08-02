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