local container = {}
local multiplier = settings.startup["cubes-multiplier"].value or 1

-- [Item] --
local item = table.deepcopy(data.raw["module"]["speed-module-3"])
item.effect = {
   consumption = 100.0,
   speed = 200.0
}
item.icon = "__cubes-challenge__/graphics/icons/cubium.png"
item.name = "super-module"
item.tier = 4
table.insert(container, item)
data:extend(container)

data:extend({
  {
    type     = "sprite",
    name     = "cubium-gui-icon",                -- your chosen internal name
    filename = "__cubes-challenge__/graphics/icons/cubium.png",
    priority = "extra-high-no-scale",
    width    = 64, height = 64,
    mipmap_count = 1
  }
})

data:extend({
  {
    type            = "custom-input",
    name            = "resummon-cubes-hotkey",
    key_sequence    = "SHIFT + R",
    consuming       = "none",
    localised_name = { "custom-input.resummon-cubes" }
  }
})

local function is_recycling_recipe(recipe)
  -- skip any recipe whose name begins with "scrap-" or includes "-recycle", "-waste"
  return recipe.name:match("^scrap%-") or recipe.name:match("%-recycle$") or recipe.name:match("%-recyle$") or recipe.name:match("%-waste$") or recipe.name:match("%-reprocessing$")
end

local function is_barrel_recipe(recipe)
  return recipe.name:match("^fill%-") or recipe.name:match("^empty%-") or recipe.name:match("%-barrel$")
end

local function is_biter_recipe(recipe)
  return recipe.name:match("^biter%-") or recipe.name:match("^egg%-") or recipe.name:match("%-egg$")
end

local function find_proto(name)
  -- if name exists as ANY item-type, this will return it:
  local proto = data.raw.item[name]
  if proto then
    return proto, proto.type
  end
  return nil, nil
end


-- Find existing ingredient by name (new or legacy style)
local function find_ingredient_index(ings, item_name)
  for i, ing in pairs(ings) do
    if ing.name == item_name or ing[1] == item_name then
      return i
    end
  end
  return nil
end

local function add_ingredient(ings, item_name)
  ings = ings or {}
  local idx = find_ingredient_index(ings, item_name)
  if idx then
    local ing = ings[idx]
    if ing.amount then
      ing.amount = ing.amount
    else
      ing[2] = (ing[2] or 0)
    end
  else
    table.insert(ings, { type = "item", name = item_name, amount = 1 })
  end
  return ings
end

local function patch_results(res)
  if res.allow_productivity then return end

  local name, proto
  if res.result then
    name = res.result
    res.results = {{ type="item", name=name, amount=(res.result_count or 1) }}
    res.result, res.result_count = nil, nil
  elseif res.results and #res.results > 0 then
    name = res.results[1].name
  else
    return
  end
  
  proto = find_proto(name)
   if not proto then
    -- skip this recipe entirely if there is no matching prototype
    return
  end
  -- icon copying from proto...
  if proto and proto.icons and proto.icons[1] then
    local layer = proto.icons[1]
    res.icon      = layer.icon
    res.icon_size = layer.icon_size or proto.icon_size or 64
  elseif proto and proto.icons then
    local layer = proto.icons
    res.icon      = layer.icon
    res.icon_size = layer.icon_size or proto.icon_size or 64
  elseif proto and proto.icon then
    res.icon      = proto.icon
    res.icon_size = proto.icon_size or 64
  else
    res.icon      = "__cubes-challenge__/graphics/icons/cubium.png"
    res.icon_size = 64
  end

  res.main_product = name
  if res.ingredients then
    res.ingredients = add_ingredient(res.ingredients, "super-module")
  end
  if res.results then
    for _, out in ipairs(res.results) do
      if out.amount then
        out.amount = out.amount * multiplier
      elseif out[2] then
        out[2] = out[2] * multiplier
      end
    end
    res.results     = add_ingredient(res.results,     "super-module")
  end
end

-- helper: does this machine prototype have base productivity?
local function machine_has_base_prod(machine)
  if machine.effect_receiver and machine.effect_receiver.base_effect then
    local bp = machine.effect_receiver.base_effect.productivity
    if bp and bp > 0 then
      return true
    end
  end
  return false
end

-- build a table of categories to skip
local productive_categories = {}

-- scan all machines / smelters etc that are relevant
local function scan_machines()
  -- Assembling machines
  for name, machine in pairs(data.raw["assembling-machine"]) do
    if machine.crafting_categories then
      if machine_has_base_prod(machine) then
        for _, cat in pairs(machine.crafting_categories) do
          productive_categories[cat] = true
        end
      end
    end
  end

  -- Also consider furnaces or other prototypes that have cooking / smelting
  for name, furnace in pairs(data.raw["furnace"]) do
    if furnace.crafting_categories then
      if machine_has_base_prod(furnace) then
        for _, cat in pairs(furnace.crafting_categories) do
          productive_categories[cat] = true
        end
      end
    end
  end

  -- Other entity types if you have mods that add special machines (labs, rocket-silo etc., if they have base_productivity)
  for _, proto_name in pairs({ "rocket-silo" }) do
    for name, ent in pairs(data.raw[proto_name] or {}) do
      if ent.crafting_categories and machine_has_base_prod(ent) then
        for _, cat in pairs(ent.crafting_categories) do
          productive_categories[cat] = true
        end
      end
    end
  end
end

-- call the scan somewhere before patching
scan_machines()


for _, recipe in pairs(data.raw.recipe) do
  local cat = recipe.category or "crafting"
  if not recipe.hidden and not is_recycling_recipe(recipe) and not is_barrel_recipe(recipe) and not is_biter_recipe(recipe) and not productive_categories[cat] then
    patch_results(recipe)
    if recipe.normal    then patch_results(recipe.normal)    end
    if recipe.expensive then patch_results(recipe.expensive) end
  end
end
