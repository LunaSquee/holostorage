-- holostorage nodes

-- Common registrations
dofile(holostorage.modpath.."/nodes/common.lua")

-- Controller
dofile(holostorage.modpath.."/nodes/controller.lua")

-- Cabling
dofile(holostorage.modpath.."/nodes/cable.lua")

-- Disk drives
dofile(holostorage.modpath.."/nodes/disk_drive.lua")

-- Grids
dofile(holostorage.modpath.."/nodes/grid.lua")

-- Buses
dofile(holostorage.modpath.."/nodes/bus.lua")

-- Solderer
dofile(holostorage.modpath.."/nodes/solderer.lua")

-- Start the network
holostorage.network.register_abm_controller("holostorage:controller_active")
holostorage.network.register_abm_nodes()
