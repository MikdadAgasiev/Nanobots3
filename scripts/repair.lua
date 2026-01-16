-- repair.lua
local function hasAllModules(plr, normalized)
    if not (plr and plr.valid) then return false end
    if not (pinv and pinv.valid) then return false end

    for req_key, want in pairs(normalized) do
        local name, quality = req_key:match("([^:]+):(.+)")
        local have = initial_modules[name] or 0
        local need = want - have
        if need > 0 then
            local available = plr.cheat_mode and need or pinv.get_item_count({ name = name, quality = quality })
            if available < need then
                nlog("❌ Не хватает: " .. name .. " (" .. quality .. ") нужно=" .. need .. " есть=" .. available)
                return false
            end
        end
    end
    return true
end

local normalized = {}
for key, v in pairs(requests.item_requests or {}) do
    local name = v.name or key
    local count = tonumber(v.count or v.amount or v or 0) or 0
    local quality = v.quality or "normal"
    local req_key = name .. ":" .. quality
    if name and count > 0 then
        normalized[req_key] = (normalized[req_key] or 0) + count
    end
end

if not hasAllModules(player, normalized) then
    nlog("⚠️ Отмена: не все модули доступны в инвентаре")
    return false
end

local free_slots_total = 0
for i = 1, #module_inv do
    local slot = module_inv[i]
    if slot.valid_for_read then
        return false
    end
    free_slots_total = free_slots_total + 1
end

local any_inserted, any_unsatisfied = false, false

for req_key, want in pairs(normalized) do
    if not (entity.valid and player.valid and pinv.valid) then
        return any_inserted
    end

    local name, quality = req_key:match("([^:]+):(.+)")
    local have = initial_modules[name] or 0
    local need = want - have
    if need <= 0 then goto continue_loop end

    local available = player.cheat_mode and need or pinv.get_item_count({ name = name, quality = quality })
    if available < need then
        any_unsatisfied = true
        goto continue_loop
    end

    local possible = math.min(need, available, free_slots_total)
    local remaining, inserted = possible, 0

    for i = 1, #module_inv do
        if remaining <= 0 then break end
        if not entity.valid then return any_inserted end
        local slot = module_inv[i]
        if not slot.valid_for_read then
            slot.set_stack({ name = name, count = 1, quality = quality })
            remaining = remaining - 1
            inserted = inserted + 1
            free_slots_total = free_slots_total - 1
        end
    end

    if inserted > 0 and not player.cheat_mode and pinv.valid then
        pinv.remove({ name = name, quality = quality, count = inserted })
    end

    if inserted > 0 then any_inserted = true end
    if want - (have + inserted) > 0 then any_unsatisfied = true end

    ::continue_loop::
end

if not any_unsatisfied then
    if requests.valid then requests.destroy() end
end

return any_inserted

local function create_projectile(name, surface, force, source, target, speed)
    speed = speed or 1
    force = force or 'player'
    if surface and surface.valid then
        surface.create_entity { name = name, force = force, position = source, target = target, speed = speed }
    end
end

-- Queue actions (same as before) + Repair uses nano-projectile-repair
function Queue.cliff_deconstruction(data)
    local entity, player = data.entity, game.get_player(data.player_index)
    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then
        return insert_or_spill_items(player, { data.item_stack })
    end
    if not (entity and entity.valid and entity.to_be_deconstructed()) then
        return insert_or_spill_items(player, { data.item_stack })
    end

    create_projectile('nano-projectile-deconstructors', entity.surface, entity.force, player.character.position, entity.position)
    local exp_name = data.item_stack.name == 'artillery-shell' and 'big-artillery-explosion' or 'big-explosion'
    entity.surface.create_entity { name = exp_name, position = entity.position }
    entity.destroy({ do_cliff_correction = true, raise_destroy = true })
    nlog_agg("Снесено скал", "cliff")
end

