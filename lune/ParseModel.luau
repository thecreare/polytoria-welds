local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local MATERIAL_MAP = {
	CorrodedMetal = "RustyIron",
	Wood = "Wood",
	Concrete = "Concrete",
	Slate = "Stone",
	Foil = "Ice",
	Grass = "Grass",
	Fabric = "Fabric",
}


-- "SmoothPlastic",
-- "Neon",
-- "Metal",
-- "Brick",
-- "Dirt",
-- "Snow",
-- "Sand",
-- "Sandstone",
-- "Plastic",
-- "Plywood",
-- "Planks",
-- "Marble",

return function(path: string, subdivide_threshold: number)
	local placeFile = fs.readFile(path)
	local model = roblox.deserializePlace(placeFile)

	local output_lines = {
		"local WORLD = game['Environment']",
		"local RAD_TO_DEG = 360/(math.pi*2)",
		"",
		"return function()",
		"local output = {}",
		"",
	}

	local function CreateInstance(name: string)
		table.insert(output_lines, `local i = Instance.New("{name}")`)
		table.insert(output_lines, `table.insert(output, i)`)
	end

	local function WriteLine(key: string, value: any)
		table.insert(output_lines, `i.{key} = {value}`)
	end

	local function WritePartProps(part: Part)
		WriteLine("Position", `Vector3.New({part.CFrame.Position})`)
		WriteLine("Size", `Vector3.New({part.Size})`)
		WriteLine("Rotation", `Vector3.New({table.concat(table.pack(part.CFrame:ToEulerAnglesYXZ()), ", ")})*RAD_TO_DEG`)
		WriteLine("Color", `Color.New({part.Color}, {1-part.Transparency})`)
		WriteLine("Material", `PartMaterial.{MATERIAL_MAP[part.Material.Name] or "SmoothPlastic"}`)
		WriteLine("CanCollide", part.CanCollide)
		WriteLine("Parent", `WORLD`)
	end

	local Serialize = {
		Part = function(part: Part)
			if subdivide_threshold then
				local remaining_thickness = part.Size.Y
				local base_cf = part.CFrame
				local working_cf = base_cf - base_cf.UpVector * part.Size.Y * 0.5
				while remaining_thickness > 0 do
					local amount_to = math.min(remaining_thickness, subdivide_threshold)
					remaining_thickness -= amount_to
					working_cf += base_cf.UpVector * amount_to * 0.5
					part.Size = roblox.Vector3.new(part.Size.X, amount_to, part.Size.Z)
					part.CFrame = working_cf
					working_cf += base_cf.UpVector * amount_to * 0.5
					table.insert(output_lines, `-- This is a subdivided bit, its Y is {amount_to}`)
					CreateInstance("Part")
					WritePartProps(part)
				end
				return
			end
			CreateInstance("Part")
			WritePartProps(part)
		end,
		TrussPart = function(truss: TrussPart)
			CreateInstance("Truss")
			WritePartProps(truss)
		end
	}

	-- Manipulating and reading instances - just like in Roblox!
	for _, child in model:GetDescendants() do
		local method = Serialize[child.ClassName]
		if method then
			method(child)
		end
	end

	-- Writing a place file
	-- local newPlaceFile = roblox.serializePlace(game)
	-- fs.writeFile("myPlaceFile.rbxl", newPlaceFile)
	table.insert(output_lines, "return output")
	table.insert(output_lines, "end")
	return table.concat(output_lines, "\n")
end
