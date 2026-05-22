local NTST = NextTryStatusTracker
local wm = WINDOW_MANAGER

local function getFontPath(style)
    if style == "bold" then
        return "EsoUI/Common/Fonts/univers67.otf"
    end
    return "EsoUI/Common/Fonts/univers57.otf"
end

function NTST:GetFontString(state)
    local s = self.sv.styles[state]
    return string.format("%s|%d|soft-shadow-thin", getFontPath(s.fontStyle), s.fontSize)
end

function NTST:GetStatusStyle(isOnline)
    return isOnline and self.sv.styles.online or self.sv.styles.offline
end

function NTST:ResetPosition()
    self.sv.position = nil
    self:ApplyPosition()
end

function NTST:SavePosition()
    if not self.container or not self.sv then return end
    local left = self.container:GetLeft()
    local top = self.container:GetTop()
    if left == nil or top == nil then return end
    self.sv.position = { x = zo_round(left), y = zo_round(top) }
end

function NTST:ApplyPosition()
    if not self.container then return end
    self.container:ClearAnchors()
    if self.sv.position then
        self.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.sv.position.x, self.sv.position.y)
    else
        self.container:SetAnchor(CENTER, GuiRoot, CENTER, GuiRoot:GetWidth() * 0.25, 0)
    end
end

function NTST:AttachDragHandlers(control)
    if not control or control.nextTryTrackerDragAttached then return end
    control.nextTryTrackerDragAttached = true
    control:SetHandler("OnMouseDown", function(_, button)
        if self.sv.uiUnlocked and button == MOUSE_BUTTON_INDEX_LEFT and self.container then
            self.container:StartMoving()
        end
    end)
    control:SetHandler("OnMouseUp", function()
        if self.sv.uiUnlocked and self.container then
            self.container:StopMovingOrResizing()
            self:SavePosition()
        end
    end)
end

function NTST:ApplyMouseStateToRows()
    if not self.rows then return end
    for _, row in ipairs(self.rows) do
        row:SetMouseEnabled(self.sv.uiUnlocked)
        if row.bg then row.bg:SetMouseEnabled(self.sv.uiUnlocked) end
        if row.label then row.label:SetMouseEnabled(self.sv.uiUnlocked) end
    end
end

function NTST:ApplyWindowVisual()
    if not self.containerBg then return end
    local display = self.sv.display
    local bg = display.backgroundColor
    local border = self.sv.uiUnlocked and display.unlockedBorderColor or display.borderColor
    local edgeSize = display.borderSize or 0

    if self.sv.uiUnlocked and edgeSize < 2 then edgeSize = 2 end
    self.containerBg:SetCenterColor(bg.r, bg.g, bg.b, bg.a)
    self.containerBg:SetEdgeColor(border.r, border.g, border.b, edgeSize > 0 and border.a or 0)
    self.containerBg:SetEdgeTexture(nil, math.max(1, edgeSize), math.max(1, edgeSize), math.max(1, edgeSize))
end

function NTST:CreateSceneFragment()
    if self.fragment or not self.container then return end
    if ZO_HUDFadeSceneFragment then
        self.fragment = ZO_HUDFadeSceneFragment:New(self.container)
    elseif ZO_SimpleSceneFragment then
        self.fragment = ZO_SimpleSceneFragment:New(self.container)
    end
    if self.fragment and SCENE_MANAGER then
        local hud = SCENE_MANAGER:GetScene("hud")
        local hudui = SCENE_MANAGER:GetScene("hudui")
        if hud then hud:AddFragment(self.fragment) end
        if hudui then hudui:AddFragment(self.fragment) end
    end
end

function NTST:IsSettingsPreviewActive()
    return self.settingsPreviewActive and self.sv and self.sv.enabled and self.sv.settingsPreview
end

function NTST:SetSettingsPreview(active)
    self.settingsPreviewActive = active and true or false
    self:ApplyVisibility()
    if self.settingsPreviewActive and self.sv and self.sv.enabled then
        self:Refresh(true)
    end
