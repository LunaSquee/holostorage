-- Storage disks

holostorage.disks = {}

function holostorage.disks.register_disk(index, desc, capacity)
	local mod = minetest.get_current_modname()
	minetest.register_craftitem(mod..":storage_disk"..index, {
		description = desc.."\nStores "..capacity.." Stacks",
		inventory_image = "holostorage_disk"..index..".png",
		groups = {holostorage_disk = 1},
		holostorage_capacity = capacity,
		holostorage_name = "disk"..index,
		stack_max = 1,
		on_secondary_use = function (itemstack, user, pointed_thing)
			return stack
		end
	})
end

-- Make sure stack is disk
function holostorage.disks.is_valid_disk(stack)
	local stack_name = stack:get_name()
	return minetest.get_item_group(stack_name, "holostorage_disk") > 0
end

local capacities   = {1000, 8000, 16000, 32000, 64000}
local descriptions = {"1K Disk", "8K Disk", "16K Disk", "32K Disk", "64K Disk"}
for i = 1, 5 do
	holostorage.disks.register_disk(i, descriptions[i], capacities[i])
end
