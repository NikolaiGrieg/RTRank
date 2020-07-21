function RTRank:handleSlashCommand(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "rank" then
		local target_rank = tonumber(args)
		if target_rank then
			self:updateRank(target_rank)
		else
			print("RTRank: Input \"" .. args .. "\" was not recognized as a number")
		end
	elseif cmd  == "background" then -- todo switch?
		self.config.background_enabled = not self.config.background_enabled
		RTRank:updateBackground()
		if self.config.background_enabled then
			print("Toggled background on")
		else
			print("Toggled background off")
		end
	elseif cmd == "output" then
		print("PH output")
	elseif cmd == "dumpdb" then -- todo parse spec
		print("PH dumpdb") -- todo print db in a nice format
	end
	self.updateStoredVars()
end

function RTRank:updateStoredVars()
	RTRankConfig = RTRank.config
end

function RTRank:getDefaultText()
    return "Target rank: " .. self.config.match_ranking
end

function RTRank:updateRank(rank)
	if rank > 0 then
		RTRank.config.match_ranking = rank  -- can't validate, as lookup is inferred at encounter time
		if not RTRank.lookupState.is_combat then
			RTRank:setDefaultText()
		else
			print("RTRank: Hotswapping target rank")
		end
		print("RTRank: Set target rank to: " .. RTRank.config.match_ranking)
	else
		print("Requested rank needs to be at least 1 (got " .. rank .. ")")
	end
end


function RTRank:loadStoredConfig()
	if RTRankConfig ~= nil then
		self.config = RTRankConfig
		print("using stored RTRankConfig")
	else
		print("no stored vars found")
		RTRankConfig = self.config
	end
end