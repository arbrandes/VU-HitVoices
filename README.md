# VU-HitVoices
Loosely based on the fortnite hitmarkers mod; adds character voices, crowd applause, and an announcer.

## Features

### Player Voices
- Players can select their character voice using `!voice` in chat
- Players can also use the console command `vu-hitvoices.Voice`

Current characters are:
- Combine Soldier: `!Combine` or `!Voice Combine`
- Captain Falcon: `!Captain` or `!Voice Captain`
- Incineroar: `!Incineroar` or `!Voice Incineroar`
- Ganondorf: `!Ganon` or `!Voice Ganon`
- Peach: `!Peach` or `!Voice Peach`
- Luigi: `!Luigi` or `!Voice Luigi`
- Wolf: `!Wolf` or `!Voice Wolf`
- Fox: `!Fox` or `!Voice Fox`
- Zombie 1: `!Zombie1` or `!Voice Zombie1`
- Zombie 2: `!Zombie2` or `!Voice Zombie2`
- Zombie 3: `!Zombie3` or `!Voice Zombie3`

Effects can be turned off with the command `!Off` or `!Voice Off` in chat
Names can be partial as long as more than two letters are provided

### Crowd and Announcer
The crowd cheers and awws on kills and deaths.
The announcer calls out joining players and yells Go!

## Player Configuration
These options are available to clients via the in-game console

### `vu-hitvoices.Voice CharacterName`
- **CharacterName** - Sets your current character voice

### `vu-hitvoices.AllowCustom Enabled|Boolean`
- **Enabled** - Boolean true or false. Enable or disable custom triggered server sounds


## Server Configuration
As a server owner you can enable or disable voices available to the clients.
You can also specify which names bots are allowed to use.
All of these settings can be set via RCON or by adding them to your `Startup.txt`

### `vu-hitvoices.Voices`
**Default:** `"Captain,Combine,Ganon,Incineroar,Peach,Wolf,Fox,Luigi,Zombie1,Zombie2,Zombie3,Off"`
- A comma-separated list of characters available to the players

### `vu-hitvoices.BotVoices`
**Default:** `"Zombie1,Zombie2,Zombie3"`
- A comma-separated list of characters available to bots only, bots choose randomly from this list

### `vu-hitvoices.AnnounceBots`
**Default:** `true`
- Enable/Disable joining player announcement for bots

### `vu-hitvoices.KillVoiceMaxRange`
**Default:** `30`
- Max distance for volume fading on kill sounds (Meters)
- `-1` to disable volume fading entirely

## RCON Sound Commands
These can be used to manually trigger sounds for players

Players can disable this feature by using the clientside console command `vu-hitvoices.AllowCustom false`

### `vu-hitvoices.PlayScene PlayerName SceneName [CharacterName] [Volume]`
- **PlayerName** - Specify a player name or `*` for eveyone
- **SceneName** - Specify the scene name. Valid Names: `Spawn` or `SetCharacter`
- **CharacterName** - *Optional* - `Current` to use player's character, `*` for random, or use any valid character name
- **Volume** - *Optional* - Volume level. Float value from 0 to 1

### `vu-hitvoices.PlaySound PlayerName SoundName [CharacterName] [Delay] [Volume]`
- **PlayerName** - Specify a player name or `*` for eveyone
- **SoundName** - Specify the sound name. Valid Names: `Spawn` or `SetCharacter`
- **CharacterName** - *Optional* - `Current` to use player's character, `*` for random, or use any valid character name
- **Delay** - *Optional* - Delay in milliseconds before playing the sound
- **Volume** - *Optional* - Volume level. Float value from 0 to 1

### Valid Sound Names
*Casing is important*
- Custom *
- AnnouncerReady
- AnnouncerGo
- AnnouncerPraise
- AnnounceCharacter
- Connected
- Cheer
- Aww
- Jump
- Taunt
- Death

\* If you specify `Custom` you must use the `CharacterName` argument to specify the path to the sound effect.
Not guaranteed to work with online resources.

## Credit
Original hitmarkers mod: [fortnite-hit-effects](https://github.com/kapraran/VU-mods/tree/master/fortnite-hit-effects)
