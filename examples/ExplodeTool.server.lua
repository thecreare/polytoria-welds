--[[
ExplodeTool example. Gives players a very simple tool that removes welds in a radius when clicked

This is the server-side script, make sure to use the client-side script as well
This should be placed as a Script in ScriptService

It is recommended to use this alongside the Bridge example
]]

local Hidden = game["Hidden"]
local Environment = game["Environment"]
local ScriptService = game["ScriptService"]

-- Remember to update this to point to the correct script
-- Make sure WelderScript runs before this script (placing WelderScript above this one should work)
local Welder = ScriptService["WelderScript"]

local explode_event = Instance.New("NetworkEvent")
explode_event.Name = "ExplodeEvent"
explode_event.Parent = Hidden

local EXPLOSION_RADIUS = 6

-- This is for example purposes, in a real game you should not let the client freely create explosions anywhere like this
explode_event.InvokedServer:Connect(function(player, message)
	local position = message:GetVector3("p")
	local parts = {}

	local function InsertPart(part)
		table.insert(parts, part)
	end

	Environment:CreateExplosion(position, EXPLOSION_RADIUS, 0, false, InsertPart, 10)
	Welder.Call("ClearWeldsBulk", table.unpack(parts))
	Welder.Call("PrintDebugInfo")
end)
