------------------------------------------------------------------------
-- StaggerBar · Core/Core.lua
-- AceAddon entry point: init, events, OnUpdate, slash commands
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local StaggerBar = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")
ns.addon = StaggerBar

local Utils = ns.Utils
local Bar   = ns.Bar
local L     = ns.L

------------------------------------------------------------------------
-- AceDB profile defaults
------------------------------------------------------------------------
local DB_DEFAULTS = {
    profile = {
        -- General
        locked         = false,
        updateInterval = 2,
        testMode       = false,

        -- Bar
        barWidth    = 250,
        barHeight   = 22,
        barTexture  = "Blizzard",
        bgOpacity   = 0.5,

        -- Position
        position = {
            point    = "CENTER",
            relPoint = "CENTER",
            xOfs     = 0,
            yOfs     = -200,
        },

        -- Colors (RGBA)
        colorLight    = { 0.30, 0.80, 0.30, 1 },
        colorModerate = { 1.00, 0.80, 0.00, 1 },
        colorHeavy    = { 1.00, 0.20, 0.20, 1 },
        colorExtreme  = { 1.00, 0.00, 0.00, 1 },
        bgExtreme     = { 1, 0, 0 },
        bgNormal      = { 0, 0, 0 },

        -- Text — label
        -- Text — templates (use flags: %s %r %p %t %d %tp %m %n)
        labelTemplate = "%n",
        pctTemplate   = "%p",
        tickTemplate  = "%d/s  (%tp)",
        fontFace     = "Friz Quadrata TT",
        fontSize     = 12,
        fontOutline  = "OUTLINE",
        labelAnchor  = "LEFT",
        labelXOfs    = 4,
        labelYOfs    = 0,

        -- Text — percentage
        showPercentage = true,
        pctAnchor      = "RIGHT",
        pctXOfs        = -4,
        pctYOfs        = 0,

        -- Number format: 1=raw, 2=k/m, 3=mil/M, 4=K/M
        numberFormat = 2,

        -- Tick display
        showTickPercent = true,
        tickAnchor      = "BOTTOM",
        tickXOfs        = 0,
        tickYOfs        = -2,

        -- Glow (LibCustomGlow)
        glowEnabled    = true,
        glowTier       = 4,
        glowType       = "Autocast",     -- Pixel, AutoCast, Button, Proc
        glowColor      = { 1, 0, 0, 0.8 },
        glowLines      = 8,           -- N for Pixel / particle groups for AutoCast
        glowFrequency  = 0.25,
        glowLength     = nil,          -- nil = auto
        glowThickness  = 2,
        glowScale      = 1,
        glowXOffset    = 0,
        glowYOffset    = 0,
    },
}

------------------------------------------------------------------------
-- OnInitialize
------------------------------------------------------------------------
function StaggerBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("StaggerBarDB", DB_DEFAULTS, true)
    ns.db   = self.db

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied",  "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset",   "RefreshConfig")

    -- Build options table (defined in Modules/Options.lua)
    if ns.BuildOptions then ns.BuildOptions() end

    self:RegisterChatCommand("bsb",         "SlashHandler")
    self:RegisterChatCommand("brewstaggerbar", "SlashHandler")
end

------------------------------------------------------------------------
-- OnEnable
------------------------------------------------------------------------
function StaggerBar:OnEnable()
    Bar:Create()
    Bar:ApplySettings()

    -- OnUpdate loop
    Bar.frame:SetScript("OnUpdate", function(frame, dt)
        frame.elapsed = frame.elapsed + dt
        if frame.elapsed < frame.throttle then return end
        frame.elapsed = 0
        Bar:Update()
    end)

    -- Spec / zone change events
    local ef = Bar.frame
    ef:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("PLAYER_TALENT_UPDATE")
    ef:SetScript("OnEvent", function()
        self:UpdateVisibility()
    end)

    self:UpdateVisibility()
    self:Print(L["StaggerBar"] .. " loaded.  /sb help")
end

------------------------------------------------------------------------
-- Visibility — Brewmaster only
------------------------------------------------------------------------
function StaggerBar:UpdateVisibility()
    if not Bar or not Bar.frame then return end
    if self.db.profile.testMode then Bar:Show(); return end
    if Utils.IsBrewing() then Bar:Show() else Bar:Hide() end
end

------------------------------------------------------------------------
-- RefreshConfig — profile switch callback
------------------------------------------------------------------------
function StaggerBar:RefreshConfig()
    ns.db = self.db
    if Bar.frame then
        Bar:ApplySettings()
        self:UpdateVisibility()
    end
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
function StaggerBar:SlashHandler(input)
    input = (input or ""):trim():lower()

    if input == "" or input == "toggle" then
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
            self:Print("Usage: /sb size <width> <height>")
        end

    elseif input == "help" then
        self:Print("|cff00ccffStaggerBar|r commands:")
        self:Print("  /sb            — toggle visibility")
        self:Print("  /sb lock       — lock/unlock position")
        self:Print("  /sb config     — open options GUI")
        self:Print("  /sb size W H   — resize bar")
        self:Print("  /sb reset      — reset profile")
    else
        self:Print("Unknown command. /sb help")
    end
end