function Queue.deconstruction(data)
    local entity = data.entity
    local player = game.get_player(data.player_index)
    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then return end
    if not (entity and entity.valid and entity.to_be_deconstructed()) then return end

    -- Сохраняем всё, что нужно ДО потенциального уничтожения entity
    local entity_name = entity.name
    local surface = data.surface or entity.surface
    local force = entity.force
    local ppos = player.character.position
    local epos = entity.position

    create_projectile('nano-projectile-deconstructors', surface, force, ppos, epos)
    create_projectile('nano-projectile-return', surface, force, epos, ppos)

    if entity_name == 'deconstructible-tile-proxy' then
        local tile = surface.get_tile(epos)
        if tile then
            local tile_name = tile.name
            player.mine_tile(tile)
            if entity.valid then entity.destroy() end
            nlog_agg("Снесено плиток", tile_name)
        end
    else
        -- ВАЖНО: после mine_entity() entity может стать invalid
        player.mine_entity(entity)
        nlog_agg("Снесено", entity_name)
    end
end

function Queue.build_entity_ghost(data)
    local ghost = data.entity
    local player = game.get_player(data.player_index)
    local surface = data.surface
    local position = data.position

    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then
        return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode)
    end
    if not (ghost and ghost.valid and ghost.ghost_name == data.entity_name) then
        return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode)
    end

    local item_stacks = get_all_items_on_ground(ghost)
    if not player.surface.can_place_entity { name = ghost.ghost_name, position = ghost.position, direction = ghost.direction, force = ghost.force } then
        return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode)
    end

    local revived, entity, requests = ghost.revive { return_item_request_proxy = true, raise_revive = true }
    if not revived then
        return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode)
    end

    if not entity then
        if insert_or_spill_items(player, item_stacks, player.cheat_mode) then
            create_projectile('nano-projectile-return', surface, player.force, position, player.character.position)
        end
        return
    end

    create_projectile('nano-projectile-constructors', entity.surface, entity.force, player.character.position, entity.position)
    entity.health = (entity.health > 0) and ((data.item_stack.health or 1) * entity.max_health)

    if insert_or_spill_items(player, insert_into_entity(entity, item_stacks)) then
        create_projectile('nano-projectile-return', surface, player.force, position, player.character.position)
    end

    nlog_agg("Построено", data.entity_name)

    if requests and requests.valid and entity and entity.valid then
        satisfy_requests(requests, entity, player)
    end
end

function Queue.build_tile_ghost(data)
    local ghost = data.entity
    local player = game.get_player(data.player_index)
    local surface = data.surface
    local position = data.position

    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then
        return insert_or_spill_items(player, { data.item_stack })
    end
    if not (ghost and ghost.valid) then
        return insert_or_spill_items(player, { data.item_stack })
    end

    local tile, hidden_tile = surface.get_tile(position), surface.get_hidden_tile(position)
    local force = ghost.force
    local tile_was_mined = hidden_tile and tile.prototype.can_be_part_of_blueprint and player.mine_tile(tile)
    local ghost_was_revived = ghost.valid and ghost.revive({ raise_revive = true })
    if not (tile_was_mined or ghost_was_revived) then
        return insert_or_spill_items(player, { data.item_stack })
    end

    local item_ptype = data.item_stack and prototypes.item[data.item_stack.name]
    local tile_ptype = item_ptype and item_ptype.place_as_tile_result.result
    create_projectile('nano-projectile-constructors', surface, force, player.character.position, position)

    Position.floored(position)
    if tile_was_mined and not ghost_was_revived then
        create_projectile('nano-projectile-return', surface, force, position, player.character.position)
        surface.set_tiles({ { name = tile_ptype.name, position = position } }, true, true, false, true)
    end
    surface.play_sound { path = 'nano-sound-build-tiles', position = position }

    local tile_name = tile_ptype and tile_ptype.name or (data.item_stack and data.item_stack.name) or "unknown"
    nlog_agg("Уложено плиток", tile_name)
end

function Queue.upgrade_direction(data)
    local ghost = data.entity
    local player = game.get_player(data.player_index)
    local surface = data.surface
    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then return end
    if not (ghost and ghost.valid and ghost.to_be_upgraded()) then return end

    ghost.direction = data.direction
    ghost.cancel_upgrade(player.force, player)
    create_projectile('nano-projectile-constructors', ghost.surface, ghost.force, player.character.position, ghost.position)
    surface.play_sound { path = 'utility/build_small', position = ghost.position }
    nlog_agg("Повернуто", ghost.name)
end

