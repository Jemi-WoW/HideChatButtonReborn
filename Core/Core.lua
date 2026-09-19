local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.frames = {}
ns.pendingIndicator = nil

local defaults = {
    button = {
        point = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x = 0,
        y = 0,
        size = 24,
        opacity = 1,
    },
    toast = {
        disableAll = false,
        separateOpacity = false,
        opacity = 1,
        events = {
            whisper = true,
            guild = true,
            officer = true,
            party = true,
            partyLeader = true,
            raid = true,
            raidLeader = true,
            raidWarning = true,
            instance = true,
            instanceLeader = true,
            battleground = false,
            battlegroundLeader = false,
        },
    },
    anchorMode = false,
    hidden = false,
}

local indicatorMap = {
    CHAT_MSG_WHISPER = { text = "W", color = { 1.00, 0.00, 1.00 }, optionKey = "whisper", label = "Whisper" },
    CHAT_MSG_GUILD = { text = "G", color = { 0.40, 0.80, 0.00 }, optionKey = "guild", label = "Guild" },
    CHAT_MSG_OFFICER = { text = "O", color = { 0.40, 0.80, 0.00 }, optionKey = "officer", label = "Officer" },
    CHAT_MSG_PARTY = { text = "P", color = { 0.40, 0.40, 1.00 }, optionKey = "party", label = "Party" },
    CHAT_MSG_PARTY_LEADER = { text = "PL", color = { 0.40, 0.40, 1.00 }, optionKey = "partyLeader", label = "Party Leader" },
    CHAT_MSG_RAID = { text = "R", color = { 0.80, 0.40, 0.00 }, optionKey = "raid", label = "Raid" },
    CHAT_MSG_RAID_LEADER = { text = "RL", color = { 0.80, 0.40, 0.00 }, optionKey = "raidLeader", label = "Raid Leader" },
    CHAT_MSG_RAID_WARNING = { text = "RW", color = { 1.00, 0.20, 0.20 }, optionKey = "raidWarning", label = "Raid Warning" },
    CHAT_MSG_INSTANCE_CHAT = { text = "I", color = { 1.00, 0.50, 0.00 }, optionKey = "instance", label = "Instance Chat" },
    CHAT_MSG_INSTANCE_CHAT_LEADER = { text = "IL", color = { 1.00, 0.50, 0.00 }, optionKey = "instanceLeader", label = "Instance Leader" },
    CHAT_MSG_BATTLEGROUND = { text = "BG", color = { 0.80, 0.40, 0.20 }, optionKey = "battleground", label = "Battleground" },
    CHAT_MSG_BATTLEGROUND_LEADER = { text = "BGL", color = { 0.80, 0.40, 0.20 }, optionKey = "battlegroundLeader", label = "Battleground Leader" },
}

local registeredIndicatorEvents = {}

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then
        return dst
    end

    if type(dst) ~= "table" then
        dst = {}
    end

    for key, value in pairs(src) do
        if type(value) == "table" then
            dst[key] = CopyDefaults(value, dst[key])
        elseif dst[key] == nil then
            dst[key] = value
        end
    end

    return dst
end

local function SafeRegisterEvent(frame, eventName)
    if registeredIndicatorEvents[eventName] then
        return true
    end

    local ok = pcall(function()
        frame:RegisterEvent(eventName)
    end)

    if ok then
        registeredIndicatorEvents[eventName] = true
        return true
    end

    return false
end

local function GetMessageGUID(...)
    return select(12, ...)
end

function ns:GetIndicatorInfo(event)
    return indicatorMap[event]
end

function ns:GetToastEventDefinitions()
    local definitions = {}

    for eventName, info in pairs(indicatorMap) do
        if self:IsChatEventSupported(eventName) then
            definitions[#definitions + 1] = {
                event = eventName,
                key = info.optionKey,
                label = info.label,
                color = info.color,
            }
        end
    end

    table.sort(definitions, function(a, b)
        return a.label < b.label
    end)

    return definitions
end

function ns:GetDB()
    return HideChatButtonRebornDB
end

function ns:GetPendingIndicator()
    return self.pendingIndicator
end

function ns:SetPendingIndicator(text, color)
    self.pendingIndicator = {
        text = text,
        color = color,
    }

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end
end

function ns:ClearPendingIndicator()
    self.pendingIndicator = nil

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end
end

function ns:GetToastDB()
    return self:GetDB().toast
end

function ns:IsToastDisabled()
    return self:GetToastDB().disableAll and true or false
end

