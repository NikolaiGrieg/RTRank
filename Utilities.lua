RTRank.utils = {}

function RTRank.utils:get_player_class( ... )
	local playerClass, _ = UnitClass("player");
	local playerClassNoSpace = playerClass:gsub("%s+", "")
	return playerClassNoSpace
end

function RTRank.utils:get_player_spec()
	local currentSpec = GetSpecialization()
	local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
	return currentSpecName
end

function RTRank.utils:get_role(player_class, player_spec )
	local role = Constants["Rolemap"][player_class][player_spec]
	if role == nil then
		print("RTRank: Unable to find role in rolemap for class: " .. player_class .. ", spec: " .. player_spec)
	end
	return role
end

function RTRank.utils:format_amount( num )
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

function RTRank.utils:get_current_time_step()
	--- uses encounter start if in encounter, else combat start

	local encounterStart = RTRank.lookupState.startTime
	local nowTime = GetTime()

	if encounterStart ~= nil then
		return math.floor(nowTime - encounterStart)
	else
		return math.floor(nowTime - RTRank.lookupState.combatStartTime)
	end
end

function RTRank.utils:get_name_from_rank(rank, encounter_id)
	local db = RTRank.lookupState.db
	local spec = self:get_player_spec() -- todo class?
	local target_series = db.lookup[spec][encounter_id][rank]
	local name = target_series["name"]
	return name
end

function RTRank.utils:convert_aps_to_bar_pct(player_aps, target_aps)
	--- Converts to bar friendly format, where display is relative to 100.
	--- Some examples:
	--- given player = 100k and target = 200k => player is 50% of target => return -50%
	--- given player = 100k and target = 70k => player is 143% of target => return +43%

	if target_aps == 0 then
		return 100
	end

	local base_pct = player_aps / target_aps * 100
	if base_pct > 100 then
		return base_pct - 100
	else
		return - (100 - base_pct)
	end
end