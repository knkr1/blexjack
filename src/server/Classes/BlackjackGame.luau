local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[
BlackjackGame.lua

This supposed to handle all tables by creating them inside
]]

local GameEnum = require(ReplicatedStorage.GameEnum)
local net = require(ReplicatedStorage.Packages.net)
local CardGenerator = require(script.Parent.CardGenerator)
local actionWatch = net:RemoteEvent("action")
local setVisiblity = net:RemoteEvent("SetVisibility")
local setProximity = net:RemoteEvent("setProximity")
local leaveRequest = net:RemoteEvent("leaveRequest")
local clientStatus = net:RemoteEvent("clientStatus")

local waitingTime = 10

local BlackjackGame = {}

BlackjackGame.__index = BlackjackGame

type Username = string

type blackjackTable = Part & {
	Chair: Part & {
		Front: Attachment,
	},
	Table: Part & {
		Dealer: Attachment,
		Front: Attachment,
		Player1: Attachment,
		Player2: Attachment,
		Player3: Attachment,
		Player4: Attachment,
		tableJoin: ProximityPrompt,
		Info: BillboardGui & {
			MainFrame: Frame & {
				Status: TextBox,
			},
		},
	},
	player1: Part & {
		Front: Attachment,
	},
	player2: Part & {
		Front: Attachment,
	},
	player3: Part & {
		Front: Attachment,
	},
	player4: Part & {
		Front: Attachment,
	},
	Border: Folder & {
		border: UnionOperation,
		Front: Attachment,
	},
}
type self = {
	players: {
		plr: Player,
		cards: { string },
	},
	dealer: { string },
	isGame: boolean,
	isDealer: boolean,
	blackjackTable: Part,
	indexTurn: number,
	canStart: boolean,
}

export type BlackjackGame = typeof(setmetatable({} :: self, BlackjackGame))

function BlackjackGame.new(blackjackTable: blackjackTable, isDealer: boolean?): BlackjackGame
	local self = {}

	--Whetever if there will be a dealer (Which requires 1 player) or with other people (Atleast 2 players)
	--Theres only dealer games atm. Community is not functional.
	if isDealer == nil then
		isDealer = true
	end

	self.isDealer = isDealer
	self.players = {}
	self.dealer = {}
	self.isGame = false
	self.blackjackTable = blackjackTable
	self.indexTurn = -1
	self.canStart = false

	return setmetatable(self, BlackjackGame)
end

function BlackjackGame:Init()
	--Redefining due intellisense issues
	local blackjackTable: blackjackTable = self.blackjackTable

	--Add user
	blackjackTable.Table.tableJoin.PromptButtonHoldEnded:Connect(function(plr)
		if self.isGame ~= true then
			self:AddPlayer(plr)

			--TODO: plrIndex could create bug in some situtations, will get reviewed.
			self:AttachPlayer(plr)
		end
	end)

	--Remove User
	leaveRequest.OnServerEvent:Connect(function(plr)
		self:RemovePlayer(plr)
		self:DeattachPlayer(plr)
	end)

	task.spawn(function()
		while task.wait() do
			if #self.players > 0 then
				self.canStart = true
			else
				self.canStart = false
			end
		end
	end)
	task.spawn(function()
		while task.wait() do
			--Go for a loop until canStart (enough players)
			while self.canStart == false do
				self:SetStatus("Waiting For Players")

				task.wait()
			end
			--Intermissions, break if can't start
			for i = waitingTime, 0, -1 do
				if self.canStart == false then
					break
				end
				self:SetStatus(i)
				self:SetClientStatus("Game starting in " .. i)
				task.wait(1)
			end

			--Game start, only if can start, else go back to the beginning
			if self.canStart then
				print("wooho game")
			end
		end
	end)
end

function BlackjackGame:AddPlayer(plr: Player): boolean
	if self.isGame then
		warn("BlackjackGame -- Tried to add a player while there's a game.")
		return false
	end

	--To avoid adding the same player twice, let's check.
	if self:FindPlayerInTable(plr) then
		--TODO: Add a bug tracker to see how often it exists.
		warn("BlackjackGame -- Tried to add a player that already exists.")
		return false
	end
	--player object(1), card in hand(2), action(3), bet(4), watch(5)
	table.insert(self.players, {
		plr,
		{},
		GameEnum.blackjackActions.none,
		0,
		actionWatch.OnServerEvent:Connect(function(reqPLR, request, data)
			if reqPLR == plr then
				if GameEnum.blackjackActions[request] then
					local _, plrIndex = self:FindPlayerInTable(self.players)

					--Only write the action if it's player's turn
					if self.indexTurn == plrIndex then
						self:FindPlayerInTable(plr)[4] = request
						print("logged: " .. request)
					end
				elseif request == GameEnum.blackjackRequestActions.bet then
					--TODO: check requested amount, check user's server amount
				end
			end
		end),
	})
	return true
end

