--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.GameEnum)
local net = require(ReplicatedStorage.Packages.net)
local GuiHandler = {}

local PlayerGui, BetScreen, Hit, Pass, plr, action, SetVis, Leave, leaveRequest, Status, statusRequest, dealerCount, playerCount

function GuiHandler:Init()
	print("GUI TRIGGER")
	plr = game.Players.LocalPlayer
	PlayerGui = plr.PlayerGui
	BetScreen = PlayerGui.BetScreen
	Hit = BetScreen.Hit
	Pass = BetScreen.Pass
	Leave = BetScreen.Leave
	Status = BetScreen.Status

	print("initl val done")

	action = net:RemoteEvent("action")
	SetVis = net:RemoteEvent("SetVisibility")
	leaveRequest = net:RemoteEvent("leaveRequest")
	statusRequest = net:RemoteEvent("clientStatus")
	playerCount = net:RemoteEvent("playerCount")
	dealerCount = net:RemoteEvent("dealerCount")

	print("inital net done")

	SetVis.OnClientEvent:Connect(function(bool: boolean)
		print("Changed vis")
		BetScreen.Enabled = bool
	end)

	statusRequest.OnClientEvent:Connect(function(text)
		Status.Text = text
	end)

	playerCount.OnClientEvent:Connect(function(text)
		BetScreen.PlayerCard.Count.Text = text
	end)

	dealerCount.OnClientEvent:Connect(function(text)
		BetScreen.DealerCard.Count.Text = text
	end)

	GuiHandler:Watch()

	print("GUI HANDLER LOADED")
end

function GuiHandler:Watch()
	Hit.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			action:FireServer(GameEnum.blackjackActions.hit, {})
			print("Hit clicked from client")
		end
	end)

	Pass.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			action:FireServer(GameEnum.blackjackActions.pass, {})
			print("Pass clicked from client")
		end
	end)

	Leave.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			leaveRequest:FireServer()
		end
	end)
end

return GuiHandler