function Queue.upgrade_ghost(data)
    local ghost = data.entity
    local player = game.get_player(data.player_index)
    local surface = data.surface
    local position = data.position

    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then
        return insert_or_spill_items(player, { data.item_stack })
    end
    if not (ghost and ghost.valid) then
        return insert_or_spill_items(player, { data.item_stack })
    end

    local old_name = ghost.name
    local new_name = data.entity_name or data.item_stack.name

    local entity = surface.create_entity {
        name = new_name,
        direction = ghost.direction,
        force = ghost.force,
        position = position,
        fast_replace = true,
        player = player,
        type = ghost.type == 'underground-belt' and ghost.belt_to_ground_type or nil,
        raise_built = true
    }
    if not entity then
        return insert_or_spill_items(player, { data.item_stack })
    end

    create_projectile('nano-projectile-constructors', entity.surface, entity.force, player.character.position, entity.position)
    surface.play_sound { path = 'utility/build_small', position = entity.position }
    entity.health = (entity.health > 0) and ((data.item_stack.health or 1) * entity.max_health)

    nlog_agg("Апгрейд " .. old_name .. " →", new_name)
end

function Queue.item_requests(data)
    local proxy = data.entity
    local player = game.get_player(data.player_index)
    if not player or not player.valid then return end
    if not player.character or not player.character.valid then return end
    if not proxy or not proxy.valid then return end

    local target = proxy.proxy_target
    local target_name = target and target.valid and target.name or "unknown"
    if not target or not target.valid then return end

    nlog("🎯 Обработка запроса модулей для: " .. target_name)

    local ok = satisfy_requests(proxy, target, player)
    if ok and player.character and player.character.valid then
        create_projectile('nano-projectile-constructors', proxy.surface, proxy.force, player.character.position, proxy.position)
    end
end

-- Repair action (UPDATED projectile name)
function Queue.repair(data)
    local entity = data.entity
    local player = game.get_player(data.player_index)

    if not (player and player.valid) then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end
    if not (player.character and player.character.valid) then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end
    if not (entity and entity.valid) then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end
    if not cfg.do_repair then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end

    if data.unit_number then
        touch_session(data.player_index, data.unit_number)
    end

    local ratio = entity.get_health_ratio()
    if not ratio or ratio >= 1 then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end

    local ammo = data.ammo
    if not (ammo and ammo.valid_for_read) then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end

    if cfg.network_limits and not nano_network_check(player.character, entity) then
        return
    end

    local radius = get_ammo_radius(player, ammo)
    local dx = player.character.position.x - entity.position.x
    local dy = player.character.position.y - entity.position.y
    if (dx * dx + dy * dy) > (radius * radius) then
        return
    end

    local max_health = entity.max_health or 100
    local current_health = entity.health or 0
    local damage = max_health - current_health
    if damage <= 0 then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end

    local repaired, pack_exhausted = use_repair_tool(player, damage)
    if repaired <= 0 and not pack_exhausted then
        return
    end

    -- IMPORTANT: repair uses nano-projectile-repair now
    if data.repair_shot and repaired > 0 then
        local surface = data.surface or entity.surface
        local force = entity.force
        create_projectile('nano-projectile-repair', surface, force, player.character.position, entity.position)
        -- звук можно оставить или убрать:
        surface.play_sound { path = 'utility/build_small', position = entity.position }
    end

    if repaired > 0 then
        entity.health = math.min(max_health, current_health + repaired)
        nlog_agg("Отремонтировано", entity.name)
    end

    if not (entity.valid and (entity.get_health_ratio() or 0) < 1) then
        if data and data.player_index and data.unit_number then end_session(data.player_index, data.unit_number) end
        return
    end

    if not has_repair_tool(player) then
        return
    end

    local delay = (cfg and cfg.repair_requeue_delay) or 20

    local nd = {
        player_index = data.player_index,
        ammo         = ammo,
        position     = entity.position,
        surface      = entity.surface,
        unit_number  = data.unit_number or entity.unit_number,
        entity       = entity,
        action       = 'repair'
    }

    if pack_exhausted then
        nd.repair_shot = true
        push_pending_repair(nd, game.tick + delay, true)
    else
        nd.repair_shot = false
        push_pending_repair(nd, game.tick + delay, false)
    end
end