function ns:SetToastDisabled(disabled)
    self:GetToastDB().disableAll = disabled and true or false

    if disabled and self.HideToast then
        self:HideToast(true)
    end

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end


function ns:IsToastEnabledForEvent(event)
    local info = indicatorMap[event]
    if not info or not info.optionKey then
        return false
    end

    local toastDB = self:GetToastDB()
    return toastDB.events[info.optionKey] and true or false
end

function ns:SetToastEventEnabled(optionKey, enabled)
    self:GetToastDB().events[optionKey] = enabled and true or false

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:UseSeparateToastOpacity()
    return self:GetToastDB().separateOpacity and true or false
end

function ns:SetSeparateToastOpacity(enabled)
    self:GetToastDB().separateOpacity = enabled and true or false

    if self.UpdateToastOpacity then
        self:UpdateToastOpacity()
    end

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:GetToastOpacity()
    local toastDB = self:GetToastDB()

    if toastDB.separateOpacity then
        return math.max(0.2, math.min(1, toastDB.opacity or 1))
    end

    return math.max(0.2, math.min(1, self:GetDB().button.opacity or 1))
end

function ns:SetToastOpacity(opacity)
    self:GetToastDB().opacity = math.max(0.2, math.min(1, opacity or 1))

    if self.UpdateToastOpacity then
        self:UpdateToastOpacity()
    end

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:SaveButtonPosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local db = self:GetDB()

    db.button.point = point or defaults.button.point
    db.button.relativePoint = relativePoint or defaults.button.relativePoint
    db.button.x = math.floor((x or defaults.button.x) + 0.5)
    db.button.y = math.floor((y or defaults.button.y) + 0.5)

    if self.UpdateToastPosition then
        self:UpdateToastPosition()
    end
end

function ns:ApplyStoredButtonPosition()
    local button = self.frames.button
    if not button then
        return
    end

    local db = self:GetDB()
    button:ClearAllPoints()
    button:SetPoint(
        db.button.point or defaults.button.point,
        UIParent,
        db.button.relativePoint or defaults.button.relativePoint,
        db.button.x or defaults.button.x,
        db.button.y or defaults.button.y
    )

    if self.frames.anchor then
        self:UpdateAnchor()
    end

    if self.UpdateToastPosition then
        self:UpdateToastPosition()
    end
end

function ns:ResetButtonPosition()
    local db = self:GetDB()
    db.button.point = defaults.button.point
    db.button.relativePoint = defaults.button.relativePoint
    db.button.x = defaults.button.x
    db.button.y = defaults.button.y

    self:ApplyStoredButtonPosition()
end

function ns:ResetButtonSize()
    local db = self:GetDB()
    db.button.size = defaults.button.size
    db.button.opacity = defaults.button.opacity

    if self.ApplyButtonSettings then
        self:ApplyButtonSettings()
    end

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:ResetToastOpacity()
    self:GetToastDB().opacity = defaults.toast.opacity
    self:GetToastDB().separateOpacity = defaults.toast.separateOpacity

    if self.UpdateToastOpacity then
        self:UpdateToastOpacity()
    end

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:SetButtonToCorner(point)
    local db = self:GetDB()
    db.button.point = point
    db.button.relativePoint = point
    db.button.x = 0
    db.button.y = 0

    self:ApplyStoredButtonPosition()

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:RefreshAll()
    if self.ApplyButtonSettings then
        self:ApplyButtonSettings()
    end

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end

    if self.UpdateAnchorMode then
        self:UpdateAnchorMode()
    end

    if self.UpdateToastPosition then
        self:UpdateToastPosition()
    end

    if self.UpdateToastOpacity then
        self:UpdateToastOpacity()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            HideChatButtonRebornDB = CopyDefaults(defaults, HideChatButtonRebornDB)
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        ns:CreateButton()
        ns:CreateAnchor()
        ns:CreateToast()
        ns:InitializeChatManager()
        ns:CreateSettings()
        ns:ApplyInitialState()
        ns:RefreshAll()

        for chatEvent in pairs(indicatorMap) do
            if ns:IsChatEventSupported(chatEvent) then
                SafeRegisterEvent(eventFrame, chatEvent)
            end
        end
        return
    end

    local indicator = indicatorMap[event]
    if indicator and ns.IsChatHidden and ns:IsChatHidden() then
        local message = ...
        local sender = select(2, ...)
        local guid = GetMessageGUID(...)
        ns:SetPendingIndicator(indicator.text, indicator.color)

        if ns.ShowToast then
            ns:ShowToast(event, sender, message, guid)
        end
    end
end)
