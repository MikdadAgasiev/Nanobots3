script.on_event(defines.events.on_tick, function()
    local player = game.get_player(1)
    if not player then return end
    if not player.character then player.create_character() end
    local surface = player.character.surface
    surface.request_to_generate_chunks({0,0}, 1)
    surface.force_generate_chunk_requests()
    local mode = script.test_arg
    if mode == 'reset' or mode == 'reset-remote' or mode == 'reset-cheat' or mode == 'reset-full' then
        player.character.get_main_inventory().clear()
        player.insert{name='iron-chest', count=10, quality='epic'}
        player.cheat_mode = mode == 'reset-cheat'
        if mode == 'reset-remote' or mode == 'reset-full' then
            player.set_controller{type=defines.controllers.remote, surface=surface, position={500,500}}
        end
        remote.call('item_safety_test', 'reserve', player.index)
        local expected = player.cheat_mode and 10 or 7
        assert(player.character.get_item_count{name='iron-chest',quality='epic'} == expected, 'reservation failed')
        if mode == 'reset-full' then
            local inventory = player.character.get_main_inventory()
            for i = 1, #inventory do inventory[i].set_stack{name='iron-plate',count=100} end
            local function returned()
                local count = 0
                for _, item in pairs(surface.find_entities_filtered{name='item-on-ground',position=player.character.position,radius=10}) do
                    if item.stack.name == 'iron-chest' and item.stack.quality.name == 'epic' then count = count + item.stack.count end
                end
                return count
            end
            remote.call('item_safety_test','reset')
            assert(returned() == 3, 'overflow refund not found beside the physical character')
            remote.call('item_safety_test','reset')
            assert(returned() == 3, 'second reset duplicated spilled items')
            log('ITEM SAFETY PASSED: '..mode)
            script.finish_test(true)
            return
        end
        remote.call('item_safety_test', 'reset')
        assert(player.character.get_item_count{name='iron-chest',quality='epic'} == 10, 'reset lost or duplicated reserved items')
        remote.call('item_safety_test', 'reset')
        assert(player.character.get_item_count{name='iron-chest',quality='epic'} == 10, 'second reset duplicated items')
    elseif mode == 'overflow' then
        local chest = assert(surface.create_entity{name='iron-chest',position={20,20},force=player.force})
        local inv = chest.get_inventory(defines.inventory.chest)
        inv.set_bar(2)
        inv[1].set_stack{name='iron-plate',count=99,quality='epic'}
        local remaining = remote.call('item_safety_test','insert',chest,{{name='iron-plate',count=3,quality='epic'}})
        assert(inv[1].count == 100 and #remaining == 1 and remaining[1].count == 2, 'partial insert count mismatch')
        assert(remaining[1].quality == 'epic', 'overflow lost quality')
    else
        local ghost = assert(surface.create_entity{name='entity-ghost',inner_name='iron-chest',position={20.5,20.5},force=player.force})
        if mode == 'ground' then
            surface.create_entity{name='item-on-ground',position=ghost.position,stack={name='iron-plate',count=3,quality='epic'}}
        elseif mode == 'held' then
            local inserter = assert(surface.create_entity{name='inserter',position={20.5,21.5},direction=defines.direction.north,force=player.force})
            inserter.held_stack.set_stack{name='iron-plate',count=3,quality='epic'}
            ghost.destroy()
            ghost = assert(surface.create_entity{name='entity-ghost',inner_name='assembling-machine-1',position=inserter.held_stack_position,force=player.force})
        else
            error('unknown test mode: '..tostring(mode))
        end
        local expected = mode == 'held' and 1 or 3
        local stacks = remote.call('item_safety_test','collect',ghost)
        assert(#stacks == 1 and stacks[1].count == expected, 'collection count mismatch')
        assert(stacks[1].quality == 'epic', 'collected items lost quality')
        player.character.get_main_inventory().clear()
        remote.call('item_safety_test','refund',player.index,stacks)
        assert(player.character.get_item_count{name='iron-plate',quality='epic'} == expected, 'refund lost quality')
        assert(player.character.get_item_count{name='iron-plate',quality='normal'} == 0, 'refund produced normal quality')
    end
    log('ITEM SAFETY PASSED: '..mode)
    script.finish_test(true)
end)
