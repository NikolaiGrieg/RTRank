local frame, events = CreateFrame("FRAME", "FooAddonFrame"), {};

function events:PLAYER_ENTERING_WORLD(...)
	local f = frame
	f:SetFrameStrata("BACKGROUND")
	f:SetWidth(128) -- Set these to whatever height/width is needed 
	f:SetHeight(64) -- for your Texture

	local t = f:CreateTexture(nil,"BACKGROUND")
	t:SetColorTexture(0,0,0, 0.8)--"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
	t:SetAllPoints(f)
	f.texture = t

	f:SetPoint("CENTER",200,-100)

	f.text = f:CreateFontString(nil,"ARTWORK") 
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	f.text:SetText("this is a text")
	f:Show()
end

function events:PLAYER_REGEN_DISABLED (...)
	local msg = "in combat"
	print(msg)
	frame.text:SetText(msg)
end

function events:PLAYER_REGEN_ENABLED (...)
	local msg = "left combat"
	print(msg)
	frame.text:SetText(msg)
end


local function initFrame(frame)
	--frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame:SetScript("OnEvent", function(self, event, ...)
 		events[event](self, ...); -- call one of the functions above
	end);
	for k, v in pairs(events) do
	 	frame:RegisterEvent(k); -- Register all events for which handlers have been defined
	end
end


initFrame(frame)

