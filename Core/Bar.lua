------------------------------------------------------------------------
-- StaggerBar · Core/Bar.lua
-- Bar frame creation, text elements, and visual update loop
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local Utils = ns.Utils
local LCG
local LibSmooth
local GLOW_KEY = "StaggerBarGlow"

ns.Bar = {}
local Bar = ns.Bar

------------------------------------------------------------------------
-- Resolve a LibSharedMedia path (statusbar or font)
------------------------------------------------------------------------
local function LSM_Fetch(mediaType, key, fallback)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local path = LSM:Fetch(mediaType, key)
        if path then return path end
    end
    return fallback
end

------------------------------------------------------------------------
-- Create the bar frame
------------------------------------------------------------------------
function Bar:Create()
    LCG = LibStub("LibCustomGlow-1.0", true)
    LibSmooth = LibStub("LibSmoothStatusBar-1.0", true)
    local f = CreateFrame("Frame", "StaggerBarFrame", UIParent, "BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(5)
    f:SetClampedToScreen(true)

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0, 0, 0, 0.9)

    -- StatusBar
    local bar = CreateFrame("StatusBar", "StaggerBarStatusBar", f)
    bar:SetPoint("TOPLEFT", 3, -3)
    bar:SetPoint("BOTTOMRIGHT", -3, 3)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    f.bar = bar

    -- Background texture
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetVertexColor(0, 0, 0, 0.5)
    f.bg = bg

    -- Spark
    local spark = bar:CreateTexture(nil, "OVERLAY", nil, 1)
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetSize(12, 30)
    f.spark = spark

    -- Text: label (custom / "Stagger")
    local labelText = bar:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    labelText:SetShadowOffset(1, -1)
    f.labelText = labelText

    -- Text: percentage
    local pctText = bar:CreateFontString(nil, "OVERLAY")
    pctText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    pctText:SetShadowOffset(1, -1)
    f.pctText = pctText

    -- Text: tick info
    local tickText = bar:CreateFontString(nil, "OVERLAY")
    tickText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    tickText:SetShadowOffset(1, -1)
    f.tickText = tickText

    -- Text: test mode indicator
    local testBadge = f:CreateFontString(nil, "OVERLAY")
    testBadge:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    testBadge:SetShadowOffset(1, -1)
    testBadge:SetTextColor(1, 0.8, 0, 1)
    testBadge:SetPoint("TOP", f, "BOTTOM", 0, -1)
    testBadge:SetText("")
    f.testBadge = testBadge

    -- Sparkline frame (mini history graph below the bar)
    local sparkFrame = CreateFrame("Frame", nil, f)
    sparkFrame:SetHeight(12)
    sparkFrame:Hide()
    sparkFrame.lines = {}
    sparkFrame.data  = {}
    f.sparkFrame = sparkFrame

    -- Dragging
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function(self)
        if not ns.db or not ns.db.profile.locked then
            self:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not ns.db then return end
        local pos = ns.db.profile.position
        local anchor = ns.GetAnchorFrame(pos.anchorTo or "UIParent", pos.customFrame) or UIParent

        -- Recompute X/Y so the bar stays at its new screen position
        -- relative to the user-chosen anchor frame, preserving their
        -- point/relPoint choices.
        local point    = pos.point    or "CENTER"
        local relPoint = pos.relPoint or "CENTER"
        local bx, by = ns.GetCornerPos(self,   point)
        local ax, ay = ns.GetCornerPos(anchor, relPoint)
        pos.xOfs = bx - ax
        pos.yOfs = by - ay

        self:ClearAllPoints()
        self:SetPoint(point, anchor, relPoint, pos.xOfs, pos.yOfs)
    end)

    -- Tooltip
    f:SetScript("OnEnter", function(self)
        if ns.db and ns.db.profile.locked then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("|cff00ccffStaggerBar|r", 1, 1, 1)
        GameTooltip:AddLine("Drag to move  |  /bsb lock  |  /bsb config", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Throttle state
    f.elapsed  = 0
    f.throttle = 0

    self.frame = f
    return f
end

------------------------------------------------------------------------
-- Helper: anchor a FontString and set justify
------------------------------------------------------------------------
local function AnchorText(fs, anchor, parent, xOfs, yOfs)
    fs:ClearAllPoints()
    fs:SetPoint(anchor, parent, anchor, xOfs or 0, yOfs or 0)
    if anchor:find("LEFT") then
        fs:SetJustifyH("LEFT")
    elseif anchor:find("RIGHT") then
        fs:SetJustifyH("RIGHT")
    else
        fs:SetJustifyH("CENTER")
    end
end

------------------------------------------------------------------------
-- Apply all settings from DB profile to the bar
------------------------------------------------------------------------
function Bar:ApplySettings()
    local f = self.frame
    if not f or not ns.db then return end
    local p = ns.db.profile

    -- Geometry & position
    f:SetSize(p.barWidth, p.barHeight)
    f:ClearAllPoints()
    local anchorFrame = ns.GetAnchorFrame(p.position.anchorTo or "UIParent", p.position.customFrame) or UIParent
    f:SetPoint(p.position.point, anchorFrame, p.position.relPoint, p.position.xOfs, p.position.yOfs)

    -- Clamp to screen (recover bar if offscreen after resolution change)
    C_Timer.After(0, function() Utils.ClampToScreen(f) end)

    -- Texture (LSM)
    local tex = LSM_Fetch("statusbar", p.barTexture, "Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetStatusBarTexture(tex)
    f.bg:SetTexture(tex)
    f.bg:SetAlpha(p.bgOpacity or 0.5)

    -- Throttle (updates per second — used as real-time interval in OnUpdate)
    f.updatesPerSec = p.updateInterval or 2

    -- Font (LSM) — global fallbacks
    local fontPath    = LSM_Fetch("font", p.fontFace, STANDARD_TEXT_FONT)
    local outlineFlag = p.fontOutline or "OUTLINE"

    -- Helper: resolve per-element font or fall back to global
    local function ResolveFont(facePref, sizePref, outlinePref, defaultSize)
        local face = facePref and LSM_Fetch("font", facePref, fontPath) or fontPath
        local size = sizePref or defaultSize or (p.fontSize or 12)
        local outline = outlinePref or outlineFlag
        return face, size, outline
    end

    -- Label text
    local lf, ls, lo = ResolveFont(p.labelFontFace, p.labelFontSize, p.labelFontOutline, p.fontSize)
    f.labelText:SetFont(lf, ls, lo)
    AnchorText(f.labelText, p.labelAnchor or "LEFT", f.bar, p.labelXOfs or 4, p.labelYOfs or 0)
    f.labelText:SetText(p.labelTemplate or "%n")

    -- Percentage text
    local pf, ps, po = ResolveFont(p.pctFontFace, p.pctFontSize, p.pctFontOutline, p.fontSize)
    f.pctText:SetFont(pf, ps, po)
    AnchorText(f.pctText, p.pctAnchor or "RIGHT", f.bar, p.pctXOfs or -4, p.pctYOfs or 0)
    f.pctText:SetShown(p.showPercentage ~= false)

    -- Tick text
    local tf, ts, to_ = ResolveFont(p.tickFontFace, p.tickFontSize, p.tickFontOutline, 10)
    f.tickText:SetFont(tf, ts, to_)
    AnchorText(f.tickText, p.tickAnchor or "BOTTOM", f.bar, p.tickXOfs or 0, p.tickYOfs or -2)
    f.tickText:SetShown(p.showTick or false)

    -- Smooth bar via LibSmoothStatusBar
    if LibSmooth then
        if p.smoothBar then
            LibSmooth:SmoothBar(f.bar)
        else
            LibSmooth:ResetBar(f.bar)
        end
    end

    -- Bar orientation
    local isVertical = (p.barOrientation == "VERTICAL")
    f.bar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
    f.isVertical = isVertical

    -- Spark size
    if isVertical then
        f.spark:SetSize(p.barWidth * 1.8, 12)
        f.spark:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)  -- rotate 90°
    else
        f.spark:SetSize(12, p.barHeight * 1.8)
        f.spark:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)  -- default
    end


    -- Border customization
    local borderTex = LSM_Fetch("border", p.borderTexture, "Interface\\Tooltips\\UI-Tooltip-Border")
    local borderSz  = p.borderSize or 12
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = borderTex,
        edgeSize = borderSz,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0, 0, 0, 0.7)

    -- Border color (always applied from profile)
    local bc = p.borderColor or { 0, 0, 0, 0.9 }
    f:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 0.9)

    -- Lock visual
    if p.locked then
        f:EnableMouse(false)
    else
        f:EnableMouse(true)
    end
