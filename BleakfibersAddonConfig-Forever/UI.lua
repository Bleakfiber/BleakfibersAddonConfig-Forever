--[[
    Bleakfiber's Addon Config - Forever
    UI.lua - Master Frame, Navigation Sidebar, Content Pane & Lazy-loaded Modules
]]

local BAC = BleakfibersAddonConfigForever
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Reusable backdrop definitions
local MAIN_WINDOW_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local INSET_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- UI Color Palette: Dark slate/iron with gold accents
local COLORS = {
    bgSlate      = { 0.08, 0.10, 0.13, 0.96 }, -- Dark iron / slate
    sidebarBg    = { 0.06, 0.07, 0.09, 0.92 }, -- Deep inset background
    contentBg    = { 0.05, 0.06, 0.08, 0.94 }, -- Dark content background
    goldBorder   = { 0.82, 0.68, 0.28, 1.00 }, -- Bright beveled gold
    goldMuted    = { 0.50, 0.42, 0.20, 0.85 }, -- Muted gold border
    goldText     = { 1.00, 0.82, 0.25 },       -- #FFD140
    whiteText    = { 0.90, 0.92, 0.94 },
    dimText      = { 0.55, 0.58, 0.63 },
    tabNormal    = { 0.12, 0.14, 0.17, 0.65 },
    tabHighlight = { 0.20, 0.22, 0.27, 0.80 },
    tabActive    = { 0.22, 0.19, 0.12, 0.95 }, -- Gold-tinted active tab
}

-- Caches for UI frames and tab buttons
BAC.moduleContainers = {}
BAC.tabButtons = {}
BAC.selectedModuleID = nil

--[[-----------------------------------------------------------------------------
    Shared Widget Factory (BAC.UI)
    Exposed publicly so all child addons can inherit pixel-perfect UI widgets
-------------------------------------------------------------------------------]]
BAC.UI = BAC.UI or {}
BAC.UI.COLORS = COLORS
BAC.UI.MAIN_WINDOW_BACKDROP = MAIN_WINDOW_BACKDROP
BAC.UI.INSET_BACKDROP = INSET_BACKDROP

function BAC.UI:CreateSectionHeader(parent, text, pointOrX, relPointOrY, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if y ~= nil then
        header:SetPoint(pointOrX, parent, relPointOrY, x, y)
    else
        local posX = pointOrX or 16
        local posY = relPointOrY or -16
        header:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)
    end
    header:SetText(text)
    header:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    return header
end

local function CreateSectionHeader(parent, text, point, relPoint, x, y)
    return BAC.UI:CreateSectionHeader(parent, text, point, relPoint, x, y)
end

function BAC.UI:CreateDivider(parent, y, width)
    local div = parent:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    if width then
        div:SetWidth(width)
        div:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    else
        div:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
        div:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, y)
    end
    div:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.4)
    return div
end

function BAC.UI:CreateCheckbox(parent, name, labelText, x, y, getFunc, setFunc, tooltip)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb.text = _G[name .. "Text"]
    if cb.text then
        cb.text:SetText(labelText)
        cb.text:SetFontObject("GameFontHighlight")
    end

    cb.getFunc = getFunc
    cb.setFunc = setFunc
    cb:SetChecked(getFunc and getFunc() or false)

    cb:SetScript("OnClick", function(self)
        if self.setFunc then
            self.setFunc(self:GetChecked())
        end
    end)

    if tooltip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(labelText, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return cb
end

function BAC.UI:CreateSlider(parent, name, labelText, minVal, maxVal, step, x, y, getFunc, setFunc, formatStr)
    step = step or 1
    formatStr = formatStr or (step < 1 and "%.1f" or "%d")
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    if slider.SetObeyStepNumbers then
        slider:SetObeyStepNumbers(true)
    end
    slider:SetWidth(180)

    local low = _G[name .. "Low"]
    if low then low:SetText(tostring(minVal)) end
    local high = _G[name .. "High"]
    if high then high:SetText(tostring(maxVal)) end

    slider.getFunc = getFunc
    slider.setFunc = setFunc
    slider.formatStr = formatStr
    slider.labelText = labelText

    local curVal = getFunc and getFunc() or minVal
    local titleText = _G[name .. "Text"]
    if titleText then
        titleText:SetText(labelText .. ": " .. string.format(formatStr, curVal))
    end
    slider:SetValue(curVal)

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        local tt = _G[name .. "Text"]
        if tt then
            tt:SetText(self.labelText .. ": " .. string.format(self.formatStr, val))
        end
        if self.setFunc then
            self.setFunc(val)
        end
    end)

    return slider
end

function BAC.UI:CreateDropdown(parent, name, labelText, items, x, y, width, getFunc, setFunc)
    width = width or 150
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(labelText)
    label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])

    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(dd, width)

    local function OnClick(self)
        UIDropDownMenu_SetSelectedValue(dd, self.value)
        UIDropDownMenu_SetText(dd, items[self.value] or tostring(self.value))
        if setFunc then
            setFunc(self.value)
        end
    end

    local function Init(self, level)
        local cur = getFunc and getFunc()
        for val, text in pairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = text
            info.value = val
            info.func = OnClick
            info.checked = (val == cur)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dd, Init)
    local curVal = getFunc and getFunc()
    UIDropDownMenu_SetSelectedValue(dd, curVal)
    UIDropDownMenu_SetText(dd, items[curVal] or tostring(curVal))

    return dd
end

