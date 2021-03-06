--[[ Created by Grid2 original authors, modified by Michael ]]--

local Grid2 = Grid2
local Grid2Frame = Grid2Frame
local GetTime = GetTime
local min = min

local AlignPoints = Grid2.AlignPoints

local function Bar_CreateHH(self, parent)
	local bar = self:CreateFrame("StatusBar", parent)
	bar:SetStatusBarColor(0,0,0,0)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	if self.backColor then
		bar.bgBar = bar.bgBar or CreateFrame("StatusBar", nil, parent)
		bar.bgBar:SetMinMaxValues(0, 1)
		bar.bgBar:SetValue(1)
		bar.bgBar:Show()
	end
	bar:Show()
end

local function Bar_Layout(self, parent)
	local Bar    = parent[self.name]
	local bgBar  = Bar.bgBar
	local orient = self.orientation or Grid2Frame.db.profile.orientation
	local points = AlignPoints[orient][not self.reverseFill]
	local level  = parent:GetFrameLevel() + self.frameLevel
	Bar:ClearAllPoints()
	Bar:SetOrientation(orient)
	Bar:SetStatusBarTexture(self.texture)
	Bar:SetReverseFill(self.reverseFill)
	local barParent = self.barParent
	if barParent then
		local PBar = parent[barParent.name]
		Bar:SetFrameLevel(PBar:GetFrameLevel()+ (barParent.backColor and 1 or 0) )
		Bar:SetSize( PBar:GetWidth(), PBar:GetHeight() )
		Bar:SetPoint( points[1], PBar:GetStatusBarTexture(), points[2], 0, 0)
		Bar:SetPoint( points[3], PBar:GetStatusBarTexture(), points[4], 0, 0)
		if bgBar then bgBar:Hide() end
	else
		local w = self.width  or parent.container:GetWidth()
		local h = self.height or parent.container:GetHeight()	
		Bar:SetFrameLevel(level)
		Bar:SetSize(w, h)	
		Bar:SetPoint(self.anchor, parent.container, self.anchorRel, self.offsetx, self.offsety)			
		if self.backColor then
			local color = self.backColor 
			bgBar:SetStatusBarTexture(self.texture)
			bgBar:SetStatusBarColor(color.r,color.g,color.b,color.a)
			bgBar:SetOrientation(orient)
			bgBar:SetFrameLevel(level)
			bgBar:ClearAllPoints()
			bgBar:SetPoint( points[1], Bar:GetStatusBarTexture(), points[2], 0, 0)
			bgBar:SetPoint( points[3], Bar:GetStatusBarTexture(), points[4], 0, 0)
			bgBar:SetPoint( points[2], Bar, points[2], 0, 0)
			bgBar:SetPoint( points[4], Bar, points[4], 0, 0)
			bgBar:Show()
		elseif bgBar then bgBar:Hide() end				
	end    
end

local function Bar_GetBlinkFrame(self, parent)
	return parent[self.name]
end

local function Bar_SetValue(self, parent, value)
	parent[self.name]:SetValue(value)
end

local function Bar_SetValueParent(self, parent, value)
	parent[self.name]:SetValue(value)
	local barChild = parent[self.barChild.name]
	if value+barChild:GetValue()>1 then barChild:SetValue(1-value) end
end

local function Bar_SetValueChild(self, parent, value)
	local v = parent[self.barParent.name]:GetValue()
	if value+v>1 then value = 1-v end
	parent[self.name]:SetValue(value)	
end

--{{{ Bar OnUpdate
local durationTimers = {}
local expirations = {}
local durations= {}
local function tevent(self, parent, bar)
	local timeLeft = expirations[bar] - GetTime()
	self:SetValue( parent, timeLeft>0 and timeLeft/durations[bar] or 0 ) 
end
local function tcancel(bar)
	if durationTimers[bar] then
		Grid2:CancelTimer(durationTimers[bar])
		durationTimers[bar], expirations[bar], durations[bar] = nil, nil, nil
	end
end

local function Bar_OnUpdateD(self, parent, unit, status)
	local bar,value = parent[self.name],0
	if status then
		local expiration = status:GetExpirationTime(unit)
		if expiration then
			local now = GetTime()
			local timeLeft = expiration - now
			if timeLeft>0 then
				local duration= status:GetDuration(unit) or timeLeft
				expirations[bar]= expiration
				durations[bar]= duration
				if not durationTimers[bar] then
					durationTimers[bar]= Grid2:ScheduleRepeatingTimer(tevent, (duration>3 and 0.001 or 0.001), self, parent, bar)
				end	
				value= timeLeft / duration
			else
				tcancel(bar)
			end
		end	
	else
		tcancel(bar)
	end
	self:SetValue(parent,value)
end

local function Bar_OnUpdateS(self, parent, unit, status)
	self:SetValue( parent, status and status:GetCount(unit)/status:GetCountMax(unit) or 0)
end

local function Bar_OnUpdate(self, parent, unit, status)
	self:SetValue(parent, status and status:GetPercent(unit) or 0)
end

--}}}