end

------------------------------------------------------------------------
-- Test mode state
------------------------------------------------------------------------
local testValue     = 0
local testDirection = 1   -- 1 = subiendo, -1 = bajando
local TEST_SPEED    = 0.4 -- cuánto sube/baja pct por segundo
local TEST_MAX_HP   = 5000000

local function GetTestData(dt)
    testValue = testValue + (TEST_SPEED * dt * testDirection)
    if testValue >= 1.3 then
        testValue = 1.3
        testDirection = -1
    elseif testValue <= 0 then
        testValue = 0
        testDirection = 1
    end
    return testValue * TEST_MAX_HP, TEST_MAX_HP
end

function Bar:ResetTestState()
    testValue     = 0
    testDirection = 1
end

------------------------------------------------------------------------
-- Stop all active glow types and reset the flag
------------------------------------------------------------------------
function Bar:StopGlow()
    local f = self.frame
    if not f or not LCG then return end
    LCG.PixelGlow_Stop(f, GLOW_KEY)
    LCG.AutoCastGlow_Stop(f, GLOW_KEY)
    LCG.ButtonGlow_Stop(f)
    LCG.ProcGlow_Stop(f, GLOW_KEY)
    f.glowActive = false
end

------------------------------------------------------------------------
-- Per-frame visual update
------------------------------------------------------------------------
function Bar:Update()
    local f = self.frame
    if not f or not ns.db then return end
    local p = ns.db.profile

    local stagger, maxHP

    -- Test mode indicator badge
    if f.testBadge then
        f.testBadge:SetShown(p.testMode == true)
        if p.testMode then f.testBadge:SetText("|cffFFCC00TEST MODE|r") end
    end

    if p.testMode then
        stagger, maxHP = GetTestData(f.dt or 0.033)
    else
        stagger = Utils.SafeCall(UnitStagger, "player")
        maxHP   = Utils.SafeCall(UnitHealthMax, "player")
    end

    if not stagger or not maxHP or maxHP == 0 or maxHP == 1 then
        f.bar:SetValue(0)
        f.labelText:SetText("")
        f.pctText:SetText("")
        f.tickText:SetText("")
        return
    end

    local tier, pct = Utils.GetStaggerTier(stagger, maxHP)
    if not pct then f.bar:SetValue(0); return end

    -- Bar fill
    local colorKeys = { "colorLight", "colorModerate", "colorHeavy", "colorExtreme" }
    local color = p[colorKeys[tier]]

    local maxPct = p.barMaxPct or 10
    local targetVal
    if p.barOverflowWrap then
        -- Wrap: bar refills from 0 when exceeding maxPct (cyclic)
        targetVal = (pct % maxPct) / maxPct
        if pct >= maxPct and targetVal == 0 then targetVal = 1 end
    else
        -- Clamp: bar stays full at maxPct
        targetVal = math.min(pct / maxPct, 1)
    end

    if tier == 4 then
        f.bg:SetVertexColor(p.bgExtreme[1], p.bgExtreme[2], p.bgExtreme[3], p.bgOpacity or 0.5)
    else
        f.bg:SetVertexColor(p.bgNormal[1], p.bgNormal[2], p.bgNormal[3], p.bgOpacity or 0.5)
    end

    -- SetValue — LibSmoothStatusBar handles interpolation if enabled
    f.bar:SetValue(targetVal)
    f.currentVal = targetVal
    f.bar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)

    -- Glow control (LibCustomGlow)
    if LCG and p.glowEnabled then
        if tier >= (p.glowTier or 4) then
            if not f.glowActive then
                local gc = p.glowColor or { 1, 0, 0, 0.8 }
                local gt = p.glowType or "Pixel"
                local xo = p.glowXOffset or 0
                local yo = p.glowYOffset or 0

                if gt == "Pixel" then
                    LCG.PixelGlow_Start(f, gc,
                        p.glowPixelLines or 8,
                        p.glowPixelFrequency or 0.25,
                        p.glowPixelLength,          -- nil = auto
                        p.glowPixelThickness or 2,
                        xo, yo,
                        p.glowPixelBorder or false,
                        GLOW_KEY)
                elseif gt == "AutoCast" then
                    LCG.AutoCastGlow_Start(f, gc,
                        p.glowACParticles or 8,
                        p.glowACFrequency or 0.25,
                        p.glowACScale or 1,
                        xo, yo,
                        GLOW_KEY)
                elseif gt == "Button" then
                    LCG.ButtonGlow_Start(f, gc,
                        p.glowButtonFrequency or 0.25)
                elseif gt == "Proc" then
                    LCG.ProcGlow_Start(f, {
                        color      = gc,
                        duration   = p.glowProcDuration or 1,
                        startAnim  = p.glowProcStartAnim ~= false,
                        xOffset    = xo,
                        yOffset    = yo,
                        key        = GLOW_KEY,
                    })
                end
                f.glowActive = true
                f.glowActiveType = gt
            end
        else
            if f.glowActive then self:StopGlow() end
        end
    elseif f.glowActive then
        self:StopGlow()
    end

    -- Sound alert
    if p.soundEnabled and tier >= (p.soundTier or 3) then
        local now = GetTime()
        if not f.lastSoundTime or (now - f.lastSoundTime) >= (p.soundCooldown or 5) then
            local soundFile = LSM_Fetch("sound", p.soundFile, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959)
            if type(soundFile) == "string" then
                PlaySoundFile(soundFile, "Master")
            elseif type(soundFile) == "number" then
                PlaySound(soundFile, "Master")
            end
            f.lastSoundTime = now
        end
    end

    -- Chat log when reaching a tier — routed via LibSink if available
    if p.chatLogEnabled and tier >= (p.chatLogTier or 4) then
        if not f.lastLogTier or f.lastLogTier < tier then
            local tierNames = { "Light", "Moderate", "Heavy", "EXTREME" }
            local msg = string.format("%s stagger: %s (%d%%)",
                tierNames[tier] or "?",
                Utils.FormatNumber(stagger, p.numberFormat or 2),
                math.floor(pct * 100))
            local addon = ns.addon
            if addon and addon.Pour then
                addon:Pour(msg, 1, 0.8, 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffFFCC00[StaggerBar]|r " .. msg)
            end
        end
    end
    f.lastLogTier = tier

    -- Spark position (horizontal or vertical)
    if f.isVertical then
        local barH = f.bar:GetHeight()
        if barH and barH > 0 then
            local py = barH * (f.currentVal or f.bar:GetValue())
            f.spark:ClearAllPoints()
            f.spark:SetPoint("CENTER", f.bar, "BOTTOM", 0, py)
        end
    else
        local barW = f.bar:GetWidth()
        if barW and barW > 0 then
            local px = barW * (f.currentVal or f.bar:GetValue())
            f.spark:ClearAllPoints()
            f.spark:SetPoint("CENTER", f.bar, "LEFT", px, 0)
        end
    end

    -- Compute tick (API first, then fallback). All math on `stagger` is
    -- wrapped because UnitStagger may return a tainted "secret number".
    local tickVal = Utils.GetStaggerTickValue()
    local staggerPositive = Utils.SafeOp(function() return stagger > 0 end, false)
    if (not tickVal or tickVal == 0) and staggerPositive then
        if p.testMode then
            tickVal = Utils.SafeDiv(stagger, 20)
        else
            tickVal = Utils.SafeDiv(stagger, Utils.GetStaggerTicks())
        end
    end
    tickVal = tickVal or 0

    local dps = tickVal * 2
    local tickHpPct = 0
    if maxHP > 0 and dps > 0 then
        local safeDiv = Utils.SafeDiv(dps, maxHP)
        if safeDiv then tickHpPct = math.floor(safeDiv * 1000) / 100 end
    end

    -- Build data table for templates (sanitize stagger for display).
    local staggerFloored = Utils.SafeOp(function() return math.floor(stagger) end, 0)
    local data = {
        stagger    = stagger,
        rawStagger = tostring(staggerFloored),
        maxHP      = maxHP,
        pctStr     = math.floor(pct * 100),
        tick       = tickVal,
        dps        = dps,
        tickPct    = tickHpPct,
        name       = "Stagger",
    }

    local numFmt = p.numberFormat or 2

    -- Label text
    local labelTpl = p.labelTemplate or "%n"
    if labelTpl == "" then labelTpl = "%n" end
    f.labelText:SetText(Utils.FormatText(labelTpl, data, numFmt))

    -- Percentage text
    if p.showPercentage ~= false then
        local pctTpl = p.pctTemplate or "%p"
        f.pctText:SetText(Utils.FormatText(pctTpl, data, numFmt))
    else
        f.pctText:SetText("")
    end

    -- Tick text
    if p.showTick then
        local tickTpl = p.tickTemplate or "%d/s  (%tp)"
        f.tickText:SetText(Utils.FormatText(tickTpl, data, numFmt))
    else
        f.tickText:SetText("")
    end

    -- Sparkline history
    self:UpdateSparkline(pct, p)
end

------------------------------------------------------------------------
-- Sparkline mini-graph
------------------------------------------------------------------------
function Bar:UpdateSparkline(pct, p)
    local f = self.frame
    local sf = f.sparkFrame
    if not sf then return end

    if not p.sparklineEnabled then sf:Hide(); return end
    sf:Show()

    local maxSamples = p.sparklineSamples or 30
    sf:SetHeight(p.sparklineHeight or 12)
    local yOfs = p.sparklineYOfs or 0
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 2, yOfs)
    sf:SetPoint("TOPRIGHT", self.frame, "BOTTOMRIGHT", -2, yOfs)

    -- Add data point
    table.insert(sf.data, math.min(pct or 0, 1.5))
    if #sf.data > maxSamples then table.remove(sf.data, 1) end

    -- Clear old lines
    for _, line in ipairs(sf.lines) do line:Hide() end

    local w = sf:GetWidth()
    local h = sf:GetHeight()
    if w <= 0 or h <= 0 or #sf.data < 2 then return end

    local sc = p.sparklineColor or { 1, 1, 1, 0.6 }
    local maxPct = 1.5  -- scale so 150% stagger = full height
    local step = w / (maxSamples - 1)

    for i = 2, #sf.data do
        local idx = i - 1
        if not sf.lines[idx] then
            local line = sf:CreateLine(nil, "OVERLAY")
            line:SetThickness(1.5)
            sf.lines[idx] = line
        end
        local line = sf.lines[idx]
        local x1 = (i - 2) * step
        local y1 = (sf.data[i-1] / maxPct) * h
        local x2 = (i - 1) * step
        local y2 = (sf.data[i] / maxPct) * h
        line:SetStartPoint("BOTTOMLEFT", sf, x1, y1)
        line:SetEndPoint("BOTTOMLEFT", sf, x2, y2)
        line:SetColorTexture(sc[1], sc[2], sc[3], sc[4] or 0.6)
        line:Show()
    end
end

------------------------------------------------------------------------
-- Show / Hide helpers
------------------------------------------------------------------------
function Bar:Show()
    if self.frame then 
        self.frame:Show()
    end
end
function Bar:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Bar:IsShown()
    return self.frame and self.frame:IsShown()
end