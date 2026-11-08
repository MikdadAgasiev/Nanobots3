"""Run real Factorio scenarios against an isolated copy of the supplied mod source."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('--factorio', type=Path, default=Path(r'C:\Program Files (x86)\Steam\steamapps\common\Factorio\bin\x64\factorio.exe'))
parser.add_argument('--only', nargs='*')
args = parser.parse_args()
here = Path(__file__).resolve().parent
hooks = '''
-- Test-only access to the production helpers; never included in the release.
remote.add_interface('item_safety_test', {
    collect = get_all_items_on_ground,
    insert = insert_into_entity,
    refund = function(index, stacks) insert_or_spill_items(game.get_player(index), stacks) end,
    reset = reset_nano_queue,
    reserve = function(index)
        local player = game.get_player(index)
        for _, count in ipairs{1,2} do
            local stack = assert(get_items_from_inv(player, {name='iron-chest',count=count,quality='epic'}, player.cheat_mode))
            queue:insert({player_index=index, item_stack=stack, action='build_entity_ghost', entity=player.character, surface=player.character.surface, position=player.character.position}, game.tick+600+count)
        end
    end
})
'''
cases = [(mode, 'item-safety', mode, 30) for mode in ['ground','held','overflow','reset','reset-remote','reset-cheat','reset-full']]
cases += [('cancel','queue-cancellation','cancel',240),('demolition','map-demolition','remote',300),('interface','interface-signal','signal',700),('dense-repair','dense-repair','far',1000)]
if args.only:
    cases = [case for case in cases if case[0] in args.only]
results = here / 'results'
results.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='nanobots-tests-') as temporary:
    root = Path(temporary)
    info = json.loads((args.source/'info.json').read_text(encoding='utf-8-sig'))
    mod = root / 'mods' / (info['name']+'_'+info['version'])
    shutil.copytree(args.source, mod, ignore=shutil.ignore_patterns('.git','results','__pycache__'))
    nano = mod / 'scripts' / 'nanobots.lua'
    nano.write_text(nano.read_text(encoding='utf-8-sig') + hooks, encoding='utf-8')
    interface = mod / 'scripts' / 'roboport-interface.lua'
    interface.write_text(interface.read_text(encoding='utf-8-sig') + "\nremote.add_interface('interface_test', {run = run_interface})\n", encoding='utf-8')
    (root/'mods'/'mod-list.json').write_text('{"mods":[{"name":"base","enabled":true},{"name":"quality","enabled":true},{"name":"Nanobots3","enabled":true}]}')
    for _, scenario, _, _ in cases:
        source = here / 'scenarios' / scenario
        shutil.copytree(source, root/'runtime'/'scenarios'/scenario, dirs_exist_ok=True)
    config = root/'config.ini'
    config.write_text('[path]\nread-data='+str(args.factorio.parent.parent.parent/'data').replace('\\','/')+'\nwrite-data='+str(root/'runtime').replace('\\','/')+'\n[other]\ncheck-updates=false\n',encoding='utf-8')
    failures = []
    for name, scenario, mode, ticks in cases:
        command = [str(args.factorio),'--config',str(config),'--mod-directory',str(root/'mods'),'--test-scenario',scenario,'--test-arg',mode,'--test-ticks',str(ticks)]
        run = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0, timeout=90)
        (results/(name+'.log')).write_bytes(run.stdout)
        passed = run.returncode == 0 and b'Test passed at tick' in run.stdout
        print(name+': '+('PASS' if passed else 'FAIL'), flush=True)
        if not passed:
            failures.append(name)
            print(run.stdout.decode('utf-8',errors='replace')[-2200:], flush=True)
    raise SystemExit(bool(failures))
