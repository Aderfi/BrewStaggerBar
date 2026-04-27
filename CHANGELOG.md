# StaggerBar Changelog

## v2.0.2 (2026-04-28)
### Changes since v2.0.0:



## v2.0.1 (2026-04-28)
- Minor fixes for 12.0.5 compatibility issues



## v2.0.0 (2026-04-20)

Major refactor — new features, new libraries, improved architecture.

### Architecture & Code Quality
- Centralized all spell IDs, tier thresholds, tick counts and constants into `ns.CONST` table
- Fixed OnUpdate throttle: now uses real elapsed time (`dt`) instead of estimating `frames × 1/60`
- Added screen clamp recovery: bar auto-repositions to center if saved offscreen after a resolution change
- Fixed missing `end` closure in `UpdateSparkline` function
- Fixed truncated `SlashHandler` — restored missing help text and error handling

### New Libraries Integrated
- **LibSmoothStatusBar-1.0** — replaces manual lerp logic for smooth bar animation; toggle on/off in General settings
- **LibDualSpec-1.0** — automatic profile switching per specialization; dropdown added to Profiles tab
- **LibSink-2.0** — alert output routing: chat, Scrolling Combat Text, MikSBT, Blizzard floating text, Parrot, etc.; configurable in Alerts tab
- **LibDBCompartment-1.0** — registers the addon in the Midnight Addon Compartment menu (new minimap system)
- **LibDeflate + AceSerializer-3.0** — compressed profile import/export via `/bsb export` and `/bsb import`

### New Features
- **Visibility rules** — hide out of combat (with configurable fade delay), in rest areas/cities, or when stagger is zero
- **Sound alerts** — play a LibSharedMedia sound when reaching a configurable tier, with adjustable cooldown
- **Combat chat log** — prints stagger tier alerts to chat (routed via LibSink)
- **Custom border** — LibSharedMedia border texture, size and color selectors
- **Vertical orientation** — bar can be rotated 90° with adapted spark positioning
- **New template flags**: `%a` (absolute value e.g. "450k / 1.2m"), `%purify` (Purifying Brew predicted clear value)
- **Independent fonts** — each text element (label, percentage, tick) can override the global font face, size and outline
- **Sparkline history** — mini line graph below the bar showing stagger trend over time, with configurable height, samples and color
- **Test Mode indicator** — yellow "TEST MODE" badge visible below the bar when test mode is active
- **Profile import/export** — serialize current profile to a compressed string; import via paste dialog or `/bsb import`
- **Bar scaling** — stagger bar maximum is now 1000% max HP (linear fill) instead of resetting overflow at 100%

### New Locales
- German (deDE), French (frFR), Brazilian Portuguese (ptBR), Chinese Simplified (zhCN)

### Options Panel
- Expanded from 6 to 10 tabs: General, Bar, Colors, Glow, Text, Tick Display, Alerts, Sparkline, Import/Export, Profiles
- General tab: added Smooth Bar toggle, Visibility section (hide out of combat / in town / at full HP / fade delay)
- Bar tab: added Orientation selector, Border section (texture, size, color)
- Text tab: added per-element font overrides for label, percentage and tick
- Alerts tab: sound alert config + chat log config + LibSink output destination
- Sparkline tab: enable, height, samples, color
- Import/Export tab: export button + import text field

### Slash Commands
- `/bsb export` — open export window with profile string
- `/bsb import <string>` — import a profile from a compressed string

---

## v1.1.0 (2026-03-16)
- Full rewrite as standalone addon (migrated from WeakAuras)
- Midnight (12.0) Secret Values compatible (pcall-wrapped APIs)
- AceAddon-3.0 / AceDB-3.0 framework with profile support
- LibSharedMedia-3.0 integration for textures and fonts
- Configurable color tiers: Light / Moderate / Heavy / Extreme
- Configurable text: custom label, font face, size, outline, anchor point + offsets
- Number formatting: raw, k/m, mil/M, K/M short
- Toggleable tick DPS and tick %HP/s display with independent anchor
- Full AceConfig GUI (General, Bar, Colors, Text, Tick Display, Profiles)
- Drag-to-move with lock toggle
- Auto-show only for Brewmaster Monk spec
- Slash commands: /sb, /staggerbar
- Locales: enUS, esES


## v1.0.0 (2026-03-16)
- Release v1.0.0
