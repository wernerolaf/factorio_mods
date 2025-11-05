-- List of turrets to ban
local banned = { "flamethrower-turret", "laser-turret" }

for _, name in ipairs(banned) do
  -- 1. Disable placement by removing place_result
  local item = data.raw.item[name]
  if item then
    item.place_result = nil  -- no more entity to place
  end
end

--ban gas weapons and drones

function ban_capsule(name)
local cap = data.raw["capsule"][name]
if cap then
  cap.capsule_action = {
    type = "throw",               -- valid CapsuleAction type
    uses_stack = true,            -- default behavior
    attack_parameters = {
      type = "projectile",        -- AttackParameters subtype
      ammo_category = "capsule",  -- matches the poison capsule
      ammo_type = {               -- mandatory AmmoType block
        category = "capsule",
        target_type = "position",
        action = {
          type = "direct",        -- valid ActionDelivery type
          action_delivery = {
            type = "instant",     -- instant delivery
            target_effects = {
              {
                type = "script",       -- must specify a valid effect type 
                effect_id = "no-op"    -- arbitrary ID
              }
            }
          }
        }
      },
      cooldown = 30,              -- base-game cooldown
      projectile_center = {0, 0},
      projectile_creation_distance = 0.6,
      range = 25                  -- base-game range
    }
  }
end
end

ban_capsule("slowdown-capsule")
ban_capsule("poison-capsule")
ban_capsule("defender-capsule")
ban_capsule("distractor-capsule")
ban_capsule("destroyer-capsule")

--ban mines

local land_mine = data.raw["land-mine"]["land-mine"]
if land_mine then
  -- Remove the explosion/stun effect
  land_mine.action = nil
end


--ban nukes
local ammo = data.raw["ammo"]["atomic-bomb"]
if ammo then
  ammo.action = nil
end

-- Disable the nuclear rocket projectile
local rocket = data.raw["projectile"]["atomic-rocket"]
if rocket then
  rocket.action = nil
end

-- Disable the artillery shell’s action
local shell = data.raw["projectile"]["atomic-artillery-shell"]
if shell then
  shell.action = nil
end

-- Remove the explosion entity entirely (safest fallback)
data.raw["explosion"]["atomic-rocket-explosion"] = nil  -- kills the explosion prototype
