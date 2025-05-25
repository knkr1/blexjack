--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.GameEnum)
local net = require(ReplicatedStorage.Packages.net)
local GuiHandler = {}

local PlayerGui, BetScreen, Hit, Pass, Double, Split, plr, action, SetVis, Leave, leaveRequest, Status, statusRequest

function GuiHandler:Init()
	plr = game.Players.LocalPlayer
	PlayerGui = plr.PlayerGui
	BetScreen = PlayerGui.BetScreen
	Hit = BetScreen.Hit
	Pass = BetScreen.Pass
	Double = BetScreen.Double
	Split = BetScreen.Split
	Leave = BetScreen.Leave
	Status = BetScreen.Status

	action = net:RemoteEvent("action")
	SetVis = net:RemoteEvent("SetVisibility")
	leaveRequest = net:RemoteEvent("leaveRequest")
	statusRequest = net:RemoteEvent("clientStatus")

	SetVis.OnClientEvent:Connect(function(bool: boolean)
		GuiHandler:SetVisibility(bool)
	end)

	statusRequest.OnClientEvent:Connect(function(text)
		Status.Text = text
	end)

	GuiHandler:Watch()

	print("GUI HANDLER LOADED")
end

function GuiHandler:SetVisibility(bool: boolean)
	BetScreen.Enabled = bool
	print("Changed Visibility")
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
		end
	end)

	Split.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			action:FireServer(GameEnum.blackjackActions.split, {})
		end
	end)

	Double.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			action:FireServer(GameEnum.blackjackActions.double, {})
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
