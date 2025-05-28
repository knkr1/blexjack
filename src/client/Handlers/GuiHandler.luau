--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.GameEnum)
local net = require(ReplicatedStorage.Packages.net)
local GuiHandler = {}

local PlayerGui, PlayScreen, Hit, Pass, plr, action, SetVis, Leave, leaveRequest, Status, statusRequest, dealerCount, playerCount
local BetScreen, BetFrame, PreviousBet, DoubleBet, NewBet, setBetVisibility

function GuiHandler:Init()
	print("GUI TRIGGER")
	plr = game.Players.LocalPlayer
	PlayerGui = plr.PlayerGui
	PlayScreen = PlayerGui.PlayScreen
	Hit = PlayScreen.Hit
	Pass = PlayScreen.Pass
	Leave = PlayScreen.Leave
	Status = PlayScreen.Status

	BetScreen = PlayerGui.BetScreen
	BetFrame = BetScreen.BetFrame
	PreviousBet = BetFrame.PreviousBet
	DoubleBet = BetFrame.DoubleBet
	NewBet = BetFrame.NewBet

	print("initl val done")

	action = net:RemoteEvent("action")
	SetVis = net:RemoteEvent("SetVisibility")
	leaveRequest = net:RemoteEvent("leaveRequest")
	statusRequest = net:RemoteEvent("clientStatus")
	playerCount = net:RemoteEvent("playerCount")
	dealerCount = net:RemoteEvent("dealerCount")

	setBetVisibility = net:RemoteEvent("setBetVisibility")
	print("inital net done")

	SetVis.OnClientEvent:Connect(function(bool: boolean)
		print("Changed vis")
		PlayScreen.Enabled = bool
	end)

	statusRequest.OnClientEvent:Connect(function(text)
		Status.Text = text
	end)

	playerCount.OnClientEvent:Connect(function(text)
		PlayScreen.PlayerCard.Count.Text = text
	end)

	dealerCount.OnClientEvent:Connect(function(text)
		PlayScreen.DealerCard.Count.Text = text
	end)

	setBetVisibility.OnClientEvent:Connect(function(bool: boolean)
		if bool == false then
			BetScreen.Enabled = false
		else
		end
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

	--BetSceen

	PreviousBet.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			leaveRequest:FireServer()
		end
	end)

	NewBet.BetButton.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			leaveRequest:FireServer()
		end
	end)

	DoubleBet.InputBegan:Connect(function(InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			leaveRequest:FireServer()
		end
	end)
end

return GuiHandler
