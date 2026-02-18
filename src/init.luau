local Environment = game["Environment"]

local Assembly = require("src/Assembly")
local PartNode = require("src/PartNode")
local AssemblyMap = require("src/AssemblyMap")
local PartMap = require("src/PartMap")

export type Assembly = Assembly.Assembly
export type PartNode = PartNode.PartNode

local BASE_WELD_EPSILON = Vector3.New(0.1)

function GetOrCreateNode(part: Part): PartNode
	local node = PartMap[part]
	if node then return node end
	local new_node = PartNode.new()
	new_node:AssignPart(part)
	return new_node
end

--- Safely creates a weld between two parts, handles parts being initialized, unutilized, and part of separate graphs
function CreateWeld(part_a: Part, part_b: Part)
	assert(part_a and part_b, "CreateWeld expects two parts")
	local a = GetOrCreateNode(part_a)
	local b = GetOrCreateNode(part_b)
	
	local a_asm: Assembly? = a.assembly
	local b_asm: Assembly? = b.assembly
	
	if a_asm and b_asm and a_asm ~= b_asm then
		a_asm:AssimilateOtherAssembly(b_asm)
		a_asm:JoinNodes(a, b)
	elseif a_asm and b_asm then
		if a_asm:AreJoined(a, b) then return end
		a_asm:JoinNodes(a, b)
	elseif a_asm then
		a_asm:InsertNode(b)
		a_asm:JoinNodes(a, b)
	elseif b_asm then
		b_asm:InsertNode(a)
		b_asm:JoinNodes(a, b)
	else
		local asm = Assembly.new()
		asm:InsertNode(a)
		asm:InsertNode(b)
		asm:JoinNodes(a, b)
	end
end

--- Removes a weld between two parts, does noting if the parts are unutilized or otherwise not welded
function RemoveWeld(part_a: Part, part_b: Part)
	assert(part_a and part_b, "RemoveWeld expects two parts")
	local a = PartMap[part_a]
	local b = PartMap[part_b]
	if not a or not b then return end
	if a.assembly ~= b.assembly then return end
	local assembly: Assembly = a.assembly
	assembly:EraseEdge(a, b)
end

--- Removes all the welds of a part, fully detaching it
function ClearWelds(part: Part)
	assert(part, "ClearWelds expects one part")
	local part_node = PartMap[part]
	if not part_node then return end
	local assembly: Assembly = part_node.assembly
	assembly:ClearEdges(part_node)
	assembly:SplitIfNecessary()
end

--- Same as `Welder:ClearWelds(part: Part)` except it operates on a table of parts.
--- This will be much faster when clearing welds on many individual parts in the same assembly
--- NOTE: Polytoria is jank and so this needs to be `:Call`-ed which doesn't support tables so it
---  uses a vararg which may make this really slow. I am yet to test
function ClearWeldsBulk(...: Part)
	local assemblies: {[Assembly]: boolean} = {}

	for _, part in ipairs({...}) do
		local part_node = PartMap[part]
		if not part_node then continue end
		local assembly: Assembly = part_node.assembly
		assembly:ClearEdges(part_node)
		assemblies[assembly] = true
	end

	for assembly, _ in pairs(assemblies) do
		assembly:SplitIfNecessary()
	end
end

--- Creates welds to nearby parts using Environment:OverlapBox. Optionally an ignore list & epsilon can be supplied
--- NOTE: Polytoria is jank and so this needs to be `:Call`-ed which doesn't support tables so it
---  uses a vararg for the ignore list which may make this really slow. I am yet to test
function MakeWelds(part: Part, epsilon: number?, ...: DynamicInstance)
	assert(part, "MakeWelds expects one part")
	local weld_epsilon = if epsilon then Vector3.New(epsilon) else BASE_WELD_EPSILON
	local intersections = Environment:OverlapBox(part.Position, part.Size + weld_epsilon, part.Rotation, {...})

	for _, other_part in ipairs(intersections) do
		CreateWeld(part, other_part)
	end
end

--- Wrapper for part:Destroy(), handles updating of any linked assemblies.
--- This should ALWAYS be used when dealing with parts that may be part of an assembly.
function DestroyPart(part: Part)
	assert(part, "MakeWelds expects one part")
	ClearWelds(part)
	PartMap[part] = nil
	part:Destroy()
end

--- Same as `Welder:DestroyPart(part: Part)` except it operates on a table of parts.
--- Similar `Welder:ClearWeldsBulk(parts: {Part})`, this will be much faster when clearing welds on many individual parts in the same assembly
--- NOTE: Polytoria is jank and so this needs to be `:Call`-ed which doesn't support tables so it
---  uses a vararg which may make this really slow. I am yet to test
function DestroyPartsBulk(...: Part)
	local parts = {...}
	ClearWeldsBulk(parts)
	for _, part in ipairs(parts) do
		PartMap[part] = nil
		part:Destroy()
	end
end

function PrintDebugInfo()
	local assembly_count = 0
	local part_count = 0

	for _, _ in pairs(PartMap) do
		part_count += 1
	end

	for _, _ in pairs(AssemblyMap) do
		assembly_count += 1
	end

	print(`There are {part_count} parts and {assembly_count} assemblies`)
end

function SetDebugEnabled(enabled: boolean)
	Assembly.DEBUG_MODE_ENABLED = enabled
end
