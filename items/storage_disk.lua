-- Storage disks

storagetest.disks = {}

local function inv_to_table(inv)
	local t = {}
	for listname, list in pairs(inv:get_lists()) do
		local size = inv:get_size(listname)
		if size then
			t[listname] = {}
			for i = 1, size, 1 do
				t[listname][i] = inv:get_stack(listname, i):to_table()
			end
		end
	end
	return t
end

local function table_to_inv(inv, t)
	for listname, list in pairs(t) do
		for i, stack in pairs(list) do
			inv:set_stack(listname, i, stack)
		end
	end
end

local function save_inv_itemstack(inv, stack)
	local meta = stack:get_meta()
	meta:set_string("storagetest_inventory", minetest.serialize(inv_to_table(inv)))
	return stack
end

function storagetest.disks.register_disk(index, desc, capacity)
	local mod = minetest.get_current_modname()
	minetest.register_craftitem(mod..":storage_disk"..index, {
		description = desc.."\nStores "..capacity.." Stacks",
		inventory_image = "storagetest_disk"..index..".png",
		groups = {storagetest_disk = 1},
		storagetest_capacity = capacity,
		storagetest_name = "disk"..index,
		stack_max = 1,
		on_secondary_use = function (itemstack, user, pointed_thing)
			local inv, stack = storagetest.disks.add_stack(itemstack, ItemStack("default:cobble 99"))
			if not inv then print("full!"); return itemstack end
			return stack
		end
	})
end

-- Make sure stack is disk
function storagetest.disks.is_valid_disk(stack)
	local stack_name = stack:get_name()
	return minetest.get_item_group(stack_name, "storagetest_disk") > 0
end

function storagetest.disks.get_stack_inventory(stack)
	if not storagetest.disks.is_valid_disk(stack) then return nil end
	local stack_name = stack:get_name()
	local meta       = stack:get_meta()
	local name       = minetest.registered_items[stack_name].storagetest_name
	local capacity   = minetest.registered_items[stack_name].storagetest_capacity

	local inv = minetest.create_detached_inventory(name, {

	})
	inv:set_size("main", capacity)
	local invmetastring = meta:get_string("storagetest_inventory")

	if invmetastring ~= "" then
		table_to_inv(inv, minetest.deserialize(invmetastring))
		save_inv_itemstack(inv, stack)
	end

	return inv, stack
end

function storagetest.disks.save_stack_inventory(inv, stack)
	if not storagetest.disks.is_valid_disk(stack) then return nil end
	stack = save_inv_itemstack(inv, stack)

	local meta     = stack:get_meta()
	local capacity = minetest.registered_items[stack:get_name()].storagetest_capacity
	local desc     = minetest.registered_items[stack:get_name()].description
	meta:set_string("description", desc.."\nContains "..storagetest.disks.get_stack_count(nil, inv).."/"..capacity)

	return inv, stack
end

function storagetest.disks.get_stack_count(stack, invn)
	local inv = invn or storagetest.disks.get_stack_inventory(stack)
	if not inv then return 0 end
	
	local count = 0
	for _,v in pairs(inv:get_list("main")) do
		if not v:is_empty() then
			count = count + 1
		end
	end

	return count
end

function storagetest.disks.add_stack(stack, item)
	local inv = storagetest.disks.get_stack_inventory(stack)
	if not inv then return nil end
	if not inv:room_for_item("main", item) then return nil end
	
	inv:add_item("main", item)

	return storagetest.disks.save_stack_inventory(inv, stack)
end

function storagetest.disks.has_stack(stack, item)
	local inv = storagetest.disks.get_stack_inventory(stack)
	if not inv then return nil end
	return inv:contains_item("main", item, true)
end

function storagetest.disks.take_stack(stack, item)
	local inv = storagetest.disks.get_stack_inventory(stack)
	if not inv then return nil end
	local item = inv:remove_item("main", item)
	
	inv, stack = storagetest.disks.save_stack_inventory(inv, stack)

	return item, stack
end

local capacities   = {1000, 8000, 16000, 32000, 64000}
local descriptions = {"1K Disk", "8K Disk", "16K Disk", "32K Disk", "64K Disk"}
for i = 1, 5 do
	storagetest.disks.register_disk(i, descriptions[i], capacities[i])
end
