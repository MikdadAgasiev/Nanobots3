-- nanobots.lua
local function get_ammo_radius(player, ammo)
    -- Функция для вычисления радиуса аммуниции
    return ammo.get_radius()
end

local function create_projectile(name, surface, force, source, target, speed)
    speed = speed or 1
    force = force or 'player'
    if surface and surface.valid then
        surface.create_entity { name = name, force = force, position = source, target = target, speed = speed }
    end
end

local function nano_network_check(character, entity)
    -- Проверка на соединение с сетью нано-ботов
    return true
end

local function use_repair_tool(player, damage)
    -- Использование инструмента для ремонта
    return damage, false
end

local function has_repair_tool(player)
    -- Проверка, есть ли инструмент для ремонта
    return true
end

local function nlog_agg(message, type)
    -- Логирование сообщений
    game.print(message)
end

-- Основной объект очереди
local Queue = {}

function Queue.insert(data, tick)
    -- Добавление действия в очередь
    if not storage.nano_queue then
        storage.nano_queue = {}
    end
    table.insert(storage.nano_queue, data)
end

function Queue.execute(event)
    -- Исполнение действий из очереди
    for _, data in ipairs(storage.nano_queue) do
        if data.action == 'repair' then
            Queue.repair(data)
        elseif data.action == 'deconstruction' then
            Queue.deconstruction(data)
        elseif data.action == 'build_entity_ghost' then
            Queue.build_entity_ghost(data)
        elseif data.action == 'build_tile_ghost' then
            Queue.build_tile_ghost(data)
        elseif data.action == 'upgrade_direction' then
            Queue.upgrade_direction(data)
        elseif data.action == 'upgrade_ghost' then
            Queue.upgrade_ghost(data)
        elseif data.action == 'item_requests' then
            Queue.item_requests(data)
        end
    end
end

function Queue.deconstruction(data)
    local entity = data.entity
    local player = game.get_player(data.player_index)
    if not (player and player.valid) then return end
    if not (player.character and player.character.valid) then return end
    if not (entity and entity.valid and entity.to_be_deconstructed()) then return end

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
        return insert_or_spill_items(player, { data.item_stack })
    end
    if not (ghost and ghost.valid and ghost.ghost_name == data.entity_name) then
        return insert_or_spill_items(player, { data.item_stack })
    end

    local item_stacks = get_all_items_on_ground(ghost)
    if not player.surface.can_place_entity { name = ghost.ghost_name, position = ghost.position, direction = ghost.direction, force = ghost.force } then
        return insert_or_spill_items(player, { data.item_stack })
    end

    local revived, entity, requests = ghost.revive { return_item_request_proxy = true, raise_revive = true }
    if not revived then
        return insert_or_spill_items(player, { data.item_stack })
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
    local player = game
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

-- Trees (termite ammo)
local function everyone_hates_trees(player, pos, nano_ammo)
    local radius = get_ammo_radius(player, nano_ammo)
    local force = player.force

    for _, stupid_tree in pairs(player.surface.find_entities_filtered { position = pos, radius = radius, type = 'tree', limit = 200 }) do
        if nano_ammo.valid and nano_ammo.valid_for_read then
            if not stupid_tree.to_be_deconstructed() then
                local tree_area = Area.expand(stupid_tree.bounding_box, .5)
                if player.surface.count_entities_filtered { area = tree_area, name = 'nano-cloud-small-termites' } == 0 then
                    player.surface.create_entity {
                        name = 'nano-projectile-termites',
                        position = player.character.position,
                        force = force,
                        target = stupid_tree,
                        speed = .5
                    }
                    ammo_drain(player, nano_ammo, 1)
                    nlog_agg("Атаковано деревьев", "tree")
                end
            end
        else
            break
        end
    end
end

-- Execute item
function Queue.execute_item(data)
    if data.action == 'cliff_deconstruction' then
        Queue.cliff_deconstruction(data)
    elseif data.action == 'deconstruction' then
        Queue.deconstruction(data)
    elseif data.action == 'build_entity_ghost' then
        Queue.build_entity_ghost(data)
    elseif data.action == 'build_tile_ghost' then
        Queue.build_tile_ghost(data)
    elseif data.action == 'upgrade_direction' then
        Queue.upgrade_direction(data)
    elseif data.action == 'upgrade_ghost' then
        Queue.upgrade_ghost(data)
    elseif data.action == 'item_requests' then
        Queue.item_requests(data)
    elseif data.action == 'repair' then
        Queue.repair(data)
    end
end

