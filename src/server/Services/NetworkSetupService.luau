local ReplicatedStorage = game:GetService("ReplicatedStorage")
local net = require(ReplicatedStorage.Packages.net)
local NetworkSetupService = {}

function NetworkSetupService:Init()
	local actionWatch = net:RemoteEvent("action")
	local setVisiblity = net:RemoteEvent("SetVisibility")
	local setProximity = net:RemoteEvent("setProximity")
	local leaveRequest = net:RemoteEvent("leaveRequest")
	local clientStatus = net:RemoteEvent("clientStatus")
	local dealerCount = net:RemoteEvent("dealerCount")
	local playerCount = net:RemoteEvent("playerCount")
end

return NetworkSetupService
