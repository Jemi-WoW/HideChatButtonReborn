local _, ns = ...

local FALLBACK_FONT = "Fonts\\FRIZQT__.TTF"

local build = select(4, GetBuildInfo()) or 0

-- Forever reports WOW_PROJECT_MAINLINE, so only the build number tells it apart.
ns.isForever = build >= 16000 and build < 20000
ns.isClassicEra = not ns.isForever

-- Retail dropped the battleground chat events in favour of instance chat.
local UNSUPPORTED_CHAT_EVENTS = ns.isForever and {
    CHAT_MSG_BATTLEGROUND = true,
    CHAT_MSG_BATTLEGROUND_LEADER = true,
} or {}

local CHECKBOX_TEMPLATES = { "InterfaceOptionsCheckButtonTemplate", "UICheckButtonTemplate" }
local SLIDER_TEMPLATES = { "OptionsSliderTemplate", "UISliderTemplate" }

local function TryCreateFrame(frameType, name, parent, template)
    local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
    if ok and frame then
        return frame
    end
end

local function CreateFromTemplates(frameType, name, parent, templates)
    for _, template in ipairs(templates) do
        local frame = TryCreateFrame(frameType, name, parent, template)
        if frame then
            return frame, template
        end
    end

    return CreateFrame(frameType, name, parent), nil
end

local function FindChild(frame, name, suffix, key)
    return frame[key] or frame[key:lower()] or (name and _G[name .. suffix]) or nil
end

local function StyleBareCheckbox(check)
    check:SetNormalTexture("Interface/Buttons/UI-CheckBox-Up")
    check:SetPushedTexture("Interface/Buttons/UI-CheckBox-Down")
    check:SetHighlightTexture("Interface/Buttons/UI-CheckBox-Highlight", "ADD")
    check:SetCheckedTexture("Interface/Buttons/UI-CheckBox-Check")
    check:SetDisabledCheckedTexture("Interface/Buttons/UI-CheckBox-Check-Disabled")
end

local function StyleBareSlider(slider)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0, 0, 0, 0.6)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    track:SetHeight(6)

    slider:SetThumbTexture("Interface/Buttons/UI-SliderBar-Button-Horizontal")
    slider:SetHeight(17)
end

function ns:TryCreateFrame(frameType, name, parent, template)
    return TryCreateFrame(frameType, name, parent, template)
end

function ns:GetFontPath(fontObject)
    local font, _, flags = fontObject and fontObject:GetFont()

    if not font then
        font = (GameFontNormal and GameFontNormal:GetFont()) or STANDARD_TEXT_FONT or FALLBACK_FONT
    end

    return font, flags or ""
end

function ns:IsChatEventSupported(event)
    return not UNSUPPORTED_CHAT_EVENTS[event]
end

function ns:CreateCheckbox(parent, name, label)
    local check, template = CreateFromTemplates("CheckButton", name, parent, CHECKBOX_TEMPLATES)

    if not template then
        StyleBareCheckbox(check)
    end

    check:SetSize(26, 26)

    local text = FindChild(check, name, "Text", "Text")
    if not text then
        text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", check, "RIGHT", 2, 0)
    end

    text:SetText(label)
    check.Text = text
    check.Label = text

    return check
end

function ns:CreateSlider(parent, name, label, minVal, maxVal, step, width)
    local slider, template = CreateFromTemplates("Slider", name, parent, SLIDER_TEMPLATES)

    if not template then
        StyleBareSlider(slider)
    end

    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetWidth(width or 300)

    local low = FindChild(slider, name, "Low", "Low")
    local high = FindChild(slider, name, "High", "High")
    local text = FindChild(slider, name, "Text", "Text")

    if not low then
        low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 2)
    end

    if not high then
        high = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 2)
    end

    if not text then
        text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("BOTTOM", slider, "TOP", 0, 2)
    end

    low:SetText(tostring(minVal))
    high:SetText(tostring(maxVal))
    text:SetText(label)

    slider.Low = low
    slider.High = high
    slider.Text = text
    slider.Label = text

    return slider
end

function ns:CreatePanelButton(parent, width, text)
    local button = TryCreateFrame("Button", nil, parent, "UIPanelButtonTemplate") or CreateFrame("Button", nil, parent)

    if not button:GetFontString() then
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER")
        button:SetFontString(label)
        button:SetHighlightFontObject("GameFontHighlight")
    end

    button:SetSize(width, 24)
    button:SetText(text)

    return button
end
