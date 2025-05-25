--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.GameEnum)
local net = require(ReplicatedStorage.Packages.net)
local GuiHandler = {}

local PlayerGui, BetScreen, Hit, Pass, Double, Split, plr, action, SetVis

function GuiHandler:Init()
	plr = game.Players.LocalPlayer
	PlayerGui = plr.PlayerGui
	BetScreen = PlayerGui.BetScreen
	Hit = BetScreen.Hit
	Pass = BetScreen.Pass
	Double = BetScreen.Double
	Split = BetScreen.Split
	action = net:RemoteEvent("action")
	SetVis = net:RemoteEvent("SetVisibility")

	SetVis.OnClientEvent:Connect(function(bool: boolean)
		GuiHandler:SetVisibility(bool)
	end)

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
end

return GuiHandler
