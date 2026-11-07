local _, ns = ...

local function CreatePanel(name, parentName)
    local panel = CreateFrame("Frame")
    panel.name = name
    panel.parent = parentName

    local refresh = function()
        if ns.RefreshSettingsState then
            ns:RefreshSettingsState()
        end
    end

    panel.refresh = refresh
    panel.OnRefresh = refresh
    panel.OnCommit = function() end
    panel.OnDefault = function() end

    return panel
end

local refreshing = false

function ns:RefreshSettingsState()
    -- Widget setters fire their own change handlers, which refresh again.
    if refreshing then
        return
    end

    refreshing = true

    if self.RefreshGeneralOptionsState then
        self:RefreshGeneralOptionsState()
    end

    if self.RefreshToastOptionsState then
        self:RefreshToastOptionsState()
    end

    refreshing = false
end

function ns:CreateSettings()
    if self.frames.aboutPanel then
        return
    end

    local about = CreatePanel("HideChatButtonReborn")
    local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("HideChatButtonReborn")

    local subtitle = about:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Simple and lightweight chat toggle for WoW Classic and WoW Forever.")

    local version = about:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    version:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -18)
    version:SetText("Version: 2.4")

    local author = about:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    author:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -8)
    author:SetText("Author: Jamie/Jemi")

    local general = CreatePanel("General Options", "HideChatButtonReborn")
    ns:BuildGeneralOptionsPanel(general)

    local toasts = CreatePanel("Toast Options", "HideChatButtonReborn")
    ns:BuildToastOptionsPanel(toasts)

    if not (Settings and Settings.RegisterCanvasLayoutCategory) then
        return
    end

    local category = Settings.RegisterCanvasLayoutCategory(about, "HideChatButtonReborn")
    category.ID = "HideChatButtonReborn"
    Settings.RegisterAddOnCategory(category)
    Settings.RegisterCanvasLayoutSubcategory(category, general, "General Options")
    Settings.RegisterCanvasLayoutSubcategory(category, toasts, "Toast Options")

    self.settingsCategory = category

    self.frames.aboutPanel = about
    self.frames.generalPanel = general
    self.frames.toastPanel = toasts

    self:RefreshSettingsState()
end
