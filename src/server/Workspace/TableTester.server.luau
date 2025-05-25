local ServerScriptService = game:GetService("ServerScriptService")
local BlackjackGame = require(ServerScriptService.Classes.BlackjackGame)
local tbl = game.Workspace.BlackjackGame

print("doing")
local bj = BlackjackGame.new(tbl)
bj:Init()
print("made")
