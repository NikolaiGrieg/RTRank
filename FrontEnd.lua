function RTRank:updateText(msg)
	self.frame.text:SetText(msg)
	local width = self.frame.text:GetStringWidth()
	self.frame:SetWidth(width)
end

-- todo event handlers should maybe not be in front end file
function RTRank.events:PLAYER_ENTERING_WORLD(...)
	RTRank:loadStoredConfig()
	RTRank:renderFrame()
end

function RTRank:renderFrame()
	local f = self.frame
	f:SetFrameStrata("BACKGROUND")
	f:SetWidth(140) -- Set these to whatever height/width is needed
	f:SetHeight(64) -- for your Texture

	local t = f:CreateTexture(nil,"BACKGROUND")
	t:SetColorTexture(0,0,0, 0.5)
	t:SetAllPoints(f)
	f.texture = t
	if not RTRank.config.background_enabled then
		t:Hide()
	end

	f:SetPoint("CENTER",200,-100)

	f.text = f:CreateFontString(nil,"ARTWORK")
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	RTRank:setDefaultText()

	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", self.frame.StartMoving)
	f:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
	f:Show()
end

function RTRank:updateBackground()
	local on = self.config.background_enabled
	if on then
		RTRank.frame.texture:Show()
	else
		RTRank.frame.texture:Hide()
	end
end

function RTRank.events:PLAYER_REGEN_DISABLED (...) --enter combat -- TODO refactor these
	RTRank.lookupState.is_combat = true
	RTRank.lookupState.combatStartTime = GetTime()

	RTRank:step()
end

function RTRank.events:PLAYER_REGEN_ENABLED (...) -- left combat
	RTRank.lookupState.is_combat = false
	RTRank.lookupState.active_encounter = -1
	RTRank.lookupState.difficultyID = -1
	local t = RTRank.utils:get_current_time_step()
	local state = RTRank.encounterState

	if RTRank.encounterState.in_session then  -- execute final commands before ending session
		local msg = ""
		if RTRank.config.output_type == "cumulative" then -- todo refactor strings
			msg = "Final value against rank " .. RTRank.config.match_ranking ..  " ("
					.. RTRank.utils:get_name_from_rank(RTRank.config.match_ranking, RTRank.config.dummy_encounter) .. ")" .. ":\n" ..
			" At t = " .. t .. ":" .. "\nTarget: " .. RTRank.utils:format_amount(state.target_amount) ..
			"\nYou: " .. RTRank.utils:format_amount(state.player_amount) .. "\nDiff: " .. RTRank.utils:format_amount(stat.diff);
		elseif RTRank.config.output_type == "second" then
			msg = "Final value against rank " .. RTRank.config.match_ranking  .. " ("
					.. RTRank.utils:get_name_from_rank(RTRank.config.match_ranking, RTRank.config.dummy_encounter) .. ")".. ":\n" ..
			" At t = " .. t .. ":" .. "\nTarget: " .. RTRank.utils:format_amount(state.target_aps) ..
			"\nYou: " .. RTRank.utils:format_amount(state.player_aps) .. "\nDiff: " .. RTRank.utils:format_amount(state.aps_diff);
		end
		RTRank:updateText(msg)

		end_combat_session(true)
	end
end

function RTRank.events:ENCOUNTER_START (...)
	local encounterID, _ , difficultyID, _ = ...
	RTRank.lookupState.active_encounter = encounterID
	RTRank.lookupState.difficultyID = difficultyID
	RTRank.lookupState.startTime = GetTime()
	print("RTRank: Initialized encounter " .. encounterID .. ", with difficulty: " .. difficultyID)
	if difficultyID ~= 5 then
		print("RTRank: Non-mythic difficulty detected, using mythic data as this is the only available.")
	end
end

function RTRank:setDefaultText()
	self:updateText(self:getDefaultText())
end


function RTRank:initEvents()
	local events = RTRank.events

	self.frame:SetScript("OnEvent", function(self, event, ...)
 		events[event](self, ...); -- call one of the functions above
	end);
	for k, v in pairs(events) do
	 	self.frame:RegisterEvent(k); -- Register all events for which handlers have been defined
	end
end

--TODOs:
--Feature 2: functionality to specify rank for comparison as user-setting (maybe just have a config file at first)
--Then presentation could use some polish
--Feature 3 (if we get this far): Dynamically infer final rank based on cumulative amount proximity at t (copy python implementation)

--todo option to not show in raids