
-- INVENTORY CACHE
holostorage.server_inventory = {
	cache = {},
	new = function (size)
		local system = {
			size = size,
			stacks = {}
		}

		function system:get_size(abs)
			return system.size
		end

		function system:get_stack(abs, index)
			if not index then index = abs end
			
			if system.stacks[index] then
				return system.stacks[index]
			end

			return ItemStack(nil)
		end

		function system:set_stack(abs, index, stack)
			if not stack then
				stack = index
				index = abs
			end

			if type(stack) == "table" or type(stack) == "string" then
				stack = ItemStack(stack)
			end

			system.stacks[index] = stack
			return stack
		end

		function system:get_list(abs)
			return system.stacks
		end

		function system:set_list(abs, list)
			if not list then list = abs end

			system.stacks = list
		end

		function system:get_width(abs)
			local size = 0
			for _,v in pairs(system.stacks) do
				if v and not v:is_empty() then
					size = size + 1
				end
			end
			return size
		end

		function system:first_empty_index()
			local index = 0
			local last = 0
			for inx, stack in pairs(system.stacks) do
				if stack:is_empty() then
					index = inx
					break
				end

				if last ~= inx - 1 then
					index = inx - 1
					break
				end
				last = inx
			end

			if index == 0 then
				return #system.stacks + 1
			end

			return index
		end

		function system:room_for_item(abs, stack)
			if not stack then stack = abs end
			local matching = false

			if system:get_width() < system.size then return true end

			for _,stc in pairs(system.stacks) do
				if not stc or stc:is_empty() then
					matching = true
					break
				end

				if stc:get_name() == stack:get_name() and 
					stc:get_meta() == stack:get_meta() then
					if stc:item_fits(stack) then
						matching = true
						break
					end
				end
			end
			return matching
		end

		function system:add_item(abs, stack)
			if not stack then stack = abs end
			local leftover = nil
			local first_empty_index = system:first_empty_index()
			local added = false

			for i, stc in pairs(system.stacks) do
				if stc:get_name() == stack:get_name() and stc:get_meta() == stack:get_meta() then
					if stc:get_count() == stack:get_stack_max() then
						break
					end

					leftover = system.stacks[i]:add_item(stack)
					if leftover and not leftover:is_empty() and system:room_for_item(leftover) then
						leftover = system:add_item(leftover)
					end

					added = true
					break
				end
			end
			
			if added then return leftover end

			if not leftover then
				system.stacks[system:first_empty_index()] = stack
				leftover = ItemStack(nil)
			end 
			
			return leftover
		end

		return system
	end,
	from_table = function (inv, table)
		if table["main"] then
			table = table["main"]
		end

		for i, stack in pairs(table) do
			inv:set_stack(i, stack)
		end

		return inv
	end,
	to_table = function (inv)
		local t = {}
		local size = inv:get_size()
		if size then
			for i = 1, size, 1 do
				t[i] = inv:get_stack(i):to_table()
			end
		end
		return t
	end
}

local function create_invref(capacity)
	return holostorage.server_inventory.new(capacity)
end

function holostorage.server_inventory.ensure_disk_inventory(stack, pstr)
	local meta = stack:get_meta()
	local tag  = meta:get_string("storage_tag")
	local cap  = minetest.registered_items[stack:get_name()].holostorage_capacity
	
	if not tag or tag == "" then
		local rnd = PseudoRandom(os.clock())
		local rndint = rnd.next(rnd)
		local diskid = "d"..pstr.."-"..rndint
		meta:set_string("storage_tag", diskid)
		holostorage.server_inventory.cache[diskid] = create_invref(cap)
	end

	return stack
end

function holostorage.server_inventory.load_disk_from_file(stack, diskptr)
	local world     = minetest.get_worldpath()
	local directory = world.."/holostorage"
	local cap       = minetest.registered_items[stack:get_name()].holostorage_capacity
	local inv       = create_invref(cap)
	minetest.mkdir(directory)

	local filetag = minetest.sha1(diskptr)..".invref"
	local file = io.open(directory.."/"..filetag)
	
	if not file then
		holostorage.server_inventory.cache[diskptr] = inv
		return diskptr
	end

	local str = ""
	for line in file:lines() do
		str = str..line
	end

	file:close()

	holostorage.server_inventory.from_table(inv, minetest.deserialize(str))
	holostorage.server_inventory.cache[diskptr] = inv
	return diskptr
end

function holostorage.server_inventory.save_disk_to_file(diskptr)
	if not holostorage.server_inventory.cache[diskptr] then return nil end

	local world     = minetest.get_worldpath()
	local directory = world.."/holostorage"
	local filetag   = minetest.sha1(diskptr)..".invref"

	minetest.mkdir(directory)

	local inv  = holostorage.server_inventory.cache[diskptr]
	local data = minetest.serialize(holostorage.server_inventory.to_table(inv))

	minetest.safe_file_write(directory.."/"..filetag, data)
	return diskptr
end

function holostorage.server_inventory.save_disks_to_file()
	for diskptr in pairs(holostorage.server_inventory.cache) do
		holostorage.server_inventory.save_disk_to_file(diskptr)
	end
end

-- Save disks on shutdown
minetest.register_on_shutdown(function ()
	holostorage.server_inventory.save_disks_to_file()
end)
