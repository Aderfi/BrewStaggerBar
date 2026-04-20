------------------------------------------------------------------------
-- StaggerBar · Modules/Options.lua
-- AceConfig-3.0 options table definition
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local L   = ns.L
local Bar = ns.Bar

------------------------------------------------------------------------
-- Shared dropdown values (defined in Core/Utils.lua as ns.*)
------------------------------------------------------------------------
local ANCHOR_VALUES       = ns.ANCHOR_POINTS
local OUTLINE_VALUES      = ns.OUTLINE_STYLES
local NUMBER_FORMAT_VALUES = ns.NUMBER_FORMATS

local TIER_VALUES = {
    [1] = "Light (0-30%)",
    [2] = "Moderate (30-60%)",
    [3] = "Heavy (60-100%)",
    [4] = "Extreme (>100%)",
}

local ORIENTATION_VALUES = {
    HORIZONTAL = L["Horizontal"],
    VERTICAL   = L["Vertical"],
}

local function Refresh()
    if Bar and Bar.frame then Bar:ApplySettings() end
end

local TEMPLATE_FLAGS_DESC = L["Template Flags Desc"]
    .. "\n\n"
    .. "|cff00ccff%n|r = " .. L["Flag Name"]
    .. "\n|cff00ccff%s|r = " .. L["Flag Stagger"]
    .. "\n|cff00ccff%r|r = " .. L["Flag Raw"]
    .. "\n|cff00ccff%p|r = " .. L["Flag Percent"]
    .. "\n|cff00ccff%t|r = " .. L["Flag Tick"]
    .. "\n|cff00ccff%d|r = " .. L["Flag DPS"]
    .. "\n|cff00ccff%tp|r = " .. L["Flag TickPct"]
    .. "\n|cff00ccff%m|r = " .. L["Flag MaxHP"]
    .. "\n|cff00ccff%a|r = " .. L["Flag Absolute"]
    .. "\n|cff00ccff%purify|r = " .. L["Flag Purify"]
    .. "\n\n" .. L["Template Example"]

