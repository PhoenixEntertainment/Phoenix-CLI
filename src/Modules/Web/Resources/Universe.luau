local RobloxRequest = require("@web/RobloxRequest")

local Universe = {}

function Universe:Create(OwnerID)
	local Response = RobloxRequest("POST", "https://apis.roblox.com/universes/v1/universes/create", {
		Body = { templatePlaceId = 95206881 },
		Query = { groupId = OwnerID },
	}, true)

	if not Response.Ok then
		return false
	end

	return true, { UniverseID = Response.Body.universeId, RootPlaceID = Response.Body.rootPlaceId }
end

return Universe
