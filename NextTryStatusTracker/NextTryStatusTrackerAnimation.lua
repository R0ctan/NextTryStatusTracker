local NTST = NextTryStatusTracker
local function L(key) return NTST.L(key) end
local function msg(text) return NTST.Msg(text) end

function NTST:ApplyBlinkVisual(row, stateOnline)
    local fontColor = self.sv.blinkFontColor or self.defaults.blinkFontColor
    local bgColor = self.sv.blinkBackgroundColor or self.defaults.blinkBackgroundColor
    row.label:SetFont(self:GetBlinkFontString(stateOnline))
    row.label:SetColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
    row.bg:SetCenterColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    row.bg:SetEdgeColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
end

function NTST:BlinkThenApply(row, oldOnline, finalOnline, onComplete)
    row.blinkToken = (row.blinkToken or 0) + 1
    local token = row.blinkToken

    local flashes = zo_clamp(zo_floor(tonumber(self.sv.blinkCount) or self.defaults.blinkCount or 5), 0, 20)
    if flashes <= 0 then
        self:ApplyRowVisual(row, finalOnline)
        if onComplete then onComplete(row) end
        return
    end

    local phaseMs = zo_clamp(zo_floor(tonumber(self.sv.blinkPhaseMs) or self.defaults.blinkPhaseMs or 500), 50, 5000)
    local flashIndex = 0

    local function isCurrent()
        return row and row.SetHidden and row.blinkToken == token
    end

    local totalTicks = flashes * 2

    local function step()
        if not isCurrent() then return end

        flashIndex = flashIndex + 1

        if flashIndex % 2 == 1 then
            self:ApplyRowVisual(row, oldOnline)
        else
            self:ApplyBlinkVisual(row, oldOnline)
        end

        zo_callLater(function()
            if not isCurrent() then return end
            if flashIndex < totalTicks then
                step()
            else
                self:ApplyRowVisual(row, finalOnline)
                if onComplete then onComplete(row) end
            end
        end, phaseMs)
    end

    step()
end

function NTST:TestBlink()
    if not self.container or not self.rows then return end

    self:Refresh(true)
    local entries = self:GetDisplayEntries()
    if #entries == 0 then
        msg(L("noTrackedPlayers"))
        return
    end

    local pending = 0
    for i, entry in ipairs(entries) do
        local row = self.rows[i]
        if row and not row:IsHidden() then
            pending = pending + 1
        end
    end

    if pending == 0 then return end

    self.blinkInProgress = true
    self.refreshAfterBlink = false

    local function finish()
        pending = pending - 1
        if pending <= 0 then
            self.blinkInProgress = false
            self.refreshAfterBlink = false
            self:Refresh(true)
        end
    end

    for i, entry in ipairs(entries) do
        local row = self.rows[i]
        if row and not row:IsHidden() then
            self:BlinkThenApply(row, entry.isOnline, entry.isOnline, finish)
        end
    end
end
