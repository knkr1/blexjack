--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local CardGenerator = require(ServerScriptService.Classes.CardGenerator)
local Part = game.Workspace.Part
local ClickDetector = Part.ClickDetector

local cards = CardGenerator.new()
ClickDetector.MouseClick:Connect(function()
	print(cards:PullCard())
end)
