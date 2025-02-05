local lastFrameRng = 0x01234567
local thisFrameRng = 0x01234567
local rngValueDiff = 0
local rngValueAbs = 0
local startingRng = 0x01234567

local rightShiftConstant = 4294967295
local leftShiftConstant = 8191

local rightShiftAmount = 13
local leftShiftAmount = 19

local rngAddr = 0x1150
local rngMemoryRegion = "IWRAM"

client.SetGameExtraPadding(110, 0, 0, 0)

event.onloadstate(
	function()
		lastFrameRng = 0x01234567
		thisFrameRng = 0x01234567
		rngValueDiff = 0
		rngValueAbs = 0
	end
)

local function load_current_rng()
	lastFrameRng = thisFrameRng
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

local function rng_count(x)
	i = 0
	
	y = startingRng

	if (x == startingRng or thisFrameRng == 0) then
		return
	end

	while (y ~= x) do
		i = i + 1
		local tempValue = logical_and(y * 3, 0xFFFFFFFF)
		y = logical_and(logical_or(right_shift(logical_and(tempValue, rightShiftConstant), rightShiftAmount), left_shift(logical_and(tempValue, leftShiftConstant), leftShiftAmount)), 0xFFFFFFFF)
	end

	return i
end

local function compute_diff()
	rngValueDiff = 0
	
	if (thisFrameRng == startingRng or thisFrameRng == 0 or thisFrameRng == lastFrameRng) then
		return
	end
	
	local tempValue = rng_count(thisFrameRng)

	rngValueDiff = tempValue - rngValueAbs

	rngValueAbs = tempValue

end

local function calculate_rng_diff()
	load_current_rng()
	compute_diff()
end

local function draw_rng_diff()
	gui.cleartext()
	gui.drawString(0, 80, "Last Frame RNG Value:", "orange", nil, 8, "MiniSet2")
	gui.drawString(0, 90, string.format("	0x%08X", lastFrameRng), "orange", nil, 8, "MiniSet2")
	gui.drawString(0, 100, "This Frame RNG Value:", "pink", nil, 8, "MiniSet2")
	gui.drawString(0, 110, string.format("	0x%08X", thisFrameRng), "pink", nil, 8, "MiniSet2")
	gui.drawString(0, 120, "RNG Changes Last Frame:", "green", nil, 8, "MiniSet2")
	gui.drawString(0, 130, string.format("	%s", rngValueDiff), "green", nil, 8, "MiniSet2")
	gui.drawString(0, 140, "Total RNG Changes:", "yellow", nil, 8, "MiniSet2")
	gui.drawString(0, 150, string.format("	%s", rngValueAbs), "yellow", nil, 8, "MiniSet2")
end

while true do
	calculate_rng_diff()
	draw_rng_diff()
	emu.frameadvance()
end