-- List of pipe/tank prototypes to ban
local banned = { "pipe", "pipe-to-ground", "storage-tank" }

for _, name in ipairs(banned) do
  -- 1. Disable placement by removing place_result
  local item = data.raw.item[name]
  if item then
    item.place_result = nil  -- no more entity to place
  end
end
