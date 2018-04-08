-- Storagetest commons

storagetest.helpers = {}

function storagetest.helpers.swap_node(pos, noded)
	local node = minetest.get_node(pos)
	if node.name == noded.name then
		return
	end
	minetest.swap_node(pos, noded)
end

function storagetest.helpers.grid_refresh(pos, n, controller)
	local node    = minetest.get_node(pos)
	local meta    = minetest.get_meta(pos)
	local nodedef = minetest.registered_nodes[node.name]
	local prev    = meta:get_string("controller")

	meta:set_string("infotext", ("%s Active"):format(nodedef.description))
	meta:set_string("controller", minetest.pos_to_string(controller))

	if not prev or prev == "" then
		minetest.get_node_timer(pos):start(0.02)
	end

	if nodedef.storagetest_enabled_name then
		node.name = nodedef.storagetest_enabled_name
		storagetest.helpers.swap_node(pos, node)
	end
end
