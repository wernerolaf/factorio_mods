data:extend({
  {
    type = "double-setting",
    name = "devour-pollution-threshold",
    setting_type = "runtime-global",
    default_value = 500.0,
    minimum_value = 0.0,
    order = "a"
  },
  {
    type = "int-setting",
    name = "devour-active-duration",
    setting_type = "runtime-global",
    default_value = 3600,        -- ticks (60 seconds)
    minimum_value = 1,
    order = "b",
    description = {"", "How many ticks the Devour of Spaghetti remains alive before despawning."}
  },
  {
    type = "int-setting",
    name = "devour-cooldown-duration",
    setting_type = "runtime-global",
    default_value = 3600,        -- ticks (60 seconds)
    minimum_value = 0,
    order = "c",
    description = {"", "How many ticks after despawn before it can be summoned again."}
  }
})

data:extend({
  {
    type = "string-setting",
    name = "pollution-summon-enemy-type",
    setting_type = "startup",
    default_value = "big-demolisher",
    allowed_values = { "behemoth-biter", "big-demolisher" },
    localised_name = { "", "[entity-name]", "pollution-summon-enemy-type" },
    order = "a"
  }
})
