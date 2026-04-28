------------------------------------------------------------------------
-- StaggerBar · Core/Core.lua
-- AceAddon entry point: init, events, OnUpdate, slash commands
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local LibSink = LibStub("LibSink-2.0", true)
local mixins = { "AceConsole-3.0" }
if LibSink then table.insert(mixins, "LibSink-2.0") end

local StaggerBar = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, unpack(mixins))
ns.addon = StaggerBar

local Utils = ns.Utils
local Bar   = ns.Bar
local L     = ns.L

------------------------------------------------------------------------
-- AceDB profile defaults
------------------------------------------------------------------------
local DB_DEFAULTS = {
    global = {
        schemaVersion = 1,
    },
    profile = {
        -- General
        locked         = false,
        updateInterval = 2,
        testMode       = false,
        smoothBar      = true,
        debug          = false,

        -- Visibility
        hideOutOfCombat  = false,
        hideInTown       = false,
        hideAtFullHP     = false,
        combatFadeDelay  = 3,      -- seconds to wait after combat ends before hiding

        -- Bar
        barWidth    = 250,
        barHeight   = 22,
        barTexture  = "Blizzard",
        bgOpacity   = 0.5,
        barOrientation = "HORIZONTAL",  -- HORIZONTAL or VERTICAL
        barMaxPct = 10,                -- max % of HP for bar scaling (e.g. 10 = 1000%)
        barOverflowWrap = false,       -- false = clamp at max, true = refill cyclically

        -- Position
        position = {
            point    = "CENTER",
            relPoint = "CENTER",
            xOfs     = 0,
            yOfs     = -200,
        },

        -- Border
        borderTexture  = "Blizzard Tooltip",
        borderSize     = 12,
        borderColor    = { 0, 0, 0, 0.9 },

        -- Colors (RGBA)
        colorLight    = { 0.30, 0.80, 0.30, 1 },
        colorModerate = { 1.00, 0.80, 0.00, 1 },
        colorHeavy    = { 1.00, 0.20, 0.20, 1 },
        colorExtreme  = { 0.80, 0.00, 0.80, 1 },
        bgExtreme     = { 0.5, 0, 0.5 },
        bgNormal      = { 0, 0, 0 },

        -- Text — label
        -- Text — templates (use flags: %s %r %p %t %d %tp %m %n %a %purify)
        labelTemplate = "%d (%tp)",
        pctTemplate   = "%p",
        tickTemplate  = "%d/s  (%tp)",

        -- Global font (fallback)
        fontFace     = "Friz Quadrata TT",
        fontSize     = 12,
        fontOutline  = "OUTLINE",

        -- Label font overrides (nil = use global)
        labelFontFace    = nil,
        labelFontSize    = nil,
        labelFontOutline = nil,
        labelAnchor  = "LEFT",
        labelXOfs    = 4,
        labelYOfs    = 0,

        -- Text — percentage
        showPercentage   = true,
        pctFontFace      = nil,
        pctFontSize      = nil,
        pctFontOutline   = nil,
        pctAnchor        = "RIGHT",
        pctXOfs          = -4,
        pctYOfs          = 0,

        -- Number format: 1=raw, 2=k/m, 3=mil/M, 4=K/M
        numberFormat = 2,

        -- Tick display
        showTick         = false,
        tickFontFace     = nil,
        tickFontSize     = 10,
        tickFontOutline  = nil,
        tickAnchor       = "BOTTOM",
        tickXOfs         = 0,
        tickYOfs         = -2,

        -- Sound alerts
        soundEnabled     = false,
        soundTier        = 3,          -- tier that triggers sound
        soundFile        = "Raid Warning",
        soundCooldown    = 5,          -- seconds between alerts

        -- Combat log output
        chatLogEnabled   = false,
        chatLogTier      = 4,          -- tier to log

        -- Sparkline history
        sparklineEnabled = false,
        sparklineHeight  = 12,
        sparklineSamples = 30,      -- number of data points
        sparklineColor   = { 1, 1, 1, 0.6 },
        sparklineYOfs    = 0,

        -- Glow (LibCustomGlow)
        glowEnabled    = true,
        glowTier       = 4,
        glowType       = "AutoCast",     -- Pixel, AutoCast, Button, Proc
        glowColor      = { 1, 0, 0, 0.8 },
        glowXOffset    = 0,
        glowYOffset    = 0,

        -- Pixel glow params
        glowPixelLines     = 8,
        glowPixelFrequency = 0.25,
        glowPixelLength    = nil,       -- nil = auto
        glowPixelThickness = 2,
        glowPixelBorder    = false,

        -- AutoCast glow params
        glowACParticles    = 8,
        glowACFrequency    = 0.25,
        glowACScale        = 1,

        -- Button glow params
        glowButtonFrequency = 0.25,

        -- Proc glow params
        glowProcDuration   = 1,
        glowProcStartAnim  = true,
    },
}

