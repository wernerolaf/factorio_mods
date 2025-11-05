-- item_cost_iterative.lua

local M = {}

-- Configuration
local ITERATIONS = 100
local FallbackCost = 1.0

-- Compute item costs via iterative relaxation
function M.compute_costs(data)
  -- Build mapping: item → recipes that produce it
  local item_to_recipes = {}
  for rec_name, rec in pairs(data.raw.recipe) do
    -- get list of results
    local results = nil
    if rec.results then
      results = rec.results
    elseif rec.result then
      results = { { type = "item", name = rec.result, amount = rec.result_count or 1 } }
    end
    if results then
      for _, pr in ipairs(results) do
        if pr.type == "item" then
          item_to_recipes[pr.name] = item_to_recipes[pr.name] or {}
          table.insert(item_to_recipes[pr.name], rec)
        end
      end
    end
  end

  item_cost = {}
  -- Iteratively refine
  for iter = 1, ITERATIONS do
    -- Optionally log iteration start
    -- log("Cost iteration " .. iter)

    for item_name, recs in pairs(item_to_recipes) do
      -- For each recipe that produces item_name
      for _, rec in ipairs(recs) do
        -- Get its ingredient list (choose rec.ingredients or rec.normal, etc.)
        local ing_list = nil
        if rec.ingredients then
          ing_list = rec.ingredients
        elseif rec.normal and rec.normal.ingredients then
          ing_list = rec.normal.ingredients
        else
          ing_list = {}
        end

        -- Sum cost of ingredients
        local sum_ing_cost = 0
        local valid = true
        for _, ing in ipairs(ing_list) do
            local c = item_cost[ing.name]
            if not c then
              valid = false
              item_cost[ing.name] = FallbackCost
              break
            end
            sum_ing_cost = sum_ing_cost + c * ing.amount
        end

        if valid then
          -- Compute total output amount
          local total_out = 0
          if rec.results then
            for _, pr in ipairs(rec.results) do
              total_out = total_out + pr.amount
            end
          elseif rec.result then
            total_out = total_out + (rec.result_count or 1)
          end
          if total_out > 0 then
            local new_cost = sum_ing_cost / total_out
            item_cost[item_name] = new_cost
          end
        end
      end
    end
  end

  return item_cost
end

return M

