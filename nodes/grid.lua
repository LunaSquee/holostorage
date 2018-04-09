-- Storage Grid

holostorage.grid = {}

function holostorage.grid.sort(inlist)
	local typecnt = {}
	local typekeys = {}
	for _, st in ipairs(inlist) do
		if not st:is_empty() then
			local n = st:get_name()
			local w = st:get_wear()
			local m = st:get_metadata()
			local k = string.format("%s %05d %s", n, w, m)
			if not typecnt[k] then
				typecnt[k] = {
					name = n,
					wear = w,
					metadata = m,
					stack_max = st:get_stack_max(),
					count = 0,
				}
				table.insert(typekeys, k)
			end
			typecnt[k].count = typecnt[k].count + st:get_count()
		end
	end
	table.sort(typekeys)
	local outlist = {}
	for _, k in ipairs(typekeys) do
		local tc = typecnt[k]
		while tc.count > 0 do
			local c = math.min(tc.count, tc.stack_max)
			table.insert(outlist, ItemStack({
				name = tc.name,
				wear = tc.wear,
				metadata = tc.metadata,
				count = c,
			}))
			tc.count = tc.count - c
		end
	end
	if #outlist > #inlist then return end
	while #outlist < #inlist do
		table.insert(outlist, ItemStack(nil))
	end
	return outlist
end

function holostorage.grid.get_formspec(scroll_lvl, pages, craft_inv)
	local craft = ""
	local title = "Grid"
	local height = 6
	
	if craft_inv then
		title = "Crafting Grid"
		height = 3
		craft = "list[current_player;craft;1.5,3.8;3,3;]"..
				"image[4.5,4.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
				"list[current_player;craftpreview;5.5,4.8;1,1;]"
	end

	local scroll = ""
	if scroll_lvl < pages then
		scroll = scroll.."button[7,"..(height-0.5)..";1,1;down;Down]"
	end

	if scroll_lvl > 0 then
		scroll = scroll.."button[7,0.5;1,1;up;Up]"
	end

	return "size[8,12]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;"..title.."]"..
		"field[1.25,7.45;4,1;search;Search..;]"..
		"field_close_on_enter[search;false]"..
		"list[context;main;0,7;1,1;]"..
		"list[context;grid;0,0.5;7,"..height..";]"..
		"list[current_player;main;0,8;8,1;]"..
		"list[current_player;main;0,9.2;8,3;8]"..
		craft..
		scroll..
		"listring[context;main]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 8)
end

function holostorage.grid.to_network(meta)
	local ctrl    = meta:get_string("controller")
	if not ctrl or ctrl == "" then return nil end
	local network = minetest.hash_node_position(minetest.string_to_pos(ctrl))
	return network
end

function holostorage.grid.handle_grid(pos, meta, network, inv)
	local refresh = false
	local limited_items = {}

	local items   = holostorage.network.get_storage_inventories(network)
	local scroll  = meta:get_int("scroll_len") or 0
	local grid    = inv:get_size("grid")

	-- Sort the items
	items = holostorage.grid.sort(items)

	-- Search
	local search = meta:get_string("search")
	local preserve = {}
	if search and search ~= "" then
		for _, v in pairs(items) do
			if v:get_name():find(search) then
				preserve[#preserve + 1] = v
			end
		end
	else
		preserve = items
	end

	for i = (scroll * 7) + 1, grid + (scroll * 7) do
		if preserve[i] then
			limited_items[#limited_items + 1] = preserve[i]
		end
	end 

	inv:set_list("grid", limited_items)

	-- Handle inputting items
	local input = inv:get_stack("main", 1)
	if not input:is_empty() then
		local success, leftover = holostorage.network.insert_item(network, input)
		if success then
			inv:set_stack("main", 1, leftover)
			refresh = true
		end
	end

	-- Reset formspec, recalculate scrolls
	local grid_craft = meta:get_int("craft") == 1
	local height     = math.floor(#preserve / 8)
	meta:set_int("scroll_height", height)
	meta:set_string("formspec", holostorage.grid.get_formspec(scroll, height, grid_craft))

	return refresh
end

local function on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	if fields["up"] then
		if meta:get_int("scroll_len") > 0 then
			meta:set_int("scroll_len", meta:get_int("scroll_len") - 1)
		end
	elseif fields["down"] then
		if meta:get_int("scroll_len") < meta:get_int("scroll_height") then
			meta:set_int("scroll_len", meta:get_int("scroll_len") + 1)
		end
	elseif fields["search"] and fields["key_enter"] then
		meta:set_string("search", fields["search"])
		meta:set_int("scroll_len", 0)
	elseif fields["quit"] then
		meta:set_string("search", "")
		meta:set_int("scroll_len", 0)
	end
	minetest.get_node_timer(pos):start(0.02)
end

function holostorage.grid.allow_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "grid" or listname == "craftpreview" then
		return 0
	end

	return stack:get_count()
end

function holostorage.grid.allow_move_active(pos, from_list, from_index, to_list, to_index, count, player)
	if from_list == "grid" and to_list == "main" then
		return 0
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)

	return holostorage.grid.allow_put(pos, to_list, to_index, stack, player)
end

function holostorage.grid.on_disable(pos)
	local meta = minetest.get_meta(pos)
	local prev = meta:get_string("controller")
	if prev and prev ~= "" then
		meta:set_string("controller", "")
		minetest.get_node_timer(pos):start(0.02)
	end
end

function holostorage.grid.on_move(pos, from_list, from_index, to_list, to_index, count, player)
	if from_list == "grid" and to_list == "craft" then
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(to_list, to_index)
		local meta    = minetest.get_meta(pos)
		local network = holostorage.grid.to_network(meta)
		if network then
			holostorage.network.take_item(network, stack)
		end
	end

	minetest.get_node_timer(pos):start(0.02)
end

function holostorage.grid.on_take(pos, listname, index, stack, player)
	if listname == "grid" then
		local meta    = minetest.get_meta(pos)
		local network = holostorage.grid.to_network(meta)
		if network then
			holostorage.network.take_item(network, stack)
		end
	end

	minetest.get_node_timer(pos):start(0.02)
end

local function timer(pos, elapsed)
	local refresh = false
	local meta    = minetest.get_meta(pos)
	local node    = minetest.get_node(pos)
	local inv     = meta:get_inventory()
	local network = holostorage.grid.to_network(meta)

	if not network then
		inv:set_list("grid", {})
	else
		refresh = holostorage.grid.handle_grid(pos, meta, network, inv)
	end

	return refresh
end

minetest.register_node("holostorage:grid", {
	description = "Grid",
	tiles = {
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_machine_block.png",
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_grid.png",
	},
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
	},
	on_construct = function (pos)
		holostorage.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", holostorage.grid.get_formspec(0, 1))

		local inv  = meta:get_inventory()
		inv:set_size("main", 1)
		inv:set_size("grid", 7*6)

		meta:set_int("scroll_len", 0)
		meta:set_int("scroll_height", 6)
	end,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.02)
		return itemstack
	end,
	after_dig_node = holostorage.network.clear_networks,
	holostorage_run = holostorage.helpers.grid_refresh,
	allow_metadata_inventory_move = function ()
		return 0
	end,
	allow_metadata_inventory_put = function ()
		return 0
	end,
	allow_metadata_inventory_take = function ()
		return 0
	end,
	holostorage_enabled_name = "holostorage:grid_active",
	holostorage_on_disable = holostorage.grid.on_disable,
})

