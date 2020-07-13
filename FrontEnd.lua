local frame, events = CreateFrame("FRAME", "RTRankMain"), {};

inCombat = false

local function updateCounter(counter)
	if inCombat then
		local nowTime = GetTime()
		local seconds = math.floor(nowTime - startTime)


		if Database.size > seconds then
			timeSerVal = Database.lookup[seconds + 1] -- 1 indexed..
			frame.text:SetText(seconds .. " : " .. timeSerVal)
		end

		C_Timer.After(1, updateCounter)
	end
end

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
	inCombat = true
	startTime = GetTime()
	updateCounter()
end

function events:PLAYER_REGEN_ENABLED (...)
	inCombat = false
	local msg = "left combat"
	frame.text:SetText(msg)
end

-- ENCOUNTER_START todo

local function initFrame(frame)
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

function printDB()
	for idx,v in pairs(Database.lookup) do
		print(idx .. " : " .. v)
	end
end

initFrame(frame)
--printDB()

--TODOs:
--Get class, spec, encounter ID on encounter start, to identify correct table.
--Create combat log parser (or see if we can use some existing API)
--Feature 1: get relative performance compared to rank1 at t
--Feature 2: functionality to specify rank for comparison as user-setting (maybe just have a config file at first)
--Then presentation could use some polish
--Feature 3 (if we get this far): Dynamically infer final rank based on cumulative amount proximity at t (copy python implementation)