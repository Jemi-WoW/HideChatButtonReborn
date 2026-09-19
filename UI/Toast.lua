local _, ns = ...

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local SHOW_TIME = 3.25
local FADE_TIME = 0.45
local LIST_SHOW_TIME = 6
local EMPTY_LIST_SHOW_TIME = 2.5
local MAX_BODY_CHARS = 10
local MAX_HISTORY = 10

local history = {}
local missedTotal = 0

local function GetBaseFont()
    return ns:GetFontPath(GameFontHighlight)
end

local function TrimRealm(name)
    if not name then
        return "Unknown"
    end

    return string.match(name, "^[^-]+") or name
end

local function TrimMessage(message)
    message = tostring(message or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    message = message:gsub("\n", " "):gsub("\r", "")
    message = message:gsub("%s+", " ")

    if string.len(message) > MAX_BODY_CHARS then
        return string.sub(message, 1, MAX_BODY_CHARS) .. "..."
    end

    return message
end

local function GetDefaultColor()
    local color = NORMAL_FONT_COLOR
    if color then
        return color.r, color.g, color.b
    end
    return 1, 0.82, 0
end

local function GetClassColor(guid)
    if not guid then
        return GetDefaultColor()
    end

    local ok, _, class = pcall(GetPlayerInfoByGUID, guid)
    local color = ok and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then
        return color.r, color.g, color.b
    end

    return GetDefaultColor()
end

local function GetHexColor(r, g, b)
    r = math.floor((r or 1) * 255 + 0.5)
    g = math.floor((g or 1) * 255 + 0.5)
    b = math.floor((b or 1) * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

local function GetIndicatorHexColor(indicator)
    local color = indicator and indicator.color
    if not color then
        local r, g, b = GetDefaultColor()
        return GetHexColor(r, g, b)
    end
    return GetHexColor(color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1)
end

local function GetMissedCountLabel(count)
    if count > MAX_HISTORY then
        return "10+"
    end
    return tostring(count)
end

local function ApplyBackdrop(frame, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.88)
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
end

local function SetFonts(toast)
    local font, flags = GetBaseFont()
    toast.Name:SetFont(font, 13, flags)
    toast.Message:SetFont(font, 12, flags)
end

local function LayoutSingleToast(toast)
    toast.Name:SetWidth(420)
    toast.Message:SetWidth(420)

    toast.Name:ClearAllPoints()
    toast.Message:ClearAllPoints()
    toast.Name:SetPoint("TOPLEFT", 10, -8)
    toast.Message:SetPoint("TOPLEFT", toast.Name, "BOTTOMLEFT", 0, -2)

    local width = math.max(toast.Name:GetStringWidth(), toast.Message:GetStringWidth()) + 20
    local height = toast.Name:GetStringHeight() + toast.Message:GetStringHeight() + 22

    width = math.max(120, math.min(width, 440))
    height = math.max(40, height)

    toast:SetSize(width, height)
end

local function CreateSingleToastFrame(frameName)
    local toast = CreateFrame("Frame", frameName, UIParent, backdropTemplate)
    toast:SetFrameStrata("DIALOG")
    toast:SetClampedToScreen(true)
    toast:EnableMouse(false)

    toast.Name = toast:CreateFontString(nil, "OVERLAY")
    toast.Name:SetJustifyH("LEFT")
    toast.Name:SetJustifyV("TOP")

    toast.Message = toast:CreateFontString(nil, "OVERLAY")
    toast.Message:SetJustifyH("LEFT")
    toast.Message:SetJustifyV("TOP")

    SetFonts(toast)
    ApplyBackdrop(toast, { 0.72, 0.58, 0.18 })
    toast.baseAlpha = 1
    toast:Hide()

    return toast
end

local function CreateListToastFrame(frameName)
    local toast = CreateFrame("Frame", frameName, UIParent, backdropTemplate)
    toast:SetFrameStrata("DIALOG")
    toast:SetClampedToScreen(true)
    toast:EnableMouse(false)

    toast.Title = toast:CreateFontString(nil, "OVERLAY")
    toast.Title:SetJustifyH("LEFT")
    toast.Title:SetJustifyV("TOP")

    toast.Body = toast:CreateFontString(nil, "OVERLAY")
    toast.Body:SetJustifyH("LEFT")
    toast.Body:SetJustifyV("TOP")

    local font, flags = GetBaseFont()
    toast.Title:SetFont(font, 13, flags)
    toast.Body:SetFont(font, 12, flags)

    ApplyBackdrop(toast, { 0.72, 0.58, 0.18 })
    toast.baseAlpha = 1
    toast:Hide()

    return toast
end

local function BuildEntry(event, sender, message, guid)
    local indicator = ns:GetIndicatorInfo(event)
    if not indicator then
        return nil
    end

    local nameText = TrimRealm(sender)
    local bodyText = TrimMessage(message)
    local nameR, nameG, nameB = GetClassColor(guid)

    return {
        event = event,
        sender = sender,
        guid = guid,
        indicator = indicator,
        channelText = indicator.text or "?",
        nameText = nameText,
        bodyText = bodyText,
        nameR = nameR,
        nameG = nameG,
        nameB = nameB,
        timestamp = GetTime(),
    }
end

local function ApplyEntryToSingleToast(toast, entry)
    ApplyBackdrop(toast, entry.indicator.color)

    toast.Name:SetText(entry.nameText)
    toast.Name:SetTextColor(entry.nameR, entry.nameG, entry.nameB)

    toast.Message:SetText(entry.bodyText)
    toast.Message:SetTextColor(1, 1, 1)

    LayoutSingleToast(toast)
end

local function StartFade(frame, duration)
    frame.fadeStart = GetTime()
    frame.fadeDuration = duration or FADE_TIME
    frame.startAlpha = frame:GetAlpha()
    frame.hideAt = nil
end

local function ClearFrameTimers(frame)
    frame.hideAt = nil
    frame.fadeStart = nil
    frame.fadeDuration = nil
    frame.startAlpha = nil
    frame.offsetX = 0
end

function ns:GetMissedMessageCount()
    return missedTotal
end

function ns:GetMissedMessages()
    return history
end

function ns:ClearMissedMessages()
    wipe(history)
    missedTotal = 0

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end
end

function ns:UpdateToastPosition()
    local button = self.frames.button
    if not button then
        return
    end

    local framesToPosition = {
        self.frames.toast,
        self.frames.toastList,
    }

    for _, frame in ipairs(framesToPosition) do
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", button, "TOPLEFT", frame.offsetX or 0, 8)
        end
    end
end

function ns:UpdateToastOpacity()
    local framesToUpdate = {
        self.frames.toast,
        self.frames.toastList,
    }

    local baseAlpha = self.GetToastOpacity and self:GetToastOpacity() or 1

    for _, frame in ipairs(framesToUpdate) do
        if frame then
            frame.baseAlpha = baseAlpha
            if frame:IsShown() and not frame.fadeStart then
                frame:SetAlpha(baseAlpha)
            end
        end
    end
end

local function UpdateListToast(frame, now)
    if not frame:IsShown() then
        return
    end

    if frame.hideAt and now >= frame.hideAt and not frame.fadeStart then
        StartFade(frame, FADE_TIME)
    end

    if frame.fadeStart then
        local duration = frame.fadeDuration or FADE_TIME
        local elapsed = now - frame.fadeStart
        if elapsed >= duration then
            frame:Hide()
            frame:SetAlpha(frame.baseAlpha or 1)
            ClearFrameTimers(frame)
            frame:SetScript("OnUpdate", nil)
            return
        end

        local startAlpha = frame.startAlpha or (frame.baseAlpha or 1)
        frame:SetAlpha(startAlpha * (1 - (elapsed / duration)))
    end
end

local function EnsureListToastController(frame)
    if not frame then
        return
    end

    frame:SetScript("OnUpdate", function(self)
        local now = GetTime()

        if not ns:IsChatHidden() then
            self:Hide()
            self:SetAlpha(self.baseAlpha or 1)
            ClearFrameTimers(self)
            self:SetScript("OnUpdate", nil)
            return
        end

        UpdateListToast(self, now)
    end)
end

local function UpdateSingleToast(frame, now)
    if not frame:IsShown() then
        return
    end

    if frame.hideAt and now >= frame.hideAt and not frame.fadeStart then
        StartFade(frame, FADE_TIME)
    end

    if frame.fadeStart then
        local duration = frame.fadeDuration or FADE_TIME
        local elapsed = now - frame.fadeStart
        if elapsed >= duration then
            frame:Hide()
            frame:SetAlpha(frame.baseAlpha or 1)
            frame.currentEntry = nil
            ClearFrameTimers(frame)
            return
        end

        local startAlpha = frame.startAlpha or (frame.baseAlpha or 1)
        frame:SetAlpha(startAlpha * (1 - (elapsed / duration)))
    end
end

local function RefreshToastController()
    local toast = ns.frames.toast
    if not toast then
        return
    end

    if not toast.controllerAttached then
        toast.controllerAttached = true
        toast:SetScript("OnUpdate", function()
            local now = GetTime()

            if not ns:IsChatHidden() then
                ns:HideToast(true)
                return
            end

            if ns:IsToastDisabled() then
                local listToast = ns.frames.toastList
                if not (listToast and listToast:IsShown()) then
                    ns:HideToast(true)
                end
            end

            UpdateSingleToast(ns.frames.toast, now)
            UpdateListToast(ns.frames.toastList, now)
        end)
    end
end

function ns:HideToast(immediate)
    local framesToHide = {
        self.frames.toast,
        self.frames.toastList,
    }

    for _, frame in ipairs(framesToHide) do
        if frame then
            frame.currentEntry = nil
            if immediate then
                frame:Hide()
                frame:SetAlpha(frame.baseAlpha or 1)
                ClearFrameTimers(frame)
            else
                StartFade(frame, FADE_TIME)
            end
        end
    end
end

function ns:ShowMissedMessagesToast()
    local listToast = self.frames.toastList
    if not listToast then
        return
    end

    local count = missedTotal
    local titleCount = GetMissedCountLabel(count)
    local titleText = count == 0 and "Missed messages" or (titleCount == "1" and "1 missed message" or (titleCount .. " missed messages"))
    local lines = {}

    if count == 0 then
        lines[1] = "No missed messages yet."
    else
        for index = #history, 1, -1 do
            local entry = history[index]
            local nameHex = GetHexColor(entry.nameR, entry.nameG, entry.nameB)
            local channelHex = GetIndicatorHexColor(entry.indicator)
            local channelText = entry.channelText or "?"
            lines[#lines + 1] = string.format("|cff%s%s|r |cff%s[%s]|r: %s", nameHex, entry.nameText, channelHex, channelText, entry.bodyText)
        end
    end

    listToast.Title:SetText(titleText)
    listToast.Title:SetTextColor(1, 0.82, 0)
    listToast.Body:SetText(table.concat(lines, "\n"))
    listToast.Body:SetTextColor(1, 1, 1)

    listToast.Title:ClearAllPoints()
    listToast.Body:ClearAllPoints()
    listToast.Title:SetPoint("TOPLEFT", 10, -8)
    listToast.Body:SetPoint("TOPLEFT", listToast.Title, "BOTTOMLEFT", 0, -4)
    listToast.Body:SetWidth(420)

    local width = math.max(listToast.Title:GetStringWidth(), listToast.Body:GetStringWidth()) + 20
    local height = listToast.Title:GetStringHeight() + listToast.Body:GetStringHeight() + 24
    listToast:SetSize(math.max(170, math.min(width, 440)), math.max(44, height))

    ApplyBackdrop(listToast, { 0.72, 0.58, 0.18 })
    self:UpdateToastPosition()
    self:UpdateToastOpacity()

    ClearFrameTimers(listToast)
    listToast:SetAlpha(listToast.baseAlpha or 1)
    listToast:Show()

    local showTime = (count == 0) and EMPTY_LIST_SHOW_TIME or LIST_SHOW_TIME
    listToast.hideAt = GetTime() + showTime
    EnsureListToastController(listToast)
    RefreshToastController()
end

function ns:ShowToast(event, sender, message, guid)
    local toast = self.frames.toast
    if not toast or not self:IsChatHidden() then
        return
    end

    local entry = BuildEntry(event, sender, message, guid)
    if not entry then
        return
    end

    missedTotal = missedTotal + 1
    history[#history + 1] = entry
    while #history > MAX_HISTORY do
        table.remove(history, 1)
    end

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end

    if self:IsToastDisabled() or not self:IsToastEnabledForEvent(event) then
        return
    end

    RefreshToastController()

    toast.currentEntry = entry
    ClearFrameTimers(toast)
    ApplyEntryToSingleToast(toast, entry)
    self:UpdateToastPosition()
    self:UpdateToastOpacity()
    toast:SetAlpha(toast.baseAlpha or 1)
    toast:Show()
    toast.hideAt = GetTime() + SHOW_TIME
end

function ns:CreateToast()
    if self.frames.toast then
        return self.frames.toast
    end

    local toast = CreateSingleToastFrame("HideChatButtonRebornToast")
    local listToast = CreateListToastFrame("HideChatButtonRebornToastList")

    self.frames.toast = toast
    self.frames.toastList = listToast

    self:UpdateToastPosition()
    self:UpdateToastOpacity()
    RefreshToastController()

    return toast
end
