local VISIBLE = "visible-enemies"
local PLAYER = "player"
local ENEMY   = "enemy"
local REVEAL_RADIUS = 128


local function swap_to_visible(unit)
  if not (unit and unit.valid) then return end

  -- Derive the “visible” name by stripping your suffix
  local visible_name = unit.name .. "-visible"
  
if not prototypes.entity[visible_name] then
  return unit
  -- prototype doesn’t exist
end
  -- Remember the unit’s state
  local pos       = unit.position
  local dir       = unit.direction
  local health    = unit.health
  local force     = unit.force
  local surface   = unit.surface
  local unit_number = unit.unit_number

  -- Destroy the invisible unit
  unit.destroy()

  -- Create the new visible unit
  local new_unit = surface.create_entity({
    name      = visible_name,
    position  = pos,
    direction = dir,
    force     = force,
    raise_built = true,    -- triggers on_built events if you need them
  })

  if new_unit then
    new_unit.health = health
    -- Optionally copy over other properties, tags, etc.
  end

  return new_unit
end

local function setup_forces()
  if not game.forces[VISIBLE] then
    game.create_force(VISIBLE)
  end
  -- Player should ignore invisible enemies (enemy force) by default
  game.forces[PLAYER].set_cease_fire(ENEMY, true)
  -- Player attacks visible enemies
  game.forces[PLAYER].set_cease_fire(VISIBLE, false)
  -- Enemy (biters) treats visible enemies as friends
  game.forces[ENEMY].set_cease_fire(VISIBLE, true)
  game.forces[VISIBLE].set_cease_fire(ENEMY, true)
  -- And visible enemies fight the player
  game.forces[VISIBLE].set_cease_fire(PLAYER, false)
end

script.on_init(setup_forces)
script.on_configuration_changed(setup_forces)


local function reveal_nearby(radar)
  local surface = radar.surface
  local pos     = radar.position
  local radius  = REVEAL_RADIUS
  -- Find invisible units within radius
  for _, unit in pairs(surface.find_entities_filtered{
      position = pos,
      force = "enemy",
      radius=radius
    }) do
      unit.force = game.forces[VISIBLE]
      local new_unit = swap_to_visible(unit)
      --game.print(string.format(
      --  "[InvisibleEnemies] Revealed %s at (%.1f, %.1f)",
      --  unit.name, unit.position.x, unit.position.y))
      -- Optional: create a reveal animation or flying-text
      -- surface.create_particle{...}
    
  end
end

script.on_event(defines.events.on_sector_scanned, function(event)
  if event.radar and event.radar.valid and event.radar.name == "radar-mk2" then
    reveal_nearby(event.radar)
  end
end)


local function get_spawn_position(player)
  -- If the player is in a vehicle, use that position; otherwise use the character’s
  if player.vehicle and player.vehicle.valid then
    return player.vehicle.position
  elseif player.character and player.character.valid then
    return player.character.position
  else
    -- Fallback to player.surface’s center—or any default
    return {x = 0, y = 0}
  end
end

local function spawn_tutorial_biters(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local surface = player.surface
  local pos     = get_spawn_position(player)
  local force   = game.forces.enemy

  local offsets = {
    {x =  0.5, y =  0},
    {x = -0.5, y =  0},
    {x =  0, y =  0.5},
    {x =  0, y = -0.5},
  }

  for _, off in ipairs(offsets) do
    local spawn_pos = {pos.x + off.x, pos.y + off.y}
    -- ensure we’re not spawning inside walls or water
    local safe_pos = surface.find_non_colliding_position("small-biter", spawn_pos, 5, 1)
                      or spawn_pos
    surface.create_entity{
      name        = "small-biter",
      position    = safe_pos,
      force       = force,
      raise_built = true,
    }
    --player.print(string.format(
    --  "[color=yellow]Debug:[/color] Spawned small-biter at (%.1f, %.1f)",
    --  safe_pos.x, safe_pos.y
    --))
  end
end

-- Register the event
script.on_event(defines.events.on_player_created, spawn_tutorial_biters)
