-- holostorage cabling

local function get_formspec(title, filter)
	local fl = "Blacklist"
	
	if filter ~= nil then
		if filter == 1 then
			fl = "Whitelist"
		end
	else
		fl = nil
	end

	if fl then
		fl = "button[0,2.5;2,1;filter;"..fl.."]"
	else
		fl = ""
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;"..title.."]"..
		"list[context;filter;0,1.5;8,1;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		fl..
		"listring[context;filter]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function inventory_ghost_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	local inv = minetest.get_meta(pos):get_inventory()
	stack:set_count(1)
	inv:set_stack(listname, index, stack)
	return 0
end

local function inventory_ghost_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	local inv = minetest.get_meta(pos):get_inventory()
	inv:set_stack(listname, index, ItemStack(nil))
	return 0
end

local function flip_filter(pos, form, fields, player)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local ndef = minetest.registered_nodes[node.name].description
	if fields["filter"] then
		local f = meta:get_int("filter")
		if f == 0 then f = 1 else f = 0 end
		meta:set_int("filter", f)

		meta:set_string("formspec", get_formspec(ndef, f))
	end
end

minetest.register_node("holostorage:import_bus", {
	description = "Import Bus",
	tiles = {
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_machine_block.png",
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_import.png",
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		holostorage_distributor = 1,
		holostorage_device = 1,
		cracky = 2,
		oddly_breakable_by_hand = 2
	},
	on_construct = function (pos)
		holostorage.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_formspec("Import Bus", 0))

		local inv  = meta:get_inventory()
		inv:set_size("filter", 8)

		meta:set_int("filter", 0)
	end,
	on_destruct = holostorage.network.clear_networks,
	on_receive_fields = flip_filter,
	holostorage_run = function (pos, _, controller)
		local network = minetest.hash_node_position(controller)
		local node    = minetest.get_node(pos)
		local meta    = minetest.get_meta(pos)
		local inv     = meta:get_inventory()
		local front   = holostorage.front(pos, node.param2)
		
		local front_node = minetest.get_node(front)
		if front_node.name ~= "air" then
			local front_meta = minetest.get_meta(front)
			local front_inv   = front_meta:get_inventory()
			local front_def   = minetest.registered_nodes[front_node.name]
			if front_inv:get_list("main") then
				local list = front_inv:get_list("main")
				local filter_type = meta:get_int("filter")
				for index, stack in pairs(list) do
					if not stack:is_empty() then
						local can_take = false
						local copystack = front_inv:get_stack("main", index)
						copystack:set_count(1)

						if filter_type == 0 and inv:contains_item("filter", copystack) then
							can_take = false
						elseif filter_type == 1 and inv:contains_item("filter", copystack) then
							can_take = true
						else
							can_take = true
						end

						if can_take then
							local success, outst = holostorage.network.insert_item(network, copystack)
							if success then
								stack:set_count(stack:get_count() - 1)
								front_inv:set_stack("main", index, stack)
								break -- Don't take more than one per cycle
							end
						end
					end
				end
				front_inv:set_list("main", list)
			end
		end
	end,
	allow_metadata_inventory_take = inventory_ghost_take,
	allow_metadata_inventory_put  = inventory_ghost_put
})

minetest.register_node("holostorage:export_bus", {
	description = "Export Bus",
	tiles = {
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_machine_block.png",
		"holostorage_machine_block.png", "holostorage_machine_block.png", "holostorage_export.png",
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		holostorage_distributor = 1,
		holostorage_device = 1,
		cracky = 2,
		oddly_breakable_by_hand = 2
	},
	on_construct = function (pos)
		holostorage.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_formspec("Export Bus"))

		local inv  = meta:get_inventory()
		inv:set_size("filter", 8)
	end,
	on_destruct = holostorage.network.clear_networks,
	holostorage_run = function (pos, _, controller)
		local network = minetest.hash_node_position(controller)
		local node    = minetest.get_node(pos)
		local meta    = minetest.get_meta(pos)
		local inv     = meta:get_inventory()
		local front   = holostorage.front(pos, node.param2)
		
		local front_node = minetest.get_node(front)
		if front_node.name ~= "air" then
			local front_meta = minetest.get_meta(front)
			local front_inv   = front_meta:get_inventory()
			local front_def   = minetest.registered_nodes[front_node.name]
			if front_inv:get_list("main") then
				local items = holostorage.network.get_storage_inventories(network)
				for index, stack in pairs(items) do
					if not stack:is_empty() then
						local can_take = false
						stack:set_count(1)

						if inv:contains_item("filter", stack) then
							can_take = true
						end

						if not front_inv:room_for_item("main", stack) then
							can_take = false
						end

						if can_take then
							local success, gotten = holostorage.network.take_item(network, stack)
							if success then
								front_inv:add_item("main", gotten)
								break -- Don't take more than one per cycle
							end
						end
					end
				end
			end
		end
	end,
	allow_metadata_inventory_take = inventory_ghost_take,
	allow_metadata_inventory_put  = inventory_ghost_put
})

holostorage.devices["holostorage:import_bus"] = true
holostorage.devices["holostorage:export_bus"] = true
