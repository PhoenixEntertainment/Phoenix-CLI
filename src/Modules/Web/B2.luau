local Serde = require("@lune/serde")
local Network = require("@lune/net")
local FileSystem = require("@lune/fs")
local Print = require("@util/Print")
local Error = require("@util/Error")
local Base64 = require("@util/Base64")

local B2 = {}

local B2Session = {
	AuthTokens = {
		Session = "",
		Upload = "",
	},
	UploadURL = "",
	DownloadURL = "",
}

local function GetEnvConfigs()
	if FileSystem.isFile(".env") then
		return Serde.decode("toml", FileSystem.readFile(".env"))
	else
		Error("No .env file found! A .env file is required for phoenix to authenticate into B2.")
	end
end

local function GetB2Configs()
	local ExpectedKeys = {
		"PHOENIX_B2_KEY_ID",
		"PHOENIX_B2_KEY_VALUE",
		"PHOENIX_B2_BUCKET_NAME",
		"PHOENIX_B2_BUCKET_ID",
	}

	for _, ExpectedKey in pairs(ExpectedKeys) do
		if GetEnvConfigs()[ExpectedKey] == nil then
			Error(".env file does not specify " .. ExpectedKey .. ", unable to interact with B2!")
		end
	end

	return {
		AuthKeyID = GetEnvConfigs().PHOENIX_B2_KEY_ID,
		AuthKeyValue = GetEnvConfigs().PHOENIX_B2_KEY_VALUE,
		BucketID = GetEnvConfigs().PHOENIX_B2_BUCKET_ID,
		BucketName = GetEnvConfigs().PHOENIX_B2_BUCKET_NAME,
	}
end

local function GetSessionInfo()
	local B2Configs = GetB2Configs()
	local EncodedKey = buffer.tostring(Base64.encode(buffer.fromstring(B2Configs.AuthKeyID .. ":" .. B2Configs.AuthKeyValue)))
	local AuthResponse = Network.request({
		url = "https://api.backblazeb2.com/b2api/v4/b2_authorize_account",
		method = "GET",
		headers = {
			["Authorization"] = "Basic " .. EncodedKey,
		},
	})
	local DecodedResponse = Serde.decode("json", AuthResponse.body)

	if not AuthResponse.ok then
		Print("Failed to auth into b2 : " .. AuthResponse.statusCode .. " " .. AuthResponse.statusMessage, "Error")
		print(DecodedResponse)

		Error("Failed to auth into b2, aborting")
	end

	return DecodedResponse
end

local function CreateB2Session()
	local B2Configs = GetB2Configs()
	local SessionInfo = GetSessionInfo()

	local GetUploadURLResponse = Network.request({
		url = SessionInfo.apiInfo.storageApi.apiUrl .. "/b2api/v4/b2_get_upload_url",
		method = "GET",
		headers = {
			["Authorization"] = SessionInfo.authorizationToken,
		},
		query = {
			["bucketId"] = B2Configs.BucketID,
		},
	})
	local DecodedUploadURLResponse = Serde.decode("json", GetUploadURLResponse.body)

	if not GetUploadURLResponse.ok then
		Print("Failed to create b2 session : " .. GetUploadURLResponse.statusCode .. " " .. GetUploadURLResponse.statusMessage, "Error")
		print(DecodedUploadURLResponse)

		Error("Failed to create b2 session, aborting")
	end

	B2Session = {
		AuthTokens = { Session = SessionInfo.authorizationToken, Upload = DecodedUploadURLResponse.authorizationToken },
		UploadURL = DecodedUploadURLResponse.uploadUrl,
		DownloadURL = SessionInfo.apiInfo.storageApi.downloadUrl,
	}
end

function B2:ReadFile(DestFilePath)
	local ReadResponse = Network.request({
		url = B2Session.DownloadURL .. "/file/" .. GetB2Configs().BucketName .. "/" .. DestFilePath,
		method = "GET",
		headers = {
			["Authorization"] = B2Session.AuthTokens.Session,
		},
	})

	if not ReadResponse.ok then
		if ReadResponse.statusCode ~= 404 then
			local DecodedReadResponse = Serde.decode("json", ReadResponse.body)

			Print("Failed to read file from b2 : " .. ReadResponse.statusCode .. " " .. ReadResponse.statusMessage, "Error")
			print(DecodedReadResponse)

			return false, nil, false
		else
			return false, nil, true
		end
	else
		return true, ReadResponse.body, false
	end
end

function B2:WriteFile(DestFilePath, FileContents)
	local WriteResponse = Network.request({
		url = B2Session.UploadURL,
		method = "POST",
		headers = {
			["Authorization"] = B2Session.AuthTokens.Upload,
			["Content-Type"] = "text/plain",
			["X-Bz-File-Name"] = DestFilePath,
			["X-Bz-Content-Sha1"] = Serde.hash("sha1", FileContents),
			["Content-Length"] = #FileContents,
		},
		body = FileContents,
	})

	if not WriteResponse.ok then
		local DecodedWriteResponse = Serde.decode("json", WriteResponse.body)

		Print("Failed to write file to b2 : " .. WriteResponse.statusCode .. " " .. WriteResponse.statusMessage, "Error")
		print(DecodedWriteResponse)

		return false
	else
		return true
	end
end

CreateB2Session()

return B2
