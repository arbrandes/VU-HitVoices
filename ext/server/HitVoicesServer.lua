class "HitVoicesServer"

function HitVoicesServer:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoicesServer:RegisterVars()

	self.characterLookup = {}
	self.validNames = {'Captain', 'Combine', 'Ganon', 'Incineroar', 'Peach', 'Wolf', 'Off'}
	self.showNameChoices = ''

	for i=1, #self.validNames do
		if (self.showNameChoices:len() > 0) then
			self.showNameChoices = self.showNameChoices..', '
		end
		self.showNameChoices = self.showNameChoices..'!'..self.validNames[i]
	end
end

function HitVoicesServer:RegisterEvents()
	Events:Subscribe('Player:Joining', self, self.onPlayerJoining)
	Events:Subscribe('Player:Killed', self, self.onPlayerKilled)
	Events:Subscribe('Player:Chat', self, self.onPlayerChat)

	Events:Subscribe('HitEffects:OnSetCharacter', self, self.onSetCharacter)

	-- hook should run last
	Hooks:Install('Soldier:Damage', 0, self, self.onSoldierDamage)
end

function HitVoicesServer:onPlayerJoining(name, playerGuid, ipAddress, accountGuid)
	ChatManager:Yell(name..' Joins the Battle!', 30)
end

function HitVoicesServer:onSoldierDamage(hookCtx, soldier, info, giverInfo)
	-- player took damage from anything
	if (soldier ~= nil and soldier.player ~= nil and info.damage ~= nil and info.damage > 0) then
		NetEvents:SendToLocal('HitEffects:OnDamageTaken', soldier.player, info.damage, info.boneIndex == 1)
	end
	-- we only care about player to player damage
	if giverInfo ~= nil and giverInfo.giver ~= nil and
		soldier ~= nil and soldier.player ~= nil and
		info.damage ~= nil and info.damage > 0 then
		if (giverInfo.giver.id ~= soldier.player.id) then -- player1 on player2 damage
			NetEvents:SendToLocal('HitEffects:OnDamageGiven', giverInfo.giver, soldier.player.id, info.damage, info.boneIndex == 1)
		end
	end
	hookCtx:Pass(soldier, info, giverInfo)
end

function HitVoicesServer:onPlayerKilled(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
	-- check for melee kill first
	if (player ~= nil and inflictor ~= nil) then
		if (info.weaponUnlock ~= nil) then
			local weaponId = _G[info.weaponUnlock.typeInfo.name](info.weaponUnlock).debugUnlockId
			if (weaponId == 'U_Knife_Razor' or weaponId == 'U_Knife') then
				NetEvents:SendToLocal('HitEffects:OnPlayerMelee', inflictor, player.id, inflictor.id)
				NetEvents:SendToLocal('HitEffects:OnPlayerMelee', player, player.id, inflictor.id)
			end
		else
			NetEvents:SendToLocal('HitEffects:OnPlayerKilled', inflictor, player.id, inflictor.id)
			NetEvents:SendToLocal('HitEffects:OnPlayerKilled', player, player.id, inflictor.id)
		end
	end
end

function HitVoicesServer:onPlayerChat(player, recipientMask, message)

	if player == nil or message == nil then
		return
	end

	local parts = string.lower(message):split(' ')
	if (parts ~= nil and #parts > 0) then
		if (parts[1] == '!voice' and parts[2] ~= nil) then
			local characterName = string.lower(parts[2])

			for i=1, #self.validNames do
				if (parts[2]:lower() == self.validNames[i]:lower()) then
					self:onSetCharacter(player.id, parts[2]:lower())
					return
				end
			end
			ChatManager:SendMessage("Choices are: "..self.showNameChoices, player)
			return
		elseif (#parts == 1 and parts[1] == '!voice') then
			ChatManager:SendMessage("Choices are: "..self.showNameChoices, player)
		end

		if (parts[1] ~= nil) then
			for i=1, #self.validNames do
				if (parts[1]:lower() == '!'..self.validNames[i]:lower()) then
					self:onSetCharacter(player.id, self.validNames[i]:lower())
					return
				end
			end
		end
		
	end
end

function HitVoicesServer:onSetCharacter(playerID, characterName)
	self.characterLookup[tostring(playerID)] = characterName:lower()
	print('onSetCharacter - entries: '..tostring(#self.characterLookup))
	for id,character in pairs(self.characterLookup) do
		print('['..tostring(id)..']: '..tostring(character))
	end

	NetEvents:BroadcastLocal('HitEffects:OnChangeCharacter', playerID, characterName:lower(), self.characterLookup)
end

return HitVoicesServer()