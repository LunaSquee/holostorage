-- Disk Drive

local function get_formspec()
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Disk Drive]"..
		"list[context;main;1,1;6,1;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;main]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function count_inv(inv)
	local count = 0
	for _,stack in pairs(inv:get_list("main")) do
		if not stack:is_empty() then
			count = count + 1
		end
	end
	return count
end

local function timer(pos, elapsed)
	local refresh = false
	local meta    = minetest.get_meta(pos)
	local node    = minetest.get_node(pos)
	local inv     = meta:get_inventory()

	local count  = count_inv(inv)
	local cnname = minetest.registered_nodes[node.name]["_basename"]
	node.name = cnname..count
	holostorage.helpers.swap_node(pos, node)

	return refresh
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if not holostorage.disks.is_valid_disk(stack) then
		return 0
	end

	return stack:get_count()
end

local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function sort_by_stack_name( ... )
	-- body
end

local function register_disk_drive(index)
	local groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
		holostorage_storage = 1,
		disk_drive = 1,
	}

	local driveoverlay = ""
	if index ~= 0 then
		groups["not_in_creative_inventory"] = 1
		driveoverlay = "^holostorage_drive_section"..index..".png"
	end

	minetest.register_node("holostorage:disk_drive"..index, {
		description = "Disk Drive",
		tiles = {
			"holostorage_drive_side.png", "holostorage_drive_side.png", "holostorage_drive_side.png",
			"holostorage_drive_side.png", "holostorage_drive_side.png", "holostorage_drive.png"..driveoverlay, 
		},
		drop = "holostorage:disk_drive0",
		_basename = "holostorage:disk_drive",
		paramtype2 = "facedir",
		on_timer = timer,
		groups = groups,
		on_construct = function (pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", get_formspec())
			local inv = meta:get_inventory()
			inv:set_size("main", 6)
			holostorage.network.clear_networks(pos)
		end,
		after_dig_node = holostorage.network.clear_networks,

		allow_metadata_inventory_put = allow_metadata_inventory_put,
		allow_metadata_inventory_take = allow_metadata_inventory_take,
		allow_metadata_inventory_move = allow_metadata_inventory_move,

		on_metadata_inventory_move = function(pos)
			minetest.get_node_timer(pos):start(0.02)
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			stack = holostorage.server_inventory.ensure_disk_inventory(stack, minetest.pos_to_string(pos))

			local meta  = minetest.get_meta(pos)
			local inv   = meta:get_inventory()

			inv:set_stack(listname, index, stack)

			minetest.get_node_timer(pos):start(0.02)
		end,
		on_metadata_inventory_take = function(pos)
			minetest.get_node_timer(pos):start(0.02)
		end,
	})

	holostorage.devices["holostorage:disk_drive"..index] = true
end

-- Register 6 variants of the disk drive.
for i = 0, 6 do
	register_disk_drive(i)
end

-- Create ABM for syncing disks
minetest.register_abm({
	label = "Storage Disk Synchronization",
	nodenames = {"group:disk_drive"},
	neighbors = {"group:holostorage_distributor"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local inv  = meta:get_inventory()

		local disks = inv:get_list("main")
		for _,stack in pairs(disks) do
			local meta = stack:get_meta()
			local tag  = meta:get_string("storage_tag")
			if tag and tag ~= "" then
				if not holostorage.server_inventory.cache[tag] then
					print("loading drive",tag)
					holostorage.server_inventory.load_disk_from_file(stack, tag)
				end
			end
		end
	end
})
