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

    -- todo check avaiable indexes
    RTRank.config.match_ranking = rank
    if not RTRank.lookupState.is_combat then
        RTRank:setDefaultText()
    else
        print("RTRank: Hotswapped target rank to: " .. RTRank.config.match_ranking)
    end
    print("RTRank: Set target rank to: " .. RTRank.config.match_ranking)
end