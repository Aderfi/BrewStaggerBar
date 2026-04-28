------------------------------------------------------------------------
-- StaggerBar · Core/Utils.lua
-- Utility functions: safe API calls, number formatting, helpers
------------------------------------------------------------------------
local ADDON_NAME, ns = ...

ns.Utils = {}
local Utils = ns.Utils

------------------------------------------------------------------------
-- Constants (centralized)
------------------------------------------------------------------------
ns.CONST = {
    STAGGER_LIGHT      = 124273,
    STAGGER_MODERATE   = 124274,
    STAGGER_HEAVY      = 124275,
    BOB_AND_WEAVE      = 280515,
    BREWMASTER_SPEC_ID = 268,     -- Brewmaster Monk specialization ID
    BASE_TICKS         = 20,    -- 10s / 0.5s
    BAW_TICKS          = 26,    -- 13s / 0.5s (Bob and Weave)
    TICK_RATE          = 0.5,   -- seconds per tick
    PURIFY_PCT         = 0.50,  -- Purifying Brew clears 50%
    TIER_THRESHOLDS    = { 0.30, 0.60, 1.00 },  -- Light/Moderate/Heavy boundaries
}

-- Backward compat aliases
ns.STAGGER_LIGHT    = ns.CONST.STAGGER_LIGHT
ns.STAGGER_MODERATE = ns.CONST.STAGGER_MODERATE
ns.STAGGER_HEAVY    = ns.CONST.STAGGER_HEAVY

------------------------------------------------------------------------
-- Safe API wrapper — returns nil if the call errors (secret values)
------------------------------------------------------------------------
function Utils.SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

------------------------------------------------------------------------
-- Safe arithmetic — returns nil on error or NaN
------------------------------------------------------------------------
function Utils.SafeDiv(a, b)
    if not a or not b then return nil end
    local ok, result = pcall(function() return a / b end)
    if ok and result == result then return result end
    return nil
end

function Utils.SafeSub(a, b)
    if not a or not b then return nil end
    local ok, result = pcall(function() return a - b end)
    if ok and result == result then return result end
    return nil
end

------------------------------------------------------------------------
-- Number formatting
-- formatStyle: 1 = raw, 2 = k/m, 3 = mil/M, 4 = K/M short
------------------------------------------------------------------------
function Utils.FormatNumber(value, formatStyle)
    if not value then return "0" end
    formatStyle = formatStyle or 2

    -- 1: Raw — full number with dot thousand separators
    if formatStyle == 1 then
        local formatted = tostring(math.floor(value))
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
            if k == 0 then break end
        end
        return formatted
    end

    -- 2: k/m (1.3k, 4.20m)
    if formatStyle == 2 then
        if value >= 1000000 then
            return string.format("%.2fm", value / 1000000)
        elseif value >= 1000 then
            return string.format("%.1fk", value / 1000)
        end
        return tostring(math.floor(value))
    end

    -- 3: mil/M (1.3mil, 4.20M)
    if formatStyle == 3 then
        if value >= 1000000 then
            return string.format("%.2fM", value / 1000000)
        elseif value >= 1000 then
            return string.format("%.1fmil", value / 1000)
        end
        return tostring(math.floor(value))
    end

    -- 4: K/M short (1.3K, 4.2M)
    if formatStyle == 4 then
        if value >= 1000000 then
            return string.format("%.1fM", value / 1000000)
        elseif value >= 100000 then
            return string.format("%dK", math.floor(value / 1000))
        elseif value >= 1000 then
            return string.format("%.1fK", value / 1000)
        end
        return tostring(math.floor(value))
    end

    return tostring(math.floor(value))
end

------------------------------------------------------------------------
-- Get stagger tick value from debuff aura data
------------------------------------------------------------------------
function Utils.GetStaggerTickValue()
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID then
        for _, spellID in ipairs({ ns.STAGGER_LIGHT, ns.STAGGER_MODERATE, ns.STAGGER_HEAVY }) do
            local aura = Utils.SafeCall(C_UnitAuras.GetAuraDataBySpellID, "player", spellID)
            if aura and aura.points and aura.points[1] then
                local tick = Utils.SafeCall(function() return aura.points[1] end)
                if tick and tick > 0 then return tick end
            end
        end
    end

    -- Legacy fallback (pre-12.0)
    if WA_GetUnitDebuff then
        for _, spellID in ipairs({ ns.STAGGER_LIGHT, ns.STAGGER_MODERATE, ns.STAGGER_HEAVY }) do
            local data = { Utils.SafeCall(WA_GetUnitDebuff, "player", spellID) }
            if data and data[16] and data[16] > 0 then return data[16] end
        end
    end

    return 0
end

------------------------------------------------------------------------
-- Stagger tier: returns tierIndex (1-4), pct
------------------------------------------------------------------------
function Utils.GetStaggerTier(stagger, maxHP)
    local pct = Utils.SafeDiv(stagger, maxHP)
    if not pct then return 1, 0 end
    local T = ns.CONST.TIER_THRESHOLDS
    if pct < T[1] then     return 1, pct
    elseif pct < T[2] then return 2, pct
    elseif pct < T[3] then return 3, pct
    else                    return 4, pct end
