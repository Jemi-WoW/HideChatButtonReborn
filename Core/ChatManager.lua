local _, ns = ...

local watchedFrames = {}
local watchedLookup = {}
local frameStates = {}
local hookedFrames = {}
local editModeActive = false
local editModeHooked = false

local EXTRA_FRAME_NAMES = {
    "GeneralDockManager",
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton",
    "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
}

local function GetChatWindowCount()
    return NUM_CHAT_WINDOWS or 10
end

local function AddWatchedFrame(frame)
    if not frame or watchedLookup[frame] then
        return
    end

    watchedLookup[frame] = true
    watchedFrames[#watchedFrames + 1] = frame
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
    for i = 1, GetChatWindowCount() do
        AddWatchedFrame(_G["ChatFrame" .. i])
        AddWatchedFrame(_G["ChatFrame" .. i .. "Tab"])
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
        frame:Hide()
    end
end

local function RestoreWatchedFrames()
    for frame, wasShown in pairs(frameStates) do
        if wasShown then
            frame:Show()
        end
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
            frame:Hide()
        end
    end
end

function ns:InitializeChatManager()
    wipe(watchedFrames)
    wipe(watchedLookup)

    BuildWatchList()
    HookEditMode()

    local watcher = CreateFrame("Frame")

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