function BAC.UI:CreateButton(parent, name, text, x, y, width, height, onClick)
    local btn = CreateFrame("Button", name, parent, BACKDROP_TEMPLATE)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetSize(width or 120, height or 24)
    btn:SetBackdrop(INSET_BACKDROP)
    btn:SetBackdropColor(unpack(COLORS.tabNormal))
    btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(text)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
        self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.tabNormal))
        self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        label:SetTextColor(COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3])
    end)

    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

function BAC.UI:CreateColorPicker(parent, name, labelText, x, y, getFunc, setFunc)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(160, 26)

    local swatch = CreateFrame("Button", name .. "Swatch", frame, BACKDROP_TEMPLATE)
    swatch:SetSize(20, 20)
    swatch:SetPoint("LEFT", frame, "LEFT", 0, 0)
    swatch:SetBackdrop(INSET_BACKDROP)
    swatch:SetBackdropBorderColor(unpack(COLORS.goldBorder))

    local colorTex = swatch:CreateTexture(nil, "ARTWORK")
    colorTex:SetPoint("TOPLEFT", swatch, "TOPLEFT", 2, -2)
    colorTex:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)

    local cur = getFunc and getFunc() or { r = 1, g = 1, b = 1 }
    colorTex:SetColorTexture(cur.r or 1, cur.g or 1, cur.b or 1, 1)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    label:SetText(labelText)

    swatch:SetScript("OnClick", function()
        local c = getFunc and getFunc() or { r = 1, g = 1, b = 1 }
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            colorTex:SetColorTexture(r, g, b, 1)
            if setFunc then setFunc({ r = r, g = g, b = b }) end
        end
        ColorPickerFrame.cancelFunc = function(prev)
            colorTex:SetColorTexture(c.r, c.g, c.b, 1)
            if setFunc then setFunc(c) end
        end
        ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame:Show()
    end)

    return frame
end

function BAC.UI:CreateEditBox(parent, name, labelText, x, y, width, getFunc, setFunc)
    width = width or 200
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(labelText)
    label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])

    local eb = CreateFrame("EditBox", name, parent, BACKDROP_TEMPLATE)
    eb:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    eb:SetSize(width, 22)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetBackdrop(INSET_BACKDROP)
    eb:SetBackdropColor(unpack(COLORS.contentBg))
    eb:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    eb:SetTextInsets(6, 6, 0, 0)

    local cur = getFunc and getFunc() or ""
    eb:SetText(cur)

    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if setFunc then setFunc(self:GetText()) end
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        if setFunc then setFunc(self:GetText()) end
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText(getFunc and getFunc() or "")
    end)

    return eb
end

