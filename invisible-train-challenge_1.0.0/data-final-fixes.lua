-- data-final-fixes.lua
-- Invisible Train Challenge: remove all rolling‑stock visuals, including wheels

-- Helper to nil out specified fields on a table
local function clear_fields(tbl, fields)
  if type(tbl) ~= "table" then return end
  for _, f in ipairs(fields) do
    tbl[f] = nil
  end
end

-- Fields to remove from locomotive & wagon prototypes
local proto_fields = {
  "pictures",                    -- legacy flat/curved sprites
  "graphics_set",                -- 2.0+ unified graphics_set
  "working_visualisations",      -- smoke, sparks, etc.
  "animation",                   -- in graphics_set
  "back_light", "front_light",   -- lights
  "stand_by_light", "gui_light", "player_light",
  --"minimap_representation",      -- minimap icon
  --"selected_minimap_representation"
}

-- Clear out locomotives
for _, loco in pairs(data.raw["locomotive"]) do
  -- 1) Remove every body, light, effect and minimap field
  clear_fields(loco, proto_fields)

  -- 2) Remove wheels entirely
  loco.wheels = nil
end

-- Clear out cargo wagons
for _, wagon in pairs(data.raw["cargo-wagon"]) do
  -- 1) Remove every body, light, effect and minimap field
  clear_fields(wagon, proto_fields)

  -- 2) Remove wheels entirely
  wagon.wheels = nil
end

for _, wagon in pairs(data.raw["fluid-wagon"]) do
  -- 1) Remove every body, light, effect and minimap field
  clear_fields(wagon, proto_fields)

  -- 2) Remove wheels entirely
  wagon.wheels = nil
end

for _, wagon in pairs(data.raw["artillery-wagon"]) do
  -- 1) Remove every body, light, effect and minimap field
  clear_fields(wagon, proto_fields)

  -- 2) Remove wheels entirely
  wagon.wheels = nil
end

-- Remove turret graphics from all artillery wagons
for _, wagon in pairs(data.raw["artillery-wagon"]) do
  clear_fields(wagon, {
    "turret_animation_set",            -- the in‑vehicle turret visuals
    "cannon_barrel_pictures",          -- barrel sprite
    "cannon_barrel_shadow_pictures",   -- barrel shadow
    "cannon_base_pictures",            -- base sprite
    "cannon_base_shadow_pictures",     -- base shadow
    "cannon_aux_pictures",             -- any auxiliaries
    "cannon_aux_shadow_pictures"
  })
end
