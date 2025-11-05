-- data.lua
local new_range = settings.startup["pole-wire-range"].value

for _, pole in pairs(data.raw["electric-pole"]) do
  pole.maximum_wire_distance = new_range
end