--[[-----------------------------------------------------------------------------
    Static Dialogs for Profile Management
-------------------------------------------------------------------------------]]
StaticPopupDialogs["BLEAKFIBERS_SAVE_AS_PROFILE"] = {
    text = "Save current settings as a new profile:\nEnter profile name:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 24,
    OnAccept = function(self)
        local editBox = _G[self:GetName() .. "EditBox"]
        local text = editBox:GetText()
        if text and text:match("%S") then
            BAC:SaveCurrentAsProfile(text:match("^%s*(.-)%s*$"))
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local text = self:GetText()
        if text and text:match("%S") then
            BAC:SaveCurrentAsProfile(text:match("^%s*(.-)%s*$"))
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

StaticPopupDialogs["BLEAKFIBERS_NEW_PROFILE"] = {
    text = "Enter a name for the new blank profile:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 24,
    OnAccept = function(self)
        local editBox = _G[self:GetName() .. "EditBox"]
        local text = editBox:GetText()
        if text and text:match("%S") then
            BAC:CreateProfile(text:match("^%s*(.-)%s*$"))
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local text = self:GetText()
        if text and text:match("%S") then
            BAC:CreateProfile(text:match("^%s*(.-)%s*$"))
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

StaticPopupDialogs["BLEAKFIBERS_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete profile '%s'?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data then
            BAC:DeleteProfile(data)
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

StaticPopupDialogs["BLEAKFIBERS_RESET_PROFILE"] = {
    text = "Reset all addon settings in profile '%s' to defaults?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        BAC:ResetProfile(data)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

--[[-----------------------------------------------------------------------------
    Master Frame Initialization
-------------------------------------------------------------------------------]]
function BAC:CreateMasterFrame()
    if self.frame then return self.frame end

    local db = BleakfibersConfigDB or {}
    local width = db.width or 760
    local height = db.height or 520
    local point = db.point or "CENTER"
    local relPoint = db.relativePoint or "CENTER"
    local xOfs = db.xOfs or 0
    local yOfs = db.yOfs or 0

    -- Root Master Frame
    local f = CreateFrame("Frame", "BleakfibersConfigFrame", UIParent, BACKDROP_TEMPLATE)
    f:SetSize(width, height)
    f:SetPoint(point, UIParent, relPoint, xOfs, yOfs)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetResizable(true)

    -- ESC-to-close behavior
    tinsert(UISpecialFrames, "BleakfibersConfigFrame")

    -- Resize bounds
    if f.SetResizeBounds then
        f:SetResizeBounds(640, 420, 1200, 850)
    else
        f:SetMinResize(640, 420)
        f:SetMaxResize(1200, 850)
    end

    -- Visual styling: Dark slate background with gold beveled border
    f:SetBackdrop(MAIN_WINDOW_BACKDROP)
    f:SetBackdropColor(unpack(COLORS.bgSlate))
    f:SetBackdropBorderColor(unpack(COLORS.goldBorder))

    -- Title Bar Area (Draggable)
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -32, -6)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")

    titleBar:SetScript("OnDragStart", function()
        f:StartMoving()
    end)

    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pt, _, relPt, x, y = f:GetPoint()
        if BleakfibersConfigDB then
            BleakfibersConfigDB.point = pt
            BleakfibersConfigDB.relativePoint = relPt or pt
            BleakfibersConfigDB.xOfs = math.floor(x + 0.5)
            BleakfibersConfigDB.yOfs = math.floor(y + 0.5)
        end
    end)

    -- Title Icon / Emblem
    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Title Text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    titleText:SetText("|cFFFFD100Bleakfiber's Addon Config|r  |cFF8899A6Forever|r")

    -- Version Subtitle
    local versionText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -1)
    versionText:SetText("v" .. self.version)

    -- Global Movers Toggle Button (in Title Bar)
    local globalMoverBtn = CreateFrame("Button", nil, titleBar, BACKDROP_TEMPLATE)
    globalMoverBtn:SetSize(110, 22)
    globalMoverBtn:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
    globalMoverBtn:SetBackdrop(INSET_BACKDROP)
    globalMoverBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
    globalMoverBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    globalMoverBtn.title = globalMoverBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    globalMoverBtn.title:SetPoint("CENTER", globalMoverBtn, "CENTER", 0, 0)
    globalMoverBtn.title:SetText("Unlock Movers")

    globalMoverBtn:SetScript("OnEnter", function(btn)
        if not BAC:AreMoversUnlocked() then
            btn:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
            btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        end
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Global UI Movers", COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
        GameTooltip:AddLine("Unlock or lock all moveable UI frames across all Bleakfiber addons.", 1, 1, 1, true)
        GameTooltip:AddLine("|cFF8899A6Command: /bac movers|r", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    globalMoverBtn:SetScript("OnLeave", function(btn)
        BAC:UpdateMoverButtonState()
        GameTooltip:Hide()
    end)
    globalMoverBtn:SetScript("OnClick", function()
        BAC:ToggleAllMovers()
    end)
    f.globalMoverBtn = globalMoverBtn

    -- Global Reset Movers Button (in Title Bar)
    local globalResetBtn = CreateFrame("Button", nil, titleBar, BACKDROP_TEMPLATE)
    globalResetBtn:SetSize(52, 22)
    globalResetBtn:SetPoint("RIGHT", globalMoverBtn, "LEFT", -6, 0)
    globalResetBtn:SetBackdrop(INSET_BACKDROP)
    globalResetBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
    globalResetBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local globalResetBtnText = globalResetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    globalResetBtnText:SetPoint("CENTER", globalResetBtn, "CENTER", 0, 0)
    globalResetBtnText:SetText("Reset")

    globalResetBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
        btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Reset All Movers", COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
        GameTooltip:AddLine("Reset all moveable UI frames across all addons to default positions.", 1, 1, 1, true)
        GameTooltip:AddLine("|cFF8899A6Command: /bac resetmovers|r", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    globalResetBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
        btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        GameTooltip:Hide()
    end)
    globalResetBtn:SetScript("OnClick", function()
        BAC:ResetAllMovers()
    end)
    f.globalResetBtn = globalResetBtn

    -- Master Profile Dropdown & Button (in Title Bar near Movers)
    local profileDropdownFrame = CreateFrame("Frame", "BleakfibersProfileDropDown", UIParent, "UIDropDownMenuTemplate")
    f.profileDropdownFrame = profileDropdownFrame

    local profileBtn = CreateFrame("Button", "BleakfibersMasterProfileBtn", titleBar, BACKDROP_TEMPLATE)
    profileBtn:SetSize(130, 22)
    profileBtn:SetPoint("RIGHT", globalResetBtn, "LEFT", -6, 0)
    profileBtn:SetBackdrop(INSET_BACKDROP)
    profileBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
    profileBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local profileBtnText = profileBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profileBtnText:SetPoint("LEFT", profileBtn, "LEFT", 6, 0)
    profileBtnText:SetPoint("RIGHT", profileBtn, "RIGHT", -6, 0)
    profileBtnText:SetJustifyH("CENTER")
    profileBtnText:SetWordWrap(false)
    profileBtnText:SetText("Profile: " .. BAC:GetActiveProfile())
    profileBtn.title = profileBtnText
    f.profileBtn = profileBtn

    profileBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
        btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Master Profile Manager", COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
        GameTooltip:AddLine("Active: |cFFFFFFFF" .. BAC:GetActiveProfile() .. "|r", 1, 1, 1)
        GameTooltip:AddLine("Click to switch, create, reset, or delete synchronized profiles across all Bleakfiber addons.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("|cFF8899A6Command: /bac profile <name>|r", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    profileBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
        btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        GameTooltip:Hide()
    end)

    profileBtn:SetScript("OnClick", function(btn)
        BAC:ToggleProfileMenu(btn)
    end)

    -- Gold Divider below Title Bar
    local titleDivider = f:CreateTexture(nil, "ARTWORK")
    titleDivider:SetHeight(1)
    titleDivider:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -36)
    titleDivider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -36)
    titleDivider:SetColorTexture(COLORS.goldBorder[1], COLORS.goldBorder[2], COLORS.goldBorder[3], 0.6)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Bottom-right Resize Grip
    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:EnableMouse(true)

    local gripTex = resizeGrip:CreateTexture(nil, "ARTWORK")
    gripTex:SetAllPoints(resizeGrip)
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    resizeGrip:SetScript("OnEnter", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeGrip:SetScript("OnLeave", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        if BleakfibersConfigDB then
            BleakfibersConfigDB.width = math.floor(f:GetWidth() + 0.5)
            BleakfibersConfigDB.height = math.floor(f:GetHeight() + 0.5)
        end
    end)

    -- Footer hint text
    local footerText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 8)
    footerText:SetText("|cFF667788Use /bac or /bleakfiber to toggle this window|r")

    -- Left Sidebar Frame
    local sidebar = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    sidebar:SetWidth(190)
    sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -44)
    sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 24)
    sidebar:SetBackdrop(INSET_BACKDROP)
    sidebar:SetBackdropColor(unpack(COLORS.sidebarBg))
    sidebar:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    f.sidebar = sidebar

    -- Sidebar Scrollable Frame
    local sidebarScroll = CreateFrame("ScrollFrame", "BleakfibersSidebarScrollFrame", sidebar, "UIPanelScrollFrameTemplate")
    sidebarScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -8)
    sidebarScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -26, 8)

    local scrollChild = CreateFrame("Frame", nil, sidebarScroll)
    scrollChild:SetSize(155, 1) -- Height dynamically adjusted
    sidebarScroll:SetScrollChild(scrollChild)
    f.sidebarScrollChild = scrollChild

    -- Right Content Pane
    local contentPane = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    contentPane:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    contentPane:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 24)
    contentPane:SetBackdrop(INSET_BACKDROP)
    contentPane:SetBackdropColor(unpack(COLORS.contentBg))
    contentPane:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    f.contentPane = contentPane

    -- Content Header Bar
    local contentHeader = CreateFrame("Frame", nil, contentPane)
    contentHeader:SetHeight(32)
    contentHeader:SetPoint("TOPLEFT", contentPane, "TOPLEFT", 12, -6)
    contentHeader:SetPoint("TOPRIGHT", contentPane, "TOPRIGHT", -12, -6)
    f.contentHeader = contentHeader

    local contentTitle = contentHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    contentTitle:SetPoint("LEFT", contentHeader, "LEFT", 0, 0)
    contentTitle:SetText("")
    contentTitle:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    f.contentTitle = contentTitle

    -- Refresh Button in Content Header
    local refreshBtn = CreateFrame("Button", nil, contentHeader, BACKDROP_TEMPLATE)
    refreshBtn:SetSize(75, 22)
    refreshBtn:SetPoint("RIGHT", contentHeader, "RIGHT", 0, 0)
    refreshBtn:SetBackdrop(INSET_BACKDROP)
    refreshBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
    refreshBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    refreshBtn:Hide()

    local refreshBtnText = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    refreshBtnText:SetPoint("CENTER", refreshBtn, "CENTER", 0, 0)
    refreshBtnText:SetText("Refresh")

    refreshBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
        btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
    end)
    refreshBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
        btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    end)
    refreshBtn:SetScript("OnClick", function()
        if BAC.selectedModuleID and BAC.modules[BAC.selectedModuleID] then
            local mod = BAC.modules[BAC.selectedModuleID]
            if mod.refresh and type(mod.refresh) == "function" then
                local ok, err = pcall(mod.refresh)
                if not ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF2020[Bleakfiber's Addon Config] Refresh error:|r " .. tostring(err))
                end
            end
        end
    end)
    f.refreshBtn = refreshBtn

    -- Module-specific Mover Button in Content Header
    local moduleMoverBtn = CreateFrame("Button", nil, contentHeader, BACKDROP_TEMPLATE)
    moduleMoverBtn:SetSize(68, 22)
    moduleMoverBtn:SetBackdrop(INSET_BACKDROP)
    moduleMoverBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
    moduleMoverBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    moduleMoverBtn:Hide()

    local moduleMoverBtnText = moduleMoverBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    moduleMoverBtnText:SetPoint("CENTER", moduleMoverBtn, "CENTER", 0, 0)
    moduleMoverBtnText:SetText("Movers")
    moduleMoverBtn.title = moduleMoverBtnText

    moduleMoverBtn:SetScript("OnEnter", function(btn)
        local isUnlocked = false
        if BAC.selectedModuleID and BAC.modules[BAC.selectedModuleID] then
            local mod = BAC.modules[BAC.selectedModuleID]
            if mod.isMoversUnlocked then
                local ok, res = pcall(mod.isMoversUnlocked)
                if ok then isUnlocked = res end
            end
        end
        if not isUnlocked then
            btn:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
            btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        end
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Module Movers", COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
        GameTooltip:AddLine("Toggle moveable UI frames for this specific addon.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    moduleMoverBtn:SetScript("OnLeave", function(btn)
        BAC:UpdateMoverButtonState()
        GameTooltip:Hide()
    end)
    moduleMoverBtn:SetScript("OnClick", function()
        if BAC.selectedModuleID and BAC.modules[BAC.selectedModuleID] then
            local mod = BAC.modules[BAC.selectedModuleID]
            if mod.toggleMovers and type(mod.toggleMovers) == "function" then
                local isUnlocked = false
                if mod.isMoversUnlocked then
                    local ok, res = pcall(mod.isMoversUnlocked)
                    if ok then isUnlocked = res end
                end
                pcall(mod.toggleMovers, not isUnlocked)
                BAC:UpdateMoverButtonState()
            end
        end
    end)
    f.moduleMoverBtn = moduleMoverBtn

    -- Content Header Divider
    local contentDivider = contentPane:CreateTexture(nil, "ARTWORK")
    contentDivider:SetHeight(1)
    contentDivider:SetPoint("TOPLEFT", contentPane, "TOPLEFT", 10, -38)
    contentDivider:SetPoint("TOPRIGHT", contentPane, "TOPRIGHT", -10, -38)
    contentDivider:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.5)
    f.contentDivider = contentDivider

    -- Content Container Area (Housing the active module frame)
    local contentArea = CreateFrame("Frame", nil, contentPane)
    contentArea:SetPoint("TOPLEFT", contentPane, "TOPLEFT", 10, -42)
    contentArea:SetPoint("BOTTOMRIGHT", contentPane, "BOTTOMRIGHT", -10, 10)
    f.contentArea = contentArea

    -- Empty State Frame
    local emptyState = CreateFrame("Frame", nil, contentPane)
    emptyState:SetAllPoints(contentArea)
    f.emptyState = emptyState

    local emptyIcon = emptyState:CreateTexture(nil, "ARTWORK")
    emptyIcon:SetSize(48, 48)
    emptyIcon:SetPoint("CENTER", emptyState, "CENTER", 0, 40)
    emptyIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    emptyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    emptyIcon:SetVertexColor(0.7, 0.65, 0.45, 0.7)

    local emptyTitle = emptyState:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    emptyTitle:SetPoint("TOP", emptyIcon, "BOTTOM", 0, -14)
    emptyTitle:SetText("|cFFFFD100Bleakfiber's Addon Config|r")

    local emptyMessage = emptyState:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyMessage:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -8)
    emptyMessage:SetWidth(380)
    emptyMessage:SetText("Select an addon on the left to configure settings.")
    emptyMessage:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])

    local emptySubtext = emptyState:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptySubtext:SetPoint("TOP", emptyMessage, "BOTTOM", 0, -14)
    emptySubtext:SetText("Registered modules will appear in the navigation sidebar.")

    -- Handle OnShow to restore last state and refresh navigation
    f:SetScript("OnShow", function()
        BAC:RefreshSidebar()
        BAC:UpdateMoverButtonState()
        BAC:UpdateProfileUI()
        local lastTab = BleakfibersConfigDB and BleakfibersConfigDB.lastTab
        if lastTab and BAC.modules[lastTab] then
            BAC:SelectModule(lastTab)
        elseif BAC.selectedModuleID and BAC.modules[BAC.selectedModuleID] then
            BAC:SelectModule(BAC.selectedModuleID)
        elseif BAC.sortedModules and #BAC.sortedModules > 0 then
            BAC:SelectModule(BAC.sortedModules[1])
        elseif #BAC.moduleOrder > 0 then
            BAC:SelectModule(BAC.moduleOrder[1])
        else
            BAC:ShowEmptyState()
        end
    end)

    f:SetScript("OnHide", function()
        if BAC.profileMenuFrame then
            BAC.profileMenuFrame:Hide()
        end
    end)

    f:Hide()
    self.frame = f
    return f
