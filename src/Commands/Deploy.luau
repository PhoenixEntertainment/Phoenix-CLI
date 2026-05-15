local FileSystem = require("@lune/fs")
local Serde = require("@lune/serde")
local Roblox = require("@lune/roblox")

local Table = require("../Modules/Util/Table")
local Print = require("../Modules/Util/Print")
local Error = require("../Modules/Util/Error")
local GetUID = require("../Modules/Util/GetUID")
local GetFileHash = require("../Modules/Util/GetFileHash")

local IAC_RESOURCES = {
	Universe = require("../Modules/Web/Resources/Universe"),
	UniverseSettings = require("../Modules/Web/Resources/UniverseSettings"),
	Places = require("../Modules/Web/Resources/Places"),
	SocialLinks = require("../Modules/Web/Resources/SocialLinks"),
	GamePasses = require("../Modules/Web/Resources/GamePasses"),
	DevProducts = require("../Modules/Web/Resources/DevProducts"),
	Badges = require("../Modules/Web/Resources/Badges"),
}

local BASE_IAC_STATE = {
	SchemaVersion = 3,
	Resources = {},
	FirstDeployment = true,
}
local IAC_SCHEMA_MIGRATIONS = {
	["1 -> 2"] = function(IACState)
		for ResourceType, ResourceInstances in pairs(IACState.Resources) do
			if ResourceType == "Places" then
				for _, ResourceInstance in pairs(ResourceInstances) do
					ResourceInstance.Settings = {
						name = "",
						description = "",
						maxPlayerCount = 0,
						socialSlotType = "",
					}
				end
			end
		end

		return IACState
	end,
	["2 -> 3"] = function(IACState)
		IACState.Universe = IACState.Resources.Universe
		IACState.Resources.Universe = nil

		return IACState
	end,
}

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetIACConfigs()
	if FileSystem.isFile("Environments.json") then
		return Serde.decode("json", FileSystem.readFile("Environments.json"))
	else
		Error("No Environments.json file found!")
	end
end

local function EnvironmentExists(EnvName)
	local IACConfigs = GetIACConfigs()

	for _, EnvironmentConfig in pairs(IACConfigs.Environments) do
		if EnvironmentConfig.Name == EnvName then
			return true
		end
	end

	return false
end

local function GetMigratedIACState(State)
	local CurrentState = Table.Copy(State, true)

	for CurrentVersion = CurrentState.SchemaVersion, BASE_IAC_STATE.SchemaVersion - 1 do
		print(CurrentVersion .. " -> " .. CurrentVersion + 1)
		CurrentState = IAC_SCHEMA_MIGRATIONS[CurrentVersion .. " -> " .. CurrentVersion + 1](CurrentState)
	end
	CurrentState.SchemaVersion = BASE_IAC_STATE.SchemaVersion

	return CurrentState
end

local function ReadIACState(ProjName, EnvName)
	local StateFileName = "b2/" .. ProjName .. "/" .. EnvName .. ".json"

	if FileSystem.isFile(StateFileName) then --TODO: Replace this with webcall to file in b2 bucket
		local IACState = Serde.decode("json", FileSystem.readFile(StateFileName))

		if IACState.SchemaVersion ~= BASE_IAC_STATE.SchemaVersion then
			if IACState.SchemaVersion > BASE_IAC_STATE.SchemaVersion then
				Error("IAC state file has a newer schema version than is supported. Is your phoenix CLI install outdated?")
			end

			return GetMigratedIACState(IACState)
		else
			return IACState
		end
	else
		return Table.Copy(BASE_IAC_STATE, true)
	end
end

local function WriteIACState(ProjName, EnvName, IACState)
	if not FileSystem.isDir("b2/" .. ProjName .. "/") then
		FileSystem.writeDir("b2/" .. ProjName .. "/")
	end
	local StateFileName = "b2/" .. ProjName .. "/" .. EnvName .. ".json"

	FileSystem.writeFile(StateFileName, Serde.encode("json", IACState, true))
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Command logic
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function DoInitialSanityChecks(Args)
	if not EnvironmentExists(Args.GetArg("env")) then
		Error("No environment with the name '" .. Args.GetArg("env") .. "' is defined in Environments.json!")
	end

	if GetIACConfigs().Resources.Places == nil then
		Error("No places exist in Environments.json!")
	else
		local RootFound = false

		for _, PlaceConfig in pairs(GetIACConfigs().Resources.Places) do
			if PlaceConfig.IsRoot then
				RootFound = true
				break
			end
		end

		if not RootFound then
			Error("No starter place was defined in Environments.json!")
		end
	end
