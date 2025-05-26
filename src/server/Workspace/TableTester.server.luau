local ServerScriptService = game:GetService("ServerScriptService")
local BlackjackGame = require(ServerScriptService.Classes.BlackjackGame)

for i, v in pairs(game.Workspace:GetDescendants()) do
	if v.Name == "BlackjackGame" then
		local bj = BlackjackGame.new(v)
		bj:Init()
	end
end