end

--[[-----------------------------------------------------------------------------
    Navigation Sidebar: Refresh & Draw Tabs
-------------------------------------------------------------------------------]]
function BAC:RefreshSidebar()
    if not self.frame or not self.frame.sidebarScrollChild then return end

    local scrollChild = self.frame.sidebarScrollChild
    local tabHeight = 30
    local tabSpacing = 4
    local currentY = 4

    -- Initialize persistent headers and group divider on scrollChild
    if not scrollChild.headerBleakfiber then
        scrollChild.headerBleakfiber = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        scrollChild.headerBleakfiber:SetText("|cFFFFD100BLEAKFIBER'S|r")
    end

    if not scrollChild.groupDivider then
        scrollChild.groupDivider = scrollChild:CreateTexture(nil, "ARTWORK")
        scrollChild.groupDivider:SetHeight(1)
        scrollChild.groupDivider:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.6)
    end

    if not scrollChild.headerOther then
        scrollChild.headerOther = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        scrollChild.headerOther:SetText("|cFFC9A038OTHER ADDONS|r")
    end

    -- Hide headers and divider initially
    scrollChild.headerBleakfiber:Hide()
    scrollChild.groupDivider:Hide()
    scrollChild.headerOther:Hide()

    -- Hide all existing tab buttons
    for _, btn in pairs(self.tabButtons) do
        btn:Hide()
    end

    -- Retrieve sorted lists (Bleakfiber addons prioritized on top, each group alphabetical)
    local sortedAll, bleakfiberModules, otherModules = self:GetSortedModuleList()
    self.sortedModules = sortedAll

    -- Helper to lay out a list of module buttons
    local function LayoutModuleGroup(moduleIDs, isBleakGroup)
        for _, moduleID in ipairs(moduleIDs) do
            local moduleData = self.modules[moduleID]
            local btn = self.tabButtons[moduleID]

            if not btn then
                btn = CreateFrame("Button", nil, scrollChild, BACKDROP_TEMPLATE)
                btn:SetHeight(tabHeight)
                btn:SetBackdrop(INSET_BACKDROP)

                -- Tab Text
                btn.title = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.title:SetPoint("LEFT", btn, "LEFT", 10, 0)
                btn.title:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
                btn.title:SetJustifyH("LEFT")

                -- Active indicator strip on the left edge
                btn.activeIndicator = btn:CreateTexture(nil, "OVERLAY")
                btn.activeIndicator:SetWidth(3)
                btn.activeIndicator:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
                btn.activeIndicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 2)
                btn.activeIndicator:SetColorTexture(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3], 1.0)
                btn.activeIndicator:Hide()

                btn:SetScript("OnClick", function()
                    BAC:SelectModule(moduleID)
                end)

                btn:SetScript("OnEnter", function(tab)
                    if BAC.selectedModuleID ~= moduleID then
                        tab:SetBackdropColor(unpack(COLORS.tabHighlight))
                        tab:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                    end

                    -- Tooltip
                    GameTooltip:SetOwner(tab, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(moduleData.name or moduleID, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
                    if moduleData.author then
                        GameTooltip:AddLine("Author: |cFFFFFFFF" .. moduleData.author .. "|r", COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])
                    end
                    if moduleData.description then
                        GameTooltip:AddLine(moduleData.description, 0.85, 0.85, 0.85, true)
                    end
                    GameTooltip:Show()
                end)

                btn:SetScript("OnLeave", function(tab)
                    if BAC.selectedModuleID ~= moduleID then
                        tab:SetBackdropColor(unpack(COLORS.tabNormal))
                        tab:SetBackdropBorderColor(unpack(COLORS.goldMuted))
                    end
                    GameTooltip:Hide()
                end)

                self.tabButtons[moduleID] = btn
            end

            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
            btn:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -currentY)

            -- Format button label: If in Bleakfiber group, strip redundant prefix if desired
            local displayLabel = moduleData.sidebarName or moduleData.name or moduleID
            if isBleakGroup and not moduleData.sidebarName then
                displayLabel = displayLabel:gsub("^[Bb]leakfiber'?s?%s+", "")
                displayLabel = displayLabel:gsub("^[Bb]leak%s+", "")
            end

            btn.title:SetText(displayLabel)
            btn:Show()

            currentY = currentY + tabHeight + tabSpacing
        end
    end

    -- 1. Bleakfiber's Section
    if #bleakfiberModules > 0 then
        scrollChild.headerBleakfiber:ClearAllPoints()
        scrollChild.headerBleakfiber:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 6, -currentY)
        scrollChild.headerBleakfiber:Show()
        currentY = currentY + 18

        LayoutModuleGroup(bleakfiberModules, true)
    end

    -- 2. Other Creators' Section
    if #otherModules > 0 then
        if #bleakfiberModules > 0 then
            currentY = currentY + 4
            scrollChild.groupDivider:ClearAllPoints()
            scrollChild.groupDivider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -currentY)
            scrollChild.groupDivider:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, -currentY)
            scrollChild.groupDivider:Show()
            currentY = currentY + 10
        end

        scrollChild.headerOther:ClearAllPoints()
        scrollChild.headerOther:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 6, -currentY)
        scrollChild.headerOther:Show()
        currentY = currentY + 18

        LayoutModuleGroup(otherModules, false)
    end

    scrollChild:SetHeight(math.max(currentY + 6, 1))
    self:UpdateTabHighlights()
