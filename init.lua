-- Storagetest

storagetest = rawget(_G, "storagetest") or {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
storagetest.modpath = modpath

storagetest.devices = {}

-- Network
dofile(modpath.."/network.lua")

-- Nodes
dofile(modpath.."/nodes.lua")
