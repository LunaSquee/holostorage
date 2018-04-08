-- Solderer

holostorage.solderer = {}
holostorage.solderer.recipes = {}

local box = {
	type = "fixed",
	fixed = {
		{-0.4375, -0.5000, -0.4375, 0.4375, -0.2500, 0.4375},
		{-0.4375, 0.2500, -0.4375, 0.4375, 0.5000, 0.4375},
		{-0.3750, -0.2500, -0.3750, 0.3750, -0.1250, 0.3750},
		{-0.3750, 0.1250, -0.3750, 0.3750, 0.2500, 0.3750},
		{-0.2500, -0.1250, -0.2500, -0.1250, 0.1250, -0.1250},
		{-0.2500, -0.1250, 0.1250, -0.1250, 0.1250, 0.2500},
		{0.1250, -0.1250, 0.1250, 0.2500, 0.1250, 0.2500},
		{0.1250, -0.1250, -0.2500, 0.2500, 0.1250, -0.1250}
	}
}

local collision_box = {
	type = "fixed",
	fixed = {-1/2.3, -1/2, -1/2.3, 1/2.3, 1/2, 1/2.3},
}

local function get_formspec(min, max)
	local bar = "image[3.5,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"
	
	if min ~= nil then
		local percent = math.floor((min/max)*100)
		bar = "image[3.5,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
			  (percent)..":gui_furnace_arrow_fg.png^[transformR270]"
	end

	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Solderer]"..
		"list[context;src;2.5,0.5;1,3;]"..
		bar..
		"list[context;dst;4.5,1.5;1,1;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;src]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	if listname == "dst" then
		return 0
	end

	return stack:get_count()
end

local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	return stack:get_count()
end

local function get_recipe_index(items)
	if not items or type(items) ~= "table" then return false end
	local l = {}
	for i, stack in ipairs(items) do
		l[i] = ItemStack(stack):get_name()
	end
	return table.concat(l, "/")
end

function holostorage.solderer.register_recipe(data)
	for i, stack in ipairs(data.input) do
		data.input[i] = ItemStack(stack):to_string()
	end

	if type(data.output) == "table" then
		for i, v in ipairs(data.output) do
			data.output[i] = ItemStack(data.output[i]):to_string()
		end
	else
		data.output = ItemStack(data.output):to_string()
	end
	
	local index = get_recipe_index(data.input)
	
	holostorage.solderer.recipes[index] = data
end

function holostorage.solderer.get_recipe(items)
	local index = get_recipe_index(items)
	local recipe = holostorage.solderer.recipes[index]
	if recipe then
		local new_input = {}
		for i, stack in ipairs(items) do
			new_input[i] = ItemStack(stack)
			new_input[i]:take_item(1)
		end
		return {time = recipe.time,
		        new_input = new_input,
		        output = recipe.output}
	else
		return nil
	end
end

local function round(v)
	return math.floor(v + 0.5)
end

local function run_solderer(pos, _, controller)
	local meta     = minetest.get_meta(pos)
	local inv      = meta:get_inventory()

	local machine_node  = "holostorage:solderer"
	local machine_speed = 1

	while true do
		local result = holostorage.solderer.get_recipe(inv:get_list("src"))
		if not result then
			local swap = holostorage.helpers.swap_node(pos, machine_node)
			if swap then
				meta:set_string("infotext", "Solderer Idle")
				meta:set_string("formspec", get_formspec())
				meta:set_int("src_time", 0)
			end
			return
		end
		meta:set_int("src_time", meta:get_int("src_time") + round(machine_speed * 10))
		holostorage.helpers.swap_node(pos, machine_node.."_active")
		meta:set_string("infotext", "Solderer Active")
		if meta:get_int("src_time") <= round(result.time*10) then
			meta:set_string("formspec", get_formspec(meta:get_int("src_time"), round(result.time*10)))
			return
		end
		local output = result.output
		if type(output) ~= "table" then output = { output } end
		local output_stacks = {}
		for _, o in ipairs(output) do
			table.insert(output_stacks, ItemStack(o))
		end
		local room_for_output = true
		inv:set_size("dst_tmp", inv:get_size("dst"))
		inv:set_list("dst_tmp", inv:get_list("dst"))
		for _, o in ipairs(output_stacks) do
			if not inv:room_for_item("dst_tmp", o) then
				room_for_output = false
				break
			end
			inv:add_item("dst_tmp", o)
		end
		if not room_for_output then
			holostorage.helpers.swap_node(pos, machine_node)
			meta:set_string("infotext", "Solderer Idle")
			meta:set_string("formspec", get_formspec())
			meta:set_int("src_time", round(result.time*10))
			return
		end
		meta:set_int("src_time", meta:get_int("src_time") - round(result.time*10))
		inv:set_list("src", result.new_input)
		inv:set_list("dst", inv:get_list("dst_tmp"))
	end
end

minetest.register_node("holostorage:solderer", {
	description = "Solderer",
	drawtype = "nodebox",
	node_box = box,
	is_ground_content = false,
	tiles = {"holostorage_machine_block.png"},
	groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
	},
	on_construct = function (pos)
		holostorage.network.clear_networks(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_formspec())

		local inv  = meta:get_inventory()
		inv:set_size("src", 3)
		inv:set_size("dst", 1)
	end,
	on_destruct = holostorage.network.clear_networks,
	selection_box = collision_box,
	collision_box = collision_box,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	holostorage_run = run_solderer,
})

minetest.register_node("holostorage:solderer_active", {
	description = "Solderer",
	drawtype = "nodebox",
	paramtype = "light",
	light_source = 8,
	node_box = box,
	is_ground_content = false,
	drop = "holostorage:solderer",
	tiles = {"holostorage_machine_block.png"},
	groups = {
		cracky = 1,
		holostorage_distributor = 1,
		holostorage_device = 1,
		not_in_creative_inventory = 1,
	},
	on_destruct = holostorage.network.clear_networks,
	selection_box = collision_box,
	collision_box = collision_box,

	holostorage_disabled_name = "holostorage:solderer",

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	holostorage_run = run_solderer,
})

holostorage.devices["holostorage:solderer"] = true
holostorage.devices["holostorage:solderer_active"] = true
