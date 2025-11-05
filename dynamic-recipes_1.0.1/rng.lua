-- rng.lua

local rng = {}
rng.__index = rng

-- Create a new RNG with given integer seed
function rng.new(seed)
  local self = setmetatable({}, rng)
  -- Use a 32-bit or 64-bit state; here we pick 64-bit (but using Lua number)
  self.state = seed or 1
  return self
end

-- Example LCG parameters (these are from glibc or similar; you can choose others)
-- state = (a * state + c) mod m
-- For example:
local A = 1664525
local C = 1013904223
local M_MOD = 2^32  -- modulus (wrap around 32 bits)

function rng:next()
  -- update internal state
  self.state = (A * self.state + C) % M_MOD
  return self.state
end

-- Returns integer in [lo, hi] (inclusive)
function rng:rand_int(lo, hi)
  local r = self:next()
  -- scale it down into the interval
  local range = hi - lo + 1
  -- use modulo bias; it's okay for many uses
  local v = lo + (r % range)
  return v
end

-- Returns a float in [0, 1)
function rng:rand()
  local r = self:next()
  return r / M_MOD
end

-- Choose a random element from an array-like table
function rng:choice(tbl)
  local n = #tbl
  if n == 0 then return nil end
  local idx = self:rand_int(1, n)
  return tbl[idx]
end

-- A convenience: random float between lo and hi
function rng:rand_real(lo, hi)
  return lo + (hi - lo) * self:rand()
end

return rng

