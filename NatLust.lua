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
local settingsCategory
local settingsPanel
local texturePathBox
local soundPathBox
local statusText
local testToggleButton
local lockToggleButton
local applySettingsButton
local StartVisual
local StopVisual
local UpdateToggleButtonLabels
local RefreshPathInputs
local isElvUISkinned = false

local trackedBuffs = {
    [2825] = true, -- Bloodlust
    [32182] = true, -- Heroism
    [80353] = true, -- Time Warp
    [264667] = true, -- Primal Rage
    [390386] = true, -- Fury of the Aspects
}

local defaults = {
    texturePath = "Interface\\AddOns\\NatLust\\media\\pedro.tga",
    soundPath = "Interface\\AddOns\\NatLust\\media\\pedro.mp3",
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    alpha = 1,
    colorR = 1,
    colorG = 1,
    colorB = 1,
    colorA = 1,
    strata = "HIGH",
    level = 10,
    enableAnimation = true,
}

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

local function GetConfig()
    if type(NatLustDB) ~= "table" then
        ResetConfig()
    else
        CopyDefaults(NatLustDB, defaults)
    end

    return NatLustDB
end

local function GetDisplayPath(value, fallback)
    if value and value ~= "" then
        return value
    end

    return fallback
end

local function NormalizePaths()
    local db = GetConfig()

    if not db.texturePath or db.texturePath == "" then
        db.texturePath = defaults.texturePath
    end

    if not db.soundPath or db.soundPath == "" then
        db.soundPath = defaults.soundPath
    end
end

local function SaveFramePosition()
    local db = GetConfig()
    local point, _, relativePoint, x, y = visualFrame:GetPoint(1)
    db.point = point or defaults.point
    db.relativePoint = relativePoint or defaults.relativePoint
    db.x = x or defaults.x
    db.y = y or defaults.y
end

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

local function StopAudio()
    if soundHandle then
        StopSound(soundHandle)
        soundHandle = nil
    end
end

local function StartAudio()
    local db = GetConfig()

    StopAudio()

    if not db.soundPath or db.soundPath == "" then
        print("|cff00ff98NatLust|r Sound load failed: path is empty.")
        return
    end

    local willPlay, handle = PlaySoundFile(db.soundPath, "Master")
    if willPlay then
        soundHandle = handle
        print("|cff00ff98NatLust|r Sound started: " .. db.soundPath)
    else
        print("|cff00ff98NatLust|r Sound load failed: " .. db.soundPath)
    end
end

StopVisual = function()
    if visualAnimation and visualAnimation:IsPlaying() then
        visualAnimation:Stop()
    end

    visualFrame:SetScript("OnUpdate", nil)
    visualTexture:SetTexCoord(0, 1, 0, 1)
    visualTexture:Hide()

    if unlockState then
        visualFrame:SetBackdropBorderColor(0, 1, 0, 0.9)
        anchorLabel:Show()
        visualFrame:Show()
    else
        visualFrame:Hide()
    end
end

StartVisual = function()
    local db = GetConfig()
    local textureLoaded

    ApplyVisualConfig()
    textureLoaded = visualTexture:SetTexture(db.texturePath)
    if textureLoaded == false or textureLoaded == nil then
        print("|cff00ff98NatLust|r Texture load failed: " .. tostring(db.texturePath))
    else
        print("|cff00ff98NatLust|r Texture started: " .. db.texturePath)
    end

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

local function StartEffects()
    StartVisual()
    StartAudio()
end

local function AuraMatchesSpellID(spellID)
    return spellID and trackedBuffs[spellID] or false
end

local function HasTrackedAura()
    local index = 1
    local auraData

    while true do
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            auraData = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
            if not auraData then
                return false
            end

            if AuraMatchesSpellID(auraData.spellId) then
                return true
            end
        else
            local _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", index)
            if not spellID then
                return false
            end

            if AuraMatchesSpellID(spellID) then
                return true
            end
        end

        index = index + 1
    end
end

local function UpdateActiveState(nextState)
    if nextState and not activeState then
        activeState = true
        StartEffects()
    elseif not nextState and activeState then
        activeState = false
        StopEffects()
    end
end

local function EvaluateAuras()
    if testState then
        return
    end

    local hasTrackedAura = HasTrackedAura()
    if hasTrackedAura and not activeState then
        print("|cff00ff98NatLust|r Lust aura detected on player.")
    end
    UpdateActiveState(hasTrackedAura)
end

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

    UpdateToggleButtonLabels()
end

local function RunTest()
    testState = true
    UpdateActiveState(true)
    UpdateToggleButtonLabels()
end

local function StopAll()
    testState = false
    UpdateActiveState(false)
    UpdateToggleButtonLabels()
end

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

local function CreateSettingLabel(parent, text, anchor, offsetX, offsetY)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetX or 0, offsetY or -16)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function CreatePathEditBox(parent, anchor, initialText, onCommit)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(520, 30)
    editBox:SetAutoFocus(false)
    editBox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    editBox:SetTextInsets(8, 8, 0, 0)
    editBox:SetText(initialText or "")
    editBox:SetCursorPosition(0)

    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        onCommit(self:GetText())
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        onCommit(self:GetText())
    end)

    return editBox
end

local function ShowStatusMessage(text)
    if statusText then
        statusText:SetText(text or "")
    end
end

local function ApplyElvUISkin()
    if isElvUISkinned then
        return
    end

    local E = _G.ElvUI and unpack(_G.ElvUI)
    if not E or not E.private or not E.private.skins or not E.private.skins.blizzard then
        return
    end

    local S = E.GetModule and E:GetModule("Skins", true)
    if not S or not S.HandleButton then
        return
    end

    if applySettingsButton then
        S:HandleButton(applySettingsButton)
    end

    if testToggleButton then
        S:HandleButton(testToggleButton)
    end

    if lockToggleButton then
        S:HandleButton(lockToggleButton)
    end

    isElvUISkinned = true
