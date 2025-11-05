local util = require("util")

local M = {}

function M.compute_tiers(data)
-- 1. Build tech graph and recipe unlocks

-- techs_by_name: map tech_name → tech prototype
local techs_by_name = data.raw["technology"]

-- For each tech, list which recipe names it unlocks
local recipes_unlocked_by_tech = {}
for tech_name, tech in pairs(techs_by_name) do
  recipes_unlocked_by_tech[tech_name] = {}
  if tech.effects then
    for _, eff in ipairs(tech.effects) do
      if eff.type == "unlock-recipe" then
        table.insert(recipes_unlocked_by_tech[tech_name], eff.recipe)
      end
    end
  end
end

-- 2. Build tech prerequisite graph (reverse edges too)
--   tech_prereqs[tech] = { list of tech names that are direct prerequisites }
local tech_prereqs = {}
for tech_name, tech in pairs(techs_by_name) do
  tech_prereqs[tech_name] = {}
  if tech.prerequisites then
    for _, pr in ipairs(tech.prerequisites) do
      table.insert(tech_prereqs[tech_name], pr)
    end
  end
end

-- 3. Compute tech tiers: distance from “base” (techs with no prerequisites)
local tech_tier = {}  -- tech_name → integer tier (0 = base / no prereqs)
local visited = {}

-- Depth-first / memoization
local function compute_tech_tier(name)
  if tech_tier[name] then
    return tech_tier[name]
  end
  local prereqs = tech_prereqs[name]
  if not prereqs or #prereqs == 0 then
    tech_tier[name] = 0
    return 0
  end
  -- compute max-tier among prereqs, then +1
  local maxp = -math.huge
  for _, p in ipairs(prereqs) do
    local pt = compute_tech_tier(p)
    if pt > maxp then maxp = pt end
  end
  tech_tier[name] = maxp + 1
  return tech_tier[name]
end

for tech_name, _ in pairs(techs_by_name) do
  compute_tech_tier(tech_name)
end

-- 4. Now assign recipe tiers
local recipe_tier = {}  -- recipe_name → integer tier

-- First, set default: recipes enabled from start
for rec_name, rec in pairs(data.raw["recipe"]) do
  if rec.enabled then
    recipe_tier[rec_name] = 0
  end
end

-- For unlocked recipes
for tech_name, rec_list in pairs(recipes_unlocked_by_tech) do
  local t = tech_tier[tech_name]
  for _, recn in ipairs(rec_list) do
    local old = recipe_tier[recn]
    if not old or t < old then
      recipe_tier[recn] = t
    end
  end
end

-- (Optional) propagate tiers to dependent recipes: if a recipe uses ingredients whose recipes are higher-tier, you might bump this recipe up:
for rec_name, rec in pairs(data.raw["recipe"]) do
  if rec.ingredients then
    for _, ing in ipairs(rec.ingredients) do
      local ingname = ing.name
      -- if that ingredient is produced by a recipe (i.e. data.raw.recipe[ingname]) and has tier
      if recipe_tier[ingname] then
        recipe_tier[rec_name] = math.max(recipe_tier[rec_name] or 0, recipe_tier[ingname] + 1)
      end
    end
  end
end

return recipe_tier
end

return M
-- Now you have recipe_tier mapping usable for variant logic
-- (You may want to invert it: tier → list of recipes)

-- Example debug: print tiers
-- for rec, tier in pairs(recipe_tier) do
--   log("Recipe " .. rec .. " → tier " .. tier)
-- end
