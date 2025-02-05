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
	frame_counter = frame_counter + 1
	if (new_location[1] == 0 and new_location[2] == 0) then
		--0, 0 means start menu is opened. Here we don't want to update the location but we still want the timer to tick (This breaks for minish woods maybe?)
		local addend = 0.016
		if (frame_counter % 3 == 0) then
			addend = 0.017
		end
		room_time = room_time + addend
	elseif (current_location[1] == new_location[1] and current_location[2] == new_location[2]) then		
		local addend = 0.016
		if (frame_counter % 3 == 0) then
			addend = 0.017
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