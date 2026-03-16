# StaggerBar

![WoW Version](https://img.shields.io/badge/WoW-Midnight%2012.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)

Lightweight Brewmaster Monk stagger tracking bar for **World of Warcraft: Midnight (12.0+)**.

Built from the ground up as a standalone addon to replace a WeakAuras setup that is no longer viable under Midnight's Secret Values API restrictions.

![preview](https://i.imgur.com/placeholder.png)
<!-- Replace with an actual screenshot once available -->

---

## Features

- **Stagger bar** with 4 configurable color tiers: Light (0-30%), Moderate (30-60%), Heavy (60-100%), Extreme (>100%)
- **Overflow indicator** — background changes color when stagger exceeds max HP
- **Template-based text system** — fully customizable label, percentage and tick text using flags:

  | Flag | Output |
  |------|--------|
  | `%n` | Name ("Stagger") |
  | `%s` | Stagger total (formatted) |
  | `%r` | Stagger total (raw number) |
  | `%p` | Stagger as % of max HP |
  | `%t` | Single tick value (formatted) |
  | `%d` | DPS — tick × 2 (formatted) |
  | `%tp` | Tick as %HP per second |
  | `%m` | Max HP (formatted) |
  | `%%` | Literal `%` character |
  | `%(` | Literal `(` character |
  | `%)` | Literal `)` character |

- **Number formatting** — choose between raw, k/m, mil/M, or K/M short notation
- **LibSharedMedia** integration for bar textures and fonts
- **LibCustomGlow** integration — configurable glow effects (Pixel, AutoCast, Button, Proc) triggered by stagger tier
- **Font customization** — face, size, outline, per-text anchor point and X/Y offsets
- **Test Mode** — simulates stagger cycling through all tiers for previewing settings
- **Bob and Weave** talent detection — auto-adjusts tick calculation (20 vs 26 ticks)
- **AceDB profiles** — per-character or shared profiles with copy/delete/reset
- **Drag-to-move** with lock toggle
- **Auto-visibility** — only shows when playing Brewmaster spec
- **Midnight compatible** — all combat API calls wrapped in `pcall` for Secret Values safety

---

## Installation

### Manual

1. Download or clone this repository
2. Copy the `StaggerBar` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Download the required libraries and place them in `StaggerBar/Libraries/`:

| Library | Source |
|---------|--------|
| LibStub | [WowAce](https://www.wowace.com/projects/libstub) |
| CallbackHandler-1.0 | [WowAce](https://www.wowace.com/projects/callbackhandler) |
| Ace3 (full package) | [CurseForge](https://www.curseforge.com/wow/addons/ace3) / [GitHub](https://github.com/WoWUIDev/Ace3) |
| LibSharedMedia-3.0 | [CurseForge](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) |
| LibCustomGlow-1.0 | [CurseForge](https://www.curseforge.com/wow/addons/libcustomglow) / [GitHub](https://github.com/Stanzilla/LibCustomGlow) |

### CurseForge Packager

If you use the CurseForge packager, the included `.pkgmeta` will download all libraries automatically.

---

## Libraries Directory Structure

```
Libraries/
├── init.xml
├── LibStub/
├── CallbackHandler-1.0/
├── Ace3/
│   ├── AceAddon-3.0/
│   ├── AceConsole-3.0/
│   ├── AceDB-3.0/
│   ├── AceDBOptions-3.0/
│   ├── AceGUI-3.0/
│   └── AceConfig-3.0/
│       ├── AceConfigCmd-3.0/
│       ├── AceConfigDialog-3.0/
│       └── AceConfigRegistry-3.0/
├── LibSharedMedia-3.0/
└── LibCustomGlow-1.0/
```

---

## Addon File Structure

```
StaggerBar/
├── Core/
│   ├── Utils.lua          — Safe API wrappers, number formatting, template engine
│   ├── Bar.lua            — Bar frame, StatusBar, texts, glow, visual updates
│   └── Core.lua           — AceAddon entry point, AceDB, events, slash commands
├── Libraries/             — Embedded libraries (see above)
│   └── init.xml           — Library load order
├── Locales/
│   ├── enUS.lua           — English
│   └── esES.lua           — Spanish
├── Media/
│   ├── Textures/          — Custom bar textures (optional)
│   └── Fonts/             — Custom fonts (optional)
├── Modules/
│   └── Options.lua        — AceConfig options table (all GUI tabs)
├── GUI.lua                — AceConfigDialog, Blizzard Settings, profiles
├── StaggerBar.toc
├── .pkgmeta
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## Slash Commands

| Command | Action |
|---------|--------|
| `/bsb` | Toggle bar visibility |
| `/bsb lock` | Lock/unlock bar position |
| `/bsb config` | Open options GUI |
| `/bsb size W H` | Resize bar (e.g. `/bsb size 300 24`) |
| `/bsb reset` | Reset profile to defaults |
| `/bsb help` | Show command list |

---

## Options GUI

Accessible via `/bsb config` or **Esc → Options → AddOns → StaggerBar**.

| Tab | Controls |
|-----|----------|
| **General** | Lock toggle, Update Interval, Test Mode |
| **Bar** | Width, Height, Texture (LSM), Background Opacity |
| **Colors** | 4 color pickers with alpha (Light / Moderate / Heavy / Extreme) |
| **Glow** | Enable, Trigger Tier, Glow Type, Color, Lines, Frequency, Thickness, Scale |
| **Text** | Font Face (LSM), Size, Outline, Label/Pct/Tick Templates, Anchor Points, Offsets, Number Format |
| **Tick Display** | Show toggle, Template, Font Size, Anchor, Offsets |
| **Profiles** | AceDB profile management (copy/delete/reset) |

---

## Template Examples

| Template | Result |
|----------|--------|
| `%n` | `Stagger` |
| `%n: %s %(%p%)` | `Stagger: 1.2m (45%)` |
| `%r` | `1234567` |
| `%d/s %(%tp%%)` | `123.4k/s (4.5%)` |
| `%s / %m` | `1.2m / 2.7m` |
| `Tick: %t — DPS: %d` | `Tick: 61.7k — DPS: 123.4k` |

---

## Midnight API Notes

- `UnitStagger("player")` — stagger was whitelisted as a declassified secondary resource
- `UnitHealthMax("player")` — returns non-secret for personal health
- `C_UnitAuras.GetAuraDataBySpellID` — used for tick values from stagger debuffs (124273 / 124274 / 124275)
- `IsPlayerSpell(280515)` — talent detection (Bob and Weave) is not combat-restricted
- All combat API calls are wrapped in `pcall` — if Blizzard re-restricts any of these, the bar degrades gracefully

---

## Contributing

Issues and pull requests are welcome. If you find a bug or want to suggest a feature, open an issue on the [GitHub repository](https://github.com/Aderfi/StaggerBar).

---

## License



---

## Author

**Aderfi** — [GitHub](https://github.com/Aderfi)