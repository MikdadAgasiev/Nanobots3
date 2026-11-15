script.on_event(defines.events.on_tick, function(event)
    local player = game.get_player(1)
    if not player then return end
    local mode = assert(script.test_arg, 'test mode is required')
    if not storage.start then
        storage.start = event.tick
        if not player.character then player.create_character() end
        player.force.research_all_technologies()
        local surface = player.character.surface
        surface.request_to_generate_chunks({0,0}, 2)
        surface.force_generate_chunk_requests()
        for _, entity in pairs(surface.find_entities_filtered{area={{-16,-16},{16,16}},type={'tree','simple-entity'}}) do entity.destroy() end
        local tiles = {}
        for x=-16,16 do for y=-16,16 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
        surface.set_tiles(tiles, true)
        player.teleport({0,0})
        player.character.get_main_inventory().clear()
        player.get_inventory(defines.inventory.character_guns)[1].set_stack{name='gun-nano-emitter',count=1}
        player.get_inventory(defines.inventory.character_ammo)[1].set_stack{name='ammo-nano-constructors',count=100}

        storage.cheat_test = mode:find('cheat-',1,true) == 1
        player.cheat_mode = mode:find('-off',1,true) ~= nil
        storage.item = (mode == 'quality-upgrade-type' or mode == 'quality-retarget') and 'fast-transport-belt' or 'iron-chest'
        storage.quality = storage.cheat_test and 'normal' or 'epic'
        if mode ~= 'quality-wrong' then player.insert{name=storage.item,count=2,quality=storage.quality} end
        if mode == 'quality-mixed' or mode == 'quality-wrong' or mode == 'quality-retarget' then
            player.insert{name=storage.item,count=1,quality='normal'}
        end
        if mode:find('upgrade',1,true) or mode == 'quality-retarget' then
            local name = storage.item == 'fast-transport-belt' and 'transport-belt' or 'iron-chest'
            storage.target = assert(surface.create_entity{name=name,position={4.5,0.5},force=player.force})
            assert(storage.target.order_upgrade{force=player.force,target={name=storage.item,quality='epic'}})
        else
            storage.target = assert(surface.create_entity{name='entity-ghost',inner_name=storage.item,quality=storage.quality,position={4.5,0.5},force=player.force})
        end
        if mode == 'quality-matrix' then
            storage.target.destroy()
            player.character.get_main_inventory().clear()
            storage.qualities = {'normal','uncommon','rare','epic','legendary'}
            for i, quality in ipairs(storage.qualities) do
                player.insert{name='iron-chest',count=2,quality=quality}
                assert(surface.create_entity{name='entity-ghost',inner_name='iron-chest',quality=quality,position={i+1.5,3.5},force=player.force})
            end
        elseif mode == 'quality-vehicle-remote' then
            player.character.get_main_inventory().clear()
            storage.car = assert(surface.create_entity{name='car',position={0,0},force=player.force})
            storage.car.set_driver(player)
            storage.car.insert{name='iron-chest',count=2,quality='epic'}
            player.set_controller{type=defines.controllers.remote,surface=surface,position={500,500}}
        end
    elseif not storage.triggered and (storage.cheat_test or mode == 'quality-retarget') and remote.call('item_safety_test','pending',player.index) then
        storage.triggered = true
        if mode == 'quality-retarget' then
            assert(storage.target.order_upgrade{force=player.force,target={name=storage.item,quality='legendary'}})
        else
            player.cheat_mode = not player.cheat_mode
            storage.target.destroy()
            if mode:find('-reset-',1,true) then remote.call('Nanobots3','reset_queue') end
        end
    elseif event.tick-storage.start == 240 then
        local surface = player.character.surface
        if mode == 'quality-matrix' then
            for i, quality in ipairs(storage.qualities) do
                assert(surface.find_entity({name='iron-chest',quality=quality},{i+1.5,3.5}), 'missing '..quality..' construction')
                assert(player.character.get_item_count{name='iron-chest',quality=quality} == 1, 'wrong '..quality..' material count')
            end
            log('QUALITY CONSTRUCTION PASSED: '..mode)
            script.finish_test(true)
            return
        end
        local ammo = player.character.get_inventory(defines.inventory.character_ammo)[1]
        local expected = 1
        if storage.cheat_test then
            assert(storage.triggered, 'no queued construction to cancel')
            expected = 2
        elseif mode == 'quality-wrong' then
            assert(storage.target.valid, 'built using the wrong quality')
            assert(player.character.get_item_count{name=storage.item,quality='normal'} == 1, 'wrong-quality item was consumed')
            expected = 0
        elseif mode == 'quality-retarget' then
            assert(storage.triggered and storage.target.valid and storage.target.quality.name == 'normal', 'retargeting upgraded with the wrong reserved quality')
            expected = 2
        else
            local built = surface.find_entity({name=storage.item,quality='epic'},{4.5,0.5})
            log('QUALITY RESULT '..mode..' ghost='..tostring(storage.target.valid)..' built='..tostring(built and built.quality.name)..' reserved='..tostring(player.character.get_item_count{name=storage.item,quality=storage.quality}))
            assert(built and built.quality.name == 'epic', 'quality construction or upgrade did not complete')
            if mode == 'quality-mixed' then
                assert(player.character.get_item_count{name=storage.item,quality='normal'} == 1, 'normal item was consumed')
            end
        end
        local material_owner = storage.car or player.character
        assert(material_owner.get_item_count{name=storage.item,quality=storage.quality} == expected, 'reserved items were lost, duplicated or not used')
        if storage.cheat_test or mode == 'quality-wrong' or mode == 'quality-retarget' then
            assert(ammo.count == 100 and ammo.ammo == ammo.prototype.magazine_size, 'cancelled task spent ammunition')
        end
        log('QUALITY CONSTRUCTION PASSED: '..mode)
        script.finish_test(true)
    end
end)
