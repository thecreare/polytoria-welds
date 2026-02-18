local AssemblyMap = require("./AssemblyMap")
local GenerateUniqueId = require("./GenerateUniqueId")
local PartNode = require("./PartNode.luau")
local TableUtil = require("./TableUtil")

local Assembly = {}
Assembly.__index = Assembly
Assembly.DEBUG_MODE_ENABLED = false

type PartNode = PartNode.PartNode

export type Assembly = typeof(setmetatable({} :: {
	parts: {[number]: PartNode},
	root: Part,
	id: number,
	debug_color: Color,
}, Assembly))

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
		debug_color = Color.Random(),
	}, Assembly)

	AssemblyMap[self.id] = self

	return self
end

function Assembly.InsertNode(self: Assembly, node: PartNode)
	node.part.Parent = self.root
	node.assembly = self
	self.parts[node.id] = node
	self.root.Mass += node.mass
	if Assembly.DEBUG_MODE_ENABLED then
		node.part.Color = self.debug_color
	end
end

function Assembly.EraseNode(self: Assembly, node: PartNode)
	node.assembly = nil
	self.parts[node.id] = nil
	self.root.Mass -= node.mass
end

function Assembly.AreJoined(self: Assembly, node_a: PartNode, node_b: PartNode)
	return TableUtil.Find(node_a.edges, node_b)
end

function Assembly.JoinNodes(self: Assembly, node_a: PartNode, node_b: PartNode)
	table.insert(node_a.edges, node_b)
	table.insert(node_b.edges, node_a)
end

function Assembly.EraseEdge(self: Assembly, node_a: PartNode, node_b: PartNode)
	TableUtil.FindAndErase(node_a.edges, node_b)
	TableUtil.FindAndErase(node_b.edges, node_a)
end

function Assembly.ClearEdges(self: Assembly, node: PartNode)
	for _, other in pairs(node.edges) do
		TableUtil.FindAndErase(other.edges, node)
	end
	TableUtil.Clear(node.edges)
end

function Assembly._CloneForSplit(self: Assembly): Assembly
	local new = self.new()
	new.root.Position = self.root.Position
	return new
end

function Assembly.AssimilateOtherAssembly(self: Assembly, other: Assembly)
	for id, part_node in pairs(other.parts) do
		local part = part_node.part
		local world_quat = part.Quaternion
		local world_pos = part.Position
		self:InsertNode(part_node)
		part.Quaternion = world_quat
		part.Position = world_pos
	end
	-- TODO: Dispose of other
end

function Assembly.SplitIfNecessary(self: Assembly)
	if not next(self.parts) then return end
	local already_crawled = {}

	local last_parts_key = nil
	local function pop_to_crawl(): PartNode?
		while true do
			local key, next_node = next(self.parts, last_parts_key)
			if key == nil then return nil end
			last_parts_key = key
			if already_crawled[next_node] then continue end
			already_crawled[next_node] = true
			return next_node
		end
	end
	local node_stack = {pop_to_crawl()}
	local current_connected_set = {}
	local groups = {}
	while true do
		local node = table.remove(node_stack)
		if not node then
			table.insert(groups, current_connected_set)
			current_connected_set = {}
			local next_node = pop_to_crawl()
			if not next_node then break end
			table.insert(node_stack, next_node)
			continue
		end
		table.insert(current_connected_set, node)
		for _, other in pairs(node.edges) do
			if already_crawled[other] then continue end
			table.insert(node_stack, other)
			already_crawled[other] = true
		end
	end

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
end

return Assembly
