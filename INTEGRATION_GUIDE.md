# Bleakfiber's Addon Config - Third-Party Developer Integration Guide

This guide provides everything third-party and community addon developers need to hook their addon configurations, mover systems, and profile handlers into **Bleakfiber's Addon Config - Forever** (Target Interface: `16001` / World of Warcraft Forever).

---

## 📑 Table of Contents

- [1. Overview & Architecture](#1-overview--architecture)
- [2. Why Integrate with Bleakfiber's Addon Config?](#2-why-integrate-with-bleakfibers-addon-config)
- [3. Soft-Linking Pattern (Zero Mandatory Dependencies)](#3-soft-linking-pattern-zero-mandatory-dependencies)
- [4. The Core Public API: `BAC:RegisterModule`](#4-the-core-public-api-bacregistermodule)
- [5. Building Your Options UI (`buildUI`)](#5-building-your-options-ui-buildui)
  - [Approach A: Using the Shared `BAC.UI` Toolkit (Recommended)](#approach-a-using-the-shared-bacui-toolkit-recommended)
  - [Approach B: Embedding an Existing AceGUI / Custom Frame](#approach-b-embedding-an-existing-acegui--custom-frame)
- [6. Integrating with Master Movers (`/bac mover`)](#6-integrating-with-master-movers-bac-mover)
- [7. Integrating with Cross-Addon Profile Sync](#7-integrating-with-cross-addon-profile-sync)
- [8. Slash Command Redirection](#8-slash-command-redirection)
- [9. Complete Copy-Pasteable Boilerplate Examples](#9-complete-copy-pasteable-boilerplate-examples)
  - [Example 1: Pure Native Lua Addon (Zero Libraries)](#example-1-pure-native-lua-addon-zero-libraries)
  - [Example 2: Ace3-Based Addon (AceDB-3.0 & AceConfig-3.0)](#example-2-ace3-based-addon-acedb-30--aceconfig-30)

---

## 1. Overview & Architecture

**Bleakfiber's Addon Config** (`BleakfibersAddonConfig-Forever` / `BAC`) is a centralized configuration manager and UI orchestrator for World of Warcraft.

Key capabilities available to registered addons:
- **Escape Game Menu Integration**: Adds a stylized `Bleakfiber's Config` button directly inside the native Blizzard Game Menu (`GameMenuFrame`) below Macros/Options with built-in combat lockdown protection.
- **Categorized Sidebar Navigation**: Automatically categorizes official suite modules under `BLEAKFIBER'S` and community modules under `OTHER ADDONS`.
- **Unified Master Movers**: Coordinates frame dragging and repositioning across all installed addons simultaneously (`/bac mover`), while hiding redundant individual addon mover modes.
- **Synchronized, Non-Destructive Profiles**: Automatically synchronizes profile switching across all registered addons in lockstep without overwriting or wiping existing user configurations.
- **Shared Widget Toolkit (`BAC.UI`)**: Full suite of pre-styled Dark Slate & Gold UI widgets (checkboxes, sliders, dropdowns, color pickers, editboxes, and smart auto-hiding scrollbars).

---

## 2. Why Integrate with Bleakfiber's Addon Config?

1. **Effortless Discovery**: Players can open your configuration directly from the Escape menu without having to remember custom slash commands.
2. **Zero UI Boilerplate**: You don't need to build movable standalone frames, title bars, close buttons, or backdrop textures—BAC handles the window shell.
3. **Consistent Visual Polish**: Consume the `BAC.UI` toolkit to get professional Dark Slate & Gold styling matching the modern UI standard.
4. **Coordinated On-Screen Layout**: Players can align all their UI elements at once using `/bac mover`.
5. **Completely Optional (Soft Dependency)**: Your addon can remain 100% standalone and operational if BAC is not installed.

---

## 3. Soft-Linking Pattern (Zero Mandatory Dependencies)

**Never list `BleakfibersAddonConfig-Forever` as a `## Dependencies:` in your `.toc`.** 

Instead, declare it under `## OptionalDeps:` so your addon loads normally whether BAC is installed or not:

```toc
## Interface: 16001
## Title: My Awesome Addon
## Notes: A high-performance utility addon for WoW Forever.
## Author: YourName
## Version: 1.0.0
## SavedVariables: MyAwesomeAddonDB
## OptionalDeps: BleakfibersAddonConfig-Forever
```

In your Lua code, listen for either your addon or BAC loading:

```lua
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "MyAwesomeAddon" or addonName == "BleakfibersAddonConfig-Forever" then
        if BleakfibersAddonConfigForever and BleakfibersAddonConfigForever.RegisterModule then
            -- Hook into BAC
            RegisterWithBAC()
        end
    end
end)
```

---

## 4. The Core Public API: `BAC:RegisterModule`

To register your addon, call `BleakfibersAddonConfigForever:RegisterModule(moduleID, moduleData)`.

### Method Signature
```lua
BleakfibersAddonConfigForever:RegisterModule(moduleID, moduleData)
```

### Parameters

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `moduleID` | `string` | **Yes** | Unique identifier for your module (e.g., `"MyAddon"`). |
| `name` | `string` | No | Full display title shown in the content header (defaults to `moduleID`). |
| `sidebarName` | `string` | No | Short name displayed on the left sidebar tab button (defaults to `name`). |
| `author` | `string` | No | Addon author. If not `"Bleakfiber"`, your module is automatically filed under the styled **OTHER ADDONS** sidebar group. |
| `isBleakfiber` | `boolean` | No | Explicit flag. Set to `false` for community/third-party addons. |
| `description` | `string` | No | Optional subtitle or tooltip summary. |
| `db` | `table` | No | Direct reference to your addon's `SavedVariables` table. |
| `buildUI` | `function(container, isMasterHub)` | **Yes** | Callback that creates and anchors your UI controls inside `container`. |
| `refresh` | `function()` | No | Callback invoked when the user clicks the "Refresh" button or switches active profiles. |
| `movers` / `toggleMovers` | `function(state)` | No | Callback to show/hide your on-screen frame movers. |
| `resetMovers` | `function()` | No | Callback to reset your frame positions to defaults. |
| `isMoversUnlocked` | `function()` | No | Callback returning boolean `true` if your movers are currently visible. |
| `profiles` | `table` | No | Table containing profile synchronization handlers (see Section 7). |

---

## 5. Building Your Options UI (`buildUI`)

When the user clicks your tab in the BAC sidebar, BAC creates a clean content container frame and calls your `buildUI(container, isMasterHub)` function.

* `container`: A standard WoW `Frame` pre-anchored to the content area (`~530px` to `1000px` width, `~430px` to `750px` height).
* `isMasterHub`: Always `true` when invoked by BAC.

---

### Approach A: Using the Shared `BAC.UI` Toolkit (Recommended)

When BAC is loaded, `BleakfibersAddonConfigForever.UI` (`BAC.UI`) exports ready-to-use widget factory methods:

```lua
local BAC = BleakfibersAddonConfigForever

local function BuildMyUI(container, isMasterHub)
    local Kit = BAC.UI

    -- 1. Section Header
    Kit:CreateSectionHeader(container, "General Settings", 16, -16)

    -- 2. Checkbox
    -- Parameters: (parent, name, labelText, x, y, getFunc, setFunc, [tooltip])
    Kit:CreateCheckbox(container, "MyAddon_CbEnable", "Enable Addon", 16, -44,
        function() return MyAddonDB.enabled end,
        function(val) MyAddonDB.enabled = val; MyAddon:UpdateState() end,
        "Toggle whether MyAddon is active."
    )

    -- 3. Slider
    -- Parameters: (parent, name, labelText, minVal, maxVal, step, x, y, getFunc, setFunc, [formatStr])
    Kit:CreateSlider(container, "MyAddon_SliderScale", "Frame Scale", 0.5, 2.0, 0.05, 16, -88,
        function() return MyAddonDB.scale or 1.0 end,
        function(val) MyAddonDB.scale = val; MyAddon:SetScale(val) end,
        "%.2f"
    )

    -- 4. Dropdown Menu
    -- Parameters: (parent, name, labelText, itemsTable, x, y, width, getFunc, setFunc)
    local fontOptions = { ["Friz"] = "Friz Quadrata", ["Arial"] = "Arial Narrow", ["Skurri"] = "Skurri" }
    Kit:CreateDropdown(container, "MyAddon_DdFont", "Display Font", fontOptions, 16, -142, 160,
        function() return MyAddonDB.font or "Friz" end,
        function(val) MyAddonDB.font = val; MyAddon:SetFont(val) end
    )

    -- 5. Color Picker
    -- Parameters: (parent, name, labelText, x, y, getFunc, setFunc)
    Kit:CreateColorPicker(container, "MyAddon_CpColor", "Border Color", 16, -196,
        function() return MyAddonDB.color or { r = 1, g = 0.82, b = 0 } end,
        function(c) MyAddonDB.color = c; MyAddon:UpdateColor(c) end
    )

    -- 6. EditBox
    -- Parameters: (parent, name, labelText, x, y, width, getFunc, setFunc)
    Kit:CreateEditBox(container, "MyAddon_EbPrefix", "Chat Prefix", 16, -240, 180,
        function() return MyAddonDB.prefix or "[MyAddon]" end,
        function(txt) MyAddonDB.prefix = txt end
    )

    -- 7. Action Button
    -- Parameters: (parent, name, text, x, y, width, height, onClick)
    Kit:CreateButton(container, "MyAddon_BtnReset", "Reset to Defaults", 16, -284, 140, 24, function()
        MyAddon:ResetDefaults()
        if container.refresh then container:refresh() end
    end)
end
```

#### Smart Auto-Hiding Scrollbar
If your options page has more vertical content than fits on screen, wrap your controls in a standard `ScrollFrame` and pass it to `BAC.UI:SetupAutoScroll`:
```lua
local scrollFrame = CreateFrame("ScrollFrame", "MyAddonScrollFrame", container, "UIPanelScrollFrameTemplate")
scrollFrame:SetAllPoints(container)
local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(container:GetWidth() - 24, 600)
scrollFrame:SetScrollChild(scrollChild)

-- Automatically hides scrollbar & disables mousewheel when child fits in frame!
BAC.UI:SetupAutoScroll(scrollFrame, scrollChild)
```

---

### Approach B: Embedding an Existing AceGUI / Custom Frame

If your addon already uses `AceGUI-3.0` or `AceConfigDialog-3.0`, you can embed your existing options table directly inside BAC's `container`:

```lua
local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)

local function BuildMyUI(container, isMasterHub)
    if AceConfigDialog then
        -- Open your registered AceConfig table directly inside BAC's container frame
        AceConfigDialog:Open("MyAddonConfig", container)
    end
end
```

---

## 6. Integrating with Master Movers (`/bac mover`)

When players use **Bleakfiber's Addon Config**, they love the ability to unlock all on-screen frames simultaneously with `/bac mover` or by clicking the "Movers" button in the content header.

To participate in master movers, provide:
1. `toggleMovers(state)`: Function that receives boolean `true` (unlock/show movers) or `false` (lock/hide movers).
2. `resetMovers()`: Function that restores your frames to their default screen coordinates.
3. `isMoversUnlocked()`: Function returning boolean `true` if your frames are currently unlocked.

### Position Symmetry & Drift Prevention
When saving dragged frames, **always preserve `relativePoint` (`relPoint`)** to eliminate coordinate drift across screen resolutions:

```lua
function MyAddon:SaveMover(moverFrame)
    local point, relativeTo, relPoint, xOfs, yOfs = moverFrame:GetPoint(1)
    if not point then return end

    MyAddonDB.pos = {
        point = point,
        relPoint = relPoint or point, -- Critical for symmetry!
        x = math.floor(xOfs + 0.5),
        y = math.floor(yOfs + 0.5),
    }
end

function MyAddon:RestorePosition(targetFrame)
    local pos = MyAddonDB.pos
    if not pos then return end

    targetFrame:ClearAllPoints()
    targetFrame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x, pos.y)
end
```

---

## 7. Integrating with Cross-Addon Profile Sync

BAC provides a centralized **Master Profile** selector. When the player switches to "Healer" or "PvP", BAC notifies all registered addons.

### The Non-Destructive Profile Contract
**Rule: Never wipe existing settings to defaults when creating a new profile.**
When `Create(profileKey)` is invoked, copy the active running configuration into the new profile key so the user never loses their setup.

```lua
local profileHooks = {
    -- Return current active profile name string
    GetCurrent = function()
        return MyAddonDB.activeProfile or "Default"
    end,

    -- Switch to named profile
    SetCurrent = function(profileKey)
        if not MyAddonDB.profiles[profileKey] then
            -- Safe clone if profile doesn't exist yet
            MyAddonDB.profiles[profileKey] = CopyTable(MyAddonDB.profiles[MyAddonDB.activeProfile] or DEFAULT_SETTINGS)
        end
        MyAddonDB.activeProfile = profileKey
        MyAddon:ApplySettings()
    end,

    -- Return table array of all profile names: { "Default", "PvP", "Raid" }
    List = function()
        local list = {}
        for name in pairs(MyAddonDB.profiles) do
            table.insert(list, name)
        end
        return list
    end,

    -- Create new profile (NON-DESTRUCTIVE: clone current settings!)
    Create = function(profileKey)
        if not MyAddonDB.profiles[profileKey] then
            MyAddonDB.profiles[profileKey] = CopyTable(MyAddonDB.profiles[MyAddonDB.activeProfile] or DEFAULT_SETTINGS)
        end
        MyAddonDB.activeProfile = profileKey
        MyAddon:ApplySettings()
    end,

    -- Delete a profile
    Delete = function(profileKey)
        if profileKey ~= "Default" then
            MyAddonDB.profiles[profileKey] = nil
            if MyAddonDB.activeProfile == profileKey then
                MyAddonDB.activeProfile = "Default"
                MyAddon:ApplySettings()
            end
        end
    end,

    -- Copy settings from one profile to another
    Copy = function(fromKey, toKey)
        if MyAddonDB.profiles[fromKey] then
            MyAddonDB.profiles[toKey] = CopyTable(MyAddonDB.profiles[fromKey])
            MyAddon:ApplySettings()
        end
    end,

    -- Reset a profile to factory defaults
    Reset = function(profileKey)
        MyAddonDB.profiles[profileKey] = CopyTable(DEFAULT_SETTINGS)
        MyAddon:ApplySettings()
    end,
}
```

---

## 8. Slash Command Redirection

If the player types your addon's slash command (e.g. `/myaddon` or `/myaddon config`), you can open BAC directly to your addon's tab:

```lua
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    msg = msg and msg:lower():trim() or ""

    if msg == "mover" then
        MyAddon:ToggleMovers()
    elseif BleakfibersAddonConfigForever and BleakfibersAddonConfigForever.SelectModule then
        -- Open BAC and navigate straight to your addon tab!
        BleakfibersAddonConfigForever:ShowUI()
        BleakfibersAddonConfigForever:SelectModule("MyAddon")
    else
        -- Fallback if BAC is not installed: print help or open your own window
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[MyAddon]|r Install Bleakfiber's Addon Config for graphical settings.")
    end
end
```

---

## 9. Complete Copy-Pasteable Boilerplate Examples

### Example 1: Pure Native Lua Addon (Zero Libraries)

Save as `Integration.lua` in your addon folder:

```lua
local ADDON_NAME = "SimpleClock"
local DISPLAY_TITLE = "Simple Clock"

local function InitBAC()
    if not (BleakfibersAddonConfigForever and BleakfibersAddonConfigForever.RegisterModule) then
        return
    end

    BleakfibersAddonConfigForever:RegisterModule(ADDON_NAME, {
        name = DISPLAY_TITLE,
        sidebarName = DISPLAY_TITLE,
        author = "CommunityAuthor",
        isBleakfiber = false, -- Lands cleanly under "OTHER ADDONS"
        description = "Lightweight on-screen digital clock.",
        db = SimpleClockDB,

        -- 1. Build the GUI using shared Dark Slate & Gold widgets
        buildUI = function(container, isMasterHub)
            local Kit = BleakfibersAddonConfigForever.UI

            Kit:CreateSectionHeader(container, "Clock Display Settings", 16, -16)

            Kit:CreateCheckbox(container, "SC_Cb24Hr", "Use 24-Hour Time Format", 16, -44,
                function() return SimpleClockDB.use24Hour end,
                function(val) SimpleClockDB.use24Hour = val; SimpleClock:Update() end,
                "Toggle between 12-hour (AM/PM) and 24-hour military time."
            )

            Kit:CreateSlider(container, "SC_SliderScale", "Clock Scale", 0.5, 2.5, 0.1, 16, -88,
                function() return SimpleClockDB.scale or 1.0 end,
                function(val) SimpleClockDB.scale = val; SimpleClock:SetScale(val) end,
                "%.1f"
            )
        end,

        -- 2. Master Mover Integration
        toggleMovers = function(state) SimpleClock:ToggleMover(state) end,
        resetMovers  = function() SimpleClock:ResetPosition() end,
        isMoversUnlocked = function() return SimpleClock.isUnlocked end,

        -- 3. Live Refresh
        refresh = function()
            SimpleClock:Update()
        end,
    })
end

-- Registration Event Listener
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == ADDON_NAME or name == "BleakfibersAddonConfig-Forever" then
        InitBAC()
    end
end)
```

---

### Example 2: Ace3-Based Addon (AceDB-3.0 & AceConfig-3.0)

```lua
local ADDON_NAME = "AceTracker"
local DISPLAY_TITLE = "Ace Tracker"

local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)

local function RegisterAceWithBAC()
    if not (BleakfibersAddonConfigForever and BleakfibersAddonConfigForever.RegisterModule) then
        return
    end

    BleakfibersAddonConfigForever:RegisterModule(ADDON_NAME, {
        name = DISPLAY_TITLE,
        sidebarName = DISPLAY_TITLE,
        author = "CommunityAuthor",
        isBleakfiber = false,
        db = AceTracker.db and AceTracker.db.profile,

        -- Embed existing AceConfig table directly into BAC content pane!
        buildUI = function(container, isMasterHub)
            if AceConfigDialog then
                AceConfigDialog:Open("AceTracker", container)
            end
        end,

        -- Synchronize with AceDB-3.0 profiles!
        profiles = {
            GetCurrent = function() return AceTracker.db:GetCurrentProfile() end,
            SetCurrent = function(p) AceTracker.db:SetProfile(p) end,
            List       = function() return AceTracker.db:GetProfiles() end,
            Create     = function(p) AceTracker.db:SetProfile(p) end,
            Delete     = function(p) AceTracker.db:DeleteProfile(p) end,
            Copy       = function(from) AceTracker.db:CopyProfile(from) end,
            Reset      = function() AceTracker.db:ResetProfile() end,
        },

        refresh = function()
            if AceTracker.UpdateUI then AceTracker:UpdateUI() end
        end,
    })
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == ADDON_NAME or name == "BleakfibersAddonConfig-Forever" then
        RegisterAceWithBAC()
    end
end)
```

---

## 10. Summary & Support

By integrating with **Bleakfiber's Addon Config**, your addon gains:
* Native visibility in the Escape Game Menu.
* Dedicated listing in the **OTHER ADDONS** sidebar.
* Support for global `/bac mover` positioning.
* Synchronized, non-destructive profile management.
* Zero external library overhead.

For questions, reference implementations, or pull requests, visit the official [Bleakfiber Addon Suite GitHub](https://github.com/Bleakfiber).
