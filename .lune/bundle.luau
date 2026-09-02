local process = require("@lune/process")
local fs = require("@lune/fs")

print("? Bundling Delirium with Wax...")

if not fs.isDir("dist") then
    fs.writeDir("dist")
end

local result = process.spawn("lune", {
    "run",
    "wax",
    "bundle",
    "input=bundle.project.json",
    "output=dist/Delirium.lua",
    "ci-mode=true",
})

if result.ok then
    print("? Successfully bundled Delirium -> dist/Delirium.lua")
else
    print("? Bundle failed:\n" .. (result.stderr ~= "" and result.stderr or result.stdout))
end
