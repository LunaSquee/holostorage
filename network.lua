-- Storagetest Network
-- Some code borrowed from Technic (https://github.com/minetest-mods/technic/blob/master/technic/machines/switching_station.lua)

storagetest.network = {}
storagetest.network.networks = {}
storagetest.network.devices = {}
storagetest.network.redundant_warn = {}

function storagetest.get_or_load_node(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then return node end
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	return nil
end

local function get_item_group(name, grp)
	return minetest.get_item_group(name, grp) > 0
end

function storagetest.network.is_network_conductor(name)
	return get_item_group(name, "storagetest_distributor")
end

function storagetest.network.is_network_device(name)
	return get_item_group(name, "storagetest_device")
end

-----------------------
-- Network traversal --
-----------------------

local function flatten(map)
	local list = {}
	for key, value in pairs(map) do
		list[#list + 1] = value
	end
	return list
end

-- Add a node to the network
local function add_network_node(nodes, pos, network_id)
	local node_id = minetest.hash_node_position(pos)
	storagetest.network.devices[node_id] = network_id
	if nodes[node_id] then
		return false
	end
	nodes[node_id] = pos
	return true
end

local function add_cable_node(nodes, pos, network_id, queue)
	if add_network_node(nodes, pos, network_id) then
		queue[#queue + 1] = pos
	end
end

local check_node_subp = function(dv_nodes, st_nodes, controllers, all_nodes, pos, devices, c_pos, network_id, queue)
	storagetest.get_or_load_node(pos)
	local meta = minetest.get_meta(pos)
	local name = minetest.get_node(pos).name

	if storagetest.network.is_network_conductor(name) then
		add_cable_node(all_nodes, pos, network_id, queue)
	end

	if devices[name] then
		meta:set_string("st_network", minetest.pos_to_string(c_pos))
		if get_item_group(name, "storagetest_controller") then
			-- Another controller, disable it
			add_network_node(controllers, pos, network_id)
			meta:set_int("active", 0)
		elseif get_item_group(name, "storagetest_storage") then
			add_network_node(st_nodes, pos, network_id)
		elseif storagetest.network.is_network_device(name) then
			add_network_node(dv_nodes, pos, network_id)
		end

		meta:set_int("nw_timeout", 2)
	end
end

-- Traverse a network given a list of machines and a cable type name
local traverse_network = function(dv_nodes, st_nodes, controllers, all_nodes, pos, devices, c_pos, network_id, queue)
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}
	for _, cur_pos in pairs(positions) do
		check_node_subp(dv_nodes, st_nodes, controllers, all_nodes, cur_pos, devices, c_pos, network_id, queue)
	end
end

local touch_nodes = function(list)
	for _, pos in ipairs(list) do
		local meta = minetest.get_meta(pos)
		meta:set_int("nw_timeout", 2) -- Touch node
	end
end

local function get_network(c_pos, positions)
	local network_id = minetest.hash_node_position(c_pos)
	local cached     = storagetest.network.networks[network_id]

	if cached then
		touch_nodes(cached.dv_nodes)
		touch_nodes(cached.st_nodes)
		for _, pos in ipairs(cached.controllers) do
			local meta = minetest.get_meta(pos)
			meta:set_int("active", 0)
			meta:set_string("active_pos", minetest.serialize(c_pos))
		end
		return cached.dv_nodes, cached.st_nodes
	end

	local dv_nodes    = {}
	local st_nodes    = {}
	local controllers = {}
	local all_nodes   = {}
	local queue       = {}

	for pos in pairs(positions) do
		queue = {}

		local node = minetest.get_node(pos)
		if node and storagetest.network.is_network_conductor(node.name) and not storagetest.network.is_network_device(node.name) then
			add_cable_node(all_nodes, pos, network_id, queue)
		elseif node and storagetest.network.is_network_device(node.name) then
			queue = {c_pos}
		end

		while next(queue) do
			local to_visit = {}
			for _, posi in ipairs(queue) do
				traverse_network(dv_nodes, st_nodes, controllers, all_nodes,
						posi, storagetest.devices, c_pos, network_id, to_visit)
			end
			queue = to_visit
		end
	end

	dv_nodes    = flatten(dv_nodes)
	st_nodes    = flatten(st_nodes)
	controllers = flatten(controllers)
	all_nodes   = flatten(all_nodes)

	storagetest.network.networks[network_id] = {all_nodes = all_nodes, dv_nodes = dv_nodes, 
		st_nodes = st_nodes, controllers = controllers}
	return dv_nodes, st_nodes
end

--------------------
-- Controller ABM --
--------------------

storagetest.network.active_state = true

minetest.register_chatcommand("storagectl", {
	params = "state",
	description = "Enables or disables Storagetest's storage controller ABM",
	privs = { basic_privs = true },
	func = function(name, state)
		if state == "on" then
			storagetest.network.active_state = true
		else
			storagetest.network.active_state = false
		end
	end
})

function storagetest.network.register_abm_controller(name)
	minetest.register_abm({
		nodenames = {name},
		label = "Storage Controller", -- allows the mtt profiler to profile this abm individually
		interval   = 1,
		chance     = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			if not storagetest.network.active_state then return end
			local meta             = minetest.get_meta(pos)
			local meta1            = nil

			local dv_nodes     = {}
			local st_nodes     = {}
			local device_name  = "Storage Controller"

			local positions = {
				{x=pos.x,   y=pos.y-1, z=pos.z},
				{x=pos.x,   y=pos.y+1, z=pos.z},
				{x=pos.x-1, y=pos.y,   z=pos.z},
				{x=pos.x+1, y=pos.y,   z=pos.z},
				{x=pos.x,   y=pos.y,   z=pos.z-1},
				{x=pos.x,   y=pos.y,   z=pos.z+1}
			}

			local ntwks   = {}
			local errored = false
			local nw_branches = 0
			for _,pos1 in pairs(positions) do
				--Disable if necessary
				if meta:get_int("active") ~= 1 then
					minetest.forceload_free_block(pos)
					minetest.forceload_free_block(pos1)
					meta:set_string("infotext",("%s Already Present"):format(device_name))

					local poshash = minetest.hash_node_position(pos)

					if not storagetest.network.redundant_warn[poshash] then
						storagetest.network.redundant_warn[poshash] = true
						print("[Storagetest] Warning: redundant controller found near "..minetest.pos_to_string(pos))
					end
					errored = true
					return
				end

				local name = minetest.get_node(pos1).name
				local networked = storagetest.network.is_network_conductor(name)
				if networked then
					ntwks[pos1] = true
					nw_branches = nw_branches + 1
				end
			end

			if errored then
				return
			end

			if nw_branches == 0 then
				minetest.forceload_free_block(pos)
				meta:set_string("infotext", ("%s Has No Network"):format(device_name))
				return
			else
				minetest.forceload_block(pos)
			end

			dv_nodes, st_nodes = get_network(pos, ntwks)

			-- Run all the nodes
			local function run_nodes(list)
				for _, pos2 in ipairs(list) do
					storagetest.get_or_load_node(pos2)
					local node2 = minetest.get_node(pos2)
					local nodedef
					if node2 and node2.name then
						nodedef = minetest.registered_nodes[node2.name]
					end
					if nodedef and nodedef.storagetest_run then
						nodedef.storagetest_run(pos2, node2, pos)
					end
				end
			end

			run_nodes(dv_nodes)
			run_nodes(st_nodes)

			meta:set_string("infotext", ("%s Active"):format(device_name))
		end,
	})
end

-------------------------------------
-- Update networks on block change --
-------------------------------------

local function check_connections(pos)
	local machines = {}
	for name in pairs(storagetest.devices) do
		machines[name] = true
	end
	local connections = {}
	local positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}
	for _,connected_pos in pairs(positions) do
		local name = minetest.get_node(connected_pos).name
		if machines[name] or storagetest.network.is_network_conductor(name) or get_item_group(name, "storagetest_controller") then
			table.insert(connections,connected_pos)
		end
	end
	return connections
end

function storagetest.network.clear_networks(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local name = node.name
	local placed = name ~= "air"
	local positions = check_connections(pos)
	if #positions < 1 then return end
	local dead_end = #positions == 1
	for _,connected_pos in pairs(positions) do
		local net = storagetest.network.devices[minetest.hash_node_position(connected_pos)] or minetest.hash_node_position(connected_pos)
		if net and storagetest.network.networks[net] then
			if dead_end and placed then
				-- Dead end placed, add it to the network
				-- Get the network
				local node_at = minetest.get_node(positions[1])
				local network_id = storagetest.network.devices[minetest.hash_node_position(positions[1])] or minetest.hash_node_position(positions[1])

				if not network_id or not storagetest.network.networks[network_id] then
					-- We're evidently not on a network, nothing to add ourselves to
					return
				end
				local c_pos = minetest.get_position_from_hash(network_id)
				local network = storagetest.network.networks[network_id]

				-- Actually add it to the (cached) network
				-- This is similar to check_node_subp
				storagetest.network.devices[minetest.hash_node_position(pos)] = network_id
				pos.visited = 1

				if storagetest.network.is_network_conductor(name) then
					table.insert(network.all_nodes, pos)
				end

				if storagetest.devices[name] then
					meta:set_string("st_network", minetest.pos_to_string(c_pos))
					if get_item_group(name, "storagetest_controller") then
						table.insert(network.controllers, pos)
					elseif get_item_group(name, "storagetest_storage") then
						table.insert(network.st_nodes, pos)
					elseif storagetest.network.is_network_device(name) then
						table.insert(network.dv_nodes, pos)
					end
				end
			elseif dead_end and not placed then
				-- Dead end removed, remove it from the network
				-- Get the network
				local network_id = storagetest.network.devices[minetest.hash_node_position(positions[1])] or minetest.hash_node_position(positions[1])
				if not network_id or not storagetest.network.networks[network_id] then
					-- We're evidently not on a network, nothing to remove ourselves from
					return
				end
				local network = storagetest.network.networks[network_id]

				-- Search for and remove device
				storagetest.network.devices[minetest.hash_node_position(pos)] = nil
				for tblname,table in pairs(network) do
					for devicenum,device in pairs(table) do
						if device.x == pos.x
						and device.y == pos.y
						and device.z == pos.z then
							table[devicenum] = nil
						end
					end
				end
			else
				-- Not a dead end, so the whole network needs to be recalculated
				for _,v in pairs(storagetest.network.networks[net].all_nodes) do
					local pos1 = minetest.hash_node_position(v)
					storagetest.network.devices[pos1] = nil
				end
				storagetest.network.networks[net] = nil
			end
		end
	end
end

-- Timeout ABM
-- Timeout for a node in case it was disconnected from the network
-- A node must be touched by the station continuously in order to function
local function controller_timeout_count(pos, tier)
	local meta = minetest.get_meta(pos)
	local timeout = meta:get_int("nw_timeout")
	if timeout <= 0 then
		return true
	else
		meta:set_int("nw_timeout", timeout - 1)
		return false
	end
end

function storagetest.network.register_abm_nodes()
	minetest.register_abm({
		label = "Devices: timeout check",
		nodenames = {"group:storagetest_device"},
		interval   = 1,
		chance     = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local meta = minetest.get_meta(pos)
			if storagetest.devices[node.name] and controller_timeout_count(pos) then
				local nodedef = minetest.registered_nodes[node.name]
				if nodedef and nodedef.storagetest_disabled_name then
					node.name = nodedef.storagetest_disabled_name
					minetest.swap_node(pos, node)
				elseif nodedef and nodedef.storagetest_on_disable then
					nodedef.storagetest_on_disable(pos, node)
				end
				if nodedef then
					local meta = minetest.get_meta(pos)
					meta:set_string("infotext", ("%s Has No Network"):format(nodedef.description))
				end
			end
		end,
	})
end

-----------------------
-- Network Functions --
-----------------------

function storagetest.network.get_storage_devices(network_id)
	local network = storagetest.network.networks[network_id]
	if not network or not network.st_nodes then return {} end
	return network.st_nodes
end

function concat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function storagetest.network.get_storage_inventories(network_id)
	local storage_nodes = storagetest.network.get_storage_devices(network_id)
	local items         = {}

	for _,pos in pairs(storage_nodes) do
		local stacks = storagetest.stack_list(pos)
		items = concat(items, stacks)
	end

	return items
end

function storagetest.network.insert_item(network_id, stack)
	local storage_nodes = storagetest.network.get_storage_devices(network_id)

	for _,pos in pairs(storage_nodes) do
		local success, leftover = storagetest.insert_stack(pos, stack)
		if success then
			return success, leftover
		end
	end

	return nil
end

function storagetest.network.take_item(network_id, stack)
	local storage_nodes = storagetest.network.get_storage_devices(network_id)

	for _,pos in pairs(storage_nodes) do
		local success, stacki = storagetest.take_stack(pos, stack)
		if success and stacki then
			if stacki:get_count() == stack:get_count() then
				return success, stacki
			else
				stack:set_count(stack:get_count() - stacki:get_count())
				return storagetest.network.take_item(network_id, stack)
			end
		end
	end

	return nil
end
