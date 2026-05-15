local FileSystem = require("@lune/fs")
local RobloxRequest = require("../RobloxRequest")
local GetFileHash = require("../../Util/GetFileHash")
local Table = require("../../Util/Table")
local FormData = require("../FormData/FormData")

local Gamepasses = {}

local function CreateGamepass(UniverseID, GamepassSettings)
	local GamepassFormData = FormData.new()

	for SettingKey, SettingValue in pairs(GamepassSettings) do
		GamepassFormData:append(SettingKey, SettingValue)
	end

	local Response = RobloxRequest("POST", "https://apis.roblox.com/game-passes/v1/universes/" .. UniverseID .. "/game-passes", {
		Body = GamepassFormData:getBody(),
		Headers = {
			["Content-Type"] = GamepassFormData:getHeader(),
		},
	})

	if not Response.Ok then
		return false
	end

	return true, Response.Body.gamePassId
end

local function UpdateGamepass(UniverseID, GamepassID, GamepassSettings)
	local GamepassFormData = FormData.new()

	for SettingKey, SettingValue in pairs(GamepassSettings) do
		GamepassFormData:append(SettingKey, SettingValue)
	end

	local Response = RobloxRequest("PATCH", "https://apis.roblox.com/game-passes/v1/universes/" .. UniverseID .. "/game-passes/" .. GamepassID, {
		Body = GamepassFormData:getBody(),
		Headers = {
			["Content-Type"] = GamepassFormData:getHeader(),
		},
	})

	return Response.Ok
end

local function UpdateGamepassIcon(UniverseID, GamepassID, Icon)
	local GamepassFormData = FormData.new()

	GamepassFormData:append("imageFile", FileSystem.readFile(Icon), "icon.png")

	local Response = RobloxRequest("PATCH", "https://apis.roblox.com/game-passes/v1/universes/" .. UniverseID .. "/game-passes/" .. GamepassID, {
		Body = GamepassFormData:getBody(),
		Headers = {
			["Content-Type"] = GamepassFormData:getHeader(),
		},
	})

	return Response.Ok
end

function Gamepasses:Create(UniverseID, GamepassSettings)
	local CreateSuccess, GamepassID = CreateGamepass(UniverseID, GamepassSettings.Settings)

	if not CreateSuccess then
		return false
	end

	return true, { GamepassID = GamepassID, FileHash = "" }
end

function Gamepasses:Update(UniverseID, GamepassConfig, CurrentGamepassState)
	local NewGamepassState = Table.Copy(CurrentGamepassState, true)
	local UpdateSettingsSuccess = UpdateGamepass(UniverseID, NewGamepassState.GamepassID, GamepassConfig.Settings)

	if not UpdateSettingsSuccess then
		return false
	end

	if GetFileHash(GamepassConfig.File) ~= NewGamepassState.FileHash then
		local Success = UpdateGamepassIcon(UniverseID, NewGamepassState.GamepassID, GamepassConfig.File)

		if not Success then
			return false
		end

		NewGamepassState.FileHash = GetFileHash(GamepassConfig.File)
	end

	return true, NewGamepassState
end

return Gamepasses
