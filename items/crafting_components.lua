
-- Chips
minetest.register_craftitem("holostorage:basic_chip", {
	description = "Basic Processor Chip",
	inventory_image = "holostorage_basic_node.png"
})

minetest.register_craftitem("holostorage:advanced_chip", {
	description = "Advanced Processor Chip",
	inventory_image = "holostorage_advanced_node.png"
})

minetest.register_craftitem("holostorage:elite_chip", {
	description = "Elite Processor Chip",
	inventory_image = "holostorage_elite_node.png"
})

-- Silicon
minetest.register_craftitem("holostorage:silicon", {
	description = "Silicon",
	inventory_image = "holostorage_silicon.png",
	groups = {silicon = 1}
})

minetest.register_craftitem("holostorage:silicon_wafer", {
	description = "Silicon Wafer",
	inventory_image = "holostorage_wafer.png",
	groups = {wafer = 1}
})

-- Processors
minetest.register_craftitem("holostorage:basic_processor", {
	description = "Basic Processor",
	inventory_image = "holostorage_basic_processor.png"
})

minetest.register_craftitem("holostorage:advanced_processor", {
	description = "Advanced Processor",
	inventory_image = "holostorage_advanced_processor.png"
})

minetest.register_craftitem("holostorage:elite_processor", {
	description = "Elite Processor",
	inventory_image = "holostorage_elite_processor.png"
})

-- Disk components
minetest.register_craftitem("holostorage:quartz_platter", {
	description = "Quartz Platter (1K)",
	inventory_image = "holostorage_quartz_platter.png"
})

minetest.register_craftitem("holostorage:resistant_platter", {
	description = "Resistant Platter (8K)",
	inventory_image = "holostorage_resistant_platter.png"
})

minetest.register_craftitem("holostorage:adapt_platter", {
	description = "Adapt Platter (16K)",
	inventory_image = "holostorage_adapt_platter.png"
})

minetest.register_craftitem("holostorage:nanostorage_platter", {
	description = "Nanostorage Platter (32K)",
	inventory_image = "holostorage_nanostorage_platter.png"
})

minetest.register_craftitem("holostorage:elite_platter", {
	description = "Elite Nanostorage Platter (64K)",
	inventory_image = "holostorage_elite_platter.png"
})

minetest.register_craftitem("holostorage:disk_control_circuit", {
	description = "Disk Control Circuit",
	inventory_image = "holostorage_disk_control_circuit.png"
})

-- Other
minetest.register_node("holostorage:machine_block", {
	description = "Machine Block",
	tiles = {"holostorage_machine_block.png"},
	groups = {cracky = 2}
})

minetest.register_craftitem("holostorage:quartz_iron", {
	description = "Quartz-Enriched Iron",
	inventory_image = "holostorage_quartz_iron.png"
})