------------------------------------------------------------------------
-- DB schema migration
------------------------------------------------------------------------
local DB_SCHEMA_VERSION = 1

function StaggerBar:MigrateDB()
    local g = self.db.global

    -- future migrations:
    -- if (g.schemaVersion or 0) < 2 then
    --     ... migrate fields ...
    --     g.schemaVersion = 2
    -- end

    g.schemaVersion = DB_SCHEMA_VERSION
end

------------------------------------------------------------------------
-- OnInitialize
------------------------------------------------------------------------
function StaggerBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BrewStaggerBarDB", DB_DEFAULTS, true)
    ns.db   = self.db
    self:MigrateDB()

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied",  "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset",   "RefreshConfig")

    -- LibDualSpec — auto-switch profile per spec
    local LDS = LibStub("LibDualSpec-1.0", true)
    if LDS then LDS:EnhanceDatabase(self.db, ADDON_NAME) end

    -- Build options table (defined in Modules/Options.lua)
    if ns.BuildOptions then ns.BuildOptions() end

    self:RegisterChatCommand("bsb",         "SlashHandler")
    self:RegisterChatCommand("brewstaggerbar", "SlashHandler")
end

------------------------------------------------------------------------
-- Runtime event registration helpers (registered only while active)
------------------------------------------------------------------------
function StaggerBar:RegisterRuntimeEvents()
    if not Bar or not Bar.frame then return end
    local ef = Bar.frame
    ef:RegisterEvent("PLAYER_REGEN_DISABLED")
    ef:RegisterEvent("PLAYER_REGEN_ENABLED")
    ef:RegisterEvent("PLAYER_UPDATE_RESTING")
    ef:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function StaggerBar:UnregisterRuntimeEvents()
    if not Bar or not Bar.frame then return end
    local ef = Bar.frame
    ef:UnregisterEvent("PLAYER_REGEN_DISABLED")
    ef:UnregisterEvent("PLAYER_REGEN_ENABLED")
    ef:UnregisterEvent("PLAYER_UPDATE_RESTING")
    ef:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
end

------------------------------------------------------------------------
-- Active/inactive runtime lifecycle
------------------------------------------------------------------------
function StaggerBar:SetActive(active)
    active = not not active
    if self._active == active then return end
    self._active = active

    if active then
        self:RegisterRuntimeEvents()
        Utils.Debug("SetActive: activated runtime events")
    else
        self:UnregisterRuntimeEvents()
        if self._fadeTimer then self._fadeTimer:Cancel(); self._fadeTimer = nil end
        self._combatFading = false
        if Bar and Bar.frame then
            Bar.frame.elapsed = 0
            Bar.frame.lastSoundTime = nil
            Bar.frame.lastLogTier = nil
            if Bar.frame.sparkFrame then Bar.frame.sparkFrame.data = {} end
        end
        if Bar then
            Bar:Hide()
            Bar:StopGlow()
        end
        Utils.Debug("SetActive: deactivated runtime events")
    end
