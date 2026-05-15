local Process = require("@lune/process")
local Print = require("./Print")

local function Error(ErrorMessage)
	Print(ErrorMessage, "Error")
	Process.exit(1)
end

return Error
