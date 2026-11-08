-- Switch the selected Nano Emitter between constructors and termites.
-- LuaItemStack.swap_stack preserves quality and remaining magazine state.
local AmmoSwitch = {}
local CONSTRUCTORS = 'ammo-nano-constructors'
local TERMITES = 'ammo-nano-termites'
local TYPES = {
    [CONSTRUCTORS] = TERMITES,
    [TERMITES] = CONSTRUCTORS
}

-- Return the inventory slot of the requested ammo type. When switching an
-- occupied slot, prefer the same quality but allow other qualities as fallback.
local function find_ammo_slot(main, name, preferred_quality)
    local first_slot
    for i = 1, #main do
        local candidate = main[i]
        if candidate.valid_for_read and candidate.name == name then
            if preferred_quality and candidate.quality.name == preferred_quality then
                return i
            end
            if not first_slot then first_slot = i end
        end
    end
    return first_slot
end

function AmmoSwitch.toggle(player)
    if not (player and player.valid and player.character and player.character.valid) then return end
    local character = player.character
    local guns = character.get_inventory(defines.inventory.character_guns)
    local ammo = character.get_inventory(defines.inventory.character_ammo)
    local main = player.get_main_inventory()
    if not (guns and guns.valid and ammo and ammo.valid and main and main.valid) then return end
    local index = character.selected_gun_index
    if not index or not guns[index] or not guns[index].valid_for_read or guns[index].name ~= 'gun-nano-emitter' then
        player.print({'nanobots-ammo-switch.emitter-required'})
        return
    end

    local equipped = ammo[index]
    if not equipped then
        player.print({'nanobots-ammo-switch.swap-failed'})
        return
    end

    local candidate_slot
    if equipped.valid_for_read then
        local target = TYPES[equipped.name]
        if not target then
            player.print({'nanobots-ammo-switch.unsupported-ammo'})
            return
        end
        candidate_slot = find_ammo_slot(main, target, equipped.quality.name)
        if not candidate_slot then
            player.print({'nanobots-ammo-switch.missing-ammo', {'item-name.' .. target}})
            return
        end
    else
        -- Empty emitter: load constructors first, or termites if unavailable.
        candidate_slot = find_ammo_slot(main, CONSTRUCTORS)
            or find_ammo_slot(main, TERMITES)
        if not candidate_slot then
            player.print({'nanobots-ammo-switch.no-ammo-available'})
            return
        end
    end

    -- Swapping also works with an empty equipped slot and keeps the original
    -- stack state (including partially used magazines) without cloning items.
    if not equipped.swap_stack(main[candidate_slot]) then
        player.print({'nanobots-ammo-switch.swap-failed'})
    end
end

return AmmoSwitch
