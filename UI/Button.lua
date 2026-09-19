local _, ns = ...

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local DEFAULT_COLOR = { 1.0, 0.82, 0.0 }

local function GetBaseFont()
    return ns:GetFontPath(GameFontNormalLarge)
end

local function GetTextSize(buttonSize, text)
    local length = text and string.len(text) or 1

    if length <= 1 then
        return math.max(12, math.floor(buttonSize * 0.62 + 0.5))
    elseif length == 2 then
        return math.max(10, math.floor(buttonSize * 0.40 + 0.5))
    end

    return math.max(8, math.floor(buttonSize * 0.30 + 0.5))
end

local function ApplyTextStyle(fontString, buttonSize, text, color)
    local font, flags = GetBaseFont()
    local size = GetTextSize(buttonSize, text)

    fontString:SetFont(font, size, flags)
    fontString:SetTextColor(color[1], color[2], color[3])
end

local function SetButtonStyle(button, hovered)
    local borderR, borderG, borderB = 0.72, 0.58, 0.18
    local bgAlpha = hovered and 0.95 or 0.82

    button:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button:SetBackdropColor(0.05, 0.05, 0.05, bgAlpha)
    button:SetBackdropBorderColor(borderR, borderG, borderB, 1)
end

local function AddTooltipLine(tooltip, text, r, g, b)
    if text and text ~= "" then
        tooltip:AddLine(text, r or 0.8, g or 0.8, b or 0.8)
    end
end

local function FormatMissedCount(count)
    if count > 10 then
        return "10+"
    end
    return tostring(count)
end

local function UpdatePulseVisual(button, buttonSize)
    if not button or not button.PulseFrame or not button.PulseFill then
        return
    end

    local inset = math.max(3, math.floor(buttonSize * 0.14 + 0.5))
    local innerInset = math.max(2, math.floor(buttonSize * 0.09 + 0.5))

    button.PulseFrame:ClearAllPoints()
    button.PulseFrame:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    button.PulseFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)

    button.PulseFill:ClearAllPoints()
    button.PulseFill:SetPoint("TOPLEFT", button.PulseFrame, "TOPLEFT", innerInset, -innerInset)
    button.PulseFill:SetPoint("BOTTOMRIGHT", button.PulseFrame, "BOTTOMRIGHT", -innerInset, innerInset)
end


function ns:ApplyButtonSettings()
    local button = self.frames.button
    if not button then
        return
    end

    local db = self:GetDB()
    local size = math.max(18, math.min(64, db.button.size or 24))
    local opacity = math.max(0.2, math.min(1, db.button.opacity or 1))

    button:SetSize(size, size)
    button:SetAlpha(opacity)
    UpdatePulseVisual(button, size)

    if self.frames.anchor and self.frames.anchor:IsShown() then
        self:UpdateAnchor()
    end

    if self.UpdateToastPosition then
        self:UpdateToastPosition()
    end

    if self.UpdateToastOpacity then
        self:UpdateToastOpacity()
    end

    self:UpdateButtonVisual()
end

function ns:UpdateButtonVisual()
    local button = self.frames.button
    if not button or not button.Text then
        return
    end

    local db = self:GetDB()
    local size = math.max(18, math.min(64, db.button.size or 24))
    local indicator = self.GetPendingIndicator and self:GetPendingIndicator() or nil

    local missedCount = self.GetMissedMessageCount and self:GetMissedMessageCount() or 0
    local shouldPulse = missedCount > 0

    if button.PulseFrame and button.PulseFill then
        if shouldPulse then
            button.pulseStart = button.pulseStart or GetTime()
            button.PulseFrame:Show()
            button.PulseFill:Show()
        else
            button.pulseStart = nil
            button.PulseFrame:SetAlpha(0)
            button.PulseFill:SetAlpha(0)
            button.PulseFrame:Hide()
            button.PulseFill:Hide()
        end
    end

    local text = "−"
    local color = DEFAULT_COLOR
    local tooltip = "Hide chat"

    if self:IsChatHidden() then
        if indicator and indicator.text and indicator.text ~= "" then
            text = indicator.text
            color = indicator.color or DEFAULT_COLOR
            tooltip = "Show chat"
        else
            text = "+"
            color = DEFAULT_COLOR
            tooltip = "Show chat"
        end
    end

    ApplyTextStyle(button.Text, size, text, color)
    button.Text:SetText(text)
    button.tooltipText = tooltip
end

function ns:CreateButton()
    if self.frames.button then
        return self.frames.button
    end

    local db = self:GetDB()
    local button = CreateFrame("Button", "HideChatButtonRebornButton", UIParent, backdropTemplate)
    button:SetPoint(db.button.point, UIParent, db.button.relativePoint, db.button.x, db.button.y)
    button:SetClampedToScreen(true)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    SetButtonStyle(button, false)

    button.PulseFrame = CreateFrame("Frame", nil, button, backdropTemplate)
    button.PulseFrame:SetFrameLevel(button:GetFrameLevel())
    button.PulseFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button.PulseFrame:SetBackdropColor(0.15, 0.02, 0.02, 0.22)
    button.PulseFrame:SetBackdropBorderColor(0.75, 0.18, 0.18, 0.5)
    button.PulseFrame:Hide()

    button.PulseFill = button.PulseFrame:CreateTexture(nil, "ARTWORK")
    button.PulseFill:SetColorTexture(1, 0.08, 0.08, 1)
    button.PulseFill:SetBlendMode("ADD")
    button.PulseFill:Hide()

    button.Text = button:CreateFontString(nil, "OVERLAY")
    button.Text:SetPoint("CENTER", 0, 0)

    button.Highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.Highlight:SetAllPoints()
    button.Highlight:SetTexture("Interface/Buttons/UI-Common-MouseHilight")
    button.Highlight:SetBlendMode("ADD")
    button.Highlight:SetAlpha(0.35)

    button:SetScript("OnEnter", function(self)
        SetButtonStyle(self, true)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("HideChatButtonReborn")
        GameTooltip:AddLine(self.tooltipText or "Toggle chat", 1, 0.82, 0)

        local missedCount = ns.GetMissedMessageCount and ns:GetMissedMessageCount() or 0
        if missedCount > 0 then
            local labelCount = FormatMissedCount(missedCount)
            local label = labelCount == "1" and "1 missed message" or (labelCount .. " missed messages")
            GameTooltip:AddLine(label, 1, 0.82, 0)
        end

        AddTooltipLine(GameTooltip, "Left-click: Toggle chat")
        AddTooltipLine(GameTooltip, "Right-click: Show missed messages")
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        SetButtonStyle(self, false)
        GameTooltip:Hide()
    end)

    button:SetScript("OnUpdate", function(self)
        if not self.PulseFrame or not self.PulseFrame:IsShown() or not self.PulseFill then
            return
        end

        local startTime = self.pulseStart or GetTime()
        local alpha = 0.08 + (math.sin((GetTime() - startTime) * 5.5) + 1) * 0.16
        self.PulseFrame:SetAlpha(math.min(0.8, alpha + 0.12))
        self.PulseFill:SetAlpha(alpha)
    end)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            ns:ToggleChat()
        elseif mouseButton == "RightButton" and ns.ShowMissedMessagesToast then
            ns:ShowMissedMessagesToast()
        end
    end)

    self.frames.button = button
    self:ApplyButtonSettings()

    return button
end
