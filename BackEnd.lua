RTRank.lookupState.db = Database_Priest -- todo do some class matching

function RTRank:step() --todo refactor further
	---main (recursive) loop
	if inCombat then
		local lookup_state = RTRank.lookupState
        local db = lookup_state.db
		local spec = RTRank.utils:get_player_spec()

		local target_series = nil
		local encounter_id = lookup_state.active_encounter
		local encounter_diff = lookup_state.difficultyID

		-- dummy for testing
		if encounter_id == -1 then -- we are not in encounter
			if RTRank.config.dummy_enabled then
				encounter_id = RTRank.config.dummy_encounter
				encounter_diff = 5
			end
		end

		if encounter_id ~= -1 then  -- 5 = mythic, we only have this data --encounter_diff == 5
			RTRank.encounterState.in_session = true
			if db.lookup[spec] ~= nil then
				if db.lookup[spec][encounter_id] ~= nil then
					target_series = db.lookup[spec][encounter_id][RTRank.config.match_ranking]
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
	local seconds = RTRank.utils:get_current_time_step()
	local class = RTRank.utils:get_player_class()
	local spec = RTRank.utils:get_player_spec()
	local role = RTRank.utils:get_role(class, spec)

	local target_series_len = db.lookup[spec][encounter_id].length -- todo also get the playername for target rank as metadata

	local cumulative_amt = get_current_amount(role)

	if seconds < target_series_len then
		local timeSerVal = target_series[seconds + 1] -- 1 indexed..

		RTRank.encounterState:updateState(cumulative_amt, timeSerVal)
		local state = RTRank.encounterState

		local new_text = ""
		if RTRank.config.output_type == "cumulative" then
			new_text = "Target(" .. RTRank.config.match_ranking .. "): " ..
					RTRank.utils:format_amount(state.target_amount) .. "\nRelative performance: " ..
					RTRank.utils:format_amount(state.diff)
		elseif RTRank.config.output_type == "second" then
			new_text = "Target(" .. RTRank.config.match_ranking .. "): " ..
					RTRank.utils:format_amount(state.target_aps) .. "\nRelative performance: " ..
					RTRank.utils:format_amount(state.aps_diff)
		end

		RTRank:updateText(new_text)

		C_Timer.After(1, RTRank.step) --todo handle last partial second, these events are lost atm
	else
		print("RTRank: Exceeded max time steps(" .. seconds .. ") for comparison, stopping updates")
	end
end


function RTRank.encounterState:updateState(cumulative_player, cumulative_target)
	local seconds = RTRank.utils:get_current_time_step()

	local metric_diff = cumulative_player - cumulative_target

	local aps = 0
	local target_aps = 0
	local aps_diff = 0

	if seconds ~= 0 then
		aps = cumulative_player / seconds
		target_aps = cumulative_target / seconds
		aps_diff = metric_diff / seconds
	end

	self.player_amount = cumulative_player
	self.target_amount = cumulative_target
	self.diff = metric_diff
	self.player_aps = aps
	self.target_aps = target_aps
	self.aps_diff = aps_diff

	--RTRank.encounterState = state
end


function end_combat_session(override_text)  --different from end combat, this should be called on invalid session (e.g not encounter)
	RTRank.encounterState.in_session = false

	local encounter = RTRank.lookupState.active_encounter
	if encounter ~= -1 then
		print("RTRank: Ending combat session for encounter " .. encounter)
	else
		print("TMP: RTRank: Ending combat session")
	end

	if not override_text then
        RTRank:updateText(RTRank.config.default_text)
	end

end