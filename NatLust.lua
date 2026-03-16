local ADDON_NAME, addonTable = ...
local L = addonTable.L or {}

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
local columnsBox
local rowsBox
local framesBox
local fpsBox
local widthSlider
local heightSlider
local widthValueBox
local heightValueBox
local statusText
local statusHintText
local testToggleButton
local lockToggleButton
local applySettingsButton
local defaultSettingsButton
local StartVisual
local StopVisual
local GetSpriteSettings
local UpdateToggleButtonLabels
local RefreshPathInputs
local isElvUISkinned = false
local spriteElapsed = 0
local currentSpriteFrame = 1

local trackedBuffs = {
    [2825] = true, -- Bloodlust
    [32182] = true, -- Heroism
    [80353] = true, -- Time Warp
    [264667] = true, -- Primal Rage
    [390386] = true, -- Fury of the Aspects
}

local MEDIA_PREFIX = "Interface\\AddOns\\NatLust\\Media\\"

local defaults = {
    texturePath = "pedro.tga",
    soundPath = "pedro.mp3",
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    width = 60,
    height = 60,
    alpha = 1,
    colorR = 1,
    colorG = 1,
    colorB = 1,
    colorA = 1,
    strata = "HIGH",
    level = 10,
    enableAnimation = true,
    spriteColumns = 4,
    spriteRows = 8,
    spriteFrames = 32,
    spriteFPS = 12,
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

local function GetDisplayValue(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

local function BuildMediaPath(fileName)
    local name = strtrim(fileName or "")
    if name == "" then
        return nil
    end

    return MEDIA_PREFIX .. name
end

local function ExtractFileName(value, fallback)
    local text = GetDisplayPath(value, fallback)
    local normalized = strtrim(text or "")

    if normalized == "" then
        return fallback
    end

    if string.sub(normalized, 1, string.len(MEDIA_PREFIX)) == MEDIA_PREFIX then
        return string.sub(normalized, string.len(MEDIA_PREFIX) + 1)
    end

    return normalized:match("([^\\/:]+)$") or normalized
end

local function NormalizePaths()
    local db = GetConfig()

    if db.texturePath == nil then
        db.texturePath = defaults.texturePath
    else
        db.texturePath = ExtractFileName(db.texturePath, "")
    end

    if db.soundPath == nil then
        db.soundPath = defaults.soundPath
    else
        db.soundPath = ExtractFileName(db.soundPath, "")
    end

    GetSpriteSettings()
end

local function SaveFramePosition()
    local db = GetConfig()
    local point, _, relativePoint, x, y = visualFrame:GetPoint(1)
    db.point = point or defaults.point
    db.relativePoint = relativePoint or defaults.relativePoint
    db.x = x or defaults.x
    db.y = y or defaults.y
end

local function ClampInteger(value, fallback, minimum)
    local number = tonumber(value)
    if not number then
        return fallback
    end

    number = math.floor(number + 0.5)
    if minimum and number < minimum then
        return minimum
    end

    return number
end

GetSpriteSettings = function()
    local db = GetConfig()
    local columns = ClampInteger(db.spriteColumns, defaults.spriteColumns, 1)
    local rows = ClampInteger(db.spriteRows, defaults.spriteRows, 1)
    local frames = ClampInteger(db.spriteFrames, defaults.spriteFrames, 1)
    local fps = ClampInteger(db.spriteFPS, defaults.spriteFPS, 1)
    local maxFrames = columns * rows

    if frames > maxFrames then
        frames = maxFrames
    end

    db.spriteColumns = columns
    db.spriteRows = rows
    db.spriteFrames = frames
    db.spriteFPS = fps

    return columns, rows, frames, fps
end

local function SetSpriteFrame(frameIndex)
    local db = GetConfig()
    local columns, rows, frames = GetSpriteSettings()
    local frame = math.min(math.max(frameIndex or 1, 1), frames)
    local column = (frame - 1) % columns
    local row = math.floor((frame - 1) / columns)
    local cropLeft = 0
    local cropRight = 1
    local cropTop = 0
    local cropBottom = 1
    local width
    local height
    local left
    local right
    local top
    local bottom

    -- pedro.tga only uses the top-left 768x1536 area of a 1024x2048 sheet.
    if db.texturePath == "pedro.tga" then
        cropRight = 0.75
        cropBottom = 0.75
    end

    width = (cropRight - cropLeft) / columns
    height = (cropBottom - cropTop) / rows
    left = cropLeft + (column * width)
    right = left + width
    top = cropTop + (row * height)
    bottom = top + height

    currentSpriteFrame = frame
    visualTexture:SetTexCoord(left, right, top, bottom)
end

local function StopSpriteAnimation()
    spriteElapsed = 0
    currentSpriteFrame = 1
    visualFrame:SetScript("OnUpdate", nil)
    visualTexture:SetTexCoord(0, 1, 0, 1)
end

local function StartSpriteAnimation()
    local _, _, frames, fps = GetSpriteSettings()

    spriteElapsed = 0
    currentSpriteFrame = 1

    if frames <= 1 then
        visualTexture:SetTexCoord(0, 1, 0, 1)
        visualFrame:SetScript("OnUpdate", nil)
        return
    end

    SetSpriteFrame(1)

    visualFrame:SetScript("OnUpdate", function(_, elapsed)
        local frameDuration = 1 / fps

        spriteElapsed = spriteElapsed + elapsed
        while spriteElapsed >= frameDuration do
            spriteElapsed = spriteElapsed - frameDuration
            currentSpriteFrame = currentSpriteFrame + 1
            if currentSpriteFrame > frames then
                currentSpriteFrame = 1
            end
            SetSpriteFrame(currentSpriteFrame)
        end
    end)
end

local function ApplyVisualConfig()
    local db = GetConfig()
    visualFrame:ClearAllPoints()
    visualFrame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
    visualFrame:SetSize(db.width, db.height)
    visualFrame:SetAlpha(db.alpha)
    visualFrame:SetFrameStrata(db.strata or defaults.strata)
    visualFrame:SetFrameLevel(db.level or defaults.level)

    visualTexture:SetTexture(BuildMediaPath(db.texturePath))
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
        return
    end

    local soundPath = BuildMediaPath(db.soundPath)
    if not soundPath then
        return
    end

    local willPlay, handle = PlaySoundFile(soundPath, "Master")
    if willPlay then
        soundHandle = handle
        print("|cff00ff98NatLust|r " .. (L.SOUND_STARTED or "Sound started: ") .. soundPath)
    else
        print("|cff00ff98NatLust|r " .. (L.SOUND_FAILED or "Sound load failed: ") .. soundPath)
    end
end

StopVisual = function()
    if visualAnimation and visualAnimation:IsPlaying() then
        visualAnimation:Stop()
    end

    StopSpriteAnimation()
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
    local _, _, frames = GetSpriteSettings()

    if not db.texturePath or db.texturePath == "" then
        StopVisual()
        return
    end

    ApplyVisualConfig()
    local texturePath = BuildMediaPath(db.texturePath)
    textureLoaded = visualTexture:SetTexture(texturePath)
    if textureLoaded == false or textureLoaded == nil then
        print("|cff00ff98NatLust|r " .. (L.TEXTURE_FAILED or "Texture load failed: ") .. tostring(texturePath))
    else
        print("|cff00ff98NatLust|r " .. (L.TEXTURE_STARTED or "Texture started: ") .. texturePath)
    end

    visualFrame:Show()
    visualTexture:Show()
    StartSpriteAnimation()

    if frames > 1 then
        if visualAnimation then
            visualAnimation:Stop()
        end
        visualTexture:SetAlpha(1)
        visualTexture:SetScale(1)
    elseif db.enableAnimation and visualAnimation then
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
        print("|cff00ff98NatLust|r " .. (L.LUST_DETECTED or "Lust aura detected on player."))
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
    anchorLabel:SetText(L.ADDON_TITLE or "NatLust")
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

local function CreatePathEditBox(parent, anchor, initialText, onCommit, width)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(width or 260, 30)
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

local function CreateValueSlider(parent, anchor, labelText, minValue, maxValue, step)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -22)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)

    slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.Text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 6)
    slider.Text:SetText(labelText)

    slider.Low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    slider.Low:SetText("")
    slider.Low:Hide()

    slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    slider.High:SetText("")
    slider.High:Hide()

    slider.ValueBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    slider.ValueBox:SetSize(56, 26)
    slider.ValueBox:SetAutoFocus(false)
    slider.ValueBox:SetNumeric(true)
    slider.ValueBox:SetPoint("LEFT", slider, "RIGHT", 14, 0)
    slider.ValueBox:SetTextInsets(8, 8, 0, 0)
    slider.ValueBox:SetText(tostring(minValue))

    slider.ValueBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local value = ClampInteger(self:GetText(), slider:GetValue(), minValue)
        value = math.min(maxValue, math.max(minValue, value))
        slider:SetValue(value)
    end)

    slider.ValueBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText(tostring(math.floor(slider:GetValue() + 0.5)))
    end)

    slider.ValueBox:SetScript("OnEditFocusLost", function(self)
        local value = ClampInteger(self:GetText(), slider:GetValue(), minValue)
        value = math.min(maxValue, math.max(minValue, value))
        slider:SetValue(value)
    end)

    return slider
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

    if texturePathBox and S.HandleEditBox then
        S:HandleEditBox(texturePathBox)
    end

    if soundPathBox and S.HandleEditBox then
        S:HandleEditBox(soundPathBox)
    end

    if columnsBox and S.HandleEditBox then
        S:HandleEditBox(columnsBox)
    end

    if rowsBox and S.HandleEditBox then
        S:HandleEditBox(rowsBox)
    end

    if framesBox and S.HandleEditBox then
        S:HandleEditBox(framesBox)
    end

    if fpsBox and S.HandleEditBox then
        S:HandleEditBox(fpsBox)
    end

    if widthSlider and S.HandleSliderFrame then
        S:HandleSliderFrame(widthSlider)
    elseif widthSlider and S.HandleSlider then
        S:HandleSlider(widthSlider)
    end

    if heightSlider and S.HandleSliderFrame then
        S:HandleSliderFrame(heightSlider)
    elseif heightSlider and S.HandleSlider then
        S:HandleSlider(heightSlider)
    end

    if widthSlider and widthSlider.ValueBox and S.HandleEditBox then
        S:HandleEditBox(widthSlider.ValueBox)
    end

    if heightSlider and heightSlider.ValueBox and S.HandleEditBox then
        S:HandleEditBox(heightSlider.ValueBox)
    end

    if applySettingsButton then
        S:HandleButton(applySettingsButton)
    end

    if defaultSettingsButton then
        S:HandleButton(defaultSettingsButton)
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
        testToggleButton:SetText(testState and (L.END_FAKE_LUST or "End Fake Lust") or (L.FAKE_LUST or "Fake Lust"))
    end

    if lockToggleButton then
        lockToggleButton:SetText(unlockState and (L.LOCK or "Lock") or (L.UNLOCK or "Unlock"))
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
    if not texturePathBox or not soundPathBox or not columnsBox or not rowsBox or not framesBox or not fpsBox or not widthSlider or not heightSlider then
        return
    end

    NormalizePaths()

    local db = GetConfig()
    texturePathBox:SetText(GetDisplayValue(db.texturePath, defaults.texturePath))
    texturePathBox:SetCursorPosition(0)
    soundPathBox:SetText(GetDisplayValue(db.soundPath, defaults.soundPath))
    soundPathBox:SetCursorPosition(0)
    columnsBox:SetText(tostring(db.spriteColumns or defaults.spriteColumns))
    columnsBox:SetCursorPosition(0)
    rowsBox:SetText(tostring(db.spriteRows or defaults.spriteRows))
    rowsBox:SetCursorPosition(0)
    framesBox:SetText(tostring(db.spriteFrames or defaults.spriteFrames))
    framesBox:SetCursorPosition(0)
    fpsBox:SetText(tostring(db.spriteFPS or defaults.spriteFPS))
    fpsBox:SetCursorPosition(0)
    widthSlider:SetValue(db.width or defaults.width)
    heightSlider:SetValue(db.height or defaults.height)
    if widthSlider.ValueBox then
        widthSlider.ValueBox:SetText(tostring(db.width or defaults.width))
    end
    if heightSlider.ValueBox then
        heightSlider.ValueBox:SetText(tostring(db.height or defaults.height))
    end
