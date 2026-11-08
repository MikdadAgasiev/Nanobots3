-- Native recipe edits (no stdlib2) for pypostprocessing compatibility.
-- stdlib2's Recipe wrapper leaves function-carrying metatables on prototypes,
-- which mods that serialise data.raw (e.g. pypostprocessing) cannot handle.

require('prototypes/technology/shortcuts')

if not settings.startup['nanobots-legacy-research-prerequisites'].value then
    for _, branch in ipairs({'nano-speed-', 'nano-range-'}) do
        for level = 2, 4 do
            local technology = data.raw.technology[branch .. level]
            technology.prerequisites = {branch .. (level - 1)}
            if level == 2 then
                technology.prerequisites[2] = 'logistic-science-pack'
                technology.unit.count = 150
            end
        end
    end
end

-- bobmods recipe changes
if mods['boblibrary'] then

    -- Does an item prototype exist under any common item subtype?
    -- Some prototype tables may be absent entirely in a given mod setup,
    -- so every data.raw lookup must be guarded before indexing it.
    local ITEM_PROTOTYPE_TYPES = {
        'item',
        'item-with-entity-data',
        'tool',
        'ammo',
        'capsule',
        'gun',
        'module'
    }

    local function item_exists(name)
        for _, prototype_type in ipairs(ITEM_PROTOTYPE_TYPES) do
            local prototypes = data.raw[prototype_type]
            if prototypes and prototypes[name] then
                return true
            end
        end
        return false
    end

    -- Replace an ingredient in place, only if the recipe and the new item exist.
    local function safe_replace(recipe_name, old_ing, new_ing)
        local recipe = data.raw['recipe'][recipe_name]
        if not recipe or not item_exists(new_ing) then return end
        if not recipe.ingredients then return end
        for _, ing in pairs(recipe.ingredients) do
            -- Ingredients are tables ({type, name, amount}) in 2.0; guard anyway.
            if type(ing) == 'table' and ing.name == old_ing then
                ing.name = new_ing
            end
        end
    end

    -- Add an ingredient if the recipe and the item exist and it's not already present.
    local function safe_add(recipe_name, ing_name, amount)
        local recipe = data.raw['recipe'][recipe_name]
        if not recipe or not item_exists(ing_name) then return end
        recipe.ingredients = recipe.ingredients or {}
        for _, ing in pairs(recipe.ingredients) do
            if type(ing) == 'table' and ing.name == ing_name then
                return -- already present
            end
        end
        recipe.ingredients[#recipe.ingredients + 1] =
            {type = 'item', name = ing_name, amount = amount or 1}
    end

    local key = 'bobmods-logistics-disableroboports'
    if settings["startup"][key] and settings["startup"][key].value then
        safe_replace('roboport-interface', 'roboport', 'bob-logistic-zone-expander')
    end
    safe_replace('gun-nano-emitter', 'electronic-circuit', 'basic-circuit-board')
    safe_replace('ammo-nano-constructors', 'electronic-circuit', 'basic-circuit-board')
    safe_replace('ammo-nano-termites', 'electronic-circuit', 'basic-circuit-board')

    safe_add('equipment-bot-chip-items', 'robot-brain-construction')
    safe_add('equipment-bot-chip-trees', 'robot-brain-construction')
    safe_add('equipment-bot-chip-nanointerface', 'robot-brain-construction')
    safe_add('equipment-bot-chip-nanointerface', 'gun-nano-emitter')
    safe_add('equipment-bot-chip-launcher', 'robot-brain-combat')
    safe_add('equipment-bot-chip-feeder', 'robot-brain-combat')
end
