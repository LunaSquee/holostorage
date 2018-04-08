-- Storage disks

holostorage.disks = {}
holostorage.disks.memcache = {}

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

local function create_invref(ptr, capacity)
	local inv = minetest.create_detached_inventory(ptr, {})
	inv:set_size("main", capacity)
	return inv
end

function holostorage.disks.ensure_disk_inventory(stack, pstr)
	local meta = stack:get_meta()
	local tag  = meta:get_string("storage_tag")
	local cap  = minetest.registered_items[stack:get_name()].holostorage_capacity
	
	if not tag or tag == "" then
		local rnd = PseudoRandom(os.clock())
		local rndint = rnd.next(rnd)
		local diskid = "d"..pstr.."-"..rndint
		meta:set_string("storage_tag", diskid)
		holostorage.disks.memcache[diskid] = create_invref(diskid, cap)
	end

	return stack
end

function holostorage.disks.load_disk_from_file(stack, diskptr)
	local world     = minetest.get_worldpath()
	local directory = world.."/holostorage"
	local cap       = minetest.registered_items[stack:get_name()].holostorage_capacity
	local inv       = create_invref(diskptr, cap)
	minetest.mkdir(directory)

	local filetag = minetest.sha1(diskptr)..".invref"
	local file = io.open(directory.."/"..filetag)
	
	if not file then
		holostorage.disks.memcache[diskptr] = inv
		return diskptr
	end

	local str = ""
	for line in file:lines() do
		str = str..line
	end

	file:close()

	table_to_inv(inv, minetest.deserialize(str))
	holostorage.disks.memcache[diskptr] = inv
	return diskptr
end

function holostorage.disks.save_disk_to_file(diskptr)
	if not holostorage.disks.memcache[diskptr] then return nil end

	local world     = minetest.get_worldpath()
	local directory = world.."/holostorage"
	local filetag   = minetest.sha1(diskptr)..".invref"

	minetest.mkdir(directory)

	local inv  = holostorage.disks.memcache[diskptr]
	local data = minetest.serialize(inv_to_table(inv))

	minetest.safe_file_write(directory.."/"..filetag, data)
	return diskptr
end

function holostorage.disks.save_disks_to_file()
	for diskptr in pairs(holostorage.disks.memcache) do
		holostorage.disks.save_disk_to_file(diskptr)
	end
end

-- Make sure stack is disk
function holostorage.disks.is_valid_disk(stack)
	local stack_name = stack:get_name()
	return minetest.get_item_group(stack_name, "holostorage_disk") > 0
end

-- Save disks on shutdown
minetest.register_on_shutdown(function ()
	holostorage.disks.save_disks_to_file()
end)

local capacities   = {1000, 8000, 16000, 32000, 64000}
local descriptions = {"1K Disk", "8K Disk", "16K Disk", "32K Disk", "64K Disk"}
for i = 1, 5 do
	holostorage.disks.register_disk(i, descriptions[i], capacities[i])
end
