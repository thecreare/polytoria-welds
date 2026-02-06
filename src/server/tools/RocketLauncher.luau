local PartMap = require("shared/PartMap")
local MAX_DIST = 500
local EXPLOSION_RADIUS = 6
local ROCKET_SPEED = 75
local ENVIRONMENT = game["Environment"]

local function SpawnRocket(from: Vector3, to: Vector3)
	local rocket = Instance.New("Part") :: Part
	rocket.CanCollide = false
	rocket.Size = Vector3.New(0.2, 0.2, 1)
	rocket.Color = Color.New(1, 0, 0)
	rocket.Parent = ENVIRONMENT

	local init_time = os.clock()
	spawn(function()
		while true do
			local move_dist = (os.clock() - init_time) * ROCKET_SPEED
			if move_dist >= math.min(MAX_DIST, (to - from).magnitude) then
				rocket.Position = to
				break
			end
			rocket.Position = from + (to - from).normalized * move_dist
			rocket:LookAt(to)
			wait()
		end
		rocket:Destroy()

		local hit_assemblies = {}

		local function DamagePart(part: Part)
			if part.ClassName ~= "Part" then return end
			part:AddForce((to - part.Position).normalized * 5, ForceMode.Impulse)
			local node = PartMap[part]
			if not node then return end
			local assembly = node.assembly
			assembly:ClearEdges(node)
			table.insert(hit_assemblies, assembly)
		end

		ENVIRONMENT:CreateExplosion(to, EXPLOSION_RADIUS, 0, false, DamagePart, 10)

		for _, assembly in ipairs(hit_assemblies) do
			assembly:SplitIfNecessary()
		end

		-- local explode = Instance.New("Part") :: Part
		-- explode.CanCollide = false
		-- explode.q
		-- explode.CastShadows = false
		-- explode.Color = Color.New(1, 0.5, 0, 0.5)
		-- explode.Shape = PartShape.Ball
		-- explode.Size = Vector3.New(EXPLOSION_RADIUS * 2)
		-- explode.Position = to
		-- explode.Parent = ENVIRONMENT
		-- wait(0.2)
		-- explode:Destroy()
	end)
end

return function()
	local tool = Instance.New("Tool") :: Tool
	tool.Droppable = false
	tool.Name = "Rocket"
	tool.Activated:Connect(function()
		print("Pew Pew!")
		local backpack = tool.Parent
		if not backpack then return end
		local player = backpack.Parent
		if not player then return end
		print(player)
		local hit_pos = Input.GetMouseWorldPosition()
		SpawnRocket(tool.Position, hit_pos)
	end)
	return tool
end
