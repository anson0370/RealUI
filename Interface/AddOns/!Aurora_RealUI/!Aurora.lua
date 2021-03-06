local _, mods = ...
mods["Aurora"] = {}
mods["nibRealUI"] = {}
mods["PLAYER_LOGIN"] = {}

-- RealUI skin hook
REALUI_STRIPE_TEXTURES = REALUI_STRIPE_TEXTURES or {}
REALUI_WINDOW_FRAMES = REALUI_WINDOW_FRAMES or {}
local debug = RealUI.Debug
local db

-- Aurora API
local F, C
local r, g, b
local style = {}
style.apiVersion = "6.0"

style.skipSplashScreen = true

--style.highlightColor = {r = 0, g = 1, b = 0}
style.classcolors = {
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["DRUID"]       = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"]      = { r = 0.67, g = 0.83, b = 0.45 },
    ["MAGE"]        = { r = 0.41, g = 0.80, b = 0.94 },
    ["MONK"]        = { r = 0.00, g = 1.00, b = 0.59 },
    ["PALADIN"]     = { r = 0.96, g = 0.55, b = 0.73 },
    ["PRIEST"]      = { r = 0.80, g = 0.80, b = 0.80 },
    ["ROGUE"]       = { r = 1.00, g = 0.96, b = 0.41 },
    ["SHAMAN"]      = { r = 0.00, g = 0.44, b = 0.87 },
    ["WARLOCK"]     = { r = 0.58, g = 0.51, b = 0.79 },
    ["WARRIOR"]     = { r = 0.78, g = 0.61, b = 0.43 },
}

-- Save these functions so we dont have to duplicate just to place a border around an icon.
style.copy = {
    CreateBD = true,
    CreateBG = true,
    CreateGradient = true,
    CreateBDFrame = true,
    ReskinIcon = true,
}

-- Reskin* functions (Icon excepted) should never be saved, and only used within !Aurora.
-- This is to ensure a consistent look if the user disables Aurora.
local functions = {}
functions.CreateBD = function(f, a)
    --print("Override CreateBD", f:GetName(), a)
    f:SetBackdrop({
        bgFile = RealUI.media.textures.plain,
        edgeFile = RealUI.media.textures.plain,
        edgeSize = 1,
    })
    f:SetBackdropBorderColor(0, 0, 0)
    if not a then
        --print("CreateSD")
        f:SetBackdropColor(unpack(RealUI.media.window))
        f.tex = f.tex or f:CreateTexture(nil, "BACKGROUND", nil, 1)
        f.tex:SetTexture([[Interface\AddOns\nibRealUI\Media\StripesThin]], true)
        f.tex:SetAlpha(0.5) --db.settings.stripeOpacity)
        f.tex:SetAllPoints()
        f.tex:SetHorizTile(true)
        f.tex:SetVertTile(true)
        f.tex:SetBlendMode("ADD")
        tinsert(REALUI_WINDOW_FRAMES, f)
        tinsert(REALUI_STRIPE_TEXTURES, f.tex)
    else
        --print("CreateBD: alpha", a)
        f:SetBackdropColor(0, 0, 0, a)
    end
end

functions.CreateBG = function(frame)
    local f = frame
    if frame:GetObjectType() == "Texture" then f = frame:GetParent() end

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, -1, 1)
    bg:SetPoint("BOTTOMRIGHT", frame, 1, -1)
    bg:SetTexture(RealUI.media.textures.plain)
    bg:SetVertexColor(0, 0, 0)

    return bg
end

local buttonR, buttonG, buttonB, buttonA
functions.CreateGradient = function(f)
    local tex = f:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)
    tex:SetTexture(RealUI.media.textures.plain)
    tex:SetVertexColor(buttonR, buttonG, buttonB, buttonA)

    return tex
end

functions.CreateBDFrame = function(f, a)
    local frame
    if f:GetObjectType() == "Texture" then
        frame = f:GetParent()
    else
        frame = f
    end

    local lvl = frame:GetFrameLevel()

    local bg = CreateFrame("Frame", nil, frame)
    bg:SetPoint("TOPLEFT", f, -1, 1)
    bg:SetPoint("BOTTOMRIGHT", f, 1, -1)
    bg:SetFrameLevel(lvl == 0 and 1 or lvl - 1)

    F.CreateBD(bg, a)

    return bg
end

functions.ReskinIcon = function(icon)
    RealUI.Debug("ReskinIcon", F, C, icon)
    icon:SetTexCoord(.08, .92, .08, .92)
    return F.CreateBG(icon)
end
style.functions = functions

style.initVars = function()
    RealUI.Debug("initVars", Aurora, Aurora[1], Aurora[2])
    F, C = unpack(Aurora)
    r, g, b = C.r, C.g, C.b
    buttonR, buttonG, buttonB, buttonA = .1, .1, .1, 1
end

AURORA_CUSTOM_STYLE = style

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_LOGIN" and IsAddOnLoaded("Aurora") then
        F, C = unpack(Aurora)
        -- some skins need to be deferred till after all other addons.
        for addonName, func in next, mods[event] do
            if type(addonName) == "string" then
                if IsAddOnLoaded(addonName) then
                    -- Create skin modules for addon so they can be individually disabled.
                    local skin = RealUI:RegisterSkin(addonName)
                    if RealUI:GetModuleEnabled(addonName) then
                        func(skin, F, C)
                    end
                end
            else
                -- Some mods are indexed
                func(F, C)
            end
        end
        f:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "ADDON_LOADED" then
        local addonModule = mods[addon]
        debug("Load Addon", addon, addonModule)
        if addon == "Aurora" then
            F, C = unpack(Aurora)

            F.ReskinAtlas = function(f, atlas, is8Point)
                --debug("ReskinAtlas")
                if not atlas then atlas = f:GetAtlas() end
                local file, _, _, left, right, top, bottom = GetAtlasInfo(atlas)
                file = file:sub(10) -- cut off "Interface"
                f:SetTexture([[Interface\AddOns\!Aurora_RealUI\Media]]..file)
                if is8Point then
                    return left, right, top, bottom
                else
                    f:SetTexCoord(left, right, top, bottom)
                end
            end

            for _, moduleFunc in pairs(addonModule) do
                F.AddPlugin(function()
                    moduleFunc(F, C)
                end)
            end
        elseif addon == "nibRealUI" then
            --db = RealUI.db.profile
            for _, moduleFunc in pairs(addonModule) do
                moduleFunc(F, C)
            end
        else
            if addonModule then
                if type(addonModule) == "function" then
                    addonModule(F, C)
                end
            end
        end
    end
end)
