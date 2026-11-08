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
  p.character.get_main_inventory().clear()
  s.set_tiles((function()
   local tiles={}
   for x=-16,16 do for y=-16,16 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
   return tiles
  end)(),true)
  for x=-15,14 do for y=-15,14 do
   if x*x+y*y>4 then s.create_entity{name='transport-belt',position={x+.5,y+.5},force=p.force} end
  end end
  local filter={area={{-15,-15},{15,15}},force=p.force,limit=400}
  local first={}
  for _,ent in pairs(s.find_entities_filtered(filter)) do if ent.unit_number then first[ent.unit_number]=true end end
  filter.limit=nil
  for _,ent in pairs(s.find_entities_filtered(filter)) do
   local pos=ent.position
   if ent.type=='transport-belt' and not first[ent.unit_number] and pos.x^2+pos.y^2<13^2 then
    storage.damaged=ent
    ent.health=20
    break
   end
  end
  assert(storage.damaged,'missing target beyond first 400')
  local camera=script.test_arg=='near' and {0,0} or {6000,6000}
  p.set_controller{type=defines.controllers.remote,position=camera,surface=s}
  p.teleport(camera,s)
  log('MAP '..script.test_arg..' camera='..helpers.table_to_json(p.position)..' phys='..helpers.table_to_json(p.physical_position)..' player_count='..p.get_item_count('iron-chest')..' character_count='..p.character.get_item_count('iron-chest'))
 elseif e.tick-storage.start==180 then
  log('DENSE REPAIR health='..storage.damaged.health)
  assert(storage.damaged.health>60,'repair target starved')
  assert(p.character.get_item_count('repair-pack')==0)
  script.finish_test(true)
 end
end)




