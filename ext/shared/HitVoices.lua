class "HitVoices"


function HitVoices:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoices:RegisterVars()

	self.characterLookup = {}
	self.validNames = {'Captain', 'Combine', 'Ganon', 'Incineroar', 'Peach', 'Wolf', 'Off'}
	self.showNameChoices = ''
	self.showNameChoicesConsole = ''

	for i=1, #self.validNames do
		if (self.showNameChoices:len() > 0) then
			self.showNameChoices = self.showNameChoices..', '
		end
		if (self.showNameChoicesConsole:len() > 0) then
			self.showNameChoicesConsole = self.showNameChoicesConsole..', '
		end
		self.showNameChoices = self.showNameChoices..'!'..self.validNames[i]
		self.showNameChoicesConsole = self.showNameChoicesConsole..self.validNames[i]
	end
end

function HitVoices:RegisterEvents()
	NetEvents:Subscribe('HitVoices:OnChangeCharacter', self, self.setCharacter)
end

function HitVoices:setCharacter(playerID, characterName)
	print('setCharacter: '..tostring(playerID)..' | '..tostring(characterName))
	print('setCharacter: self.characterLookup ('..tostring(self.characterLookup)..')')
	self.characterLookup[playerID] = characterName
end

function HitVoices:getCharacter(playerID)
	print('getCharacter -> playerID: '..tostring(playerID))
	if (self.characterLookup[playerID] == nil) then
		self.characterLookup[playerID] = self.validNames[math.random(1, #self.validNames-1)]:lower()
		print('getCharacter -> empty')
	end
	print('getCharacter -> self.characterLookup[playerID]: '..tostring(self.characterLookup[playerID]))
	return self.characterLookup[playerID]
end

return HitVoices()