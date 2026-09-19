local _, ns = ...

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local function SetAnchorToButton(anchor, button)
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", button, "CENTER", 0, 0)
    anchor:SetSize(button:GetWidth() + 30, button:GetHeight() + 30)
end

local function SyncButtonToAnchor(anchor, button)
    local x, y = anchor:GetCenter()
    if not x or not y then
        return
    end

    button:ClearAllPoints()
    button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

    if ns.UpdateToastPosition then
        ns:UpdateToastPosition()
    end
end

function ns:UpdateAnchor()
    local anchor = self.frames.anchor
    local button = self.frames.button
    if not anchor or not button then
        return
    end

    SetAnchorToButton(anchor, button)
end

function ns:UpdateAnchorMode()
    local db = self:GetDB()
    local anchor = self.frames.anchor
    if not anchor then
        return
    end

    if db.anchorMode then
        self:UpdateAnchor()
        anchor:Show()
    else
        anchor:Hide()
    end

    if self.RefreshSettingsState then
        self:RefreshSettingsState()
    end
end

function ns:SetAnchorMode(enabled)
    self:GetDB().anchorMode = enabled and true or false
    self:UpdateAnchorMode()
end

function ns:CreateAnchor()
    if self.frames.anchor then
        return self.frames.anchor
    end

    local button = self.frames.button
    local anchor = CreateFrame("Frame", "HideChatButtonRebornAnchor", UIParent, backdropTemplate)
    anchor:SetFrameStrata("DIALOG")
    anchor:SetClampedToScreen(true)
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    anchor:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    anchor:SetBackdropBorderColor(0.72, 0.58, 0.18, 1)

    anchor.Title = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchor.Title:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 4, 2)
    anchor.Title:SetText("Anchor")

    anchor.CloseButton = ns:TryCreateFrame("Button", nil, anchor, "UIPanelCloseButton")
    if anchor.CloseButton then
        anchor.CloseButton:SetPoint("BOTTOMLEFT", anchor.Title, "BOTTOMRIGHT", 0, -7)
        anchor.CloseButton:SetSize(24, 24)
        anchor.CloseButton:SetScript("OnClick", function()
            ns:SetAnchorMode(false)
        end)
    end

    anchor.Help = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    anchor.Help:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
    anchor.Help:SetText("Drag to move")

    anchor:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self:SetScript("OnUpdate", function(frame)
            SyncButtonToAnchor(frame, button)
        end)
    end)

    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetScript("OnUpdate", nil)

        SyncButtonToAnchor(self, button)
        ns:SaveButtonPosition(button)
        ns:UpdateAnchor()
    end)

    self.frames.anchor = anchor
    self:UpdateAnchor()
    anchor:Hide()

    return anchor
end
