current_location = {memory.readbyte(0x0BF4), memory.readbyte(0x0BF5)}
room_time = 0
previous_room_time = 0
prev_room_frame_count = 0
frame_counter = 0

client.SetGameExtraPadding(130, 0, 0, 0)

event.onloadstate(
	function()
		room_time = 0
		previous_room_time = 0
		prev_room_frame_count = 0
		frame_counter = 0
		current_location = {memory.readbyte(0x0BF4), memory.readbyte(0x0BF5)}
	end
)

memory.usememorydomain("IWRAM")
while true do
	local new_location = {memory.readbyte(0x0BF4), memory.readbyte(0x0BF5)}
	local is_in_menu = memory.read_u16_le(0x10CF) == 0x100
	frame_counter = frame_counter + 1
	if (is_in_menu) then
		local addend = 0.017
		if (frame_counter % 3 == 2) then
			addend = 0.016
		end
		room_time = room_time + addend
	elseif (current_location[1] == new_location[1] and current_location[2] == new_location[2]) then		
		local addend = 0.017
		if (frame_counter % 3 == 2) then
			addend = 0.016
		end
		room_time = room_time + addend
	else
		previous_room_time = room_time
		prev_room_frame_count = frame_counter - 1
		room_time = 0
		frame_counter = 0
		current_location = new_location
	end
	gui.cleartext()
	gui.pixelText(0, 110, string.format("Room time: %.3f seconds", room_time), "orange", nil)
	gui.pixelText(0, 120, string.format("Room time: %s frames", frame_counter), "orange", nil)
	gui.pixelText(0, 140, string.format("Prev room time: %.3f seconds", previous_room_time), "green", nil)
	gui.pixelText(0, 150, string.format("Prev room time: %s frames", prev_room_frame_count), "green", nil)
	emu.frameadvance()
end