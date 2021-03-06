local nibRealUI = LibStub("AceAddon-3.0"):GetAddon("nibRealUI")

local MODNAME = "UnitFrames"
local UnitFrames = nibRealUI:GetModule(MODNAME)
local db, ndb, ndbc

local oUF = oUFembed

local round = nibRealUI.Round
local info = {
    health = {
        leftAngle = [[/]],
        rightAngle = [[/]],
        growDirection = "LEFT",
        smooth = true,
    },
    predict = {
        leftAngle = [[/]],
        rightAngle = [[/]],
        growDirection = "LEFT",
        smooth = true,
    },
    power = {
        leftAngle = [[\]],
        rightAngle = [[\]],
        growDirection = "LEFT",
        smooth = true,
    },
    [1] = {
        x = 222,
        y = 24,
        endBox = {
            x = -10,
            y = -4,
        },
    },
    [2] = {
        x = 259,
        y = 28,
        endBox = {
            x = -11,
            y = -2,
        },
    },
}

local function CreateHealthBar(parent)
    local width, height = parent:GetWidth(), round((parent:GetHeight() - 3) * db.units.player.healthHieght)
    local info = info.health
    local health = parent:CreateAngleFrame("Status", width, height, parent.overlay, info)
    health:SetPoint("TOPRIGHT", parent, 0, 0)
    if ndb.settings.reverseUnitFrameBars then
        health:SetReversePercent(true)
    end

    health.text = health:CreateFontString(nil, "OVERLAY")
    health.text:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 2, 2)
    health.text:SetFont(unpack(nibRealUI:Font()))
    parent:Tag(health.text, "[realui:smartHealth]")

    local stepPoints = db.misc.steppoints[nibRealUI.class] or db.misc.steppoints["default"]
    local stepHeight = round(height / 2)
    health.step = {}
    health.warn = {}
    for i = 1, 2 do
        health.step[i] = parent:CreateAngleFrame("Frame", stepHeight + 2, stepHeight, health, info)
        health.warn[i] = parent:CreateAngleFrame("Frame", height + 2, height, health, info)
        local xOfs = round(stepPoints[i] * health.info.maxWidth)
        if health.reverse then
            health.step[i]:SetPoint("TOPRIGHT", health, -xOfs, 0)
            health.warn[i]:SetPoint("TOPRIGHT", health, -xOfs, 0)
        else
            xOfs = xOfs + health.info.minWidth
            health.step[i]:SetPoint("TOPRIGHT", health, "TOPLEFT", xOfs, 0)
            health.warn[i]:SetPoint("TOPRIGHT", health, "TOPLEFT", xOfs, 0)
        end
        health.step[i]:SetBackgroundColor(.5, .5, .5, nibRealUI.media.background[4])
        health.warn[i]:SetBackgroundColor(.5, .5, .5, nibRealUI.media.background[4])
    end

    health.colorClass = db.overlay.classColor
    health.colorHealth = true

    health.frequentUpdates = true
    health.PostUpdate = UnitFrames.UpdateSteps
    --health.Override = UnitFrames.HealthOverride
    parent.Health = health
    UnitFrames:SetHealthColor(parent)
end

local function CreatePredictBar(parent)
    local width, height = parent.Health:GetSize()
    local info = info.predict
    local absorbBar = parent:CreateAngleFrame("Bar", width, height, parent.Health, info)
    absorbBar:SetStatusBarColor(1, 1, 1, db.overlay.bar.opacity.absorb)
    absorbBar:SetReversePercent(true)

    parent.HealPrediction = {
        absorbBar = absorbBar,
        frequentUpdates = true,
        Override = UnitFrames.PredictOverride,
    }
end

local function CreatePvPStatus(parent)
    local width, height = parent.Health:GetSize()
    local info = info.health

    local height = ceil(height * 0.65)
    local pvp = parent:CreateAngleFrame("Frame", height + 4, height, parent.Health, info)
    pvp:SetPoint("TOPRIGHT", parent.Health, -8, 0)

    pvp.text = pvp:CreateFontString(nil, "OVERLAY")
    pvp.text:SetPoint("BOTTOMLEFT", parent.Health, "TOPLEFT", 15, 2)
    pvp.text:SetFont(unpack(nibRealUI:Font()))
    pvp.text:SetJustifyH("LEFT")
    pvp.text.frequentUpdates = 1
    parent:Tag(pvp.text, "[realui:pvptimer]")

    pvp.Override = UnitFrames.PvPOverride
    parent.PvP = pvp
