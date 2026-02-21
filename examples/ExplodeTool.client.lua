--[[
ExplodeTool example. Gives players a very simple tool that removes welds in a radius when clicked

This is the client-side script, make sure to use the server-side script as well
This should be placed as a LocalScript in a child of a new Tool in PlayerDefaults.Backpack

It is recommended to use this alongside the Bridge example
]]

local Hidden = game["Hidden"]

local explode_event = Hidden["ExplodeEvent"]

script.Parent.Activated:Connect(function()
	local click_pos = Input.GetMouseWorldPosition()

	local message = NetMessage.New()
	message:AddVector3("p", click_pos)

	explode_event.InvokeServer(message)
end)
