local multiplier = settings.startup["worm-range-multiplier"].value

-- Helper: is this a worm turret?
local function is_worm(name)
  return name:find("worm")  -- matches "small-worm", "big-worm", "behemoth-worm", etc.
end

for name, turret in pairs(data.raw["turret"]) do
  if is_worm(name) and turret.attack_parameters then
    -- scale the ranges
    local ap = turret.attack_parameters
    ap.range = ap.range * multiplier
    turret.prepare_range = ap.range
  end
end