minetest.register_node("holostorage:grid_active", {
	description = "Grid",
	tiles = {
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_machine_block.png",
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_grid_active.png",
	},
	drop = "holostorage:grid",
	paramtype = "light",
	light_source = 8,
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
		not_in_creative_inventory = 1
	},
	on_metadata_inventory_move = holostorage.grid.on_move,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.get_node_timer(pos):start(0.02)
	end,
	on_metadata_inventory_take = holostorage.grid.on_take,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.05)
		return itemstack
	end,
	after_dig_node = holostorage.network.clear_networks,
	holostorage_run = holostorage.helpers.grid_refresh,
	holostorage_disabled_name = "holostorage:grid",
	allow_metadata_inventory_move = holostorage.grid.allow_move_active,
	allow_metadata_inventory_put = holostorage.grid.allow_put,
	on_receive_fields = on_receive_fields,
})

-- Crafting version

minetest.register_node("holostorage:crafting_grid", {
	description = "Crafting Grid",
	tiles = {
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_machine_block.png",
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_crafting_grid.png", 
	},
	paramtype2 = "facedir",
	on_timer = timer,
	groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
	},
	on_construct = function (pos)
		holostorage.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", holostorage.grid.get_formspec(0, 1, true))

		local inv  = meta:get_inventory()
		inv:set_size("main", 1)
		inv:set_size("grid", 7*3)
		
		meta:set_int("scroll_len", 0)
		meta:set_int("scroll_height", 3)

		meta:set_int("craft", 1)
	end,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.02)
		return itemstack
	end,
	after_dig_node = holostorage.network.clear_networks,
	holostorage_run = holostorage.helpers.grid_refresh,
	allow_metadata_inventory_move = function ()
		return 0
	end,
	allow_metadata_inventory_put = function ()
		return 0
	end,
	allow_metadata_inventory_take = function ()
		return 0
	end,
	holostorage_enabled_name = "holostorage:crafting_grid_active",
	holostorage_on_disable = holostorage.grid.on_disable,
})

minetest.register_node("holostorage:crafting_grid_active", {
	description = "Crafting Grid",
	tiles = {
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_machine_block.png",
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_crafting_grid_active.png",
	},
	drop = "holostorage:crafting_grid",
	paramtype2 = "facedir",
	paramtype = "light",
	light_source = 8,
	on_timer = timer,
	groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
		not_in_creative_inventory = 1
	},
	on_metadata_inventory_move = holostorage.grid.on_move,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.get_node_timer(pos):start(0.02)
	end,
	on_metadata_inventory_take = holostorage.grid.on_take,
	on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(0.05)
		return itemstack
	end,
	after_dig_node = holostorage.network.clear_networks,
	holostorage_run = holostorage.helpers.grid_refresh,
	holostorage_disabled_name = "holostorage:crafting_grid",
	allow_metadata_inventory_move = holostorage.grid.allow_move_active,
	allow_metadata_inventory_put = holostorage.grid.allow_put,
	on_receive_fields = on_receive_fields,
})

holostorage.devices["holostorage:grid"] = true
holostorage.devices["holostorage:grid_active"] = true

holostorage.devices["holostorage:crafting_grid"] = true
holostorage.devices["holostorage:crafting_grid_active"] = true
