-- Storagetest nodes

-- Common registrations
dofile(storagetest.modpath.."/nodes/common.lua")

-- Controller
dofile(storagetest.modpath.."/nodes/controller.lua")

-- Cabling
dofile(storagetest.modpath.."/nodes/cable.lua")

-- Disk drives
dofile(storagetest.modpath.."/nodes/disk_drive.lua")

-- Grids
dofile(storagetest.modpath.."/nodes/grid.lua")

-- Buses
dofile(storagetest.modpath.."/nodes/bus.lua")

-- Start the network
storagetest.network.register_abm_controller("storagetest:controller_active")
storagetest.network.register_abm_nodes()
