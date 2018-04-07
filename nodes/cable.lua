-- Storagetest cabling

minetest.register_node("storagetest:cable", {
	description = "Storage Cable",
	drawtype = "nodebox",
	tiles = {"storagetest_cable.png"},
	node_box = {
		type = "connected",
		fixed = {{-1/8, -1/8, -1/8, 1/8, 1/8, 1/8}},
		connect_front = {
			{-1/8, -1/8, -1/2, 1/8, 1/8, -1/8}
		},
		connect_back = {
			{-1/8, -1/8, 1/8, 1/8, 1/8, 1/2}
		},
		connect_top = {
			{-1/8, 1/8, -1/8, 1/8, 1/2, 1/8}
		},
		connect_bottom = {
			{-1/8, -1/2, -1/8, 1/8, -1/8, 1/8}
		},
		connect_left = {
			{-1/2, -1/8, -1/8, 1/8, 1/8, 1/8}
		},
		connect_right = {
			{1/8, -1/8, -1/8, 1/2, 1/8, 1/8}
		},
	},
	paramtype = "light",
	connect_sides = { "top", "bottom", "front", "left", "back", "right" },
	is_ground_content = false,
	connects_to = {
		"group:storagetest_controller",
		"group:storagetest_distributor",
		"group:storagetest_cable",
	},
	groups = {
		storagetest_distributor = 1,
		storagetest_cable = 1,
		cracky = 2,
		oddly_breakable_by_hand = 2
	},
	on_construct = function (pos)
		storagetest.network.clear_networks(pos)
	end,
	on_destruct = storagetest.network.clear_networks,
})
