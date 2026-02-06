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

function PartNode.AssignGenericPart(self: PartNode)
	local new_part = Instance.New("Part") :: Part
	new_part.Color = Color.Random()
	new_part.Anchored = true
	self:AssignPart(new_part)
end

function PartNode.AssignPart(self: PartNode, new_part: Part)
	PartMap[new_part] = self
	self.part = new_part
	self.mass = new_part.Size.magnitude
end

return PartNode
