-- settings.lua

data:extend({
  {
    type = "int-setting",
    name = "rng-seed",
    setting_type = "startup",
    default_value = 12345,
    minimum_value = 0,
    maximum_value = 2147483647,
    description = "Seed for recipe randomization (deterministic)"
  }
})

data:extend({
  {
    type = "int-setting",
    name = "variants-num",
    setting_type = "startup",
    default_value = 3,
    minimum_value = 0,
    maximum_value = 8,  
    per_user = false,
    description = "Number of variants to generate"
  }
})

data:extend({
  {
    type = "int-setting",
    name = "ingredients-num",
    setting_type = "startup",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 9,
    description = "Number of extra ingredients to add to recipes"
  }
})

data:extend({
  {
    type = "int-setting",
    name = "base-multiplier",
    setting_type = "startup",
    default_value = 8,
    minimum_value = 1,
    maximum_value = 99,
    description = "Multiplier to base recipe costs"
  }
})

data:extend({
  {
    type = "int-setting",
    name = "seconds-randomize",
    setting_type = "startup",
    default_value = 300,
    minimum_value = 10,
    maximum_value = 3600,
    description = "Time in seconds to randomize recipes"
  }
})


