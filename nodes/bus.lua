-- Storagetest cabling

minetest.register_node("storagetest:import_bus", {
	description = "Import Bus",
	tiles = {
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_machine_block.png",
		"storagetest_machine_block.png", "storagetest_machine_block.png", "storagetest_import.png",
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		storagetest_distributor = 1,
		storagetest_device = 1,
		cracky = 2,
		oddly_breakable_by_hand = 2
	},
	on_construct = function (pos)
		storagetest.network.clear_networks(pos)
	end,
	on_destruct = storagetest.network.clear_networks,
	storagetest_run = function (pos, _, controller)
		local network = minetest.hash_node_position(controller)
		local node    = minetest.get_node(pos)
		local front   = storagetest.front(pos, node.param2)
		
		local front_node = minetest.get_node(front)
		if front_node.name ~= "air" then
			local front_meta = minetest.get_meta(front)
			local front_inv   = front_meta:get_inventory()
			local front_def   = minetest.registered_nodes[front_node.name]
			if front_inv:get_list("main") then
				local list = front_inv:get_list("main")
				for index, stack in pairs(list) do
					if not stack:is_empty() then
						local allow_count = 0
						local copystack = front_inv:get_stack("main", index)
						copystack:set_count(1)
						local success, outst = storagetest.network.insert_item(network, copystack)
						if success then
							stack:set_count(stack:get_count() - 1)
							front_inv:set_stack("main", index, stack)
							break -- Don't take more than one per cycle
						end
					end
				end
				front_inv:set_list("main", list)
			end
		end
	end
})

storagetest.devices["storagetest:import_bus"] = true
