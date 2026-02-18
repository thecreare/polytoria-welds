local TableUtil = {}

function TableUtil.Find<T>(haystack: {T}, needle: T): number?
	for i, v in ipairs(haystack) do
		if v == needle then
			return i
		end
	end
	return nil
end

function TableUtil.Clear(haystack: {[any]: any})
	for k, _ in pairs(haystack) do
		haystack[k] = nil
	end
end

function TableUtil.Clone(haystack: {[any]: any})
	local new = {}
	for k, v in pairs(haystack) do
		new[k] = v
	end
	return new
end

function TableUtil.FindAndErase<T>(haystack: {T}, needle: T)
	local idx = TableUtil.Find(haystack, needle)
	assert(idx)
	table.remove(haystack, idx)
end

return TableUtil