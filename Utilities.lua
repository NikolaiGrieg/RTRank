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