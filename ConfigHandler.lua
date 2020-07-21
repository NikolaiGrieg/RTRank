function RTRank.config:handleSlashCommand(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "rank" then
		local target_rank = tonumber(args)
		if target_rank then
			self:updateRank(target_rank)
		else
			print("RTRank: Input \"" .. args .. "\" was not recognized as a number")
		end
	elseif cmd  == "background" then

	elseif cmd == "output" then

	end
end

function RTRank.config:getDefaultText()
    return "Target rank: " .. self.match_ranking
end

function RTRank.config:updateRank(rank)
	if rank > 0 then
		RTRank.config.match_ranking = rank  -- can't validate, as lookup is inferred at encounter time
		if not RTRank.lookupState.is_combat then
			RTRank:setDefaultText()
		else
			print("RTRank: Hotswapped target rank to: " .. RTRank.config.match_ranking)
		end
		print("RTRank: Set target rank to: " .. RTRank.config.match_ranking)
	else
		print("Requested rank needs to be at least 1 (got " .. rank .. ")")
	end



end