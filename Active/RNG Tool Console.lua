local lastFrameRng = 0x01234567
local thisFrameRng = 0x01234567
local intermediateValue = 0x01234567
local rngValueDiff = 0
local startingRng = 0x01234567

local rightShiftConstant = 4294967295
local leftShiftConstant = 8191

local rightShiftAmount = 13
local leftShiftAmount = 19

local rngAddr = 0x1150
local rngMemoryRegion = "IWRAM"

local wasError = false
local wasErrorTimer = 0
local wasErrorTimerDuration = 480

function write_intro()
	console.writeline("***********************************")
	console.writeline("*  TMC RNG Diff Lua Console Tool  *")
	console.writeline("*        Created By Hailey        *")
	console.writeline("* For Use With Bizhawk 2.9 and up *")
	console.writeline("***********************************")
end

event.onloadstate(
	function()
		write_intro()
		lastFrameRng = 0x01234567
		thisFrameRng = 0x01234567
		intermediateValue = 0x01234567
		rngValueDiff = 0
	end
)

local function load_current_rng()
	lastFrameRng = thisFrameRng
	intermediateValue = lastFrameRng
	thisFrameRng = memory.read_u32_le(rngAddr, rngMemoryRegion)
end

local function logical_or(value1, value2)
	return value1 | value2
end

local function logical_and(value1, value2)
	return value1 & value2
end

local function right_shift(value, shift_amount)
	return value >> shift_amount
end

local function left_shift(value, shift_amount)
	return value << shift_amount
end

local function compute_diff()
	rngValueDiff = 0

	if (thisFrameRng == startingRng or thisFrameRng == 0) then
		return
	end
	
	while (intermediateValue ~= thisFrameRng and rngValueDiff < 10000) do
		rngValueDiff = rngValueDiff + 1
		local tempValue = logical_and(intermediateValue * 3, 0xFFFFFFFF)
		intermediateValue = logical_and(logical_or(right_shift(logical_and(tempValue, rightShiftConstant), rightShiftAmount), left_shift(logical_and(tempValue, leftShiftConstant), leftShiftAmount)), 0xFFFFFFFF)
	end
	
	if (rngValueDiff >= 10000) then 
		lastFrameRng = thisFrameRng
		intermediateValue = thisFrameRng
		rngValueDiff = 0
		wasErrorTimer = 0
		wasError = true
	end
end

local function calculate_rng_diff()
	load_current_rng()
	compute_diff()
end

local function draw_rng_diff()
	gui.cleartext()
	if (wasError) then
		gui.drawString(0, 90, "Error: RNG Diff > 10000", "red", nil, 8, "MiniSet2")
		wasErrorTimer = wasErrorTimer + 1
		if (wasErrorTimer >= wasErrorTimerDuration) then
			wasError = false
		end
	end
	gui.drawString(0, 100, "Last Frame RNG Value:", "orange", nil, 8, "MiniSet2")
	gui.drawString(0, 110, string.format("	0x%08X", lastFrameRng), "orange", nil, 8, "MiniSet2")
	gui.drawString(0, 120, "This Frame RNG Value:", "pink", nil, 8, "MiniSet2")
	gui.drawString(0, 130, string.format("	0x%08X", thisFrameRng), "pink", nil, 8, "MiniSet2")
	gui.drawString(0, 140, "Total RNG Calls Last Frame:", "green", nil, 8, "MiniSet2")
	gui.drawString(0, 150, string.format("	%s", rngValueDiff), "green", nil, 8, "MiniSet2")
end

local function write_diff_to_console()
	emu.framecount()
	if (wasError) then
		console.writeline("Error: Total RNG calls this frame exceeded 10000!")
		wasError = false
	end
	
	if (rngValueDiff == 0) then
		return
	end
	
	console.writeline(string.format("Frame %s: ", emu.framecount()))
	console.writeline(string.format("	Last frame RNG: 0x%08X", lastFrameRng))
	console.writeline(string.format("	This frame RNG: 0x%08X", thisFrameRng))
	console.writeline(string.format("	Total RNG calls last frame: %s", rngValueDiff))
end

write_intro()

while true do
	calculate_rng_diff()
	write_diff_to_console()
	emu.frameadvance()
end