-- control.lua

local SECONDS = settings.startup["seconds-randomize"].value or 300

-- Ticks between randomizing variant per base
local RANDOM_INTERVAL = 60 * SECONDS  
-- Ticks between scanning / override logic
local SCAN_INTERVAL = 30

-- Base → variant recipes mapping
--local variant_mapping = {
--  ["iron-gear-wheel"] = { "iron-gear-wheel-variant-1", "iron-gear-wheel-variant-2" },
--  ["electronic-circuit"] = { "electronic-circuit-variant-1", "electronic-circuit-variant-2" },}

local variant_mapping = {}
local recipe_to_base = {}

local function build_variant_mapping()
  variant_mapping = {}
  recipe_to_base = {}
  for name, recipe_proto in pairs(prototypes.get_recipe_filtered{}) do
    if string.find(name, "%-variant%-") then
      local base = name:match("^(.*)%-variant%-%d+$")
      if base then
        variant_mapping[base] = variant_mapping[base] or {}
        table.insert(variant_mapping[base], name)
        recipe_to_base[name] = base
      end
    end
  end
end


-- Persistent storage setup
local function init_storage()
  if storage.active_variant == nil then
    storage.active_variant = {}
  end
  if storage.pending_switch == nil then
    storage.pending_switch = {}
  end
end

-- Enable a variant globally (for all forces)
local function enable_variant_globally(vname)
  for _, f in pairs(game.forces) do
    local rec = f.recipes[vname]
    if rec and f.recipes[recipe_to_base[vname]].enabled then
      rec.enabled = true
    end
  end
end

-- Disable a variant globally
local function disable_variant_globally(vname)
  for _, f in pairs(game.forces) do
    local rec = f.recipes[vname]
    if rec then
      rec.enabled = false
    end
  end
end

-- Activate one variant for a base
local function activate_variant_for_base(base, variant_name)
  local variants = variant_mapping[base]
  if not variants then return end
  for _, v in ipairs(variants) do
    disable_variant_globally(v)
  end
  enable_variant_globally(variant_name)
end

-- Randomize one base
local function randomize_for_base(base)
  local variants = variant_mapping[base]
  if not variants or #variants == 0 then return end
  local choice = variants[math.random(#variants)]
  storage.active_variant[base] = choice
  activate_variant_for_base(base, choice)
  --for _, player in pairs(game.connected_players) do
  --  player.print("[Randomizer] Base “" .. base .. "” → variant: " .. choice)
  --end
end

-- Randomize all bases
local function randomize_all()
  for base, _ in pairs(variant_mapping) do
    randomize_for_base(base)
  end
end

-- Guard: check if an entity is an assembling machine
local function is_assembling_machine(entity)
  if not entity or not entity.valid then
    return false
  end
  local proto = entity.prototype
  if proto and proto.type == "assembling-machine" then
    return true
  end
  return false
end

-- Try to reset the recipe of an assembler (clear it) if safe
-- Returns (success:boolean, reason:string)
local function attempt_reset(entity)
  if not is_assembling_machine(entity) then
    return false, "not an assembling-machine"
  end
  local cur = entity.get_recipe()
  if not cur then
    return true, "no recipe to reset"
  end
  --if entity.is_crafting() then
  --  return false, "is crafting"
  --end
  local output = entity.get_output_inventory()
  if output and not output.is_empty() then
    return false, "output inventory not empty"
  end

  -- Okay to clear
  entity.set_recipe(nil)
  return true, "reset succeeded"
end

-- Determine which variant the assembler should run
local function get_desired_variant(entity)
  if not is_assembling_machine(entity) then
    return nil
  end

  -- Fallback: if current recipe is one of the variants, return active variant for its base
  local cur = entity.get_recipe()
  if cur then
    local b = recipe_to_base[cur.name]
    if b then
      return storage.active_variant[b]
    end
  end

  return nil
end

-- Check if variant is enabled for that force
local function is_variant_enabled(entity, variant_name)
  local rec = entity.force.recipes[variant_name]
  return rec and rec.enabled
end

-- Enforce variant on a machine
local function enforce_variant(entity)
  if not is_assembling_machine(entity) then
    return
  end
  local desired = get_desired_variant(entity)
  if not desired then
    --entity.force.print("DEBUG: no desired variant for assembler " .. entity.unit_number)
    return
  end
  local cur = entity.get_recipe()
  if cur and cur.name == desired then
    --entity.force.print("DEBUG: assembler " .. entity.unit_number .. " already using " .. desired)
    return
  end
  if not is_variant_enabled(entity, desired) then
    --entity.force.print("DEBUG: variant " .. desired .. " not enabled for force " .. entity.force.name)
    return
  end

  local ok, reason = attempt_reset(entity)
  if not ok then
    --entity.force.print("DEBUG: reset failed on assembler " .. entity.unit_number .. ": " .. reason)
    storage.pending_switch[entity.unit_number] = {
      target = desired,
      attempts = (storage.pending_switch[entity.unit_number] and storage.pending_switch[entity.unit_number].attempts or 0) + 1
    }
    return
  end
  --entity.force.print("DEBUG: reset succeeded on assembler " .. entity.unit_number)

  -- Now set new recipe
  entity.set_recipe(desired)
  --entity.force.print("DEBUG: set recipe on assembler " .. entity.unit_number .. " → " .. desired)
end

-- Process pending switches
local function process_pending()
  for unit, info in pairs(storage.pending_switch) do
    -- locate the assembler
    local found_entity = nil
    for _, surface in pairs(game.surfaces) do
      local arr = surface.find_entities_filtered{ unit_number = unit }
      if arr and #arr > 0 then
        found_entity = arr[1]
        break
      end
    end
    if not found_entity or not found_entity.valid then
      storage.pending_switch[unit] = nil
    else
      local ok, reason = attempt_reset(found_entity)
      if ok then
        found_entity.set_recipe(info.target)
        --found_entity.force.print("DEBUG: pending switch succeeded for assembler " .. unit .. " → " .. info.target)
        storage.pending_switch[unit] = nil
      --else
        --found_entity.force.print("DEBUG: pending reset still failing for assembler " .. unit .. ": " .. reason)
      end
    end
  end
end

-- Scan all assemblers and enforce or queue
local function scan_override()
  for _, surface in pairs(game.surfaces) do
    local machines = surface.find_entities_filtered{ type = "assembling-machine" }
    for _, m in ipairs(machines) do
      enforce_variant(m)
    end
  end
  process_pending()
end

-- Event handlers
script.on_init(function()
  build_variant_mapping()
  init_storage()
  -- enable all variants initially
  for _, variants in pairs(variant_mapping) do
    for _, v in ipairs(variants) do
      enable_variant_globally(v)
    end
  end
  randomize_all()
end)

script.on_load(function()
  -- re-enable variants after load
  for _, variants in pairs(variant_mapping) do
    for _, v in ipairs(variants) do
      enable_variant_globally(v)
    end
  end
end)

script.on_nth_tick(RANDOM_INTERVAL, function(event)
  randomize_all()
  for _, player in pairs(game.connected_players) do
    player.print("[Randomizer] New variants enabled!")
  end
end)

script.on_nth_tick(SCAN_INTERVAL, function(event)
  scan_override()
end)

