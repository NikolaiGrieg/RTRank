local frame, events = CreateFrame("FRAME", "RTRankMain"), {};

--config
local match_ranking = 100


inCombat = false
local final_amount = -1

local function updateCounter(counter)
	if inCombat then
		local seconds = get_current_time_step()

		local target_series = Database.lookup[match_ranking]
		local target_series_len = 200 --TODO replace sample value


		if seconds < target_series_len then
			timeSerVal = target_series[seconds + 1] -- 1 indexed..
			frame.text:SetText(seconds .. " : " .. format_amount(timeSerVal))
			final_amount = timeSerVal
		end

		C_Timer.After(1, updateCounter)
	end
end

function get_current_time_step()
	local nowTime = GetTime()
	local t = math.floor(nowTime - startTime)
	return t
end

function format_amount( num )
	if num == 0 then -- lua doesn't like to divide zero
		return 0 
	end

	local thousand = 1000
	local million = 1000000
	if num > thousand then
		if num > million then
			return string.format("%.2f", (num / million)) .. "m"
		end
		return string.format("%.2f", (num / thousand)) .. "k"
	end
end


function events:PLAYER_ENTERING_WORLD(...)
	local f = frame
	f:SetFrameStrata("BACKGROUND")
	f:SetWidth(140) -- Set these to whatever height/width is needed 
	f:SetHeight(64) -- for your Texture

	local t = f:CreateTexture(nil,"BACKGROUND")
	t:SetColorTexture(0,0,0, 0.8)--"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
	t:SetAllPoints(f)
	f.texture = t

	f:SetPoint("CENTER",200,-100)

	f.text = f:CreateFontString(nil,"ARTWORK") 
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	f.text:SetText("Target rank: " .. match_ranking)
	f:Show()
end

function events:PLAYER_REGEN_DISABLED (...)
	inCombat = true
	startTime = GetTime()
	updateCounter()
end

function events:PLAYER_REGEN_ENABLED (...)
	inCombat = false
	local t = get_current_time_step()
	local msg = "Final value against rank " .. match_ranking .. ":\n" .. 
		" For t = " .. t .. ":" .. "\nTarget: " .. format_amount(final_amount) ..
		"\nYou: TODO";

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
--get current cumulative aps from Details api

--Get class, spec, encounter ID on encounter start, to identify correct table.
--Feature 1: get relative performance compared to rank1 at t
--Feature 2: functionality to specify rank for comparison as user-setting (maybe just have a config file at first)
--Then presentation could use some polish
--Feature 3 (if we get this far): Dynamically infer final rank based on cumulative amount proximity at t (copy python implementation)

--todo fix: square format for lua db, mechanism for handling current time going over max previously seen