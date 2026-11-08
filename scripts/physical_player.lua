local function get_physical_character(player)
    if not (player and player.valid) then return nil end
    local character = player.character
    if character and character.valid then return character end
    return nil
end

local function get_physical_vehicle(player)
    if not (player and player.valid) then return nil end
    local ok, vehicle = pcall(function() return player.physical_vehicle end)
    if ok and vehicle and vehicle.valid then return vehicle end
    ok, vehicle = pcall(function() return player.vehicle end)
    if ok and vehicle and vehicle.valid then return vehicle end
    return nil
end

local function get_physical_surface(player)
    if not (player and player.valid) then return nil end
    local ok, surface = pcall(function() return player.physical_surface end)
    if ok and surface and surface.valid then return surface end
    local character = get_physical_character(player)
    return character and character.surface or nil
end

local function get_physical_position(player)
    if not (player and player.valid) then return nil end
    local ok, position = pcall(function() return player.physical_position end)
    if ok and position then return position end
    local character = get_physical_character(player)
    return character and character.position or nil
end

local function is_remote_view(player)
    if not (player and player.valid) then return false end
    local ok, controller_type = pcall(function() return player.controller_type end)
    return ok and defines.controllers and controller_type == defines.controllers.remote
end

return {
    get_physical_character = get_physical_character,
    get_physical_vehicle = get_physical_vehicle,
    get_physical_surface = get_physical_surface,
    get_physical_position = get_physical_position,
    is_remote_view = is_remote_view,
}
