# BrewStaggerBar

![WoW Version](https://img.shields.io/badge/WoW-Midnight%2012.0-blue)
![Version](https://img.shields.io/badge/Version-2.3.0-orange)
![License](https://img.shields.io/badge/License-GPLv3-green)

Lightweight, feature-rich Brewmaster Monk stagger tracking bar for **World of Warcraft: Midnight (12.0+)**.

Built from the ground up as a standalone addon to replace a WeakAuras setup that is no longer viable under Midnight's Secret Values API restrictions. All combat API calls are wrapped in `pcall` for full Secret Values safety — if Blizzard re-restricts any API, the bar degrades gracefully instead of throwing errors.

![preview](https://i.imgur.com/placeholder.png)
<!-- Replace with an actual screenshot once available -->

---

## Features

### Stagger Bar
- 4 configurable color tiers: Light (0–30%), Moderate (30–60%), Heavy (60–100%), Extreme (>100%)
- Bar maximum scales up to 1000% max HP (configurable via slider) with linear fill instead of resetting at 100%
- Optional overflow wrap mode: bar refills cyclically when exceeding the configured maximum
- Background color changes on extreme stagger
- Horizontal or vertical orientation
- Smooth bar animation powered by LibSmoothStatusBar (toggleable)
- Custom border texture, size and color via LibSharedMedia
- Bar textures and fonts via LibSharedMedia

### Template Text System
Three independent text elements (label, percentage, tick) — each with its own font face, size, outline, anchor point and X/Y offsets. All text is driven by templates using these flags:

| Flag | Output | Example |
|------|--------|---------|
| `%n` | Name | `Stagger` |
| `%s` | Stagger total (formatted) | `1.2m` |
| `%r` | Stagger total (raw) | `1234567` |
| `%p` | Stagger as % of max HP | `45%` |
| `%t` | Single tick value (formatted) | `61.7k` |
| `%d` | Tick DPS — tick × 2 (formatted) | `123.4k/s` |
| `%tp` | Tick as %HP per second | `4.5%` |
| `%m` | Max HP (formatted) | `2.7m` |
| `%a` | Absolute stagger / max HP | `450k / 1.2m` |
| `%purify` | Purifying Brew predicted clear | `225k` |
| `%%` | Literal `%` | `%` |
| `%(` / `%)` | Literal parentheses | `(` `)` |

Number formatting options: raw, k/m, mil/M, or K/M short notation.

**Default templates:** label shows `%d (%tp)` (tick DPS with tick percentage), right side shows `%p` (stagger percentage).

### Glow Effects
LibCustomGlow integration with 4 glow types, each with its own configurable parameters:

| Type | Parameters |
|------|------------|
| **Pixel** | Lines, frequency, thickness, border mode |
| **AutoCast** | Particles, frequency, scale |
| **Button** | Frequency |
| **Proc** | Duration, start animation toggle |

All types share color picker and X/Y offset controls. Glow triggers at a configurable stagger tier.

### Visibility Rules
- Auto-show only when playing Brewmaster spec
- Hide out of combat (with configurable fade delay in seconds)
- Hide in rest areas / cities
- Hide when stagger is zero (full HP)

### Sparkline History
Mini line graph below the bar showing stagger trend over time. Configurable height, number of samples and color.

### Alerts
- **Sound alerts** — play any LibSharedMedia sound when reaching a configurable tier, with adjustable cooldown
- **Combat chat log** — print stagger tier warnings to chat, routed via LibSink (supports Scrolling Combat Text, MikSBT, Blizzard floating text, Parrot, and more)

### Profile System
- AceDB profiles with per-character or shared configurations
- Automatic profile switching per specialization via LibDualSpec
- Compressed profile import/export (AceSerializer + LibDeflate) — share your setup as a string

### Other
- Test Mode with visual indicator — cycles through all tiers for previewing settings
- Bob and Weave talent detection — auto-adjusts tick calculation (20 vs 26 ticks)
- Drag-to-move with lock toggle
- Screen clamp recovery — bar auto-repositions to center if saved offscreen after a resolution change
- Addon Compartment integration (Midnight minimap menu) via LibDBCompartment

---

## Slash Commands

| Command | Action |
|---------|--------|
| `/bsb` | Toggle bar visibility |
| `/bsb lock` | Lock/unlock bar position |
| `/bsb config` | Open options GUI |
| `/bsb size W H` | Resize bar (e.g. `/bsb size 300 24`) |
| `/bsb reset` | Reset profile to defaults |
| `/bsb export` | Export profile as compressed string |
| `/bsb import <string>` | Import profile from string |
| `/bsb help` | Show command list |

---

## Options GUI

Accessible via `/bsb config` or **Esc → Options → AddOns → BrewStaggerBar**. 10 tabs:

| Tab | Controls |
|-----|----------|
| **General** | Lock, update interval, smooth bar toggle, visibility rules (combat/town/full HP/fade delay), test mode |
| **Bar** | Width, height, texture, opacity, orientation, max % slider, overflow wrap toggle, border (texture/size/color) |
| **Colors** | 4 color pickers with alpha (Light / Moderate / Heavy / Extreme), background colors for normal and extreme |
| **Glow** | Enable, trigger tier, glow type selector, shared controls (color, X/Y offset), per-type parameters (conditionally visible) |
| **Text** | Global font (face/size/outline), per-element overrides for label, percentage and tick |
| **Tick Display** | Show toggle, template, font, anchor, offsets |
| **Alerts** | Sound alert config (file/tier/cooldown), chat log config (tier), LibSink output destination |
| **Sparkline** | Enable, height, samples, color, Y offset |
| **Import/Export** | Export button, import text field |
| **Profiles** | AceDB profile management + LibDualSpec auto-switching |

---

## Localization

BrewStaggerBar includes translations for: English (enUS), Spanish (esES), German (deDE), French (frFR), Brazilian Portuguese (ptBR), and Chinese Simplified (zhCN).

---

## Installation

### CurseForge / WoWUp
Install directly from CurseForge. All libraries are bundled.

### Manual
1. Download or clone this repository
2. Copy the `BrewStaggerBar` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. All required libraries should be in `BrewStaggerBar/Libraries/`

### Required Libraries

| Library | Purpose |
|---------|---------|
| LibStub | Library loader |
| CallbackHandler-1.0 | Event callbacks |
| Ace3 (AceAddon, AceConsole, AceDB, AceDBOptions, AceGUI, AceConfig, AceSerializer) | Addon framework |
| LibSharedMedia-3.0 | Textures, fonts, sounds, borders |
| LibCustomGlow-1.0 | Glow effects |
| LibSmoothStatusBar-1.0 | Smooth bar animation |
| LibDualSpec-1.0 | Auto profile switching per spec |
| LibSink-2.0 | Alert output routing |
| LibDBCompartment-1.0 | Addon Compartment menu |
| LibDeflate | Profile compression |

---

## File Structure

```
BrewStaggerBar/
├── Core/
│   ├── Utils.lua          — Constants, safe API wrappers, number formatting, template engine
│   ├── Bar.lua            — Bar frame, StatusBar, texts, glow, sparkline, visual updates
│   └── Core.lua           — AceAddon entry point, AceDB, events, visibility, slash commands, import/export
├── Libraries/
│   └── init.xml           — Library load order
├── Locales/
│   ├── enUS.lua           — English
│   ├── esES.lua           — Spanish
│   ├── deDE.lua           — German
│   ├── frFR.lua           — French
│   ├── ptBR.lua           — Brazilian Portuguese
│   └── zhCN.lua           — Chinese Simplified
├── Media/
│   ├── Textures/          — Custom bar textures (optional)
│   └── Fonts/             — Custom fonts (optional)
├── Modules/
│   └── Options.lua        — AceConfig options table (10 tabs)
├── GUI.lua                — AceConfigDialog, Blizzard Settings, Addon Compartment, profiles
├── BrewStaggerBar.toc
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## Midnight API Notes

| API | Usage |
|-----|-------|
| `UnitStagger("player")` | Declassified secondary resource — returns current stagger amount |
| `UnitHealthMax("player")` | Non-secret for personal health |
| `C_UnitAuras.GetAuraDataBySpellID` | Tick values from stagger debuffs (124273 / 124274 / 124275) |
| `IsPlayerSpell(280515)` | Bob and Weave talent detection (not combat-restricted) |

All calls are wrapped in `pcall` for graceful degradation.

---

## License

GNU General Public License v3.0

---

## Author

**Aderfi**
