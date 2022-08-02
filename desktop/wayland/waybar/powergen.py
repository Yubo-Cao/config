import asyncio
import json
import logging
import aiofiles
from typing import Dict, Any
from itertools import starmap
import shutil


async def get_config(name: str) -> Dict[str, Any]:
    try:
        async with aiofiles.open(name, "r") as config:
            return json.loads(await config.read())
    except IOError as e:
        logging.error(f"Failed to open file {name}, {e!r}")
    except Exception as e:
        logging.error(f"{e!r}")


def rightarrow():
    count: int = 0
    while True:
        yield {f"custom/rightarrow{count}": {"format": ""}}
        count += 1


def leftarrow():
    count: int = 0
    while True:
        yield {f"custom/leftarrow{count}": {"format": ""}}
        count += 1


async def main():
    GEN_CONFIG = await get_config("genconfig.json")
    COLOR_SCHEME = await get_config(GEN_CONFIG["scheme_config"])
    WAYBAR_CONFIG = await get_config(GEN_CONFIG["waybar_config"])
    shutil.copy(GEN_CONFIG["css_input"],GEN_CONFIG["css_output"])

    css = await aiofiles.open(GEN_CONFIG["css_output"], "a")

    for mod, color in zip(
        WAYBAR_CONFIG["modules-right"], COLOR_SCHEME[GEN_CONFIG["scheme"]].values()
    ):
        await css.write(
            f"""#{mod.replace('/','-')}{{
    background-color: rgba({', '.join(starmap(lambda a,b: str(int(a + b,
    base=16)), zip(color[1::2],color[2::2])))}, 0.5);
}}
"""
        )


asyncio.run(main())
