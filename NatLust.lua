local ADDON_NAME = ...

local addon = CreateFrame("Frame")
local activeState = false
local testState = false
local unlockState = false
local soundHandle
local visualFrame
local visualTexture
local visualAnimation
local anchorLabel

local trackedBuffs = {
    ["Bloodlust"] = true,
    ["Heroism"] = true,
    ["Time Warp"] = true,
    ["Primal Rage"] = true,
    ["Fury of the Aspects"] = true,
    ["Harrier's Cry"] = true,
}

local defaults = {
    texturePath = "Interface\\AddOns\\NatLust\\media\\texture.tga",
    soundPath = "Interface\\AddOns\\NatLust\\media\\lust.mp3",
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    width = 256,
    height = 256,
    alpha = 1,
    colorR = 1,
    colorG = 1,
    colorB = 1,
    colorA = 1,
    strata = "HIGH",
    level = 10,
    enableAnimation = true,
}

-- Initialize missing saved values without overwriting user settings.
local function CopyDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = target[key] or {}
            CopyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function ResetConfig()
    NatLustDB = {}
    CopyDefaults(NatLustDB, defaults)
end

-- Return the live saved-variable table with defaults applied.
local function GetConfig()
    if type(NatLustDB) ~= "table" then
        ResetConfig()
    else
        CopyDefaults(NatLustDB, defaults)
    end

    return NatLustDB
end

-- Persist the frame anchor after dragging in unlock mode.
local function SaveFramePosition()
    local db = GetConfig()
    local point, _, relativePoint, x, y = visualFrame:GetPoint(1)
    db.point = point or defaults.point
    db.relativePoint = relativePoint or defaults.relativePoint
    db.x = x or defaults.x
    db.y = y or defaults.y
end

-- Apply all visual settings from SavedVariables to the display frame.
local function ApplyVisualConfig()
    local db = GetConfig()
    visualFrame:ClearAllPoints()
    visualFrame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
    visualFrame:SetSize(db.width, db.height)
    visualFrame:SetAlpha(db.alpha)
    visualFrame:SetFrameStrata(db.strata or defaults.strata)
    visualFrame:SetFrameLevel(db.level or defaults.level)

    visualTexture:SetTexture(db.texturePath)
    visualTexture:SetVertexColor(db.colorR, db.colorG, db.colorB, db.colorA)
    visualTexture:SetAlpha(1)
end

-- Stop the currently playing custom sound if WoW returned a handle.
local function StopAudio()
    if soundHandle then
        StopSound(soundHandle)
        soundHandle = nil
    end
end

-- Start the configured sound from the beginning and save its handle.
local function StartAudio()
    local db = GetConfig()

    StopAudio()

    if not db.soundPath or db.soundPath == "" then
        return
    end

    local willPlay, handle = PlaySoundFile(db.soundPath, "Master")
    if willPlay then
        soundHandle = handle
    end
end

-- Stop the animation and hide the texture unless the frame is unlocked.
local function StopVisual()
    if visualAnimation and visualAnimation:IsPlaying() then
        visualAnimation:Stop()
    end

    visualTexture:Hide()

    if unlockState then
        visualFrame:SetBackdropBorderColor(0, 1, 0, 0.9)
        anchorLabel:Show()
        visualFrame:Show()
    else
        visualFrame:Hide()
    end
end

-- Show the texture and always restart the animation from the beginning.
local function StartVisual()
    local db = GetConfig()

    ApplyVisualConfig()
    visualFrame:Show()
    visualTexture:Show()

    if db.enableAnimation and visualAnimation then
        visualAnimation:Stop()
        visualTexture:SetAlpha(1)
        visualTexture:SetScale(1)
        visualAnimation:Play()
    else
        visualTexture:SetAlpha(1)
        visualTexture:SetScale(1)
    end

    if unlockState then
        visualFrame:SetBackdropBorderColor(1, 0.82, 0, 0.9)
        anchorLabel:Show()
    end
end

local function StopEffects()
    StopAudio()
    StopVisual()
end

-- Start both the visual and audio parts of the effect.
local function StartEffects()
    StartVisual()
    StartAudio()
end

local function AuraMatchesName(name)
    return name and trackedBuffs[name] or false
end

-- Unified aura scan for player helpful buffs.
local function HasTrackedAura()
    local index = 1

    while true do
        local name = UnitBuff("player", index)
        if not name then
            return false
        end

        if AuraMatchesName(name) then
            return true
        end

        index = index + 1
    end
end

-- Transition gate that prevents duplicate start and stop calls.
local function UpdateActiveState(nextState)
    if nextState and not activeState then
        activeState = true
        StartEffects()
    elseif not nextState and activeState then
        activeState = false
        StopEffects()
    end
end

-- Re-evaluate the player's lust state from UNIT_AURA.
local function EvaluateAuras()
    if testState then
        return
    end

    UpdateActiveState(HasTrackedAura())
end