end

local function CreatePowerBar(parent)
    local width, height = round(parent:GetWidth() * 0.89), round((parent:GetHeight() - 3) * (1 - db.units.player.healthHieght))
    local info = info.power
    --print("Create Power bar")
    local power = parent:CreateAngleFrame("Status", width, height, parent.overlay, info)
    power:SetPoint("BOTTOMRIGHT", parent, -5, 0)

    power.text = power:CreateFontString(nil, "OVERLAY")
    power.text:SetPoint("TOPRIGHT", power, "BOTTOMRIGHT", 2, -3)
    power.text:SetFont(unpack(nibRealUI:Font()))
    parent:Tag(power.text, "[realui:power]")

    local stepPoints = db.misc.steppoints[nibRealUI.class] or db.misc.steppoints["default"]
    local stepHeight = round(height * .6)
    power.step = {}
    power.warn = {}
    for i = 1, 2 do
        power.step[i] = parent:CreateAngleFrame("Frame", stepHeight + 2, stepHeight, power, info)
        power.warn[i] = parent:CreateAngleFrame("Frame", height + 2, height, power, info)
        power.step[i]:SetBackgroundColor(.5, .5, .5, nibRealUI.media.background[4])
        power.warn[i]:SetBackgroundColor(.5, .5, .5, nibRealUI.media.background[4])
    end

    power.colorPower = true

    power.frequentUpdates = true
    power.PostUpdate = UnitFrames.UpdateSteps
    --power.Override = UnitFrames.PowerOverride
    parent.Power = power
end

local function CreatePowerStatus(parent) -- Combat, AFK, etc.
    local texture = UnitFrames.textures[UnitFrames.layoutSize].F1.statusBox
    local status = {}
    for i = 1, 2 do
        status.bg = parent.Power:CreateTexture(nil, "BORDER")
        status.bg:SetTexture(texture.bar)
        status.bg:SetSize(texture.width, texture.height)

        status.border = parent.Power:CreateTexture(nil, "OVERLAY", nil, 3)
        status.border:SetTexture(texture.border)
        status.border:SetAllPoints(status.bg)

        status.bg.Override = UnitFrames.UpdateStatus
        status.border.Override = UnitFrames.UpdateStatus

        if i == 1 then
            status.bg:SetPoint("TOPRIGHT", parent.Power, "TOPLEFT", 8, 0)
            parent.Combat = status.bg
            parent.Resting = status.border
        else
            status.bg:SetPoint("TOPRIGHT", parent.Power, "TOPLEFT", 2, 0)
            parent.Leader = status.bg
            parent.AFK = status.border
        end
    end
end

local function CreateStats(parent)
    parent.Stats = {}
    for i = 1, 2 do
        parent.Stats[i] = {}
        parent.Stats[i].icon = parent.overlay:CreateTexture(nil, "OVERLAY")
        parent.Stats[i].icon:SetTexture(nibRealUI.media.icons.DoubleArrow)
        parent.Stats[i].icon:SetSize(16, 16)
        if i == 1 then
            parent.Stats[i].icon:SetPoint("BOTTOMLEFT", parent.Health, "BOTTOMRIGHT", 10, 0)
        else
            parent.Stats[i].icon:SetPoint("TOPLEFT", parent.Power, "TOPRIGHT", 15, 5)
        end

        parent.Stats[i].text = parent.overlay:CreateFontString(nil, "OVERLAY")
        parent.Stats[i].text:SetFont(unpack(nibRealUI:Font()))
        parent.Stats[i].text:SetPoint("BOTTOMLEFT", parent.Stats[i].icon, "BOTTOMRIGHT", 0, 0)
    end
end

