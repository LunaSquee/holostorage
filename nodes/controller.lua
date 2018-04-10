-- holostorage controller

local function get_formspec(list)
	local tx = {}
	for _,item in pairs(list) do
		table.insert(tx, item[1].."x "..item[2])
	end

	local list = "textlist[0,0.5;7.8,3.5;devices;"..table.concat(tx, ",").."]"

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Controller]"..
		list..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

minetest.register_node("holostorage:controller", {
	description = "Storage Controller",
	tiles = {"holostorage_controller.png"},
	on_construct = function (pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Storage Controller")
		meta:set_string("formspec", get_formspec({}))
		meta:set_string("active", 1)
		meta:set_string("channel", "controller"..minetest.pos_to_string(pos))
		minetest.swap_node(pos, {name="holostorage:controller_active"})
		local poshash = minetest.hash_node_position(pos)
		holostorage.network.redundant_warn[poshash] = nil
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
		holostorage_controller = 1
	}
})

local function compare(a,b)
	return a[1] > b[1]
end

minetest.register_node("holostorage:controller_active", {
	description = "Storage Controller",
	tiles = {
		{
			name = "holostorage_controller_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 5.0,
			},
		}
	},
	paramtype = "light",
	light_source = 8,
	drop = "holostorage:controller",
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local network_id = minetest.hash_node_position(pos)
		local devices = {}

		local network = holostorage.network.networks[network_id]
		if network and network.all_nodes then
			for _,pos in pairs(network.all_nodes) do
				local node = minetest.get_node(pos)
				local ndname = minetest.registered_nodes[node.name].description
				if not devices[ndname] then
					devices[ndname] = 0
				end
				devices[ndname] = devices[ndname] + 1
			end
		end
		
		local tfsort = {}
		
		for name, count in pairs(devices) do
			tfsort[#tfsort + 1] = {count, name}
		end

		table.sort(tfsort, compare)

		meta:set_string("formspec", get_formspec(tfsort))
		return itemstack
	end,
	groups = {
		cracky = 1,
		not_in_creative_inventory = 1,
		holostorage_controller = 1
	}
})
