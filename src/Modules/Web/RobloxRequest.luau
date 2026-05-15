local Serde = require("@lune/serde")
local Network = require("@lune/net")
local Print = require("../Util/Print")
local RobloxAuth = require("./RobloxAuth")

local CSRF_Token = ""

local function UpdateCSRFToken()
	local Response = Network.request({
		url = "https://auth.roblox.com/v2/logout",
		method = "POST",
		headers = { ["Cookie"] = RobloxAuth:GetRobloxCookie() },
	})

	CSRF_Token = Response.headers["x-csrf-token"]
end

return function(Method, URL, Arguments, IsCookieBased)
	if CSRF_Token == "" then
		UpdateCSRFToken()
	end

	if Arguments.Headers == nil then
		Arguments.Headers = {}
	end

	if IsCookieBased then
		Arguments.Headers["x-csrf-token"] = CSRF_Token
		Arguments.Headers["Cookie"] = RobloxAuth:GetRobloxCookie()
	else
		Arguments.Headers["x-api-key"] = RobloxAuth:GetOCKey()
	end

	if Arguments.Headers["Content-Type"] == nil then
		Arguments.Headers["Content-Type"] = "application/json"
		Arguments.Body = Serde.encode("json", Arguments.Body)
	end

	local Response = Network.request({
		url = URL,
		method = Method,
		headers = Arguments.Headers,
		body = Arguments.Body,
		query = Arguments.Query,
	})
	local ResponseBody = Response.body ~= "" and Response.body or "{}"

	local DecodedResponse = {
		Ok = Response.ok,
		StatusCode = Response.statusCode,
		Headers = Response.headers,
		Body = Serde.decode("json", ResponseBody),
	}

	if not Response.ok then
		Print("Roblox web request failed : " .. Response.statusCode .. " " .. Response.statusMessage, "Error")
		if ResponseBody ~= "{}" then
			print(DecodedResponse.Body)
		end
	end

	return DecodedResponse
end
