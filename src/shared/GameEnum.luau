local GameEnum = {}

GameEnum.blackjackActions = {
	["none"] = "none",
	["split"] = "split",
	["pass"] = "pass",
	["hit"] = "hit",
	["double"] = "double",
	["insurance"] = "insurance",
}

GameEnum.blackjackRequestActions = {
	["bet"] = "bet",
}

return GameEnum
