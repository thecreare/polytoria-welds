local fs = require("@lune/fs")
local ParseModel = require("./ParseModel")

fs.writeFile("compiled_models/map.luau", ParseModel("models/map.rbxmx"))
fs.writeFile("compiled_models/bridge.luau", ParseModel("models/bridge.rbxmx", 8))
