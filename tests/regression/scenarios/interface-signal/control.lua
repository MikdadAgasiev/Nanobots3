script.on_event(defines.events.on_tick, function(event)
    local player = game.get_player(1)
    if not player then return end
    if not storage.start then
        storage.start = event.tick
        if not player.character then player.create_character() end
        local surface = player.surface
        surface.request_to_generate_chunks({0,0},2)
        surface.force_generate_chunk_requests()
        -- Randomly generated enemies intentionally block interface cleanup;
        -- other trees can consume its per-scan target budget.
        for _, entity in pairs(surface.find_entities_filtered{type={'tree','simple-entity'}}) do entity.destroy() end
        for _, entity in pairs(surface.find_entities_filtered{force='enemy'}) do entity.destroy() end
        surface.set_tiles{{name='grass-1',position={0,0}}}
        local port = assert(surface.create_entity{name='roboport-interface-main', position={0,0}, force=player.force, raise_built=true})
        storage.real_port=assert(surface.create_entity{name='roboport',position={5,5},force=player.force})
        storage.real_port.get_inventory(defines.inventory.roboport_robot).insert{name='construction-robot', count=10}
        storage.port = port
        local control=assert(surface.find_entity('roboport-interface-cc',{0,0})).get_or_create_control_behavior()
        local section=control.get_section(1) or control.add_section()
        section.set_slot(1,{value={type='virtual',name='nano-signal-chop-trees',quality='normal'},min=1})
        storage.tree=assert(surface.create_entity{name='tree-01',position={8,0},force='neutral'})
        storage.scanner=assert(surface.find_entity('roboport-interface-scanner',{0,0}))
    end
    storage.real_port.energy=storage.real_port.electric_buffer_size
    storage.port.energy=storage.port.electric_buffer_size
    storage.scanner.energy=storage.scanner.electric_buffer_size
    if event.tick-storage.start==120 then
        remote.call('interface_test','run',assert(storage.port.surface.find_entity('roboport-interface-cc',storage.port.position)))
    elseif event.tick-storage.start==600 then
        assert(not storage.tree.valid or storage.tree.to_be_deconstructed(player.force),'signal did not mark the tree')
        log('INTERFACE SIGNAL PASSED')
        script.finish_test(true)
    end
end)

