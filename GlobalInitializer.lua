Constants = {
	["Rolemap"] = {
		["Priest"] = {
			["Discipline"] = "healer",
			["Holy"] = "healer",
			["Shadow"] = "damage"
		},
		["Shaman"] = {
			["Restoration"] = "healer",
			["Enhancement"] = "damage",
			["Elemental"] = "damage"
		}
	} --todo rest
}

local frame, events = CreateFrame("FRAME", "RTRankMain"), {};
RTRank = {}
RTRank.frame = frame
RTRank.events = events

RTRank.encounterState = {
	["player_amount"] = -1,
	["target_amount"] = -1,
	["diff"] = -1,
	["player_aps"] = -1,
	["target_aps"] = -1,
	["aps_diff"] = -1,
}

RTRank.lookupState = {
	["active_encounter"] = -1,
	["difficultyID"] = -1,
	["startTime"] = nil,
	["combatStartTime"] = -1
}

--config
if RTRankConfig ~= nil then
	RTRank.config = RTRankConfig
	--print("using stored RTRankConfig")
else
	RTRank.config = {
		["match_ranking"] = 1,
		["dummy_encounter"] = 2329,
		["dummy_enabled"] = true,
		["background_enabled"] = true,
		["output_type"] = "second",  -- second, cumulative
	}

	RTRankConfig = RTRank.config -- todo does this reference or copy?
	--print("stored: " .. RTRankConfig.match_ranking)
	--print("RTRank: " .. RTRank.config.match_ranking)
end


-- slash commands
SLASH_RTRANK1 = "/rtr";
function SlashCmdList.RTRANK(msg)
	RTRank.config:handleSlashCommand(msg)
end
