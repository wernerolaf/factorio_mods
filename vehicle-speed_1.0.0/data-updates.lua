-- data-updates.lua
-- Read multipliers from startup settings
local speed_mult   = settings.startup["vr-speed-multiplier"].value
local accel_mult   = settings.startup["vr-acceleration-multiplier"].value

-- Helper to apply to a given vehicle prototype
local function boost_vehicle(proto_name, category)
  local proto = data.raw[category] and data.raw[category][proto_name]
  if not proto then return end

  -- Top speed
  if proto.max_speed then
    proto.max_speed = proto.max_speed * speed_mult
  end

  -- Acceleration / braking
  -- Some vehicles use braking_power, some braking_force
  if proto.braking_power then
    -- braking_power is an energy string; multiply numeric part
    local value, unit = proto.braking_power:match("^(%d+%.?%d*)(%a+)$")
    if value and unit then
      proto.braking_power = (tonumber(value) * accel_mult) .. unit
    end
  elseif proto.braking_force then
    proto.braking_force = proto.braking_force * accel_mult
  end
end

-- Apply to specific vehicles
boost_vehicle("car",              "car")
boost_vehicle("tank",             "tank")
boost_vehicle("spidertron",       "spider-vehicle")
boost_vehicle("locomotive",       "locomotive")
