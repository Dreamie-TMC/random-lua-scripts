local memoryRegion = "IWRAM"
local positionMask = 0xFFFF
local subpixelShift = 16

local actionOffset = 0xC
local facingDirectionOffset = 0x14
local xOffset = 0x2C
local yOffset = 0x30
local globalLinkAddress = 0x1160
local globalLinkActionAddress = 0x116C
local globalLinkFacingDirectionAddress = 0x1174
local globalLinkXPosAddress = 0x118C
local globalLinkYPosAddress = 0x1190

local areaIdAddress = 0xBF4
local roomIdAddress = 0xBF5

local expectedRollActionId = 0x18
local expectedFacingDirection = 0
local minXSubpixels = 0x2900
local expectedXSubpixels = 0x2D00
local maxXSubpixels = 0x4700
local expectedXCoordinate = 0x3C3
local minYSubpixels = 0x3300
local expectedYSubpixels = 0x3500
local maxYSubpixels = 0x5100
local expectedYCoordinate = 0x475
local expectedAreaId = 0x60
local expectedRoomId = 0x08

local expectedDelta = 4
local currentDelta = 0
local isInAttempt = false
local lastFrameRoomArea = { Area = 0, Room = 0 }

local shouldDisplayEngagedMessage = false
local engagedMessageDisplayFrames = 0
local engaged = false

local shouldDisplayInPositionMessage = false
local shouldDisplayWorkingWrongSubpixelsMessage = false
local shouldDisplayWrongSubpixelsMessage = false

local shouldDisplayAttemptMessage = false
local attemptMessageDisplayFrames = 0

local lastFramePositionValues = { X = 0, XSub = 0, Y = 0, YSub = 0, FacingDirection = 1, IsInPosition = false }

event.onloadstate(
	function()
		currentDelta = 0
		
		shouldDisplayInPositionMessage = false
		shouldDisplayWrongSubpixelsMessage = false
		
		shouldDisplayAttemptMessage = false
		attemptMessageDisplayFrames = 0
		
		engaged = lastFrameRoomArea["Area"] == expectedAreaId and lastFrameRoomArea["Room"] == expectedRoomId
		shouldDisplayEngagedMessage = engaged
		engagedMessageDisplayFrames = 0
		
		isInAttempt = false
	end
)

local function logical_and(value1, value2)
	return value1 & value2
end

local function right_shift(value, shift_amount)
	return value >> shift_amount
end

local function left_shift(value, shift_amount)
	return value << shift_amount
end

local function load_area_and_room()
	local area = memory.read_s8(areaIdAddress, memoryRegion)
	local room = memory.read_s8(roomIdAddress, memoryRegion)
	
	engaged = area == expectedAreaId and room == expectedRoomId
	
	if (engaged and (area ~= lastFrameRoomArea["Area"] or room ~= lastFrameRoomArea["Room"])) then
		shouldDisplayEngagedMessage = true
	end
	
	lastFrameRoomArea = {Area = area, Room = room}
end

local function load_position_data()
	local xPositionValues = memory.read_u32_le(globalLinkXPosAddress, memoryRegion)
	local yPositionValues = memory.read_u32_le(globalLinkYPosAddress, memoryRegion)
	local facingDirection = memory.read_u8(globalLinkFacingDirectionAddress, memoryRegion)
	
	local positionData = { 
		X = right_shift(xPositionValues, subpixelShift), 
		XSub = logical_and(xPositionValues, positionMask), 
		Y = right_shift(yPositionValues, subpixelShift), 
		YSub = logical_and(yPositionValues, positionMask),
		FacingDirection = facingDirection
	}
	
	positionData["IsOnPixel"] = (
		positionData["FacingDirection"] == expectedFacingDirection
		and positionData["X"] == expectedXCoordinate 
		and positionData["Y"] == expectedYCoordinate
	)
	
	positionData["IsInPosition"] = (
		positionData["IsOnPixel"]
		and positionData["XSub"] == expectedXSubpixels
		and positionData["YSub"] == expectedYSubpixels 
		and positionData["FacingDirection"] == expectedFacingDirection
	)
	
	positionData["IsInValidXSubRange"] = (
		positionData["XSub"] >= minXSubpixels 
		and positionData["XSub"] <= maxXSubpixels 
	)
	
	positionData["IsInValidYSubRange"] = (
		positionData["YSub"] >= minYSubpixels 
		and positionData["YSub"] <= maxYSubpixels 
	)
	
	positionData["IsOnWorkingSubpixel"] = (
		positionData["IsOnPixel"]
		and positionData["IsInValidXSubRange"]
		and positionData["IsInValidYSubRange"]
	)
	
	local forceDisplayFramesMessage = attemptMessageDisplayFrames > 0 and attemptMessageDisplayFrames <= 20
	
	if (not forceDisplayFramesMessage and positionData["IsInPosition"]) then
		shouldDisplayInPositionMessage = true
		currentDelta = 0
		isInAttempt = false
	elseif (not forceDisplayFramesMessage and positionData["IsOnWorkingSubpixel"]) then
		shouldDisplayWorkingWrongSubpixelsMessage = true
		currentDelta = 0
		isInAttempt = false
	elseif (not forceDisplayFramesMessage and positionData["IsOnPixel"]) then
		shouldDisplayWrongSubpixelsMessage = true
		currentDelta = 0
		isInAttempt = false
	end
	
	if (
		(lastFramePositionValues["IsInPosition"] and not positionData["IsInPosition"]) or
		(lastFramePositionValues["IsOnWorkingSubpixel"] and not positionData["IsOnWorkingSubpixel"]) or
		(lastFramePositionValues["IsOnWorkingSubpixel"] and positionData["IsOnWorkingSubpixel"] and (lastFramePositionValues["XSub"] ~= positionData["XSub"] or lastFramePositionValues["YSub"] ~= positionData["YSub"]))
	) then
		isInAttempt = true
	end
	
	lastFramePositionValues = positionData
