local util = require("util")
local rng_mod = require("rng")
local item_cost_mod = require("item_cost")
local tech_tier_mod = require("tech_tiers")
local variant_gen = require("variant_generator")

-- read the seed from settings
local seed = settings.startup["rng-seed"].value or 1
local num_variants =  settings.startup["variants-num"].value or 1
local ing_extra =  settings.startup["ingredients-num"].value or 1
local mult = settings.startup["base-multiplier"].value or 1

local rng = rng_mod.new(seed)

-- compute cost & tiers
local cost_table = item_cost_mod.compute_costs(data)
local recipe_tier = tech_tier_mod.compute_tiers(data)

-- debug logs
for rec, t in pairs(recipe_tier) do
  log("Recipe " .. rec .. " → tier " .. t)
end
for item, c in pairs(cost_table) do
  log("Item " .. item .. " → cost " .. string.format("%.6f", c))
end


-- Build blacklist_unstackable_items set
local blacklist_unstackable = {}

local categories = {
  "armor", "item", "item-with-entity-data", "ammo",
  "gun", "selection-tool", "spidertron-remote"
}
for _, cat in ipairs(categories) do
  local tbl = data.raw[cat]
  if tbl then
    for _, item in pairs(tbl) do
      if item.stack_size and item.stack_size == 1 then
        blacklist_unstackable[item.name] = true
      end
    end
  end
end

local function should_randomize(base_name, base_proto, recipe_tier, item_cost, blacklist_unstackable)

  -- skip if recipe is enabled by default (so you preserve basic ones)
  if base_proto.enabled then
    return false
  end
  -- blacklist unstackable
  if blacklist_unstackable[base_name] then
    return false
  end

  -- skip if recipe_tier is nil or 0
  local tier = recipe_tier[base_name]
  if not tier or tier <= 0 then
    return false
  end

  -- skip if name matches blacklist pattern
  local blacklist_patterns = { "barrel", "fill", "empty", "water", "scrap", "recyle", "recycle", "waste", "uran", "rocket%-part", "cliff", "biter", "asteroid", "steel"}
  for _, pat in ipairs(blacklist_patterns) do
    if string.find(base_name, pat) then
      return false
    end
  end
  
  for name, furnace in pairs(data.raw["furnace"]) do
    if furnace.crafting_categories and base_proto.category then

        for _, cat in pairs(furnace.crafting_categories) do
    	if cat == base_proto.category then
    	   return false
    	end
    	end
    end
  end
  
  -- skip if recipe uses super-module compatibility with cubes-challenge mod
  local ing_list = base_proto.ingredients or (base_proto.normal and base_proto.normal.ingredients) or {}
  for _, ing in ipairs(ing_list) do
    if ing.name and string.find(ing.name, "super%-module") then
      return false
    end
  end
  
  -- skip fluids and recipes with circular dependencies
  local res_list = nil
  if base_proto.results then
    res_list = base_proto.results
  elseif base_proto.normal and base_proto.normal.results then
    res_list = base_proto.normal.results
  end
  if res_list then
    for _, r in ipairs(res_list) do
      if r.type == "fluid" then
        return false
      end
      
      for _, ing in ipairs(ing_list) do
    if ing.name == r.name then
      return false
    end
  end 
      
    end
  end

  -- otherwise safe to randomize
  return true
end

local function multiply_ingredients(proto)
        if proto.ingredients then
          for _, ing in ipairs(proto.ingredients) do
            ing.amount = ing.amount * mult
          end
        end
        if proto.normal and proto.normal.ingredients then
          for _, ing in ipairs(proto.normal.ingredients) do
            ing.amount = ing.amount * mult
          end
        end
        if proto.expensive and proto.expensive.ingredients then
          for _, ing in ipairs(proto.expensive.ingredients) do
            ing.amount = ing.amount * mult
          end
        end
      end


-- generate variants
local new_recipes = {}
for base_name, base_proto in pairs(data.raw.recipe) do
  if should_randomize(base_name, base_proto, recipe_tier, cost_table, blacklist_unstackable) then
    local vars = variant_gen.generate_variants_for(base_name, base_proto, recipe_tier, cost_table, rng, num_variants, ing_extra)
    
    if #vars > 0 then
      -- we have at least one variant, so penalize (multiply) the original recipe’s cost
      multiply_ingredients(base_proto)
    end
    
    for idx, var in ipairs(vars) do
      local newp = util.table.deepcopy(base_proto)
      newp.name = var.name
      newp.enabled = false
      newp.ingredients = var.ingredients
      newp.results = var.results
      if newp.normal then
        newp.normal.ingredients = var.ingredients
        newp.normal.results = var.results
      end
      if newp.expensive then
        newp.expensive.ingredients = var.ingredients
        newp.expensive.results = var.results
      end
      table.insert(new_recipes, newp)
    end
  end
end
data:extend(new_recipes)
