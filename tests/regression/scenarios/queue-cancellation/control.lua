script.on_event(defines.events.on_tick,function(e)
 local p=game.get_player(1)
 if not p then return end
 if storage.start and p.controller_type==defines.controllers.remote and script.test_arg=='far' then p.teleport({6000,6000},p.character.surface) end
 if not storage.start then
  storage.start=e.tick
  if not p.character then p.create_character() end
  p.force.research_all_technologies()
  local s=p.character.surface
  s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
  for _,ent in pairs(s.find_entities_filtered{area={{-12,-12},{12,12}},type={'tree','simple-entity'}}) do ent.destroy() end
  p.teleport({0,0})
  p.get_inventory(defines.inventory.character_guns)[1].set_stack{name='gun-nano-emitter',count=1}
  p.get_inventory(defines.inventory.character_ammo)[1].set_stack{name='ammo-nano-constructors',count=100}
  p.insert{name='iron-chest',count=10}
  local target=s.create_entity{name='entity-ghost',inner_name='iron-chest',position={3,0},force=p.force}
  storage.ghost=target
  local camera=script.test_arg=='near' and {0,0} or {6000,6000}
  p.set_controller{type=defines.controllers.remote,position=camera,surface=s}
  p.teleport(camera,s)
  log('MAP '..script.test_arg..' camera='..helpers.table_to_json(p.position)..' phys='..helpers.table_to_json(p.physical_position)..' player_count='..p.get_item_count('iron-chest')..' character_count='..p.character.get_item_count('iron-chest'))
 elseif script.test_arg == 'cancel' and storage.ghost.valid and p.character.get_item_count('iron-chest') == 9 then
  storage.ghost.destroy()
  storage.cancelled=true
 elseif e.tick-storage.start==180 then
  log('MAP RESULT '..script.test_arg..' ghost='..tostring(storage.ghost.valid)..' character_count='..p.character.get_item_count('iron-chest'))
  assert(not storage.ghost.valid,'ghost was not built')
  local ammo=p.character.get_inventory(defines.inventory.character_ammo)[1]
  if script.test_arg=='cancel' then
   assert(storage.cancelled and p.character.get_item_count('iron-chest')==10,'material was not refunded')
   assert(ammo.count==100 and ammo.ammo==ammo.prototype.magazine_size,'cancelled construction used charge')
  else
   assert(p.character.get_item_count('iron-chest')==9,'wrong material count')
  end
  script.finish_test(true)
 end
end)



