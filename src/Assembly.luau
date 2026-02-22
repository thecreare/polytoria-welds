local AssemblyMap = require("./AssemblyMap")
local PartMap = require("./PartMap")
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
	_processing: boolean,
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
		_processing = false,
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

--- Anti-race-condition device.
--- In no world should this be needed but it is
function Assembly._AwaitSafe(self: Assembly)
	while self._processing do wait() end
	self._processing = true
end

function Assembly._MarkSafe(self: Assembly)
	self._processing = false
end

function Assembly.AssimilateOtherAssembly(self: Assembly, other: Assembly)
	self:_AwaitSafe()
	-- Anchoring is required because currently it seems
	-- the lua thread is non-blocking to physics
	-- meaning `self.root` and `other.root` will have moved a little
	-- bit in the time it took to assimilate other. Leading to
	-- weird offsets and artifacts.
	-- This has also been done in `SplitIfNecessary`
	self.root.Anchored = true
	other.root.Anchored = true
	for id, part_node in pairs(other.parts) do
		local part = part_node.part
		local world_quat = part.Quaternion
		local world_pos = part.Position
		self:InsertNode(part_node)
		part.Quaternion = world_quat
		part.Position = world_pos
	end
	TableUtil.Clear(other.parts)
	other:Cleanup()
	self.root.Anchored = false
	self:_MarkSafe()
end

function Assembly.SplitIfNecessary(self: Assembly)
	self:_AwaitSafe()
	if not next(self.parts) then
		self:_MarkSafe()
		return
	end
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
			if #current_connected_set > 0 then
				table.insert(groups, current_connected_set)
				current_connected_set = {}
			end
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

	if #groups <= 1 then
		self:_MarkSafe()
		return
	end
	local largest_group
	local largest_group_size = -1
	local new_graphs = {}
	for i, group in pairs(groups) do
		local this_group_size = #group
		if this_group_size > largest_group_size then
			largest_group = group
			largest_group_size = this_group_size
		end

		if i ~= #groups then
			local new_graph = self:_CloneForSplit()
			new_graph.root.Anchored = true
			table.insert(new_graphs, new_graph)
		end
	end

	-- For some reason, the new disconnected parts end up looking really funky (only in multiplayer) if there isn't a delay
	-- between the creation of the root part and the insertion of the children.
	-- This is why the graphs are created above in `new_graphs`
	wait()

	self.root.Anchored = true
	for _, group in pairs(groups) do
		if group == largest_group then continue end

		-- Split off list of node ids
		local new_graph = table.remove(new_graphs)
		for _, node in pairs(group) do
			self:EraseNode(node)
			new_graph:InsertNode(node)
		end
		new_graph.root.Anchored = false
	end
	self.root.Anchored = false
	self:_MarkSafe()
end

function Assembly.Cleanup(self: Assembly)
	self:_AwaitSafe()
	-- I think there can be a race condition where Cleanup gets called again while the assembly is
	--  already in the process of cleaning up. This should be impossible because the cleanup never yields...
	--  and yet it still happens. I'm starting to really dislike the way scripts work in polytoria
	if self.root == nil then
		self:_MarkSafe()
		return
	end
	self.root:Destroy()
	AssemblyMap[self.id] = nil
	for id, node in pairs(self.parts) do
		PartMap[node.part] = nil
	end
	self:_MarkSafe()
end

return Assembly
