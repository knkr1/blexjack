local ReplicatedStorage = game:GetService("ReplicatedStorage")
local net = require(ReplicatedStorage.Packages.net)
local ClientHandler = {}

function ClientHandler:Init()
	--Setting ProximityPrompt
	net:RemoteEvent("setProximity").OnClientEvent:Connect(function(boolean)
		for _, v in pairs(game.Workspace:GetDescendants()) do
			if v:IsA("ProximityPrompt") and v.Name == "tableJoin" then
				v.Enabled = boolean
			end
		end
	end)
end

return ClientHandler