end

--[[-----------------------------------------------------------------------------
    Update Tab Button Visual Highlights
-------------------------------------------------------------------------------]]
function BAC:UpdateTabHighlights()
    for modID, btn in pairs(self.tabButtons) do
        if modID == self.selectedModuleID then
            btn:SetBackdropColor(unpack(COLORS.tabActive))
            btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
            btn.title:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            btn.activeIndicator:Show()
        else
            btn:SetBackdropColor(unpack(COLORS.tabNormal))
            btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
            btn.title:SetTextColor(COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3])
            btn.activeIndicator:Hide()
        end
    end
end

--[[-----------------------------------------------------------------------------
    Empty State Display
-------------------------------------------------------------------------------]]
function BAC:ShowEmptyState()
    self.selectedModuleID = nil

    if self.frame then
        if self.frame.contentTitle then
            self.frame.contentTitle:SetText("")
        end
        if self.frame.refreshBtn then
            self.frame.refreshBtn:Hide()
        end
        if self.frame.moduleMoverBtn then
            self.frame.moduleMoverBtn:Hide()
        end
        if self.frame.contentDivider then
            self.frame.contentDivider:Hide()
        end
        if self.frame.emptyState then
            self.frame.emptyState:Show()
        end

        -- Hide all module containers
        for _, container in pairs(self.moduleContainers) do
            container:Hide()
        end
    end

    self:UpdateTabHighlights()
    self:UpdateMoverButtonState()
