local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[
BlackjackGame.lua

This supposed to handle all tables by creating them inside
]]

local GameEnum = require(ReplicatedStorage.GameEnum)
local net = require(ReplicatedStorage.Packages.net)
local CardGenerator = require(script.Parent.CardGenerator)
local actionWatch = net:RemoteEvent("action")
local setVisibility = net:RemoteEvent("SetVisibility")
local setProximity = net:RemoteEvent("setProximity")
local leaveRequest = net:RemoteEvent("leaveRequest")
local clientStatus = net:RemoteEvent("clientStatus")
local dealerCount = net:RemoteEvent("dealerCount")
local playerCount = net:RemoteEvent("playerCount")

--TODO: Add settings inside of the blackjack table and pull it from there.
local waitingTime = 10

local BlackjackGame = {}

BlackjackGame.__index = BlackjackGame

--Really long typechecking attempt for the table
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
	player1: Seat & {
		Front: Attachment,
	},
	player2: Seat & {
		Front: Attachment,
	},
	player3: Seat & {
		Front: Attachment,
	},
	player4: Seat & {
		Front: Attachment,
	},
	Border: Folder & {
		border: UnionOperation & {
			Front: Attachment,
		},
	},
}
--Typechecking for player data
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
	processedPlayers: number,
}

export type BlackjackGame = typeof(setmetatable({} :: self, BlackjackGame))

