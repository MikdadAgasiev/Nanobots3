-- Native implementation (no stdlib2) for pypostprocessing compatibility.
-- stdlib2's Data wrapper leaves function-carrying metatables on prototypes,
-- which mods that serialise data.raw (e.g. pypostprocessing) cannot handle.
local util = require('util')

local function make_shortcut(chip)
    if mods['PickerInventoryTools'] then
        -- Plain-table copy of the equipment prototype, renamed and relabelled.
        local disabled = util.table.deepcopy(chip)
        disabled.name = 'picker-disabled-' .. chip.name
        disabled.localised_name = {
            'nano-disabled-equipment.disabled',
            chip.localised_name or {'equipment-name.' .. chip.name}
        }
        data:extend{disabled}

        data:extend{
            {
                type = 'shortcut',
                name = 'toggle-' .. chip.name,
                order = 'c[toggles]-z[' .. chip.name .. ']',
                action = 'lua',
                toggleable = true,
                localised_name = {'shortcut.toggle-' .. chip.name},
                associated_control_input = nil,
                technology_to_unlock = 'personal-roboport-equipment',
                icon = {
                    filename = chip.sprite.filename,
                    priority = 'extra-high-no-scale',
                    size = 32,
                    scale = 1,
                    mipmap_count = 0,
                    flags = {'gui-icon'}
                }
            }
        }
    end
end

return make_shortcut