-- Toggle drag mode and show an anchor outline while unlocked.
local function SetUnlocked(enabled)
    unlockState = enabled and true or false

    visualFrame:SetMovable(unlockState)
    visualFrame:EnableMouse(unlockState)

    if unlockState then
        ApplyVisualConfig()
        visualFrame:SetBackdropBorderColor(0, 1, 0, 0.9)
        visualFrame:Show()
        anchorLabel:Show()
        if not activeState then
            visualTexture:Hide()
        end
    else
        anchorLabel:Hide()
        if activeState or testState then
            visualFrame:SetBackdropBorderColor(1, 0.82, 0, 0.9)
            visualTexture:Show()
            visualFrame:Show()
        else
            visualFrame:Hide()
        end
    end
end

-- Manual preview mode for testing texture, sound, and animation.
local function RunTest()
    testState = true
    StartEffects()
end

-- Hard stop for manual preview or live aura-driven playback.
local function StopAll()
    testState = false
    activeState = false
    StopEffects()
end

-- Create the main display frame, texture, anchor label, and animation group.
local function CreateVisualFrame()
    visualFrame = CreateFrame("Frame", ADDON_NAME .. "DisplayFrame", UIParent, "BackdropTemplate")
    visualFrame:SetClampedToScreen(true)
    visualFrame:SetMovable(false)
    visualFrame:EnableMouse(false)
    visualFrame:RegisterForDrag("LeftButton")
    visualFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    visualFrame:SetBackdropColor(0, 0, 0, 0.15)
    visualFrame:SetBackdropBorderColor(0, 1, 0, 0.9)
    visualFrame:Hide()

    visualFrame:SetScript("OnDragStart", function(self)
        if unlockState then
            self:StartMoving()
        end
    end)

    visualFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePosition()
    end)

    visualTexture = visualFrame:CreateTexture(nil, "ARTWORK")
    visualTexture:SetAllPoints()
    visualTexture:Hide()

    anchorLabel = visualFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorLabel:SetPoint("CENTER")
    anchorLabel:SetText("NatLust")
    anchorLabel:Hide()

    visualAnimation = visualTexture:CreateAnimationGroup()
    visualAnimation:SetLooping("REPEAT")

    local alphaIn = visualAnimation:CreateAnimation("Alpha")
    alphaIn:SetOrder(1)
    alphaIn:SetFromAlpha(0.25)
    alphaIn:SetToAlpha(1)
    alphaIn:SetDuration(0.25)

    local scaleUp = visualAnimation:CreateAnimation("Scale")
    scaleUp:SetOrder(1)
    scaleUp:SetScale(1.08, 1.08)
    scaleUp:SetOrigin("CENTER", 0, 0)
    scaleUp:SetDuration(0.25)

    local alphaOut = visualAnimation:CreateAnimation("Alpha")
    alphaOut:SetOrder(2)
    alphaOut:SetFromAlpha(1)
    alphaOut:SetToAlpha(0.7)
    alphaOut:SetDuration(0.45)

    local scaleDown = visualAnimation:CreateAnimation("Scale")
    scaleDown:SetOrder(2)
    scaleDown:SetScale(0.9259, 0.9259)
    scaleDown:SetOrigin("CENTER", 0, 0)
    scaleDown:SetDuration(0.45)

    visualAnimation:SetScript("OnStop", function()
        visualTexture:SetAlpha(1)
        visualTexture:SetScale(1)
    end)

    ApplyVisualConfig()
end

local function PrintUsage()
    print("|cff00ff98NatLust|r commands:")
    print("/natlust test - Show the texture and play the sound once")
    print("/natlust stop - Stop sound and hide the texture")
    print("/natlust unlock - Unlock the frame for dragging")
    print("/natlust lock - Lock the frame in place")
    print("/natlust reset - Reset saved settings")
end

-- Slash handler for testing, stopping, moving, and resetting the addon.
local function HandleSlashCommand(message)
    local command = string.lower(strtrim(message or ""))

    if command == "test" then
        RunTest()
    elseif command == "stop" then
        StopAll()
    elseif command == "unlock" then
        SetUnlocked(true)
    elseif command == "lock" then
        SetUnlocked(false)
    elseif command == "reset" then
        ResetConfig()
        ApplyVisualConfig()
        SetUnlocked(false)
        StopAll()
        print("|cff00ff98NatLust|r settings reset.")
    else
        PrintUsage()
    end
end

-- Addon bootstrap: init config, frame, slash commands, and aura listener.
local function Initialize()
    GetConfig()
    CreateVisualFrame()
    SetUnlocked(false)

    SLASH_NATLUST1 = "/natlust"
    SlashCmdList.NATLUST = HandleSlashCommand

    addon:RegisterEvent("UNIT_AURA")
    EvaluateAuras()
end

addon:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            Initialize()
            addon:UnregisterEvent("ADDON_LOADED")
        end
        return
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            EvaluateAuras()
        end
    end
end)

addon:RegisterEvent("ADDON_LOADED")
