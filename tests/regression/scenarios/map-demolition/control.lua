script.on_event(defines.events.on_tick, function(e)
    local p = game.get_player(1)
    if not p then return end
    if not storage.start then
        storage.start = e.tick
        if not p.character then p.create_character() end
        p.force.research_all_technologies()
        local c = p.character
        local s = c.surface
        s.request_to_generate_chunks({0, 0}, 2)
        s.force_generate_chunk_requests()
        for _, ent in pairs(s.find_entities_filtered{area={{-12,-12},{12,12}},type={'tree','simple-entity'}}) do ent.destroy() end
        p.teleport({0,0})
        c.get_inventory(defines.inventory.character_guns)[1].set_stack{name='gun-nano-emitter',count=1}
        c.get_inventory(defines.inventory.character_ammo)[1].set_stack{name='ammo-nano-constructors',count=100}
        local inv = c.get_main_inventory()
        inv.clear()
        if script.test_arg == 'full' then
            for i=1,#inv do inv[i].set_stack{name='iron-plate', count=100} end
        end
        storage.target=s.create_entity{name='iron-chest',position={4.5,0.5},force=p.force}
        assert(storage.target.order_deconstruction(p.force))
        storage.initial_count=c.get_inventory(defines.inventory.character_ammo)[1].ammo
        if script.test_arg ~= 'normal' then
            p.set_controller{type=defines.controllers.remote,surface=s,position={500,500}}
        end
    end
    local c=p.character
    if script.test_arg ~= 'normal' then p.teleport({500,500}, c.surface) end
    if e.tick-storage.start == 240 then
        local ammo=c.get_inventory(defines.inventory.character_ammo)[1]
        local spent=storage.initial_count-ammo.ammo
        local returned=c.get_item_count('iron-chest')
        log('DEMOLITION '..script.test_arg..' target='..tostring(storage.target.valid)..' spent='..spent..' returned='..returned)
        if script.test_arg == 'full' then
            assert(storage.target.valid and spent==0 and returned==0)
        else
            assert(not storage.target.valid and spent==1 and returned==1)
        end
        script.finish_test(true)
    end
end)
