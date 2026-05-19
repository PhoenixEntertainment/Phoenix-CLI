--[=[
	@within TableUtil
	@function Copy
	@param tbl table -- Table to copy
	@param deep boolean? -- Whether or not to perform a deep copy
	@return table

	Creates a copy of the given table. By default, a shallow copy is
	performed. For deep copies, a second boolean argument must be
	passed to the function.

	:::caution No cyclical references
	Deep copies are _not_ protected against cyclical references. Passing
	a table with cyclical references _and_ the `deep` parameter set to
	`true` will result in a stack-overflow.
	:::

	Taken from https://github.com/Sleitnick/RbxUtil/blob/main/modules/table-util/init.luau
]=]
local function Copy<T>(t: T, deep: boolean?): T
	if not deep then
		return (table.clone(t :: any) :: any) :: T
	end
	local function DeepCopy(tbl: { any })
		local tCopy = table.clone(tbl)
		for k, v in tCopy do
			if type(v) == "table" then
				tCopy[k] = DeepCopy(v)
			end
		end
		return tCopy
	end
	return DeepCopy(t :: any) :: T
end

function deep_compare(tbl1, tbl2)
	if tbl1 == tbl2 then
		return true
	end
	for k, v in pairs(tbl1) do
		if type(v) == "table" and type(tbl2[k]) == "table" then
			if not deep_compare(v, tbl2[k]) then
				return false
			end
		else
			if v ~= tbl2[k] then
				return false
			end
		end
	end
	for k in pairs(tbl2) do
		if tbl1[k] == nil then
			return false
		end
	end
	return true
end

return {
	Copy = Copy,
	IsEqual = deep_compare,
}
