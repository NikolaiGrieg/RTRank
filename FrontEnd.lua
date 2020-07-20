local frame, events = CreateFrame("FRAME", "RTRankMain"), {};

--config
local match_ranking = 1
local dummy_encounter = 2329
local dummy_enabled = true
local default_text = "Target rank: " .. match_ranking
local background_enabled = true

--temp config todo dynamically determine database on startup

db = Database_Priest

--vars
inCombat = false
local in_session = false
local final_target_amount = -1
local final_player_amount = -1
local final_diff = -1
local lookup_state = {  -- todo need global object RTRank
	["active_encounter"] = -1,
	["difficultyID"] = -1,
	["startTime"] = nil
}

--main loop, handles steps
local function updateCounter()
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

	local target_series_len = db.lookup[spec][encounter_id].length

	local cumulative_amt = get_current_amount(role)

	if seconds < target_series_len then -- todo show dps instead of cumulative dmg
		local timeSerVal = target_series[seconds + 1] -- 1 indexed..
		local metric_diff = cumulative_amt - timeSerVal

		final_target_amount = timeSerVal
		final_player_amount = cumulative_amt
		final_diff = metric_diff

		frame.text:SetText("Target(" .. match_ranking .. "): " .. format_amount(timeSerVal) .. "\nRelative performance: " .. format_amount(metric_diff))
		updateBackground(frame)

		C_Timer.After(1, updateCounter) --todo handle last partial second, these events are lost atm
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
		t:SetColorTexture(0,0,0, 0.8)
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

	updateCounter()
end

function events:PLAYER_REGEN_ENABLED (...) -- left combat
	inCombat = false
	lookup_state.active_encounter = -1
	lookup_state.difficultyID = -1
	local t = get_current_time_step()

	if in_session then  -- execute final commands before ending session
		local msg = "Final value against rank " .. match_ranking .. ":\n" ..
		" At t = " .. t .. ":" .. "\nTarget: " .. format_amount(final_target_amount) ..
		"\nYou: " .. format_amount(final_player_amount) .. "\nDiff: " .. format_amount(final_diff);

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