end

function NTST:ApplyVisibility()
    if not self.container then return end
    local disabled = not (self.sv and self.sv.enabled)
    local hiddenByToggle = not (self.sv and self.sv.visible)

    if self.fragment and self.fragment.SetHiddenForReason then
        self.fragment:SetHiddenForReason("disabled", disabled)
        self.fragment:SetHiddenForReason("toggle", hiddenByToggle)
    elseif not self:IsSettingsPreviewActive() then
        self.container:SetHidden(disabled or hiddenByToggle)
    end

    if self:IsSettingsPreviewActive() then
        self.container:SetHidden(false)
    elseif not self.fragment then
        self.container:SetHidden(disabled or hiddenByToggle)
    end
end

function NTST:SetUnlocked(unlocked)
    self.sv.uiUnlocked = unlocked and true or false
    if not self.container then return end
    self.container:SetMovable(self.sv.uiUnlocked)
    self.container:SetMouseEnabled(self.sv.uiUnlocked)
    self.container:SetClampedToScreen(true)
    if self.containerBg then self.containerBg:SetMouseEnabled(self.sv.uiUnlocked) end
    self:ApplyMouseStateToRows()
    self:ApplyWindowVisual()
end

function NTST:CreateUI()
    if self.container then return end

    local c = wm:CreateTopLevelWindow("NextTryStatusTrackerWindow")
    c:SetResizeToFitDescendents(false)
    c:SetClampedToScreen(true)
    c:SetDrawTier(DT_MEDIUM)
    c:SetDrawLayer(DL_CONTROLS)
    c:SetMouseEnabled(self.sv.uiUnlocked)
    c:SetMovable(self.sv.uiUnlocked)
    self:AttachDragHandlers(c)
    c:SetHandler("OnMoveStop", function() self:SavePosition() end)

    c.bg = wm:CreateControl("NextTryStatusTrackerWindowBg", c, CT_BACKDROP)
    c.bg:SetAnchorFill(c)
    c.bg:SetInsets(0, 0, 0, 0)
    c.bg:SetMouseEnabled(self.sv.uiUnlocked)
    self:AttachDragHandlers(c.bg)

    self.container = c
    self.containerBg = c.bg
    self.rows = {}
    self.lastOnline = {}

    self:CreateSceneFragment()
    self:ApplyVisibility()
    self:ApplyWindowVisual()
    self:ApplyPosition()
end

function NTST:ApplyRowVisual(row, isOnline)
    local state = isOnline and "online" or "offline"
    local s = self:GetStatusStyle(isOnline)

    row.label:SetFont(self:GetFontString(state))
    row.label:SetColor(s.fontColor.r, s.fontColor.g, s.fontColor.b, s.fontColor.a)
    row.bg:SetCenterColor(s.backgroundColor.r, s.backgroundColor.g, s.backgroundColor.b, s.backgroundColor.a)
    row.bg:SetEdgeColor(s.backgroundColor.r, s.backgroundColor.g, s.backgroundColor.b, s.backgroundColor.a)
end

function NTST:CreateRow(index)
    local row = wm:CreateControl("NextTryStatusTrackerRow" .. index, self.container, CT_CONTROL)
    row:SetDimensions(10, 10)
    row:SetMouseEnabled(self.sv.uiUnlocked)
    self:AttachDragHandlers(row)

    row.bg = wm:CreateControl("NextTryStatusTrackerRowBg" .. index, row, CT_BACKDROP)
    row.bg:SetAnchorFill(row)
    row.bg:SetEdgeTexture(nil, 1, 1, 0)
    row.bg:SetInsets(0, 0, 0, 0)
    row.bg:SetMouseEnabled(self.sv.uiUnlocked)
    self:AttachDragHandlers(row.bg)

    row.label = wm:CreateControl("NextTryStatusTrackerRowLabel" .. index, row, CT_LABEL)
    row.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    row.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    row.label:SetMouseEnabled(self.sv.uiUnlocked)
    self:AttachDragHandlers(row.label)

    return row
