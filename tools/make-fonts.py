#!/usr/bin/env python3
"""Bake the static faces the widget ships from their variable sources.

Two reasons nothing is applied at runtime:

  - Doto's round-dot look exists only as a point on its ROND axis; all nine of
    its named instances sit at ROND=0.
  - Asking for an axis at runtime through `font.variableAxes` renders the wrong
    glyphs inside plasmashell — right face, right letter count, wrong characters.

Neither font declares a Reserved Font Name, so instancing and renaming them is
allowed. Both licences travel with the packages as shared/fonts/OFL-*.txt.

Needs fonttools:  python3 -m venv .venv && .venv/bin/pip install fonttools
Usage:            .venv/bin/python tools/make-fonts.py
"""
import pathlib
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "shared" / "fonts"

WINDOWS_ENGLISH = dict(platformID=3, platEncID=1, langID=0x409)
MAC_ENGLISH = dict(platformID=1, platEncID=0, langID=0)

# source file, family to publish under, then one entry per face:
# file stem, subfamily, axis coordinates, OS/2 weight class
JOBS = [
    (
        "Doto-VariableFont.ttf",
        "Doto Round",
        [
            ("Doto-Round-Regular", "Regular", {"ROND": 100, "wght": 400}, 400),
            ("Doto-Round-Medium", "Medium", {"ROND": 100, "wght": 500}, 500),
        ],
    ),
    (
        # 350 sits between Light and Regular: airy at 17px, still solid at 9px
        "Jost-VariableFont.ttf",
        "Jost Book",
        [
            ("Jost-Book", "Regular", {"wght": 350}, 350),
        ],
    ),
]


def set_name(font, name_id, value):
    for spec in (WINDOWS_ENGLISH, MAC_ENGLISH):
        font["name"].setName(value, name_id, **spec)


def main():
    for source, family, faces in JOBS:
        src = ROOT / "tools" / source
        if not src.exists():
            sys.exit(f"missing source font: {src}")

        for stem, subfamily, coords, weight_class in faces:
            font = TTFont(src)
            instancer.instantiateVariableFont(
                font, coords, inplace=True, updateFontNames=False
            )

            # RIBBI naming: a non-Regular weight keeps "Regular" as the legacy
            # style and carries the real style in the typographic names, so a
            # family lookup plus a weight still resolves to the right face.
            legacy_family = family if subfamily == "Regular" else f"{family} {subfamily}"
            pinned = " ".join(f"{k}={v}" for k, v in sorted(coords.items()))
            set_name(font, 1, legacy_family)
            set_name(font, 2, "Regular")
            set_name(font, 3, f"{family} {subfamily}; instanced {pinned}")
            set_name(font, 4, f"{family} {subfamily}")
            set_name(font, 6, f"{family.replace(' ', '')}-{subfamily}")
            set_name(font, 16, family)
            set_name(font, 17, subfamily)

            font["OS/2"].usWeightClass = weight_class

            out = OUT / f"{stem}.ttf"
            font.save(out)
            print(f"wrote {out.relative_to(ROOT)}  ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
