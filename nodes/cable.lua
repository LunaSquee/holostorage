-- holostorage cabling

minetest.register_node("holostorage:cable", {
	description = "Storage Cable",
	drawtype = "nodebox",
	tiles = {"holostorage_cable.png"},
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
		"group:holostorage_controller",
		"group:holostorage_distributor",
		"group:holostorage_cable",
	},
	groups = {
		holostorage_distributor = 1,
		holostorage_cable = 1,
		cracky = 2,
		oddly_breakable_by_hand = 2
	},
	on_construct = function (pos)
		holostorage.network.clear_networks(pos)
	end,
	after_dig_node = holostorage.network.clear_networks,
})
