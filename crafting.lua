-- Soldering
local solderer_recipes = {
	{
		input = {"", "default:steel_ingot", ""},
		output = "holostorage:basic_chip",
		time = 4,
	},
	{
		input = {"", "default:gold_ingot", ""},
		output = "holostorage:advanced_chip",
		time = 4,
	},
	{
		input = {"", "default:diamond", ""},
		output = "holostorage:elite_chip",
		time = 4,
	},
	{
		input = {"", "holostorage:silicon", ""},
		output = "holostorage:silicon_wafer",
		time = 4,
	},
	{
		input = {"holostorage:basic_chip", "holostorage:silicon_wafer", "default:mese_crystal"},
		output = "holostorage:basic_processor",
		time = 6,
	},
	{
		input = {"holostorage:advanced_chip", "holostorage:silicon_wafer", "default:mese_crystal"},
		output = "holostorage:advanced_processor",
		time = 6,
	},
	{
		input = {"holostorage:elite_chip", "holostorage:silicon_wafer", "default:mese_crystal"},
		output = "holostorage:elite_processor",
		time = 6,
	},
	{
		input = {"holostorage:elite_chip", "holostorage:grid", "default:mese_crystal"},
		output = "holostorage:crafting_grid",
		time = 12,
	},
	{
		input = {"holostorage:elite_chip", "dye:dark_green", "default:mese_crystal"},
		output = "holostorage:disk_control_circuit",
		time = 16,
	},
}

for _, recipe in pairs(solderer_recipes) do
	holostorage.solderer.register_recipe(recipe)
end

-- Crafting
-- Recipes involving quartz
local quartz = minetest.get_modpath("quartz") ~= nil
if quartz then
	minetest.register_craft({
		type = "shapeless",
		output = "holostorage:quartz_iron",
		recipe = {
			"default:steel_ingot", "quartz:quartz_crystal", "quartz:quartz_crystal", "quartz:quartz_crystal"
		}
	})

	minetest.register_craft({
		type = "cooking",
		output = "holostorage:silicon",
		recipe = "quartz:quartz_crystal"
	})
else
	minetest.register_craft({
		type = "cooking",
		output = "holostorage:silicon",
		recipe = "default:desert_sand"
	})
end

minetest.register_craft({
	output = "holostorage:machine_block",
	recipe = {
		{"holostorage:quartz_iron", "holostorage:quartz_iron", "holostorage:quartz_iron"},
		{"holostorage:quartz_iron", "",                        "holostorage:quartz_iron"},
		{"holostorage:quartz_iron", "holostorage:quartz_iron", "holostorage:quartz_iron"}
	}
})

minetest.register_craft({
	output = "holostorage:solderer",
	recipe = {
		{"holostorage:quartz_iron", "holostorage:quartz_iron",   "holostorage:quartz_iron"},
		{"default:mese_crystal",    "holostorage:machine_block", "default:mese_crystal"},
		{"holostorage:quartz_iron", "holostorage:quartz_iron",   "holostorage:quartz_iron"}
	}
})

minetest.register_craft({
	output = "holostorage:disk_drive0",
	recipe = {
		{"holostorage:quartz_iron", "holostorage:advanced_processor", "holostorage:quartz_iron"},
		{"holostorage:quartz_iron", "holostorage:machine_block",      "holostorage:quartz_iron"},
		{"holostorage:quartz_iron", "holostorage:advanced_processor", "holostorage:quartz_iron"}
	}
})

minetest.register_craft({
	output = "holostorage:grid",
	recipe = {
		{"holostorage:basic_processor", "holostorage:quartz_iron",   "default:glass"},
		{"default:mese_crystal",        "holostorage:machine_block", "default:glass"},
		{"holostorage:basic_processor", "holostorage:quartz_iron",   "default:glass"}
	}
})

minetest.register_craft({
	output = "holostorage:cable 16",
	recipe = {
		{"holostorage:quartz_iron", "holostorage:quartz_iron", "holostorage:quartz_iron"}
	}
})

minetest.register_craft({
	output = "holostorage:import_bus",
	recipe = {
		{"holostorage:advanced_processor", "holostorage:cable"},
		{"default:mese_crystal",           "holostorage:machine_block"}
	}
})

minetest.register_craft({
	output = "holostorage:export_bus",
	recipe = {
		{"holostorage:cable",    "holostorage:advanced_processor"},
		{"default:mese_crystal", "holostorage:machine_block"}
	}
})

minetest.register_craft({
	output = "holostorage:external_storage_bus",
	recipe = {
		{"holostorage:import_bus", "holostorage:export_bus"},
		{"default:mese_crystal",   "default:chest"}
	}
})

minetest.register_craft({
	output = "holostorage:controller",
	recipe = {
		{"default:mese_crystal", "holostorage:quartz_iron",   "default:mese_crystal"},
		{"default:diamond",      "holostorage:machine_block", "default:diamond"},
		{"default:mese_crystal", "holostorage:cable",         "default:mese_crystal"},
	}
})

-- Platters
minetest.register_craft({
	output = "holostorage:quartz_platter",
	recipe = {
		{"",    "holostorage:quartz_iron", ""},
		{"holostorage:quartz_iron", "default:mese_crystal", "holostorage:quartz_iron"},
		{"",    "holostorage:quartz_iron", ""},
	}
})

-- Disks
minetest.register_craft({
	output = "holostorage:storage_disk1",
	recipe = {
		{"holostorage:advanced_processor",   "holostorage:quartz_platter",  "holostorage:advanced_processor"},
		{"holostorage:quartz_platter",       "holostorage:elite_processor", "holostorage:quartz_platter"},
		{"holostorage:disk_control_circuit", "holostorage:quartz_iron",     "holostorage:disk_control_circuit"},
	}
})
