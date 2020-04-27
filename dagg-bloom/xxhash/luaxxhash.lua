--[[
	Copyright (C) 2014 szensk.

	https://github.com/szensk/luaxxhash/
--]]

local ffi = require('ffi')
local bit = require('bit')
local rotl, xor, band, shl, shr = bit.rol, bit.bxor, bit.band, bit.lshift, bit.rshift

local u32type = ffi.typeof("uint32_t")
local P1 = (2654435761)
local P2 = (2246822519)
local P3 = (3266489917)
local P4 = (668265263)
local P5 = (374761393)
local U1 = u32type(P1)
local U2 = u32type(P2)

local function mmul(x1, x2) --multiplication with modulo2 semantics
	return tonumber(ffi.cast('uint32_t', ffi.cast('uint32_t', x1) * ffi.cast('uint32_t', x2)))
end

local function xxhash32(data, seed, len)
	seed = seed or 0
	len = len or #data
	local p = ffi.cast("const uint8_t*", data)
	data = ffi.cast('const uint32_t*', data)
	local h32 = 0
	local i = 0 -- byte index
	local n = 0 -- 4 byte index
	if len >= 16 then
		local limit = len - 16
		local v = ffi.new("uint32_t[4]")
		v[0], v[1] = seed + U1 + U2, seed + U2
		v[2], v[3] = seed, seed - U1
		while i <= limit do 
			for j=0, 3 do
				v[j] = v[j] + data[n] * U2; 
				v[j] = rotl(v[j], 13); v[j] = v[j] * U1
				i = i + 4; n = n + 1
			end
		end
		h32 = rotl(v[0], 1) + rotl(v[1], 7) + rotl(v[2], 12) + rotl(v[3], 18)
	else
		h32 = seed + P5
	end
	h32 = h32 + len

	local limit = len - 4
	while i <= limit do
		h32 = (h32 + mmul(data[n], P3))
		h32 = mmul(rotl(h32, 17), P4)
		i = i + 4; n = n + 1
	end

	while i < len do
		h32 = h32 + mmul(p[i], P5)
		h32 = mmul(rotl(h32, 11), P1)
		i = i + 1
	end

	h32 = xor(h32, shr(h32, 15))
	h32 = mmul(h32, P2)
	h32 = xor(h32, shr(h32, 13))
	h32 = mmul(h32, P3)
	h32 = xor(h32, shr(h32, 16))
	return h32
end

return xxhash32
