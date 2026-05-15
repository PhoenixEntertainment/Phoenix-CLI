local FileSystem = require("@lune/fs")
local RobloxRequest = require("../RobloxRequest")
local GetFileHash = require("../../Util/GetFileHash")
local Table = require("../../Util/Table")
local FormData = require("../FormData/FormData")

local Badges = {}

local function CreateBadge(UniverseID, BadgeSettings, Icon)
	local BadgeFormData = FormData.new()

	BadgeFormData:append("Files", FileSystem.readFile(Icon), "icon.png")
	BadgeFormData:append("name", BadgeSettings.name)
	BadgeFormData:append("paymentSourceType", 2)
	BadgeFormData:append("expectedCost", 0)
	BadgeFormData:append("isActive", false)

	local Response = RobloxRequest("POST", "https://apis.roblox.com/legacy-badges/v1/universes/" .. UniverseID .. "/badges", {
		Body = BadgeFormData:getBody(),
		Headers = {
			["Content-Type"] = BadgeFormData:getHeader(),
		},
	})

	if not Response.Ok then
		return false
	end

	return true, Response.Body.id
end

local function UpdateBadge(UniverseID, BadgeID, BadgeSettings)
	local Response = RobloxRequest("PATCH", "https://apis.roblox.com/legacy-badges/v1/badges/" .. BadgeID, {
		Body = BadgeSettings,
	})

	return Response.Ok
end

local function UpdateBadgeIcon(UniverseID, BadgeID, Icon)
	local BadgeFormData = FormData.new()

	BadgeFormData:append("Files", FileSystem.readFile(Icon), "icon.png")

	local Response = RobloxRequest("POST", "https://apis.roblox.com/legacy-publish/v1/badges/" .. BadgeID .. "/icon", {
		Body = BadgeFormData:getBody(),
		Headers = {
			["Content-Type"] = BadgeFormData:getHeader(),
		},
	})

	return Response.Ok
end

function Badges:Create(UniverseID, BadgeSettings)
	local CreateSuccess, BadgeID = CreateBadge(UniverseID, BadgeSettings.Settings, BadgeSettings.File)

	if not CreateSuccess then
		return false
	end

	return true, { BadgeID = BadgeID, FileHash = "" }
end

function Badges:Update(UniverseID, BadgeConfig, CurrentBadgeState)
	local NewBadgeState = Table.Copy(CurrentBadgeState, true)
	local UpdateSettingsSuccess = UpdateBadge(UniverseID, NewBadgeState.BadgeID, BadgeConfig.Settings)

	if not UpdateSettingsSuccess then
		return false
	end

	if GetFileHash(BadgeConfig.File) ~= NewBadgeState.FileHash then
		local Success = UpdateBadgeIcon(UniverseID, NewBadgeState.BadgeID, BadgeConfig.File)

		if not Success then
			return false
		end

		NewBadgeState.FileHash = GetFileHash(BadgeConfig.File)
	end

	return true, NewBadgeState
end

return Badges
