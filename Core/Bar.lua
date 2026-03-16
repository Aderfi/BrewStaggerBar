------------------------------------------------------------------------
-- StaggerBar · Core/Bar.lua
-- Bar frame creation, text elements, and visual update loop
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local Utils = ns.Utils
local LCG
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
        if ns.db then
            local point, _, relPoint, x, y = self:GetPoint()
            ns.db.profile.position.point    = point
            ns.db.profile.position.relPoint = relPoint
            ns.db.profile.position.xOfs     = x
            ns.db.profile.position.yOfs     = y
        end
    end)

    -- Tooltip
    f:SetScript("OnEnter", function(self)
        if ns.db and ns.db.profile.locked then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("|cff00ccffStaggerBar|r", 1, 1, 1)
        GameTooltip:AddLine("Drag to move  |  /sb lock  |  /sb config", 0.7, 0.7, 0.7)
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
    f:SetPoint(p.position.point, UIParent, p.position.relPoint, p.position.xOfs, p.position.yOfs)

    -- Texture (LSM)
    local tex = LSM_Fetch("statusbar", p.barTexture, "Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetStatusBarTexture(tex)
    f.bg:SetTexture(tex)
    f.bg:SetAlpha(p.bgOpacity or 0.5)

    -- Throttle
    f.throttle = (p.updateInterval or 2) * (1 / 60)

    -- Font (LSM)
    local fontPath    = LSM_Fetch("font", p.fontFace, STANDARD_TEXT_FONT)
    local outlineFlag = p.fontOutline or "OUTLINE"

    -- Label text
    f.labelText:SetFont(fontPath, p.fontSize or 12, outlineFlag)
    AnchorText(f.labelText, p.labelAnchor or "LEFT", f.bar, p.labelXOfs or 4, p.labelYOfs or 0)
    f.labelText:SetText(p.labelTemplate or "%n")

    -- Percentage text
    f.pctText:SetFont(fontPath, p.fontSize or 12, outlineFlag)
    AnchorText(f.pctText, p.pctAnchor or "RIGHT", f.bar, p.pctXOfs or -4, p.pctYOfs or 0)
    f.pctText:SetShown(p.showPercentage ~= false)

    -- Tick text
    f.tickText:SetFont(fontPath, p.tickFontSize or 10, outlineFlag)
    AnchorText(f.tickText, p.tickAnchor or "BOTTOM", f.bar, p.tickXOfs or 0, p.tickYOfs or -2)
    f.tickText:SetShown(p.showTick or false)

    -- Spark height
    f.spark:SetHeight(p.barHeight * 1.8)


    -- Lock visual
    if p.locked then
        f:SetBackdropBorderColor(0, 0, 0, 0.5)
        f:EnableMouse(false)
    else
        f:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)
        f:EnableMouse(true)
    end
end

------------------------------------------------------------------------
-- Test mode state
------------------------------------------------------------------------
local testValue = 0
local testDirection = 1  -- 1 = subiendo, -1 = bajando
local TEST_SPEED = 0.4   -- cuánto sube/baja pct por segundo
local TEST_MAX_HP = 5000000

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

------------------------------------------------------------------------
-- Per-frame visual update
------------------------------------------------------------------------
function Bar:Update()
    local f = self.frame
    if not f or not ns.db then return end
    local p = ns.db.profile

    local stagger, maxHP

    if p.testMode then
        stagger, maxHP = GetTestData(f.elapsed + (f.throttle or 0.033))
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

    if tier == 4 then
        local overflow = Utils.SafeDiv(Utils.SafeSub(stagger, maxHP), maxHP) or 0
        f.bar:SetValue(math.min(overflow, 1))
        f.bg:SetVertexColor(p.bgExtreme[1], p.bgExtreme[2], p.bgExtreme[3], p.bgOpacity or 0.5)
    else
        f.bar:SetValue(pct)
        f.bg:SetVertexColor(p.bgNormal[1], p.bgNormal[2], p.bgNormal[3], p.bgOpacity or 0.5)
    end
    f.bar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)

    -- Glow control (LibCustomGlow)
    if LCG and p.glowEnabled then
        if tier >= (p.glowTier or 4) then
            if not f.glowActive then
                local gc = p.glowColor or { 1, 0, 0, 0.8 }
                local glowType = p.glowType or "Pixel"

                if glowType == "Pixel" then
                    LCG.PixelGlow_Start(f, gc, p.glowLines, p.glowFrequency,
                        p.glowLength, p.glowThickness,
                        p.glowXOffset, p.glowYOffset, false, GLOW_KEY)
                elseif glowType == "AutoCast" then
                    LCG.AutoCastGlow_Start(f, gc, p.glowLines, p.glowFrequency,
                        p.glowScale, p.glowXOffset, p.glowYOffset, GLOW_KEY)
                elseif glowType == "Button" then
                    LCG.ButtonGlow_Start(f, gc, p.glowFrequency)
                elseif glowType == "Proc" then
                    LCG.ProcGlow_Start(f, gc, GLOW_KEY)
                end
                f.glowActive = true
            end
        else
            if f.glowActive then
                local glowType = p.glowType or "Pixel"
                if glowType == "Pixel" then
                    LCG.PixelGlow_Stop(f, GLOW_KEY)
                elseif glowType == "AutoCast" then
                    LCG.AutoCastGlow_Stop(f, GLOW_KEY)
                elseif glowType == "Button" then
                    LCG.ButtonGlow_Stop(f)
                elseif glowType == "Proc" then
                    LCG.ProcGlow_Stop(f, GLOW_KEY)
                end
                f.glowActive = false
            end
        end
    elseif f.glowActive and LCG then
        LCG.PixelGlow_Stop(f, GLOW_KEY)
        LCG.AutoCastGlow_Stop(f, GLOW_KEY)
        LCG.ButtonGlow_Stop(f)
        LCG.ProcGlow_Stop(f, GLOW_KEY)
        f.glowActive = false
    end

    -- Spark
    local barW = f.bar:GetWidth()
    if barW and barW > 0 then
        local px = barW * f.bar:GetValue()
        f.spark:ClearAllPoints()
        f.spark:SetPoint("CENTER", f.bar, "LEFT", px, 0)
    end

    -- Compute tick (API first, then fallback)
    local tickVal = Utils.GetStaggerTickValue()
    if (not tickVal or tickVal == 0) and stagger > 0 then
        if p.testMode then
            tickVal = stagger / 20
        else
            tickVal = stagger / Utils.GetStaggerTicks()
        end
    end
    tickVal = tickVal or 0

    local dps = tickVal * 2
    local tickHpPct = 0
    if maxHP > 0 and dps > 0 then
        tickHpPct = math.floor(Utils.SafeDiv(dps, maxHP) * 1000)
    end

    -- Build data table for templates
    local data = {
        stagger    = stagger,
        rawStagger = tostring(math.floor(stagger)),
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