end

--[[-----------------------------------------------------------------------------
    Module Selection & Lazy Loading
-------------------------------------------------------------------------------]]
function BAC:SelectModule(moduleID)
    if not self.frame then
        self:CreateMasterFrame()
    end

    local moduleData = self.modules[moduleID]
    if not moduleData then
        self:ShowEmptyState()
        return
    end

    self.selectedModuleID = moduleID

    if BleakfibersConfigDB then
        BleakfibersConfigDB.lastTab = moduleID
    end

    -- Hide empty state and show header divider
    self.frame.emptyState:Hide()
    self.frame.contentDivider:Show()

    -- Update Content Header Title
    self.frame.contentTitle:SetText(moduleData.name or moduleID)

    -- Header action buttons (Refresh & Module Movers)
    local hasRefresh = (moduleData.refresh and type(moduleData.refresh) == "function")
    local hasMovers = (moduleData.toggleMovers and type(moduleData.toggleMovers) == "function")

    if hasRefresh then
        self.frame.refreshBtn:ClearAllPoints()
        self.frame.refreshBtn:SetPoint("RIGHT", self.frame.contentHeader, "RIGHT", 0, 0)
        self.frame.refreshBtn:Show()
    else
        self.frame.refreshBtn:Hide()
    end

    if hasMovers then
        self.frame.moduleMoverBtn:ClearAllPoints()
        if hasRefresh then
            self.frame.moduleMoverBtn:SetPoint("RIGHT", self.frame.refreshBtn, "LEFT", -6, 0)
        else
            self.frame.moduleMoverBtn:SetPoint("RIGHT", self.frame.contentHeader, "RIGHT", 0, 0)
        end
        self.frame.moduleMoverBtn:Show()
    else
        self.frame.moduleMoverBtn:Hide()
    end

    -- Hide all other module containers
    for id, container in pairs(self.moduleContainers) do
        if id ~= moduleID then
            container:Hide()
        end
    end

    -- Lazy loading: build UI only once when first visited
    local activeContainer = self.moduleContainers[moduleID]
    if not activeContainer then
        activeContainer = CreateFrame("Frame", "BleakfibersContainer_" .. moduleID, self.frame.contentArea)
        activeContainer:SetAllPoints(self.frame.contentArea)
        activeContainer.isMasterHub = true

        local success, err = pcall(moduleData.buildUI, activeContainer, true)
        if not success then
            local errorMsg = activeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errorMsg:SetPoint("CENTER", activeContainer, "CENTER", 0, 0)
            errorMsg:SetTextColor(1.0, 0.2, 0.2)
            errorMsg:SetText("Error loading module UI:\n" .. tostring(err))
        end

        self.moduleContainers[moduleID] = activeContainer
    end

    activeContainer.isMasterHub = true
    activeContainer:Show()

    -- Trigger live refresh if available
    if moduleData.refresh and type(moduleData.refresh) == "function" then
        pcall(moduleData.refresh)
    end

    self:UpdateTabHighlights()
    self:UpdateMoverButtonState()
