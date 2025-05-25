local ReplicatedStorage = game:GetService("ReplicatedStorage")
local net = require(ReplicatedStorage.Packages.net)
local NetworkSetupService = {}

function NetworkSetupService:Init()
	net:RemoteEvent("action")
	net:RemoteEvent("SetVisibility")
end

return NetworkSetupService
