NextTryStatusTracker = NextTryStatusTracker or {}
local NTST = NextTryStatusTracker

NTST.name = "NextTryStatusTracker"
NTST.version = "1.0.2"
NTST.savedVariablesName = "NextTryStatusTrackerSavedVariables"

local em = EVENT_MANAGER

function NTST.CopyColor(c)
    c = c or { r = 1, g = 1, b = 1, a = 1 }
    return { r = c.r or 1, g = c.g or 1, b = c.b or 1, a = c.a or 1 }
end

NTST.defaults = {
    enabled = true,
    visible = true,
    uiUnlocked = false,
    settingsPreview = true,
    layout = "vertical",
    nameMode = "account",
    sortMode = "alphabetical",
    groupByStatus = false,
    showOnlyOnline = false,
    refreshSeconds = 60,
    blinkCount = 5,
    blinkPhaseMs = 500,
    blinkFontColor = { r = 0, g = 0, b = 0, a = 1 },
    blinkBackgroundColor = { r = 1, g = 0.55, b = 0, a = 1 },
    soundEnabled = false,
    statusSound = "QUEST_ACCEPTED",
    selectedFriend = "",
    selectedGuildId = "",
    selectedGuildMember = "",
    selectedGuildMemberCharacter = "",
    manualPlayer = "",
    selectedRemovePlayer = "",
    position = nil,
    players = {},
    playerSources = {},
    display = {
        padding = 4,
        rowGap = 4,
        groupGap = 12,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        borderColor = { r = 1, g = 1, b = 1, a = 0 },
        unlockedBorderColor = { r = 1, g = 1, b = 1, a = 0.45 },
        borderSize = 0,
    },
    styles = {
        offline = {
            fontSize = 16,
            fontStyle = "normal",
            fontColor = { r = 0.78, g = 0.78, b = 0.78, a = 1 },
            backgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        },
        online = {
            fontSize = 16,
            fontStyle = "normal",
            fontColor = { r = 0, g = 0, b = 0, a = 1 },
            backgroundColor = { r = 155 / 255, g = 255 / 255, b = 129 / 255, a = 1 },
        },
    },
}

local function L(key)
    local lang = GetCVar and GetCVar("language.2") or "en"
    if lang ~= "de" and lang ~= "en" and lang ~= "fr" and lang ~= "es" and lang ~= "ru" and lang ~= "zh" then lang = "en" end
    local selected = NextTryStatusTracker_Lang and NextTryStatusTracker_Lang[lang]
    local fallback = NextTryStatusTracker_Lang and NextTryStatusTracker_Lang.en
    if selected and selected[key] then return selected[key] end
    if fallback and fallback[key] then return fallback[key] end
    return key
end
NTST.L = L

local function msg(text)
    if CHAT_SYSTEM then
        CHAT_SYSTEM:AddMessage(string.format("|cFFE000[%s]|r %s", NTST.name, text))
    end
end
NTST.Msg = msg

function NTST.CleanPlayerText(name)
    if type(name) ~= "string" then return nil end
    if zo_strformat then
        name = zo_strformat("<<1>>", name)
    end
    name = string.gsub(name, "%^%a+", "")
    name = zo_strtrim(name)
    if name == "" then return nil end
    return name
end

function NTST.NormalizeName(name)
    name = NTST.CleanPlayerText(name)
    if not name then return nil end
    return zo_strlower(name)
end

function NTST.NormalizeDisplayName(name)
    name = NTST.CleanPlayerText(name)
    if not name or name == L("none") then return nil end
    if not string.match(name, "^@") then name = "@" .. name end
    return name
end

function NTST:FindPlayerIndex(name)
    local normalized = self.NormalizeName(name)
    if not normalized or not self.sv or not self.sv.players then return nil end
    for i, playerName in ipairs(self.sv.players) do
        if self.NormalizeName(playerName) == normalized then return i end
    end
    return nil
end

local function sortCaseInsensitive(list, key)
    table.sort(list, function(a, b)
        local av = key and key(a) or a
        local bv = key and key(b) or b
        return zo_strlower(av or "") < zo_strlower(bv or "")
    end)
end

function NTST:SortTrackedPlayers()
    if self.sv and self.sv.players then
        sortCaseInsensitive(self.sv.players)
    end
end

