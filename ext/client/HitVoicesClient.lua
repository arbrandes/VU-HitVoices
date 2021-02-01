class "HitVoicesClient"

function HitVoicesClient:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoicesClient:RegisterVars()

	self.characterLookup = {}
	self.validNames = {'Captain', 'Combine', 'Ganon', 'Incineroar', 'Peach', 'Wolf', 'Off'}
	self.killCounter = 0
	self.showNameChoices = ''
	self.showNameChoicesConsole = ''
	self.lastPlayerConnectedTime = 0;

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

function HitVoicesClient:RegisterEvents()

	Console:Register('SetCharacter', 'Usage: vu-hitvoices.SetCharacter ['..self.showNameChoicesConsole..'] - Choose Your Character!', self, self.onConsoleSetCharacter)

	Events:Subscribe('Player:UpdateInput', self, self.onPlayerUpdateInput)
	Events:Subscribe('Player:Connected', self, self.onPlayerConnected)
	Events:Subscribe('Player:Respawn', self, self.onPlayerRespawn)
	Events:Subscribe('Extension:Loaded', WebUI, WebUI.Init)

	NetEvents:Subscribe('HitEffects:OnChangeCharacter', self, self.onChangeCharacter)
	NetEvents:Subscribe('HitEffects:OnDamageTaken', self, self.onDamageTaken)
	NetEvents:Subscribe('HitEffects:OnDamageGiven', self, self.onDamageGiven)
	NetEvents:Subscribe('HitEffects:OnPlayerKilled', self, self.onPlayerKilled)
	NetEvents:Subscribe('HitEffects:OnPlayerMelee', self, self.onPlayerMelee)
end

function HitVoicesClient:onConsoleSetCharacter(args) 
	local characterName = string.lower(args[1])
	for i=1, #self.validNames do
		if (characterName == self.validNames[i]:lower()) then
			local myself = PlayerManager:GetLocalPlayer()
			NetEvents:SendLocal('HitEffects:OnSetCharacter', myself.id, characterName)
			return
		end
	end

	SharedUtils:Print("Choices are: "..self.showNameChoices)
	return false
end

function HitVoicesClient:getCharacter(playerID)
	if (self.characterLookup[tostring(playerID)] == nil) then
		self.characterLookup[tostring(playerID)] = self.validNames[math.random(1, #self.validNames)]:lower()
	end
	return self.characterLookup[tostring(playerID)]
end



function HitVoicesClient:onPlayerUpdateInput(player, deltaTime)
	local myself = PlayerManager:GetLocalPlayer()
	if(myself.input ~= nil and myself.soldier ~= nil) then
		if (myself.id == player.id and player.input:GetLevel(EntryInputActionEnum.EIAJump) > 0) and not isYumping then
			WebUI:ExecuteJS(string.format("playJumpSound(\'%s\')", self:getCharacter(myself.id)))
			isYumping = true
		end
		if (myself.id == player.id and player.input:GetLevel(EntryInputActionEnum.EIAJump) <= 0) and isYumping then
			isYumping = false
		end
	end
end

function HitVoicesClient:onPlayerConnected(player)
	local myself = PlayerManager:GetLocalPlayer()
	if (myself ~= nil and myself.id == player.id) then
		NetEvents:SendLocal('HitEffects:OnSetCharacter', myself.id, self:getCharacter(myself.id))
	end
	if (myself ~= nil and myself.id ~= player.id) then

		if (self.lastPlayerConnectedTime < SharedUtils:GetTimeMS()) then
			self.lastPlayerConnectedTime = SharedUtils:GetTimeMS() + 1500 -- prevent event spam, 1.5 second delay

			WebUI:ExecuteJS(string.format("playConnectedSound(\'%s\')", self:getCharacter(player.id)))
		end
	end

	-- myself is nil == it's a bot
	if (myself == nil and player.id ~= nil) then
		NetEvents:SendLocal('HitEffects:OnSetCharacter', player.id, self:getCharacter(player.id))
	end
end

function HitVoicesClient:onPlayerRespawn(player)
	local myself = PlayerManager:GetLocalPlayer()
	if (myself.id == player.id) then
		WebUI:ExecuteJS(string.format("playSpawnScene(\'%s\')", self:getCharacter(myself.id)))
	end
end

function HitVoicesClient:onChangeCharacter(playerID, characterName, newCharacterLookupTable)
	self.characterLookupTable = {}
	for id,character in pairs(newCharacterLookupTable) do
		print('['..tostring(id)..']: '..tostring(character))
		self.characterLookupTable[id] = character
	end

	local myself = PlayerManager:GetLocalPlayer()
	if (myself.id == playerID) then
		WebUI:ExecuteJS(string.format('playSetCharacterScene(\'%s\')', characterName:lower()))
	end
end

function HitVoicesClient:onDamageTaken(damage, isHeadshot)
	WebUI:ExecuteJS(string.format('addTakenEffect(%d, %s)', math.floor(damage), tostring(isHeadshot)))
end

function HitVoicesClient:onDamageGiven(playerID, damage, isHeadshot)
	WebUI:ExecuteJS(string.format('addGivenEffect(\'%s\', %d, %s)', self:getCharacter(playerID), math.floor(damage), tostring(isHeadshot)))
end

function HitVoicesClient:onPlayerKilled(playerID, killerID)
	print('self.killCounter: '..tostring(self.killCounter))
	local myself = PlayerManager:GetLocalPlayer()
	if (myself.id == killerID) then
		self.killCounter = self.killCounter + 1
		WebUI:ExecuteJS(string.format("playCheerSound(\'%s\')", self:getCharacter(killerID)))

		if (self.killCounter > 0 and self.killCounter % 5 == 0) then
			print(string.format("playTauntSound(\'%s\', 1000)", self:getCharacter(killerID)))
			WebUI:ExecuteJS(string.format("playTauntSound(\'%s\', 1000)", self:getCharacter(killerID)))
		end
	end
	if (myself.id == playerID) then
		self.killCounter = 0
		if (myself.id ~= killerID) then
			WebUI:ExecuteJS(string.format("playDeathScene(\'%s\', \'%s\')", self:getCharacter(playerID), self:getCharacter(killerID)))
		else
			WebUI:ExecuteJS(string.format("playDeathScene(\'%s\', \'off\')", self:getCharacter(playerID)))
		end
	end
end

function HitVoicesClient:onPlayerMelee(playerID, killerID)
	local myself = PlayerManager:GetLocalPlayer()
	if (myself.id == killerID and myself.id ~= playerID) then
		self.killCounter = self.killCounter + 1
		local js = string.format("playCheerSound(\'%s\');playDeathSound(\'%s\');playTauntSound(\'%s\', 1500)",
			self:getCharacter(killerID),
			self:getCharacter(playerID),
			self:getCharacter(killerID)
		)
		WebUI:ExecuteJS(js)
		print(js)
	end
	if (myself.id == playerID and myself.id ~= killerID) then
		self.killCounter = 0

		local js = string.format("playAwwSound(\'%s\');playDeathSound(\'%s\');playTauntSound(\'%s\', 1500)",
			self:getCharacter(playerID),
			self:getCharacter(playerID),
			self:getCharacter(killerID)
		)
		WebUI:ExecuteJS(js)
		print(js)
	end
end


return HitVoicesClient()