------------------------------------------------------------------------
-- StaggerBar · Modules/Options.lua
-- AceConfig-3.0 options table definition
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local L   = ns.L
local Bar = ns.Bar

------------------------------------------------------------------------
-- Shared dropdown values
------------------------------------------------------------------------
local ANCHOR_VALUES = {
    LEFT = "Left", RIGHT = "Right", CENTER = "Center",
    TOP = "Top", BOTTOM = "Bottom",
    TOPLEFT = "Top Left", TOPRIGHT = "Top Right",
    BOTTOMLEFT = "Bottom Left", BOTTOMRIGHT = "Bottom Right",
}

local OUTLINE_VALUES = {
    [""]              = "None",
    ["OUTLINE"]       = "Outline",
    ["THICKOUTLINE"]  = "Thick Outline",
    ["MONOCHROME"]    = "Monochrome",
}

local NUMBER_FORMAT_VALUES = {
    [1] = "Raw (1.234.567)",
    [2] = "k / m  (1.2k, 4.20m)",
    [3] = "mil / M  (1.2mil, 4.20M)",
    [4] = "K / M short  (1.2K, 4M)",
}

local function Refresh()
    if Bar and Bar.frame then Bar:ApplySettings() end
end

------------------------------------------------------------------------
-- Build and register options
------------------------------------------------------------------------
function ns.BuildOptions()
    local LSM = LibStub("LibSharedMedia-3.0", true)

    local options = {
        name = "|cff00ccffStaggerBar|r",
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
                            if Bar.frame then Bar.frame.throttle = v * (1/60) end
                        end,
                    },
                    spacer = { name = "", type = "description", order = 9 },
                    hdrTest = {
                        name = "Test Mode",
                        type = "header",
                        order = 10,
                    },
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
                        values = LSM and LSM:HashTable("statusbar") or { ["Blizzard"] = "Blizzard" },
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
            -- TAB: Glow
            --------------------------------------------------------
            glow = {
                name = "Glow",
                type = "group",
                order = 3.5,
                args = {
                    glowEnabled = {
                        name = "Enable Glow",
                        desc = "Glow around the bar when a stagger tier is reached.",
                        type = "toggle", order = 1, width = "full",
                        get = function() return ns.db.profile.glowEnabled end,
                        set = function(_, v)
                            ns.db.profile.glowEnabled = v
                            if not v and ns.Bar.frame then
                                ns.Bar.frame.glowActive = false
                                local LCG = LibStub("LibCustomGlow-1.0", true)
                                if LCG then
                                    LCG.PixelGlow_Stop(ns.Bar.frame, "StaggerBarGlow")
                                    LCG.AutoCastGlow_Stop(ns.Bar.frame, "StaggerBarGlow")
                                    LCG.ButtonGlow_Stop(ns.Bar.frame)
                                    LCG.ProcGlow_Stop(ns.Bar.frame, "StaggerBarGlow")
                                end
                            end
                            Refresh()
                        end,
                    },
                    glowTier = {
                        name = "Trigger Tier",
                        desc = "Minimum stagger tier to activate glow.",
                        type = "select", order = 2,
                        values = {
                            [1] = "Light (0-30%)",
                            [2] = "Moderate (30-60%)",
                            [3] = "Heavy (60-100%)",
                            [4] = "Extreme (>100%)",
                        },
                        get = function() return ns.db.profile.glowTier end,
                        set = function(_, v) ns.db.profile.glowTier = v; Refresh() end,
                    },
                    glowType = {
                        name = "Glow Type",
                        desc = "Visual style of the glow effect.",
                        type = "select", order = 3,
                        values = {
                            Pixel    = "Pixel (rotating lines)",
                            AutoCast = "AutoCast (orbiting particles)",
                            --Button   = "Button (classic action glow)",
                            --Proc     = "Proc (spell proc glow)",
                        },
                        get = function() return ns.db.profile.glowType end,
                        set = function(_, v)
                            -- Stop current glow before switching type
                            if ns.Bar.frame and ns.Bar.frame.glowActive then
                                ns.Bar.frame.glowActive = false
                                local LCG = LibStub("LibCustomGlow-1.0", true)
                                if LCG then
                                    LCG.PixelGlow_Stop(ns.Bar.frame, "StaggerBarGlow")
                                    LCG.AutoCastGlow_Stop(ns.Bar.frame, "StaggerBarGlow")
                                    LCG.ButtonGlow_Stop(ns.Bar.frame)
                                    LCG.ProcGlow_Stop(ns.Bar.frame, "StaggerBarGlow")
                                end
                            end
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
                            if ns.Bar.frame then ns.Bar.frame.glowActive = false end
                            Refresh()
                        end,
                    },
                    hdrParams = { name = "Glow Parameters", type = "header", order = 10 },
                    glowLines = {
                        name = "Lines / Particles",
                        desc = "Number of lines (Pixel) or particle groups (AutoCast).",
                        type = "range", order = 11,
                        min = 1, max = 20, step = 1,
                        get = function() return ns.db.profile.glowLines end,
                        set = function(_, v)
                            ns.db.profile.glowLines = v
                            if ns.Bar.frame then ns.Bar.frame.glowActive = false end
                        end,
                    },
                    glowFrequency = {
                        name = "Frequency",
                        desc = "Speed of rotation/animation. Negative inverts direction.",
                        type = "range", order = 12,
                        min = -1, max = 1, step = 0.025, softMin = -0.5, softMax = 0.5,
                        get = function() return ns.db.profile.glowFrequency end,
                        set = function(_, v)
                            ns.db.profile.glowFrequency = v
                            if ns.Bar.frame then ns.Bar.frame.glowActive = false end
                        end,
                    },
                    glowThickness = {
                        name = "Thickness (Pixel)",
                        desc = "Thickness of pixel glow lines.",
                        type = "range", order = 13,
                        min = 1, max = 10, step = 0.5,
                        get = function() return ns.db.profile.glowThickness end,
                        set = function(_, v)
                            ns.db.profile.glowThickness = v
                            if ns.Bar.frame then ns.Bar.frame.glowActive = false end
                        end,
                    },
                    glowScale = {
                        name = "Scale (AutoCast)",
                        desc = "Scale of AutoCast particles.",
                        type = "range", order = 14,
                        min = 0.5, max = 3, step = 0.1,
                        get = function() return ns.db.profile.glowScale end,
                        set = function(_, v)
                            ns.db.profile.glowScale = v
                            if ns.Bar.frame then ns.Bar.frame.glowActive = false end
                        end,
                    },
                },
            },

            --------------------------------------------------------
            -- TAB 4: Text
            --------------------------------------------------------
            text = {
                name = L["Text"],
                type = "group",
                order = 4,
                args = {
                    -- ── Font globals ─────────────────────────────
                    hdrFont = { name = "Font Settings", type = "header", order = 0 },

                    fontFace = {
                        name = L["Font Face"],
                        desc = L["Font Face Desc"],
                        type = "select", order = 1,
                        dialogControl = LSM and "LSM30_Font" or nil,
                        values = LSM and LSM:HashTable("font") or { ["Friz Quadrata TT"] = "Friz Quadrata TT" },
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
                        desc = "Flags: %n=name, %s=stagger, %r=raw, %p=percent, %t=tick, %d=dps, %tp=tick%HP, %m=maxHP",
                        type = "input", order = 11, width = "double",
                        get = function() return ns.db.profile.labelTemplate end,
                        set = function(_, v) ns.db.profile.labelTemplate = v; Refresh() end,
                    },
                    pctTemplate = {
                        name = "Percent Template",
                        desc = "Flags: %n=name, %s=stagger, %r=raw, %p=percent, %t=tick, %d=dps, %tp=tick%HP, %m=maxHP",
                        type = "input", order = 12, width = "double",
                        get = function() return ns.db.profile.pctTemplate end,
                        set = function(_, v) ns.db.profile.pctTemplate = v; Refresh() end,
                    },
                    labelAnchor = {
                        name = L["Anchor Point"],
                        desc = L["Anchor Point Desc"],
                        type = "select", order = 12,
                        values = ANCHOR_VALUES,
                        get = function() return ns.db.profile.labelAnchor end,
                        set = function(_, v) ns.db.profile.labelAnchor = v; Refresh() end,
                    },
                    labelXOfs = {
                        name = L["Text X Offset"],
                        type = "range", order = 13,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.labelXOfs end,
                        set = function(_, v) ns.db.profile.labelXOfs = v; Refresh() end,
                    },
                    labelYOfs = {
                        name = L["Text Y Offset"],
                        type = "range", order = 14,
                        min = -200, max = 200, step = 1,
                        get = function() return ns.db.profile.labelYOfs end,
                        set = function(_, v) ns.db.profile.labelYOfs = v; Refresh() end,
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
            -- TAB 5: Tick Display
            --------------------------------------------------------
            ticks = {
                name = L["Tick Display"],
                type = "group",
                order = 5,
                args = {
                    showTick = {
                        name = "Show Tick Text",
                        desc = "Show/hide the tick info text.",
                        type = "toggle", order = 1, width = "full",
                        get = function() return ns.db.profile.showTick end,
                        set = function(_, v) ns.db.profile.showTick = v; Refresh() end,
                    },
                    tickTemplate = {
                        name = "Tick Template",
                        desc = "Flags: %n=name, %s=stagger, %r=raw, %p=percent, %t=tick, %d=dps, %tp=tick%HP, %m=maxHP",
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
                },
            },

            -- Profiles tab is injected by GUI.lua via AceDBOptions
        },
    }

    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    ns.options = options
end
