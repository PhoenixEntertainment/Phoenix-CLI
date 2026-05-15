local RobloxRequest = require("../RobloxRequest")

local SocialLinks = {}

local function UpdateUniverseSocialLinks(UniverseID, NewSocialLinks)
	local Response = RobloxRequest("PATCH", "https://apis.roblox.com/cloud/v2/universes/" .. UniverseID, {
		Body = NewSocialLinks,
	})

	if not Response.Ok then
		return false
	end

	return true, {}
end

function SocialLinks:Create(UniverseID, NewSocialLinks)
	return UpdateUniverseSocialLinks(UniverseID, NewSocialLinks)
end

function SocialLinks:Update(UniverseID, NewSocialLinks)
	return UpdateUniverseSocialLinks(UniverseID, NewSocialLinks)
end

return SocialLinks
