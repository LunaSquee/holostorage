-- Storage Grid

storagetest.grid = {}

function storagetest.grid.get_formspec(inventories, scroll_lvl, craft_inv)
	return "size[8,12]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Grid]"..
		"list[context;main;0,0;1,1;]"..
		"list[context;grid;0,1;7,6;]"..
		"list[current_player;main;0,8;8,1;]"..
		"list[current_player;main;0,9.2;8,3;8]"..
		"listring[context;main]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 8)
end

local function timer(pos, elapsed)
	local refresh = false
	local meta    = minetest.get_meta(pos)
	local node    = minetest.get_node(pos)

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
		meta:set_string("formspec", storagetest.grid.get_formspec(nil, 1))

		local inv  = meta:get_inventory()
		inv:set_size("main", 1)
		inv:set_size("grid", 7*6)
	end,
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = storagetest.helpers.grid_refresh,
	storagetest_enabled_name = "storagetest:grid_active",
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
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = storagetest.helpers.grid_refresh,
	storagetest_disabled_name = "storagetest:grid",
})

storagetest.devices["storagetest:grid"] = true
storagetest.devices["storagetest:grid_active"] = true
