
-- ================================================================
-- UNIVERSAL MOOSE SPAWNER UTILITY MENU
-- ================================================================
-- Allows spawning any group template (fighter, cargo, etc.) at any airbase
-- for either coalition, with options for cold/hot/runway start.
-- Includes cleanup and status commands.
-- ================================================================

-- List of available airbases (Caucasus map, add/remove as needed)
local AIRBASES = {
    "Kutaisi", "Senaki-Kolkhi", "Sukhumi-Babushara", "Gudauta", "Sochi-Adler",
    "Krymsk", "Anapa-Vityazevo", "Krasnodar-Pashkovsky", "Mineralnye Vody",
    "Nalchik", "Mozdok", "Beslan"
}

-- List of example templates (add your own as needed)
local TEMPLATES = {
    "CARGO", "CARGO_RU", "Kutaisi CAP", "Sukhumi CAP", "Batumi CAP", "Gudauta CAP"
    -- Add more fighter/cargo templates here
}

-- Coalition options
local COALITIONS = {
    {name = "Blue", side = coalition.side.BLUE},
    {name = "Red", side = coalition.side.RED}
}

-- Start types
local START_TYPES = {
    {name = "Cold Start", value = SPAWN.Takeoff.Cold},
    {name = "Hot Start", value = SPAWN.Takeoff.Hot},
    {name = "Runway", value = SPAWN.Takeoff.Runway}
}

-- Track spawned groups for cleanup
local spawnedGroups = {}

-- Utility: Add group to cleanup tracking
local function TrackGroup(group)
    if group and group:IsAlive() then
        table.insert(spawnedGroups, group)
    end
end

-- Utility: Cleanup all spawned groups
local function CleanupAll()
    local cleaned = 0
    for _, group in ipairs(spawnedGroups) do
        if group and group:IsAlive() then
            group:Destroy()
            cleaned = cleaned + 1
        end
    end
    spawnedGroups = {}
    MESSAGE:New("Cleaned up " .. cleaned .. " spawned groups", 10):ToAll()
end

-- Utility: Show status of spawned groups
local function ShowStatus()
    local alive = 0
    for _, group in ipairs(spawnedGroups) do
        if group and group:IsAlive() then alive = alive + 1 end
    end
    MESSAGE:New("Spawner Status:\nAlive groups: " .. alive .. "\nTotal spawned: " .. #spawnedGroups, 15):ToAll()
end

-- Main menu
local MenuRoot = MENU_MISSION:New("Universal Spawner")

-- Submenus for coalition
local MenuBlue = MENU_MISSION:New("Spawn for BLUE", MenuRoot)
local MenuRed = MENU_MISSION:New("Spawn for RED", MenuRoot)

-- For each coalition, create template/airbase/start type menus
for _, coalitionData in ipairs(COALITIONS) do
    local menuCoalition = (coalitionData.side == coalition.side.BLUE) and MenuBlue or MenuRed

    for _, templateName in ipairs(TEMPLATES) do
        local menuTemplate = MENU_MISSION:New("Template: " .. templateName, menuCoalition)

        for _, airbaseName in ipairs(AIRBASES) do
            local menuAirbase = MENU_MISSION:New("Airbase: " .. airbaseName, menuTemplate)

            for _, startType in ipairs(START_TYPES) do
                local menuStartType = MENU_MISSION:New(startType.name, menuAirbase)
                for numToSpawn = 1, 5 do
                    MENU_MISSION_COMMAND:New(
                        "Spawn " .. numToSpawn,
                        menuStartType,
                        function()
                            local airbase = AIRBASE:FindByName(airbaseName)
                            if not airbase then
                                MESSAGE:New("Airbase not found: " .. airbaseName, 10):ToAll()
                                return
                            end
                            local spawnObj = SPAWN:New(templateName)
                            spawnObj:InitLimit(10, 20)
                            local spawned = 0
                            for i = 1, numToSpawn do
                                local group = spawnObj:SpawnAtAirbase(airbase, startType.value)
                                if group then
                                    TrackGroup(group)
                                    spawned = spawned + 1
                                end
                            end
                            if spawned > 0 then
                                MESSAGE:New("Spawned " .. spawned .. " '" .. templateName .. "' at " .. airbaseName .. " (" .. startType.name .. ")", 10):ToAll()
                            else
                                MESSAGE:New("Failed to spawn '" .. templateName .. "' at " .. airbaseName, 10):ToAll()
                            end
                        end
                    )
                end
            end
        end
    end
end

-- Quick spawn (first template, first airbase, cold start)
MENU_MISSION_COMMAND:New(
    "Quick Spawn (" .. TEMPLATES[1] .. ")",
    MenuRoot,
    function()
        local airbase = AIRBASE:FindByName(AIRBASES[1])
        local spawnObj = SPAWN:New(TEMPLATES[1])
        spawnObj:InitLimit(10, 20)
        local spawned = 0
        for i = 1, 1 do
            local group = spawnObj:SpawnAtAirbase(airbase, SPAWN.Takeoff.Cold)
            if group then
                TrackGroup(group)
                spawned = spawned + 1
            end
        end
        if spawned > 0 then
            MESSAGE:New("Quick spawned '" .. TEMPLATES[1] .. "' at " .. AIRBASES[1], 10):ToAll()
        else
            MESSAGE:New("Failed to quick spawn '" .. TEMPLATES[1] .. "' at " .. AIRBASES[1], 10):ToAll()
        end
    end
)

-- Status and cleanup commands
MENU_MISSION_COMMAND:New("Show Spawner Status", MenuRoot, ShowStatus)
MENU_MISSION_COMMAND:New("Cleanup All Spawned Groups", MenuRoot, CleanupAll)

-- ================================================================
-- CONFIGURATION
-- ================================================================

-- Menu configuration
local MENU_CONFIG = {
    rootMenuText = "CARGO OPERATIONS",
    coalitionSide = coalition.side.BLUE,  -- Change to RED if needed
    debugMode = true
}

-- Spawn configuration
local SPAWN_CONFIG = {
    templateName = "CARGO",              -- Template name in mission editor
    maxActive = 3,                       -- Maximum active aircraft
    maxSpawns = 10,                      -- Maximum total spawns
    cleanupTime = 300,                   -- Cleanup time in seconds (5 minutes)
    spawnAirbase = "Kutaisi",            -- Default spawn airbase
    takeoffType = SPAWN.Takeoff.Cold     -- Cold start by default
}

-- Available airbases for spawning (Caucasus map)
local AVAILABLE_AIRBASES = {
    "Kutaisi",
    "Senaki-Kolkhi", 
    "Sukhumi-Babushara",
    "Gudauta",
    "Sochi-Adler",
    "Krymsk",
    "Anapa-Vityazevo",
    "Krasnodar-Pashkovsky",
    "Mineralnye Vody",
    "Nalchik",
    "Mozdok",
    "Beslan"
}

-- ================================================================
-- GLOBAL VARIABLES
-- ================================================================

-- Spawn object
local CargoSpawn = nil

-- Menu objects
local MenuRoot = nil
local MenuSpawn = nil
