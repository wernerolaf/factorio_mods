-- settings.lua
data:extend({
  {
    type = "int-setting",
    name = "worm-range-multiplier",
    setting_type = "startup",
    default_value = 4,
    minimum_value = 1,
    maximum_value = 10,
    order = "a"
  }
})