end

--[[-----------------------------------------------------------------------------
    Update Mover Button States (Global & Module-specific)
-------------------------------------------------------------------------------]]
function BAC:UpdateMoverButtonState()
    if not self.frame then return end

    local areUnlocked = self:AreMoversUnlocked()

    -- 1. Global Movers Button in Title Bar
    local gBtn = self.frame.globalMoverBtn
    if gBtn and gBtn.title then
        if areUnlocked then
            gBtn.title:SetText("|cFF00FF00Lock Movers|r")
            gBtn:SetBackdropColor(0.10, 0.26, 0.14, 0.95)
            gBtn:SetBackdropBorderColor(0.20, 0.85, 0.30, 1.0)
        else
            gBtn.title:SetText("|cFFFFD100Unlock Movers|r")
            gBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
            gBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        end
    end

    -- 2. Module-specific Mover Button in Content Header
    local mBtn = self.frame.moduleMoverBtn
    if mBtn and mBtn:IsShown() and self.selectedModuleID then
        local mod = self.modules[self.selectedModuleID]
        local modUnlocked = areUnlocked
        if mod and mod.isMoversUnlocked and type(mod.isMoversUnlocked) == "function" then
            local ok, val = pcall(mod.isMoversUnlocked)
            if ok then modUnlocked = val end
        end

        if modUnlocked then
            mBtn.title:SetText("|cFF00FF00Lock|r")
            mBtn:SetBackdropColor(0.10, 0.26, 0.14, 0.95)
            mBtn:SetBackdropBorderColor(0.20, 0.85, 0.30, 1.0)
        else
            mBtn.title:SetText("Movers")
            mBtn:SetBackdropColor(0.12, 0.14, 0.18, 0.8)
            mBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        end
    end
end

--[[-----------------------------------------------------------------------------
    Profile Menu & Interaction (Custom Dark Slate & Gold Popup)
-------------------------------------------------------------------------------]]
function BAC:GetOrCreateProfileMenu()
    if self.profileMenuFrame then return self.profileMenuFrame end

    local menuFrame = CreateFrame("Frame", "BleakfibersProfileMenuFrame", UIParent, BACKDROP_TEMPLATE)
    menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    menuFrame:SetClampedToScreen(true)
    menuFrame:SetBackdrop(INSET_BACKDROP)
    menuFrame:SetBackdropColor(0.08, 0.10, 0.13, 0.98)
    menuFrame:SetBackdropBorderColor(unpack(COLORS.goldBorder))
    menuFrame:EnableMouse(true)
    menuFrame:Hide()

    -- Click-catcher backdrop to dismiss menu on clicking outside
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(math.max(menuFrame:GetFrameLevel() - 1, 1))
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnClick", function()
        menuFrame:Hide()
    end)
    menuFrame.catcher = catcher

    menuFrame:SetScript("OnShow", function()
        catcher:Show()
    end)
    menuFrame:SetScript("OnHide", function()
        catcher:Hide()
    end)

    menuFrame.itemButtons = {}
    self.profileMenuFrame = menuFrame
    return menuFrame
end

