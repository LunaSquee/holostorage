-- Disk Drive

local function timer(pos, elapsed)
	local refresh = false
	local meta    = minetest.get_meta(pos)
	local node    = minetest.get_node(pos)

	return refresh
end

local function register_disk_drive(index)
	local groups = {
		cracky = 1,
		storagetest_distributor = 1,
		storagetest_device = 1,
		storagetest_storage = 1,
	}

	local driveoverlay = ""
	if index ~= 0 then
		groups["not_in_creative_inventory"] = 1
		driveoverlay = "^storagetest_drive_section"..index..".png"
	end

	minetest.register_node("storagetest:disk_drive"..index, {
		description = "Disk Drive",
		tiles = {
			"storagetest_drive_side.png", "storagetest_drive_side.png", "storagetest_drive_side.png",
			"storagetest_drive_side.png", "storagetest_drive_side.png", "storagetest_drive.png"..driveoverlay, 
		},
		drop = "storagetest:disk_drive0",
		paramtype2 = "facedir",
		on_timer = timer,
		groups = groups,
		on_construct = function (pos)
			storagetest.network.clear_networks(pos)
		end,
		on_destruct = storagetest.network.clear_networks,
	})

	storagetest.devices["storagetest:disk_drive"..index] = true
end

-- Register 6 variants of the disk drive.
for i = 0, 6 do
	register_disk_drive(i)
end