-- Scan in range: repairs + ghosts/deconstruct/upgrades
local function queue_ghosts_in_range(player, pos, nano_ammo)
    storage.players = storage.players or {}
    local pdata = storage.players[player.index] or {}
    storage.players[player.index] = pdata

    local force = player.force
    local _next_nano_tick =
        (pdata._next_nano_tick and pdata._next_nano_tick < (game.tick + 2000) and pdata._next_nano_tick) or game.tick

    local tick_spacing =
        max(1, cfg.queue_rate - (queue_speed[force.get_gun_speed_modifier('nano-ammo')] or queue_speed[4]))

    local next_tick, queue_count = queue:next(_next_nano_tick, tick_spacing)
    local radius = get_ammo_radius(player, nano_ammo)
    local area = Position.expand_to_area(pos, radius)

    -- Repairs optimized scan
    if cfg.do_repair then
        ensure_throttle()

        local in_combat = is_player_in_combat(player)
        local scan_types = (in_combat and cfg.repair_combat_important_only) and cfg.repair_scan_types_combat or cfg.repair_scan_types_normal

        if scan_types and #scan_types > 0 and has_repair_tool(player) then
            local candidates = player.surface.find_entities_filtered {
                area = area,
                force = force,
                type = scan_types,
                limit = 400
            }

            local list = {}

            for _, entity in pairs(candidates) do
                if nano_repairable_entity(entity) then
                    local ratio_e = entity.get_health_ratio() or 1
                    if ratio_e < (cfg.repair_threshold or 0.95) then
                        local unit = entity.unit_number
                        if unit then
                            local last = storage.repair_last_scan_tick[unit]
                            local throttle = cfg.repair_throttle_ticks or 0
                            if (not last) or throttle <= 0 or (game.tick - last) >= throttle then
                                storage.repair_last_scan_tick[unit] = game.tick

                                local already_session = session_active(player.index, unit)
                                local can_start = (not already_session) and can_start_new_session(player.index)

                                if already_session or can_start then
                                    if not queue:get_hash(entity) then
                                        local pr = get_repair_priority(entity)
                                        if not (in_combat and cfg.repair_combat_important_only) or pr <= 40 then
                                            list[#list + 1] = {
                                                entity = entity,
                                                unit = unit,
                                                pr = pr,
                                                ratio = ratio_e,
                                                start_new = (not already_session)
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            lua_table_sort(list, function(a, b)
                if a.pr ~= b.pr then return a.pr < b.pr end
                return a.ratio < b.ratio
            end)

            for i = 1, #list do
                if queue_count() >= cfg.queue_cycle then break end
                if not (nano_ammo.valid and nano_ammo.valid_for_read) then break end

                local rec = list[i]
                local entity = rec.entity
                if not (entity and entity.valid) then goto continue_repair_loop end
                if queue:get_hash(entity) then goto continue_repair_loop end

                if rec.start_new then
                    if not can_start_new_session(player.index) then break end
                    local data = {
                        player_index = player.index,
                        ammo = nano_ammo,
                        position = entity.position,
                        surface = entity.surface,
                        unit_number = rec.unit,
                        entity = entity,
                        action = 'repair',
                        repair_shot = true
                    }
                    queue:insert(data, next_tick())
                    ammo_drain(player, nano_ammo, 1)
                    start_session(player.index, rec.unit)
                else
                    local data = {
                        player_index = player.index,
                        ammo = nano_ammo,
                        position = entity.position,
                        surface = entity.surface,
                        unit_number = rec.unit,
                        entity = entity,
                        action = 'repair',
                        repair_shot = false
                    }
                    queue:insert(data, next_tick())
                end

                ::continue_repair_loop::
            end
        end
    end

    -- Ghosts/deconstruct/upgrades scan (FIXED invalid access)
    for _, ghost in pairs(player.surface.find_entities(area)) do
        if not (ghost and ghost.valid) then
            goto continue_ghost_loop
        end

        local same_force = ghost.force == force
        local deconstruct = ghost.to_be_deconstructed()
        local upgrade = ghost.to_be_upgraded() and ghost.force == force

        if not (deconstruct or upgrade or same_force) then
            goto continue_ghost_loop
        end

        -- log only after valid check
        nlog_agg("Сканирование призраков", ghost.name)

        if not (nano_ammo.valid and nano_ammo.valid_for_read) then
            break
        end

        if cfg.network_limits and not nano_network_check(player.character, ghost) then
            goto continue_ghost_loop
        end

        if queue_count() >= cfg.queue_cycle then
            break
        end

        if queue:get_hash(ghost) then
            goto continue_ghost_loop
        end

        local data = {
            player_index = player.index,
            ammo        = nano_ammo,
            position    = ghost.position,
            surface     = ghost.surface,
            unit_number = ghost.unit_number,
            entity      = ghost
        }

        if ghost.name == 'item-request-proxy' and cfg.do_proxies then
            data.action = 'item_requests'
            data.target = ghost.proxy_target
            queue:insert(data, next_tick())
            ammo_drain(player, nano_ammo, 1)
            goto continue_ghost_loop
        end

        if deconstruct then
            if ghost.type == 'cliff' then
                if player.force.technologies['nanobots-cliff'].researched then
                    local item_stack = local_find_item(explosives, player, false)
                    if item_stack then
                        local explosive = get_items_from_inv(player, item_stack, player.cheat_mode)
                        if explosive then
                            data.item_stack = explosive
                            data.action = 'cliff_deconstruction'
                            queue:insert(data, next_tick())
                            ammo_drain(player, nano_ammo, 1)
                        end
                    end
                end
            elseif ghost.minable then
                data.action = 'deconstruction'
                data.deconstructors = true
                queue:insert(data, next_tick())
                ammo_drain(player, nano_ammo, 1)
            end
        elseif upgrade then
            local prototype = ghost.get_upgrade_target()
            if prototype then
                if prototype.name == ghost.name then
                    local dir = ghost.get_upgrade_direction()
                    if ghost.direction ~= dir then
                        data.action = 'upgrade_direction'
                        data.direction = dir
                        queue:insert(data, next_tick())
                        ammo_drain(player, nano_ammo, 1)
                    end
                else
                    local item_stack = local_find_item(prototype.items_to_place_this, player, false)
                    if item_stack then
                        data.action = 'upgrade_ghost'
                        local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                        if place_item then
                            data.entity_name = prototype.name
                            data.item_stack = place_item
                            queue:insert(data, next_tick())
                            ammo_drain(player, nano_ammo, 1)
                        end
                    end
                end
            end
        elseif ghost.name == 'entity-ghost' or (ghost.name == 'tile-ghost' and cfg.build_tiles) then
            local proto = ghost.ghost_prototype
            local item_stack = local_find_item(proto.items_to_place_this, player, false)
            if item_stack then
                if ghost.name == 'entity-ghost' then
                    local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                    if place_item then
                        data.action = 'build_entity_ghost'
                        data.entity_name = proto.name
                        data.item_stack = place_item
                        queue:insert(data, next_tick())
                        ammo_drain(player, nano_ammo, 1)
                    end
                elseif ghost.name == 'tile-ghost' then
                    local tile = ghost.surface.get_tile(ghost.position)
                    if tile then
                        local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                        if place_item then
                            data.item_stack = place_item
                            data.action = 'build_tile_ghost'
                            queue:insert(data, next_tick())
                            ammo_drain(player, nano_ammo, 1)
                        end
                    end
                end
            end
        end

        ::continue_ghost_loop::
    end

    pdata._next_nano_tick = next_tick() or game.tick
end

-- on_tick
local function poll_players(event)
    flush_aggregated_messages()

    if event.tick % max(1, floor(cfg.poll_rate / #game.connected_players)) == 0 then
        local last_player, player = next(game.connected_players, storage._last_player)
        if player and is_connected_player_ready(player) then
            if cfg.nanobots_auto and (not cfg.network_limits or nano_network_check(player.character)) then
                local gun, nano_ammo, ammo_name = get_gun_ammo_name(player, 'gun-nano-emitter')
                if gun then
                    if ammo_name == 'ammo-nano-constructors' then
                        queue_ghosts_in_range(player, player.character.position, nano_ammo)
                    elseif ammo_name == 'ammo-nano-termites' then
                        everyone_hates_trees(player, player.character.position, nano_ammo)
                    end
                end
            end
            if cfg.equipment_auto then
                armormods.prepare_chips(player)
            end
        end
        storage._last_player = last_player
    end

    queue:execute(event)
    process_pending_repairs()

    if event.tick % 60 == 0 then
        cleanup_sessions_all()
    end
end

script.on_event(defines.events.on_tick, poll_players)

local function players_changed()
    storage._last_player = nil
end

script.on_event({ defines.events.on_player_joined_game, defines.events.on_player_left_game }, players_changed)

-- init/load/reset
local function on_nano_init()
    storage.players = storage.players or {}
    storage.repair_sessions = storage.repair_sessions or {}
    storage.repair_last_scan_tick = storage.repair_last_scan_tick or {}
    storage.nano_repair_pending = storage.nano_repair_pending or {}

    storage.nano_queue = Queue()
    queue = storage.nano_queue

    nlog("🤖 Nanobots initialized")
end

script.on_init(on_nano_init)

local function on_nano_load()
    queue = Queue(storage.nano_queue)
end

script.on_load(on_nano_load)

local function reset_nano_queue()
    storage.nano_queue = nil
    queue = nil
    storage.nano_queue = Queue()
    queue = storage.nano_queue
    storage.nano_repair_pending = {}
    storage.repair_last_scan_tick = storage.repair_last_scan_tick or {}

    if storage.players then
        for _, p in pairs(storage.players) do
            if type(p) == "table" then
                p._next_nano_tick = 0
            end
        end
    end
end

script.on_event(Event.generate_event_name('reset_nano_queue'), reset_nano_queue)
