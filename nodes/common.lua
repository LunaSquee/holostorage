-- holostorage commons

holostorage.helpers = {}

function holostorage.helpers.swap_node(pos, noded)
	local node = minetest.get_node(pos)
	
	if type(noded) ~= "table" then
		noded = {name = noded}
	end

	if node.name == noded.name then
		return false
	end
	minetest.swap_node(pos, noded)
	return true
end

function holostorage.helpers.grid_refresh(pos, n, controller)
	local node    = minetest.get_node(pos)
	local meta    = minetest.get_meta(pos)
	local nodedef = minetest.registered_nodes[node.name]
	local prev    = meta:get_string("controller")

	meta:set_string("infotext", ("%s Active"):format(nodedef.description))
	meta:set_string("controller", minetest.pos_to_string(controller))

	if not prev or prev == "" then
		minetest.get_node_timer(pos):start(0.02)
	end

	if nodedef.holostorage_enabled_name then
		node.name = nodedef.holostorage_enabled_name
		holostorage.helpers.swap_node(pos, node)
	end
end

function holostorage.front(pos, fd)
	local back = minetest.facedir_to_dir(fd)
	local front = {}
	for i, v in pairs(back) do
		front[i] = v
	end
	front.x = front.x * -1 + pos.x
	front.y = front.y * -1 + pos.y
	front.z = front.z * -1 + pos.z
	return front
end

function holostorage.stack_list(pos)
	local invs = holostorage.get_all_inventories(pos)
	if not invs then return {} end
	local tabl = {}

	for _,diskptr in pairs(invs) do
		local invref = holostorage.server_inventory.cache[diskptr]
		local inv_n  = "main"
		local inv_p
		if diskptr:find("chest/") then
			inv_p, inv_n = diskptr:match("chest/(.*)/([%a_]+)")
			local pos1 = minetest.string_to_pos(inv_p)
			local meta = minetest.get_meta(pos1)
			invref = meta:get_inventory()
		end

		if invref then
			local stacks = invref:get_list(inv_n)
			for _,stack in pairs(stacks) do
				if not stack:is_empty() then
					table.insert(tabl, stack)
				end
			end
		end
	end

	--table.sort( tabl, sort_by_stack_name )
	return tabl
end

-- Storage Devices
function holostorage.insert_stack(pos, stack)
	local invs = holostorage.get_all_inventories(pos)
	if not invs then return {} end
	local tabl = {}
	local success = false
	local leftover

	for _,diskptr in pairs(invs) do
		local invref = holostorage.server_inventory.cache[diskptr]
		local inv_n  = "main"
		local inv_p
		if diskptr:find("chest/") then
			inv_p, inv_n = diskptr:match("chest/(.*)/([%a_]+)")
			local pos1 = minetest.string_to_pos(inv_p)
			local meta = minetest.get_meta(pos1)
			invref = meta:get_inventory()
		end

		if invref then
			if invref:room_for_item(inv_n, stack) then
				leftover = invref:add_item(inv_n, stack)
				success = true
				break
			end
		end
	end

	return success, leftover
end

function holostorage.take_stack(pos, stack)
	local invs = holostorage.get_all_inventories(pos)
	if not invs then return {} end
	local tabl = {}
	local stack_ret
	local success = false

	for _,diskptr in pairs(invs) do
		local invref = holostorage.server_inventory.cache[diskptr]
		local inv_n  = "main"
		local inv_p
		if diskptr:find("chest/") then
			inv_p, inv_n = diskptr:match("chest/(.*)/([%a_]+)")
			local pos1 = minetest.string_to_pos(inv_p)
			local meta = minetest.get_meta(pos1)
			invref = meta:get_inventory()
		end

		if invref then
			local list = invref:get_list(inv_n)
			for i, stacki in pairs(list) do
				if stacki:get_name() == stack:get_name() and stacki:get_wear() == stack:get_wear() then
					success = true
					if stack:get_count() >= stacki:get_count() then
						stack:set_count(stacki:get_count())
						stacki:clear()
					else
						stacki:set_count(stacki:get_count() - stack:get_count())
					end
					stack_ret = stack
					list[i] = stacki
					break
				end
			end
			invref:set_list(inv_n, list)
		end
	end

	return success, stack_ret
end

function holostorage.get_all_inventories(pos)
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "holostorage_storage") == 0 then return nil end
	local inventories = {}

	if minetest.get_item_group(node.name, "disk_drive") ~= 0 then
		local meta = minetest.get_meta(pos)
		local inv  = meta:get_inventory()
		
		local drives      = inv:get_list("main")
		for i, v in pairs(drives) do
			if not v:is_empty() then
				local meta = v:get_meta()
				local tag  = meta:get_string("storage_tag")
				if tag and tag ~= "" then
					inventories[#inventories + 1] = tag
				end
			end
		end
	else
		local meta  = minetest.get_meta(pos)
		local inv_p = meta:get_string("inv_pos")
		if inv_p and inv_p ~= "" then
			local inv_n = meta:get_string("inv_name")
			local pos1  = minetest.string_to_pos(inv_p)
			local meta1 = minetest.get_meta(pos1)
			local inv   = meta1:get_inventory()
			if inv and inv:get_list(inv_n) then
				inventories[#inventories + 1] = "chest/"..inv_p.."/"..inv_n
			end
		end
	end

	return inventories
end
