local GenerateUniqueId = require("./GenerateUniqueId")
local PartMap = require("./PartMap")

local PartNode = {}
PartNode.__index = PartNode

export type PartNode = typeof(setmetatable({} :: {
	part: Part,
	edges: {PartNode},
	id: number,
	assembly: unknown,
	mass: number,
}, PartNode))

function PartNode.new(): PartNode
	local self = setmetatable({
		part = nil :: any,
		edges = {},
		id = GenerateUniqueId(),
		mass = 1,
	}, PartNode)

	return self
end

function PartNode.AssignPart(self: PartNode, new_part: Part)
	PartMap[new_part] = self
	self.part = new_part
	self.mass = new_part.Size.magnitude
	new_part.Anchored = true
end

return PartNode
