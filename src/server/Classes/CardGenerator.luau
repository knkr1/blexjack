--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local CardGenerator = {}

CardGenerator.__index = CardGenerator

type self = {
	cardNames: { string },
	cardNumbers: { string },
	dismissSelected: boolean,
	cards: { string },
}

export type CardGenerator = typeof(setmetatable({} :: self, CardGenerator))

function CardGenerator.new(dismissSelected: boolean?): CardGenerator
	local self = setmetatable({} :: self, CardGenerator)

	--Will cards get dismissed after being choosen?
	if not dismissSelected then
		dismissSelected = true
	end

	self.cardNames = { "spade", "heart", "diamond", "club" }
	self.cardNumbers = { "ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king" }
	self.dismissSelected = dismissSelected :: boolean

	--Generating card template
	self.cards = {}
	for _, cardName in pairs(self.cardNames) do
		for _, cardNumber in pairs(self.cardNumbers) do
			table.insert(self.cards, cardNumber .. "_" .. cardName)
		end
	end

	--Shuffle Cards
	self.cards = TableUtil.Shuffle(self.cards)

	return self
end

--Pulling a card, it returns the name only.
function CardGenerator:PullCard(): string | boolean
	--If our stack is empty, return false
	if #self.cards == 0 then
		return false
	end

	--Selecting a random card
	local randomChoice: string = self.cards[math.random(1, #self.cards)]

	--Since we want to dismiss selected, we will search the index of the selected card to delete it
	if self.dismissSelected then
		local foundIndex: number = -1
		for i, _ in pairs(self.cards) do
			if self.cards[i] == randomChoice then
				foundIndex = i
			end
		end

		-- If we been able to find the location of the card, we will delete it.
		if foundIndex ~= -1 then
			table.remove(self.cards, foundIndex)
		else
			warn("CardGenerator -- Couldn't find the card to delete.")
		end
	end
	return randomChoice
end

function CardGenerator:PullCardAsAnObject(): Part | boolean
	local name: string | boolean = self:PullCard()
	if name == false then
		return false
	end
	return ReplicatedStorage.Assets.Cards[name]:Clone()
end

function CardGenerator.GetCardByName(name: string): Part | boolean
	if ReplicatedStorage.Assets.Cards[name] then
		local cardClone = ReplicatedStorage.Assets.Cards[name]:Clone()

		return cardClone
	end
	return false
end

function CardGenerator:Destroy()
	self.cards = nil
	self.cardNames = nil
	self.cardNumbers = nil
	self.dismissSelected = nil
end

return CardGenerator
