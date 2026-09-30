# RandomizedNPC

System to create background NPCs to populate an area. NPCs will walk along predetermined, random paths and can
move to nearby doors and also wander off main paths.

## Brief Structure

- NPCs spawn in and are visually added through highlights and `TweenService`
- Movement follows pre-created branches made of attachment points, and NPCs may walk along them
and continue onto any linked branches based on predetermined data
- NPCs occasionally stop partway down a branch and wander a short random
  distance off the path, using raycasts to avoid walking through obstacles.
- Each NPC has a randomized lifetime and after it expires, can exit through the entrance or go through a door
- NPCs are visually randomized through a collection of clothing/faces/hairs etc.

## Structure

```
/ReplicatedStorage
    Functions.lua
    CharacterRandomizer.lua
    RandomizedNPC.lua
    /Info
        RandomizedNPCData.lua
/StarterPlayer
    /StarterPlayerScripts
        RandomizedNPCSpawner.lua

* Assets in studio not included (character models, accessories, hair, face textures)
* Scripts require these modules (and the third-party dependencies below) through a `Modules` folder
  under `ReplicatedStorage` in Studio — place the files above inside that folder when setting the project up.
```

## Usage

```lua
local npc = RandomizedNPC.new(character, pathFolder, pathData, settings, spawnSettings)
```

| Param | Description |
|---|---|
| `character` | The NPC's character model (must have a `Humanoid` and `HumanoidRootPart`) |
| `pathFolder` | Folder containing the `Branches` (and optionally `Doors`, `SpawnPoints`) for this NPC's area |
| `pathData` | Table describing how branches link together (`LinkTo`, `LinkFrom`, `ReverseLinkTo` per branch) |
| `settings` | *(optional)* Overrides for lifetime, wait times, walk/run speed ranges, and wander offset. Falls back to defaults if omitted |
| `spawnSettings` | *(optional)* Used to spawn an NPC mid-route (e.g. resuming a specific branch) instead of at a fresh spawn point |

## Dependencies

- [evaera/roblox-lua-promise](https://github.com/evaera/roblox-lua-promise) - not included; place in `ReplicatedStorage/Modules` as `Promise`
- [howmanysmall/Janitor](https://github.com/howmanysmall/Janitor) - not included; place in `ReplicatedStorage/Modules` as `Janitor`
- [1ForeverHD/ZonePlus](https://github.com/1ForeverHD/ZonePlus) - not included; place in `ReplicatedStorage/Modules` as `Zone`
