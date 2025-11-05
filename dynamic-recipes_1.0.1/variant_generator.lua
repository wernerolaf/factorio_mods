-- variant_generator.lua

local M = {}

-- Configuration
M.max_attempts = 20

-- Generate variants for one base recipe
-- base_proto: the recipe prototype (data.raw.recipe entry)
-- recipe_tier: mapping recipe_name → tier
-- item_cost: mapping item_name → cost
-- rng: random generator with methods choice(tbl), int(lo, hi)
function M.generate_variants_for(base_name, base_proto, recipe_tier, item_cost, rng, num_variants, ing_extra)
  local variants = {}

  local base_ing = {}
  if base_proto.ingredients then
    base_ing = base_proto.ingredients
  elseif base_proto.normal and base_proto.normal.ingredients then
    base_ing = base_proto.normal.ingredients
  else
    -- fallback: empty
    base_ing = {}
    return {}
  end

  local base_results = {}
  if base_proto.results then
    base_results = base_proto.results
  elseif base_proto.result then
    base_results = { { type = "item", name = base_proto.result, amount = base_proto.result_count or 1 } }
  end

  -- compute base cost
  local function compute_recipe_cost(ings)
    local sum = 0
    for _, ing in ipairs(ings) do
      local c = item_cost[ing.name]
      if not c then
        return nil  -- unknown cost
      end
      sum = sum + c * ing.amount
    end
    -- divide by total output amount
    local total_out = 0
    for _, pr in ipairs(base_results) do
      total_out = total_out + pr.amount
    end
    if total_out > 0 then
      return sum / total_out
    else
      return nil
    end
  end

  local base_cost = compute_recipe_cost(base_ing)
  if not base_cost then
    -- can't compute base cost — bail
    return variants
  end

  local base_tier = recipe_tier[base_name] or 0

  -- prepare candidate extras pool
  local extras_pool = {}
  
  -- Build a set of names already in base ingredients
	local existing = {}
	for _, ing in ipairs(base_ing) do
	  if ing.name then
		existing[ing.name] = true
	  end
	end
  
  for item_name, cost in pairs(item_cost) do
    -- skip if no cost or is fluid or already an ingredient or probably needs wood in some form or loader or rocket parts
    if cost and data.raw.item[item_name] and not existing[item_name] and not string.find(item_name, "wood") and not string.find(item_name, "small") and not string.find(item_name, "shotgun") and not string.find(item_name, "loader") and not string.find(item_name, "part") and not string.find(item_name, "scrap") and not string.find(item_name, "waste") and not string.find(item_name, "rust") then
    -- skip unstackable items
    if data.raw.item[item_name].stack_size and data.raw.item[item_name].stack_size > 1 then
      -- item must have a producing recipe with tier < base_tier, or be raw we also want for high tech item to use high tech recipes
      -- We need a way to get item → its recipe tier; assume recipe_tier[item_name] is defined
      local item_t = recipe_tier[item_name] or 0
      if item_t < base_tier and item_t+3 > base_tier then
        if base_tier < 8 then
          if string.find(item_name, "nuclear") or string.find(item_name, "uran") then
            -- skip this one
          else
            table.insert(extras_pool, item_name)
          end
        else
          -- no blocking, allow nuclear extras too
          table.insert(extras_pool, item_name)
      end
      end
    end
    end
  end
  
  if next(extras_pool) == nil then
  return {}
end

  -- variants generation attempts
  for i = 1, num_variants do
    for attempt = 1, M.max_attempts do
      -- start with base ingredients (deep copy)
      local new_ing = {}
      for _, ing in ipairs(base_ing) do
        table.insert(new_ing, { type = ing.type, name = ing.name, amount = ing.amount })
      end

      -- determine extras
      local n_extra = ing_extra
      local chosen = {}
      for k = 1, n_extra do
        local pick = rng:choice(extras_pool)
        if not chosen[pick] then
          chosen[pick] = true
        end
      end

      for name_extra, _ in pairs(chosen) do
        local amt = 1
        table.insert(new_ing, { type = "item", name = name_extra, amount = amt })
      end

      -- compute variant cost
      local vcost = compute_recipe_cost(new_ing)
	if vcost then
	  -- Decide scaling factor
	  local scale = vcost / base_cost
	  scale = math.min(100, math.ceil(scale))

	  -- Apply scaling: multiply each result’s amount by scale, round up
	  local new_results = {}
	  for _, pr in ipairs(base_results) do
	    -- e.g. pr.amount is the original output amount
	    local orig_amt = pr.amount or 1
	    local scaled = orig_amt * scale
	    -- round up: e.g. use math.ceil
	    local new_amt = math.ceil(scaled)
	    table.insert(new_results, { type = pr.type, name = pr.name, amount = new_amt })
	  end

	  local variant_name = base_name .. "-variant-" .. i
	  -- Now accept variant
	  local variant = {
	    name = variant_name,
	    ingredients = new_ing,
	    results = new_results,
	  }
	  table.insert(variants, variant)
	  break
	end
      -- else try again
    end
  end

  return variants
end

return M

