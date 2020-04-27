--[[
    Copyright © 2016 Vít Listík

    https://github.com/tivvit/pure-lua-bloom-filter
--]]

local xxh32 = require("luaxxhash")
local bit = require("bit")
local BYTE_s = 8

-- mathematical round
function round(num)
    return math.floor(num + .5)
end

BloomFilter = {}
BloomFilter.__index = BloomFilter

function BloomFilter.__new(items, probability)
    assert(type(items) == "number", "items must be number")
    assert(type(probability) == "number", "probability must be number")

    assert(items > 0, "items must positive")
    assert(probability > 0 and probability < 1,
        "probability has to be between 0 and 1")

    local bits = math.ceil(items * math.log(probability) /
            math.log(1 / math.pow(2, math.log(2))));
    local hashes = round(math.log(2) * bits / items);

    local bf = {}
    setmetatable(bf, BloomFilter)

    bf.items = items
    bf.bits = bits
    bf.bytes = math.ceil(bits / BYTE_s) + 1 -- only for AS bytes
    bf.hashes = hashes
    bf.probability = probability
    bf.data = nil

    return bf
end

function BloomFilter.new(items, probability)
    local bf = BloomFilter.__new(items, probability)
    bf.data = {}
    for i = 0, bf.bytes do
        bf.data[i] = 0
    end

    return bf
end

function BloomFilter.load(store)
    -- TODO check type of data (problems with AS bytes)
    assert(type(store.items) == "number", "items must be number")
    assert(type(store.probability) == "number", "probability must be number")
    local bf = BloomFilter.__new(store.items, store.probability)
    bf.data = store.data
    return bf
end

function BloomFilter:add(val)
    assert(self.data ~= nil, "BloomFilter wasn't initilized, call new first")
    val = tostring(val)
    local added = 0

    for i = 0, self.hashes do
        local b = xxh32(val, i) % self.bits;
        -- this is only because AS bytes (it has no 0 index)
        local pos = math.floor(b / BYTE_s) + 1
        local byte = self.data[pos]
        local shift = bit.lshift(1, b % BYTE_s) 
        if not (bit.band(byte, shift) > 0) then
            self.data[pos] = bit.bor(byte, shift)
            added = 1
        end
    end

    return added
end

function BloomFilter:query(val)
    assert(self.data ~= nil, "BloomFilter wasn't initilized, call new first")
    val = tostring(val)
    local found = 1
    for i = 0, self.hashes do
        local b = xxh32(val, i) % self.bits;
        -- this is only because AS bytes (it has no 0 index)
        local pos = math.floor(b / BYTE_s) + 1
        local byte = self.data[pos]
        if not (bit.band(byte, bit.lshift(1, b % BYTE_s)) > 0) then
            return 0
        end
    end
    return found
end

function BloomFilter:clear()
    assert(self.data ~= nil, "BloomFilter wasn't initilized, call new first")
    for i = 0, self.bits do
        self.data[i] = 0
    end
end

function BloomFilter:store()
    assert(self.data ~= nil, "BloomFilter wasn't initilized, call new first")
    return {
        data = self.data,
        items = self.items,
        probability = self.probability,
    }
end

return BloomFilter
