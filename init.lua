-- holostorage

holostorage = rawget(_G, "holostorage") or {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
holostorage.modpath = modpath

holostorage.devices = {}

-- Memory Storage
dofile(modpath.."/masscache.lua")

-- Network
dofile(modpath.."/network.lua")

-- Items
dofile(modpath.."/items.lua")

-- Nodes
dofile(modpath.."/nodes.lua")

-- Crafting recipes
dofile(modpath.."/crafting.lua")
