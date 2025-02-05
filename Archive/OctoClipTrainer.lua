local memoryRegion = "IWRAM"

local actionOffset = 0xC
local animationOffset = 0x58
local globalLinkAddress = 0x1160
local globalLinkActionAddress = 0x116C
local globalLinkAnimationAddress = 0x11B8

local areaIdAddress = 0xBF4
local roomIdAddress = 0xBF5

local expectedRollActionId = 0x18
local expectedGrabbingAnimationIndex = 0x78
local lastFrameAnimationIndex = 0
local expectedAreaId = 0x60
local expectedRoomId = 0x08

local expectedDelta = 23
local currentDelta = 0
local isInAttempt = false
local lastFrameRoomArea = {Area = 0, Room = 0}

local shouldDisplayEngagedMessage = false
local engagedMessageDisplayFrames = 0
local engaged = false

local shouldDisplayAttemptMessage = false
local attemptMessageDisplayFrames = 0

local shouldDisplayAttemptAbortedMessage = false
local attemptAbortedMessageDisplayFrames = 0

event.onloadstate(
	function()
		currentDelta = 0
		
		shouldDisplayAttemptAbortedMessage = false
		attemptAbortedMessageDisplayFrames = 0
		
		shouldDisplayAttemptMessage = false
		attemptMessageDisplayFrames = 0
		
		engaged = astFrameRoomArea["Area"] == expectedAreaId and lastFrameRoomArea["Room"] == expectedRoomId
		shouldDisplayEngagedMessage = engaged
		engagedMessageDisplayFrames = 0
		
		isInAttempt = false
	end
)

local function load_area_and_room()
	local area = memory.read_s8(areaIdAddress, memoryRegion)
	local room = memory.read_s8(roomIdAddress, memoryRegion)
	
	engaged = area == expectedAreaId and room == expectedRoomId
	
	if (engaged and (area ~= lastFrameRoomArea["Area"] or room ~= lastFrameRoomArea["Room"])) then
		shouldDisplayEngagedMessage = true
	end
	
	lastFrameRoomArea = {Area = area, Room = room}
end

local function load_animation_data()
	local animationValue = memory.read_u8(globalLinkAnimationAddress, memoryRegion)
	
	if (animationValue == expectedGrabbingAnimationIndex) then
		isInAttempt = true
		
		if (lastFrameAnimationIndex ~= expectedGrabbingAnimationIndex) then
			currentDelta = 0
		end
	end
	
	lastFrameAnimationIndex = animationValue
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
	
	gui.text(5, 60, "Octo Trainer Engaged - Tool Developed by Hailey", "pink")
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

local function display_attempt_aborted_message()
	attemptAbortedMessageDisplayFrames = attemptAbortedMessageDisplayFrames + 1
	
	if (isInAttempt or attemptAbortedMessageDisplayFrames == 180) then
		shouldDisplayAttemptAbortedMessage = false
		attemptAbortedMessageDisplayFrames = 0 
	end
	
	gui.text(5, 60, "Attempt Aborted", "red")
end

while true do 
	load_area_and_room()
	
	if (engaged) then
		if (isInAttempt) then
			currentDelta = currentDelta + 1
			load_action_data()
		end
		
		if (currentDelta > 60) then
			shouldDisplayAttemptAbortedMessage = true
			currentDelta = 0
			isInAttempt = false
		end
		
		load_animation_data()
	end
		
	if (shouldDisplayAttemptAbortedMessage) then
		display_attempt_aborted_message()
	end
	
	if (shouldDisplayAttemptMessage) then
		display_attempt_message()
	end
	
	if (shouldDisplayEngagedMessage) then
		display_trainer_engaged_message()
	end

	emu.frameadvance()
end