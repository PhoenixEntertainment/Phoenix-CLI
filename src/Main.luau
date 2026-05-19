local Process = require("@lune/process")
local Error = require("@util/Error")

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function TableHasKeyFuzzy(Table, KeyName)
	for Key, _ in pairs(Table) do
		if string.lower(Key) == string.lower(KeyName) then
			return true
		end
	end

	return false
end

local function TableGetKeyFuzzy(Table, KeyName)
	for Key, Value in pairs(Table) do
		if string.lower(Key) == string.lower(KeyName) then
			return Value
		end
	end

	return nil
end

local function IsArgFlag(Arg)
	return string.find(Arg, "--", 1, true) ~= nil
end

local function GetFlagName(Flag)
	return string.split(Flag, "--")[2]
end

local function GetArgsWithParams()
	local Args = table.clone(Process.args)
	local ArgsWithParams = {}
	local ArgIndex = 1

	local function GetArg(ArgName)
		for _, Arg in pairs(ArgsWithParams) do
			if Arg.Name == ArgName then
				return Arg.Value or true
			end
		end
	end

	table.remove(Args, 1)

	while ArgIndex <= #Args do
		if not IsArgFlag(Args[ArgIndex]) then
			Error("Malformed argument, expected '--' in argument #" .. ArgIndex + 1 .. ", '" .. Args[ArgIndex] .. "'")
		end
		local ArgName = string.lower(GetFlagName(Args[ArgIndex]))
		local ArgValue = Args[ArgIndex + 1]

		if ArgValue ~= nil and IsArgFlag(ArgValue) then
			ArgValue = nil
		end

		table.insert(ArgsWithParams, {
			Name = ArgName,
			Value = ArgValue,
		})

		if ArgValue ~= nil then
			ArgIndex = ArgIndex + 2
		else
			ArgIndex = ArgIndex + 1
		end
	end

	return { Raw = ArgsWithParams, GetArg = GetArg }
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Runtime logic
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Commands = {
	Deploy = require("./Commands/Deploy"),

	["--Version"] = {
		ExpectedArguments = {},
		Run = function()
			print("v1.0.0")
		end,
	},
	["--Help"] = {
		ExpectedArguments = {},
		Run = function()
			local CurrentCommands = {
				{
					Command = "deploy --env <EnvName>",
					Description = "IAC tool that creates & modifies roblox web resources to match the state in a local configuration",
				},
				{
					Command = "--version",
					Description = "Displays phoenix's current version",
				},
				{
					Command = "--help",
					Description = "Displays this help message",
				},
			}
			local MaxColumnWidth = 0

			for _, Command in pairs(CurrentCommands) do
				MaxColumnWidth = math.max(MaxColumnWidth, #Command.Command)
			end
			MaxColumnWidth = MaxColumnWidth + 4

			print("Phoenix, a CLI utility to make developer QoL better")
			print()
			print("COMMANDS")
			print("---------")

			for _, Command in pairs(CurrentCommands) do
				local PaddingString = string.rep(" ", MaxColumnWidth - #Command.Command)
				print(Command.Command .. PaddingString .. Command.Description)
			end
		end,
	},
}

if Process.args[1] == nil then
	Error("No command was given. Correct usage of phoenix CLI is `phoenix <command> [args]`.")
end

if not TableHasKeyFuzzy(Commands, Process.args[1]) then
	Error("Unknown command '" .. Process.args[1] .. "'")
end

local Command = TableGetKeyFuzzy(Commands, Process.args[1])
local Args = GetArgsWithParams()

for _, ExpectedArg in pairs(Command.ExpectedArguments) do
	if Args.GetArg(ExpectedArg.Name) == nil then
		Error("Command '" .. Process.args[1] .. "' expects '--" .. ExpectedArg.Name .. "' to be passed.")
	elseif typeof(Args.GetArg(ExpectedArg.Name)) ~= ExpectedArg.Type then
		Error("Command '" .. Process.args[1] .. "' expects argument '--" .. ExpectedArg.Name .. "' to be a " .. ExpectedArg.Type .. ".")
	end
end

Command.Run(Args)