function BAC:ToggleProfileMenu(anchorBtn)
    anchorBtn = anchorBtn or (self.frame and self.frame.profileBtn) or _G["BleakfibersMasterProfileBtn"]
    if not anchorBtn then return end

    local menu = self:GetOrCreateProfileMenu()
    if menu:IsShown() then
        menu:Hide()
        return
    end

    local activeProf = self:GetActiveProfile()
    local profiles = self:GetProfiles()

    -- Clear / hide previous item buttons
    for _, btn in ipairs(menu.itemButtons) do
        btn:Hide()
    end

    local btnHeight = 22
    local menuWidth = 195
    local currentY = -8

    -- Header
    if not menu.headerText then
        menu.headerText = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        menu.headerText:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -8)
        menu.headerText:SetText("|cFFFFD100PROFILES|r")
    end
    menu.headerText:Show()
    currentY = currentY - 18

    local btnIndex = 0
    local function GetButton()
        btnIndex = btnIndex + 1
        local btn = menu.itemButtons[btnIndex]
        if not btn then
            btn = CreateFrame("Button", nil, menu, BACKDROP_TEMPLATE)
            btn:SetHeight(btnHeight)
            btn:SetBackdrop(INSET_BACKDROP)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("LEFT", btn, "LEFT", 8, 0)
            btn.text:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
            btn.text:SetJustifyH("LEFT")

            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
                self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
            end)
            btn:SetScript("OnLeave", function(self)
                if self.isActive then
                    self:SetBackdropColor(0.22, 0.19, 0.12, 0.95)
                    self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                else
                    self:SetBackdropColor(0.12, 0.14, 0.17, 0.65)
                    self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
                end
            end)

            table.insert(menu.itemButtons, btn)
        end
        return btn
    end

    -- Add profile options
    for _, pName in ipairs(profiles) do
        local btn = GetButton()
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY)
        btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY)

        local isActive = (pName == activeProf)
        btn.isActive = isActive
        if isActive then
            btn.text:SetText("|cFF00FF00✔|r |cFFFFD100" .. pName .. "|r")
            btn:SetBackdropColor(0.22, 0.19, 0.12, 0.95)
            btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        else
            btn.text:SetText("   " .. pName)
            btn:SetBackdropColor(0.12, 0.14, 0.17, 0.65)
            btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        end

        local profileName = pName
        btn:SetScript("OnClick", function()
            menu:Hide()
            BAC:SetActiveProfile(profileName)
        end)
        btn:Show()
        currentY = currentY - btnHeight - 2
    end

    -- Divider
    currentY = currentY - 2
    if not menu.divider then
        menu.divider = menu:CreateTexture(nil, "ARTWORK")
        menu.divider:SetHeight(1)
        menu.divider:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.6)
    end
    menu.divider:ClearAllPoints()
    menu.divider:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY)
    menu.divider:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY)
    menu.divider:Show()
    currentY = currentY - 4

    -- "Save Current as Profile..." button
    local saveCurrentBtn = GetButton()
    saveCurrentBtn.isActive = false
    saveCurrentBtn:ClearAllPoints()
    saveCurrentBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY)
    saveCurrentBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY)
    saveCurrentBtn.text:SetText("|cFF88FF88+ Save Current as Profile...|r")
    saveCurrentBtn:SetBackdropColor(0.12, 0.14, 0.17, 0.65)
    saveCurrentBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    saveCurrentBtn:SetScript("OnClick", function()
        menu:Hide()
        StaticPopup_Show("BLEAKFIBERS_SAVE_AS_PROFILE")
    end)
    saveCurrentBtn:Show()
    currentY = currentY - btnHeight - 2

    -- "New Blank Profile..." button
    local newBtn = GetButton()
    newBtn.isActive = false
    newBtn:ClearAllPoints()
    newBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY)
    newBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY)
    newBtn.text:SetText("|cFFFFD100+ New Blank Profile...|r")
    newBtn:SetBackdropColor(0.12, 0.14, 0.17, 0.65)
    newBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    newBtn:SetScript("OnClick", function()
        menu:Hide()
        StaticPopup_Show("BLEAKFIBERS_NEW_PROFILE")
    end)
    newBtn:Show()
    currentY = currentY - btnHeight - 2

    -- "Reset Current" button
    local resetBtn = GetButton()
    resetBtn.isActive = false
    resetBtn:ClearAllPoints()
    resetBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY)
    resetBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY)
    resetBtn.text:SetText("|cFFFFCC66Reset Current|r")
    resetBtn:SetBackdropColor(0.12, 0.14, 0.17, 0.65)
    resetBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    resetBtn:SetScript("OnClick", function()
        menu:Hide()
        local cur = BAC:GetActiveProfile()
        local dialog = StaticPopup_Show("BLEAKFIBERS_RESET_PROFILE", cur)
        if dialog then dialog.data = cur end
    end)
    resetBtn:Show()
    currentY = currentY - btnHeight - 2

    -- "Delete Current" button (if not Default)
    if activeProf ~= "Default" then
        local delBtn = GetButton()
        delBtn.isActive = false
        delBtn:ClearAllPoints()
        delBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY)
        delBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY)
        delBtn.text:SetText("|cFFFF5555Delete Current|r")
        delBtn:SetBackdropColor(0.12, 0.14, 0.17, 0.65)
        delBtn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        delBtn:SetScript("OnClick", function()
            menu:Hide()
            local cur = BAC:GetActiveProfile()
            local dialog = StaticPopup_Show("BLEAKFIBERS_DELETE_PROFILE", cur)
            if dialog then dialog.data = cur end
        end)
        delBtn:Show()
        currentY = currentY - btnHeight - 2
    end

    local totalHeight = math.abs(currentY) + 6
    menu:SetSize(menuWidth, totalHeight)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
    menu:Show()
end

function BAC:UpdateProfileUI()
    local btn = (self.frame and self.frame.profileBtn) or _G["BleakfibersMasterProfileBtn"]
    if btn and btn.title then
        btn.title:SetText("Profile: " .. self:GetActiveProfile())
    end
end