--We will make the player sit to the table.
function BlackjackGame:AttachPlayer(plr: Player)
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable

	--defining all due typechecker errors
	local character: Model = plr.Character :: Model
	local primaryPart: BasePart = character.PrimaryPart :: BasePart
	local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	primaryPart.Anchored = true
	humanoid.AutoRotate = false
	local _, index = self:FindPlayerInTable(plr)
	--TODO: doing in this way because of the fucking typechecker. **fix it**
	if index == 1 then
		primaryPart.CFrame = bjTable.player1.CFrame
	elseif index == 2 then
		primaryPart.CFrame = bjTable.player2.CFrame
	elseif index == 3 then
		primaryPart.CFrame = bjTable.player3.CFrame
	elseif index == 4 then
		primaryPart.CFrame = bjTable.player3.CFrame
	else
		warn("BlackjackGame -- Player index out of bounds: " .. index)
	end

	setVisiblity:FireClient(plr, true)
	setProximity:FireClient(plr, false)
end

function BlackjackGame:DeattachPlayer(plr: Player)
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable

	--defining all due typechecker errors
	local character: Model = plr.Character :: Model
	local primaryPart: BasePart = character.PrimaryPart :: BasePart

	primaryPart.CFrame = bjTable.Border.Front.WorldCFrame * CFrame.new(0, 5.5, 0)
	primaryPart.Anchored = false
end

function BlackjackGame:RemovePlayer(plr: Player): boolean
	--Let's find whetever they exists and get their index.
	local plrVal, plrIndex = self:FindPlayerInTable(plr)
	if plrVal then
		plrVal[5]:Disconnect()

		table.remove(self.players, plrIndex)
		return true
	end

	--TODO: Add a bug tracker to see how often it exists.
	warn("BlackjackGame -- Tried to remove a player that doesn't exists.")
	return false
end

--If there's a dealer (1 Player)
function BlackjackGame:DealerGame(): boolean
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable

	if #self.players < 1 then
		warn("BlackjackGame -- Tried to start a DealerGame without any players.")
		return false
	end
	self.isGame = true

	--Fresh new deck of cards!
	local deck = CardGenerator.new()

	--We will deal the cards, we will do it twice since we need 2 card per player + dealer
	for i, v in pairs(self.players) do
		local card: string = deck:PullCard()
		table.insert(v[2], deck:PullCard())
		local cardObject: Part = deck:PullCardAsAnObject(card)
		local attach = bjTable.Table:FindFirstChild("Player" .. i)
		if attach then
			cardObject.Parent = attach
			cardObject.CFrame = attach.WorldCFrame * CFrame.new(ReplicatedStorage.Assets.Cards.ace_spade.Size.X, 0, 0)
		else
			warn("BlackjackGame -- Couldn't find the player index for the table number.")
		end
	end

	local dcard: string = deck:PullCard()
	table.insert(self.dealer, deck:PullCard())
	local dcardObject: Part = deck:PullCardAsAnObject(dcard)
	local dattach = bjTable.Table.Dealer
	dcardObject.Parent = dattach
	dcardObject.CFrame = dattach.WorldCFrame * CFrame.new(ReplicatedStorage.Assets.Cards.ace_spade.Size.X, 0, 0)

	for i, v in pairs(self.players) do
		local card: string = deck:PullCard()
		table.insert(v[2], deck:PullCard())
		local cardObject: Part = deck:PullCardAsAnObject(card)
		local attach = bjTable.Table:FindFirstChild("Player" .. i)
		if attach then
			cardObject.Parent = attach
			cardObject.CFrame = dattach.WorldCFrame
				* CFrame.new(
					ReplicatedStorage.Assets.Cards.ace_spade.Size.X + 0.001,
					ReplicatedStorage.Assets.Cards.ace_spade.Size.Y / 2,
					ReplicatedStorage.Assets.Cards.ace_spade.Size.Z / 2
				)
		else
			warn("BlackjackGame -- Couldn't find the player index for the table number.")
		end
	end

	dcard = deck:PullCard()
	table.insert(self.dealer, deck:PullCard())
	dcardObject = deck:PullCardAsAnObject(dcard)
	dattach = bjTable.Table.Dealer
	dcardObject.Parent = dattach
	dcardObject.CFrame = dattach.WorldCFrame
		* CFrame.new(
			ReplicatedStorage.Assets.Cards.ace_spade.Size.X + 0.001,
			ReplicatedStorage.Assets.Cards.ace_spade.Size.Y / 2,
			ReplicatedStorage.Assets.Cards.ace_spade.Size.Z / 2
		)

	--Cards pulled!
	--TODO: There's no card limit atm. Abusable. (When hitting)

	return true
end

function BlackjackGame:FindPlayerInTable(plr)
	for i, v in pairs(self.players) do
		if v[1] == plr then
			return v, i
		end
	end
	return false
end

type Card = Part & {
	FrontTexture: Texture,
	BackTexture: Texture,
	Bottom: Attachment,
}

function BlackjackGame:HideCard(card: Card): ()
	card.FrontTexture.Transparency = 1
	card.CFrame = card.CFrame * CFrame.Angles(0, 0, math.rad(90))
end

function BlackjackGame:ShowCard(card: Card): ()
	card.FrontTexture.Transparency = 0
	card.CFrame = card.CFrame * CFrame.Angles(0, 0, math.rad(-90))
end

function BlackjackGame:SetStatus(text)
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable
	bjTable.Table.Info.MainFrame.Status.Text = text
end

function BlackjackGame:SetClientStatus(text)
	for i, v in pairs(self.players) do
		clientStatus:FireClient(v[1], text)
	end
end

--Game between players, atleast 2 players.
function BlackjackGame:CommunityGame() end

return BlackjackGame
