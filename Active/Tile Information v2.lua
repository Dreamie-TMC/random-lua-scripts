local last_frame_inputs = {}
local last_frame_keys = {}
local current_map_data = 0
local original_map_data = 0
local current_tile_metadata = 0
local original_tile_metadata = 0
local current_tile_collision_data = 0
local tile_in_front_collision_data = 0
local number_type_swap_timer = 0
local metadata_swap_timer = 0
local use_hex = true
local use_metadata = true
local init_timer = 240

console.writeline("Press 'H' to switch between hex (default) and decimal representation")
console.writeline("")
console.writeline("Current Mode: Hex")
console.writeline("")
console.writeline("Press 'I' to switch between metadata (default) and raw tile data representation")
console.writeline("")
console.writeline("Raw tile data is only relevant when messing with invalid tile data with the firerod")
console.writeline("")
console.writeline("Current Tile Mode: Metadata")

while true do
	local this_frame_inputs = joypad.get()
	local keys = input.get()
	
	if keys["H"] and not last_frame_keys["H"] then
		number_type_swap_timer = 240
		if use_hex then
			use_hex = false
			console.writeline("Current Mode: Decimal")
		else
			use_hex = true
			console.writeline("Current Mode: Hex")
		end
	end
	
	if keys["I"] and not last_frame_keys["I"] then
		metadata_swap_timer = 240
		if use_metadata then
			use_metadata = false
			console.writeline("Current Tile Mode: Raw")
		else
			use_metadata = true
			console.writeline("Current Tile Mode: Metadata")
		end
	end
	
	local link_facing_angle = memory.read_u8(0x03001174)
	local link_layer = memory.read_u8(0x03001198)
	local link_coordinates = memory.read_u16_le(0x03003FA2)
	local in_front_of_link = link_coordinates
	if link_facing_angle == 0 then
		in_front_of_link = link_coordinates - 0x40
	elseif link_facing_angle == 2 then
		in_front_of_link = link_coordinates + 0x1
	elseif link_facing_angle == 4 then
		in_front_of_link = link_coordinates + 0x40
	elseif link_facing_angle == 6 then
		in_front_of_link = link_coordinates - 0x1
	end
	
	if link_layer == 1 or link_layer == 3 then
		current_map_data = memory.read_u16_le(0x02025EB4 + (link_coordinates * 2))
		original_map_data = memory.read_u16_le(0x02028EB4 + (link_coordinates * 2))
		current_tile_collision_data = memory.read_u8(0x02027EB4 + link_coordinates)
		tile_in_front_collision_data = memory.read_u8(0x02027EB4 + in_front_of_link)
		current_tile_metadata = memory.read_u16_le(0x0202AEB4 + (2 * current_map_data))
		original_tile_metadata = memory.read_u16_le(0x0202AEB4 + (2 * original_map_data))
	elseif link_layer == 2 then
		current_map_data = memory.read_u16_le(0x0200B654 + (link_coordinates * 2))
		original_map_data = memory.read_u16_le(0x0200E654 + (link_coordinates * 2))
		current_tile_collision_data = memory.read_u8(0x0200D654 + link_coordinates)
		tile_in_front_collision_data = memory.read_u8(0x0200D654 + in_front_of_link)
		current_tile_metadata = memory.read_u16_le(0x02010654 + (2 * current_map_data))
		original_tile_metadata = memory.read_u16_le(0x02010654 + (2 * original_map_data))
	else
		current_map_data = 0
		original_map_data = 0
		current_tile_metadata = 0
		original_tile_metadata = 0
		current_tile_collision_data = 0
		tile_in_front_collision_data = 0
	end
	
	if use_hex then
		gui.text(0, 65, "Current tile under Link: " .. string.format("%X", use_metadata and current_tile_metadata or current_map_data))
		gui.text(0, 80, "Original tile under Link: " .. string.format("%X", use_metadata and original_tile_metadata or original_map_data))
		gui.text(0, 95, "Current tile collision data: " .. string.format("%X", current_tile_collision_data))
		gui.text(0, 110, "Collision of tile in front: " .. string.format("%X", tile_in_front_collision_data))
	else
		gui.text(0, 65, "Current tile under Link: " .. (use_metadata and current_tile_metadata or current_map_data))
		gui.text(0, 80, "Original tile under Link: " .. (use_metadata and original_tile_metadata or original_map_data))
		gui.text(0, 95, "Current tile collision data: " .. current_tile_collision_data)
		gui.text(0, 110, "Collision of tile in front: " .. tile_in_front_collision_data)
	end
	
	if init_timer > 0 then
		gui.text(0, 20, "Tile Data Viewer - Tool Created by M - See console for details", "SpringGreen")
		init_timer = init_timer - 1
	end
	
	if number_type_swap_timer > 0 then
		gui.text(0, 35, "Current Number Display Mode: " .. (use_hex and "Hex" or "Decimal"), "Cyan")
		number_type_swap_timer = number_type_swap_timer - 1
	end
	
	if metadata_swap_timer > 0 then
		gui.text(0, 50, "Current Tile Display Mode: " .. (use_metadata and "Metadata (default)" or "Raw"), "Fuchsia")
		metadata_swap_timer = metadata_swap_timer - 1
	end
	
	last_frame_inputs = this_frame_inputs
	last_frame_keys = keys
	emu.frameadvance()
end