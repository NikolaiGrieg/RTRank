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