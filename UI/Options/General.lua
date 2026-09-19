local _, ns = ...

local function CreateTitle(parent, text)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(text)
    return title
end

local function SetSliderLabel(slider, text)
    if slider and slider.Label then
        slider.Label:SetText(text)
    end
end

function ns:BuildGeneralOptionsPanel(panel)
    local title = CreateTitle(panel, "General Options")
    title:SetPoint("TOPLEFT", 16, -16)

    local anchorButton = ns:CreatePanelButton(panel, 120, "Anchor")
    anchorButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
    panel.anchorButton = anchorButton

    local anchorLeftButton = ns:CreatePanelButton(panel, 190, "Anchor Bottom Left")
    anchorLeftButton:SetPoint("LEFT", anchorButton, "RIGHT", 20, 0)
    panel.anchorLeftButton = anchorLeftButton

    local anchorRightButton = ns:CreatePanelButton(panel, 200, "Anchor Bottom Right")
    anchorRightButton:SetPoint("LEFT", anchorLeftButton, "RIGHT", 20, 0)
    panel.anchorRightButton = anchorRightButton

    local sizeSlider = ns:CreateSlider(panel, "HideChatButtonRebornSizeSlider", "Button Size", 18, 64, 1, 380)
    sizeSlider:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 10, -40)
    panel.sizeSlider = sizeSlider

    local opacitySlider = ns:CreateSlider(panel, "HideChatButtonRebornOpacitySlider", "Button Opacity", 20, 100, 1, 380)
    opacitySlider:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -48)
    panel.opacitySlider = opacitySlider

    local resetPositionButton = ns:CreatePanelButton(panel, 140, "Reset Position")
    resetPositionButton:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", -6, -28)
    panel.resetPositionButton = resetPositionButton

    local resetSizeButton = ns:CreatePanelButton(panel, 140, "Reset Size")
    resetSizeButton:SetPoint("LEFT", resetPositionButton, "RIGHT", 18, 0)
    panel.resetSizeButton = resetSizeButton

    anchorButton:SetScript("OnClick", function()
        ns:SetAnchorMode(not ns:GetDB().anchorMode)
    end)

    anchorLeftButton:SetScript("OnClick", function()
        ns:SetAnchorMode(false)
        ns:SetButtonToCorner("BOTTOMLEFT")
    end)

    anchorRightButton:SetScript("OnClick", function()
        ns:SetAnchorMode(false)
        ns:SetButtonToCorner("BOTTOMRIGHT")
    end)

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        ns:GetDB().button.size = rounded
        ns:ApplyButtonSettings()
        SetSliderLabel(self, "Button Size: " .. rounded)
    end)

    opacitySlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        ns:GetDB().button.opacity = rounded / 100
        ns:ApplyButtonSettings()
        SetSliderLabel(self, "Button Opacity: " .. rounded .. "%")
    end)

    resetPositionButton:SetScript("OnClick", function()
        ns:ResetButtonPosition()
        ns:RefreshSettingsState()
    end)

    resetSizeButton:SetScript("OnClick", function()
        ns:ResetButtonSize()
    end)
end

function ns:RefreshGeneralOptionsState()
    local panel = self.frames.generalPanel
    if not panel then
        return
    end

    local db = self:GetDB()

    if panel.anchorButton then
        if db.anchorMode then
            panel.anchorButton:SetText("Anchor On")
        else
            panel.anchorButton:SetText("Anchor")
        end
    end

    local size = db.button.size or 24
    panel.sizeSlider:SetValue(size)
    SetSliderLabel(panel.sizeSlider, "Button Size: " .. math.floor(size + 0.5))

    local opacityPercent = math.floor(((db.button.opacity or 1) * 100) + 0.5)
    panel.opacitySlider:SetValue(opacityPercent)
    SetSliderLabel(panel.opacitySlider, "Button Opacity: " .. opacityPercent .. "%")
end