local function CreateEndBox(parent)
    local texture = UnitFrames.textures[UnitFrames.layoutSize].F1.endBox
    local pos = info[UnitFrames.layoutSize].endBox
    parent.endBox = parent.overlay:CreateTexture(nil, "BORDER")
    parent.endBox:SetTexture(texture.bar)
    parent.endBox:SetSize(texture.width, texture.height)
    parent.endBox:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", pos.x, pos.y)

    local border = parent.overlay:CreateTexture(nil, "OVERLAY", nil, 3)
    border:SetTexture(texture.border)
    border:SetAllPoints(parent.endBox)

    parent.endBox.Update = UnitFrames.UpdateEndBox
end

local function CreateTotems(parent)
    -- DestroyTotem is protected, so we hack the default
    local totemBar = _G["TotemFrame"]
    totemBar:SetParent(parent.overlay)
    hooksecurefunc("TotemFrame_Update", function()
        totemBar:ClearAllPoints()
        totemBar:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 10, -4)
    end)
    for i = 1, 4 do
        local name = "TotemFrameTotem"..i
        local totem = _G[name]
        totem:SetSize(22, 22)
        totem:ClearAllPoints()
        totem:SetPoint("TOPLEFT", totemBar, i * (totem:GetWidth() + 3), 0)
        nibRealUI:CreateBG(totem)
        
        local bg = _G[name.."Background"]
        bg:SetTexture("")
        local dur = _G[name.."Duration"]
        dur:Hide()
        dur.Show = function() end
        
        local icon = _G[name.."IconTexture"]
        icon:SetTexCoord(.08, .92, .08, .92)
        icon:ClearAllPoints()
        icon:SetAllPoints()
        
        local _, border = totem:GetChildren()
        border:DisableDrawLayer("OVERLAY")
    end
end

UnitFrames["player"] = function(self)
    self:SetSize(info[UnitFrames.layoutSize].x, info[UnitFrames.layoutSize].y)

    CreateHealthBar(self)
    CreatePredictBar(self)
    CreatePvPStatus(self)
    CreatePowerBar(self)
    CreatePowerStatus(self)
    CreateStats(self)
    CreateEndBox(self)
    CreateTotems(self)

    self.RaidIcon = self:CreateTexture(nil, "OVERLAY")
    self.RaidIcon:SetSize(20, 20)
    self.RaidIcon:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 10, 4)

    function self:PostUpdate(event)
        self.endBox.Update(self, event)

        local power = self.Power
        local _, powerType = UnitPowerType(self.unit)
        --power:SetStatusBarColor(UnitFrames.PowerColors[powerType])
        power:SetReversePercent(UnitFrames.ReversePowers[powerType] or (ndb.settings.reverseUnitFrameBars))
        power.enabled = true

        local stepPoints = db.misc.steppoints[nibRealUI.class] or db.misc.steppoints["default"]
        for i = 1, 2 do
            local xOfs = floor(stepPoints[i] * power.info.maxWidth)
            if power.reverse then
                power.step[i]:SetPoint("BOTTOMRIGHT", power, -xOfs, 0)
                power.warn[i]:SetPoint("BOTTOMRIGHT", power, -xOfs, 0)
            else
                xOfs = xOfs + power.info.minWidth
                power.step[i]:SetPoint("BOTTOMRIGHT", power, "BOTTOMLEFT", xOfs, 0)
                power.warn[i]:SetPoint("BOTTOMRIGHT", power, "BOTTOMLEFT", xOfs, 0)
            end
        end
    end
end

-- Init
tinsert(UnitFrames.units, function(...)
    db = UnitFrames.db.profile
    ndb = nibRealUI.db.profile
    ndbc = nibRealUI.db.char

    local player = oUF:Spawn("player", "RealUIPlayerFrame")
    player:SetPoint("RIGHT", "RealUIPositionersUnitFrames", "LEFT", db.positions[UnitFrames.layoutSize].player.x, db.positions[UnitFrames.layoutSize].player.y)
    player:RegisterEvent("PLAYER_FLAGS_CHANGED", UnitFrames.UpdateStatus)
    player:RegisterEvent("UPDATE_SHAPESHIFT_FORM", player.PostUpdate)
end)