end

function StaggerBar:RefreshActiveState()
    local active = (self.db and self.db.profile and self.db.profile.testMode == true)
                   or Utils.IsBrewing()
    self:SetActive(active)
    self:UpdateVisibility()
end

------------------------------------------------------------------------
-- OnEnable
------------------------------------------------------------------------
function StaggerBar:OnEnable()
    Bar:Create()
    Bar:ApplySettings()

    -- OnUpdate loop (dt is real elapsed seconds from the engine)
    Bar.frame:SetScript("OnUpdate", function(frame, dt)
        if not self._active then return end
        frame.elapsed = frame.elapsed + dt
        local interval = 1 / (frame.updatesPerSec or 2)
        if frame.elapsed < interval then return end
        frame.dt = frame.elapsed       -- pass real dt to Update
        frame.elapsed = 0
        Bar:Update()
    end)

    -- Lightweight lifecycle events — always registered
    local ef = Bar.frame
    ef:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("PLAYER_TALENT_UPDATE")

    ef:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end

        if event == "PLAYER_REGEN_DISABLED" then
            -- Entered combat — cancel any pending fade and show
            self._combatFading = false
            if self._fadeTimer then self._fadeTimer:Cancel(); self._fadeTimer = nil end
            self:UpdateVisibility()
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Left combat — start fade delay if configured
            local delay = self.db.profile.combatFadeDelay or 3
            if self.db.profile.hideOutOfCombat and delay > 0 then
                self._combatFading = true
                self._fadeTimer = C_Timer.NewTimer(delay, function()
                    self._combatFading = false
                    self:UpdateVisibility()
                end)
            else
                self:UpdateVisibility()
            end
        else
            -- spec/talent/world changes — re-evaluate active state
            self:RefreshActiveState()
        end
    end)

    self:RefreshActiveState()
    self:Print(L["StaggerBar"] .. " loaded.  /bsb help")
end

------------------------------------------------------------------------
-- Visibility — Brewmaster only + conditional rules
------------------------------------------------------------------------
function StaggerBar:UpdateVisibility()
    if not Bar or not Bar.frame then return end
    local p = self.db.profile

    -- Test mode always visible
    if p.testMode == true then Bar:Show(); return end

    -- Inactive (non-Brewmaster, no test mode) — keep hidden
    if not self._active then Bar:Hide(); return end

    -- Must be Brewmaster
    if not Utils.IsBrewing() then Bar:Hide(); return end

    -- Hide in town/rest area
    if p.hideInTown and IsResting() then Bar:Hide(); return end

    -- Hide at full HP (no stagger)
    if p.hideAtFullHP then
        local stagger = Utils.SafeCall(UnitStagger, "player")
        if not stagger or stagger == 0 then Bar:Hide(); return end
    end

    -- Hide out of combat (with fade delay handled by combat events)
    if p.hideOutOfCombat and not InCombatLockdown() and not self._combatFading then
        Bar:Hide(); return
    end

    Bar:Show()
end

