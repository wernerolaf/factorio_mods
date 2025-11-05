local empty_anim = {
  layers = {{
    filename = "__invisible-biters-challenge__/graphics/blank.png",
    width = 1, height = 1,
    frame_count = 1, direction_count = 1,
    run_mode = "forward",
    animation_speed = 1
  }}
}

local keep_attack = settings.startup["invisible-biters-keep-attack-animation"].value


local function make_invisible_unit(base_name)
  local proto_old = table.deepcopy(data.raw.unit[base_name])
  proto_old.name = proto_old.name .. "-visible"
  data:extend{proto_old}
  
  local proto = data.raw.unit[base_name]
  -- Override all required visuals with empty_anim
  proto.animation       = empty_anim
  proto.run_animation   = empty_anim
  if proto.idle_animation then
    proto.idle_animation = empty_anim
  end
  if proto.idle_animation then
    proto.idle_animation = empty_anim
  end
  if proto.dying_animation then
    proto.dying_animation = empty_anim
  end
  
  if not keep_attack and proto.attack_parameters and proto.attack_parameters.animation then
  proto.attack_parameters.animation = empty_anim
  proto.alternative_attacking_frame_sequence = nil
  end
  
    -- Prevent map blip
  proto.flags = proto.flags or {}
  table.insert(proto.flags, "not-on-map")
end

local enemies = {
  "small-biter", "small-spitter", "small-worm",
  "medium-biter","medium-spitter", "medium-worm",
  "big-biter",   "big-spitter", "big-worm",
  "behemoth-biter","behemoth-spitter", "behemoth-worm"
}
for _, name in ipairs(enemies) do
  if data.raw.unit[name] then
    make_invisible_unit(name)
  end
end

--for name, prototype in pairs(data.raw.unit) do
--  if prototype.attack_parameters and prototype.subgroup == "enemies" then
--    make_invisible_unit(name)
--  end
--end