end

return {
	ExpectedArguments = {
		{ Name = "env", Type = "string" },
	},
	Run = function(Args)
		DoInitialSanityChecks(Args)

		local IACConfigs = GetIACConfigs()
		local EnvName = Args.GetArg("env")
		local IACState = ReadIACState(IACConfigs.ProjectName, EnvName)

		print("Deploying resources to environment '" .. EnvName .. "'...")

		--------------------------------------------
		-- Prepending env name to non-prod places --
		--------------------------------------------
		for _, Env in pairs(IACConfigs.Environments) do
			if Env.Name == EnvName and not Env.IsProduction then
				for _, PlaceConfig in pairs(IACConfigs.Resources.Places) do
					if PlaceConfig.IsRoot then
						PlaceConfig.Settings.name = "[" .. EnvName .. "] " .. PlaceConfig.Settings.name
					end
				end
			end
		end

		----------------------------------------------
		-- Doing first time depoyment if applicable --
		----------------------------------------------
		if IACState.FirstDeployment then
			print("Creating universe for environment...")
			local Success, Universe = IAC_RESOURCES.Universe:Create(IACConfigs.TargetOwnerID)

			if Success then
				local StartPlaceKeyName = ""
				local StartPlaceConfig = {}

				for PlaceKeyName, PlaceConfig in pairs(IACConfigs.Resources.Places) do
					if PlaceConfig.IsRoot then
						StartPlaceKeyName = PlaceKeyName
						StartPlaceConfig = PlaceConfig

						break
					end
				end
				IACState["Universe"] = Universe
				IACState.Resources["Places"] = {
					[StartPlaceKeyName] = { InternalState = IAC_RESOURCES.Places:CreateFromExisting(Universe.RootPlaceID), ConfigState = StartPlaceConfig },
				}
			else
				Error("Failed to create universe for environment, aborting.")
			end

			IACState.FirstDeployment = false
		end

		---------------------------------------------
		-- Creating, updating & deleting resources --
		---------------------------------------------
		for ResourceType, ResourceInstances in pairs(IACConfigs.Resources) do
			local ResourceStates = IACState.Resources[ResourceType] or {}

			IACState.Resources[ResourceType] = ResourceStates

			for ResourceInstanceName, ResourceInstance in pairs(ResourceInstances) do
				local ResourceState = ResourceStates[ResourceInstanceName]
				local ShouldDoUpdate = true

				if ResourceState == nil then -- Resource is defined in config but doesn't exist in state. It's a new resource!
					print("Creating new '" .. ResourceType .. "' resource with ID '" .. ResourceInstanceName .. "'...")

					local Success, NewResourceState = IAC_RESOURCES[ResourceType]:Create(IACState.Universe.UniverseID, ResourceInstance)

					if not Success then
						print("Failed to create '" .. ResourceType .. "' resource, skipping.", "Error")
						ShouldDoUpdate = false
					else
						ResourceStates[ResourceInstanceName] = { InternalState = NewResourceState, ConfigState = ResourceInstance }
						ResourceState = ResourceStates[ResourceInstanceName]
					end
				end

				if ShouldDoUpdate then -- Resouce is defined in the config and exists in state. Update if anything in the config differs from state.
					local IsDifferent = not Table.IsEqual(ResourceInstance, ResourceState.ConfigState)

					if ResourceInstance.File ~= nil then
						if GetFileHash(ResourceInstance.File) ~= ResourceState.InternalState.FileHash then
							IsDifferent = true
						end
					end

					if IsDifferent then
						print("Updating '" .. ResourceType .. "' resource with ID '" .. ResourceInstanceName .. "'...")

						local Success, NewResourceState = IAC_RESOURCES[ResourceType]:Update(IACState.Universe.UniverseID, ResourceInstance, ResourceState.InternalState)

						if not Success then
							Print("Failed to update '" .. ResourceType .. "' resource, skipping.", "Error")
						else
							ResourceStates[ResourceInstanceName] = { InternalState = NewResourceState, ConfigState = ResourceInstance }
						end
					else
						print("Skipping '" .. ResourceType .. "' resource with ID '" .. ResourceInstanceName .. "', no changes found")
					end
				end
			end
		end
		WriteIACState(IACConfigs.ProjectName, EnvName, IACState)
	end,
}