function BlackjackGame.new(blackjackTable: blackjackTable, isDealer: boolean?): BlackjackGame
	local self = {}

	--Whetever if there will be a dealer (Which requires 1 player) or with other people (Atleast 2 players)
	--Theres only dealer games atm. Community is not functional.

	--TODO: ADD COMMUNITY
	if isDealer == nil then
		isDealer = true
	end

	self.isDealer = isDealer
	--The list of players and various information about them
	self.players = {}
	--The card of dealer
	self.dealer = {}
	--Is there game going on atm?
	self.isGame = false
	--The object table
	self.blackjackTable = blackjackTable
	--Which player's turn?
	self.indexTurn = -1
	--Is game is suitable to start? (Enough players?)
	self.canStart = false
	--{is emtpy (false means empty), did made action (false means no)}
	self.indexMap = { { false, false }, { false, false }, { false, false }, { false, false } }
	--How many players did done their round
	self.processedPlayers = 0
	--Can player send action requests?
	self.canAction = false

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
			--this was long time ago idk if I fixed it or not
			self:AttachPlayer(plr)
		end
	end)

	--Remove User
	leaveRequest.OnServerEvent:Connect(function(plr)
		self:DeattachPlayer(plr)
		self:RemovePlayer(plr)
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
				self:SetStatus("Game starting in " .. i)
				self:SetClientStatus("Game starting in " .. i)
				task.wait(1)
			end

			--Game start, only if can start, else go back to the beginning
			if self.canStart then
				self:DealerGame()
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

	--Place player into empty spot, considering not max
	local plrIndex: number
	for i, v in pairs(self.indexMap) do
		if v[1] == false then
			v[1] = true
			plrIndex = i
			break
		end
	end
	if plrIndex == nil then
		warn("BlackjackGame -- Couldn't assign index to the player")
		return false
	end

	--player object(1), card in hand(2), action(3), bet(4), watch(5), player index (6), animObject (7)
	table.insert(self.players, {
		--Player object for easy access
		plr,
		--Player cards as string
		{},
		--Their action "hit", "pass", etc.
		GameEnum.blackjackActions.none,
		--Their bet (not being used atm, planned in further developement)
		0,
		--This thing manages the incoming action requests from the client such as "hit" etc.
		actionWatch.OnServerEvent:Connect(function(reqPLR, request, data)
			--Is this event comes from our own player?
			if reqPLR == plr then
				if GameEnum.blackjackActions[request] then
					local plrIndex = self:FindPlayerInTable(plr)[6]

					--Only write the action if it's player's turn and action is accepted.
					if self.indexTurn == plrIndex and self.canAction then
						self:FindPlayerInTable(plr)[3] = request
						self.canAction = false
						--print("logged: " .. request)
					end
				elseif request == GameEnum.blackjackRequestActions.bet then
					--TODO: check requested amount, check user's server amount
				end
			end
		end),
		plrIndex,
		nil,
	})
	return true
end

function BlackjackGame:RemovePlayer(plr: Player): boolean
	--Let's find whetever they exists and get their index.
	local plrVal, plrIndex = self:FindPlayerInTable(plr)
	if plrVal then
		plrVal[5]:Disconnect()
		local playerTableIndex = plrVal[6]

		--Index 2 == True means they have played their hand
		--If they played their hand, we will remove 1 player from processed players
		--Since gameplay makes a loop until player count == processedPlayers.
		if self.indexMap[playerTableIndex][2] == true then
			self.processedPlayers -= 1
		end

		--Make the seat available again (FALSE MEANS EMPTY)
		self.indexMap[plrVal[6]][1] = false
		table.remove(self.players, plrIndex)
		return true
	end

	--TODO: Add a bug tracker to see how often it exists.
	warn("BlackjackGame -- Tried to remove a player that doesn't exists.")
	return false
end

--We will make the player sit to the table.
function BlackjackGame:AttachPlayer(plr: Player)
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable

	--defining all due typechecker errors
	local character: Model = plr.Character :: Model
	--local primaryPart: BasePart = character.PrimaryPart :: BasePart
	local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	humanoid.JumpHeight = 0
	self:PlayIdleAnimation(plr)
	local index = self:FindPlayerInTable(plr)[6]

	--TODO: doing in this way because of the fucking typechecker. **fix it**
	--Make player sit to the chair based on their index
	if index == 1 then
		bjTable.player1:Sit(humanoid)
	elseif index == 2 then
		bjTable.player2:Sit(humanoid)
	elseif index == 3 then
		bjTable.player3:Sit(humanoid)
	elseif index == 4 then
		bjTable.player4:Sit(humanoid)
	else
		warn("BlackjackGame -- Player index out of bounds: " .. index)
	end

	--Enable gui & disable proximity
	setVisibility:FireClient(plr, true)
	setProximity:FireClient(plr, false)
end

function BlackjackGame:DeattachPlayer(plr: Player)
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable

	--defining all due typechecker errors
	local character: Model = plr.Character :: Model
	local primaryPart: BasePart = character.PrimaryPart :: BasePart
	local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	self:StopIdleAnimation(plr)
	--This long code makes player to unsit, due to typechecking issues I had to check everything
	local seatPart = humanoid.SeatPart
	if seatPart then
		local seatWeld = seatPart:FindFirstChild("SeatWeld")
		if seatWeld then
			seatWeld:Destroy()
		end
	end
	--Waiting here due to minor bug
	--TODO: Make this part more efficent
	task.wait(0.3)
	--Teleport player to the outside of the border
	primaryPart.CFrame = bjTable.Border.border.Front.WorldCFrame * CFrame.new(0, 5.5, 0)
	humanoid.JumpHeight = 0

	--disable gui & enable proximity prompt
	setVisibility:FireClient(plr, false)
	setProximity:FireClient(plr, true)
end

--Based on a hand, calculate the sum.
function BlackjackGame:CalculateNumber(tbl): number
	local total = 0
	local aces = 0

	for _, card in pairs(tbl) do
		--If it's a number or a text such as "ace", "king"
		local numStr = card:match("^(%d+)_")

		local value
		if numStr then
			value = tonumber(numStr)
		elseif card:lower():find("ace") then
			value = 11
			aces += 1
		elseif card:lower():find("king") or card:lower():find("queen") or card:lower():find("jack") then
			value = 10
		else
			value = 0 -- fallback if nothing matches
		end

		total += value
	end

	--dummy way to check the most efficent card combination for ace
	--TODO: Will make client card count to take text value, so that we can write all possible hands.
	while total > 21 and aces > 0 do
		total -= 10 -- ace becomes 1 instead of 11
		aces -= 1
	end

	print("total from func: " .. total)
	return total
end

--Whetever if it's possible to split
--It's not being used atm
function BlackjackGame:CanSplit(tbl): boolean
	if #tbl == 2 then
		if tonumber(tbl[1]:match("^(%d+)_")) == tonumber(tbl[1]:match("^(%d+)_")) then
			return true
		end
	end
	return false
end

--Based on players hand, check whetver they can play double or not.
--Not being used atm, here for future use.
function BlackjackGame:CanDouble(tbl): boolean
	--For a double, player have to pull a card and never again.
	if #tbl == 2 then
		return true
	end
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
	--NOTE: CardGenerator is at the same dir as the BlackjackGame. It's easy logic, check that out!
	local deck = CardGenerator.new()

	self:SetClientStatus("Dealing the cards...")
	self:SetStatus("Game on process...")

	--We will deal the cards, we will do it twice since we need 2 card per player + dealer
	for i, v in pairs(self.players) do
		--We will pull a card, as a string.
		--CardGenerator automatically shuffles at the initialization.
		--Pulling a card deletes the pulled card from the deck of cards.
		local card: string = deck:PullCard()

		--We will insert the card to the player table, cards located at index 2.
		table.insert(v[2], card)
		--Write card number to the client v[1] is our player
		self:ChangePlayerAmountClient(v[1])
		--The place cards will be placed
		local attach = bjTable.Table:FindFirstChild("Player" .. i)
		if attach then
			self:CloneCard(card, attach)
		else
			warn("BlackjackGame -- Couldn't find the player index for the table number.")
		end
		task.wait(1)
	end

	--I'll add no more comments for pulling the card since it's boilerplate :D
	local dcard: string = deck:PullCard()
	--self.dealer is the card of the dealers.
	table.insert(self.dealer, dcard)
	--Write card number to all clients
	self:ChangeDealerAmountClient(self:CalculateNumber(self.dealer))
	local dattach = bjTable.Table.Dealer
	self:CloneCard(dcard, dattach, false)
	task.wait(1)

	for i, v in pairs(self.players) do
		local card: string = deck:PullCard()
		table.insert(v[2], card)
		self:ChangePlayerAmountClient(v[1])
		local attach = bjTable.Table:FindFirstChild("Player" .. i)
		if attach then
			self:CloneCard(card, attach)
		else
			warn("BlackjackGame -- Couldn't find the player index for the table number.")
		end
		task.wait(1)
	end

	dcard = deck:PullCard()
	--We'll do this before adding the lastest card
	self:ChangeDealerAmountClient(self:CalculateNumber(self.dealer) .. "+ ?")
	table.insert(self.dealer, dcard)
	dattach = bjTable.Table.Dealer
	self:CloneCard(dcard, dattach, true)
	task.wait(1)

	--Cards pulled!
	--TODO: There's no card limit atm. Abusable. (When hitting)

	--Now the main game
	self.indexTurn = 1

	--Protection against disconnections, we will loop until everyone is fully done.
	self.processedPlayers = 0

	--Until all players processed, check all players.
	--[[
		NOTE: We have for i,v inside of the while loop, because we give players numbers based on chair index.
		If, let's say self.players[2] left, which seated at chair 2, game gives index 2 to the player, but
		they get the last index of self.players. So there's a chance we will miss some chairs if we run for i,v once.
	]]
	while #self.players ~= self.processedPlayers do
		--Loop through all players
		for i, v in pairs(self.players) do
			if self.canStart == false then
				break
			end
			--That's the player, Now the container
			if v[6] == self.indexTurn then
				--NOTE: player object(1), card in hand(2), action(3), bet(4), watch(5), player index (6), animObject (7) (RECHECK IF U CHANGED IT)

				--We will check this player if they leave.
				local roundPlr = v[1]
				local isInGame = true

				--will be in loop until its done
				while true do
					--If this person made a blackjack, we don't need to ask them for an action.
					if self:CalculateNumber(v[2]) == 21 then
						break
					end

					--Reset the previous action
					v[3] = "none"

					local nowTurn = self.indexTurn

					--We will check this value to see whetever player made an action.
					local didAction = false
					task.spawn(function()
						--If indexTurn changes, which means now it's next player, there's no need to check the old player,
						--so we will stop the loop thus stop the task.
						while nowTurn == self.indexTurn do
							--If action change, let game know action is done.
							if v[3] ~= "none" or self.canStart == false then
								didAction = true
							end

							--If player left, we will change the value thus skip other parts.
							if self:FindPlayerInTable(roundPlr) == false then
								isInGame = false
							end
							task.wait()
						end
					end)
					--Let them send actions.
					self.canAction = true

					for i2 = 10, 0, -1 do
						--If they made an action, or left the game, stop the countdown.
						if didAction or isInGame == false then
							break
						end
						self:SetClientStatus(v[1].Name .. ", your turn: " .. i2)
						task.wait(1)
					end

					--We will make them unable to send action, so they will unable to send action after time ended.
					self.canAction = false

					--If we got the action and player is in the game, also if there are still players.
					if didAction and isInGame and self.canStart then
						if v[3] == "pass" then
							--They wanted to pass, so we will break the while for them.
							self:SetClientStatus(v[1].Name .. ", Passed.")
							task.wait(1)
							break
						elseif v[3] == "hit" then
							--Give the card
							local card = deck:PullCard()
							table.insert(v[2], card)
							self:ChangePlayerAmountClient(v[1])
							local attach = bjTable.Table:FindFirstChild("Player" .. i)
							self:CloneCard(card, attach, false)
							self:SetClientStatus(v[1].Name .. ", Hit.")
							print("Pulled a card")
							task.wait(1)

							--Check the value
							local total = self:CalculateNumber(v[2])
							print(total)
							--If they pass the 21, they will automaticly lose, so let's pass them. Break the loop for them.
							if total > 21 then
								self:SetClientStatus(v[1].Name .. ", Busted!")
								print("You lose!")
								break
							end
							print("Okay all good.")
						end
					end

					--If there are no players, stop the player loop
					if self.canStart == false then
						break
					end
				end
				--Player round ended, while loop done.

				--We will not process the player if they left mid-game.
				if isInGame then
					--Tell indexMap that we played the round.
					self.indexMap[v[6]][2] = true
					self.processedPlayers += 1
				end
				--Now the next player!
				self.indexTurn += 1
			end
		end
	end
	-- The player loop ended, let's check the dealer.

	--[[
		Anticheat

		IDEA: We know what cards does dealer have on the serverside. So we will delete the hidden card (The name of the card is hidden), 
		and replace it with the card we know, since after the game end the cheater have nothing to do.
	]]

	--We will go through this section if there are still players.
	if self.canStart then
		self:SetClientStatus("Now it's dealer's turn!")
		task.wait(2)
		for i, v in pairs(bjTable.Table.Dealer:GetChildren()) do
			if v.Name == "hidden" then
				v:Destroy()
			end
		end

		--Let's add the deleted card, which is index 2. Because we added it in this way in the code.
		dattach = bjTable.Table.Dealer
		self:CloneCard(self.dealer[2], dattach)
		task.wait(1)

		--Okay, time for setting up cards for the dealer!
		local dealerTotal = self:CalculateNumber(self.dealer)
		while dealerTotal < 18 do
			dcard = deck:PullCard()
			table.insert(self.dealer, dcard)
			self:ChangeDealerAmountClient(self:CalculateNumber(self.dealer))
			dattach = bjTable.Table.Dealer
			self:CloneCard(dcard, dattach)
			task.wait(1)
			dealerTotal = self:CalculateNumber(self.dealer)
		end

		self:ChangeDealerAmountClient(self:CalculateNumber(self.dealer))

		if dealerTotal > 22 then
			self:SetClientStatus("Dealer busted!")
		else
			self:SetClientStatus("Dealer got " .. dealerTotal .. ".")
		end
		print("Dealer: " .. dealerTotal)

		task.wait(2)

		--So we pulled all necessary cards for the dealer.
		--Now we will check whetever players won against the dealer.

		for i, v in pairs(self.players) do
			local score = self:CalculateNumber(v[2])
			print(v[1].Name .. ": " .. score)
			--Either if none busted and players card higher than dealers, or dealer is busted and not us, then we won.
			if ((score < 22 and dealerTotal < 22) and score > dealerTotal) or (dealerTotal > 22 and score < 22) then
				self:SetClientStatus(v[1].Name .. " Won!")
			--If neither dealer or player busted, and we are equal, then it's a tie.
			elseif score == dealerTotal and (score < 22 and dealerTotal < 22) then
				self:SetClientStatus(v[1].Name .. " Tied.")
			else
				self:SetClientStatus(v[1].Name .. " Lost.")
			end
			task.wait(2)
		end
	end

	--Game ended! Let's clean the mess.

	--Clean the cards at the workspace.

	self:CleanGame()

	self.isGame = false
	print("Game ended!")
	return true
end

--Cleaning game
function BlackjackGame:CleanGame()
	local bjTable: blackjackTable = self.blackjackTable
	--Clean the cards at the workspace.
	for _, v in pairs(bjTable.Table:GetChildren()) do
		if v:IsA("Attachment") then
			for _, v2 in pairs(v:GetChildren()) do
				v2:Destroy()
			end
		end
	end

	--Clean the player database.
	--NOTE: player object(1), card in hand(2), action(3), bet(4), watch(5), player index (6), animObject (7) (RECHECK IF U CHANGED IT)
	for i, v in pairs(self.players) do
		v[2] = {}
		v[3] = "none"
		v[4] = 0

		self:ChangePlayerAmountClient(v[1])
	end

	self.dealer = {}

	--Reset GUI
	self:ChangeDealerAmountClient(0)

	--Lastly, clean the made actions.
	for i, v in pairs(self.indexMap) do
		--Index 2 of v specifies if the player in the chair index i played their hand or not.
		v[2] = false
	end
end

--Search through table and find the specific player from self.players, also returning index as a secondary
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

--Hiding cards by removing the front surface and hiding its name.
function BlackjackGame:HideCard(card: Card): ()
	--We will delete the texture, and change the name of the card so that it couldn't get exploited.
	card.FrontTexture:Destroy()
	card.Name = "hidden"

	--We will turn the card for the game
	card.CFrame = card.CFrame * CFrame.Angles(0, 0, math.rad(180))
end

--Made this due to high boilerplate in DealerGame, it just clones the card as an object and pastes it to desired player's position based on the cards amount for visual.
function BlackjackGame:CloneCard(cardName: string, attachment: Attachment, isHidden: boolean?)
	if isHidden == nil then
		isHidden = false
	end

	local deck = CardGenerator.new()

	local cardOffset = #attachment:GetChildren()

	local card = deck.GetCardByName(cardName)
	card.Parent = attachment
	card.CFrame = attachment.WorldCFrame
		* CFrame.new(
			ReplicatedStorage.Assets.Cards.ace_spade.Size.X - cardOffset * 0.1,
			0.01 * cardOffset,
			(ReplicatedStorage.Assets.Cards.ace_spade.Size.Z / 2) * cardOffset
		)
		* CFrame.Angles(0, 0, math.rad(-90))

	if isHidden then
		self:HideCard(card)
	end
end

--Set's the text above of the table.
function BlackjackGame:SetStatus(text)
	--Redefining due intellisense issues
	local bjTable: blackjackTable = self.blackjackTable
	bjTable.Table.Info.MainFrame.Status.Text = text
end

--Sets the text in the playerGui for every player in the table.
function BlackjackGame:SetClientStatus(text)
	for i, v in pairs(self.players) do
		clientStatus:FireClient(v[1], text)
	end
end

--Plays the sitting animation
function BlackjackGame:PlayIdleAnimation(plr: Player)
	local character = plr.Character

	local humanoid = character.Humanoid
	local animator: Animator = humanoid.Animator

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://91225478466975"

	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Idle
	track.Looped = true
	track:Play()
	--We save the track into the player database, because we will need to disable it when player lefts.
	self:FindPlayerInTable(plr)[7] = track
end

--Stop the animation & clean the mess
function BlackjackGame:StopIdleAnimation(plr: Player)
	local track: AnimationTrack = self:FindPlayerInTable(plr)[7]
	if track then
		track:Stop()
		track:Destroy()
	end
end

--Write players card sum for accessibility
function BlackjackGame:ChangePlayerAmountClient(plr: Player)
	playerCount:FireClient(plr, self:CalculateNumber(self:FindPlayerInTable(plr)[2]))
end

--These functions don't do the calculation inside because I could write a text
function BlackjackGame:ChangeDealerAmountClient(num: number | string)
	dealerCount:FireAllClients(num)
end

--Game between players, atleast 2 players.
--TODO: COMMUNITY GAME IS PLANNED IN THE FUTURE.
function BlackjackGame:CommunityGame() end

return BlackjackGame
