class "HitVoicesClient"

function HitVoicesClient:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoicesClient:RegisterVars()

	self.killCounter = 0
	self.lastPlayerConnectedTime = 0;
	self.myPlayer = nil
end

function HitVoicesClient:RegisterEvents()

	Console:Register('SetCharacter', 'Usage: vu-hitvoices.SetCharacter ['..hitVoices.showNameChoicesConsole..'] - Choose Your Character!', self, self.onConsoleSetCharacter)

	Events:Subscribe('Player:UpdateInput', self, self.onPlayerUpdateInput)
	Events:Subscribe('Player:Connected', self, self.onPlayerConnected)
	Events:Subscribe('Player:Respawn', self, self.onPlayerRespawn)
	Events:Subscribe('Extension:Loaded', WebUI, WebUI.Init)

	Events:Subscribe('HitVoices:OnChangeCharacter', self, self.onChangeCharacter)
	Events:Subscribe('HitVoices:OnDamageTaken', self, self.onDamageTaken)
	Events:Subscribe('HitVoices:OnDamageGiven', self, self.onDamageGiven)
	Events:Subscribe('HitVoices:OnPlayerKilled', self, self.onPlayerKilled)
end

function HitVoicesClient:onConsoleSetCharacter(args) 
	local characterName = string.lower(args[1])
	for i=1, #hitVoices.validNames do
		if (characterName == hitVoices.validNames[i]:lower()) then
			Events:DispatchLocal('HitVoices:OnChangeCharacter', self.myPlayer.name, characterName)
			return
		end
	end

	SharedUtils:Print("Choices are: "..hitVoices.showNameChoicesConsole)
	return false
end

function HitVoicesClient:onPlayerUpdateInput(player, deltaTime)

	if (self.myPlayer == nil) then
		self.myPlayer = PlayerManager:GetLocalPlayer()
	end

	if(self.myPlayer.input ~= nil and self.myPlayer.soldier ~= nil) then
		if (self.myPlayer.id == player.id and player.input:GetLevel(EntryInputActionEnum.EIAJump) > 0) and not isYumping then
			WebUI:ExecuteJS(string.format("playJumpSound(\'%s\')", hitVoices:getCharacter(self.myPlayer.name)))
			isYumping = true
		end
		if (self.myPlayer.id == player.id and player.input:GetLevel(EntryInputActionEnum.EIAJump) <= 0) and isYumping then
			isYumping = false
		end
	end
end

function HitVoicesClient:onPlayerConnected(player)
	self.myPlayer = PlayerManager:GetLocalPlayer()
	if (self.myPlayer ~= nil and self.myPlayer.id ~= player.id) then
		if (self.lastPlayerConnectedTime < SharedUtils:GetTimeMS()) then
			self.lastPlayerConnectedTime = SharedUtils:GetTimeMS() + 1500 -- prevent event spam, 1.5 second delay

			WebUI:ExecuteJS(string.format("playConnectedSound(\'%s\')", hitVoices:getCharacter(player.name)))
		end
	end
end

function HitVoicesClient:onPlayerRespawn(player)
	if (self.myPlayer.id == player.id) then
		WebUI:ExecuteJS(string.format("playSpawnScene(\'%s\')", hitVoices:getCharacter(self.myPlayer.name)))
	end
end

function HitVoicesClient:onChangeCharacter(playerID, characterName)
	print('HitVoicesClient:onChangeCharacter: '..tostring(self.myPlayer.name)..' | '..tostring(playerID).. ' | '..tostring(characterName))
	if (self.myPlayer.name == playerID) then
		WebUI:ExecuteJS(string.format('playSetCharacterScene(\'%s\')', characterName:lower()))
	end
end

function HitVoicesClient:onDamageTaken(playerID, damage, isHeadshot)
	if (self.myPlayer.name == playerID) then
		WebUI:ExecuteJS(string.format('addTakenEffect(%d, %s)', math.floor(damage), tostring(isHeadshot)))
	end
end

function HitVoicesClient:onDamageGiven(giverID, takerID, damage, isHeadshot)
	if (self.myPlayer.name == giverID) then
		WebUI:ExecuteJS(string.format('addGivenEffect(\'%s\', %d, %s)', hitVoices:getCharacter(takerID), math.floor(damage), tostring(isHeadshot)))
	end
end

function HitVoicesClient:onPlayerKilled(playerID, killerID, isMelee)
	print('onPlayerKilled - self.killCounter [A]: '..tostring(self.killCounter))
	
	-- player got a kill
	if (self.myPlayer.name == killerID) then
		self.killCounter = self.killCounter + 1
		WebUI:ExecuteJS(string.format("playDeathSound(\'%s\')", hitVoices:getCharacter(playerID)))
		WebUI:ExecuteJS(string.format("playCheerSound(\'%s\', 500)", hitVoices:getCharacter(killerID)))

		if (isMelee or (self.killCounter > 0 and self.killCounter % 5 == 0)) then
			WebUI:ExecuteJS(string.format("playTauntSound(\'%s\', 1500)", hitVoices:getCharacter(killerID)))
		end
	end

	-- player was killed
	if (self.myPlayer.name == playerID) then
		self.killCounter = 0

		WebUI:ExecuteJS(string.format("playDeathSound(\'%s\')", hitVoices:getCharacter(playerID)))
		WebUI:ExecuteJS(string.format("playAwwSound(\'%s\', 500)", hitVoices:getCharacter(playerID)))

		if (isMelee) then
			WebUI:ExecuteJS(string.format("playTauntSound(\'%s\', 1500)", hitVoices:getCharacter(killerID)))
		end
	end
	print('onPlayerKilled - self.killCounter [B]: '..tostring(self.killCounter))
end

return HitVoicesClient()