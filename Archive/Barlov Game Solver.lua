local npc_list_addr_first = 0x03003DAC
local npc_list_addr = 0x03003DA8

local left = "Left"
local center = "Center"
local right = "Right"
local none = "None"

local next_entity_offset = 0x4
local id_offset = 0x9
local type2_offset = 0xB
local timer_offset = 0xE
local subtimer_offset = 0xF

local target_id = 0x51
local bad_type_subtimer = 0xFF
local target_area = 0x23
local target_room = 0x8

local function load_area_and_room()
	local area = memory.read_s8(0x0BF4, "IWRAM")
	local room = memory.read_s8(0x0BF5, "IWRAM")
	return {Area = area, Room = room}
end

local function get_chest_with_money()
	local entity = memory.read_u32_le(npc_list_addr_first, "System Bus")
	
	local is_level_two = true
	local index = 0
	local attempts = 0
	
	while entity ~= npc_list_addr do
		local id = memory.read_u8(entity + id_offset, "System Bus")
		local type2 = memory.read_u8(entity + type2_offset, "System Bus")
		local timer = memory.read_u8(entity + timer_offset, "System Bus")
		local subtimer = memory.read_u8(entity + subtimer_offset, "System Bus")
		
		if id ~= target_id or type2 == bad_type_subtimer then
			entity = memory.read_u32_le(entity + next_entity_offset, "System Bus")
		elseif timer == bad_type_subtimer then
			return none
		elseif subtimer == bad_type_subtimer then
			is_level_two = false
			entity = memory.read_u32_le(entity + next_entity_offset, "System Bus")
		elseif subtimer ~= 1 then
			attempts = attempts + 1
			entity = memory.read_u32_le(entity + next_entity_offset, "System Bus")			
		else
			index = attempts
			entity = memory.read_u32_le(entity + next_entity_offset, "System Bus")
		end
	end
	
	if is_level_two then
		if index == 0 then
			return left
		elseif index == 1 then
			return center
		elseif index == 2 then
			return right
		else
			return none
		end
	else
		if index == 0 then
			return left
		elseif index == 1 then
			return right
		else
			return none
		end
	end
end

while true do
	local area_and_room = load_area_and_room()
	if area_and_room.Area == target_area and area_and_room.Room == target_room then
		local chest = get_chest_with_money()
		gui.text(0, 65, "Chest to open: " .. chest)
	end
	emu.frameadvance()
end