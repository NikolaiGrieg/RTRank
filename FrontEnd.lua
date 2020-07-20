local frame, events = CreateFrame("FRAME", "RTRankMain"), {};

--config
local match_ranking = 1
local dummy_encounter = 2329
local dummy_enabled = true
local default_text = "Target rank: " .. match_ranking
local background_enabled = true
local output_type = "second"  -- second, cumulative

--temp config todo dynamically determine database on startup

db = Database_Priest

--vars
inCombat = false
local in_session = false
local lookup_state = {
	["active_encounter"] = -1,
	["difficultyID"] = -1,
	["startTime"] = nil
}

--todo need to make this global
RTRank = {}
RTRank.encounterState = {
	["player_amount"] = -1,
	["target_amount"] = -1,
	["diff"] = -1,
	["player_aps"] = -1,
	["target_aps"] = -1,
	["aps_diff"] = -1,
}

--todo move all of these to backend module
local function step()
	---main (recursive) loop
	if inCombat then
		local spec = get_player_spec()

		local target_series = nil
		local encounter_id = lookup_state.active_encounter
		local encounter_diff = lookup_state.difficultyID

		-- dummy for testing
		if encounter_id == -1 then -- we are not in encounter
			if dummy_enabled then
				encounter_id = dummy_encounter
				encounter_diff = 5
			end
		end

		if encounter_id ~= -1 then  -- 5 = mythic, we only have this data --encounter_diff == 5
			in_session = true
			if db.lookup[spec] ~= nil then
				if db.lookup[spec][encounter_id] ~= nil then
					target_series = db.lookup[spec][encounter_id][match_ranking]
				else
					print("RTRank: Could not find data for encounter: " .. encounter_id)
				end
			else
				print("RTRank: Could not find data for spec: " .. spec)
			end

			if target_series ~= nil then
				updateDisplay(db, encounter_id, target_series)
			else
				end_combat_session(false)
			end
		else
			end_combat_session(false)
		end
	end
end

function updateDisplay(db, encounter_id, target_series)
	local seconds = get_current_time_step()
	local class = get_player_class()
	local spec = get_player_spec()
	local role = get_role(class, spec)

	local target_series_len = db.lookup[spec][encounter_id].length -- todo also get the playername for target rank as metadata

	local cumulative_amt = get_current_amount(role)

	if seconds < target_series_len then
		local timeSerVal = target_series[seconds + 1] -- 1 indexed..

		updateState(cumulative_amt, timeSerVal)
		local state = RTRank.encounterState

		local new_text = ""
		if output_type == "cumulative" then
			new_text = "Target(" .. match_ranking .. "): " .. format_amount(state.target_amount) .. "\nRelative performance: " .. format_amount(state.diff)
		elseif output_type == "second" then
			new_text = "Target(" .. match_ranking .. "): " .. format_amount(state.target_aps) .. "\nRelative performance: " .. format_amount(state.aps_diff)
		end
		frame.text:SetText(new_text)
		updateBackground(frame)

		C_Timer.After(1, step) --todo handle last partial second, these events are lost atm
	else
		print("RTRank: Exceeded max time steps(" .. seconds .. ") for comparison, stopping updates")
	end
end

--- uses encounter start if in encounter, else combat start
function get_current_time_step()
	local encounterStart = lookup_state.startTime
	local nowTime = GetTime()

	if encounterStart ~= nil then
		return math.floor(nowTime - encounterStart)
	else
		return math.floor(nowTime - combatStartTime)
	end
end

function updateState(cumulative_player, cumulative_target)
	local state = RTRank.encounterState
	local seconds = get_current_time_step()

	local metric_diff = cumulative_player - cumulative_target

	local aps = 0
	local target_aps = 0
	local aps_diff = 0

	if seconds ~= 0 then
		aps = cumulative_player / seconds
		target_aps = cumulative_target / seconds
		aps_diff = metric_diff / seconds
	end

	state.player_amount = cumulative_player
	state.target_amount = cumulative_target
	state.diff = metric_diff
	state.player_aps = aps
	state.target_aps = target_aps
	state.aps_diff = aps_diff

	RTRank.encounterState = state
end


function end_combat_session(override_text)  --different from end combat, this should be called on invalid session (e.g not encounter)
	in_session = false

	local encounter = lookup_state.active_encounter
	if encounter ~= -1 then
		print("RTRank: Ending combat session for encounter " .. encounter)
	else
		print("TMP: RTRank: Ending combat session")
	end

	if not override_text then
		frame.text:SetText(default_text)
		updateBackground(frame)
	end

end


function events:PLAYER_ENTERING_WORLD(...)
	local f = frame
	f:SetFrameStrata("BACKGROUND")
	f:SetWidth(140) -- Set these to whatever height/width is needed
	f:SetHeight(64) -- for your Texture

	if background_enabled then
		local t = f:CreateTexture(nil,"BACKGROUND")
		t:SetColorTexture(0,0,0, 0.5)
		t:SetAllPoints(f)
		f.texture = t
	end

	f:SetPoint("CENTER",200,-100)

	f.text = f:CreateFontString(nil,"ARTWORK")
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	f.text:SetText(default_text)

	updateBackground(f)

	f:Show()
end

function updateBackground(frame)
	local width = frame.text:GetStringWidth()
	frame:SetWidth(width)
end

function events:PLAYER_REGEN_DISABLED (...) --enter combat
	inCombat = true
	combatStartTime = GetTime()

	step()
end

function events:PLAYER_REGEN_ENABLED (...) -- left combat
	inCombat = false
	lookup_state.active_encounter = -1
	lookup_state.difficultyID = -1
	local t = get_current_time_step()
	local state = RTRank.encounterState

	if in_session then  -- execute final commands before ending session
		local msg = ""
		if output_type == "cumulative" then
			msg = "Final value against rank " .. match_ranking .. ":\n" ..
			" At t = " .. t .. ":" .. "\nTarget: " .. format_amount(state.target_amount) ..
			"\nYou: " .. format_amount(state.player_amount) .. "\nDiff: " .. format_amount(stat.diff);
		elseif output_type == "second" then
			msg = "Final value against rank " .. match_ranking .. ":\n" ..
			" At t = " .. t .. ":" .. "\nTarget: " .. format_amount(state.target_aps) ..
			"\nYou: " .. format_amount(state.player_aps) .. "\nDiff: " .. format_amount(state.aps_diff);
		end

		frame.text:SetText(msg)
		updateBackground(frame)

		end_combat_session(true)
	end
end

function events:ENCOUNTER_START (...)
	local encounterID, _ , difficultyID, _ = ...
	lookup_state.active_encounter = encounterID
	lookup_state.difficultyID = difficultyID
	lookup_state.startTime = GetTime()
	print("RTRank: Initialized encounter " .. encounterID .. ", with difficulty: " .. difficultyID)
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


initFrame(frame)

--TODOs:
--Feature 2: functionality to specify rank for comparison as user-setting (maybe just have a config file at first)
--Then presentation could use some polish
--Feature 3 (if we get this far): Dynamically infer final rank based on cumulative amount proximity at t (copy python implementation)

--todo handle respec events