local ban_tree = settings.startup["tree-ban-setting"].value
local ban_landfill = settings.startup["landfill-ban-setting"].value
local ban_cliff = settings.startup["cliff-ban-setting"].value

if ban_tree then

for _, tree in pairs(data.raw["tree"]) do
    tree.max_health = 10000
    tree.healing_per_tick = 1000
    tree.minable = nil
    tree.flags = {"not-flammable"}
end

for _, tree in pairs(data.raw["tree"]) do
    tree.resistances = {
        {
          type = "physical",
          percent = 100
        },
        {
          type = "impact",
          percent = 100
        },
        {
          type = "fire",
          percent = 100
        },
        {
          type = "acid",
          percent = 100
        },
        {
          type = "poison",
          percent = 100
        },
        {
          type = "explosion",
          percent = 100
        },
        {
          type = "laser",
          percent = 100
        },
        {
          type = "electric",
          percent = 100
        }
  
    }
  end
end

if ban_landfill then

local landfill = data.raw.item["landfill"]
if landfill then
  -- 2) Remove its place_as_tile behavior entirely
  landfill.place_as_tile = nil
end

end

if ban_cliff then

-- 1) Reference the vanilla cliff-explosives prototype (keep it intact)
local real_capsule = data.raw.capsule["cliff-explosives"]
if not real_capsule or not real_capsule.capsule_action then
  error("Could not find vanilla cliff-explosives capsule or its action!")
end

-- 2) Create a dummy item that players will actually craft/use
data:extend({
  {
    type = "item",
    name = "dummy-cliff-explosives",
    icon = real_capsule.icon,
    icon_size = real_capsule.icon_size,
    subgroup = real_capsule.subgroup,
    order = real_capsule.order,
    stack_size = real_capsule.stack_size
  }
})

-- 3) Redirect the vanilla recipe to produce our dummy instead of the real one
local recipe = data.raw.recipe["cliff-explosives"]
if recipe then
  -- remove any legacy result fields
  recipe.result = nil
  recipe.result_count = nil
  recipe.normal = nil
  recipe.expensive = nil

  -- define new results table for 2.0 API
  recipe.results = {
    {
      type = "item",
      name = "dummy-cliff-explosives",
      amount = 1
    }
  }
else
  error("Could not find recipe for cliff-explosives!")
end

-- name of the real and dummy items
local real_item  = "cliff-explosives"
local dummy_item = "dummy-cliff-explosives"

-- helper to replace in a simple ingredients array
local function replace_in_ingredients(ingredients)
  for i, ing in ipairs(ingredients) do
    -- two possible formats: {name, amount} or { type=..., name=..., amount=... }
    local name = ing.name or ing[1]
    if name == real_item then
      if ing.name then
        ing.name = dummy_item
      else
        ing[1] = dummy_item
      end
    end
  end
end

-- iterate all recipes
for _, recipe in pairs(data.raw.recipe) do
  -- handle simple-format recipes
  if recipe.ingredients then
    replace_in_ingredients(recipe.ingredients)
  end

  -- handle normal/expensive variants
  if recipe.normal and recipe.normal.ingredients then
    replace_in_ingredients(recipe.normal.ingredients)
  end
  if recipe.expensive and recipe.expensive.ingredients then
    replace_in_ingredients(recipe.expensive.ingredients)
  end

  -- also update results if any recipe produces the real item (unlikely but safe)
  if recipe.results then
    for _, res in ipairs(recipe.results) do
      if (res.name == real_item) then
        res.name = dummy_item
      end
    end
  elseif recipe.result == real_item then
    -- old-style single result; migrate to new style if needed
    recipe.result = nil
    recipe.result_count = nil
    recipe.results = {{ type="item", name=dummy_item, amount=1 }}
  end
end

end
