local fs = require("@lune/fs")
local ParseModel = require("./ParseModel")

local _start_time = os.clock()

fs.writeFile("compiled_models/map.luau", ParseModel("models/map.rbxmx"))
fs.writeFile("compiled_models/bridge.luau", ParseModel("models/bridge.rbxmx", 8))

local _ms = string.format("%.3f", (os.clock() - _start_time) * 1000)
print(`successfully compiled 2 models (in {_ms}ms)`)
