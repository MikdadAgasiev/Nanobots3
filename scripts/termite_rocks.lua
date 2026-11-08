local Event = require('__Nanobots3__/stdlib/event/event')
local Rocks = {}

local function enabled()
    return settings.global['nanobots-termites-eat-rocks'].value
end

local function edible(entity)
    return entity and entity.valid and entity.type == 'simple-entity'
        and entity.force.name == 'neutral' and entity.destructible
        and entity.prototype.count_as_rock_for_filtered_deconstruction
end

function Rocks.scan(player, position, radius, ammo, drain)
    if not enabled() then return end
    local surface = player.character.surface
    for _, rock in pairs(surface.find_entities_filtered{
        position = position, radius = radius, type = 'simple-entity', force = 'neutral', limit = 200
    }) do
        if not (ammo.valid and ammo.valid_for_read) then break end
        if edible(rock) and not rock.to_be_deconstructed() then
            surface.create_entity{
                name = 'nano-projectile-termites-rocks', position = position,
                force = player.force, target = rock, speed = .5
            }
            drain(player, ammo, 1)
        end
    end
end

Event.register(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= 'nanobots-termites-eat-rock' or not enabled() then return end
    local rock = event.target_entity
    if edible(rock) and not rock.to_be_deconstructed() then
        -- Consume the obstacle without mining products, loot or damage to nearby entities.
        rock.destroy{raise_destroy = true}
    end
end)

return Rocks
