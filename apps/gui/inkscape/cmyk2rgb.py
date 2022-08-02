import argparse
import pyperclip


def cmyk_to_rgb(c, m, y, k, cmyk_scale=100, rgb_scale=255):
    r = rgb_scale * (1.0 - c / cmyk_scale) * (1.0 - k / cmyk_scale)
    g = rgb_scale * (1.0 - m / cmyk_scale) * (1.0 - k / cmyk_scale)
    b = rgb_scale * (1.0 - y / cmyk_scale) * (1.0 - k / cmyk_scale)
    return r, g, b


DEFAULT = -1

parser = argparse.ArgumentParser()
parser.add_argument("cmyk", metavar="N", type=int, nargs="*", help="CMYK value")
args = parser.parse_args()

cmyk = args.cmyk

if all(channel == DEFAULT for channel in cmyk):
    cmyk = pyperclip.paste().replace(" ", ",").split(",")
if any(channel == DEFAULT for channel in cmyk) or len(cmyk) != 4:
    raise ValueError(f"Must have 4 arguments. Provided: {args.cmyk!s}")

rgb = [int(c + 0.5) for c in cmyk_to_rgb(*cmyk)]

res = " ".join(f"{c:>3}" for c in rgb)
print(res)
pyperclip.copy(res)
