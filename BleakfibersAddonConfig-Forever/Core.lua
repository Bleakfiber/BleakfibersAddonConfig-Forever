--[[
    Bleakfiber's Addon Config - Forever
    Core.lua - Namespace, Module Registry, Event Handling & Slash Commands
]]

-- Global namespace
BleakfibersAddonConfigForever = BleakfibersAddonConfigForever or {}
local BAC = BleakfibersAddonConfigForever

-- Module registry and ordered keys
BAC.modules = {}
BAC.moduleOrder = {}
BAC.version = "1.0.07"

-- Database defaults
local DB_DEFAULTS = {
    width = 760,
    height = 520,
    point = "CENTER",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = 0,
    lastTab = nil,
    activeProfile = "Default",
    profiles = { ["Default"] = true },
}

--[[-----------------------------------------------------------------------------
    Public API: RegisterModule
    @param moduleID   string: Unique identifier for the module (e.g. "BleakHUD")
    @param moduleData table: Module configuration table
           {
               name    = string (Display title for the sidebar),
               db      = table (Reference to child addon's SavedVariables),
               refresh = function() (Callback to redraw or refresh child UI on live changes),
               buildUI = function(parentFrame) (Draws controls inside container frame),
           }
-------------------------------------------------------------------------------]]
function BAC:RegisterModule(moduleID, moduleData)
    if not moduleID or type(moduleID) ~= "string" or moduleID == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[Bleakfiber's Addon Config]|r Error: Invalid moduleID provided.")
        return false
    end

    if type(moduleData) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Error: Module '%s' data must be a table.", moduleID))
        return false
    end

    if type(moduleData.buildUI) ~= "function" then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Error: Module '%s' must supply a 'buildUI' function.", moduleID))
        return false
    end

    -- Assign default display name if omitted
    moduleData.name = moduleData.name or moduleID
    moduleData.id = moduleID

    -- Determine creator category (Bleakfiber vs other creator)
    if moduleData.isBleakfiber == nil then
        if moduleData.author then
            local authLower = moduleData.author:lower()
            moduleData.isBleakfiber = (authLower:find("bleakfiber") ~= nil or authLower:find("bleak") ~= nil)
        else
            local idLower = moduleID:lower()
            local nameLower = moduleData.name:lower()
            moduleData.isBleakfiber = (idLower:find("bleak") ~= nil or nameLower:find("bleak") ~= nil)
        end
    end

    -- Mover hooks normalization (supports both nested 'movers' table and flat keys)
    if type(moduleData.movers) == "table" then
        moduleData.toggleMovers = moduleData.toggleMovers or moduleData.movers.Toggle or moduleData.movers.toggle
        moduleData.resetMovers = moduleData.resetMovers or moduleData.movers.Reset or moduleData.movers.reset
        moduleData.isMoversUnlocked = moduleData.isMoversUnlocked or moduleData.movers.IsUnlocked or moduleData.movers.isUnlocked
    end

    -- Automatically sync into _G.Bleakfibers_MoversRegistry if movers are supported
    if moduleData.toggleMovers then
        _G.Bleakfibers_MoversRegistry = _G.Bleakfibers_MoversRegistry or {}
        _G.Bleakfibers_MoversRegistry[moduleID] = {
            name = moduleData.name,
            sidebarName = moduleData.sidebarName,
            Toggle = moduleData.toggleMovers,
            Reset = moduleData.resetMovers,
            IsUnlocked = moduleData.isMoversUnlocked,
        }
    end

    -- Sync active master profile to the newly registered module if supported
    local activeProf = (BleakfibersConfigDB and BleakfibersConfigDB.activeProfile) or "Default"
    if moduleData.profiles and type(moduleData.profiles.SetCurrent) == "function" then
        pcall(moduleData.profiles.SetCurrent, activeProf)
    elseif moduleData.setProfile and type(moduleData.setProfile) == "function" then
        pcall(moduleData.setProfile, activeProf)
    end

    -- Track insertion order
    if not self.modules[moduleID] then
        table.insert(self.moduleOrder, moduleID)
    end

    self.modules[moduleID] = moduleData

    -- If UI is already instantiated, refresh sidebar navigation
    if self.RefreshSidebar then
        self:RefreshSidebar()
    end

    -- If UI is currently open and this module was the last opened tab, or none selected, re-evaluate selection
    if self.frame and self.frame:IsShown() and not self.selectedModuleID then
        if BleakfibersConfigDB and BleakfibersConfigDB.lastTab == moduleID then
            self:SelectModule(moduleID)
        end
    end

    return true
end

--[[-----------------------------------------------------------------------------
    Public API: Queries
-------------------------------------------------------------------------------]]
function BAC:GetModule(moduleID)
    return self.modules[moduleID]
end

function BAC:GetModules()
    return self.modules
end

function BAC:GetModuleOrder()
    return self.moduleOrder
end

function BAC:IsBleakfiberModule(moduleID)
    local mod = self.modules[moduleID]
    return mod and (mod.isBleakfiber == true) or false
end

function BAC:GetSortedModuleList()
    local bleakfiberList = {}
    local otherList = {}

    for _, id in ipairs(self.moduleOrder) do
        local mod = self.modules[id]
        if mod then
            if mod.isBleakfiber then
                table.insert(bleakfiberList, id)
            else
                table.insert(otherList, id)
            end
        end
    end

    local function SortByName(a, b)
        local modA = self.modules[a]
        local modB = self.modules[b]
        local nameA = (modA and (modA.sidebarName or modA.name)) or a or ""
        local nameB = (modB and (modB.sidebarName or modB.name)) or b or ""
        return nameA:lower() < nameB:lower()
    end

    table.sort(bleakfiberList, SortByName)
    table.sort(otherList, SortByName)

    local sorted = {}
    for _, id in ipairs(bleakfiberList) do
        table.insert(sorted, id)
    end
    for _, id in ipairs(otherList) do
        table.insert(sorted, id)
    end

    return sorted, bleakfiberList, otherList
end

--[[-----------------------------------------------------------------------------
    Global Cross-Addon Movers System
-------------------------------------------------------------------------------]]
_G.Bleakfibers_MoversRegistry = _G.Bleakfibers_MoversRegistry or {}
BAC.moversUnlocked = false

function BAC:AreMoversUnlocked()
    if self.moversUnlocked then return true end

    -- Check registered modules
    for _, mod in pairs(self.modules) do
        if mod.isMoversUnlocked and type(mod.isMoversUnlocked) == "function" then
            local ok, unlocked = pcall(mod.isMoversUnlocked)
            if ok and unlocked then return true end
        end
    end

    -- Check global movers registry
    if _G.Bleakfibers_MoversRegistry then
        for _, entry in pairs(_G.Bleakfibers_MoversRegistry) do
            if entry.IsUnlocked and type(entry.IsUnlocked) == "function" then
                local ok, unlocked = pcall(entry.IsUnlocked)
                if ok and unlocked then return true end
            end
        end
    end

    return false
end

function BAC:ToggleAllMovers(forceState)
    local newState
    if forceState ~= nil then
        newState = forceState
    else
        newState = not self:AreMoversUnlocked()
    end

    self.moversUnlocked = newState

    local affectedCount = 0

    -- 1. Hook into registered BAC modules
    for id, mod in pairs(self.modules) do
        if mod.toggleMovers and type(mod.toggleMovers) == "function" then
            pcall(mod.toggleMovers, newState)
            affectedCount = affectedCount + 1
        end
    end

    -- 2. Hook into _G.Bleakfibers_MoversRegistry
    if _G.Bleakfibers_MoversRegistry then
        for key, entry in pairs(_G.Bleakfibers_MoversRegistry) do
            if entry.Toggle and type(entry.Toggle) == "function" then
                pcall(entry.Toggle, newState)
                affectedCount = affectedCount + 1
            end
        end
    end

    -- Update UI button states if window is open
    if self.UpdateMoverButtonState then
        self:UpdateMoverButtonState()
    end

    local statusMsg = newState and "|cFF00FF00UNLOCKED|r (drag frames to reposition)" or "|cFFFF2020LOCKED|r"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Movers are now %s.", statusMsg))

    return newState, affectedCount
end

function BAC:ResetAllMovers()
    local resetCount = 0

    for id, mod in pairs(self.modules) do
        if mod.resetMovers and type(mod.resetMovers) == "function" then
            pcall(mod.resetMovers)
            resetCount = resetCount + 1
        end
    end

    if _G.Bleakfibers_MoversRegistry then
        for key, entry in pairs(_G.Bleakfibers_MoversRegistry) do
            if entry.Reset and type(entry.Reset) == "function" then
                pcall(entry.Reset)
                resetCount = resetCount + 1
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[Bleakfiber's Addon Config]|r All addon movers reset to default positions.")
    return resetCount
end

--[[-----------------------------------------------------------------------------
    Master Profile Synchronization API
-------------------------------------------------------------------------------]]
function BAC:GetActiveProfile()
    return (BleakfibersConfigDB and BleakfibersConfigDB.activeProfile) or "Default"
end

function BAC:GetProfiles()
    local list = {}
    if BleakfibersConfigDB and BleakfibersConfigDB.profiles then
        for profileName in pairs(BleakfibersConfigDB.profiles) do
            table.insert(list, profileName)
        end
    end
    if #list == 0 then
        table.insert(list, "Default")
    end
    table.sort(list)
    return list
end

function BAC:SetActiveProfile(profileKey)
    if not profileKey or type(profileKey) ~= "string" or profileKey == "" then return end

    if not BleakfibersConfigDB then BleakfibersConfigDB = {} end
    if not BleakfibersConfigDB.profiles then BleakfibersConfigDB.profiles = { ["Default"] = true } end

    BleakfibersConfigDB.profiles[profileKey] = true
    BleakfibersConfigDB.activeProfile = profileKey

    local syncedCount = 0

    -- Broadcast to all registered modules
    for id, mod in pairs(self.modules) do
        local handled = false
        if mod.profiles and type(mod.profiles.SetCurrent) == "function" then
            pcall(mod.profiles.SetCurrent, profileKey)
            handled = true
        elseif mod.setProfile and type(mod.setProfile) == "function" then
            pcall(mod.setProfile, profileKey)
            handled = true
        end

        if handled then
            syncedCount = syncedCount + 1
            if mod.refresh and type(mod.refresh) == "function" then
                pcall(mod.refresh)
            end
        end
    end

    if self.UpdateProfileUI then
        self:UpdateProfileUI()
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Active profile set to '|cFF00FF00%s|r' (%d addons synced).", profileKey, syncedCount))
end

function BAC:CreateProfile(profileKey)
    if not profileKey or type(profileKey) ~= "string" or profileKey == "" then return end

    if not BleakfibersConfigDB then BleakfibersConfigDB = {} end
    if not BleakfibersConfigDB.profiles then BleakfibersConfigDB.profiles = { ["Default"] = true } end

    BleakfibersConfigDB.profiles[profileKey] = true

    -- Notify modules that support Create
    for id, mod in pairs(self.modules) do
        if mod.profiles and type(mod.profiles.Create) == "function" then
            pcall(mod.profiles.Create, profileKey)
        end
    end

    self:SetActiveProfile(profileKey)
end

function BAC:SaveCurrentAsProfile(profileKey)
    if not profileKey or type(profileKey) ~= "string" or profileKey == "" then return end

    local fromProf = self:GetActiveProfile()
    if not BleakfibersConfigDB then BleakfibersConfigDB = {} end
    if not BleakfibersConfigDB.profiles then BleakfibersConfigDB.profiles = { ["Default"] = true } end

    BleakfibersConfigDB.profiles[profileKey] = true

    -- Broadcast save current / copy to all registered modules
    for id, mod in pairs(self.modules) do
        if mod.profiles then
            if type(mod.profiles.SaveCurrentAs) == "function" then
                pcall(mod.profiles.SaveCurrentAs, profileKey)
            elseif type(mod.profiles.Copy) == "function" then
                pcall(mod.profiles.Copy, fromProf, profileKey)
            elseif type(mod.profiles.Create) == "function" then
                pcall(mod.profiles.Create, profileKey, fromProf)
            end
        end
    end

    self:SetActiveProfile(profileKey)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Saved current settings as new profile '|cFF00FF00%s|r'.", profileKey))
end

function BAC:DeleteProfile(profileKey)
    if not profileKey or profileKey == "Default" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[Bleakfiber's Addon Config]|r Cannot delete the Default profile.")
        return
    end

    if BleakfibersConfigDB and BleakfibersConfigDB.profiles then
        BleakfibersConfigDB.profiles[profileKey] = nil
    end

    -- Notify modules
    for id, mod in pairs(self.modules) do
        if mod.profiles and type(mod.profiles.Delete) == "function" then
            pcall(mod.profiles.Delete, profileKey)
        end
    end

    if BleakfibersConfigDB.activeProfile == profileKey then
        self:SetActiveProfile("Default")
    else
        if self.UpdateProfileUI then
            self:UpdateProfileUI()
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Profile '%s' deleted.", profileKey))
end

function BAC:CopyProfile(fromKey, toKey)
    if not fromKey or not toKey then return end

    for id, mod in pairs(self.modules) do
        if mod.profiles and type(mod.profiles.Copy) == "function" then
            pcall(mod.profiles.Copy, fromKey, toKey)
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Copied profile '%s' to '%s'.", fromKey, toKey))
end

function BAC:ResetProfile(profileKey)
    profileKey = profileKey or self:GetActiveProfile()

    for id, mod in pairs(self.modules) do
        if mod.profiles and type(mod.profiles.Reset) == "function" then
            pcall(mod.profiles.Reset, profileKey)
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[Bleakfiber's Addon Config]|r Reset profile '%s' to defaults across all addons.", profileKey))
end

--[[-----------------------------------------------------------------------------
    UI Control Methods
-------------------------------------------------------------------------------]]
function BAC:ToggleUI()
    if not self.frame then
        if self.CreateMasterFrame then
            self:CreateMasterFrame()
        end
        if self.frame then
            self.frame:Show()
            return
        end
    end

    if self.frame then
        if self.frame:IsShown() then
            self.frame:Hide()
        else
            self.frame:Show()
        end
    end
end

function BAC:ShowUI()
    if not self.frame then
        if self.CreateMasterFrame then
            self:CreateMasterFrame()
        end
    end

    if self.frame then
        self.frame:Show()
    end
end

function BAC:HideUI()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    end
end

--[[-----------------------------------------------------------------------------
    Event Handling & SavedVariables Initialization
-------------------------------------------------------------------------------]]
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BleakfibersAddonConfig-Forever" then
        -- Initialize SavedVariables with defaults
        if type(BleakfibersConfigDB) ~= "table" then
            BleakfibersConfigDB = {}
        end

        for key, defaultValue in pairs(DB_DEFAULTS) do
            if BleakfibersConfigDB[key] == nil then
                BleakfibersConfigDB[key] = defaultValue
            end
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100Bleakfiber's Addon Config - Forever|r v" .. BAC.version .. " loaded. Type |cFF00FF00/bac|r or |cFF00FF00/bleakfiber|r to open.")

    elseif event == "PLAYER_LOGOUT" then
        -- Persist last window state if frame exists
        if BAC.frame and BleakfibersConfigDB then
            local point, _, relPoint, xOfs, yOfs = BAC.frame:GetPoint()
            if point then
                BleakfibersConfigDB.point = point
                BleakfibersConfigDB.relativePoint = relPoint or point
                BleakfibersConfigDB.xOfs = math.floor(xOfs + 0.5)
                BleakfibersConfigDB.yOfs = math.floor(yOfs + 0.5)
            end
            BleakfibersConfigDB.width = math.floor(BAC.frame:GetWidth() + 0.5)
            BleakfibersConfigDB.height = math.floor(BAC.frame:GetHeight() + 0.5)
            if BAC.selectedModuleID then
                BleakfibersConfigDB.lastTab = BAC.selectedModuleID
            end
        end
    end
end)

--[[-----------------------------------------------------------------------------
    Slash Commands: /bac, /bleakfiber
-------------------------------------------------------------------------------]]
SLASH_BLEAKFIBERSCONFIG1 = "/bac"
SLASH_BLEAKFIBERSCONFIG2 = "/bleakfiber"

SlashCmdList["BLEAKFIBERSCONFIG"] = function(msg)
    msg = msg and string.trim and string.trim(msg:lower()) or (msg and msg:lower() or "")
    if msg == "reset" then
        if BleakfibersConfigDB then
            for key, val in pairs(DB_DEFAULTS) do
                BleakfibersConfigDB[key] = val
            end
        end
        if BAC.frame then
            BAC.frame:ClearAllPoints()
            BAC.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            BAC.frame:SetSize(DB_DEFAULTS.width, DB_DEFAULTS.height)
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[Bleakfiber's Addon Config]|r Window position and size have been reset.")
    elseif msg == "move" or msg == "movers" or msg == "unlock" then
        BAC:ToggleAllMovers()
    elseif msg == "lock" then
        BAC:ToggleAllMovers(false)
    elseif msg == "resetmovers" or msg == "resetmover" then
        BAC:ResetAllMovers()
    elseif msg:find("^profile%s+") then
        local prof = msg:match("^profile%s+(.+)$")
        if prof and prof ~= "" then BAC:SetActiveProfile(prof) end
    elseif msg:find("^newprofile%s+") then
        local prof = msg:match("^newprofile%s+(.+)$")
        if prof and prof ~= "" then BAC:CreateProfile(prof) end
    elseif msg:find("^saveprofile%s+") or msg:find("^saveas%s+") then
        local prof = msg:match("^%a+%s+(.+)$")
        if prof and prof ~= "" then BAC:SaveCurrentAsProfile(prof) end
    elseif msg:find("^delprofile%s+") then
        local prof = msg:match("^delprofile%s+(.+)$")
        if prof and prof ~= "" then BAC:DeleteProfile(prof) end
    elseif msg == "profiles" then
        local list = BAC:GetProfiles()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[Bleakfiber's Addon Config]|r Available Profiles: " .. table.concat(list, ", ") .. " (Active: " .. BAC:GetActiveProfile() .. ")")
    else
        BAC:ToggleUI()
    end
end
