local _, ns = ...

local function CreateTitle(parent, text)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(text)
    return title
end

local function CreateText(parent, text)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetText(text)
    return fs
end

local function SetSliderLabel(slider, text)
    if slider and slider.Label then
        slider.Label:SetText(text)
    end
end

local function SetTextColor(fontString, enabled)
    if not fontString then
        return
    end

    if enabled then
        fontString:SetTextColor(1, 0.82, 0)
    else
        fontString:SetTextColor(0.5, 0.5, 0.5)
    end
end

local function SetSliderEnabled(slider, enabled)
    if not slider then
        return
    end

    if enabled then
        slider:Enable()
        slider:EnableMouse(true)
    else
        slider:Disable()
        slider:EnableMouse(false)
    end

    SetTextColor(slider.Label, enabled)
    SetTextColor(slider.Low, enabled)
    SetTextColor(slider.High, enabled)
end

function ns:BuildToastOptionsPanel(panel)
    local title = CreateTitle(panel, "Toast Options")
    title:SetPoint("TOPLEFT", 16, -16)

    local subtitle = CreateText(panel, "Control which chat types can create toast notifications.")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local disableAll = ns:CreateCheckbox(panel, "HideChatButtonRebornDisableToastsCheck", "Disable all toast notifications")
    disableAll:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -18)
    panel.disableAll = disableAll

    local eventTitle = CreateText(panel, "Create Toast Notifications for:")
    eventTitle:SetPoint("TOPLEFT", disableAll, "BOTTOMLEFT", 4, -18)
    panel.eventTitle = eventTitle

    panel.eventChecks = {}

    local definitions = ns:GetToastEventDefinitions()
    local startY = -12
    local columnWidth = 280

    for index, info in ipairs(definitions) do
        local check = ns:CreateCheckbox(panel, "HideChatButtonRebornToastEventCheck" .. index, info.label)
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)

        check:SetPoint("TOPLEFT", eventTitle, "BOTTOMLEFT", column * columnWidth, startY - (row * 28))
        check.optionKey = info.key
        check:SetScript("OnClick", function(self)
            ns:SetToastEventEnabled(self.optionKey, self:GetChecked())
        end)

        panel.eventChecks[#panel.eventChecks + 1] = check
    end

    local rows = math.ceil(#definitions / 2)
    local separateOpacity = ns:CreateCheckbox(panel, "HideChatButtonRebornSeparateToastOpacityCheck", "Separate Toasts window opacity")
    separateOpacity:SetPoint("TOPLEFT", eventTitle, "BOTTOMLEFT", 4, startY - (rows * 28) - 18)
    panel.separateOpacity = separateOpacity

    local opacitySlider = ns:CreateSlider(panel, "HideChatButtonRebornToastOpacitySlider", "Toast Opacity", 20, 100, 1, 300)
    opacitySlider:SetPoint("TOPLEFT", separateOpacity, "BOTTOMLEFT", 10, -40)
    panel.opacitySlider = opacitySlider

    local helperText = CreateText(panel, "When disabled, toast opacity follows the main button opacity.")
    helperText:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", -6, -8)
    panel.helperText = helperText

    disableAll:SetScript("OnClick", function(self)
        ns:SetToastDisabled(self:GetChecked())
    end)


    separateOpacity:SetScript("OnClick", function(self)
        ns:SetSeparateToastOpacity(self:GetChecked())
    end)

    opacitySlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        ns:SetToastOpacity(rounded / 100)
        SetSliderLabel(self, "Toast Opacity: " .. rounded .. "%")
    end)
end

function ns:RefreshToastOptionsState()
    local panel = self.frames.toastPanel
    if not panel then
        return
    end

    local toastDB = self:GetToastDB()
    local disabled = ns:IsToastDisabled()
    local separateOpacity = ns:UseSeparateToastOpacity()

    panel.disableAll:SetChecked(disabled)
    panel.separateOpacity:SetChecked(separateOpacity)

    for _, check in ipairs(panel.eventChecks or {}) do
        check:SetChecked(toastDB.events[check.optionKey] and true or false)

        if check.Label then
            if disabled then
                check:Disable()
                SetTextColor(check.Label, false)
            else
                check:Enable()
                SetTextColor(check.Label, true)
            end
        end
    end


    if panel.separateOpacity.Label then
        if disabled then
            panel.separateOpacity:Disable()
            SetTextColor(panel.separateOpacity.Label, false)
        else
            panel.separateOpacity:Enable()
            SetTextColor(panel.separateOpacity.Label, true)
        end
    end

    local opacityPercent = math.floor((ns:GetToastOpacity() * 100) + 0.5)
    panel.opacitySlider:SetValue(opacityPercent)
    SetSliderLabel(panel.opacitySlider, "Toast Opacity: " .. opacityPercent .. "%")

    SetSliderEnabled(panel.opacitySlider, (not disabled) and separateOpacity)

    if panel.helperText then
        if disabled then
            panel.helperText:SetTextColor(0.5, 0.5, 0.5)
        else
            panel.helperText:SetTextColor(1, 1, 1)
        end
    end
end
