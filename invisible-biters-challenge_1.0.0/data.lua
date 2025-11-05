local function parse_energy(energy_str)
  local value, unit = string.match(energy_str, "([%d%.]+)(%a+)")
  return tonumber(value), unit
end

-- Formats a numeric value and unit back into an energy string
local function format_energy(value, unit)
  -- Remove trailing decimal if integer
  if math.floor(value) == value then
    value = math.floor(value)
  end
  return tostring(value) .. unit
end

-- Multiplies a given energy string by factor, returns new string
local function multiply_energy(energy_str, factor)
  local v, u = parse_energy(energy_str)
  return format_energy(v * factor, u)
end


local energy_usage_factor = 30
local energy_per_sector_factor = 2

---------------------------------
-- Radar changes
---------------------------------
radar = data.raw.radar["radar"]
radar.fast_replaceable_group = "radar"
radar.next_upgrade = "radar-mk2"

base_rotation_speed = radar.rotation_speed
radar.rotation_speed = base_rotation_speed * 0.75

---------------------------------
-- Radar MK2
---------------------------------
radarmk2 = table.deepcopy(radar)
radarmk2.name = "radar-mk2"
radarmk2.localised_name = { "", {"entity-name.radar"}, " MK2" }
--radarmk2.localised_description = { "entity-description.radar" }
radarmk2.minable.result = "radar-mk2"
radarmk2.fast_replaceable_group = "radar"
radarmk2.corpse = "radar-mk2-remnants"

radarmk2.max_health = radarmk2.max_health * 2
radarmk2.energy_usage = multiply_energy(radarmk2.energy_usage, energy_usage_factor)
radarmk2.energy_per_sector = multiply_energy(radarmk2.energy_per_sector, energy_per_sector_factor)
radarmk2.energy_per_nearby_scan = multiply_energy(radarmk2.energy_per_nearby_scan, energy_per_sector_factor)
--radarmk2.max_distance_of_nearby_sector_revealed = radarmk2.max_distance_of_nearby_sector_revealed * 2
--radarmk2.max_distance_of_sector_revealed = radarmk2.max_distance_of_sector_revealed * 2
radarmk2.rotation_speed = base_rotation_speed * 1.25


-- new textures
radarmk2.pictures.layers[1].filename = "__invisible-biters-challenge__/graphics/entity/radar-mk2/hr-radar-mk2.png"

data:extend({ radarmk2 })


---------------------------------
-- Radar MK2 remnants
---------------------------------
radarmk2_remnants = table.deepcopy(data.raw.corpse["radar-remnants"])
radarmk2_remnants.name = "radar-mk2-remnants"

-- new textures
radarmk2_remnants.animation[1].filename = "__invisible-biters-challenge__/graphics/entity/radar-mk2/remnants/hr-radar-mk2-remnants.png"

data:extend({ radarmk2_remnants })


radar_mk2_item = 
{
	type = "item",
	name = "radar-mk2",
	icon = "__invisible-biters-challenge__/graphics/icons/radar-mk2.png",
	icon_size = 256,
	localised_name = { "", {"entity-name.radar"}, " MK2" },
	localised_description = { "entity-description.radar" },
	order = "d[radar]-b[radar-mk2]",
	place_result = "radar-mk2",
	stack_size = 50,
	subgroup = "defensive-structure"
}
data:extend({ radar_mk2_item })

radar_mk2_recipe =
{
	type = "recipe",
	name = "radar-mk2",
	enabled = true,
	energy_required = 5,
	ingredients =
	{
		{type="item", name="radar", amount=5}
	},
	results = {{type="item", name="radar-mk2", amount=1}}
}
data:extend({ radar_mk2_recipe })
