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

--config defaults, overridden from saved variable RTRankConfig on PlayerEnterWorld
RTRank.default_config = {
		["match_ranking"] = 1,
		["dummy_encounter"] = 2329,
		["dummy_enabled"] = false,
		["background_enabled"] = true,
		["output_type"] = "second",  -- second, cumulative,
		["xOfs"] = 880,
		["yOfs"] = -450
	}
RTRank.config = RTRank.default_config


-- slash commands
SLASH_RTRANK1 = "/rtr";
SLASH_RTRANK2 = "/rtrank";
function SlashCmdList.RTRANK(msg)
	RTRank:handleSlashCommand(msg)
end
