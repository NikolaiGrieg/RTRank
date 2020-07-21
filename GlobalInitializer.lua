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
RTRank.config = {
	["match_ranking"] = 1,
	["dummy_encounter"] = 2329,
	["dummy_enabled"] = true,
	["background_enabled"] = true,
	["output_type"] = "second",  -- second, cumulative
}
RTRank.config["default_text"] = "Target rank: " .. RTRank.config.match_ranking