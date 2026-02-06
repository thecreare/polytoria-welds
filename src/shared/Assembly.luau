local GenerateUniqueId = require("./GenerateUniqueId")
local PartMap = require("./PartMap")
local PartNode = require("./PartNode.luau")

local Assembly = {}
Assembly.__index = Assembly

local WELD_EPSILON = Vector3.New(0.1)

type PartNode = PartNode.PartNode

export type Assembly = typeof(setmetatable({} :: {
	parts: {[number]: PartNode},
	root: Part,
	id: number,
}, Assembly))

local function _table_find<T>(haystack: {T}, needle: T): number?
	for i, v in ipairs(haystack) do
		if v == needle then
			return i
		end
	end
	return nil
end

local function _table_clear(haystack: {[any]: any})
	for k, _ in pairs(haystack) do
		haystack[k] = nil
	end
end

local function _table_clone(haystack: {[any]: any})
	local new = {}
	for k, v in pairs(haystack) do
		new[k] = v
	end
	return new
end

local function _find_and_erase<T>(haystack: {T}, needle: T)
	local idx = _table_find(haystack, needle)
	assert(idx)
	table.remove(haystack, idx)
end

function Assembly.new(): Assembly
	local root = Instance.New("Part") :: Part
	root.Anchored = false
	root.Color = Color.New(1, 0, 1, 0)
	root.Size = Vector3.New(1)
	root.CastShadows = false
	root.CanCollide = false
	root.Parent = game["Enviroment"]

	local self = setmetatable({
		parts = {},
		root = root,
		id = GenerateUniqueId(),
	}, Assembly)

	-- root.Shared.Assembly = self

	return self
end

function Assembly.InsertNode(self: Assembly, node: PartNode)
	node.part.Parent = self.root
	node.assembly = self
	self.parts[node.id] = node
	self.root.Mass += node.mass
end

function Assembly.MakeWelds(self: Assembly, node: PartNode)
	-- print(`MakeWelds called for {node.id}`)
	local part = node.part
	local intersections = game["Environment"]:OverlapBox(part.Position, part.Size + WELD_EPSILON, part.Rotation)

	for _, other_part in ipairs(intersections) do
		-- print(`{part} is intersecting {other_part}`)
		local other_node = PartMap[other_part]
		if not other_node then continue end
		-- print(`^ ID {node.id} is intersecting {other_node.id}`)
		if self:AreJoined(node, other_node) then continue end
		self:JoinNodes(node, other_node)
	end
end

function Assembly.EraseNode(self: Assembly, node: PartNode)
	node.assembly = nil
	self.parts[node.id] = nil
	self.root.Mass -= node.mass
end

function Assembly.AreJoined(self: Assembly, node_a: PartNode, node_b: PartNode)
	return _table_find(node_a.edges, node_b)
end

function Assembly.JoinNodes(self: Assembly, node_a: PartNode, node_b: PartNode)
	table.insert(node_a.edges, node_b)
	table.insert(node_b.edges, node_a)
end

function Assembly.ClearEdges(self: Assembly, node: PartNode)
	for _, other in pairs(node.edges) do
		_find_and_erase(other.edges, node)
	end
	_table_clear(node.edges)
end

function Assembly._CloneForSplit(self: Assembly): Assembly
	local new = self.new()
	new.root.Position = self.root.Position
	return new
end

function Assembly.SplitIfNecessary(self: Assembly)
	if not next(self.parts) then return end
	local _start_time = os.clock()
	local to_crawl = _table_clone(self.parts)
	local function pop_to_crawl(): PartNode?
		local key, nexthing = next(to_crawl)
		if key == nil then return nil end
		to_crawl[key] = nil
		return nexthing
	end
	local node_stack = {pop_to_crawl()}
	local current_connected_set = {}
	local groups = {}
	while true do
		local node = table.remove(node_stack)
		-- print(`Crawling {node}`)
		if not node then
			table.insert(groups, current_connected_set)
			current_connected_set = {}
			local next_node = pop_to_crawl()
			if not next_node then break end
			table.insert(node_stack, next_node)
			continue
		end
		-- _find_and_erase(to_crawl, node)
		-- to_crawl[node.id] = nil
		table.insert(current_connected_set, node)
		for _, other in pairs(node.edges) do
			if not to_crawl[other.id] then continue end
			if _table_find(node_stack, other) then continue end
			table.insert(node_stack, other)
			to_crawl[other.id] = nil
		end
	end

	print(`Crawl finished, got {#groups} groups`)

	if #groups <= 1 then return end
	local largest_group
	local largest_group_size = -1
	for _, group in pairs(groups) do
		local this_group_size = #group
		if this_group_size > largest_group_size then
			largest_group = group
			largest_group_size = this_group_size
		end
	end

	for _, group in pairs(groups) do
		if group == largest_group then continue end
		if #group == 0 then continue end -- needed?

		-- Split off list of node ids
		local new_graph = self:_CloneForSplit()
		for _, node in pairs(group) do
			self:EraseNode(node)
			new_graph:InsertNode(node)
		end
	end
	local _end_time = os.clock()
	local _ms = string.format("%.2f", (_end_time - _start_time) * 1000)
	print(`Split finished, split {#groups} in {_ms} milliseconds`)
end

return Assembly
