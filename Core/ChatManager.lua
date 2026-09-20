local _, ns = ...

local watchedFrames = {}
local watchedLookup = {}
local frameStates = {}
local hookedFrames = {}
local reparentedFrames = {}
local originalParents = {}
local editModeActive = false
local editModeHooked = false

-- Retail chat code re-shows edit boxes on its own, so they get parked here instead.
local hiddenHolder = CreateFrame("Frame", nil, UIParent)
hiddenHolder:Hide()

local EXTRA_FRAME_NAMES = {
    "GeneralDockManager",
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton",
    "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
}

local MAX_CHAT_FRAME_SCAN = 50
local ENFORCE_INTERVAL = 0.25

local function GetChatWindowCount()
    return NUM_CHAT_WINDOWS or 10
end

local function AddWatchedFrame(frame, reparent)
    if not frame or watchedLookup[frame] then
        return
    end

    watchedLookup[frame] = true
    watchedFrames[#watchedFrames + 1] = frame

    if reparent then
        reparentedFrames[frame] = true
    end
end

local function HideFrame(frame)
    if reparentedFrames[frame] then
        if frame.ClearFocus then
            frame:ClearFocus()
        end

        originalParents[frame] = originalParents[frame] or frame:GetParent() or UIParent
        frame:SetParent(hiddenHolder)
    end

    frame:Hide()
end

local function RestoreFrame(frame)
    local parent = originalParents[frame]
    if parent then
        frame:SetParent(parent)
        originalParents[frame] = nil
    end

    if frameStates[frame] then
        frame:Show()
    end
end

local function IsHiddenByAddon()
    return ns:GetDB().hidden and not editModeActive
end

local function InstallHooks()
    for _, frame in ipairs(watchedFrames) do
        if not hookedFrames[frame] then
            hookedFrames[frame] = true
            frame:HookScript("OnShow", function(self)
                if IsHiddenByAddon() then
                    self:Hide()
                end
            end)
        end
    end
end

local function BuildWatchList()
    -- Whisper windows are temporary frames and can sit past NUM_CHAT_WINDOWS.
    for i = 1, math.max(GetChatWindowCount(), MAX_CHAT_FRAME_SCAN) do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            AddWatchedFrame(chatFrame)
            AddWatchedFrame(_G["ChatFrame" .. i .. "Tab"])
            -- Retail parents the edit box outside the chat frame, so it needs hiding too.
            AddWatchedFrame(_G["ChatFrame" .. i .. "EditBox"], true)
        end
    end

    for _, name in ipairs(EXTRA_FRAME_NAMES) do
        AddWatchedFrame(_G[name])
    end

    InstallHooks()
end

local function CaptureFrameStates()
    wipe(frameStates)

    for _, frame in ipairs(watchedFrames) do
        frameStates[frame] = frame:IsShown() and true or false
    end
end

local function HideWatchedFrames()
    for _, frame in ipairs(watchedFrames) do
        HideFrame(frame)
    end
end

local function RestoreWatchedFrames()
    for _, frame in ipairs(watchedFrames) do
        RestoreFrame(frame)
    end
end

local function HookEditMode()
    if editModeHooked or not EditModeManagerFrame then
        return
    end

    editModeHooked = true

    -- Edit Mode must be able to show and move chat even while we hide it.
    EditModeManagerFrame:HookScript("OnShow", function()
        editModeActive = true
        if ns:GetDB().hidden then
            RestoreWatchedFrames()
        end
    end)

    EditModeManagerFrame:HookScript("OnHide", function()
        editModeActive = false
        if ns:GetDB().hidden then
            CaptureFrameStates()
            HideWatchedFrames()
        end
    end)
end

local function EnforceHidden()
    ns:RefreshWatchedFrames()

    for _, frame in ipairs(watchedFrames) do
        if frame:IsShown() then
            if not reparentedFrames[frame] then
                frameStates[frame] = true
            end
            HideFrame(frame)
        end
    end
end

local clientHooksInstalled = false

local function InstallClientHooks()
    if clientHooksInstalled then
        return
    end

    clientHooksInstalled = true

    -- The client opens, docks and selects chat windows behind our back.
    for _, name in ipairs({ "FCF_OpenTemporaryWindow", "FCF_OpenNewWindow", "FCF_DockFrame", "FCF_SelectDockFrame" }) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, function()
                if IsHiddenByAddon() then
                    EnforceHidden()
                end
            end)
        end
    end

    -- Opening chat input while hidden gets no edit box to focus, so show chat and let it retry.
    local function HookChatOpener(owner, key)
        if type(owner) ~= "table" or type(owner[key]) ~= "function" then
            return
        end

        hooksecurefunc(owner, key, function(...)
            if ns:GetDB().hidden then
                ns:SetChatHidden(false)
                owner[key](...)
            end
        end)
    end

    for _, key in ipairs({ "ChatEdit_ActivateChat", "ChatFrame_OpenChat", "ChatFrame_SendTell", "ChatFrame_ReplyTell" }) do
        HookChatOpener(_G, key)
    end

    -- Forever moved these onto a namespace; the old globals may no longer be the live path.
    for _, key in ipairs({ "ActivateChat", "OpenChat", "SendTell", "ReplyTell" }) do
        HookChatOpener(_G.ChatFrameUtil, key)
    end
