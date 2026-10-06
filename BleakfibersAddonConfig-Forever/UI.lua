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
    Helper: Create Section Header
-------------------------------------------------------------------------------]]
local function CreateSectionHeader(parent, text, point, relPoint, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint(point, parent, relPoint, x, y)
    header:SetText(text)
    header:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    return header
end

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

    -- Sidebar Header
    local sidebarHeader = CreateSectionHeader(sidebar, "ADDONS", "TOPLEFT", "TOPLEFT", 12, -10)

    local sidebarDivider = sidebar:CreateTexture(nil, "ARTWORK")
    sidebarDivider:SetHeight(1)
    sidebarDivider:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -26)
    sidebarDivider:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -8, -26)
    sidebarDivider:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.5)

    -- Sidebar Scrollable Frame
    local sidebarScroll = CreateFrame("ScrollFrame", "BleakfibersSidebarScrollFrame", sidebar, "UIPanelScrollFrameTemplate")
    sidebarScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -30)
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
        local lastTab = BleakfibersConfigDB and BleakfibersConfigDB.lastTab
        if lastTab and BAC.modules[lastTab] then
            BAC:SelectModule(lastTab)
        elseif BAC.selectedModuleID and BAC.modules[BAC.selectedModuleID] then
            BAC:SelectModule(BAC.selectedModuleID)
        elseif #BAC.moduleOrder > 0 then
            BAC:SelectModule(BAC.moduleOrder[1])
        else
            BAC:ShowEmptyState()
        end
    end)

    self.frame = f
    return f
end

--[[-----------------------------------------------------------------------------
    Navigation Sidebar: Refresh & Draw Tabs
-------------------------------------------------------------------------------]]
function BAC:RefreshSidebar()
    if not self.frame or not self.frame.sidebarScrollChild then return end

    local scrollChild = self.frame.sidebarScrollChild
    local tabHeight = 32
    local tabSpacing = 4
    local currentY = 0

    -- Create or update tab buttons for each registered module
    for index, moduleID in ipairs(self.moduleOrder) do
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
            end)

            btn:SetScript("OnLeave", function(tab)
                if BAC.selectedModuleID ~= moduleID then
                    tab:SetBackdropColor(unpack(COLORS.tabNormal))
                    tab:SetBackdropBorderColor(unpack(COLORS.goldMuted))
                end
            end)

            self.tabButtons[moduleID] = btn
        end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
        btn:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -currentY)
        btn.title:SetText(moduleData.name or moduleID)
        btn:Show()

        currentY = currentY + tabHeight + tabSpacing
    end

    scrollChild:SetHeight(math.max(currentY, 1))
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

    -- Update Content Header
    self.frame.contentTitle:SetText(moduleData.name or moduleID)

    if moduleData.refresh and type(moduleData.refresh) == "function" then
        self.frame.refreshBtn:Show()
    else
        self.frame.refreshBtn:Hide()
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

        local success, err = pcall(moduleData.buildUI, activeContainer)
        if not success then
            local errorMsg = activeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errorMsg:SetPoint("CENTER", activeContainer, "CENTER", 0, 0)
            errorMsg:SetTextColor(1.0, 0.2, 0.2)
            errorMsg:SetText("Error loading module UI:\n" .. tostring(err))
        end

        self.moduleContainers[moduleID] = activeContainer
    end

    activeContainer:Show()

    -- Trigger live refresh if available
    if moduleData.refresh and type(moduleData.refresh) == "function" then
        pcall(moduleData.refresh)
    end

    self:UpdateTabHighlights()
end
