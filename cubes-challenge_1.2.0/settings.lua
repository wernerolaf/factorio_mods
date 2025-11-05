-- settings.lua
data:extend({
  {
    type = "int-setting",
    name = "cubes-start",
    setting_type = "startup",
    default_value = 8,
    minimum_value = 1,
    order = "a"
  }
})

data:extend({
  {
    type = "int-setting",
    name = "cubes-multiplier",
    setting_type = "startup",
    default_value = 8,
    minimum_value = 1,
    order = "a"
  }
})
