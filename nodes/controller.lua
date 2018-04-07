-- Storagetest controller

minetest.register_node("storagetest:controller", {
	description = "Storage Controller",
	tiles = {"storagetest_controller.png"},
	on_construct = function (pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Storage Controller")
		meta:set_string("active", 1)
		meta:set_string("channel", "controller"..minetest.pos_to_string(pos))
		minetest.swap_node(pos, {name="storagetest:controller_active"})
		local poshash = minetest.hash_node_position(pos)
		storagetest.network.redundant_warn[poshash] = nil
	end,
	after_dig_node = function(pos)
		minetest.forceload_free_block(pos)
		pos.y = pos.y - 1
		minetest.forceload_free_block(pos)
		local poshash = minetest.hash_node_position(pos)
		technic.redundant_warn[poshash] = nil
	end,
	groups = {
		cracky = 1,
		storagetest_controller = 1
	}
})

minetest.register_node("storagetest:controller_active", {
	description = "Storage Controller",
	tiles = {
		{
			name = "storagetest_controller_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 5.0,
			},
		}
	},
	drop = "storagetest:controller",
	groups = {
		cracky = 1,
		not_in_creative_inventory = 1,
		storagetest_controller = 1
	}
})
