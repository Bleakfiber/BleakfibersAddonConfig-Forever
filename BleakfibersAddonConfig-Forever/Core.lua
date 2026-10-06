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
BAC.version = "1.0.01"

-- Database defaults
local DB_DEFAULTS = {
    width = 760,
    height = 520,
    point = "CENTER",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = 0,
    lastTab = nil,
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

--[[-----------------------------------------------------------------------------
    UI Control Methods
-------------------------------------------------------------------------------]]
function BAC:ToggleUI()
    if not self.frame then
        if self.CreateMasterFrame then
            self:CreateMasterFrame()
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
    else
        BAC:ToggleUI()
    end
end
