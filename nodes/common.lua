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
	local front = minetest.facedir_to_dir(fd)
	front.x = front.x * -1 + pos.x
	front.y = front.y * -1 + pos.y
	front.z = front.z * -1 + pos.z
	return front
end
