--[[
Creates two anchored baseplates connected via an unanchored, welded, bridge
]]
local Environment = game["Environment"]

-- Remember to update this to point to the correct script
-- Make sure WelderScript runs before this script (placing WelderScript above this one should work)
local Welder = game["ScriptService"]["WelderScript"]

-- Enable debug mode that changes part colors based on the assembly they are in
Welder:Call("SetDebugEnabled", true)

-- Create a basic world
local l_baseplate = Instance.New("Part")
l_baseplate.Position = Vector3.New(100, -15, 0)
l_baseplate.Size = Vector3.New(100, 30, 100)
l_baseplate.Color = Color.FromHex("#53D45BFF")
l_baseplate.Material = PartMaterial.Grass
l_baseplate.Parent = Environment

local r_baseplate = l_baseplate:Clone()
r_baseplate.Position = Vector3.New(-100, -15, 0)
r_baseplate.Parent = Environment

local b_baseplate = l_baseplate:Clone()
b_baseplate.Size = Vector3.New(400, 10, 400)
b_baseplate.Position = Vector3.New(0, -35, 0)
b_baseplate.Parent = Environment

local function LoadBridge()
	-- Spawn bridge parts
	local parts = {}
	for x = -50, 50, 5 do
		for z = -20, 20, 5 do
			local new_part = Instance.New("Part")
			-- new_part.Color = Color.Random()
			new_part.Size = Vector3.New(5, 1, 5)
			new_part.LocalPosition = Vector3.New(x, 0.5, z)
			new_part.Parent = Environment
			table.insert(parts, new_part)
		end
	end
	
	-- Some amount of time seems to be needed before parts
	--  parented to the Environment can be detected by Environment:OverlapBox
	wait()
	
	-- Weld touching bridge parts together with Environment:OverlapBox
	for _, part in ipairs(parts) do
		Welder.Call("MakeWelds", part, nil, l_baseplate, r_baseplate)
	end
	
	Welder.Call("PrintDebugInfo")
end

while true do
	Chat:BroadcastMessage("Loading map")
	LoadBridge()
	wait(30)

	Welder.Call("DestroyAllAssemblies")
	-- For some reason there needs to be a long wait here because otherwise
	--  the DestroyAllAssemblies call will end up destroying the assemblies we are about to create
	wait(1)
end
