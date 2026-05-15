--https://github.com/Kong/lua-multipart/tree/master

local RANDOM_BOUNDARY = tostring({}):sub(10)

local function is_header(value)
	return string.match(value, "%S:%s*%S")
end

local function decode(body: string, boundary: string?)
	local result = {
		data = {},
		indexes = {} :: { [string]: { number } },
	}

	if not boundary then
		return result
	end

	local part_name: string?
	local part_index = 1
	local part_headers = {}
	local part_value = {}
	local part_value_ct = 0

	local end_boundary_length = boundary and #boundary + 2
	local processing_part_value = false

	local position = 1
	local done = false

	repeat
		local s = string.find(body, "[\r\n]", position)
		local line

		if s then
			line = string.sub(body, position, s - 1)
			position = s + 1
		else
			if position == 1 then
				line = body
			else
				line = string.sub(body, position)
			end

			done = true
		end

		if line == "" then
			if s and processing_part_value then
				part_value_ct = part_value_ct + 1
				part_value[part_value_ct] = string.sub(body, s, s)
			end
		else
			if string.sub(line, 1, 2) == "--" and string.sub(line, 3, end_boundary_length) == boundary then
				processing_part_value = false

				if part_name ~= nil then
					if part_value[part_value_ct] == "\n" then
						part_value[part_value_ct] = nil
					end

					if part_value[part_value_ct - 1] == "\r" then
						part_value[part_value_ct - 1] = nil
					end

					result.data[part_index] = {
						name = part_name,
						headers = part_headers,
						value = table.concat(part_value),
					}

					if result.indexes[part_name] == nil then
						result.indexes[part_name] = {}
					end

					table.insert(result.indexes[part_name], part_index)

					part_headers = {}
					part_value = {}
					part_value_ct = 0
					part_name = nil
					part_index = part_index + 1
				end
			else
				if not processing_part_value and line:sub(1, 19):lower() == "content-disposition" then
					for v in line:gmatch("[^;]+") do
						if not is_header(v) then
							local pos = v:match("^%s*[Nn][Aa][Mm][Ee]=()")
							if pos then
								local current_value = v:match("^%s*([^=]*)", pos)
								if not current_value then
									continue
								end

								current_value = current_value:gsub("%s*$", "")
								if not current_value then
									continue
								end

								part_name = string.sub(current_value, 2, #current_value - 1)
							end
						end
					end

					table.insert(part_headers, line)

					if s and string.sub(body, s, s + 3) == "\r\n\r\n" then
						processing_part_value = true
						position = s + 4
					end
				elseif not processing_part_value and is_header(line) then
					table.insert(part_headers, line)

					if s and string.sub(body, s, s + 3) == "\r\n\r\n" then
						processing_part_value = true
						position = s + 4
					end
				else
					processing_part_value = true

					part_value_ct = part_value_ct + 1
					part_value[part_value_ct] = line

					if s then
						part_value_ct = part_value_ct + 1
						part_value[part_value_ct] = string.sub(body, s, s)
					end
				end
			end
		end

	until done

	if part_name ~= nil then
		result.data[part_index] = {
			name = part_name,
			headers = part_headers,
			value = table.concat(part_value),
		}
		result.indexes[part_name] = { part_index }
	end

	return result
end

local function encode(t, optionalBoundary: string?)
	local boundary = optionalBoundary or RANDOM_BOUNDARY

	local result = {}
	local i = 0

	for _, v in ipairs(t.data) do
		if v.value then
			result[i + 1] = "--"
			result[i + 2] = boundary
			result[i + 3] = "\r\n"

			i = i + 3

			for _, header in ipairs(v.headers) do
				result[i + 1] = header
				result[i + 2] = "\r\n"

				i = i + 2
			end

			result[i + 1] = "\r\n"
			result[i + 2] = v.value
			result[i + 3] = "\r\n"

			i = i + 3
		end
	end

	if i == 0 then
		return ""
	end

	result[i + 1] = "--"
	result[i + 2] = boundary
	result[i + 3] = "--\r\n"

	return table.concat(result)
end

local multipart = {
	RANDOM_BOUNDARY = RANDOM_BOUNDARY,
}

multipart.__index = multipart
multipart.__tostring = function(self: multipart)
	return encode(self._data, self._boundary)
end

function multipart.get(
	self: multipart,
	name: string
): {
	headers: { string },
	name: string,
	value: string,
}?
	local index = self._data.indexes[name]
	if index then
		return self._data.data[index[1]]
	else
		return nil
	end
end

function multipart.getAll(self: multipart)
	local result = {}

	for k, v in pairs(self._data.indexes) do
		result[k] = self._data.data[v[1]].value
	end

	return result
end

function multipart.getArray(self: multipart, name: string)
	local vals = {}

	local idx = self._data.indexes[name]
	if not idx then
		return vals
	end

	for _, index in ipairs(self._data.indexes[name]) do
		table.insert(vals, self._data.data[index].value)
	end

	return vals
end

function multipart.getAllAsArrays(self: multipart)
	local result = {}

	for k in pairs(self._data.indexes) do
		result[k] = self:getArray(k)
	end

	return result
end

function multipart.getAllWithArrays(self: multipart)
	local result: { [string]: string | { string } } = {}

	for k, v in pairs(self._data.indexes) do
		if #v == 1 then
			result[k] = self._data.data[v[1]].value
		else
			result[k] = self:getArray(k)
		end
	end

	return result
end

function multipart.setSimple(self: multipart, name: string, value: string, filename: string?, content_type: string?)
	local headersArray = { 'Content-Disposition: form-data; name="', name, '"' }
	if filename then
		headersArray[4] = '; filename="'
		headersArray[5] = filename
		headersArray[6] = '"'
	end
	if content_type then
		headersArray[7] = "\r\ncontent-type: "
		headersArray[8] = content_type
	end
	local headers = table.concat(headersArray)
	if self._data.indexes[name] then
		self._data.data[self._data.indexes[name][1]] = {
			name = name,
			value = value,
			headers = { headers },
		}
	else
		local max_index = 0
		for _, indexes in pairs(self._data.indexes) do
			for _, index in ipairs(indexes) do
				if index > max_index then
					max_index = index
				end
			end
		end
		local part_index = max_index + 1
		self._data.indexes[name] = { part_index }
		self._data.data[part_index] = {
			name = name,
			value = value,
			headers = { headers },
		}
	end
end

function multipart.delete(self: multipart, name: string)
	local indexes = self._data.indexes[name]

	if indexes ~= nil then
		for _, index in ipairs(indexes) do
			table.remove(self._data.data, index)
		end
		self._data.indexes[name] = nil

		for key, index_vals in pairs(self._data.indexes) do
			for i, val in ipairs(index_vals) do
				if not val then
					continue
				end

				local num_deleted = 0
				for _, del_index in ipairs(indexes) do
					if not del_index then
						continue
					end

					if val > del_index then
						num_deleted = num_deleted + 1
					end
				end
				self._data.indexes[key][i] = val - num_deleted
			end
		end
	end
end

function multipart.tostring(self: multipart)
	return encode(self._data, self._boundary)
end

local function getBoundry(content_type: string?): string?
	if content_type then
		local boundary = string.match(content_type, ";%s*boundary=(%S+)")
		if boundary then
			if (string.sub(boundary, 1, 1) == '"' and string.sub(boundary, -1) == '"') or (string.sub(boundary, 1, 1) == "'" and string.sub(boundary, -1) == "'") then
				boundary = string.sub(boundary, 2, -2)
			end

			if boundary ~= "" then
				return boundary
			end
		end
	end

	return nil
end

local function new(data: string?, content_type: string?)
	local _boundry = getBoundry(content_type)
	local _data = decode(data or "", _boundry)

	return setmetatable({
		_boundary = _boundry,
		_data = _data,
	}, multipart)
end

export type multipart = typeof(new())

return {
	new = new,
}
