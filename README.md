# BM:RP - Black Mesa Roleplay Gamemode

BM:RP is a SourceMod plugin for Black Mesa, adding a roleplay gamemode with role management, economy, salaries, and immersive commands.

## Features

- Role selection: Scientist, Guard, Technician, HECU
- Money and salary system based on role
- RP commands: `/role`, `/money`, `/pay`, `/me`
- Friendly fire configurable in the cfg file
- Automatic equipment assignment based on role
- Role selection menu at spawn (optional)
- Random teleportation to a spawn point when changing roles (info_player_deathmatch)

## Installation

1. Install a Black Mesa server on Steam (Black Mesa Dedicated Server in your game library) tutorial: https://steamcommunity.com/sharedfiles/filedetails/?id=3495150160
2. Install MetaMod:Source (https://www.sourcemm.net/downloads.php?branch=stable) and SourceMod (https://www.sourcemod.net/downloads.php?branch=stable) to the latest version
3. Extract the zip archive into the `bms` folder on your server
4. Configure the server settings in `cfg/sourcemod/bm_rp.cfg`
5. Start the server

## Player Commands

- `/role`: Opens the role selection menu
- `/money`: Displays your money
- `/pay <userid> <amount>`: Transfers money to another player
- `/me <action>`: Performs an RP action (e.g., `/me searches the table`)

To know a player's `<userid>`, simply type `status` in the game console. It is written to the left of the player's username.

## Configuration variables (ConVars)

- `bm_rp_ffscale`: Damage scale between players (0 = disabled, 1 = normal)
- `bm_rp_forcemenu`: Forces the role menu to spawn (1 = yes)
- `bm_rp_startmoney`: Starting money
- `bm_rp_salary_interval`: Interval between each salary (in seconds)
- `bm_rp_salary_scientist`: Scientists' salary
- `bm_rp_salary_tech`: Technicians' salary
- `bm_rp_salary_guard`: Guards' salary
- `bm_rp_salary_hecu`: HECU salary

---

> This is only the beta version, so there are not many features and there may be bugs.

> For any suggestions or bugs, open an issue on this GitHub repository!