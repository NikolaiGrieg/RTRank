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
		if args == "second" then
			self.config.output_type = "second"
			print("Switched to output type \"second\"")
		elseif args == "cumulative" or args == "total" then
			self.config.output_type = "cumulative"
			print("Switched to output type \"cumulative\"")
		else
			print("RTRank: output type not recognized, allowed types are: second, cumulative (total)")
		end
	elseif cmd == "reset" then
		self:resetState()
	elseif cmd == "dummy" then
		self.config.dummy_enabled = not self.config.dummy_enabled
		if self.config.dummy_enabled then
			print("Toggled dummy mode on")
		else
			print("Toggled dummy mode off")
		end
	elseif cmd == "text" then
		self.config.text_enabled = not self.config.text_enabled
		if self.config.text_enabled then
			print("Toggled text display on")
		else
			print("Toggled text display off")
		end
		RTRank:updateTextFieldEnabled()
	elseif cmd == "printconfig" then
		for k, v in pairs( RTRank.config ) do  -- todo consider implementing custom rjust function
			print( k .. ":", v)
		end
	elseif cmd == "dumpdb" then -- todo parse spec
		print("PH dumpdb") -- todo print db in a nice format
	end
	self:updateStoredVars()
end

function RTRank:resetState()
	print("Resetting to default settings")
	self.config = self.default_config
	self.frame:SetPoint("CENTER", self.config.xOfs, self.config.yOfs)
	self.updateStoredVars()
end

function RTRank:setFramePosition(xOfs, yOfs)
	self.config.xOfs = xOfs
	self.config.yOfs = yOfs

	self.updateStoredVars()
end

function RTRank:setBarPosition(xOfs, yOfs)
	self.config.bar_xOfs = xOfs
	self.config.bar_yOfs = yOfs

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
	else
		RTRankConfig = self.config
	end
end