end

function NTST:GetEstimatedRowSize(row, isOnline)
    local state = isOnline and "online" or "offline"
    local style = self.sv.styles[state]
    local fontSize = style.fontSize or 16
    local labelPadding = 8
    local verticalPadding = 5

    row.label:SetFont(self:GetFontString(state))
    row.label:SetWidth(2000)

    local measuredWidth = row.label:GetTextWidth() or 0
    local measuredHeight = row.label:GetTextHeight() or 0
    local width = math.max(1, zo_ceil(measuredWidth + (labelPadding * 2)))
    local height = math.max(fontSize + (verticalPadding * 2), measuredHeight + (verticalPadding * 2), 24)

    return width, height, labelPadding
end

function NTST:LayoutRows(entries)
    local previous
    local maxWidth = 1
    local totalHeight = 0
    local totalWidth = 0
    local display = self.sv.display
    local padding = zo_clamp(zo_floor(display.padding or 0), 0, 50)
    local rowGap = zo_clamp(zo_floor(display.rowGap or 0), 0, 50)
    local groupGap = zo_clamp(zo_floor(display.groupGap or 0), 0, 100)

    for i, row in ipairs(self.rows) do
        row:ClearAnchors()
        row:SetHidden(i > #entries)
        if i <= #entries then
            local entry = entries[i]
            local width, height, labelPadding = self:GetEstimatedRowSize(row, entry.isOnline)
            local gap = previous and rowGap or 0
            if entry.groupBreakBefore then gap = gap + groupGap end

            row:SetDimensions(width, height)
            row.label:ClearAnchors()
            row.label:SetAnchor(LEFT, row, LEFT, labelPadding, 0)
            row.label:SetDimensions(math.max(width - (labelPadding * 2), 1), height)

            if self.sv.layout == "horizontal" then
                if previous then
                    row:SetAnchor(LEFT, previous, RIGHT, gap, 0)
                else
                    row:SetAnchor(TOPLEFT, self.container, TOPLEFT, padding, padding)
                end
                totalWidth = totalWidth + width + gap
                totalHeight = math.max(totalHeight, height)
            else
                if previous then
                    row:SetAnchor(TOPLEFT, previous, BOTTOMLEFT, 0, gap)
                else
                    row:SetAnchor(TOPLEFT, self.container, TOPLEFT, padding, padding)
                end
                maxWidth = math.max(maxWidth, width)
                totalHeight = totalHeight + height + gap
            end
            previous = row
        end
    end

    if self.sv.layout ~= "horizontal" then
        for i, row in ipairs(self.rows) do
            if i <= #entries then
                row:SetWidth(maxWidth)
                row.label:SetWidth(math.max(maxWidth - 16, 1))
            end
        end
        totalWidth = maxWidth
    end

    self.container:SetDimensions(math.max(totalWidth + (padding * 2), 1), math.max(totalHeight + (padding * 2), 1))
    self:ApplyWindowVisual()
end

function NTST:Refresh(initial)
    if not self.container then return end
    self:ApplyVisibility()
    if not self.sv.enabled then return end

    local entries = self:GetDisplayEntries()
    for i, entry in ipairs(entries) do
        local row = self.rows[i]
        if not row then
            row = self:CreateRow(i)
            self.rows[i] = row
        end

        row.playerName = entry.playerName
        row.label:SetText(entry.displayName)
        row:SetHidden(false)

        local previousStatus = self.lastOnline[entry.playerName]
        self.lastOnline[entry.playerName] = entry.isOnline
        if previousStatus ~= nil and previousStatus ~= entry.isOnline and not initial then
            self:PlayStatusSound()
            self:BlinkThenApply(row, previousStatus, entry.isOnline)
        else
            self:ApplyRowVisual(row, entry.isOnline)
        end
    end

    for i = #entries + 1, #self.rows do
        self.rows[i]:SetHidden(true)
    end

    self:LayoutRows(entries)
end
