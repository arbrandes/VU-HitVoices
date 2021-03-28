class "HitVoicesClient"

function HitVoicesClient:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoicesClient:RegisterVars()
	self.killCounter = 0
	self.lastPlayerConnectedTime = 0;
	self.myPlayer = nil
	self.currentCharacter = '';
	self.allowCustom = true;
end

function HitVoicesClient:RegisterEvents()

	Console:Register('Voice', 'Usage: vu-hitVoices.Voice ['..hitVoices.showNameChoicesConsole..'] - Choose Your Character!', self, self.onConsoleSetCharacter)
	Console:Register('AllowCustom', 'Usage: vu-hitVoices.AllowCustom [true|false] - Enable/Disable custom server sounds.', self, self.onAllowcustom)

	Events:Subscribe('Player:UpdateInput', self, self.onPlayerUpdateInput)
	Events:Subscribe('Player:Connected', self, self.onPlayerConnected)
	Events:Subscribe('Player:Respawn', self, self.onPlayerRespawn)
	Events:Subscribe('Extension:Loaded', WebUI, WebUI.Init)

	NetEvents:Subscribe('HitVoices:OnChangeCharacter', self, self.onChangeCharacter)
	NetEvents:Subscribe('HitVoices:OnDamageTaken', self, self.onDamageTaken)
	NetEvents:Subscribe('HitVoices:OnDamageGiven', self, self.onDamageGiven)
	NetEvents:Subscribe('HitVoices:OnPlayerKilled', self, self.onPlayerKilled)


	NetEvents:Subscribe('HitVoices:PlayScene', self, self.onPlaySceneCommand)
	NetEvents:Subscribe('HitVoices:PlaySound', self, self.onPlaySoundCommand)
end

function HitVoicesClient:onPlaySceneCommand(sceneName, characterName, volume)

	if (self.currentCharacter == 'off') then
		return
	end

	if (characterName == nil or characterName == '' or characterName == 'Current') then
		characterName = self.currentCharacter
	end

	if (sceneName == 'SetCharacter' or sceneName == 'Spawn') then
		WebUI:ExecuteJS(string.format("play%sScene(\'%s\', %1.2f)", sceneName, characterName, volume))
	end
end

function HitVoicesClient:onPlaySoundCommand(soundName, characterName, delay, volume)

	if (self.currentCharacter == 'off') then
		return
	end

	if (characterName == nil or characterName == '' or characterName == 'Current') then
		characterName = self.currentCharacter
	end

	if (soundName == 'AnnouncerReady' or soundName == 'AnnouncerGo' or 
		soundName == 'AnnouncerPraise' or soundName == 'AnnounceCharacter' or 
		soundName == 'Connected' or soundName == 'Cheer' or 
		soundName == 'Aww' or soundName == 'Jump' or  
		soundName == 'Taunt' or soundName == 'Death') then

		WebUI:ExecuteJS(string.format("play%sSound(\'%s\', %d, %1.2f)", soundName, characterName, delay, volume))
	elseif (soundName == 'Custom' and self.allowCustom) then

		WebUI:ExecuteJS(string.format("playCustomSound(\'%s\', %d, %1.2f)", characterName, delay, volume))
	end
end

function HitVoicesClient:onConsoleSetCharacter(args)
	if (args[1] ~= nil) then
		local characterName = hitVoices:isValidName(args[1])
		if (characterName ~= false) then
			NetEvents:SendLocal('HitVoices:OnChangeCharacter', self.myPlayer.name, characterName)
			self:onChangeCharacter(self.myPlayer.name, characterName)
			return true
		end
	end

	SharedUtils:Print("Choices are: "..hitVoices.showNameChoicesConsole)
	return false
end

function HitVoicesClient:onAllowcustom(args)

	if (args[1] ~= nil) then
		self.allowCustom = args[1]:lower() == 'true' or args[1]:lower() == 'on' or args[1] == '1'
	end

	local enabled = 'enabled'
	if (not self.allowCustom) then
		enabled = 'disabled'
	end

	SharedUtils:Print("Custom sounds are: "..enabled)
	return true
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
		if ((hitVoices:isBot(player) and hitVoices.Config.AnnounceBots) or not hitVoices:isBot(player)) then
			if (self.lastPlayerConnectedTime < SharedUtils:GetTimeMS()) then
				self.lastPlayerConnectedTime = SharedUtils:GetTimeMS() + 1500 -- prevent event spam, 1.5 second delay

				WebUI:ExecuteJS(string.format("playConnectedSound(\'%s\')", hitVoices:getCharacter(player.name)))
			end
		end
	end
	if (self.myPlayer ~= nil and self.myPlayer.id == player.id) then
		NetEvents:Send('HitVoices:OnGetConfig')
	end
end

function HitVoicesClient:onPlayerRespawn(player)
	if (self.myPlayer ~= nil and self.myPlayer.id == player.id) then
		WebUI:ExecuteJS(string.format("playSpawnScene(\'%s\')", hitVoices:getCharacter(self.myPlayer.name)))
	end
end

function HitVoicesClient:onChangeCharacter(playerID, characterName)
	if (self.myPlayer ~= nil and self.myPlayer.name == playerID) then
		self.currentCharacter = characterName:lower()
		WebUI:ExecuteJS(string.format('playSetCharacterScene(\'%s\')', characterName:lower()))
	end
end

function HitVoicesClient:onDamageTaken(damage, isHeadshot)
	WebUI:ExecuteJS(string.format('addTakenEffect(%d, %s)', math.floor(damage), tostring(isHeadshot)))
end

function HitVoicesClient:onDamageGiven(takerID, damage, isHeadshot, volume)
	WebUI:ExecuteJS(string.format('addGivenEffect(\'%s\', %d, %s, %1.2f)', hitVoices:getCharacter(takerID), math.floor(damage), tostring(isHeadshot), volume))
end

function HitVoicesClient:onPlayerKilled(killedID, killerID, isMelee, volume)
	-- player got a kill
	if (self.myPlayer ~= nil and self.myPlayer.name == killerID) then
		self.killCounter = self.killCounter + 1
		WebUI:ExecuteJS(string.format("playDeathSound(\'%s\', 0, %1.2f);playCheerSound(\'%s\', 500);",
			hitVoices:getCharacter(killedID), volume, hitVoices:getCharacter(killerID))
		)

		-- every knife kill or every 5 kills
		if (isMelee or (self.killCounter > 0 and self.killCounter % 5 == 0)) then
			WebUI:ExecuteJS(string.format("playTauntSound(\'%s\', 1500)", hitVoices:getCharacter(killerID)))
		end

		-- every other knife kill or every 10 kills
		if ((self.killCounter > 0 and self.killCounter % 2 == 0 and isMelee) or (self.killCounter > 0 and self.killCounter % 10 == 0)) then
			WebUI:ExecuteJS(string.format("playAnnouncerPraiseSound(\'%s\', 2000)", hitVoices:getCharacter(killerID)))
		end
	end

	-- player was killed
	if (self.myPlayer ~= nil and self.myPlayer.name == killedID) then
		self.killCounter = 0

		WebUI:ExecuteJS(string.format("playDeathSound(\'%s\');playAwwSound(\'%s\', 500);",
			hitVoices:getCharacter(killedID), hitVoices:getCharacter(killedID))
		)

		if (isMelee) then
			WebUI:ExecuteJS(string.format("playTauntSound(\'%s\', 1500)", hitVoices:getCharacter(killerID)))
		end
	end
end

return HitVoicesClient()