end

UpdateToggleButtonLabels = function()
    if testToggleButton then
        testToggleButton:SetText(testState and "End Fake Lust" or "Fake Lust")
    end

    if lockToggleButton then
        lockToggleButton:SetText(unlockState and "Lock" or "Unlock")
    end
end

local function OpenSettingsPanel()
    NormalizePaths()
    if settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(settingsCategory:GetID())
        C_Timer.After(0, RefreshPathInputs)
    end
end

RefreshPathInputs = function()
    if not texturePathBox or not soundPathBox then
        return
    end

    NormalizePaths()

    local db = GetConfig()
    texturePathBox:SetText(GetDisplayPath(db.texturePath, defaults.texturePath))
    texturePathBox:SetCursorPosition(0)
    soundPathBox:SetText(GetDisplayPath(db.soundPath, defaults.soundPath))
    soundPathBox:SetCursorPosition(0)
end

local function CreateSettingsPanel()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    settingsPanel = CreateFrame("Frame", ADDON_NAME .. "SettingsPanel", UIParent)
    settingsPanel.name = ADDON_NAME

    local title = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("NatLust")

    local subtitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Configure the default texture and sound paths for NatLust.")

    local textureLabel = CreateSettingLabel(settingsPanel, "Texture Path", subtitle, 0, -24)
    texturePathBox = CreatePathEditBox(settingsPanel, textureLabel, GetDisplayPath(GetConfig().texturePath, defaults.texturePath), function(value)
        GetConfig().texturePath = strtrim(value or "")
    end)
    texturePathBox:SetText(GetDisplayPath(GetConfig().texturePath, defaults.texturePath))

    local textureHelp = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    textureHelp:SetPoint("TOPLEFT", texturePathBox, "BOTTOMLEFT", 4, -6)
    textureHelp:SetJustifyH("LEFT")
    textureHelp:SetText([[Example: Interface\AddOns\NatLust\media\pedro.tga]])

    local soundLabel = CreateSettingLabel(settingsPanel, "Sound Path", textureHelp, -4, -24)
    soundPathBox = CreatePathEditBox(settingsPanel, soundLabel, GetDisplayPath(GetConfig().soundPath, defaults.soundPath), function(value)
        GetConfig().soundPath = strtrim(value or "")
    end)
    soundPathBox:SetText(GetDisplayPath(GetConfig().soundPath, defaults.soundPath))

    local soundHelp = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    soundHelp:SetPoint("TOPLEFT", soundPathBox, "BOTTOMLEFT", 4, -6)
    soundHelp:SetJustifyH("LEFT")
    soundHelp:SetText([[Example: Interface\AddOns\NatLust\media\pedro.mp3]])

    applySettingsButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    applySettingsButton:SetSize(120, 24)
    applySettingsButton:SetPoint("TOPLEFT", soundHelp, "BOTTOMLEFT", 0, -16)
    applySettingsButton:SetText("Apply")
    applySettingsButton:SetScript("OnClick", function()
        GetConfig().texturePath = GetDisplayPath(strtrim(texturePathBox:GetText() or ""), defaults.texturePath)
        GetConfig().soundPath = GetDisplayPath(strtrim(soundPathBox:GetText() or ""), defaults.soundPath)
        ApplyVisualConfig()
        ShowStatusMessage("Settings applied.")
    end)

    testToggleButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    testToggleButton:SetSize(120, 24)
    testToggleButton:SetPoint("LEFT", applySettingsButton, "RIGHT", 8, 0)
    testToggleButton:SetScript("OnClick", function()
        if testState then
            StopAll()
            ShowStatusMessage("Fake lust ended.")
        else
            RunTest()
            ShowStatusMessage("Fake lust started.")
        end
        UpdateToggleButtonLabels()
    end)

    lockToggleButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    lockToggleButton:SetSize(120, 24)
    lockToggleButton:SetPoint("LEFT", testToggleButton, "RIGHT", 8, 0)
    lockToggleButton:SetScript("OnClick", function()
        if unlockState then
            SetUnlocked(false)
            ShowStatusMessage("Frame locked.")
        else
            SetUnlocked(true)
            ShowStatusMessage("Frame unlocked.")
        end
        UpdateToggleButtonLabels()
    end)

    statusText = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", applySettingsButton, "BOTTOMLEFT", 0, -16)
    statusText:SetJustifyH("LEFT")
    statusText:SetWidth(520)
    statusText:SetText("The text boxes are prefilled with Interface\\AddOns\\NatLust\\media paths.")

    settingsPanel:SetScript("OnShow", function()
        RefreshPathInputs()
        C_Timer.After(0, RefreshPathInputs)
        UpdateToggleButtonLabels()
    end)

    settingsCategory = Settings.RegisterCanvasLayoutCategory(settingsPanel, ADDON_NAME)
    Settings.RegisterAddOnCategory(settingsCategory)
    RefreshPathInputs()
    UpdateToggleButtonLabels()
    ApplyElvUISkin()
end

local function PrintUsage()
    print("|cff00ff98NatLust|r Use /nl or /natlust to open the settings panel.")
end

local function HandleSlashCommand()
    OpenSettingsPanel()
end

local function Initialize()
    GetConfig()
    NormalizePaths()
    CreateVisualFrame()
    CreateSettingsPanel()
    SetUnlocked(false)
    ApplyElvUISkin()

    SLASH_NATLUST1 = "/nl"
    SLASH_NATLUST2 = "/natlust"
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
