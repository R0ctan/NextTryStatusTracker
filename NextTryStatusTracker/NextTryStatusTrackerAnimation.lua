local NTST = NextTryStatusTracker
local function L(key) return NTST.L(key) end
local function msg(text) return NTST.Msg(text) end

function NTST:ApplyBlinkVisual(row)
    local fontColor = self.sv.blinkFontColor or self.defaults.blinkFontColor
    local bgColor = self.sv.blinkBackgroundColor or self.defaults.blinkBackgroundColor

    row.label:SetColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
    row.bg:SetCenterColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    row.bg:SetEdgeColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
end

function NTST:BlinkThenApply(row, oldOnline, finalOnline)
    if row.isBlinking then
        row.pendingFinalOnline = finalOnline
        return
    end

    local flashes = zo_clamp(zo_floor(tonumber(self.sv.blinkCount) or self.defaults.blinkCount or 5), 0, 20)
    if flashes <= 0 then
        self:ApplyRowVisual(row, finalOnline)
        return
    end

    local phaseMs = zo_clamp(zo_floor(tonumber(self.sv.blinkPhaseMs) or self.defaults.blinkPhaseMs or 500), 50, 5000)
    local flashIndex = 0
    row.isBlinking = true
    row.pendingFinalOnline = nil

    local function step()
        if not row or not row.SetHidden then return end
        self:ApplyRowVisual(row, oldOnline)
        zo_callLater(function()
            if not row or not row.SetHidden then return end
            flashIndex = flashIndex + 1
            self:ApplyBlinkVisual(row)
            zo_callLater(function()
                if not row or not row.SetHidden then return end
                if flashIndex < flashes then
                    step()
                else
                    row.isBlinking = false
                    local finalState = row.pendingFinalOnline
                    row.pendingFinalOnline = nil
                    if finalState == nil then finalState = finalOnline end
                    self:ApplyRowVisual(row, finalState)
                end
            end, phaseMs)
        end, phaseMs)
    end

    step()
end

function NTST:TestBlink()
    if not self.container or not self.rows or not self.sv.enabled then return end

    self:Refresh(true)
    local entries = self:GetDisplayEntries()
    if #entries == 0 then
        msg(L("noTrackedPlayers"))
        return
    end

    for i, entry in ipairs(entries) do
        local row = self.rows[i]
        if row and not row:IsHidden() then
            self:BlinkThenApply(row, entry.isOnline, entry.isOnline)
        end
    end
end
