function RTRank:updateText(msg)
	self.frame.text:SetText(msg)
	local width = self.frame.text:GetStringWidth()
	self.frame:SetWidth(width)
end

-- event handlers should maybe not be in frontend file
function RTRank.events:PLAYER_ENTERING_WORLD(...)
	local isInitialLogin, isReloadingUi = ...
	if isInitialLogin or isReloadingUi then -- all frames should be created here
		RTRank:loadStoredConfig()
		RTRank:loadDataBase()
		RTRank:renderFrame()

		-- status bar
		RTRank:initStatusBar()
		RTRank:setBarValue(0)
	end
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

	f:SetPoint("TOPLEFT", RTRank.config.xOfs, RTRank.config.yOfs)

	f.text = f:CreateFontString(nil,"ARTWORK")
	f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
	f.text:SetPoint("CENTER",0,0)
	RTRank:setDefaultText()

	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", self.frame.StartMoving)
	f:SetScript("OnDragStop", dragStop)

	self:updateTextFieldEnabled()
end

function dragStop()
	local _, _, _, xOfs, yOfs = RTRank.frame:GetPoint()

	RTRank:setFramePosition(xOfs, yOfs)
	RTRank.frame:StopMovingOrSizing()
end

function RTRank:updateBackground()
	local on = self.config.background_enabled
	if on then
		RTRank.frame.texture:Show()
	else
		RTRank.frame.texture:Hide()
	end
end

function RTRank:updateTextFieldEnabled()
	local on = self.config.text_enabled
	if on then
		RTRank.frame:Show()
	else
		RTRank.frame:Hide()
	end
end

function RTRank.events:PLAYER_REGEN_DISABLED (...) --enter combat -- TODO refactor these
	RTRank.lookupState.is_combat = true
	RTRank.lookupState.combatStartTime = GetTime()


	RTRank:step() -- first step
end

function RTRank.events:PLAYER_REGEN_ENABLED (...) -- left combat
	local state = RTRank.encounterState

	if RTRank.encounterState.in_session then  -- execute final commands before ending session
		local msg = ""
		if RTRank.config.output_type == "cumulative" then
			msg = createFinalMessage(RTRank.config.match_ranking, state.player_amount, state.target_amount, state.diff)
		elseif RTRank.config.output_type == "second" then
			msg = createFinalMessage(RTRank.config.match_ranking, state.player_aps, state.target_aps, state.aps_diff)
		end
		RTRank:updateText(msg)

		end_combat_session(true)
	end

	RTRank.lookupState.is_combat = false
	RTRank.lookupState.active_encounter = -1
	RTRank.lookupState.difficultyID = -1
end

function createFinalMessage(rank, player, target, diff)
	local encounter_id = RTRank.lookupState.active_encounter -- we should have this by this point
	if encounter_id == -1 and RTRank.config.dummy_enabled then
		encounter_id = RTRank.config.dummy_encounter
	end
	local t = RTRank.utils:get_current_time_step()

	local msg = "Final value against rank " .. rank ..  " ("
			.. RTRank.utils:get_name_from_rank(rank, encounter_id) .. ")" .. ":\n" ..
	" After " .. t .. " seconds:" .. "\nTarget: " .. RTRank.utils:format_amount(target) ..
	"\nYou: " .. RTRank.utils:format_amount(player) .. "\nDiff: " .. RTRank.utils:format_amount(diff);
	return msg
end

function RTRank.events:ENCOUNTER_START (...)
	local encounterID, _ , difficultyID, _ = ...
	RTRank.lookupState.active_encounter = encounterID
	RTRank.lookupState.difficultyID = difficultyID
	RTRank.lookupState.startTime = GetTime()
	if RTRank.raid_difficulties[difficultyID] ~= nil then -- nil if difficultyID not a raid ID
		print("RTRank: Initialized encounter " .. encounterID .. ", with difficulty: " .. difficultyID) -- todo extract
		if difficultyID ~= 16 then
			print("RTRank: Non-mythic difficulty detected, using mythic data as this is the only available data.")
		end
		print(RTRank.utils:get_encounter_start_text())
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
--Load data for all classes
--Then presentation could use some polish
--Feature 3 (if we get this far): Dynamically infer final rank based on cumulative amount proximity at t (copy python implementation)

--todo option to not show in raids