local function set_eternal_night(surface)
  surface.daytime = 0.5              -- set to midnight (0.5)
  surface.freeze_daytime = true      -- freeze at that time
end

script.on_init(function()
  local s = game.surfaces["nauvis"]
  set_eternal_night(s)
end)

script.on_configuration_changed(function()
  local s = game.surfaces["nauvis"]
  set_eternal_night(s)
end)

script.on_event(defines.events.on_player_created, function(event)
  local s = game.surfaces["nauvis"]
  set_eternal_night(s)
end)

script.on_event(defines.events.on_cutscene_cancelled, function(event)
  local s = game.surfaces["nauvis"]
  set_eternal_night(s)
end)
