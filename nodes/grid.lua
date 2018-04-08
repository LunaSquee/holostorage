-- Storage Grid

storagetest.grid = {}

function storagetest.grid.get_formspec(scroll_lvl, craft_inv)
	local craft = ""
	local title = "Grid"
	local height = 6
	
	if craft_inv then
		title = "Crafting Grid"
		height = 3
		craft = "list[current_player;craft;1.5,4.5;3,3;]"..
				"image[4.5,5.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
				"list[current_player;craftpreview;5.5,5.5;1,1;]"
	end

	return "size[8,12]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;"..title.."]"..
		"list[context;main;0,7;1,1;]"..
		"list[context;grid;0,0.5;7,"..height..";]"..
		"list[current_player;main;0,8;8,1;]"..
		"list[current_player;main;0,9.2;8,3;8]"..
		craft..
		"listring[context;main]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 8)
end

function storagetest.grid.to_network(meta)
	local ctrl    = meta:get_string("controller")
	if not ctrl or ctrl == "" then return nil end
	local network = minetest.hash_node_position(minetest.string_to_pos(ctrl))
	return network
end

function storagetest.grid.handle_grid(pos, meta, network, inv)
	local refresh = false
	local limited_items = {}

	local items   = storagetest.network.get_storage_inventories(network)
	local scroll  = meta:get_int("scroll_len") or 0
	local grid    = inv:get_size("grid")

	for i = (scroll * 7) + 1, grid + (scroll * 7) do
		if items[i] then
			limited_items[#limited_items + 1] = items[i]
		end
	end 

	inv:set_list("grid", limited_items)

	-- Handle inputting items
	local input = inv:get_stack("main", 1)
	if not input:is_empty() then
		local success, leftover = storagetest.network.insert_item(network, input)
		if success then
			inv:set_stack("main", 1, leftover)
			refresh = true
		end
	end

	return refresh
end

function storagetest.grid.allow_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "grid" or listname == "craftpreview" then
		return 0
	end

	return stack:get_count()
end

function storagetest.grid.allow_move_active(pos, from_list, from_index, to_list, to_index, count, player)
	if from_list == "grid" and to_list == "main" then
		return 0
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)

	return storagetest.grid.allow_put(pos, to_list, to_index, stack, player)
end

function storagetest.grid.on_disable(pos)
	local meta = minetest.get_meta(pos)
	local prev = meta:get_string("controller")
	if prev and prev ~= "" then
		meta:set_string("controller", "")
		minetest.get_node_timer(pos):start(0.02)
	end
end

function storagetest.grid.on_move(pos, from_list, from_index, to_list, to_index, count, player)
	if from_list == "grid" and to_list == "craft" then
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(to_list, to_index)
		local meta    = minetest.get_meta(pos)
		local network = storagetest.grid.to_network(meta)
		if network then
			storagetest.network.take_item(network, stack)
		end
	end

	minetest.get_node_timer(pos):start(0.02)
end

function storagetest.grid.on_take(pos, listname, index, stack, player)
	if listname == "grid" then
		local meta    = minetest.get_meta(pos)
		local network = storagetest.grid.to_network(meta)
		if network then
			storagetest.network.take_item(network, stack)
		end
	end

	minetest.get_node_timer(pos):start(0.02)
end

local function timer(pos, elapsed)
	local refresh = false
	local meta    = minetest.get_meta(pos)
	local node    = minetest.get_node(pos)
	local inv     = meta:get_inventory()
	local network = storagetest.grid.to_network(meta)

	if not network then
		inv:set_list("grid", {})
	else
		refresh = storagetest.grid.handle_grid(pos, meta, network, inv)
	end

	return refresh
end

minetest.register_node("storagetest:grid", {
	description = "Grid",
	tiles = {
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_machine_block.png",
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_grid.png",
	},
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		storagetest_distributor = 1,
		storagetest_device = 1,
	},
	on_construct = function (pos)
		storagetest.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", storagetest.grid.get_formspec(0))

		local inv  = meta:get_inventory()
		inv:set_size("main", 1)
		inv:set_size("grid", 7*6)

		meta:set_int("scroll_len", 0)
	end,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.02)
		return itemstack
	end,
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = storagetest.helpers.grid_refresh,
	allow_metadata_inventory_move = function ()
		return 0
	end,
	allow_metadata_inventory_put = function ()
		return 0
	end,
	allow_metadata_inventory_take = function ()
		return 0
	end,
	storagetest_enabled_name = "storagetest:grid_active",
	storagetest_on_disable = storagetest.grid.on_disable,
})

minetest.register_node("storagetest:grid_active", {
	description = "Grid",
	tiles = {
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_machine_block.png",
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_grid_active.png",
	},
	drop = "storagetest:grid",
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		storagetest_distributor = 1,
		storagetest_device = 1,
		not_in_creative_inventory = 1
	},
	on_metadata_inventory_move = storagetest.grid.on_move,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.get_node_timer(pos):start(0.02)
	end,
	on_metadata_inventory_take = storagetest.grid.on_take,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.05)
		return itemstack
	end,
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = storagetest.helpers.grid_refresh,
	storagetest_disabled_name = "storagetest:grid",
	allow_metadata_inventory_move = storagetest.grid.allow_move_active,
	allow_metadata_inventory_put = storagetest.grid.allow_put,
})

-- Crafting version

minetest.register_node("storagetest:crafting_grid", {
	description = "Crafting Grid",
	tiles = {
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_machine_block.png",
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_crafting_grid.png", 
	},
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		storagetest_distributor = 1,
		storagetest_device = 1,
	},
	on_construct = function (pos)
		storagetest.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", storagetest.grid.get_formspec(0, true))

		local inv  = meta:get_inventory()
		inv:set_size("main", 1)
		inv:set_size("grid", 7*3)
		
		meta:set_int("scroll_len", 0)
	end,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.02)
		return itemstack
	end,
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = storagetest.helpers.grid_refresh,
	allow_metadata_inventory_move = function ()
		return 0
	end,
	allow_metadata_inventory_put = function ()
		return 0
	end,
	allow_metadata_inventory_take = function ()
		return 0
	end,
	storagetest_enabled_name = "storagetest:crafting_grid_active",
	storagetest_on_disable = storagetest.grid.on_disable,
})

minetest.register_node("storagetest:crafting_grid_active", {
	description = "Crafting Grid",
	tiles = {
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_machine_block.png",
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_crafting_grid_active.png",
	},
	drop = "storagetest:crafting_grid",
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		storagetest_distributor = 1,
		storagetest_device = 1,
		not_in_creative_inventory = 1
	},
	on_metadata_inventory_move = storagetest.grid.on_move,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.get_node_timer(pos):start(0.02)
	end,
	on_metadata_inventory_take = storagetest.grid.on_take,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.05)
		return itemstack
	end,
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = storagetest.helpers.grid_refresh,
	storagetest_disabled_name = "storagetest:crafting_grid",
	allow_metadata_inventory_move = storagetest.grid.allow_move_active,
	allow_metadata_inventory_put = storagetest.grid.allow_put,
})

storagetest.devices["storagetest:grid"] = true
storagetest.devices["storagetest:grid_active"] = true

storagetest.devices["storagetest:crafting_grid"] = true
storagetest.devices["storagetest:crafting_grid_active"] = true