end

local function load_action_data()
	local action = memory.read_u8(globalLinkActionAddress, memoryRegion)
	
	if (action == expectedRollActionId) then
		isInAttempt = false
		shouldDisplayAttemptMessage = true
	end
end

local function display_trainer_engaged_message() 
	engagedMessageDisplayFrames = engagedMessageDisplayFrames + 1
	
	if (engagedMessageDisplayFrames == 180) then
		shouldDisplayEngagedMessage = false
		engagedMessageDisplayFrames = 0
	end
	
	gui.text(5, 60, "Octo Clip Trainer v3 Engaged - Tool Developed by Hailey", "pink")
end

local function absolute_value(value)
	local finalValue = value
	
	if (finalValue < 0) then
		finalValue = finalValue * -1
	end
	
	return finalValue
end

local function get_frame_plural(value)
	return value > 1 and " frames" or " frame"
end

local function get_failure_text()
	local delta = expectedDelta - currentDelta
	local deltaAbs = absolute_value(delta)
	
	if (delta < 0) then
		return " (failed: you were " .. deltaAbs .. get_frame_plural(deltaAbs) .. " late)"
	end
	
	return " (failed: you were " .. deltaAbs .. get_frame_plural(deltaAbs) .. " early)"
end

local function display_attempt_message()
	attemptMessageDisplayFrames = attemptMessageDisplayFrames + 1
	
	if (attemptMessageDisplayFrames == 180 or currentDelta == 0) then
		shouldDisplayAttemptMessage = false
		attemptMessageDisplayFrames = 0
		currentDelta = 0
		return
	end
	
	local wasSuccess = currentDelta == expectedDelta
	gui.text(5, 80, "Total elapsed frames: " .. currentDelta .. (wasSuccess and " (success)" or get_failure_text()) , wasSuccess and "green" or "red")
end

local function display_in_position_message()	
	shouldDisplayInPositionMessage = false
	gui.text(5, 80, "Link is in the correct position", "orange")
end

local function display_working_wrong_subpixels_message()
	shouldDisplayWorkingWrongSubpixelsMessage = false
	gui.text(5, 80, "Link has working but incorrect subpixels", "orange")
end

local function display_wrong_subpixels_message()	
	shouldDisplayWrongSubpixelsMessage = false
	
	if (lastFramePositionValues["IsInValidXSubRange"] and not lastFramePositionValues["IsInValidYSubRange"]) then
		gui.text(5, 80, "Link has incorrect Y subpixels", "red")
	elseif (lastFramePositionValues["IsInValidYSubRange"] and not lastFramePositionValues["IsInValidXSubRange"]) then
		gui.text(5, 80, "Link has incorrect X subpixels", "red")
	else
		gui.text(5, 80, "Link has incorrect X and Y subpixels", "red")	
	end
end

while true do 
	load_area_and_room()
	
	if (engaged) then
		if (isInAttempt) then
			currentDelta = currentDelta + 1
			load_action_data()
		end
		
		load_position_data()
	end
		
	if (shouldDisplayInPositionMessage) then
		display_in_position_message()
	end
		
	if (shouldDisplayWorkingWrongSubpixelsMessage) then
		display_working_wrong_subpixels_message()
	end
	
	if (shouldDisplayWrongSubpixelsMessage) then
		display_wrong_subpixels_message()
	end
	
	if (shouldDisplayAttemptMessage) then
		display_attempt_message()
	end
	
	if (shouldDisplayEngagedMessage) then
		display_trainer_engaged_message()
	end

	emu.frameadvance()
end