local function Bar_SetOrientation(self, orientation)
	self.orientation     = orientation
	self.dbx.orientation = orientation
end

local function Bar_Disable(self, parent)
	local bar = parent[self.name]
	bar:Hide()
	if bar.bgBar then bar.bgBar:Hide() end
	self.Layout   = nil
	self.OnUpdate = nil
end

local function Bar_UpdateDB(self, dbx)
	dbx = dbx or self.dbx
	self.texture = Grid2:MediaFetch("statusbar", dbx.texture, "Gradient")
	local l = dbx.location
	self.frameLevel     = dbx.level or 1
	self.anchor         = l.point
	self.anchorRel      = l.relPoint
	self.offsetx        = l.x
	self.offsety        = l.y
	self.width          = dbx.width
	self.height         = dbx.height
	self.orientation    = dbx.orientation
	self.reverseFill    = dbx.reverseFill	
	self.backColor      = dbx.backColor
	self.Create         = Bar_CreateHH
	self.GetBlinkFrame  = Bar_GetBlinkFrame
	self.OnUpdate       = Bar_OnUpdate
	self.SetOrientation = Bar_SetOrientation
	self.Disable        = Bar_Disable	
	self.UpdateDB       = Bar_UpdateDB
	self.Layout         = Bar_Layout
	self.SetValue       = Bar_SetValue
	self.OnUpdate       = (dbx.duration and Bar_OnUpdateD) or (dbx.stack and Bar_OnUpdateS) or Bar_OnUpdate
	self.dbx            = dbx
	self.barParent      = nil
	if dbx.anchorTo then
		self.barParent = Grid2.indicators[dbx.anchorTo]
		self.barParent.barChild = self
		self.barParent.SetValue = Bar_SetValueParent
		self.SetValue = Bar_SetValueChild		
		self.reverseFill = self.barParent.reverseFill
		self.orientation = self.barParent.orientation
	end
end

local function BarColor_OnUpdate(self, parent, unit, status)
	if status then
		self:SetBarColor(parent, status:GetColor(unit))
	else
		self:SetBarColor(parent, 0, 0, 0, 0)
	end
end

local function BarColor_SetBarColor(self, parent, r, g, b, a)
	parent[self.BarName]:SetStatusBarColor(r, g, b, min(self.opacity,a or 1) )
end

local function BarColor_SetBarColorInverted(self, parent, r, g, b, a)
	parent[self.BarName]:SetStatusBarColor(0, 0, 0, min(self.opacity, 0.8) )
	if not self.dbx.anchorTo then
		parent.container:SetVertexColor(r, g, b, a)
	end	
end

local function BarColor_UpdateDB(self)
	if self.dbx.invertColor then
		self.SetBarColor = BarColor_SetBarColorInverted
	else
		self.SetBarColor = BarColor_SetBarColor
	end
	self.opacity= self.dbx.opacity or 1
end

local function Create(indicatorKey, dbx)

	local Bar = Grid2.indicators[indicatorKey] or Grid2.indicatorPrototype:new(indicatorKey)
	Bar_UpdateDB(Bar,dbx)
	Grid2:RegisterIndicator(Bar, { "percent" }, true)

	local colorKey    = indicatorKey .. "-color"
	local BarColor    = Grid2.indicators[colorKey] or Grid2.indicatorPrototype:new(colorKey)
	BarColor.dbx      = dbx
	BarColor.BarName  = indicatorKey
	BarColor.Create   = Grid2.Dummy
	BarColor.Layout   = Grid2.Dummy
	BarColor.OnUpdate = BarColor_OnUpdate
	BarColor.UpdateDB = BarColor_UpdateDB
	BarColor_UpdateDB(BarColor)
	Grid2:RegisterIndicator(BarColor, { "color" })

	Bar.sideKick = BarColor

	return Bar, BarColor
end

Grid2.setupFunc["bar"] = Create

Grid2.setupFunc["bar-color"] = Grid2.Dummy
