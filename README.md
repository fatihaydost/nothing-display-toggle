<div align="center">

# Nothing Display Toggle

**Switch any display on or off from your desktop — one tap, no System Settings.**

A KDE Plasma 6 widget for multi-monitor setups, styled after the Nothing OS dot-matrix look.

<img src="docs/hero.png" width="420" alt="The widget showing two displays, both switched on">

</div>

---

## Why

If you run more than one screen, you constantly want one of them *gone* for a while — the
laptop panel while the machine is docked, the second monitor while you play something
fullscreen, the TV you only use on weekends. Doing that through **System Settings → Display
Configuration** is four clicks and a confirmation dialog, every single time.

This widget puts a switch for every connected display on your desktop, shows you at a glance
which ones are live, and refuses to let you turn off the last one.

## What it looks like

| All displays on | One display switched off | Four displays connected |
|:---:|:---:|:---:|
| <img src="docs/hero.png" width="260" alt="Two displays, both on"> | <img src="docs/state-off.png" width="260" alt="Laptop panel off, its toggle reads SLEEPING"> | <img src="docs/state-multi.png" width="260" alt="Four displays with two HDMI outputs numbered"> |
| The counter reads `2/2` and the strip along the bottom is fully lit. | The laptop panel reads `SLEEPING`. The remaining display's switch dims — it is the last one on and cannot be turned off. | Rows appear per output. Two HDMI monitors are numbered `HDMI 1` / `HDMI 2`; the counter reads `3/4`. |

## Features

- **Every connected output, found automatically.** Nothing is hardcoded — rows appear and
  disappear as you plug monitors in and out, on any machine.
- **Labels you can actually read.** Outputs are named by what they are — `LAPTOP`, `HDMI`,
  `DP`, `VGA`, `DVI`, `TV` — numbered when several share a type, with the connector name
  (`HDMI-A-1`, `eDP-1`, …) underneath.
- **You cannot black out your machine.** The last enabled output is locked: its switch dims and
  the cursor turns to "not allowed". There is no way to reach a state with no screen on.
- **Always tells the truth.** State is re-read every 4 seconds, so the widget stays correct even
  when you change displays from System Settings, a keyboard shortcut, or another script.
- **Nothing OS styling.** Dot-matrix type, red accents, a status dot that pings like radar while
  any display is live, and a bottom strip whose lit fraction is the fraction of displays that
  are on.

## Requirements

- KDE Plasma 6
- `kscreen-doctor` — ships with Plasma (part of `libkscreen`), so it is already there on a
  standard install

Works on both Wayland and X11.

## Install

**From the widget store**

Right-click the desktop → **Add Widgets…** → **Get New Widgets…** → search for
*Nothing Display Toggle*.

**From a release file**

```bash
kpackagetool6 --type Plasma/Applet --install nothing-display-toggle.plasmoid
```

Use `--upgrade` instead of `--install` to update an existing copy.

**From source**

```bash
git clone https://github.com/fatihaydost/nothing-display-toggle.git
cd nothing-display-toggle
./install.sh
```

Then right-click the desktop → **Add Widgets…** → drag *Nothing Display Toggle* out.

> Not listed yet? Plasma caches the widget list. Restart it once:
> `systemctl --user restart plasma-plasmashell.service`

## Read this before you switch a monitor off

Turning an output off **removes it from the desktop layout**. Windows that were on it move to
the remaining screens, and so does anything sitting on that desktop — **including this widget**.

> **Put a copy on every screen.** That is how you switch a display back on: from the copy on a
> screen that is still awake.

This is also why the widget is not a screen blanker. Two different things are often called
"turning the screen off":

| | What happens | Wakes on mouse move? |
|---|---|---|
| **DPMS sleep** (`kscreen-doctor --dpms off`) | Screen goes dark, output stays in the layout | Yes — instantly, which makes it useless for parking one screen while you work on another |
| **Disable** (what this widget does) | Output leaves the layout, windows move away | No — it stays off until you switch it back on |

## Uninstall

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.fatihaydost.displaytoggle
```

> In the desktop context menu, **Remove** takes the widget off the desktop.
> **Uninstall** deletes the package from disk. They are not the same thing.

## How it works

There is no daemon, no config file of its own, and nothing running in the background beyond a
4-second poll. State is read from `kscreen-doctor -j`, and a toggle runs exactly one command:

```bash
kscreen-doctor output.<connector>.disable   # or .enable
```

Plasma's own display configuration keeps track of the result, so the state survives reboots the
same way any other display setting does.

## Building a release archive

```bash
./build.sh        # produces nothing-display-toggle.plasmoid
```

## The font

The dot-matrix face is [**Doto**](https://github.com/oliverlalan/Doto) by the Doto Project
Authors, licensed under the [SIL Open Font License 1.1](package/contents/fonts/OFL.txt) and
bundled unmodified. Doto is a variable font: the widget asks for `ROND=100` (fully round dots)
and picks weights through the `wght` axis, which needs Qt 6.7 or newer.

The font is not required. If it fails to load — or if you delete it before redistributing — the
widget falls back to the system monospace face and keeps working; it just stops looking like a
dot-matrix display.

> Widgets in this style often ship *Nothing Font (5x7)*, a FontStruct recreation whose license
> forbids redistribution ("you may not distribute, redistribute, give-away or make available
> the Font Software"). It is fine to use privately, but it cannot be bundled in a package you
> share — which is why this widget uses Doto instead.

## License

[GPL-3.0-or-later](LICENSE)
