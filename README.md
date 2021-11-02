# rtv

Rock The Vote (RTV) is a voting system that allows users to vote for a different gamemode and map to play on for the game Garry's Mod.

This project is a rewrite of [Tyrantelf's MapVote](https://github.com/tyrantelf/gmod-mapvote) and that one was originally made by [Willox](https://github.com/willox/gmod-mapvote). I used this project to learn how Garry's Mod user interface works, so this copied the original design of map vote.


# Usage

The main idea is for users to "rock the vote" whenever they want to do a gamemode or map change. This means multiple users need to rock the vote to get the vote started.

To do this, any user can type out `rtv` in the chat to request a vote to start. If enough users rtv, a vote will start.

The vote is in two parts, the gamemode and the maps associated with that gamemode (depending on the configuration, shown below)

# ULX Commands

This addon has two commands:

- `rtv`
	- Any user can use this command to request a vote to start
- `frtv <'start' or 'stop'>`
	- By default, only superadmins can use this command. This is used to force the vote to start or to stop.

# Requirements

This addon requires ULX and Ulib to function.

### Workshop Links:

- [ULX](https://steamcommunity.com/sharedfiles/filedetails/?id=557962280)
- [ULib](https://steamcommunity.com/workshop/filedetails/?id=557962238)

# Configuration

Its recommended to start the server up with this addon installed first. This will create the default configuration file. You can also create the file, just make sure its the correct name.

Config file can be found in the game's files in the path, (`garrysmod\data\rtv\config.json`)

## Example Config

```json
[
	{
		"gamemode": "sandbox",
		"prefix": [
			"gm_"
		],
		"name": "Sandbox",
		"maps": []
	},

    {
		"gamemode": "terrortown",
		"prefix": [
			"ttt_"
		],
		"name": "Trouble in Terrorist Town",
		"maps": [
            "cs_italy",
            "cs_office"
        ]
	}
]
```

**Note:** Both maps and prefix are optional fields, but one is required to give user options to vote on. Both can be entered (as shown above) and will be combined for all the choices for the user.

### name

- Name of the gamemode. This will show for users rather than the confusing name. For example, for the gamemode `terrortown` it will show the users, `Trouble in Terrorist Town`.

### gamemode

- This is what gamemode to switch to.

### maps

- List of maps to vote on. Make sure to separate the maps with a comma.

### prefix

- This field supports multiple prefixes (separated by a comma). For each prefix, this addon will add all maps matching that prefix. For example, in the configuration above for sandbox gamemode. The prefix is `gm_`, so this will add `gm_flatgrass` and `gm_sandbox` for maps to decide on.


## ConVars

There are two convars:

- `rtv_percentage` default is 0.66
	- The percentage of total players to determine how many RTV votes is required to start a vote. For example, 0.50 would be 50% of players.

- `rtv_time` default is 30
	- How long (in seconds) a vote will last
