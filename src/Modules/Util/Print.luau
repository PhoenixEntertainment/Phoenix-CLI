local StdIO = require("@lune/stdio")

local function Print(Message, MessageType)
	if MessageType == "Warning" then
		StdIO.ewrite(StdIO.color("yellow"))
		StdIO.ewrite("[WARN] ")
		StdIO.ewrite(StdIO.color("reset"))
	elseif MessageType == "Error" then
		StdIO.ewrite(StdIO.color("red"))
		StdIO.ewrite("[ERROR] ")
		StdIO.ewrite(StdIO.color("reset"))
	else
		StdIO.ewrite(StdIO.color("white"))
		StdIO.ewrite("[INFO] ")
		StdIO.ewrite(StdIO.color("reset"))
	end

	StdIO.ewrite(Message)
	print() -- Write newline
end

return Print