------------------------------------------------------------------------
-- Build and register options
------------------------------------------------------------------------
function ns.BuildOptions()
    local LSM = LibStub("LibSharedMedia-3.0", true)

    local fontValues   = LSM and LSM:HashTable("font")   or { ["Friz Quadrata TT"] = "Friz Quadrata TT" }
    local barValues    = LSM and LSM:HashTable("statusbar") or { ["Blizzard"] = "Blizzard" }
    local borderValues = LSM and LSM:HashTable("border") or { ["Blizzard Tooltip"] = "Blizzard Tooltip" }
    local soundValues  = LSM and LSM:HashTable("sound")  or { ["Raid Warning"] = "Raid Warning" }

    local options = {
        name = "|cff00ccffBrewStaggerBar|r",
        type = "group",
        childGroups = "tab",
        args = {

            --------------------------------------------------------
            -- TAB 1: General
            --------------------------------------------------------
            general = {
                name = L["General"],
                type = "group",
                order = 1,
                args = {
                    locked = {
                        name = L["Lock Position"],
                        desc = L["Lock Position Desc"],
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return ns.db.profile.locked end,
                        set = function(_, v) ns.db.profile.locked = v; Refresh() end,
                    },
                    updateInterval = {
                        name = L["Update Interval"],
                        desc = L["Update Interval Desc"],
                        type = "range",
                        order = 2,
                        min = 1, max = 10, step = 1,
                        get = function() return ns.db.profile.updateInterval end,
                        set = function(_, v)
                            ns.db.profile.updateInterval = v
                            if Bar.frame then Bar.frame.updatesPerSec = v end
                        end,
                    },
                    smoothBar = {
                        name = L["Smooth Bar"],
                        desc = L["Smooth Bar Desc"],
                        type = "toggle", order = 3, width = "full",
                        get = function() return ns.db.profile.smoothBar end,
                        set = function(_, v) ns.db.profile.smoothBar = v; Refresh() end,
                    },

                    -- ── Visibility ───────────────────────────────
                    hdrVis = { name = L["Visibility"], type = "header", order = 5 },

                    hideOutOfCombat = {
                        name = L["Hide Out of Combat"],
                        desc = L["Hide Out of Combat Desc"],
                        type = "toggle", order = 6, width = "full",
                        get = function() return ns.db.profile.hideOutOfCombat end,
                        set = function(_, v) ns.db.profile.hideOutOfCombat = v; ns.addon:UpdateVisibility() end,
                    },
                    combatFadeDelay = {
                        name = L["Combat Fade Delay"],
                        desc = L["Combat Fade Delay Desc"],
                        type = "range", order = 7,
                        min = 0, max = 30, step = 0.5,
                        get = function() return ns.db.profile.combatFadeDelay end,
                        set = function(_, v) ns.db.profile.combatFadeDelay = v end,
                    },
                    hideInTown = {
                        name = L["Hide in Town"],
                        desc = L["Hide in Town Desc"],
                        type = "toggle", order = 8,
                        get = function() return ns.db.profile.hideInTown end,
                        set = function(_, v) ns.db.profile.hideInTown = v; ns.addon:UpdateVisibility() end,
                    },
                    hideAtFullHP = {
                        name = L["Hide at Full HP"],
                        desc = L["Hide at Full HP Desc"],
                        type = "toggle", order = 9,
                        get = function() return ns.db.profile.hideAtFullHP end,
                        set = function(_, v) ns.db.profile.hideAtFullHP = v; ns.addon:UpdateVisibility() end,
                    },

                    -- ── Test Mode ────────────────────────────────
                    hdrTest = { name = "Test Mode", type = "header", order = 10 },
                    testMode = {
                        name = "Enable Test Mode",
                        desc = "Simulates stagger going up through all tiers and back down. The bar is forced visible while active.",
                        type = "toggle",
                        order = 11,
                        width = "full",
                        get = function() return ns.db.profile.testMode end,
                        set = function(_, v)
                            ns.db.profile.testMode = v
                            if v then
                                ns.Bar:ResetTestState()
                                ns.Bar:Show()
                            else
                                ns.addon:UpdateVisibility()
                            end
                            Refresh()
                        end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 2: Bar
            --------------------------------------------------------
            bar = {
                name = L["Bar"],
                type = "group",
                order = 2,
                args = {
                    barWidth = {
                        name = L["Bar Width"],
                        type = "range", order = 1,
                        min = 50, max = 600, step = 1, bigStep = 10,
                        get = function() return ns.db.profile.barWidth end,
                        set = function(_, v) ns.db.profile.barWidth = v; Refresh() end,
                    },
                    barHeight = {
                        name = L["Bar Height"],
                        type = "range", order = 2,
                        min = 8, max = 80, step = 1,
                        get = function() return ns.db.profile.barHeight end,
                        set = function(_, v) ns.db.profile.barHeight = v; Refresh() end,
                    },
                    barTexture = {
                        name = L["Bar Texture"],
                        desc = L["Bar Texture Desc"],
                        type = "select", order = 3,
                        dialogControl = LSM and "LSM30_Statusbar" or nil,
                        values = barValues,
                        get = function() return ns.db.profile.barTexture end,
                        set = function(_, v) ns.db.profile.barTexture = v; Refresh() end,
                    },
                    bgOpacity = {
                        name = L["Background Opacity"],
                        type = "range", order = 4,
                        min = 0, max = 1, step = 0.05, isPercent = true,
                        get = function() return ns.db.profile.bgOpacity end,
                        set = function(_, v) ns.db.profile.bgOpacity = v; Refresh() end,
                    },
                    barOrientation = {
                        name = L["Orientation"],
                        desc = L["Orientation Desc"],
                        type = "select", order = 5,
                        values = ORIENTATION_VALUES,
                        get = function() return ns.db.profile.barOrientation end,
                        set = function(_, v) ns.db.profile.barOrientation = v; Refresh() end,
                    },

                    -- ── Bar Scale ────────────────────────────────
                    hdrScale = { name = "Bar Scale", type = "header", order = 6 },

                    barMaxPct = {
                        name = "Bar Maximum",
                        desc = "Maximum stagger the bar represents. 1 = 100% max HP. 10 = 1000% max HP (Stagger Limit). At 100% stagger the bar shows 10% fill.",
                        type = "range", order = 7,
                        min = 1, max = 10, step = 1,
                        get = function() return ns.db.profile.barMaxPct end,
                        set = function(_, v) ns.db.profile.barMaxPct = v end,
                    },
                    barOverflowWrap = {
                        name = "Overflow Wrap",
                        desc = "When stagger exceeds the bar maximum: OFF = bar stays full (clamped), ON = bar refills from zero cyclically.",
                        type = "toggle", order = 8, width = "full",
                        get = function() return ns.db.profile.barOverflowWrap end,
                        set = function(_, v) ns.db.profile.barOverflowWrap = v end,
                    },

                    -- ── Border ───────────────────────────────────
                    hdrBorder = { name = L["Border"], type = "header", order = 10 },

                    borderTexture = {
                        name = L["Border Texture"],
                        desc = L["Border Texture Desc"],
                        type = "select", order = 11,
                        dialogControl = LSM and "LSM30_Border" or nil,
                        values = borderValues,
                        get = function() return ns.db.profile.borderTexture end,
                        set = function(_, v) ns.db.profile.borderTexture = v; Refresh() end,
                    },
                    borderSize = {
                        name = L["Border Size"],
                        desc = L["Border Size Desc"],
                        type = "range", order = 12,
                        min = 1, max = 32, step = 1,
                        get = function() return ns.db.profile.borderSize end,
                        set = function(_, v) ns.db.profile.borderSize = v; Refresh() end,
                    },
                    borderColor = {
                        name = L["Border Color"],
                        type = "color", order = 13, hasAlpha = true,
                        get = function() local c = ns.db.profile.borderColor; return c[1],c[2],c[3],c[4] end,
                        set = function(_,r,g,b,a) ns.db.profile.borderColor = {r,g,b,a}; Refresh() end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 3: Colors
            --------------------------------------------------------
            colors = {
                name = L["Colors"],
                type = "group",
                order = 3,
                args = {
                    colorLight = {
                        name = L["Light Stagger"],
                        type = "color", order = 1, hasAlpha = true,
                        get = function() local c = ns.db.profile.colorLight; return c[1],c[2],c[3],c[4] end,
                        set = function(_,r,g,b,a) ns.db.profile.colorLight = {r,g,b,a}; Refresh() end,
                    },
                    colorModerate = {
                        name = L["Moderate Stagger"],
                        type = "color", order = 2, hasAlpha = true,
                        get = function() local c = ns.db.profile.colorModerate; return c[1],c[2],c[3],c[4] end,
                        set = function(_,r,g,b,a) ns.db.profile.colorModerate = {r,g,b,a}; Refresh() end,
                    },
                    colorHeavy = {
                        name = L["Heavy Stagger"],
                        type = "color", order = 3, hasAlpha = true,
                        get = function() local c = ns.db.profile.colorHeavy; return c[1],c[2],c[3],c[4] end,
                        set = function(_,r,g,b,a) ns.db.profile.colorHeavy = {r,g,b,a}; Refresh() end,
                    },
                    colorExtreme = {
                        name = L["Extreme Stagger"],
                        type = "color", order = 4, hasAlpha = true,
                        get = function() local c = ns.db.profile.colorExtreme; return c[1],c[2],c[3],c[4] end,
                        set = function(_,r,g,b,a) ns.db.profile.colorExtreme = {r,g,b,a}; Refresh() end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 4: Glow
            --------------------------------------------------------
            glow = {
                name = "Glow",
                type = "group",
                order = 4,
                args = {
                    glowEnabled = {
                        name = "Enable Glow",
                        desc = "Glow around the bar when a stagger tier is reached.",
                        type = "toggle", order = 1, width = "full",
                        get = function() return ns.db.profile.glowEnabled end,
                        set = function(_, v)
                            ns.db.profile.glowEnabled = v
                            if not v then ns.Bar:StopGlow() end
                            Refresh()
                        end,
                    },
                    glowTier = {
                        name = "Trigger Tier",
                        desc = "Minimum stagger tier to activate glow.",
                        type = "select", order = 2,
                        values = TIER_VALUES,
                        get = function() return ns.db.profile.glowTier end,
                        set = function(_, v)
                            ns.db.profile.glowTier = v
                            ns.Bar:StopGlow()
                        end,
                    },
                    glowType = {
                        name = "Glow Type",
                        desc = "Visual style of the glow effect.",
                        type = "select", order = 3,
                        values = {
                            Pixel    = "Pixel (rotating lines)",
                            AutoCast = "AutoCast (orbiting particles)",
                            Button   = "Button (classic action glow)",
                            Proc     = "Proc (spell proc glow)",
                        },
                        get = function() return ns.db.profile.glowType end,
                        set = function(_, v)
                            ns.Bar:StopGlow()
                            ns.db.profile.glowType = v
                            Refresh()
                        end,
                    },
                    glowColor = {
                        name = "Glow Color",
                        type = "color", order = 4, hasAlpha = true,
                        get = function()
                            local c = ns.db.profile.glowColor
                            return c[1], c[2], c[3], c[4]
                        end,
                        set = function(_, r, g, b, a)
                            ns.db.profile.glowColor = { r, g, b, a }
                            ns.Bar:StopGlow()
                            Refresh()
                        end,
                    },

                    -- ── Position (all types) ─────────────────────
                    hdrPos = { name = "Position", type = "header", order = 5 },
                    glowXOffset = {
                        name = "X Offset",
                        desc = "Horizontal offset of the glow effect.",
                        type = "range", order = 6,
                        min = -50, max = 50, step = 1,
                        get = function() return ns.db.profile.glowXOffset end,
                        set = function(_, v) ns.db.profile.glowXOffset = v; ns.Bar:StopGlow() end,
                    },
                    glowYOffset = {
                        name = "Y Offset",
                        desc = "Vertical offset of the glow effect.",
                        type = "range", order = 7,
                        min = -50, max = 50, step = 1,
                        get = function() return ns.db.profile.glowYOffset end,
                        set = function(_, v) ns.db.profile.glowYOffset = v; ns.Bar:StopGlow() end,
                    },

                    -- ── Pixel params ─────────────────────────────
                    hdrPixel = {
                        name = "Pixel Glow Settings",
                        type = "header", order = 10,
                        hidden = function() return ns.db.profile.glowType ~= "Pixel" end,
                    },
                    glowPixelLines = {
                        name = "Lines",
                        desc = "Number of rotating lines.",
                        type = "range", order = 11,
                        min = 1, max = 30, step = 1,
                        hidden = function() return ns.db.profile.glowType ~= "Pixel" end,
                        get = function() return ns.db.profile.glowPixelLines end,
                        set = function(_, v) ns.db.profile.glowPixelLines = v; ns.Bar:StopGlow() end,
                    },
                    glowPixelFrequency = {
                        name = "Frequency",
                        desc = "Rotation speed. Negative inverts direction.",
                        type = "range", order = 12,
                        min = -1, max = 1, step = 0.025, softMin = -0.5, softMax = 0.5,
                        hidden = function() return ns.db.profile.glowType ~= "Pixel" end,
                        get = function() return ns.db.profile.glowPixelFrequency end,
                        set = function(_, v) ns.db.profile.glowPixelFrequency = v; ns.Bar:StopGlow() end,
                    },
                    glowPixelThickness = {
                        name = "Thickness",
                        desc = "Thickness of the lines.",
                        type = "range", order = 13,
                        min = 1, max = 10, step = 0.5,
                        hidden = function() return ns.db.profile.glowType ~= "Pixel" end,
                        get = function() return ns.db.profile.glowPixelThickness end,
                        set = function(_, v) ns.db.profile.glowPixelThickness = v; ns.Bar:StopGlow() end,
                    },
                    glowPixelBorder = {
                        name = "Border Mode",
                        desc = "Draw glow inside the border instead of outside.",
                        type = "toggle", order = 14,
                        hidden = function() return ns.db.profile.glowType ~= "Pixel" end,
                        get = function() return ns.db.profile.glowPixelBorder end,
                        set = function(_, v) ns.db.profile.glowPixelBorder = v; ns.Bar:StopGlow() end,
                    },

                    -- ── AutoCast params ──────────────────────────
                    hdrAC = {
                        name = "AutoCast Glow Settings",
                        type = "header", order = 20,
                        hidden = function() return ns.db.profile.glowType ~= "AutoCast" end,
                    },
                    glowACParticles = {
                        name = "Particle Groups",
                        desc = "Number of orbiting particle groups.",
                        type = "range", order = 21,
                        min = 1, max = 20, step = 1,
                        hidden = function() return ns.db.profile.glowType ~= "AutoCast" end,
                        get = function() return ns.db.profile.glowACParticles end,
                        set = function(_, v) ns.db.profile.glowACParticles = v; ns.Bar:StopGlow() end,
                    },
                    glowACFrequency = {
                        name = "Frequency",
                        desc = "Orbit speed. Negative inverts direction.",
                        type = "range", order = 22,
                        min = -1, max = 1, step = 0.025, softMin = -0.5, softMax = 0.5,
                        hidden = function() return ns.db.profile.glowType ~= "AutoCast" end,
                        get = function() return ns.db.profile.glowACFrequency end,
                        set = function(_, v) ns.db.profile.glowACFrequency = v; ns.Bar:StopGlow() end,
                    },
                    glowACScale = {
                        name = "Scale",
                        desc = "Size of the particles.",
                        type = "range", order = 23,
                        min = 0.5, max = 3, step = 0.1,
                        hidden = function() return ns.db.profile.glowType ~= "AutoCast" end,
                        get = function() return ns.db.profile.glowACScale end,
                        set = function(_, v) ns.db.profile.glowACScale = v; ns.Bar:StopGlow() end,
                    },

                    -- ── Button params ────────────────────────────
                    hdrButton = {
                        name = "Button Glow Settings",
                        type = "header", order = 30,
                        hidden = function() return ns.db.profile.glowType ~= "Button" end,
                    },
                    glowButtonFrequency = {
                        name = "Frequency",
                        desc = "Animation speed of the button glow.",
                        type = "range", order = 31,
                        min = 0.01, max = 2, step = 0.01,
                        hidden = function() return ns.db.profile.glowType ~= "Button" end,
                        get = function() return ns.db.profile.glowButtonFrequency end,
                        set = function(_, v) ns.db.profile.glowButtonFrequency = v; ns.Bar:StopGlow() end,
                    },

                    -- ── Proc params ──────────────────────────────
                    hdrProc = {
                        name = "Proc Glow Settings",
                        type = "header", order = 40,
                        hidden = function() return ns.db.profile.glowType ~= "Proc" end,
                    },
                    glowProcDuration = {
                        name = "Duration",
                        desc = "Duration of the proc animation cycle.",
                        type = "range", order = 41,
                        min = 0.1, max = 5, step = 0.1,
                        hidden = function() return ns.db.profile.glowType ~= "Proc" end,
                        get = function() return ns.db.profile.glowProcDuration end,
                        set = function(_, v) ns.db.profile.glowProcDuration = v; ns.Bar:StopGlow() end,
                    },
                    glowProcStartAnim = {
                        name = "Start Animation",
                        desc = "Play the intro animation when glow activates.",
                        type = "toggle", order = 42,
                        hidden = function() return ns.db.profile.glowType ~= "Proc" end,
                        get = function() return ns.db.profile.glowProcStartAnim end,
                        set = function(_, v) ns.db.profile.glowProcStartAnim = v; ns.Bar:StopGlow() end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 5: Text
            --------------------------------------------------------
            text = {
                name = L["Text"],
                type = "group",
                order = 5,
                args = {
                    -- ── Global Font ──────────────────────────────
                    hdrFont = { name = "Global Font (fallback)", type = "header", order = 0 },

                    fontFace = {
                        name = L["Font Face"],
                        desc = L["Font Face Desc"],
                        type = "select", order = 1,
                        dialogControl = LSM and "LSM30_Font" or nil,
                        values = fontValues,
                        get = function() return ns.db.profile.fontFace end,
                        set = function(_, v) ns.db.profile.fontFace = v; Refresh() end,
                    },
                    fontSize = {
                        name = L["Font Size"],
                        type = "range", order = 2,
                        min = 6, max = 32, step = 1,
                        get = function() return ns.db.profile.fontSize end,
                        set = function(_, v) ns.db.profile.fontSize = v; Refresh() end,
                    },
                    fontOutline = {
                        name = L["Font Outline"],
                        desc = L["Font Outline Desc"],
                        type = "select", order = 3,
                        values = OUTLINE_VALUES,
                        get = function() return ns.db.profile.fontOutline end,
                        set = function(_, v) ns.db.profile.fontOutline = v; Refresh() end,
                    },

                    -- ── Label text ───────────────────────────────
                    hdrLabel = { name = "Label (left text)", type = "header", order = 10 },

                    labelTemplate = {
                        name = "Label Template",
                        desc = TEMPLATE_FLAGS_DESC,
                        type = "input", order = 11, width = "double",
                        get = function() return ns.db.profile.labelTemplate end,
                        set = function(_, v) ns.db.profile.labelTemplate = v; Refresh() end,
                    },
                    pctTemplate = {
                        name = "Percent Template",
                        desc = TEMPLATE_FLAGS_DESC,
                        type = "input", order = 12, width = "double",
                        get = function() return ns.db.profile.pctTemplate end,
                        set = function(_, v) ns.db.profile.pctTemplate = v; Refresh() end,
                    },
                    labelAnchor = {
                        name = L["Anchor Point"],
                        desc = L["Anchor Point Desc"],
                        type = "select", order = 13,
                        values = ANCHOR_VALUES,
                        get = function() return ns.db.profile.labelAnchor end,
                        set = function(_, v) ns.db.profile.labelAnchor = v; Refresh() end,
                    },
                    labelXOfs = {
                        name = L["Text X Offset"],
                        type = "range", order = 14,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.labelXOfs end,
                        set = function(_, v) ns.db.profile.labelXOfs = v; Refresh() end,
                    },
                    labelYOfs = {
                        name = L["Text Y Offset"],
                        type = "range", order = 15,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.labelYOfs end,
                        set = function(_, v) ns.db.profile.labelYOfs = v; Refresh() end,
                    },
                    labelFontFace = {
                        name = L["Label Font Face"],
                        desc = "Override global font for label. Leave empty to use global.",
                        type = "select", order = 16,
                        dialogControl = LSM and "LSM30_Font" or nil,
                        values = fontValues,
                        get = function() return ns.db.profile.labelFontFace or ns.db.profile.fontFace end,
                        set = function(_, v)
                            ns.db.profile.labelFontFace = (v ~= ns.db.profile.fontFace) and v or nil
                            Refresh()
                        end,
                    },
                    labelFontSize = {
                        name = L["Label Font Size"],
                        type = "range", order = 17,
                        min = 6, max = 32, step = 1,
                        get = function() return ns.db.profile.labelFontSize or ns.db.profile.fontSize end,
                        set = function(_, v)
                            ns.db.profile.labelFontSize = (v ~= ns.db.profile.fontSize) and v or nil
                            Refresh()
                        end,
                    },
                    labelFontOutline = {
                        name = L["Label Font Outline"],
                        type = "select", order = 18,
                        values = OUTLINE_VALUES,
                        get = function() return ns.db.profile.labelFontOutline or ns.db.profile.fontOutline end,
                        set = function(_, v)
                            ns.db.profile.labelFontOutline = (v ~= ns.db.profile.fontOutline) and v or nil
                            Refresh()
                        end,
                    },

                    -- ── Percentage text ──────────────────────────
                    hdrPct = { name = "Percentage text", type = "header", order = 20 },

                    showPercentage = {
                        name = L["Show Percentage"],
                        desc = L["Show Percentage Desc"],
                        type = "toggle", order = 21,
                        get = function() return ns.db.profile.showPercentage end,
                        set = function(_, v) ns.db.profile.showPercentage = v; Refresh() end,
                    },
                    pctAnchor = {
                        name = L["Anchor Point"],
                        type = "select", order = 22,
                        values = ANCHOR_VALUES,
                        get = function() return ns.db.profile.pctAnchor end,
                        set = function(_, v) ns.db.profile.pctAnchor = v; Refresh() end,
                    },
                    pctXOfs = {
                        name = L["Text X Offset"],
                        type = "range", order = 23,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.pctXOfs end,
                        set = function(_, v) ns.db.profile.pctXOfs = v; Refresh() end,
                    },
                    pctYOfs = {
                        name = L["Text Y Offset"],
                        type = "range", order = 24,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.pctYOfs end,
                        set = function(_, v) ns.db.profile.pctYOfs = v; Refresh() end,
                    },
                    pctFontFace = {
                        name = L["Pct Font Face"],
                        type = "select", order = 25,
                        dialogControl = LSM and "LSM30_Font" or nil,
                        values = fontValues,
                        get = function() return ns.db.profile.pctFontFace or ns.db.profile.fontFace end,
                        set = function(_, v)
                            ns.db.profile.pctFontFace = (v ~= ns.db.profile.fontFace) and v or nil
                            Refresh()
                        end,
                    },
                    pctFontSize = {
                        name = L["Pct Font Size"],
                        type = "range", order = 26,
                        min = 6, max = 32, step = 1,
                        get = function() return ns.db.profile.pctFontSize or ns.db.profile.fontSize end,
                        set = function(_, v)
                            ns.db.profile.pctFontSize = (v ~= ns.db.profile.fontSize) and v or nil
                            Refresh()
                        end,
                    },
                    pctFontOutline = {
                        name = L["Pct Font Outline"],
                        type = "select", order = 27,
                        values = OUTLINE_VALUES,
                        get = function() return ns.db.profile.pctFontOutline or ns.db.profile.fontOutline end,
                        set = function(_, v)
                            ns.db.profile.pctFontOutline = (v ~= ns.db.profile.fontOutline) and v or nil
                            Refresh()
                        end,
                    },

                    -- ── Number format ────────────────────────────
                    hdrNum = { name = "Number Formatting", type = "header", order = 30 },

                    numberFormat = {
                        name = L["Number Format"],
                        desc = L["Number Format Desc"],
                        type = "select", order = 31,
                        values = NUMBER_FORMAT_VALUES,
                        get = function() return ns.db.profile.numberFormat end,
                        set = function(_, v) ns.db.profile.numberFormat = v end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 6: Tick Display
            --------------------------------------------------------
            ticks = {
                name = L["Tick Display"],
                type = "group",
                order = 6,
                args = {
                    showTick = {
                        name = L["Show Tick Text"],
                        desc = L["Show Tick Text Desc"],
                        type = "toggle", order = 1, width = "full",
                        get = function() return ns.db.profile.showTick end,
                        set = function(_, v) ns.db.profile.showTick = v; Refresh() end,
                    },
                    tickTemplate = {
                        name = L["Tick Template"],
                        desc = TEMPLATE_FLAGS_DESC,
                        type = "input", order = 2, width = "double",
                        get = function() return ns.db.profile.tickTemplate end,
                        set = function(_, v) ns.db.profile.tickTemplate = v; Refresh() end,
                    },
                    tickFontSize = {
                        name = L["Tick Font Size"],
                        type = "range", order = 3,
                        min = 6, max = 24, step = 1,
                        get = function() return ns.db.profile.tickFontSize end,
                        set = function(_, v) ns.db.profile.tickFontSize = v; Refresh() end,
                    },
                    tickAnchor = {
                        name = L["Tick Anchor"],
                        desc = L["Tick Anchor Desc"],
                        type = "select", order = 4,
                        values = ANCHOR_VALUES,
                        get = function() return ns.db.profile.tickAnchor end,
                        set = function(_, v) ns.db.profile.tickAnchor = v; Refresh() end,
                    },
                    tickXOfs = {
                        name = L["Text X Offset"],
                        type = "range", order = 5,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.tickXOfs end,
                        set = function(_, v) ns.db.profile.tickXOfs = v; Refresh() end,
                    },
                    tickYOfs = {
                        name = L["Text Y Offset"],
                        type = "range", order = 6,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.tickYOfs end,
                        set = function(_, v) ns.db.profile.tickYOfs = v; Refresh() end,
                    },
                    tickFontFace = {
                        name = L["Tick Font Face"],
                        type = "select", order = 7,
                        dialogControl = LSM and "LSM30_Font" or nil,
                        values = fontValues,
                        get = function() return ns.db.profile.tickFontFace or ns.db.profile.fontFace end,
                        set = function(_, v)
                            ns.db.profile.tickFontFace = (v ~= ns.db.profile.fontFace) and v or nil
                            Refresh()
                        end,
                    },
                    tickFontOutline = {
                        name = L["Tick Font Outline"],
                        type = "select", order = 8,
                        values = OUTLINE_VALUES,
                        get = function() return ns.db.profile.tickFontOutline or ns.db.profile.fontOutline end,
                        set = function(_, v)
                            ns.db.profile.tickFontOutline = (v ~= ns.db.profile.fontOutline) and v or nil
                            Refresh()
                        end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 7: Alerts
            --------------------------------------------------------
            alerts = {
                name = L["Sound"],
                type = "group",
                order = 7,
                args = {
                    -- ── Sound ────────────────────────────────────
                    hdrSound = { name = L["Sound"], type = "header", order = 1 },
                    soundEnabled = {
                        name = L["Enable Sound"],
                        desc = L["Enable Sound Desc"],
                        type = "toggle", order = 2, width = "full",
                        get = function() return ns.db.profile.soundEnabled end,
                        set = function(_, v) ns.db.profile.soundEnabled = v end,
                    },
                    soundTier = {
                        name = L["Sound Tier"],
                        desc = L["Sound Tier Desc"],
                        type = "select", order = 3,
                        values = TIER_VALUES,
                        get = function() return ns.db.profile.soundTier end,
                        set = function(_, v) ns.db.profile.soundTier = v end,
                    },
                    soundFile = {
                        name = L["Sound File"],
                        desc = L["Sound File Desc"],
                        type = "select", order = 4,
                        dialogControl = LSM and "LSM30_Sound" or nil,
                        values = soundValues,
                        get = function() return ns.db.profile.soundFile end,
                        set = function(_, v) ns.db.profile.soundFile = v end,
                    },
                    soundCooldown = {
                        name = L["Sound Cooldown"],
                        desc = L["Sound Cooldown Desc"],
                        type = "range", order = 5,
                        min = 1, max = 60, step = 1,
                        get = function() return ns.db.profile.soundCooldown end,
                        set = function(_, v) ns.db.profile.soundCooldown = v end,
                    },

                    -- ── Chat Log ─────────────────────────────────
                    hdrLog = { name = L["Chat Log"], type = "header", order = 10 },
                    chatLogEnabled = {
                        name = L["Enable Chat Log"],
                        desc = L["Enable Chat Log Desc"],
                        type = "toggle", order = 11, width = "full",
                        get = function() return ns.db.profile.chatLogEnabled end,
                        set = function(_, v) ns.db.profile.chatLogEnabled = v end,
                    },
                    chatLogTier = {
                        name = L["Chat Log Tier"],
                        desc = L["Chat Log Tier Desc"],
                        type = "select", order = 12,
                        values = TIER_VALUES,
                        get = function() return ns.db.profile.chatLogTier end,
                        set = function(_, v) ns.db.profile.chatLogTier = v end,
                    },

                    -- ── LibSink output routing ───────────────────
                    hdrOutput = { name = "Alert Output", type = "header", order = 20 },
                },
            },

            --------------------------------------------------------
            -- TAB 8: Sparkline
            --------------------------------------------------------
            sparkline = {
                name = L["Sparkline"],
                type = "group",
                order = 8,
                args = {
                    sparklineEnabled = {
                        name = L["Enable Sparkline"],
                        desc = L["Enable Sparkline Desc"],
                        type = "toggle", order = 1, width = "full",
                        get = function() return ns.db.profile.sparklineEnabled end,
                        set = function(_, v) ns.db.profile.sparklineEnabled = v; Refresh() end,
                    },
                    sparklineHeight = {
                        name = L["Sparkline Height"],
                        desc = L["Sparkline Height Desc"],
                        type = "range", order = 2,
                        min = 4, max = 50, step = 1,
                        get = function() return ns.db.profile.sparklineHeight end,
                        set = function(_, v) ns.db.profile.sparklineHeight = v; Refresh() end,
                    },
                    sparklineSamples = {
                        name = L["Sparkline Samples"],
                        desc = L["Sparkline Samples Desc"],
                        type = "range", order = 3,
                        min = 10, max = 120, step = 5,
                        get = function() return ns.db.profile.sparklineSamples end,
                        set = function(_, v) ns.db.profile.sparklineSamples = v end,
                    },
                    sparklineColor = {
                        name = L["Sparkline Color"],
                        type = "color", order = 4, hasAlpha = true,
                        get = function() local c = ns.db.profile.sparklineColor; return c[1],c[2],c[3],c[4] end,
                        set = function(_,r,g,b,a) ns.db.profile.sparklineColor = {r,g,b,a} end,
                    },
                    sparklineYOfs = {
                        name = L["Text Y Offset"],
                        desc = "Vertical offset of the sparkline relative to the bar bottom.",
                        type = "range", order = 5,
                        min = -50, max = 50, step = 1,
                        get = function() return ns.db.profile.sparklineYOfs end,
                        set = function(_, v) ns.db.profile.sparklineYOfs = v end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 9: Import / Export
            --------------------------------------------------------
            importexport = {
                name = "Import / Export",
                type = "group",
                order = 9,
                args = {
                    desc = {
                        name = "Use /bsb export to generate a profile string, or /bsb import <string> to import one.\nYou can also paste an import string below.",
                        type = "description", order = 1, fontSize = "medium",
                    },
                    exportBtn = {
                        name = "Export Profile",
                        desc = "Opens a window with the export string.",
                        type = "execute", order = 2, width = "full",
                        func = function() ns.addon:ExportProfile() end,
                    },
                    importStr = {
                        name = "Import String",
                        desc = "Paste an export string here and press Enter.",
                        type = "input", order = 3, width = "full", multiline = 4,
                        get = function() return "" end,
                        set = function(_, v)
                            if v and v ~= "" then ns.addon:ImportProfile(v) end
                        end,
                    },
                },
            },

            -- Profiles tab is injected by GUI.lua via AceDBOptions
        },
    }

    -- Inject LibSink output options into alerts tab
    local addon = ns.addon
    if addon and addon.GetSinkAce3OptionsDataTable then
        local sinkOpts = addon:GetSinkAce3OptionsDataTable()
        sinkOpts.order = 21
        sinkOpts.inline = true
        sinkOpts.name = "Alert Output Destination"
        options.args.alerts.args.sinkOutput = sinkOpts
    end

    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    ns.options = options
end