function NTST:GetTrackedPlayers()
    local players = {}
    if self.sv and self.sv.players then
        for _, playerName in ipairs(self.sv.players) do
            players[#players + 1] = playerName
        end
    end
    return players
end

function NTST:GetFriendListData()
    local friends = {}
    local byDisplayName = {}

    if FRIENDS_LIST_MANAGER and FRIENDS_LIST_MANAGER.GetMasterList then
        local ok, masterList = pcall(function() return FRIENDS_LIST_MANAGER:GetMasterList() end)
        if ok and type(masterList) == "table" then
            for _, friend in ipairs(masterList) do
                local displayName = self.CleanPlayerText(friend.displayName or friend.name or friend.formattedDisplayName)
                if displayName then
                    local status = friend.status
                    local data = {
                        displayName = displayName,
                        characterName = self.CleanPlayerText(friend.characterName or friend.formattedCharacterName or friend.rawCharacterName),
                        status = status,
                        online = friend.online or (status and status ~= PLAYER_STATUS_OFFLINE) or false,
                        source = "friend",
                    }
                    byDisplayName[self.NormalizeName(displayName)] = data
                    friends[#friends + 1] = data
                end
            end
        end
    end

    if #friends == 0 and GetNumFriends and GetFriendInfo then
        for i = 1, GetNumFriends() do
            local displayName, _, status = GetFriendInfo(i)
            local hasCharacter, characterName
            if GetFriendCharacterInfo then
                local ok, a, b = pcall(function() return GetFriendCharacterInfo(i) end)
                if ok then hasCharacter, characterName = a, b end
            end
            displayName = self.CleanPlayerText(displayName)
            characterName = self.CleanPlayerText(characterName)
            if displayName then
                local data = {
                    displayName = displayName,
                    characterName = hasCharacter and characterName or nil,
                    status = status,
                    online = status and status ~= PLAYER_STATUS_OFFLINE or false,
                    source = "friend",
                }
                byDisplayName[self.NormalizeName(displayName)] = data
                friends[#friends + 1] = data
            end
        end
    end

    sortCaseInsensitive(friends, function(item) return item.displayName end)
    return friends, byDisplayName
end

function NTST:BuildFriendChoices()
    local choices = { L("none") }
    local values = { "" }
    local friends = self:GetFriendListData()
    for _, friend in ipairs(friends) do
        choices[#choices + 1] = friend.displayName
        values[#values + 1] = friend.displayName
    end
    return choices, values
end

function NTST:BuildTrackedChoices()
    local choices = { L("none") }
    local values = { "" }
    local players = self:GetTrackedPlayers()
    sortCaseInsensitive(players)
    for _, playerName in ipairs(players) do
        choices[#choices + 1] = playerName
        values[#values + 1] = playerName
    end
    return choices, values
end

function NTST:BuildGuildChoices()
    local choices = { L("none") }
    local values = { "" }
    if not GetNumGuilds or not GetGuildId or not GetGuildName then return choices, values end

    local guilds = {}
    for guildIndex = 1, GetNumGuilds() do
        local guildId = GetGuildId(guildIndex)
        local guildName = guildId and GetGuildName(guildId)
        if guildId and guildName and guildName ~= "" then
            guilds[#guilds + 1] = { name = guildName, id = tostring(guildId) }
        end
    end
    sortCaseInsensitive(guilds, function(item) return item.name end)
    for _, guild in ipairs(guilds) do
        choices[#choices + 1] = guild.name
        values[#values + 1] = guild.id
    end
    return choices, values
end

function NTST:GetGuildMemberData(guildId, memberIndex)
    if not guildId or not memberIndex or not GetGuildMemberInfo then return nil end
    local ok, a, b, c, d, e = pcall(function() return GetGuildMemberInfo(guildId, memberIndex) end)
    if not ok then return nil end

    local displayName, status
    if type(a) == "string" and string.sub(a, 1, 1) == "@" then
        displayName, status = a, d
    elseif type(b) == "string" and string.sub(b, 1, 1) == "@" then
        displayName, status = b, c
    elseif type(a) == "string" then
        displayName, status = a, d or c or e
    end
    displayName = self.CleanPlayerText(displayName)
    if not displayName then return nil end

    local characterName
    if GetGuildMemberCharacterInfo then
        local okChar, ca, cb = pcall(function() return GetGuildMemberCharacterInfo(guildId, memberIndex) end)
        if okChar then
            if type(ca) == "string" then characterName = self.CleanPlayerText(ca)
            elseif type(cb) == "string" then characterName = self.CleanPlayerText(cb) end
        end
    end

    return {
        displayName = displayName,
        characterName = self.CleanPlayerText(characterName),
        status = status,
        online = status and status ~= PLAYER_STATUS_OFFLINE or false,
        source = "guild",
        guildId = guildId,
        guildName = GetGuildName and GetGuildName(guildId) or nil,
    }
end

function NTST:GetGuildMemberList(guildId)
    local members = {}
    if not guildId or guildId == "" or not GetNumGuildMembers then return members end
    guildId = tonumber(guildId) or guildId
    local ok, count = pcall(function() return GetNumGuildMembers(guildId) end)
    if not ok or type(count) ~= "number" then return members end

    for memberIndex = 1, count do
        local data = self:GetGuildMemberData(guildId, memberIndex)
        if data then members[#members + 1] = data end
    end
    sortCaseInsensitive(members, function(item) return item.displayName end)
    return members
end

function NTST:BuildGuildMemberChoices(guildId)
    local choices = { L("none") }
    local values = { "" }
    self.guildMemberSelectionCache = {}
    local members = self:GetGuildMemberList(guildId)
    for _, member in ipairs(members) do
        local label = member.displayName
        if member.characterName and member.characterName ~= "" then
            label = label .. "  (" .. member.characterName .. ")"
        end
        choices[#choices + 1] = label
        values[#values + 1] = member.displayName
        self.guildMemberSelectionCache[self.NormalizeName(member.displayName)] = member
    end
    return choices, values
end

function NTST:GetRelevantGuildIds()
    local relevant = {}
    local sources = self.sv and self.sv.playerSources or {}
    for _, playerName in ipairs(self:GetTrackedPlayers()) do
        local source = sources[self.NormalizeName(playerName)]
        if source and source.source == "guild" and source.guildId then
            relevant[tostring(source.guildId)] = tonumber(source.guildId) or source.guildId
        end
    end
    return relevant
end

function NTST:BuildGuildStatusMap()
    local map = {}
    for _, guildId in pairs(self:GetRelevantGuildIds()) do
        local members = self:GetGuildMemberList(guildId)
        for _, member in ipairs(members) do
            map[self.NormalizeName(member.displayName)] = member
        end
    end
    return map
end

function NTST:GetDisplayNameForPlayer(playerName, friendData)
    local accountName = playerName or ""
    local characterName = friendData and friendData.characterName
    if characterName == "" then characterName = nil end

    if self.sv.nameMode == "character" then
        return characterName or accountName
    elseif self.sv.nameMode == "accountCharacter" then
        return characterName and (accountName .. " " .. characterName) or accountName
    elseif self.sv.nameMode == "characterAccount" then
        return characterName and (characterName .. " " .. accountName) or accountName
    end

    return accountName
end

function NTST:GetDisplayEntries()
    local _, friendMap = self:GetFriendListData()
    local guildMap = self:BuildGuildStatusMap()
    local entries = {}

    for _, playerName in ipairs(self:GetTrackedPlayers()) do
        local key = self.NormalizeName(playerName)
        local sourceData = self.sv.playerSources and self.sv.playerSources[key]
        local playerData = friendMap[key] or guildMap[key]
        if not playerData and sourceData and sourceData.characterName then
            playerData = { characterName = sourceData.characterName, online = false, source = sourceData.source }
        elseif playerData and sourceData and not playerData.characterName and sourceData.characterName then
            playerData.characterName = sourceData.characterName
        end
        local isOnline = playerData and playerData.online or false
        if not self.sv.showOnlyOnline or isOnline then
            entries[#entries + 1] = {
                playerName = playerName,
                friendData = playerData,
                isOnline = isOnline,
                displayName = self:GetDisplayNameForPlayer(playerName, playerData),
            }
        end
    end

    local function alpha(a, b)
        return zo_strlower(a.displayName or a.playerName or "") < zo_strlower(b.displayName or b.playerName or "")
    end

    table.sort(entries, function(a, b)
        if a.isOnline ~= b.isOnline then
            if self.sv.groupByStatus or self.sv.sortMode == "onlineFirst" then
                return self.sv.sortMode == "offlineFirst" and not a.isOnline or a.isOnline
            elseif self.sv.sortMode == "offlineFirst" then
                return not a.isOnline
            end
        end
        return alpha(a, b)
    end)

    if self.sv.groupByStatus then
        local previousStatus
        for i, entry in ipairs(entries) do
            entry.groupBreakBefore = i > 1 and previousStatus ~= entry.isOnline
            previousStatus = entry.isOnline
        end
    end

    return entries
end

function NTST:AddPlayer(name, sourceData)
    name = self.NormalizeDisplayName(name)
    if not name then
        msg(L("invalidName"))
        return
    end
    if self:FindPlayerIndex(name) then
        msg(name .. " " .. L("alreadyTracked"))
        return
    end
    self.sv.players[#self.sv.players + 1] = name
    self.sv.playerSources[self.NormalizeName(name)] = sourceData or { source = "manual" }
    self:SortTrackedPlayers()
    self.sv.selectedRemovePlayer = ""
    msg(name .. " " .. L("added"))
    self:Refresh()
    self:RefreshSettingsDropdowns()
end

function NTST:AddSelectedGuildMember()
    local memberName = self.sv.selectedGuildMember
    local guildId = tonumber(self.sv.selectedGuildId)
    if not memberName or memberName == "" or not guildId then
        msg(L("invalidName"))
        return
    end
    local cacheKey = self.NormalizeName(memberName)
    local cached = self.guildMemberSelectionCache and self.guildMemberSelectionCache[cacheKey]
    self:AddPlayer(memberName, {
        source = "guild",
        guildId = guildId,
        guildName = GetGuildName and GetGuildName(guildId) or nil,
        characterName = cached and cached.characterName or self.sv.selectedGuildMemberCharacter,
    })
    self.sv.selectedGuildMember = ""
    self.sv.selectedGuildMemberCharacter = ""
end

function NTST:RemovePlayer(name)
    local index = self:FindPlayerIndex(name)
    if not index then return end
    local removed = table.remove(self.sv.players, index)
    if self.sv.playerSources then self.sv.playerSources[self.NormalizeName(removed)] = nil end
    self.sv.selectedRemovePlayer = ""
    msg(removed .. " " .. L("removed"))
    self:Refresh()
    self:RefreshSettingsDropdowns()
end

function NTST:SetEnabled(enabled)
    self.sv.enabled = enabled and true or false
    self:ApplyVisibility()
    if self.sv.enabled then self:Refresh(true) end
end

function NTST:SetVisible(visible)
    self.sv.visible = visible and true or false
    self:ApplyVisibility()
    if self.sv.enabled and self.sv.visible then self:Refresh(true) end
end

function NTST:ToggleVisible()
    self:SetVisible(not self.sv.visible)
end

function NextTryStatusTracker_ToggleWindow()
    if NextTryStatusTracker and NextTryStatusTracker.ToggleVisible then
        NextTryStatusTracker:ToggleVisible()
    end
end

function NTST:PlayStatusSoundKey(soundKey)
    if not soundKey or soundKey == "" then return end
    if SOUNDS and SOUNDS[soundKey] and PlaySound then
        pcall(function() PlaySound(SOUNDS[soundKey]) end)
    end
end

function NTST:PlayStatusSound()
    if not self.sv.soundEnabled then return end
    self:PlayStatusSoundKey(self.sv.statusSound)
end

function NTST:TestStatusSound()
    self:PlayStatusSoundKey(self.sv.statusSound)
end

local function ensureTable(parent, key, default)
    if type(parent[key]) ~= "table" then parent[key] = NTST.CopyColor(default) end
end

local function ensureNumber(parent, key, default)
    if type(parent[key]) ~= "number" then parent[key] = default end
end

local function ensureString(parent, key, default)
    if type(parent[key]) ~= "string" then parent[key] = default end
end

local function ensureBool(parent, key, default)
    if type(parent[key]) ~= "boolean" then parent[key] = default end
end

function NTST:ApplyMigrations()
    local sv = self.sv
    local d = self.defaults

    ensureBool(sv, "enabled", d.enabled)
    ensureBool(sv, "visible", d.visible)
    ensureBool(sv, "uiUnlocked", d.uiUnlocked)
    ensureBool(sv, "settingsPreview", d.settingsPreview)
    ensureString(sv, "layout", d.layout)
    ensureString(sv, "nameMode", d.nameMode)
    ensureString(sv, "sortMode", d.sortMode)
    ensureBool(sv, "groupByStatus", d.groupByStatus)
    ensureBool(sv, "showOnlyOnline", d.showOnlyOnline)
    ensureNumber(sv, "refreshSeconds", d.refreshSeconds)
    ensureNumber(sv, "blinkCount", d.blinkCount)
    ensureNumber(sv, "blinkPhaseMs", d.blinkPhaseMs)
    ensureTable(sv, "blinkFontColor", d.blinkFontColor)
    ensureTable(sv, "blinkBackgroundColor", d.blinkBackgroundColor)
    ensureBool(sv, "soundEnabled", d.soundEnabled)
    ensureString(sv, "statusSound", d.statusSound)
    if sv.statusSound == "NEW_NOTIFICATION" then sv.statusSound = d.statusSound end
    ensureString(sv, "selectedGuildId", d.selectedGuildId)
    ensureString(sv, "selectedGuildMember", d.selectedGuildMember)
    ensureString(sv, "selectedGuildMemberCharacter", d.selectedGuildMemberCharacter)

    if type(sv.players) ~= "table" then sv.players = {} end
    if type(sv.playerSources) ~= "table" then sv.playerSources = {} end
    for _, playerName in ipairs(sv.players) do
        local key = self.NormalizeName(playerName)
        if key and type(sv.playerSources[key]) ~= "table" then
            sv.playerSources[key] = { source = "manual" }
        end
    end
    if type(sv.position) == "table" and (type(sv.position.x) ~= "number" or type(sv.position.y) ~= "number") then sv.position = nil end

    if type(sv.display) ~= "table" then sv.display = {} end
    ensureNumber(sv.display, "padding", d.display.padding)
    ensureNumber(sv.display, "rowGap", d.display.rowGap)
    ensureNumber(sv.display, "groupGap", d.display.groupGap)
    ensureNumber(sv.display, "borderSize", d.display.borderSize)
    ensureTable(sv.display, "backgroundColor", d.display.backgroundColor)
    ensureTable(sv.display, "borderColor", d.display.borderColor)
    ensureTable(sv.display, "unlockedBorderColor", d.display.unlockedBorderColor)

    if type(sv.styles) ~= "table" then sv.styles = {} end
    for _, state in ipairs({ "offline", "online" }) do
        if type(sv.styles[state]) ~= "table" then sv.styles[state] = {} end
        ensureNumber(sv.styles[state], "fontSize", d.styles[state].fontSize)
        ensureString(sv.styles[state], "fontStyle", d.styles[state].fontStyle)
        if sv.styles[state].fontStyle ~= "normal" and sv.styles[state].fontStyle ~= "bold" then
            sv.styles[state].fontStyle = d.styles[state].fontStyle
        end
        ensureTable(sv.styles[state], "fontColor", d.styles[state].fontColor)
        ensureTable(sv.styles[state], "backgroundColor", d.styles[state].backgroundColor)
    end

    if sv.nameMode ~= "account" and sv.nameMode ~= "character" and sv.nameMode ~= "accountCharacter" and sv.nameMode ~= "characterAccount" then
        sv.nameMode = d.nameMode
    end
    if sv.sortMode ~= "alphabetical" and sv.sortMode ~= "onlineFirst" and sv.sortMode ~= "offlineFirst" then
        sv.sortMode = d.sortMode
    end

    sv.dataVersion = 10001
end

function NTST:RegisterEvents()
    em:RegisterForEvent(self.name, EVENT_FRIEND_PLAYER_STATUS_CHANGED, function()
        zo_callLater(function() self:Refresh(false) end, 250)
    end)
    if EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED then
        em:RegisterForEvent(self.name, EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED, function()
            zo_callLater(function() self:Refresh(false) end, 250)
        end)
    end
    self:UpdateRefreshInterval()
end

function NTST:UpdateRefreshInterval()
    em:UnregisterForUpdate(self.name .. "Refresh")
    em:RegisterForUpdate(self.name .. "Refresh", self.sv.refreshSeconds * 1000, function()
        self:Refresh(false)
    end)
end

function NTST:Initialize()
    self.sv = ZO_SavedVars:NewAccountWide(self.savedVariablesName, 1, nil, self.defaults)
    self:ApplyMigrations()
    self:CreateUI()
    self:RegisterSceneVisibilityCallbacks()
    self:SetUnlocked(self.sv.uiUnlocked)
    self:CreateSettings()
    self:RegisterEvents()
    zo_callLater(function() self:Refresh(true) end, 1000)
end

local function OnAddOnLoaded(_, addonName)
    if addonName ~= NTST.name then return end
    em:UnregisterForEvent(NTST.name, EVENT_ADD_ON_LOADED)
    NTST:Initialize()
end

em:RegisterForEvent(NTST.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
