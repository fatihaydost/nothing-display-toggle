#!/usr/bin/env python3
"""Bake the two faces the widget uses out of the Doto variable font.

Doto ships nine named instances and every one of them is ROND=0 — the round-dot
look only exists as a point on the variable axis. Asking for it at runtime with
`font.variableAxes` turned out to render the wrong glyphs inside plasmashell, so
the two instances we need are baked into static files instead.

Needs fonttools:  python3 -m venv .venv && .venv/bin/pip install fonttools
Usage:            .venv/bin/python tools/make-fonts.py
"""
import pathlib
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "tools" / "Doto-VariableFont.ttf"
OUT = ROOT / "shared" / "fonts"

FAMILY = "Doto Round"
FACES = [
    # file stem, subfamily, wght, OS/2 weight class
    ("Doto-Round-Regular", "Regular", 400, 400),
    ("Doto-Round-Medium", "Medium", 500, 500),
]
WINDOWS_ENGLISH = dict(platformID=3, platEncID=1, langID=0x409)
MAC_ENGLISH = dict(platformID=1, platEncID=0, langID=0)


def set_name(font, name_id, value):
    for spec in (WINDOWS_ENGLISH, MAC_ENGLISH):
        font["name"].setName(value, name_id, **spec)


def main():
    if not SRC.exists():
        sys.exit(f"missing source font: {SRC}")

    for stem, subfamily, wght, weight_class in FACES:
        font = TTFont(SRC)
        instancer.instantiateVariableFont(
            font, {"ROND": 100, "wght": wght}, inplace=True, updateFontNames=False
        )

        # RIBBI naming: a non-Regular weight keeps "Regular" as the legacy style
        # and carries the real style in the typographic names, so a family lookup
        # plus a weight still resolves to the right face.
        legacy_family = FAMILY if subfamily == "Regular" else f"{FAMILY} {subfamily}"
        set_name(font, 1, legacy_family)
        set_name(font, 2, "Regular")
        set_name(font, 3, f"{FAMILY} {subfamily}; instanced ROND=100 wght={wght}")
        set_name(font, 4, f"{FAMILY} {subfamily}")
        set_name(font, 6, f"DotoRound-{subfamily}")
        set_name(font, 16, FAMILY)
        set_name(font, 17, subfamily)

        font["OS/2"].usWeightClass = weight_class

        out = OUT / f"{stem}.ttf"
        font.save(out)
        print(f"wrote {out.relative_to(ROOT)}  ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
