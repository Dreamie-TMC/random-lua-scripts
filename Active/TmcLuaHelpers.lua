TmcLuaHelpers = { 
	rng = 0x1234567, rng_domain = "IWRAM", rng_address = 0x1150, 
	area_address = 0xBf4, area_domain = "IWRAM", 
	room_address = 0xBF5, room_domain = "IWRAM" 
}

function TmcLuaHelpers:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TmcLuaHelpers:logical_and(number, addend)
	return number & addend
end

function TmcLuaHelpers:logical_or(number, or_value)
	return number | or_value
end

function TmcLuaHelpers:logical_left_shift(number, shift_amount)
	return number << shift_amount
end

function TmcLuaHelpers:logical_right_shift(number, shift_amount)
	return number >> shift_amount
end

function TmcLuaHelpers:rotate_right_32(number, rotate_amount)
	local rotated = bit.ror(number, rotate_amount)
	return self:logical_and(rotated, 0xFFFFFFFF)
end

function TmcLuaHelpers:rng_last_value()
	return self.rng
end

function TmcLuaHelpers:rng_next()
	local temp = self:logical_and(self.rng * 3, 0xFFFFFFFF)
	temp = self:rotate_right_32(temp, 13)
	self.rng = temp
	return self:logical_right_shift(self.rng, 1)
end

function TmcLuaHelpers:rng_next_by_weights(weights)
	local rand = self:rng_next()
	rand = self:logical_and(rand, 0xFF)
	local i = 0
	
	repeat
		local weight = weights[i]
		i = i + 1
		rand = rand - weight
	until rand < 0
	
	return i - 1
end

function TmcLuaHelpers:set_rng(value)
	self.rng = self:logical_and(value, 0xFFFFFFFF)
end

function TmcLuaHelpers:reset_rng()
	self.rng = memory.read_u32_le(self.rng_address, self.rng_domain)
end

function TmcLuaHelpers:load_area_and_room()
	return { area = memory.read_u8(self.area_address, self.area_domain), room = memory.read_u8(self.room_address, self.room_domain) }
end