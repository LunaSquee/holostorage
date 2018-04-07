-- Storage Grid

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
