require("TmcLuaHelpers")

local helper = TmcLuaHelpers:new(nil)

local octoWholeAddress = 0x03001738
local octoWholeTypeOffset = 0xA
local octoActionOffset = 0xC
local octoSubactionOffset = 0xD
local octoAttackWaitTurnsOffset = 0x78
local octoBossPhaseOffset = 0x7C
local octoPhase4AttackOffset = 0x81
local octoBossHeapPointerOffset = 0x84
local previousPhase4AttackOffset = 0x5

local bigOctoAreaId = 0x60
local bigOctoRoomId = 0xE
local lastAreaAndRoom = { area = 0, room = 0 }
local areaAndRoom = {}

local weights = {}
weights[0] = 64
weights[1] = 128
weights[2] = 64

local walks = {}
walks[0] = 1
walks[1] = 2
walks[2] = 3

--rng stops on action 2 subaction 2, but that's also the frame the boss moves to phase 4, so we're fine

local engagedMessageDisplayFrames = 0
local shouldDisplayEngagedMessage = false

local function display_trainer_engaged_message() 
	engagedMessageDisplayFrames = engagedMessageDisplayFrames + 1
	
	if (engagedMessageDisplayFrames == 180) then
		shouldDisplayEngagedMessage = false
		engagedMessageDisplayFrames = 0
	end
	
	gui.text(5, 60, "Octo Manip Trainer Engaged - Tool Developed by Hailey", "pink")
end

local function should_engage_trainer()
	shouldDisplayEngagedMessage = lastAreaAndRoom["area"] ~= bigOctoAreaId or areaAndRoom["room"] ~= bigOctoRoomId
end

local function compute_rolls_for_good_rng()
	--This currently hangs bizhawk btw
	helper:reset_rng()
	
	local totalTargetsToGet = 4
	
	local rollCounts = {}
	local i = 0
	local setRng = helper:rng_last_value()
	local rolls = 0
	
	while (i < totalTargetsToGet) do
		helper:set_rng(setRng)
		local total_walks = walks[helper:rng_next_by_weights(weights)]
		-- console.log("Total walks: " .. total_walks)
		setRng = helper:rng_last_value()
		
		local j = 0
		while (j < total_walks) do
			j = j + 1
			helper:rng_next()
		end
		
		local rng = helper:rng_next()
		
		-- console.log("Is rock bash: " .. (rng % 4))
		if (rng % 4 ~= 0) then
			rng = helper:rng_next()
			
			if (rng % 4 == 2) then
				rollCounts[i] = rolls
				i = i + 1
			end
		end
		
		rolls = rolls + 1
	end
	
	gui.text(5, 80, "Rolls to get 0 ink (displaying first 4): [" .. rollCounts[0] .. ", " .. rollCounts[1] .. ", " .. rollCounts[2] .. ", " .. rollCounts[3] .. "]", "lime")
end

local function compute_rolls_for_good_rng_during_walking(walks_remaining)
	helper:reset_rng()
	
	local setRng = helper:rng_last_value()
	local rolls = 0
	
	while (true) do
		helper:set_rng(setRng)
		local rng = helper:rng_next()
		setRng = helper:rng_last_value()
		local i = 1
		
		while (i < walks_remaining) do
			rng = helper:rng_next()
			i = i + 1
		end
		
		if (rng % 4 ~= 0) then
			rng = helper:rng_next()
			
			if (rng % 4 == 2) then
				-- console.log(string.format("0x%08X", rng))
				if (rolls == 0) then
					gui.text(5, 80, "Do nothing for 0 ink!", "lime")				
				else
					gui.text(5, 80, "You must do " .. rolls .. " rolls for 0 ink before octo stops moving", "lime")
				end
				
				break
			end
			
		end
		
		rolls = rolls + 1
	end
end

local function display_octo_pattern(attackPattern)
	if (attackPattern == 0) then
		gui.text(5, 80, "You are getting a 2 rock into an ink", "yellow")
	elseif (attackPattern == 1) then
		gui.text(5, 80, "You are getting an ink =(", "red")
	elseif (attackPattern == 2) then
		gui.text(5, 80, "You got 0 ink! =D", "lime")
	end
		
end

while true do
	areaAndRoom = helper:load_area_and_room()
	
	if (areaAndRoom["area"] == bigOctoAreaId and areaAndRoom["room"] == bigOctoRoomId) then
		if (shouldDisplayEngagedMessage) then
			display_trainer_engaged_message()
		else
			should_engage_trainer()
		end
		
		local octoType = memory.read_u8(octoWholeAddress + octoWholeTypeOffset)
		if (octoType == 0) then
			local phase = memory.read_u8(octoWholeAddress + octoBossPhaseOffset)
			
			if (phase == 4) then
				local waitTurns = memory.read_u8(octoWholeAddress + octoAttackWaitTurnsOffset)
				local action = memory.read_u8(octoWholeAddress + octoActionOffset)
				local subAction = memory.read_u8(octoWholeAddress + octoSubactionOffset)
				local phase4AttackPattern = memory.read_u8(octoWholeAddress + octoPhase4AttackOffset)
				
				if (waitTurns == 0 and action == 2 and (subAction == 2 or subAction == 3)) then
					compute_rolls_for_good_rng()
				elseif (action == 1 and (subAction == 1 or subAction == 2) and phase4AttackPattern == 0xFF) then
					compute_rolls_for_good_rng_during_walking(waitTurns + subAction - 1)
				elseif (phase4AttackPattern ~= 0xFF) then
					display_octo_pattern(phase4AttackPattern)
				end
			end
		else
			gui.text(5, 80, "Could not find required octo boss entity!", "red")
		end
	end
	
	lastAreaAndRoom = areaAndRoom
	
	emu.frameadvance()
end