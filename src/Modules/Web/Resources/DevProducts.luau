local FileSystem = require("@lune/fs")
local Table = require("@util/Table")
local RobloxRequest = require("@web/RobloxRequest")
local GetFileHash = require("@util/GetFileHash")
local FormData = require("@vendor/DiscordLuau/FormData/FormData")

local Devproducts = {}

local function CreateDevproduct(UniverseID, DevproductSettings)
	local DevproductFormData = FormData.new()

	for SettingKey, SettingValue in pairs(DevproductSettings) do
		DevproductFormData:append(SettingKey, SettingValue)
	end

	local Response = RobloxRequest("POST", "https://apis.roblox.com/developer-products/v2/universes/" .. UniverseID .. "/developer-products", {
		Body = DevproductFormData:getBody(),
		Headers = {
			["Content-Type"] = DevproductFormData:getHeader(),
		},
	})

	if not Response.Ok then
		return false
	end

	return true, Response.Body.productId
end

local function UpdateDevproduct(UniverseID, DevproductID, DevproductSettings)
	local DevproductFormData = FormData.new()

	for SettingKey, SettingValue in pairs(DevproductSettings) do
		DevproductFormData:append(SettingKey, SettingValue)
	end

	local Response = RobloxRequest("PATCH", "https://apis.roblox.com/developer-products/v2/universes/" .. UniverseID .. "/developer-products/" .. DevproductID, {
		Body = DevproductFormData:getBody(),
		Headers = {
			["Content-Type"] = DevproductFormData:getHeader(),
		},
	})

	return Response.Ok
end

local function UpdateDevproductIcon(UniverseID, DevproductID, Icon)
	local DevproductFormData = FormData.new()

	DevproductFormData:append("imageFile", FileSystem.readFile(Icon), "icon.png")

	local Response = RobloxRequest("PATCH", "https://apis.roblox.com/developer-products/v2/universes/" .. UniverseID .. "/developer-products/" .. DevproductID, {
		Body = DevproductFormData:getBody(),
		Headers = {
			["Content-Type"] = DevproductFormData:getHeader(),
		},
	})

	return Response.Ok
end

function Devproducts:Create(UniverseID, DevproductSettings)
	local CreateSuccess, DevproductID = CreateDevproduct(UniverseID, DevproductSettings.Settings)

	if not CreateSuccess then
		return false
	end

	return true, { DevproductID = DevproductID, FileHash = "" }
end

function Devproducts:Update(UniverseID, DevproductConfig, CurrentDevproductState)
	local NewDevproductState = Table.Copy(CurrentDevproductState, true)
	local UpdateSettingsSuccess = UpdateDevproduct(UniverseID, NewDevproductState.DevproductID, DevproductConfig.Settings)

	if not UpdateSettingsSuccess then
		return false
	end

	if GetFileHash(DevproductConfig.File) ~= NewDevproductState.FileHash then
		local Success = UpdateDevproductIcon(UniverseID, NewDevproductState.DevproductID, DevproductConfig.File)

		if not Success then
			return false
		end

		NewDevproductState.FileHash = GetFileHash(DevproductConfig.File)
	end

	return true, NewDevproductState
end

return Devproducts
