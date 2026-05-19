local FileSystem = require("@lune/fs")
local Table = require("@util/Table")
local GetFileHash = require("@util/GetFileHash")
local RobloxRequest = require("@web/RobloxRequest")

local Places = {}

local function CreatePlace(UniverseID)
	local Response = RobloxRequest("POST", "https://apis.roblox.com/universes/v1/user/universes/" .. UniverseID .. "/places", {
		Body = { templatePlaceId = 95206881 },
	}, true)

	if not Response.Ok then
		return false
	end

	return true, Response.Body.placeId
end

local function PublishPlaceFile(UniverseID, PlaceID, PlaceFile)
	local Response = RobloxRequest("POST", "https://apis.roblox.com/universes/v1/" .. UniverseID .. "/places/" .. PlaceID .. "/versions", {
		Headers = {
			["Content-Type"] = "application/octet-stream",
		},
		Query = {
			versionType = "Published",
		},
		Body = FileSystem.readFile(PlaceFile),
	})

	return Response.Ok
end

local function UpdatePlaceSettings(PlaceID, Settings)
	local Response = RobloxRequest("PATCH", "https://develop.roblox.com/v2/places/" .. PlaceID, {
		Body = Settings,
	}, true)

	return Response.Ok
end

function Places:CreateFromExisting(PlaceID)
	return { PlaceID = PlaceID, FileHash = "" }
end

function Places:Create(UniverseID)
	local CreateSuccess, PlaceID = CreatePlace(UniverseID)

	if not CreateSuccess then
		return false
	end

	return true, { PlaceID = PlaceID, FileHash = "" }
end

function Places:Update(UniverseID, PlaceConfig, CurrentPlaceState)
	local NewPlaceState = Table.Copy(CurrentPlaceState, true)
	local UpdateSettingsSuccess = UpdatePlaceSettings(NewPlaceState.PlaceID, PlaceConfig.Settings)

	if not UpdateSettingsSuccess then
		return false
	end

	if GetFileHash(PlaceConfig.File) ~= CurrentPlaceState.FileHash then
		local Success = PublishPlaceFile(UniverseID, NewPlaceState.PlaceID, PlaceConfig.File)

		if not Success then
			return false
		end

		NewPlaceState.FileHash = GetFileHash(PlaceConfig.File)
	end

	return true, NewPlaceState
end

return Places
