-- Storagetest commons

storagetest.helpers = {}

function storagetest.helpers.swap_node(pos, noded)
	local node = minetest.get_node(pos)
	if node.name == noded.name then
		return
	end
	minetest.swap_node(pos, noded)
end

function storagetest.helpers.grid_refresh(pos, n, network)
	local node    = minetest.get_node(pos)
	local nodedef = minetest.registered_nodes[node.name]

	if nodedef.storagetest_enabled_name then
		node.name = nodedef.storagetest_enabled_name
		storagetest.helpers.swap_node(pos, node)
	end
end
