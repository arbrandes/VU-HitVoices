class "HitVoicesServer"

function HitVoicesServer:__init()
	self:RegisterVars()
	self:RegisterEvents()
end

function HitVoicesServer:RegisterVars()
end

function HitVoicesServer:RegisterEvents()
	Events:Subscribe('Player:Joining', self, self.onPlayerJoining)
	Events:Subscribe('Player:Killed', self, self.onPlayerKilled)
	Events:Subscribe('Player:Chat', self, self.onPlayerChat)
	Hooks:Install('Soldier:Damage', 0, self, self.onSoldierDamage)

	for conVar, conValue in pairs(hitVoices.Config) do
		RCON:RegisterCommand('vu-hitVoices.'..conVar, RemoteCommandFlag.RequiresLogin, function(command, args, loggedIn)

			local varName = command:split('.')[2]
			if (varName == 'AnnounceBots') then
				if (args ~= nil and args[1] ~= nil) then
					hitVoices.Config[varName] = args[1] == '1' or args[1]:lower() == 'true'
				end

			elseif (varName == 'KillVoiceMaxRange') then
				if (args ~= nil and args[1] ~= nil and tonumber(args[1]) ~= nil) then
					hitVoices.Config[varName] = tonumber(args[1])
				end
			else
				if (args ~= nil and args[1] ~= nil) then
					hitVoices.Config[varName] = table.concat(args, ',')
				end
			end

			hitVoices:onSetConfig(hitVoices.Config)
			NetEvents:BroadcastLocal('HitVoices:OnSetConfig', hitVoices.Config)

			return {'OK', tostring(hitVoices.Config[varName])}
		end)
	end

	RCON:RegisterCommand('vu-hitVoices.PlayScene', RemoteCommandFlag.RequiresLogin, function(command, args, loggedIn)

		if (args == nil or #args < 2) then
			return {false, 'Arguments: PlayerName SceneName [CharacterName] [Volume]'}
		end

		local playerName = args[1] or ''
		local sceneName = args[2] or ''
		local character = hitVoices:isValidName(args[3]) or hitVoices:getRandomCharacter()
		local volume = tonumber(args[4]) or 1

		if (character == '*') then
			character = hitVoices:getRandomCharacter()
		end

		if (playerName == '*') then
			NetEvents:BroadcastLocal('HitVoices:PlayScene', sceneName, character, volume)
			return {'OK'}
		else
			local player = PlayerManager:GetPlayerByName(playerName)

			if (not player) then
				return {false, 'Player not found: '..playerName}
			end

			NetEvents:SendToLocal('HitVoices:PlayScene', player, sceneName, character, volume)
			return {'OK'}
		end
	end)

	RCON:RegisterCommand('vu-hitVoices.PlaySound', RemoteCommandFlag.RequiresLogin, function(command, args, loggedIn)

		if (args == nil or #args < 2) then
			return {false, 'Arguments: PlayerName SoundName [CharacterName] [Delay] [Volume]'}
		end

		local playerName = args[1] or ''
		local soundName = args[2] or ''
		local character = ''
		if (soundName:lower() == 'custom') then
			character = args[3]
		else
			character = hitVoices:isValidName(args[3]) or hitVoices:getRandomCharacter()
		end
		
		local delay = math.abs(tonumber(args[4]) or 0)
		local volume = math.abs(tonumber(args[5]) or 1)

		if (playerName == '*') then
			NetEvents:BroadcastLocal('HitVoices:PlaySound', soundName, character, delay, volume)
			return {'OK'}
		else
			local player = PlayerManager:GetPlayerByName(playerName)

			if (not player) then
				return {false, 'Player not found: '..playerName}
			end

			NetEvents:SendToLocal('HitVoices:PlaySound', player, soundName, character, delay, volume)
			return {'OK'}
		end
	end)
end

function HitVoicesServer:onPlayerJoining(name, playerGuid, ipAddress, accountGuid)
	ChatManager:Yell(name..' Joins the Battle!', 30)
	NetEvents:BroadcastLocal('HitVoices:OnChangeCharacter', name, hitVoices:getCharacter(name))
end

function HitVoicesServer:onSoldierDamage(hookCtx, soldier, info, giverInfo)
	-- player took damage from anything
	if (soldier ~= nil and soldier.player ~= nil and not hitVoices:isBot(soldier.player) and info.damage ~= nil and info.damage > 0) then
		NetEvents:SendToLocal('HitVoices:OnDamageTaken', soldier.player, info.damage, info.boneIndex == 1)
	end
	-- we only care about player to player damage
	if giverInfo ~= nil and giverInfo.giver ~= nil and
		soldier ~= nil and soldier.player ~= nil and
		not (hitVoices:isBot(soldier.player) and hitVoices:isBot(giverInfo.giver)) and
		info.damage ~= nil and info.damage > 0 then
		if (giverInfo.giver.id ~= soldier.player.id) then -- player1 on player2 damage
			local volume = 1
			if (giverInfo.giver.hasSoldier) then
				volume = hitVoices:getVolume(soldier.worldTransform.trans, giverInfo.giver.soldier.worldTransform.trans)
			end

			NetEvents:SendToLocal('HitVoices:OnDamageGiven', giverInfo.giver, soldier.player.name, info.damage, info.boneIndex == 1, volume)
		end
	end
	hookCtx:Pass(soldier, info, giverInfo)
end

function HitVoicesServer:onPlayerKilled(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
	
	-- check for melee kill first
	if (player ~= nil and inflictor ~= nil) then
		local isMelee = false
		if (info.weaponUnlock ~= nil) then
			local weaponId = _G[info.weaponUnlock.typeInfo.name](info.weaponUnlock).debugUnlockId
			if (weaponId == 'U_Knife_Razor' or weaponId == 'U_Knife') then
				isMelee = true
			end
		end
		local volume = 1
		if (player.hasSoldier and inflictor.hasSoldier) then
			volume = hitVoices:getVolume(player.soldier.worldTransform.trans, inflictor.soldier.worldTransform.trans)
		end

		NetEvents:SendToLocal('HitVoices:OnPlayerKilled', player, player.name, inflictor.name, isMelee, volume)
		NetEvents:SendToLocal('HitVoices:OnPlayerKilled', inflictor, player.name, inflictor.name, isMelee, volume)
	end

	-- possible bot kill
	if (player ~= nil and inflictor == nil) then
		NetEvents:SendToLocal('HitVoices:OnPlayerKilled', player, '', false, 1)
	end
end

function HitVoicesServer:onPlayerChat(player, recipientMask, message)

	if player == nil or message == nil then
		return
	end

	local parts = string.lower(message):split(' ')
	if (parts ~= nil and #parts > 0) then
		if (parts[1] == '!voice' and parts[2] ~= nil) then

			local characterName = hitVoices:isValidName(parts[2])

			if (characterName ~= false) then
				NetEvents:BroadcastLocal('HitVoices:OnChangeCharacter', player.name, characterName)
				return
			end
			ChatManager:SendMessage("Choices are: "..hitVoices.showNameChoices, player)
			return
		elseif (#parts == 1 and parts[1] == '!voice') then
			ChatManager:SendMessage("Choices are: "..hitVoices.showNameChoices, player)
		end

		if (parts[1] ~= nil and parts[1]:len() > 2) then
			local characterName = hitVoices:isValidName(parts[1]:sub(2))
			if (characterName ~= false) then
				NetEvents:BroadcastLocal('HitVoices:OnChangeCharacter', player.name, characterName)
				return
			end
		end
		
	end
end

return HitVoicesServer()