# VU-HitVoices
Based on the fortnite hitmarkers mod; adds character voices, crowd applause, and an announcer.

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

Effects can be turned off with the command `!Off` or `!Voice Off`

### Crowd and Announcer
The crowd cheers and awws on kills and deaths.
The announcer calls out joining players and yells Go!

## Server Configuration
As a server owner you can enable or disable voices available to the clients
You can also specify which names bots are allowed to use

### `vu-hitvoices.Voices`
**Default:** `"Captain,Combine,Ganon,Incineroar,Peach,Wolf,Fox,Luigi,Zombie1,Zombie2,Zombie3,Off"`
- A comma-separated list of characters available to the players

### `vu-hitvoices.BotVoices`
**Default:** `"Zombie1,Zombie2,Zombie3"`
- A comma-separated list of characters available to bots only, bots choose randomly from this list

## Credit
Original hitmarkers mod: [fortnite-hit-effects](https://github.com/kapraran/VU-mods/tree/master/fortnite-hit-effects)
