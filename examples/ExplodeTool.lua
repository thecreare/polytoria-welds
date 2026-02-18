--[[
Gives players a very simple tool that removes welds in a radius.
It is recommended to use this alongside another example file
]]

local Environment = game["Environment"]
local Players = game["Players"]

-- Remember to update this to point to the correct script
-- Make sure WelderScript runs before this script (placing WelderScript above this one should work)
local Welder = game["ScriptService"]["WelderScript"]

local EXPLOSION_RADIUS = 6

Players.PlayerAdded:Connect(function(player)
	local tool = Instance.New("Tool")
	tool.Droppable = false
	tool.Name = "Explode"
	tool.Parent = player:FindChild("Backpack")

	tool.Activated:Connect(function()
		local click_pos = Input.GetMouseWorldPosition()

		local parts = {}

		local function InsertPart(part)
			table.insert(parts, part)
		end

		Environment:CreateExplosion(click_pos, EXPLOSION_RADIUS, 0, false, InsertPart, 10)
		Welder.Call("ClearWeldsBulk", table.unpack(parts))
		Welder.Call("PrintDebugInfo")
	end)
end)
