local Serde = require("@lune/serde")

return function()
	return Serde.hash("md5", tostring(os.clock()))
end
