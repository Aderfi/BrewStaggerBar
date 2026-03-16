------------------------------------------------------------------------
-- BrewStaggerBar · GUI.lua
-- AceConfigDialog integration, profile tab injection, minimap button
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local L   = ns.L
local Bar = ns.Bar

------------------------------------------------------------------------
-- Inject AceDBOptions Profiles tab
------------------------------------------------------------------------
local function InjectProfilesTab()
    local AceDBOptions = LibStub("AceDBOptions-3.0", true)
    if not AceDBOptions or not ns.options or not ns.db then return end

    ns.options.args.profiles = AceDBOptions:GetOptionsTable(ns.db)
    ns.options.args.profiles.order = 99

    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON_NAME, ns.options)
end

------------------------------------------------------------------------
-- Register dialog panels in Blizzard Settings
------------------------------------------------------------------------
local function RegisterDialogPanel()
    local ACD = LibStub("AceConfigDialog-3.0", true)
    if not ACD then return end

    ACD:AddToBlizOptions(ADDON_NAME, "|cff00ccffStaggerBar|r")

    local tabs = {
        { key = "general", name = L["General"] },
        { key = "bar",     name = L["Bar"] },
        { key = "colors",  name = L["Colors"] },
        { key = "text",    name = L["Text"] },
        { key = "ticks",   name = L["Tick Display"] },
    }
    for _, t in ipairs(tabs) do
        ACD:AddToBlizOptions(ADDON_NAME, t.name, "|cff00ccffStaggerBar|r", t.key)
    end

    if ns.options.args.profiles then
        ACD:AddToBlizOptions(ADDON_NAME, "Profiles", "|cff00ccffStaggerBar|r", "profiles")
    end
end

------------------------------------------------------------------------
-- Open standalone floating config
------------------------------------------------------------------------
function ns:OpenConfig()
    local ACD = LibStub("AceConfigDialog-3.0", true)
    if ACD then ACD:Open(ADDON_NAME) end
end

------------------------------------------------------------------------
-- Optional minimap button (only if LibDataBroker / LibDBIcon present)
------------------------------------------------------------------------
local function SetupMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    if not LDB then return end

    local dataObj = LDB:NewDataObject(ADDON_NAME, {
        type  = "launcher",
        icon  = "Interface\\Icons\\monk_stance_drunkenox",
        label = "StaggerBar",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if Bar:IsShown() then Bar:Hide() else Bar:Show() end
            elseif button == "RightButton" then
                ns:OpenConfig()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cff00ccffStaggerBar|r")
            tt:AddLine("Left-click: Toggle  |  Right-click: Options", 0.7, 0.7, 0.7)
        end,
    })

    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if LDBIcon then LDBIcon:Register(ADDON_NAME, dataObj, ns.db and ns.db.profile) end
end

------------------------------------------------------------------------
-- Deferred init — runs after PLAYER_LOGIN so db + options exist
------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(0, function()
        if ns.db and ns.options then
            InjectProfilesTab()
            RegisterDialogPanel()
            SetupMinimapButton()
        end
    end)
end)