end

local function CreateSettingsPanel()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    settingsPanel = CreateFrame("Frame", ADDON_NAME .. "SettingsPanel", UIParent)
    settingsPanel.name = ADDON_NAME

    local title = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.ADDON_TITLE or "NatLust")

    local subtitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(L.SUBTITLE or "Enter file names only. NatLust will load them from Interface\\AddOns\\NatLust\\Media\\")

    local leftColumnX = 0
    local rightColumnX = 300
    local smallFieldStep = 122

    local textureLabel = CreateSettingLabel(settingsPanel, L.TEXTURE_FILE or "Texture File", subtitle, leftColumnX, -24)
    texturePathBox = CreatePathEditBox(settingsPanel, textureLabel, GetDisplayPath(GetConfig().texturePath, defaults.texturePath), function(value)
        GetConfig().texturePath = strtrim(value or "")
    end, 240)
    texturePathBox:SetText(GetDisplayPath(GetConfig().texturePath, defaults.texturePath))

    local textureHelp = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    textureHelp:SetPoint("TOPLEFT", texturePathBox, "BOTTOMLEFT", 4, -6)
    textureHelp:SetJustifyH("LEFT")
    textureHelp:SetWidth(240)
    textureHelp:SetText(L.TEXTURE_EXAMPLE or "Example: pedro.tga")

    local soundLabel = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    soundLabel:SetPoint("TOPLEFT", textureLabel, "TOPLEFT", rightColumnX, 0)
    soundLabel:SetJustifyH("LEFT")
    soundLabel:SetText(L.SOUND_FILE or "Sound File")
    soundPathBox = CreatePathEditBox(settingsPanel, soundLabel, GetDisplayPath(GetConfig().soundPath, defaults.soundPath), function(value)
        GetConfig().soundPath = strtrim(value or "")
    end, 240)
    soundPathBox:SetText(GetDisplayValue(GetConfig().soundPath, defaults.soundPath))

    local soundHelp = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    soundHelp:SetPoint("TOPLEFT", soundPathBox, "BOTTOMLEFT", 4, -6)
    soundHelp:SetJustifyH("LEFT")
    soundHelp:SetWidth(240)
    soundHelp:SetText(L.SOUND_EXAMPLE or "Example: pedro.mp3")

    local columnsLabel = CreateSettingLabel(settingsPanel, L.SPRITE_COLUMNS or "Columns", soundHelp, -300, -22)
    columnsBox = CreatePathEditBox(settingsPanel, columnsLabel, tostring(GetConfig().spriteColumns or defaults.spriteColumns), function(value)
        GetConfig().spriteColumns = ClampInteger(value, defaults.spriteColumns, 1)
    end, 80)

    local rowsLabel = CreateSettingLabel(settingsPanel, L.SPRITE_ROWS or "Rows", soundHelp, -300 + smallFieldStep, -22)
    rowsBox = CreatePathEditBox(settingsPanel, rowsLabel, tostring(GetConfig().spriteRows or defaults.spriteRows), function(value)
        GetConfig().spriteRows = ClampInteger(value, defaults.spriteRows, 1)
    end, 80)

    local framesLabel = CreateSettingLabel(settingsPanel, L.SPRITE_FRAMES or "Frames", soundHelp, -300 + (smallFieldStep * 2), -22)
    framesBox = CreatePathEditBox(settingsPanel, framesLabel, tostring(GetConfig().spriteFrames or defaults.spriteFrames), function(value)
        GetConfig().spriteFrames = ClampInteger(value, defaults.spriteFrames, 1)
    end, 80)

    local fpsLabel = CreateSettingLabel(settingsPanel, L.SPRITE_FPS or "FPS", soundHelp, -300 + (smallFieldStep * 3), -22)
    fpsBox = CreatePathEditBox(settingsPanel, fpsLabel, tostring(GetConfig().spriteFPS or defaults.spriteFPS), function(value)
        GetConfig().spriteFPS = ClampInteger(value, defaults.spriteFPS, 1)
    end, 80)

    local spriteHelp = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    spriteHelp:SetPoint("TOPLEFT", columnsBox, "BOTTOMLEFT", 4, -6)
    spriteHelp:SetJustifyH("LEFT")
    spriteHelp:SetWidth(520)
    spriteHelp:SetText(L.SPRITE_HINT or "Sprite sheet playback uses left-to-right, top-to-bottom order.")

    widthSlider = CreateValueSlider(settingsPanel, spriteHelp, L.WIDTH_LABEL or "Width: 50", 20, 256, 1)
    widthSlider:ClearAllPoints()
    widthSlider:SetPoint("TOPLEFT", spriteHelp, "BOTTOMLEFT", 0, -30)
    widthValueBox = widthSlider.ValueBox
    widthSlider:SetScript("OnValueChanged", function(self, value)
        local width = math.floor((value or defaults.width) + 0.5)
        local db = GetConfig()

        db.width = width
        if self.Text then
            self.Text:SetText(string.format("%s: %d", L.WIDTH_LABEL or "Width", width))
        end
        if self.ValueBox and not self.ValueBox:HasFocus() then
            self.ValueBox:SetText(tostring(width))
        end

        ApplyVisualConfig()
        if activeState or testState or unlockState then
            visualFrame:Show()
        end
    end)

    heightSlider = CreateValueSlider(settingsPanel, widthSlider, L.HEIGHT_LABEL or "Height: 50", 20, 256, 1)
    heightSlider:ClearAllPoints()
    heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -46)
    heightSlider.ValueBox:ClearAllPoints()
    heightSlider.ValueBox:SetPoint("LEFT", heightSlider, "RIGHT", 14, 0)
    heightValueBox = heightSlider.ValueBox
    heightSlider:SetScript("OnValueChanged", function(self, value)
        local height = math.floor((value or defaults.height) + 0.5)
        local db = GetConfig()

        db.height = height
        if self.Text then
            self.Text:SetText(string.format("%s: %d", L.HEIGHT_LABEL or "Height", height))
        end
        if self.ValueBox and not self.ValueBox:HasFocus() then
            self.ValueBox:SetText(tostring(height))
        end

        ApplyVisualConfig()
        if activeState or testState or unlockState then
            visualFrame:Show()
        end
    end)

    applySettingsButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    applySettingsButton:SetSize(120, 24)
    applySettingsButton:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -32)
    applySettingsButton:SetText(L.APPLY or "Apply")
    applySettingsButton:SetScript("OnClick", function()
        GetConfig().texturePath = strtrim(texturePathBox:GetText() or "")
        GetConfig().soundPath = strtrim(soundPathBox:GetText() or "")
        GetConfig().spriteColumns = ClampInteger(columnsBox:GetText(), defaults.spriteColumns, 1)
        GetConfig().spriteRows = ClampInteger(rowsBox:GetText(), defaults.spriteRows, 1)
        GetConfig().spriteFrames = ClampInteger(framesBox:GetText(), defaults.spriteFrames, 1)
        GetConfig().spriteFPS = ClampInteger(fpsBox:GetText(), defaults.spriteFPS, 1)
        GetSpriteSettings()
        ApplyVisualConfig()
        if activeState or testState then
            StartVisual()
        end
        RefreshPathInputs()
        ShowStatusMessage(L.SETTINGS_APPLIED or "Settings applied.")
    end)

    defaultSettingsButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    defaultSettingsButton:SetSize(120, 24)
    defaultSettingsButton:SetPoint("LEFT", applySettingsButton, "RIGHT", 8, 0)
    defaultSettingsButton:SetText(L.DEFAULT or "Default")
    defaultSettingsButton:SetScript("OnClick", function()
        GetConfig().texturePath = defaults.texturePath
        GetConfig().soundPath = defaults.soundPath
        GetConfig().spriteColumns = defaults.spriteColumns
        GetConfig().spriteRows = defaults.spriteRows
        GetConfig().spriteFrames = defaults.spriteFrames
        GetConfig().spriteFPS = defaults.spriteFPS
        GetConfig().width = defaults.width
        GetConfig().height = defaults.height
        RefreshPathInputs()
        ApplyVisualConfig()
        ShowStatusMessage(L.DEFAULTS_RESTORED or "Default file names restored.")
    end)

    testToggleButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    testToggleButton:SetSize(120, 24)
    testToggleButton:SetPoint("LEFT", defaultSettingsButton, "RIGHT", 8, 0)
    testToggleButton:SetScript("OnClick", function()
        if testState then
            StopAll()
            ShowStatusMessage(L.FAKE_LUST_ENDED or "Fake lust ended.")
        else
            RunTest()
            ShowStatusMessage(L.FAKE_LUST_STARTED or "Fake lust started.")
        end
        UpdateToggleButtonLabels()
    end)

    lockToggleButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    lockToggleButton:SetSize(120, 24)
    lockToggleButton:SetPoint("LEFT", testToggleButton, "RIGHT", 8, 0)
    lockToggleButton:SetScript("OnClick", function()
        if unlockState then
            SetUnlocked(false)
            ShowStatusMessage(L.FRAME_LOCKED or "Frame locked.")
        else
            SetUnlocked(true)
            ShowStatusMessage(L.FRAME_UNLOCKED or "Frame unlocked.")
        end
        UpdateToggleButtonLabels()
    end)

    statusText = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", applySettingsButton, "BOTTOMLEFT", 0, -16)
    statusText:SetJustifyH("LEFT")
    statusText:SetWidth(520)
    statusText:SetHeight(16)
    statusText:SetMaxLines(1)
    statusText:SetText("")

    statusHintText = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusHintText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -8)
    statusHintText:SetJustifyH("LEFT")
    statusHintText:SetWidth(520)
    statusHintText:SetText(L.STATUS_HINT or "NatLust always loads files from Interface\\AddOns\\NatLust\\Media\\")

    local audioHintText = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    audioHintText:SetPoint("TOPLEFT", statusHintText, "BOTTOMLEFT", 0, -12)
    audioHintText:SetJustifyH("LEFT")
    audioHintText:SetWidth(560)
    audioHintText:SetText(L.AUDIO_HINT or "Recommended audio format for WoW: MP3, 44.1 kHz, 128/192 kbps, Stereo, minimal metadata, no embedded cover art.")

    settingsPanel:SetScript("OnShow", function()
        RefreshPathInputs()
        C_Timer.After(0, RefreshPathInputs)
        UpdateToggleButtonLabels()
    end)

    settingsPanel:SetScript("OnHide", function()
        if testState then
            StopAll()
        end
    end)

    settingsCategory = Settings.RegisterCanvasLayoutCategory(settingsPanel, ADDON_NAME)
    Settings.RegisterAddOnCategory(settingsCategory)
    RefreshPathInputs()
    UpdateToggleButtonLabels()
    ApplyElvUISkin()
end

local function PrintUsage()
    print("|cff00ff98NatLust|r " .. (L.USAGE or "Use /nl or /natlust to open the settings panel."))
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
