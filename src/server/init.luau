local RocketLauncher = require("./tools/RocketLauncher")
local PartNode = require("shared/PartNode")
local Assembly = require("shared/Assembly")

local WORLD = game["Environment"]

local spawnpoint = Instance.New("Part") :: Part
spawnpoint.Position = Vector3.New(-150, 45, 0)
spawnpoint.Size = Vector3.New(5, 1, 5)
spawnpoint.IsSpawn = true
spawnpoint.Parent = WORLD

require("models/map")()

local function GiveTools(player: Player)
	local rocket = RocketLauncher()
	rocket.Parent = player:FindChild("Backpack")
end

game["Players"].PlayerAdded:Connect(function(player: Player)
	GiveTools(player)
	player.Respawned:Connect(function()
		GiveTools(player)
	end)
end)

-- print("Creating bridge...")
-- local assembly = Assembly.new()
-- assembly.root.Position = Vector3.New(0, 0, 0)
-- local l_baseplate = Instance.New("Part") :: Part
-- l_baseplate.Position = Vector3.New(100, -5, 0)
-- l_baseplate.Size = Vector3.New(100, 10, 100)
-- l_baseplate.Color = Color.FromHex("53D45BFF")
-- l_baseplate.Material = PartMaterial.Grass
-- l_baseplate.Parent = WORLD
-- local r_baseplate = Instance.New("Part") :: Part
-- r_baseplate.Position = Vector3.New(-100, -5, 0)
-- r_baseplate.Size = Vector3.New(100, 10, 100)
-- r_baseplate.Color = Color.FromHex("53D45BFF")
-- r_baseplate.Material = PartMaterial.Grass
-- r_baseplate.Parent = WORLD
-- for x = -50, 50, 5 do
-- 	for z = -20, 20, 5 do
-- 		local node = PartNode.new()
-- 		node:AssignGenericPart()
-- 		node.part.Size = Vector3.New(5, 1, 5)
-- 		assembly:InsertNode(node)
-- 		node.part.LocalPosition = Vector3.New(x, 2, z)
-- 	end
-- end

local function SpawnModel(gen: () -> {Part}, pos: Vector3)
	local assembly = Assembly.new()
	
	for _, part in ipairs(gen()) do
		local node = PartNode.new()
		node:AssignPart(part)
		local old_pos = part.Position
		assembly:InsertNode(node)
		part.LocalPosition = old_pos
	end
	
	for _, node in pairs(assembly.parts) do
		assembly:MakeWelds(node)
	end
	
	assembly.root.Position = pos or Vector3.New(0)
	assembly:SplitIfNecessary()
end

SpawnModel(require("models/bridge"), Vector3.New(-150, 100, 0))
SpawnModel(require("models/bridge"), Vector3.New(150, 100, 0))

for _, player in ipairs(game["Players"]:GetPlayers()) do
	player.Position = spawnpoint.Position + Vector3.New(0, 6, 0)
end

local magic = Instance.New("Part") :: Part
magic.Position = Vector3.New(0, 50, 0)
magic.Size = Vector3.New(2, 8, 4)
magic.Anchored = false
magic.Parent = WORLD

while wait() do
	magic:MoveRotation(Vector3.New(os.clock()*10, 0, 0))
end
