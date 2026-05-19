local FileSystem = require("@lune/fs")
local Serde = require("@lune/serde")
local Roblox = require("@lune/roblox")
local Error = require("@util/Error")

local Auth = {}

local function GetEnvConfigs()
	if FileSystem.isFile(".env") then
		return Serde.decode("toml", FileSystem.readFile(".env"))
	else
		Error("No .env file found! A .env file is required for phoenix to authenticate into Roblox.")
	end
end

function Auth:GetRobloxCookie()
	local Configs = GetEnvConfigs()

	return Configs.PHOENIX_RBX_COOKIE or Roblox.getAuthCookie()
end

function Auth:GetOCKey()
	local Configs = GetEnvConfigs()

	if Configs.PHOENIX_OC_KEY ~= nil then
		return Configs.PHOENIX_OC_KEY
	else
		Error(".env file does not specify PHOENIX_OC_KEY, unable to authenticate into Roblox!")
	end
end

return Auth
