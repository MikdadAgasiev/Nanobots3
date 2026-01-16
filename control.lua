-- Требуется для Factorio 2.0
local Interface = require('__stdlib2__/stdlib/scripts/interface').merge_interfaces(require('interface'))
local Commands = require('commands')

local ev = defines.events

-- Вместо Event.build_events используем script.on_event
script.on_event(ev.on_built_entity, function(event) 
  -- Обработка события на построение сущности
end)

script.on_event(ev.on_robot_built_entity, function(event) 
  -- Обработка события на построение роботом
end)

script.on_event(ev.script_raised_built, function(event) 
  -- Обработка события на построение через скрипт
end)

script.on_event(ev.script_raised_revive, function(event) 
  -- Обработка события на возрождение через скрипт
end)

script.on_event(ev.on_entity_cloned, function(event) 
  -- Обработка события на клонирование сущности
end)

-- Обработка событий на разрушение
script.on_event(ev.on_pre_player_mined_item, function(event) 
  -- Обработка события до разрушения игроком
end)

script.on_event(ev.on_robot_pre_mined, function(event) 
  -- Обработка события до разрушения роботом
end)

script.on_event(ev.script_raised_destroy, function(event) 
  -- Обработка события на разрушение через скрипт
end)

-- Регистрируем события для игрока и прочие интерфейсы
local Player = require('__stdlib2__/stdlib/event/player').register_events(true)
require('__stdlib2__/stdlib/event/force').register_events(true)
require('__stdlib2__/stdlib/event/changes').register_events('mod_versions', 'changes/versions')

Player.additional_data({ranges = {}})

-- Подключаем файлы с кодом
require('scripts/nanobots')
require('scripts/roboport-interface')
require('scripts/armor-mods')
require('scripts/reprogram-gui')
require('scripts/repair')

-- Интерфейс для команды
remote.add_interface(script.mod_name, Interface)

-- Добавление команд
commands.add_command(script.mod_name, 'Nanobot commands', Commands)
