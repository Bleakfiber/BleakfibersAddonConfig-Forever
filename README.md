# Bleakfiber's Addon Config - Forever

[![Interface](https://img.shields.io/badge/Interface-16001%20(WoW%20Forever)-0078D7.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersAddonConfig-Forever)
[![Release](https://img.shields.io/badge/Release-v1.1.0-ffd100.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersAddonConfig-Forever/releases)
[![License](https://img.shields.io/badge/License-Source--Available-crimson.svg?style=flat-square)](LICENSE.md)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20External-2ea44f.svg?style=flat-square)](https://github.com/Bleakfiber/BleakfibersAddonConfig-Forever)
[![Suite](https://img.shields.io/badge/Suite-Bleakfiber's%20Addon%20Suite-8a2be2.svg?style=flat-square)](https://github.com/Bleakfiber)

**Bleakfiber's Addon Config** is the centralized master configuration hub and profile orchestrator for the **Bleakfiber Addon Suite** in **World of Warcraft: Forever** (Interface 16001).

Engineered to unify your UI management into a single, cohesive Dark Slate & Gold interface, it integrates directly into the native Escape Game Menu, provides a global master mover system that coordinates on-screen positioning across all suite addons, and enforces non-destructive profile synchronization across every installed Bleakfiber addon.

Runs **100% standalone out of the box** with zero required external dependencies.

---

## 📑 Table of Contents

- [Key Highlights](#-key-highlights)
- [Feature Showcase](#-feature-showcase)
  - [1. Centralized Master Hub GUI](#1-centralized-master-hub-gui)
  - [2. Escape Game Menu Integration](#2-escape-game-menu-integration)
  - [3. Global Master Mover Mode](#3-global-master-mover-mode)
  - [4. Non-Destructive Profile Synchronization](#4-non-destructive-profile-synchronization)
  - [5. Module Registry API](#5-module-registry-api)
- [Interactive Controls & Mouse Shortcuts](#-interactive-controls--mouse-shortcuts)
- [Configuration Guide](#-configuration-guide)
- [Slash Commands Reference](#-slash-commands-reference)
- [Architecture & File Overview](#-architecture--file-overview)
- [Installation Guide](#-installation-guide)
- [Bleakfiber Addon Suite Ecosystem](#-bleakfiber-addon-suite-ecosystem)
- [License & Support](#-license--support)

---

## 🌟 Key Highlights

* **Unified Master Hub**: Seamlessly embeds options and controls for every installed Bleakfiber addon into a single window.
* **Native Escape Menu Button**: Adds a stylized `Bleakfiber's Config` button directly inside the standard Blizzard Game Menu (`GameMenuFrame`) below Macros.
* **Combat Lockdown Immunity**: Automatically disables configuration access and displays explanatory tooltips during combat encounters to prevent UI taint.
* **Global Mover Coordination (`/bac mover`)**: Unlocks on-screen position movers across all suite addons simultaneously, hiding redundant individual addon positioning modes.
* **Non-Destructive Profile Synchronization**: New profiles capture active settings across all addons rather than resetting them to factory defaults.
* **Zero External Dependencies**: Self-contained, lightweight implementation with ultra-fast loading times and minimal memory footprint.

---

## 🎯 Feature Showcase

### 1. Centralized Master Hub GUI
Say goodbye to remembering separate slash commands for each addon. Type `/bac` or `/bleak` to access a single window with sidebar navigation for:
- **Bleakfiber's Action Bars**
- **Bleakfiber's Maps**
- **Bleakfiber's Quest Tracker**
- **Bleakfiber's Unit Toggles**

### 2. Escape Game Menu Integration
Effortless access right where you expect it:
- Dynamically attaches a `Bleakfiber's Config` button beneath the Macros / Options buttons on the main Escape menu.
- Compatible with both modern WoW button pools (`GameMenuFrame.buttonPool`) and classic layout templates.
- Automatically adjusts frame height and button spacing to preserve Blizzard UI visual harmony.
- Combat lockdown guard dims the button and provides tooltip notifications during combat.

### 3. Global Master Mover Mode
Streamlined interface layout customization:
- Toggle mover mode via `/bac mover` or through the hub interface.
- Activates anchor frames across Action Bars, Quest Tracker, Bags Bar, Totem Bar, and Maps simultaneously.
- Replaces individual addon positioning modes with a unified coordinate grid and snap assistance.

### 4. Non-Destructive Profile Synchronization
Effortless character and specialization management:
- Create, switch, and delete profiles across the entire suite with one click.
- When creating a new profile, current active settings are safely cloned instead of wiping to defaults.
- Switching profiles updates all registered Bleakfiber addons in lockstep.

### 5. Module Registry API
Designed for modular expansion:
- Simple registration hook (`BAC:RegisterModule`) allows suite addons and third-party/community addons to register their presence, configuration tables, profile sync callbacks, and mover controllers.
- Community addons automatically appear under the dedicated **OTHER ADDONS** sidebar group.
- Full API documentation, widget toolkits, and boilerplate code are provided in the **[Developer Integration Guide](INTEGRATION_GUIDE.md)**.
- Addons function completely standalone when BAC is absent, and automatically integrate when BAC is present.

---

## 🖱️ Interactive Controls & Mouse Shortcuts

| Action | Description |
| :--- | :--- |
| **Escape Key -> Bleakfiber's Config** | Opens the centralized master configuration hub. |
| **`/bac` or `/bleak`** | Opens or closes the master configuration hub. |
| **`/bac mover`** | Toggles global on-screen movers for all suite addons. |
| **`/bac profile <name>`** | Switches active profile across all registered addons. |

---

## 🛠️ Configuration Guide

Type `/bac` or press `Escape -> Bleakfiber's Config`:

1. **Dashboard / Overview**: View all detected and registered Bleakfiber suite addons, their versions, and quick status summaries.
2. **Global Movers**: Launch the unified mover overlay to reposition any frame on your screen.
3. **Master Profiles**: Manage suite-wide profiles with non-destructive cloning, profile copying, and one-click switching.
4. **Addon Sub-Panels**: Select any installed addon from the sidebar navigation to configure its specific features without leaving the hub.

---

## ⌨️ Slash Commands Reference

| Command | Description |
| :--- | :--- |
| `/bac` | Opens the master configuration hub. |
| `/bleak` | Shortcut alias to open the master configuration hub. |
| `/bac mover` | Toggles global mover mode across all suite addons. |
| `/bac profile <name>` | Switches active suite profile or displays current profile. |

---

## 🏗️ Architecture & File Overview

```
BleakfibersAddonConfig-Forever/
├── BleakfibersAddonConfig-Forever.toc  # Addon metadata, SavedVariables & manifest
├── Core.lua                            # Addon hub lifecycle, module registry, GameMenu button
└── UI.lua                              # Master hub GUI, sidebar tabs, profile manager & movers
```

---

## 💾 Installation Guide

1. Download the latest release package from the official [Releases](https://github.com/Bleakfiber/BleakfibersAddonConfig-Forever/releases) page.
2. Exit World of Warcraft completely.
3. Extract the downloaded archive (`BleakfibersAddonConfig-Forever 1.1.0.zip`).
4. Copy the `BleakfibersAddonConfig-Forever` folder into your WoW client AddOns directory:
   ```
   World of Warcraft/_forever_/Interface/AddOns/BleakfibersAddonConfig-Forever
   ```
5. Launch World of Warcraft, press `Escape`, and click `Bleakfiber's Config` or type `/bac`.

---

## 🌌 Bleakfiber Addon Suite Ecosystem

Bleakfiber's Addon Config serves as the central hub for the entire **Bleakfiber Addon Suite**:

* **[Bleakfiber's Action Bars](https://github.com/Bleakfiber/BleakfibersActionBars-Forever)**: Minimalist action bar suite with bags container, totem bars, and cooldown pulse.
* **[Bleakfiber's Quest Tracker](https://github.com/Bleakfiber/BleakfibersQuestTracker-Forever)**: High-performance quest tracker with 360° Wayfinder navigation and interactive quest items.
* **[Bleakfiber's Maps](https://github.com/Bleakfiber/BleakfibersMaps-Forever)**: Lightweight world map and minimap customization suite.
* **[Bleakfiber's Unit Toggles](https://github.com/Bleakfiber/BleakfibersUnitToggles-Forever)**: Instant Blizzard unit name & nameplate toggle suite with 20 CVar presets.

---

## 📜 License & Support

* **License**: Restricted - Source-Available (All Rights Reserved, No Derivatives). See [LICENSE.md](LICENSE.md) for full terms.
* **Issues & Feedback**: Encounter a bug or have a feature request? Open an issue on our [GitHub Issue Tracker](https://github.com/Bleakfiber/BleakfibersAddonConfig-Forever/issues).
* **Author**: Bleakfiber

