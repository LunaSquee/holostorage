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
	storagetest.helpers.swap_node(pos, node)

	return refresh
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if minetest.get_item_group(stack:get_name(), "storagetest_disk") == 0 then
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

function storagetest.get_all_inventories(pos)
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "storagetest_storage") == 0 then return nil end
	local meta = minetest.get_meta(pos)
	local inv  = meta:get_inventory()
	
	local drives      = inv:get_list("meta")
	local inventories = {}
	for i, v in pairs(drives) do
		if not v:is_empty() then
			local inv1, stack = storagetest.disks.get_stack_inventory(v)
			inventories[i] = {inventory = inv1, stack = stack}
		end
	end

	return inventories
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
		_basename = "storagetest:disk_drive",
		paramtype2 = "facedir",
		on_timer = timer,
		groups = groups,
		on_construct = function (pos)
			storagetest.network.clear_networks(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", get_formspec())
			local inv = meta:get_inventory()
			inv:set_size("main", 6)
		end,
		on_destruct = storagetest.network.clear_networks,

		allow_metadata_inventory_put = allow_metadata_inventory_put,
		allow_metadata_inventory_take = allow_metadata_inventory_take,
		allow_metadata_inventory_move = allow_metadata_inventory_move,

		on_metadata_inventory_move = function(pos)
			minetest.get_node_timer(pos):start(0.02)
		end,
		on_metadata_inventory_put = function(pos)
			minetest.get_node_timer(pos):start(0.02)
		end,
		on_metadata_inventory_take = function(pos)
			minetest.get_node_timer(pos):start(0.02)
		end,
	})

	storagetest.devices["storagetest:disk_drive"..index] = true
end

-- Register 6 variants of the disk drive.
for i = 0, 6 do
	register_disk_drive(i)
end
