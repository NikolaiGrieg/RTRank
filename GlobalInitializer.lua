Constants = {
	["Rolemap"] = { -- these can be generated by running py/static/PlayerClass.py
		["Priest"] = {
			["Discipline"] = "healer",
			["Holy"] = "healer",
			["Shadow"] = "damage",
		},
		["Monk"] = {
			["Brewmaster"] = "damage",
			["Mistweaver"] = "healer",
			["Windwalker"] = "damage",
		},
		["Shaman"] = {
			["Elemental"] = "damage",
			["Enhancement"] = "damage",
			["Restoration"] = "healer",
		},
		["Paladin"] = {
			["Holy"] = "healer",
			["Protection"] = "damage",
			["Retribution"] = "damage",
		},
		["Druid"] = {
			["Balance"] = "damage",
			["Feral"] = "damage",
			["Guardian"] = "damage",
			["Restoration"] = "healer",
		},
		["Mage"] = {
			["Arcane"] = "damage",
			["Fire"] = "damage",
			["Frost"] = "damage",
		},
		["DeathKnight"] = {
			["Blood"] = "damage",
			["Frost"] = "damage",
			["Unholy"] = "damage",
		},
		["Hunter"] = {
			["Beast Mastery"] = "damage",
			["Marksmanship"] = "damage",
			["Survival"] = "damage",
		},
		["Rogue"] = {
			["Assassination"] = "damage",
			["Combat"] = "damage",
			["Subtlety"] = "damage",
		},
		["Warlock"] = {
			["Affliction"] = "damage",
			["Demonology"] = "damage",
			["Destruction"] = "damage",
		},
		["Warrior"] = {
			["Arms"] = "damage",
			["Fury"] = "damage",
			["Protection"] = "damage",
		},
		["DemonHunter"] = {
			["Havoc"] = "damage",
			["Vengeance"] = "damage",
		}
	}
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
		["text_enabled"] = true,
		["background_enabled"] = true,
		["output_type"] = "second",  -- second, cumulative,
		["xOfs"] = 880,
		["yOfs"] = -450,
		["bar_xOfs"] = 880,
		["bar_yOfs"] = -550,
	}
RTRank.config = RTRank.default_config


-- slash commands
SLASH_RTRANK1 = "/rtr";
SLASH_RTRANK2 = "/rtrank";
function SlashCmdList.RTRANK(msg)
	RTRank:handleSlashCommand(msg)
end