end

------------------------------------------------------------------------
-- Is the player a Brewmaster Monk?
------------------------------------------------------------------------
function Utils.IsBrewing()
    local _, class = UnitClass("player")
    if class ~= "MONK" then return false end

    local specIndex = GetSpecialization()
    if not specIndex then return false end

    local specID = GetSpecializationInfo(specIndex)
    return specID == ns.CONST.BREWMASTER_SPEC_ID
end

------------------------------------------------------------------------
-- Debug print — only when ns.db.profile.debug is true
------------------------------------------------------------------------
function Utils.Debug(...)
    if not (ns.db and ns.db.profile and ns.db.profile.debug) then return end
    print("|cff00ccffBrewStaggerBar|r [debug]:", ...)
end

------------------------------------------------------------------------
-- Shared dropdown values
------------------------------------------------------------------------
ns.ANCHOR_POINTS = {
    LEFT = "Left", RIGHT = "Right", CENTER = "Center",
    TOP = "Top", BOTTOM = "Bottom",
    TOPLEFT = "Top Left", TOPRIGHT = "Top Right",
    BOTTOMLEFT = "Bottom Left", BOTTOMRIGHT = "Bottom Right",
}

ns.OUTLINE_STYLES = {
    [""]              = "None",
    ["OUTLINE"]       = "Outline",
    ["THICKOUTLINE"]  = "Thick Outline",
    ["MONOCHROME"]    = "Monochrome",
}

ns.NUMBER_FORMATS = {
    [1] = "Raw (no abbreviation)",
    [2] = "Abbreviated (k/m)",
    [3] = "Abbreviated (mil/M)",
    [4] = "Abbreviated (K/M short)",
}

------------------------------------------------------------------------
-- Get number of stagger ticks (20 base, 30 with Bob and Weave)
------------------------------------------------------------------------
function Utils.GetStaggerTicks()
    if IsPlayerSpell and IsPlayerSpell(ns.CONST.BOB_AND_WEAVE) then
        return ns.CONST.BAW_TICKS
    end
    return ns.CONST.BASE_TICKS
end

------------------------------------------------------------------------
-- Template text formatter
-- Flags:
--   %s  = stagger total (formatted)
--   %r  = stagger total (raw, unformatted)
--   %p  = stagger % of max HP  (e.g. "45%")
--   %t  = single tick value (formatted)
--   %d  = DPS = tick*2 (formatted)
--   %tp = tick as %HP per second
--   %m  = max HP (formatted)
--   %n      = name ("Stagger")
--   %a      = absolute stagger / maxHP  (e.g. "450k / 1.2m")
--   %purify = value Purifying Brew would clear (50% stagger, formatted)
------------------------------------------------------------------------
function Utils.FormatText(template, data, numFmt)
    if not template or template == "" then return "" end
    numFmt = numFmt or 2

    -- Order matters: longest flags first to avoid partial match
    local result = template
    result = result:gsub("%%purify", Utils.FormatNumber((data.stagger or 0) * ns.CONST.PURIFY_PCT, numFmt))
    result = result:gsub("%%tp", data.tickPct or "")
    result = result:gsub("%%a",  Utils.FormatNumber(data.stagger, numFmt) .. " / " .. Utils.FormatNumber(data.maxHP, numFmt))
    result = result:gsub("%%r",  data.rawStagger or "")
    result = result:gsub("%%s",  Utils.FormatNumber(data.stagger, numFmt))
    result = result:gsub("%%d",  Utils.FormatNumber(data.dps, numFmt))
    result = result:gsub("%%t",  Utils.FormatNumber(data.tick, numFmt))
    result = result:gsub("%%p",  data.pctStr or "")
    result = result:gsub("%%m",  Utils.FormatNumber(data.maxHP, numFmt))
    result = result:gsub("%%n",  data.name or "Stagger")

    return result
end

------------------------------------------------------------------------
-- Clamp frame position so it stays within screen bounds
------------------------------------------------------------------------
function Utils.ClampToScreen(frame)
    if not frame then return end
    local s = frame:GetEffectiveScale()
    local sw, sh = GetScreenWidth() * s, GetScreenHeight() * s
    local l = frame:GetLeft()   or 0
    local r = frame:GetRight()  or 0
    local t = frame:GetTop()    or 0
    local b = frame:GetBottom() or 0
    l, r, t, b = l * s, r * s, t * s, b * s
    if l < 0 or r > sw or b < 0 or t > sh then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        if ns.db then
            ns.db.profile.position.point    = "CENTER"
            ns.db.profile.position.relPoint = "CENTER"
            ns.db.profile.position.xOfs     = 0
            ns.db.profile.position.yOfs     = -200
        end
    end
end

------------------------------------------------------------------------
-- Smooth lerp helper
------------------------------------------------------------------------
function Utils.Lerp(current, target, speed, dt)
    if not current or not target then return target or 0 end
    local diff = target - current
    if math.abs(diff) < 0.001 then return target end
    return current + diff * math.min(speed * dt, 1)
end