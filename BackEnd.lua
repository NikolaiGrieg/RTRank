
function RTRank:loadDataBase()
	-- this will probably load all dbs into memory, need to break up into conditional loads if this is very large
	local class = RTRank.utils:get_player_class()
	local meta_lookup = {
		["Priest"] = Database_Priest,
		["Shaman"] = Database_Shaman,
		["Druid"] = Database_Druid,
		["Monk"] = Database_Monk,
		["Paladin"] = Database_Paladin,
		["Mage"] = Database_Mage,
		["DeathKnight"] = Database_DeathKnight,
		["Hunter"] = Database_Hunter,
		["Rogue"] = Database_Rogue,
		["Warlock"] = Database_Warlock,
		["Warrior"] = Database_Warrior,
		["DemonHunter"] = Database_DemonHunter,
	}
	local db = meta_lookup[class]
	if db ~= nil then
		RTRank.lookupState.db = db
	else
		print("RTRank: No data available for class: " .. class)
	end

end

function RTRank:step() --todo refactor further
	---main (recursive) loop
	if RTRank.lookupState.is_combat then
		local lookup_state = RTRank.lookupState
        local db = lookup_state.db
		local spec = RTRank.utils:get_player_spec()

		local encounter_id = lookup_state.active_encounter
		--local encounter_diff = lookup_state.difficultyID

		-- dummy for testing
		if encounter_id == -1 then -- we are not in encounter
			if RTRank.config.dummy_enabled then
				encounter_id = RTRank.config.dummy_encounter
			end
		end


		if db.lookup[spec] ~= nil then
			local valid_encounter = db.lookup[spec][encounter_id] ~= nil
			if encounter_id ~= -1 and valid_encounter then  -- 16 = mythic, we only have this data
				RTRank.encounterState.in_session = true
				-- Adjust to closest rank if input rank doesn't exist
				local target_series_rank_count = db.lookup[spec][encounter_id].rank_count

				if target_series_rank_count < RTRank.config.match_ranking then
					print("RTRank: No data available for requested rank " ..
							RTRank.config.match_ranking .. " using closest (" .. target_series_rank_count .. ")")
					RTRank.config.match_ranking = target_series_rank_count
				end

				local target_series = db.lookup[spec][encounter_id][RTRank.config.match_ranking]

				if target_series ~= nil then
					updateDisplay(db, encounter_id, target_series)
				else
					end_combat_session(false)
				end
			else
				end_combat_session(false)
			end
		else
			print("RTRank: Could not find data for spec: " .. spec)
		end
	end
end

function updateDisplay(db, encounter_id, target_series)
	local seconds = RTRank.utils:get_current_time_step()
	local class = RTRank.utils:get_player_class()
	local spec = RTRank.utils:get_player_spec()
	local role = RTRank.utils:get_role(class, spec)

	local target_series_len = db.lookup[spec][encounter_id].length

	local cumulative_amt = get_current_amount(role)
	local timeSerVal = -1
	if seconds < target_series_len then
		timeSerVal = target_series[seconds + 1] -- 1 indexed..
	else
		timeSerVal = RTRank:extrapolateLinearCumulative(target_series, seconds, target_series_len)
	end

	--update state
	RTRank.encounterState:updateState(cumulative_amt, timeSerVal)
	local state = RTRank.encounterState

	--update text display
	RTRank:renderText(state)

	--update bar display
	local pct_diff = RTRank.utils:convert_aps_to_bar_pct(state.player_aps, state.target_aps)
	RTRank:setBarValue(pct_diff)

	C_Timer.After(1, RTRank.step) --todo handle last partial second, these events are lost atm
end

function RTRank:renderText(state)
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
end

function RTRank:extrapolateLinearCumulative(target_ser, t, target_ser_len)
	local lastVal = target_ser[target_ser_len - 1]
	local finalAPS = target_ser[target_ser_len - 1] / target_ser_len
	local extraSeconds = t - target_ser_len

	return lastVal + (finalAPS * extraSeconds)
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
end


function end_combat_session(override_text)  --different from end combat, this should be called on invalid session (e.g not encounter)
	RTRank.encounterState.in_session = false

	local encounter = RTRank.lookupState.active_encounter
	if encounter ~= -1 and RTRank.raid_difficulties[RTRank.lookupState.difficultyID] ~= nil then
		print("RTRank: Ending combat session for encounter " .. encounter)
	end

	if not override_text then
        RTRank:updateText(RTRank:getDefaultText())
	end

	-- reset states
	RTRank.encounterState.player_amount = -1
	RTRank.encounterState.target_amount = -1
	RTRank.encounterState.diff = -1
	RTRank.encounterState.player_aps = -1
	RTRank.encounterState.target_aps = -1
	RTRank.encounterState.aps_diff = -1

	RTRank.lookupState.active_encounter = -1
	RTRank.lookupState.difficultyID = -1
	RTRank.lookupState.startTime = nil
	RTRank.lookupState.combatStartTime = -1

end