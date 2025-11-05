-- Read your mod settings (still from settings.global)
local threshold      = settings.global["devour-pollution-threshold"].value
local active_ticks   = settings.global["devour-active-duration"].value
local cooldown_ticks = settings.global["devour-cooldown-duration"].value
local half_threshold = threshold * 0.5
local warned = false

-- Safe initialization in on_init
local function init()
  storage = storage or {}               -- Create storage if it doesn't exist
  storage.devour = {
    entity = nil,
    despawn_tick = nil,
    next_allowed_tick = 0
  }
  storage.watched_chunks = {}
end
script.on_init(init)                    

-- Reset on mod update
script.on_configuration_changed(function(data)
  if data.mod_changes and data.mod_changes["pollution-summon-challenge"] then
    init()
  end
end)

-- Track newly generated chunks
script.on_event(defines.events.on_chunk_generated, function(e)
  table.insert(storage.watched_chunks, { x = e.position.x, y = e.position.y })
end)

-- Spawn helper
local function spawn_devour(surface, position, tick)

  local e = surface.create_entity{
    name = "devour-of-spaghetti",
    position = position,
    force = "enemy"
  }
  storage.devour.entity            = e
  storage.devour.despawn_tick      = tick + active_ticks
  storage.devour.next_allowed_tick = tick + active_ticks + cooldown_ticks
end

-- Main loop: every second
script.on_nth_tick(60, function(ev)
  local tick, surface = ev.tick, game.surfaces["nauvis"]

  -- Despawn logic
  if storage.devour.entity then
    if not storage.devour.entity.valid or tick >= storage.devour.despawn_tick then
      if storage.devour.entity.valid then
        storage.devour.entity.destroy()
      end

      -- Calculate cooldown in seconds
      local ticks_left   = storage.devour.next_allowed_tick - tick
      local seconds_left = math.floor(ticks_left / 60)

      -- Notify players
      game.print(
        string.format(
          "[color=yellow]The Devour of Spaghetti has retreated and will sleep for %d seconds.[/color]",
          seconds_left
        )
      )

      -- Clear the entity so it can respawn later
      storage.devour.entity       = nil
      storage.devour.despawn_tick = nil
    end
  end

  -- Spawn logic
  if not storage.devour.entity and tick >= storage.devour.next_allowed_tick then
    for i, chunk in ipairs(storage.watched_chunks) do
      local pos = { x = chunk.x * 32 + 16, y = chunk.y * 32 + 16 }
      local pollution = surface.get_pollution(pos)

      -- Actual spawn
      if pollution >= threshold then
        spawn_devour(surface, pos, tick)

        -- Reset warning flag for next life
        warned = false

        -- Tell players it’s active
        local active_seconds = math.floor(active_ticks / 60)
        game.print(
          string.format(
            "[color=yellow]The Devour of Spaghetti has been summoned and will attack for %d seconds.[/color]",
            active_seconds
          )
        )

        break
      end

      -- Halfway warning
      if not warned and pollution >= half_threshold then
        game.print(
          string.format(
            "[color=orange]Warning:[/color] Chunk (%d,%d) is halfway to summoning the Devour!",
            chunk.x, chunk.y
          )
        )
        warned = true
      end
    end
  end
end)
