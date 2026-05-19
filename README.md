# Phoenix-CLI
CLI tool to make the development of system packages and games easier

## 🐉 HERE BE DRAGONS 🐉
This tool was quickly cobbled together in about a week to fulfill our IAC needs, since [mantle](https://mantledeploy.vercel.app/) is no longer maintained and broken in some areas. While it has gone through some testing, it is entirely possible there are various bugs & unforseen limitations with the tool. Be careful when using this tool for production environments!

Documentation is sparse at the moment, we plan to create a proper documentation site in the future.

## Commands

### Deploy
Deploy is an IAC tool that creates & modifies roblox web resources (universes, places, gamepasses, badges, etc) to match the state in a local configuration.

Deploy expects several things:
- An `Environments.json` file in the current working directory that specifies the configuration for the environments. For an example config, please see [here.](./Test/ConfigToFile.luau)
- A `.env` file that contains the following keys:
	- PHOENIX_OC_KEY (string) : Your Roblox opencloud key. Your opencloud key needs the following permissions:
		- `developer-product:read`
		- `developer-product:write`
		- `game-pass:read`
		- `game-pass:write`
		- `legacy-badge:manage`
		- `legacy-universe.badge:manage-and-spend-robux`
		- `legacy-universe.badge:write`
		- `universe-places:write`
		- `universe:write`
	- PHOENIX_B2_KEY_ID (string) : The ID of your backblaze b2 key.
	- PHOENIX_B2_KEY_VALUE (string) : The value of your backblaze b2 key.
	- PHOENIX_B2_BUCKET_ID (string) : The ID of your backblaze b2 bucket.
	- PHOENIX_B2_BUCKET_NAME (string) : The exact name of your backblaze b2 bucket.
		- ***WARNING***: Due to a limitation of the backblaze API, if this name is mispelled phoenix will treat this as an entirely new deployment, and will create a new universe.

Example usage:
`phoenix deploy --env DEV_ND`