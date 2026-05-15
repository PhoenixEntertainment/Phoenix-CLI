local RobloxRequest = require("../RobloxRequest")

local UniverseSettings = {}

local function UpdateUniverseSettings(UniverseID, NewSettings)
	local Response = RobloxRequest("PATCH", "https://develop.roblox.com/v2/universes/" .. UniverseID .. "/configuration", {
		Body = NewSettings,
	}, true)

	if not Response.Ok then
		return false
	end

	return true, {}
end

function UniverseSettings:Create(UniverseID, Settings)
	return UpdateUniverseSettings(UniverseID, Settings)
end

function UniverseSettings:Update(UniverseID, Settings)
	return UpdateUniverseSettings(UniverseID, Settings)
end

return UniverseSettings
