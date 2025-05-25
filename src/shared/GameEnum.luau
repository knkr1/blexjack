local GameEnum = {}

GameEnum.blackjackActions = {
	["none"] = "none",
	["split"] = "split",
	["stay"] = "stay",
	["hit"] = "hit",
	["double"] = "double",
	["insurance"] = "insurance",
}

GameEnum.blackjackRequestActions = {
	["bet"] = "bet",
}

return GameEnum
