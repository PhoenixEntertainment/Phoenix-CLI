local FileSystem = require("@lune/fs")
local Serde = require("@lune/serde")

return function(FilePath)
	local FileContents = FileSystem.readFile(FilePath)

	return Serde.hash("md5", FileContents)
end
