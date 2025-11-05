local enemy_name = settings.startup["pollution-summon-enemy-type"].value
local prototype   -- will hold the one we find

-- 1) Try segmented-unit (DLC boss)
if data.raw["segmented-unit"] and data.raw["segmented-unit"][enemy_name] then
  prototype = data.raw["segmented-unit"][enemy_name]

-- 2) Fallback to classic unit of the same name
elseif data.raw["unit"] and data.raw["unit"][enemy_name] then
  prototype = data.raw["unit"][enemy_name]

-- 3) Final fallback to behemoth-biter
elseif data.raw["unit"] and data.raw["unit"]["behemoth-biter"] then
  prototype = data.raw["unit"]["behemoth-biter"]
end

-- If we found something, clone it once
if prototype then
  local devour_unit = table.deepcopy(prototype)
  devour_unit.name = "devour-of-spaghetti"
  data:extend({ devour_unit })
else
  error("No valid prototype found for '" .. enemy_name .. "', and behemoth-biter is missing too.")
end
