require("TmcLuaHelpers")

local helper = TmcLuaHelpers:new(nil)

local last_area_and_room = { area = -1, room = -1 }
local layer_1_collision_data_start_address = 0x02027EB4
local layer_2_collision_data_start_address = 0x0200D654

local function file_exists(name)
   local f = io.open(name, "r")
   if f then f:close() return true else return false end
end

while true do    
    local current_area_and_room = helper:load_area_and_room()
    
    if (current_area_and_room["area"] ~= last_area_and_room["area"] or current_area_and_room["room"] ~= last_area_and_room["room"]) then
        
        local area_hex = string.format("%02X", current_area_and_room["area"])
        local room_hex = string.format("%02X", current_area_and_room["room"])
        local filename = string.format("Area_%s_Room_%s.txt", area_hex, room_hex)

        if not file_exists(filename) then
            console.writeline("Dumping collision to " .. filename)
            
            local file = io.open(filename, "w")
            file:write("Collision dump for area 0x" .. area_hex .. " and room 0x" .. room_hex .. "\n\n")

            local layer_1_lines = {}
            local layer_2_lines = {}
            
            for row_index = 0, 0x3F do
                local begin_offset = helper:logical_left_shift(row_index, 6)
                local layer_1_row = {}
                local layer_2_row = {}
                
                for col_index = 0, 0x3F do
                    local offset = begin_offset + col_index
                    
                    local layer_1_collision_value = memory.read_u8(layer_1_collision_data_start_address + offset)
                    table.insert(layer_1_row, string.format("%02X", layer_1_collision_value))
                    
                    local layer_2_collision_value = memory.read_u8(layer_2_collision_data_start_address + offset)
                    table.insert(layer_2_row, string.format("%02X", layer_2_collision_value))
                end
                
                table.insert(layer_1_lines, table.concat(layer_1_row, " "))
                table.insert(layer_2_lines, table.concat(layer_2_row, " "))
            end 

            file:write("Layer 1:\n")
            file:write(table.concat(layer_1_lines, "\n") .. "\n\n")
            
            file:write("Layer 2:\n")
            file:write(table.concat(layer_2_lines, "\n") .. "\n")
            
            file:close()
        else
            console.writeline("Skipping dump; " .. filename .. " already exists.")
        end
    end
    
    last_area_and_room = current_area_and_room
    emu.frameadvance()
end