------------------------------------------------------------------------
-- RefreshConfig — profile switch callback
------------------------------------------------------------------------
function StaggerBar:RefreshConfig()
    ns.db = self.db
    if Bar.frame then
        Bar:ApplySettings()
        self:RefreshActiveState()
    end
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
function StaggerBar:SlashHandler(input)
    input = (input or ""):trim():lower()

    if input == "" or input == "toggle" then
        if self.db.profile.testMode ~= true and not Utils.IsBrewing() then
            self:Print("BrewStaggerBar is only active for Brewmaster Monk.")
            return
        end
        if Bar:IsShown() then Bar:Hide(); self:Print("Hidden")
        else Bar:Show(); self:Print("Shown") end

    elseif input == "lock" then
        self.db.profile.locked = not self.db.profile.locked
        Bar:ApplySettings()
        self:Print(self.db.profile.locked and L["Locked"] or L["Unlocked"])

    elseif input == "config" or input == "options" or input == "opt" then
        LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)

    elseif input == "reset" then
        self.db:ResetProfile()
        self:Print("Profile reset.")

    elseif input:match("^size") then
        local w, h = input:match("size%s+(%d+)%s+(%d+)")
        if w and h then
            self.db.profile.barWidth  = tonumber(w)
            self.db.profile.barHeight = tonumber(h)
            Bar:ApplySettings()
            self:Print("Resized to " .. w .. "x" .. h)
        else
            self:Print("Usage: /bsb size <width> <height>")
        end

    elseif input == "export" then
        self:ExportProfile()

    elseif input:match("^import") then
        local str = input:match("^import%s+(.+)")
        if str then self:ImportProfile(str)
        else self:Print("Usage: /bsb import <string>") end

    elseif input == "help" then
        self:Print("|cff00ccffStaggerBar|r commands:")
        self:Print("  /bsb            — toggle visibility")
        self:Print("  /bsb lock       — lock/unlock position")
        self:Print("  /bsb config     — open options GUI")
        self:Print("  /bsb size W H   — resize bar")
        self:Print("  /bsb reset      — reset profile")
        self:Print("  /bsb export     — export profile string")
        self:Print("  /bsb import STR — import profile string")
    else
        self:Print("Unknown command. /bsb help")
    end
end

------------------------------------------------------------------------
-- Profile export/import (AceSerializer + LibDeflate)
------------------------------------------------------------------------
function StaggerBar:ExportProfile()
    local AceSerializer = LibStub("AceSerializer-3.0", true)
    local LibDeflate    = LibStub("LibDeflate", true)
    if not AceSerializer or not LibDeflate then
        self:Print("Export requires AceSerializer and LibDeflate."); return
    end

    local serialized = AceSerializer:Serialize(self.db.profile)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded    = LibDeflate:EncodeForPrint(compressed)

    -- Show in a copy-paste dialog
    if not ns.exportFrame then
        local f = CreateFrame("Frame", "BSBExportFrame", UIParent, "BackdropTemplate")
        f:SetSize(450, 300)
        f:SetPoint("CENTER")
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14, insets = {left=3,right=3,top=3,bottom=3} })
        f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -8)
        title:SetText("|cff00ccffStaggerBar|r Export")

        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -32)
        scroll:SetPoint("BOTTOMRIGHT", -28, 36)

        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(390)
        scroll:SetScrollChild(eb)
        f.editBox = eb

        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(80, 22)
        btn:SetPoint("BOTTOM", 0, 8)
        btn:SetText("Close")
        btn:SetScript("OnClick", function() f:Hide() end)

        ns.exportFrame = f
    end

    ns.exportFrame.editBox:SetText(encoded)
    ns.exportFrame.editBox:HighlightText()
    ns.exportFrame:Show()
    self:Print("Profile exported. Copy the string from the window.")
end

function StaggerBar:ImportProfile(encoded)
    local AceSerializer = LibStub("AceSerializer-3.0", true)
    local LibDeflate    = LibStub("LibDeflate", true)
    if not AceSerializer or not LibDeflate then
        self:Print("Import requires AceSerializer and LibDeflate."); return
    end

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then self:Print("|cffFF0000Import failed:|r invalid string."); return end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then self:Print("|cffFF0000Import failed:|r decompression error."); return end

    local ok, data = AceSerializer:Deserialize(serialized)
    if not ok or type(data) ~= "table" then
        self:Print("|cffFF0000Import failed:|r corrupt data."); return
    end

    -- Merge into current profile
    for k, v in pairs(data) do
        self.db.profile[k] = v
    end
    self:RefreshConfig()
    self:Print("|cff00FF00Profile imported successfully.|r")
end