end

function ns:IsChatHidden()
    return self:GetDB().hidden
end

function ns:SetChatHidden(hidden)
    local db = self:GetDB()

    if hidden then
        CaptureFrameStates()
        db.hidden = true

        if not editModeActive then
            HideWatchedFrames()
        end
    else
        db.hidden = false
        RestoreWatchedFrames()

        if self.ClearPendingIndicator then
            self:ClearPendingIndicator()
        end

        if self.ClearMissedMessages then
            self:ClearMissedMessages()
        end

        if self.HideToast then
            self:HideToast(true)
        end
    end

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end
end

function ns:ToggleChat()
    self:SetChatHidden(not self:IsChatHidden())
end

function ns:RefreshWatchedFrames()
    local previousCount = #watchedFrames
    BuildWatchList()

    if #watchedFrames > previousCount and IsHiddenByAddon() then
        for index = previousCount + 1, #watchedFrames do
            local frame = watchedFrames[index]
            frameStates[frame] = frame:IsShown() and true or false
            HideFrame(frame)
        end
    end
end

function ns:InitializeChatManager()
    wipe(watchedFrames)
    wipe(watchedLookup)

    BuildWatchList()
    HookEditMode()
    InstallClientHooks()

    local watcher = CreateFrame("Frame")
    local enforceElapsed = 0

    watcher:SetScript("OnUpdate", function(_, elapsed)
        if not IsHiddenByAddon() then
            return
        end

        enforceElapsed = enforceElapsed + elapsed
        if enforceElapsed < ENFORCE_INTERVAL then
            return
        end

        enforceElapsed = 0
        EnforceHidden()
    end)

    for _, event in ipairs({ "UPDATE_CHAT_WINDOWS", "UPDATE_FLOATING_CHAT_WINDOWS", "ADDON_LOADED", "PLAYER_ENTERING_WORLD" }) do
        pcall(watcher.RegisterEvent, watcher, event)
    end

    watcher:SetScript("OnEvent", function(_, event)
        -- Edit Mode can load late, so keep retrying the hook.
        HookEditMode()

        if event == "UPDATE_CHAT_WINDOWS" or event == "UPDATE_FLOATING_CHAT_WINDOWS" then
            ns:RefreshWatchedFrames()
        end
    end)
end

function ns:ApplyInitialState()
    if self:IsChatHidden() then
        CaptureFrameStates()

        if not editModeActive then
            HideWatchedFrames()
        end
    end

    if self.UpdateButtonVisual then
        self:UpdateButtonVisual()
    end

    if self.UpdateToastPosition then
        self:UpdateToastPosition()
    end
end
