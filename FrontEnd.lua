local frame, events = CreateFrame("FRAME", "RTRankMain"), {};

--config
local match_ranking = 1
local dummy_encounter = 2329
local dummy_enabled = false

--temp config todo dynamically determine database on startup


db = Database_Priest

--vars
inCombat = false
local final_target_amount = -1
local final_player_amount = -1
local final_diff = -1
local lookup_state = {
	["active_encounter"] = -1,
	["difficultyID"] = -1
}

local function updateCounter(counter) --todo refactor this method is already overloaded
	if inCombat then
		local seconds = get_current_time_step()

		local class = get_player_class()
		local spec = get_player_spec()
		local target_series = nil

		local encounter_id = lookup_state.active_encounter
		local encounter_diff = lookup_state.difficultyID

		if encounter_id == -1 then -- we are not in encounter
			if dummy_enabled then
				encounter_id = dummy_encounter
				encounter_diff = 5
			end
		end

		if encounter_id ~= -1 and encounter_diff == 5 then  -- 5 = mythic, we only have this data

			if db.lookup[spec] ~= nil then
				if db.lookup[spec][encounter_id] ~= nil then
					target_series = db.lookup[spec][encounter_id][match_ranking]
				else
					print("Could not find data for encounter: " .. encounter_id)
				end
			else
				print("Could not find data for spec: " .. spec)
			end


			local target_series_len = db.lookup[spec][encounter_id].length

			local role = get_role(class, spec)
			local cumulative_amt = get_current_amount(role)


			if seconds < target_series_len then
				local timeSerVal = target_series[seconds + 1] -- 1 indexed..
				local metric_diff = cumulative_amt - timeSerVal
				frame.text:SetText("Target(" .. match_ranking .. "): " .. format_amount(timeSerVal) .. "\nRelative performance: " .. format_amount(metric_diff))
				final_target_amount = timeSerVal
				final_player_amount = cumulative_amt
				final_diff = metric_diff
			end

			C_Timer.After(1, updateCounter) --todo handle last partial second, these events are lost atm
		else
			end_combat_session()
		end
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
	if math.abs(num) > thousand then
		if math.abs(num) > million then
			return string.format("%.2f", (num / million)) .. "m"
		end
		return string.format("%.2f", (num / thousand)) .. "k"
	end
	return string.format("%.2f", num)
end

function end_combat_session()  --different from end combat, this should be called on invalid session (e.g not encounter)
	frame.text:SetText("No encounter")
end


function events:PLAYER_ENTERING_WORLD(...)
	local f = frame
	f:SetFrameStrata("BACKGROUND")
	f:SetWidth(140) -- Set these to whatever height/width is needed 
	f:SetHeight(64) -- for your Texture

	--todo maybe create dynamically resizing background wrt text

	--local t = f:CreateTexture(nil,"BACKGROUND")
	--t:SetColorTexture(0,0,0, 0.8)--"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
	--t:SetAllPoints(f)
	--f.texture = t

	f:SetPoint("CENTER",200,-100)

	f.text = f:CreateFontString(nil,"ARTWORK") 
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	f.text:SetText("Target rank: " .. match_ranking)
	f:Show()
end

function events:PLAYER_REGEN_DISABLED (...) --enter combat
	inCombat = true
	startTime = GetTime()
	updateCounter()
end

function events:PLAYER_REGEN_ENABLED (...) -- left combat
	inCombat = false
	lookup_state.active_encounter = -1
	lookup_state.difficultyID = -1

	local t = get_current_time_step()
	local msg = "Final value against rank " .. match_ranking .. ":\n" .. 
		" At t = " .. t .. ":" .. "\nTarget: " .. format_amount(final_target_amount) ..
		"\nYou: " .. format_amount(final_player_amount) .. "\nDiff: " .. format_amount(final_diff);

	frame.text:SetText(msg)
end

function events:ENCOUNTER_START (...)
	local encounterID, _ , difficultyID, _ = ...
	lookup_state.active_encounter = encounterID
	lookup_state.difficultyID = difficultyID
end

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
	for idx,v in pairs(db.lookup) do
		print(idx .. " : " .. v)
	end
end


-- todo new file probably
local details = _G.Details

function get_current_amount( metric_type )
	if metric_type == "healer" then
		local actor = details:GetActor ("current", DETAILS_ATTRIBUTE_HEAL, UnitName ("player"))
		if actor ~= nil then
			return actor.total
		else
			return 0
		end
	end
	if metric_type == "damage" then
		local actor = details:GetActor("current", DETAILS_ATTRIBUTE_DAMAGE, UnitName ("player")) --default damage, current combat
		if actor ~= nil then
			return actor.total
		else
			return 0
		end
	end
end

function get_player_class( ... )
	local playerClass, _ = UnitClass("player");
	return playerClass
end

function get_player_spec()
	local currentSpec = GetSpecialization()
	local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
	return currentSpecName
end

function get_role(player_class, player_spec )
	local role = Constants["Rolemap"][player_class][player_spec]
	if role == nil then
		print("RTRank: Unable to find role in rolemap for class: " .. player_class .. ", spec: " .. player_spec)
	end
	return role
end

initFrame(frame)
--printDB()

--TODOs:
--Get class, spec, encounter ID on encounter start, to identify correct table.
--Feature 2: functionality to specify rank for comparison as user-setting (maybe just have a config file at first)
--Then presentation could use some polish
--Feature 3 (if we get this far): Dynamically infer final rank based on cumulative amount proximity at t (copy python implementation)

--todo handle respec events