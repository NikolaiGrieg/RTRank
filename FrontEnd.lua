--vars
inCombat = false


function RTRank:updateText(msg)
	self.frame.text:SetText(msg)
	local width = self.frame.text:GetStringWidth()
	self.frame:SetWidth(width)
end

function RTRank.events:PLAYER_ENTERING_WORLD(...)
	local f = RTRank.frame
	f:SetFrameStrata("BACKGROUND")
	f:SetWidth(140) -- Set these to whatever height/width is needed
	f:SetHeight(64) -- for your Texture

	if RTRank.config.background_enabled then
		local t = f:CreateTexture(nil,"BACKGROUND")
		t:SetColorTexture(0,0,0, 0.5)
		t:SetAllPoints(f)
		f.texture = t
	end

	f:SetPoint("CENTER",200,-100)

	f.text = f:CreateFontString(nil,"ARTWORK")
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	RTRank:setDefaultText()

	f:Show()
end
function RTRank.events:PLAYER_REGEN_DISABLED (...) --enter combat -- TODO refactor these
	inCombat = true
	RTRank.lookupState.is_combat = true
	RTRank.lookupState.combatStartTime = GetTime()

	RTRank:step()
end

function RTRank.events:PLAYER_REGEN_ENABLED (...) -- left combat
	inCombat = false
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
end

function RTRank:setDefaultText()
	self.frame.text:SetText(self.config:getDefaultText())
end


function RTRank:initEvents()
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetScript("OnDragStart", self.frame.StartMoving)
	self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)

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