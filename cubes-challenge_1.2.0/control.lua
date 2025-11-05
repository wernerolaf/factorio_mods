local cubes = settings.startup["cubes-start"].value or 1

local function give_starter_items(player)
  player.insert{name="super-module", count=cubes}
end

script.on_init(function(event)
  for _, player in pairs(game.players) do
    give_starter_items(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  give_starter_items(game.players[event.player_index])
end)

script.on_event(defines.events.on_cutscene_cancelled, function(event)
   give_starter_items(game.players[event.player_index])
end)


-- control.lua

local function world_item_count(item_name)
  local total = 0

  -- 0) Player inventories
  for _, player in pairs(game.connected_players) do
    total = total + player.get_item_count(item_name)
  end

  -- (Optional) Logistic network
  local force = game.forces.player
  for _, networks in pairs(force.logistic_networks) do
    for _, network in pairs(networks) do
      total = total + network.get_item_count{ name = item_name }
    end
  end

  -- 1) Items on the ground
  for _, surface in pairs(game.surfaces) do
    for _, dropped in pairs(surface.find_entities_filtered{ type = "item-entity" }) do
      local stack = dropped.stack
      if stack.valid_for_read and stack.name == item_name then
        total = total + stack.count
      end
    end

    -- 2) All inventories on containers/vehicles
    local inv_ents = surface.find_entities_filtered{
      type = { "container", "logistic-container", "car", "cargo-wagon", "spider-vehicle" }
    }
    for _, ent in pairs(inv_ents) do
      for _, inv_id in pairs(defines.inventory) do
        local inv = ent.get_inventory(inv_id)
        if inv and inv.valid then
          total = total + inv.get_item_count(item_name)
        end
      end
    end

    -- 3) Module slots
    local machines = surface.find_entities_filtered{
      type = { "assembling-machine", "furnace", "lab", "beacon", "rocket-silo" }
    }
    for _, m in pairs(machines) do
      local mod_inv = m.get_module_inventory()
      if mod_inv and mod_inv.valid then
        total = total + mod_inv.get_item_count(item_name)
      end
    end

    -- 4) Belts & splitters
    local belts = surface.find_entities_filtered{
      type = { "transport-belt", "underground-belt", "splitter" }
    }
    for _, belt in pairs(belts) do
      for lane = 1, 2 do
        local line = belt.get_transport_line(lane)
        if line and line.valid and line.get_item_count then
          total = total + line.get_item_count(item_name)
        end
      end
    end
  end

  return total
end



local function purge_excess(item_name, excess)
  -- 1) From players
  for _, player in pairs(game.connected_players) do
    if excess <= 0 then return 0 end
    excess = excess - player.remove_item{ name = item_name, count = excess }
  end

  -- 2) From all container‑style inventories
  for _, surface in pairs(game.surfaces) do
    if excess <= 0 then return 0 end
    local inv_ents = surface.find_entities_filtered{
      type = { "container", "logistic-container", "car", "cargo-wagon", "spider-vehicle" }
    }
    for _, ent in pairs(inv_ents) do
      if excess <= 0 then return 0 end
      -- iterate numeric inventory IDs
      for _, inv_id in pairs(defines.inventory) do
        if excess <= 0 then break end
        local inv = ent.get_inventory(inv_id)
        if inv and inv.valid then
          excess = excess - inv.remove{ name = item_name, count = excess }
        end
      end
    end
  end

  -- 3) From module slots
  for _, surface in pairs(game.surfaces) do
    if excess <= 0 then return 0 end
    local machines = surface.find_entities_filtered{
      type = { "assembling-machine", "furnace", "lab", "beacon", "rocket-silo" }
    }
    for _, m in pairs(machines) do
      if excess <= 0 then return 0 end
      local mod_inv = m.get_module_inventory()
      if mod_inv and mod_inv.valid then
        excess = excess - mod_inv.remove{ name = item_name, count = excess }
      end
    end
  end

  -- 4) From belts, underground belts, splitters
  for _, surface in pairs(game.surfaces) do
    if excess <= 0 then return 0 end
    local belts = surface.find_entities_filtered{
      type = { "transport-belt", "underground-belt", "splitter" }
    }
    for _, belt in pairs(belts) do
      if excess <= 0 then return 0 end
      for lane = 1, 2 do
        local line = belt.get_transport_line(lane)
        if line and line.valid and line.remove_item then
          excess = excess - line.remove_item{ name = item_name, count = excess }
          if excess <= 0 then return 0 end
        end
      end
    end
  end

  return excess  -- any leftovers
end

local function do_resummon(player_index)
  local player = game.players[player_index]
  if not (player and player.valid) then return end

  local target  = cubes
  if target <= 0 then return end

  local item    = "super-module"
  local current = world_item_count(item)

  if current < target then
    player.insert{ name = item, count = target - current }
  elseif current > target then
    purge_excess(item, current - target)
  end
end


-- when player joins, add a button to their top GUI
script.on_event(defines.events.on_player_created, function(e)
  local p = game.players[e.player_index]
  p.gui.top.add{
    type = "sprite-button",
    name = "resummon_cubes_btn",
    sprite = "cubium-gui-icon",  -- or your cubium icon
    tooltip = {"gui.resummon-cubes-button"}
  }
end)

-- handle the button click
script.on_event("resummon-cubes-hotkey", function(e)
  do_resummon(e.player_index)
end)

script.on_event(defines.events.on_gui_click, function(e)
  if e.element.name ~= "resummon_cubes_btn" then return end
  do_resummon(e.player_index)
end)
