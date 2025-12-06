--[[
═══════════════════════════════════════════════════════════════════════════════
                Moose_TDAC_CargoDispatcher.lua
    Automated Logistics System for TADC Squadron Replenishment
═══════════════════════════════════════════════════════════════════════════════

DESCRIPTION:
    This script monitors RED and BLUE squadrons for low aircraft counts and automatically dispatches CARGO aircraft from a list of supply airfields to replenish them.
    It spawns cargo aircraft and routes them to destination airbases. Delivery detection and replenishment is handled by the main TADC system.

CONFIGURATION:
    - Update static templates and airfield lists as needed for your mission.
    - Set thresholds and supply airfields in CARGO_SUPPLY_CONFIG.
    - Replace static templates with actual group templates from the mission editor for realism.

REQUIRES:
    - MOOSE framework (for SPAWN, AIRBASE, etc.)

═══════════════════════════════════════════════════════════════════════════════
]]
---@diagnostic disable: undefined-global, lowercase-global
-- MOOSE framework globals are defined at runtime by DCS World
-- Single-run guard to prevent duplicate dispatcher loops if script is reloaded
if _G.__TDAC_DISPATCHER_RUNNING then
    env.info("[TDAC] CargoDispatcher already running; aborting duplicate load")
    return
end
_G.__TDAC_DISPATCHER_RUNNING = true

--[[
    CARGO SUPPLY CONFIGURATION
    --------------------------------------------------------------------------
    Set supply airfields, cargo template names, and resupply thresholds for each coalition.
]]
local CARGO_SUPPLY_CONFIG = {
    red = {
        supplyAirfields = { "Sochi-Adler", "Nalchik", "Beslan", "Maykop-Khanskaya" }, -- replace with your RED supply airbase names
        cargoTemplate = "CARGO_RED_AN26",    -- replace with your RED cargo aircraft template name
        threshold = 0.90                     -- ratio below which to trigger resupply (testing)
    },
    blue = {
        supplyAirfields = { "Batumi", "Kobuleti", "Senaki-Kolkhi", "Kutaisi", "Soganlug" }, -- replace with your BLUE supply airbase names
        cargoTemplate = "CARGO_BLUE_C130",   -- replace with your BLUE cargo aircraft template name
        threshold = 0.90                     -- ratio below which to trigger resupply (testing)
    }
}

--[[
    GLOBAL STATE AND CONFIGURATION
    --------------------------------------------------------------------------
    Tracks all active cargo missions and dispatcher configuration.
]]
if not cargoMissions then
    cargoMissions = { red = {}, blue = {} }
end

-- Dispatcher config (interval in seconds)
if not DISPATCHER_CONFIG then
    -- default interval (seconds) and a slightly larger grace period to account for slow servers/networks
    DISPATCHER_CONFIG = { interval = 60, gracePeriod = 25 }
end

-- Safety flag: when false, do NOT fall back to spawning from in-memory template tables.
-- Set to true if you understand the tweaked-template warning and accept the risk.
if DISPATCHER_CONFIG.ALLOW_FALLBACK_TO_INMEM_TEMPLATE == nil then
    DISPATCHER_CONFIG.ALLOW_FALLBACK_TO_INMEM_TEMPLATE = false
end





--[[
    UTILITY STUBS
    --------------------------------------------------------------------------
    selectRandomAirfield: Picks a random airfield from a list.
    announceToCoalition: Stub for in-game coalition messaging.
    Replace with your own logic as needed.
]]
if not selectRandomAirfield then
    function selectRandomAirfield(airfieldList)
        if type(airfieldList) == "table" and #airfieldList > 0 then
            return airfieldList[math.random(1, #airfieldList)]
        end
        return nil
    end
end

-- Stub for announceToCoalition (replace with your own logic if needed)
if not announceToCoalition then
    function announceToCoalition(coalitionKey, message)
        -- Replace with actual in-game message logic
        env.info("[ANNOUNCE] [" .. tostring(coalitionKey) .. "]: " .. tostring(message))
    end
end


--[[
    LOGGING
    --------------------------------------------------------------------------
    Advanced logging configuration and helper function for debug output.
]]
local ADVANCED_LOGGING = {
    enableDetailedLogging = false,
    logPrefix = "[TADC Cargo]"
}

-- Logging function (must be defined before any log() calls)
local function log(message, detailed)
    if not detailed or ADVANCED_LOGGING.enableDetailedLogging then
        env.info(ADVANCED_LOGGING.logPrefix .. " " .. message)
    end
end

log("═══════════════════════════════════════════════════════════════════════════════", true)
log("Moose_TDAC_CargoDispatcher.lua loaded.", true)
log("═══════════════════════════════════════════════════════════════════════════════", true)


-- Provide a safe deepCopy if MIST is not available
local function deepCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        if type(v) == 'table' then
            res[k] = deepCopy(v)
        else
            res[k] = v
        end
    end
    return res
end

-- Dispatch cooldown per airbase (seconds) to avoid repeated immediate retries
local CARGO_DISPATCH_COOLDOWN = DISPATCHER_CONFIG and DISPATCHER_CONFIG.cooldown or 300 -- default 5 minutes
local lastDispatchAttempt = { red = {}, blue = {} }

local function getCoalitionSide(coalitionKey)
    if coalitionKey == 'blue' then return coalition.side.BLUE end
    if coalitionKey == 'red' then return coalition.side.RED end
    return nil
end

-- Forward-declare parking check helper so functions defined earlier can call it
local destinationHasSuitableParking

-- Validate dispatcher configuration: check that supply airfields exist and templates appear valid
local function validateDispatcherConfig()
    local problems = {}

    -- Check supply airfields exist
    for coalitionKey, cfg in pairs(CARGO_SUPPLY_CONFIG) do
        if cfg and cfg.supplyAirfields and type(cfg.supplyAirfields) == 'table' then
            for _, abName in ipairs(cfg.supplyAirfields) do
                local ok, ab = pcall(function() return AIRBASE:FindByName(abName) end)
                if not ok or not ab then
                    table.insert(problems, string.format("Missing airbase for %s supply list: '%s'", tostring(coalitionKey), tostring(abName)))
                end
            end
        else
            table.insert(problems, string.format("Missing or invalid supplyAirfields for coalition '%s'", tostring(coalitionKey)))
        end

        -- Check cargo template presence (best-effort using SPAWN:New if available)
        if cfg and cfg.cargoTemplate and type(cfg.cargoTemplate) == 'string' and cfg.cargoTemplate ~= '' then
            local okSpawn, spawnObj = pcall(function() return SPAWN:New(cfg.cargoTemplate) end)
            if not okSpawn or not spawnObj then
                -- SPAWN:New may not be available at load time; warn but don't fail hard
                table.insert(problems, string.format("Cargo template suspicious or missing: '%s' (coalition: %s)", tostring(cfg.cargoTemplate), tostring(coalitionKey)))
            end
        else
            table.insert(problems, string.format("Missing cargoTemplate for coalition '%s'", tostring(coalitionKey)))
        end
    end

    if #problems == 0 then
        log("TDAC Dispatcher config validation passed ✓", true)
        MESSAGE:New("TDAC Dispatcher config validation passed ✓", 15):ToAll()
        return true, {}
    else
        log("TDAC Dispatcher config validation found issues:", true)
        MESSAGE:New("TDAC Dispatcher config validation found issues:" .. table.concat(problems, ", "), 15):ToAll()
        for _, p in ipairs(problems) do
            log("  ✗ " .. p, true)
        end
        return false, problems
    end
end

-- Expose console helper to run the check manually
function _G.TDAC_RunConfigCheck()
    local ok, problems = validateDispatcherConfig()
    if ok then
        return true, "OK"
    else
        return false, problems
    end
end



--[[
    getSquadronStatus(squadron, coalitionKey)
    --------------------------------------------------------------------------
    Returns the current, max, and ratio of aircraft for a squadron.
    If you track current aircraft in a table, update this logic accordingly.
    Returns: currentCount, maxCount, ratio
]]
local function getSquadronStatus(squadron, coalitionKey)
    local current = squadron.current or squadron.count or squadron.aircraft or 0
    local max = squadron.max or squadron.aircraft or 1
    if squadron.templateName and _G.squadronAircraftCounts and _G.squadronAircraftCounts[coalitionKey] then
        current = _G.squadronAircraftCounts[coalitionKey][squadron.templateName] or current
    end
    local ratio = (max > 0) and (current / max) or 0
    return current, max, ratio
end



--[[
    hasActiveCargoMission(coalitionKey, airbaseName)
    --------------------------------------------------------------------------
    Returns true if there is an active (not completed/failed) cargo mission for the given airbase.
    Failed missions are immediately removed from tracking to allow retries.
]]
local function hasActiveCargoMission(coalitionKey, airbaseName)
    for i = #cargoMissions[coalitionKey], 1, -1 do
        local mission = cargoMissions[coalitionKey][i]
        if mission.destination == airbaseName then
            -- Remove completed or failed missions immediately to allow retries
            if mission.status == "completed" or mission.status == "failed" then
                log("Removing " .. mission.status .. " cargo mission for " .. airbaseName .. " from tracking")
                table.remove(cargoMissions[coalitionKey], i)
            else
                -- Consider mission active only if the group is alive OR we're still within the grace window
                local stillActive = false
                if mission.group and mission.group.IsAlive and mission.group:IsAlive() then
                    stillActive = true
                else
                    local pending = mission._pendingStartTime
                    local grace = mission._gracePeriod or DISPATCHER_CONFIG.gracePeriod or 8
                    if pending and (timer.getTime() - pending) <= grace then
                        stillActive = true
                    end
                end
                if stillActive then
                    log("Active cargo mission found for " .. airbaseName .. " (" .. coalitionKey .. ")")
                    return true
                end
            end
        end
    end
    log("No active cargo mission for " .. airbaseName .. " (" .. coalitionKey .. ")")
    return false
end

--[[
    trackCargoMission(coalitionKey, mission)
    --------------------------------------------------------------------------
    Adds a new cargo mission to the tracking table and logs it.
]]
local function trackCargoMission(coalitionKey, mission)
    table.insert(cargoMissions[coalitionKey], mission)
    log("Tracking new cargo mission: " .. (mission.group and mission.group:GetName() or "nil group") .. " from " .. mission.origin .. " to " .. mission.destination)
end

--[[
    cleanupCargoMissions()
    --------------------------------------------------------------------------
    Removes failed cargo missions from the tracking table if their group is no longer alive.
]]
local function cleanupCargoMissions()
    for _, coalitionKey in ipairs({"red", "blue"}) do
        for i = #cargoMissions[coalitionKey], 1, -1 do
            local m = cargoMissions[coalitionKey][i]
            if m.status == "failed" or m.status == "completed" then
                if not (m.group and m.group:IsAlive()) then
                    log("Cleaning up " .. m.status .. " cargo mission: " .. (m.group and m.group:GetName() or "nil group"))
                    table.remove(cargoMissions[coalitionKey], i)
                end
            end
        end
    end
end

--[[
    dispatchCargo(squadron, coalitionKey)
    --------------------------------------------------------------------------
    Spawns a cargo aircraft from a supply airfield to the destination squadron airbase.
    Uses static templates for each coalition, assigns a unique group name, and sets a custom route.
    Tracks the mission and schedules route assignment with a delay to ensure group is alive.
]]
local function dispatchCargo(squadron, coalitionKey)
    local config = CARGO_SUPPLY_CONFIG[coalitionKey]
    local origin
    local attempts = 0
    local maxAttempts = 10
    local coalitionSide = getCoalitionSide(coalitionKey)
    
    repeat
        origin = selectRandomAirfield(config.supplyAirfields)
        attempts = attempts + 1
        
        -- Ensure origin is not the same as destination
        if origin == squadron.airbaseName then
            origin = nil
        else
            -- Validate that origin airbase exists and is controlled by correct coalition
            local originAirbase = AIRBASE:FindByName(origin)
            if not originAirbase then
                log("WARNING: Origin airbase '" .. tostring(origin) .. "' does not exist. Trying another...")
                origin = nil
            elseif originAirbase:GetCoalition() ~= coalitionSide then
                log("WARNING: Origin airbase '" .. tostring(origin) .. "' is not controlled by " .. coalitionKey .. " coalition. Trying another...")
                origin = nil
            end
        end
    until origin or attempts >= maxAttempts
    
    -- enforce cooldown per destination to avoid immediate retries
    lastDispatchAttempt[coalitionKey] = lastDispatchAttempt[coalitionKey] or {}
    local last = lastDispatchAttempt[coalitionKey][squadron.airbaseName]
    if last and (timer.getTime() - last) < CARGO_DISPATCH_COOLDOWN then
        log("Skipping dispatch to " .. squadron.airbaseName .. " (cooldown active)")
        return
    end
    if not origin then
        log("No valid origin airfield found for cargo dispatch to " .. squadron.airbaseName .. " (avoiding same origin/destination)")
        return
    end
    local destination = squadron.airbaseName
    local cargoTemplate = config.cargoTemplate
    -- Safety: check if destination has suitable parking for larger transports. If not, warn in log.
    local okParking = true
    -- Only check for likely large transports (C-130 / An-26 are large-ish) — keep conservative
    if cargoTemplate and (string.find(cargoTemplate:upper(), "C130") or string.find(cargoTemplate:upper(), "C-17") or string.find(cargoTemplate:upper(), "C17") or string.find(cargoTemplate:upper(), "AN26") ) then
        okParking = destinationHasSuitableParking(destination)
        if not okParking then
            log("WARNING: Destination '" .. tostring(destination) .. "' may not have suitable parking for " .. tostring(cargoTemplate) .. ". Skipping dispatch to prevent despawn.")
            return
        end
    end
    local groupName = cargoTemplate .. "_to_" .. destination .. "_" .. math.random(1000,9999)

    log("Dispatching cargo: " .. groupName .. " from " .. origin .. " to " .. destination)

    -- Spawn cargo aircraft at origin using the template name ONLY for SPAWN
    -- Note: cargoTemplate is a config string; script uses in-file Lua template tables (CARGO_AIRCRAFT_TEMPLATE_*)
    log("DEBUG: Attempting spawn for group: '" .. groupName .. "' at airbase: '" .. origin .. "' (using in-file Lua template)", true)
    local airbaseObj = AIRBASE:FindByName(origin)
    if not airbaseObj then
        log("ERROR: AIRBASE:FindByName failed for '" .. tostring(origin) .. "'. Airbase object is nil!")
    else
        log("DEBUG: AIRBASE object found for '" .. origin .. "'. Proceeding with spawn.", true)
    end

    -- Prepare a mission placeholder. We'll set the group and spawnPos after successful spawn.
    local mission = {
        group = nil,
        origin = origin,
        destination = destination,
        squadron = squadron,
        status = "pending",
        -- Anchor a pending start time now to avoid the monitor loop expiring a mission
        -- before MOOSE has a chance to finalize the OnSpawnGroup callback.
        _pendingStartTime = timer.getTime(),
        _spawnPos = nil,
        _gracePeriod = DISPATCHER_CONFIG.gracePeriod or 8
    }

    -- Helper to finalize mission after successful spawn
    local function finalizeMissionAfterSpawn(spawnedGroup, spawnPos)
        mission.group = spawnedGroup
        mission._spawnPos = spawnPos
        trackCargoMission(coalitionKey, mission)
        lastDispatchAttempt[coalitionKey][squadron.airbaseName] = timer.getTime()
    end

    -- MOOSE-only spawn-by-name flow
    if type(cargoTemplate) ~= 'string' or cargoTemplate == '' then
        log("ERROR: cargoTemplate for coalition '" .. tostring(coalitionKey) .. "' must be a valid mission template name string. Aborting dispatch.")
        announceToCoalition(coalitionKey, "Resupply mission to " .. destination .. " aborted (invalid cargo template)!")
        return
    end

    -- Use a per-dispatch RAT object to spawn and route cargo aircraft.
    -- Create a unique alias to avoid naming collisions and let RAT handle routing/landing.
    local alias = cargoTemplate .. "_TO_" .. destination .. "_" .. tostring(math.random(1000,9999))
    log("DEBUG: Attempting RAT spawn for template: '" .. cargoTemplate .. "' alias: '" .. alias .. "'", true)

    -- Validate destination airbase: RAT's "Airbase doesn't exist" error actually means
    -- "Airbase not found OR not owned by the correct coalition" because RAT filters by coalition internally.
    -- We perform the same validation here to fail fast with better error messages.
    local destAirbase = AIRBASE:FindByName(destination)
    local coalitionSide = getCoalitionSide(coalitionKey)
    
    if not destAirbase then
        log("ERROR: Destination airbase '" .. destination .. "' does not exist in DCS (invalid name or not on this map). Skipping dispatch.")
        announceToCoalition(coalitionKey, "Resupply mission to " .. destination .. " failed (airbase not found on map)!")
        -- Mark mission as failed and cleanup immediately
        mission.status = "failed"
        return
    end
    
    local destCoalition = destAirbase:GetCoalition()
    if destCoalition ~= coalitionSide then
        log("INFO: Destination airbase '" .. destination .. "' captured by enemy - cargo dispatch skipped (normal mission state).", true)
        -- No announcement to coalition - this is expected behavior when base is captured
        -- Mark mission as failed and cleanup immediately
        mission.status = "failed"
        return
    end

    -- Validate origin airbase with same coalition filtering logic
    local originAirbase = AIRBASE:FindByName(origin)
    if not originAirbase then
        log("ERROR: Origin airbase '" .. origin .. "' does not exist in DCS (invalid name or not on this map). Skipping dispatch.")
        announceToCoalition(coalitionKey, "Resupply mission from " .. origin .. " failed (airbase not found on map)!")
        -- Mark mission as failed and cleanup immediately
        mission.status = "failed"
        return
    end
    
    local originCoalition = originAirbase:GetCoalition()
    if originCoalition ~= coalitionSide then
        log("INFO: Origin airbase '" .. origin .. "' captured by enemy - trying another supply source.", true)
        -- Don't announce or mark as failed - the dispatcher will try another origin
        return
    end

    local okNew, rat = pcall(function() return RAT:New(cargoTemplate, alias) end)
    if not okNew or not rat then
        log("ERROR: RAT:New failed for template '" .. tostring(cargoTemplate) .. "'. Error: " .. tostring(rat))
        if debug and debug.traceback then
            log("TRACEBACK: " .. tostring(debug.traceback(rat)), true)
        end
        announceToCoalition(coalitionKey, "Resupply mission to " .. destination .. " failed (spawn init error)!")
        -- Mark mission as failed and cleanup immediately - do NOT track failed RAT spawns
        mission.status = "failed"
        return
    end

    -- Configure RAT for a single, non-respawning dispatch with immediate spawn
    rat:SetDeparture(origin)
    rat:SetDestination(destination)
    rat:NoRespawn()
    
    -- CRITICAL: Ensure aircraft spawn in active, controllable state
    rat:InitUnControlled(false)  -- Spawn as controllable AI
    rat:InitLateActivated(false) -- Do NOT spawn as late activated
    rat:RadioON()                -- Ensure radio is active (required for AI to be "alive")
    
    -- Disable ATC delay system (240 second default queue)
    rat:ATC_Messages(false)      -- Disable ATC messaging system
    rat:Commute()                -- Set to commute mode (immediate spawn, no delays)
    rat:SetSpawnLimit(1)
    rat:SetSpawnDelay(0) -- zero delay for immediate spawn
    
    -- CRITICAL: Force takeoff from runway to prevent aircraft getting stuck at parking
    -- SetTakeoffRunway() ensures aircraft spawn directly on runway and take off immediately
    if rat.SetTakeoffRunway then 
        rat:SetTakeoffRunway() 
        log("DEBUG: Configured cargo to take off from runway at " .. origin, true)
    else
        log("WARNING: SetTakeoffRunway() not available - falling back to SetTakeoffHot()", true)
        if rat.SetTakeoffHot then rat:SetTakeoffHot() end
    end
    
    -- Ensure RAT will look for parking and not despawn the group immediately on landing.
    -- This makes the group taxi to parking and come to a stop so other scripts (e.g. Load2nd)
    -- that detect parked/stopped cargo aircraft can register the delivery.
    if rat.SetParkingScanRadius then rat:SetParkingScanRadius(80) end
    if rat.SetParkingSpotSafeON then rat:SetParkingSpotSafeON() end
    if rat.SetDespawnAirOFF then rat:SetDespawnAirOFF() end
    -- Check on runway to ensure proper landing behavior (distance in meters)
    if rat.CheckOnRunway then rat:CheckOnRunway(true, 75) end

    rat:OnSpawnGroup(function(spawnedGroup)
        -- Mark the canonical start time when MOOSE reports the group exists
        mission._pendingStartTime = timer.getTime()

        local spawnPos = nil
        local dcsGroup = spawnedGroup:GetDCSObject()
        if dcsGroup then
            local units = dcsGroup:getUnits()
            if units and #units > 0 then
                spawnPos = units[1]:getPoint()
            end
        end

        log("RAT spawned cargo aircraft group: " .. tostring(spawnedGroup:GetName()))
        
        -- CRITICAL FIX: Force group to start/activate immediately after spawn
        -- This addresses the MOOSE IsAlive=false issue where RAT spawns groups in inactive state
        timer.scheduleFunction(function()
            local ok, err = pcall(function()
                local dcs = spawnedGroup:GetDCSObject()
                if dcs then
                    local controller = dcs:getController()
                    if controller then
                        -- Force the group to start moving by issuing a simple command
                        -- This "wakes up" the AI controller and makes MOOSE recognize it as alive
                        controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION)
                        log("[SPAWN FIX] Activated controller for group: " .. tostring(spawnedGroup:GetName()), true)
                        
                        -- Alternative: try to explicitly start the group
                        if spawnedGroup.Start then
                            spawnedGroup:Start()
                            log("[SPAWN FIX] Called Start() on group", true)
                        end
                        
                        -- Alternative: try Activate if available
                        if spawnedGroup.Activate then
                            spawnedGroup:Activate()
                            log("[SPAWN FIX] Called Activate() on group", true)
                        end
                    end
                end
            end)
            if not ok then
                log("[SPAWN FIX] Error activating group: " .. tostring(err), true)
            end
            collectgarbage('step', 10) -- GC after timer callback
        end, {}, timer.getTime() + 0.5)
        
        -- IMMEDIATE spawn state verification (check within 2 seconds after activation attempt)
        timer.scheduleFunction(function()
            local ok, err = pcall(function()
                log("[SPAWN VERIFY] Group: " .. tostring(spawnedGroup:GetName()) .. " - IsAlive: " .. tostring(spawnedGroup:IsAlive()), true)
                local dcs = spawnedGroup:GetDCSObject()
                if dcs then
                    local controller = dcs:getController()
                    log("[SPAWN VERIFY] Controller exists: " .. tostring(controller ~= nil), true)
                    local units = dcs:getUnits()
                    if units and #units > 0 then
                        local u = units[1]
                        local life = u:getLife()
                        local life0 = u:getLife0()
                        log(string.format("[SPAWN VERIFY] Unit life: %.1f / %.1f (%.1f%%)", life, life0, (life/life0)*100), true)
                    end
                else
                    log("[SPAWN VERIFY] ERROR: No DCS group object immediately after spawn!", true)
                end
            end)
            if not ok then
                log("[SPAWN VERIFY] Error checking spawn state: " .. tostring(err), true)
            end
            collectgarbage('step', 10) -- GC after verification
        end, {}, timer.getTime() + 2)

        -- Temporary debug: log group state every 10s for 5 minutes to trace landing/parking behavior
        local debugChecks = 30 -- 30 * 10s = 5 minutes (reduced from 10 minutes to limit memory impact)
        local checkInterval = 10
        local function debugLogState(iter)
            if iter > debugChecks then 
                collectgarbage('step', 20) -- Final cleanup after debug sequence
                return 
            end
            local ok, err = pcall(function()
                local name = spawnedGroup:GetName()
                local dcs = spawnedGroup:GetDCSObject()
                if dcs then
                    local units = dcs:getUnits()
                    if units and #units > 0 then
                        local u = units[1]
                        local pos = u:getPoint()
                        -- Use dot accessor to test for function existence; colon-call to invoke
                        local vel = (u.getVelocity and u:getVelocity()) or {x=0,y=0,z=0}
                        local speed = math.sqrt((vel.x or 0)^2 + (vel.y or 0)^2 + (vel.z or 0)^2)
                        local controller = dcs:getController()
                        local airbaseObj = AIRBASE:FindByName(destination)
                        local dist = nil
                        if airbaseObj then
                            local dest = airbaseObj:GetCoordinate():GetVec2()
                            local dx = pos.x - dest.x
                            local dz = pos.z - dest.y
                            dist = math.sqrt(dx*dx + dz*dz)
                        end
                        log(string.format("[TDAC DEBUG] %s state check %d: alive=%s pos=(%.1f,%.1f) speed=%.2f m/s distToDest=%s", name, iter, tostring(spawnedGroup:IsAlive()), pos.x or 0, pos.z or 0, speed, tostring(dist)), true)
                    else
                        log(string.format("[TDAC DEBUG] %s state check %d: DCS group has no units", tostring(spawnedGroup:GetName()), iter), true)
                    end
                else
                    log(string.format("[TDAC DEBUG] %s state check %d: no DCS group object", tostring(spawnedGroup:GetName()), iter), true)
                end
            end)
            if not ok then
                log("[TDAC DEBUG] Error during debugLogState: " .. tostring(err), true)
            end
            -- Add GC step every 5 iterations
            if iter % 5 == 0 then
                collectgarbage('step', 10)
            end
            timer.scheduleFunction(function() debugLogState(iter + 1) end, {}, timer.getTime() + checkInterval)
        end
        timer.scheduleFunction(function() debugLogState(1) end, {}, timer.getTime() + checkInterval)

        -- RAT should handle routing/taxi/parking. Finalize mission tracking now.
        finalizeMissionAfterSpawn(spawnedGroup, spawnPos)
        mission.status = "enroute"
        mission._pendingStartTime = timer.getTime()
        announceToCoalition(coalitionKey, "CARGO aircraft departing (airborne) for " .. destination .. ". Defend it!")
    end)

    local okSpawn, errSpawn = pcall(function() rat:Spawn(1) end)
    if not okSpawn then
        log("ERROR: rat:Spawn() failed for template '" .. tostring(cargoTemplate) .. "'. Error: " .. tostring(errSpawn))
        if debug and debug.traceback then
            log("TRACEBACK: " .. tostring(debug.traceback(errSpawn)), true)
        end
        announceToCoalition(coalitionKey, "Resupply mission to " .. destination .. " failed (spawn error)!")
        -- Mark mission as failed and cleanup immediately - do NOT track failed spawns
        mission.status = "failed"
        return
    end
end


-- Parking diagnostics helper
-- Call from DCS console: _G.TDAC_LogAirbaseParking("Luostari Pechenga")
function _G.TDAC_LogAirbaseParking(airbaseName)
    if type(airbaseName) ~= 'string' then
        log("TDAC Parking helper: airbaseName must be a string", true)
        return false
    end
    local base = AIRBASE:FindByName(airbaseName)
    if not base then
        log("TDAC Parking helper: AIRBASE:FindByName returned nil for '" .. tostring(airbaseName) .. "'", true)
        return false
    end
    local function spotsFor(term)
        local ok, n = pcall(function() return base:GetParkingSpotsNumber(term) end)
        if not ok then return nil end
        return n
    end
    local openBig = spotsFor(AIRBASE.TerminalType.OpenBig)
    local openMed = spotsFor(AIRBASE.TerminalType.OpenMed)
    local openMedOrBig = spotsFor(AIRBASE.TerminalType.OpenMedOrBig)
    local runway = spotsFor(AIRBASE.TerminalType.Runway)
    log(string.format("TDAC Parking: %s -> OpenBig=%s OpenMed=%s OpenMedOrBig=%s Runway=%s", airbaseName, tostring(openBig), tostring(openMed), tostring(openMedOrBig), tostring(runway)), true)
    return true
end


-- Pre-dispatch safety check: ensure destination can accommodate larger transport types
destinationHasSuitableParking = function(destination, preferredTermTypes)
    local base = AIRBASE:FindByName(destination)
    if not base then return false end
    preferredTermTypes = preferredTermTypes or { AIRBASE.TerminalType.OpenBig, AIRBASE.TerminalType.OpenMedOrBig, AIRBASE.TerminalType.OpenMed }
    for _, term in ipairs(preferredTermTypes) do
        local ok, n = pcall(function() return base:GetParkingSpotsNumber(term) end)
        if ok and n and n > 0 then
            return true
        end
    end
    return false
end


--[[
    monitorSquadrons()
    --------------------------------------------------------------------------
    Checks all squadrons for each coalition. If a squadron is below the resupply threshold and has no active cargo mission,
    triggers a supply request and dispatches a cargo aircraft.
    Skips squadrons that are captured or not operational.
]]
local function monitorSquadrons()
    for _, coalitionKey in ipairs({"red", "blue"}) do
        local config = CARGO_SUPPLY_CONFIG[coalitionKey]
        local squadrons = (coalitionKey == "red") and RED_SQUADRON_CONFIG or BLUE_SQUADRON_CONFIG
        for _, squadron in ipairs(squadrons) do
            -- Skip non-operational squadrons (captured, destroyed, etc.)
            if squadron.state and squadron.state ~= "operational" then
                log("Squadron " .. squadron.displayName .. " (" .. coalitionKey .. ") is " .. squadron.state .. " - skipping cargo dispatch", true)
            else
                local current, max, ratio = getSquadronStatus(squadron, coalitionKey)
                log("Squadron status: " .. squadron.displayName .. " (" .. coalitionKey .. ") " .. current .. "/" .. max .. " ratio: " .. string.format("%.2f", ratio))
                if ratio <= config.threshold and not hasActiveCargoMission(coalitionKey, squadron.airbaseName) then
                    log("Supply request triggered for " .. squadron.displayName .. " at " .. squadron.airbaseName)
                    announceToCoalition(coalitionKey, "Supply requested for " .. squadron.airbaseName .. "! Squadron: " .. squadron.displayName)
                    dispatchCargo(squadron, coalitionKey)
                end
            end
        end
    end
end

--[[
    monitorCargoMissions()
    --------------------------------------------------------------------------
    Monitors all cargo missions, updates their status, and cleans up failed ones.
    Handles mission failure after a grace period.
]]
local function monitorCargoMissions()
    for _, coalitionKey in ipairs({"red", "blue"}) do
        for _, mission in ipairs(cargoMissions[coalitionKey]) do
            if mission.group == nil then
                log("[DEBUG] Mission group object is nil for mission to " .. tostring(mission.destination), true)
            else
                log("[DEBUG] Mission group: " .. tostring(mission.group:GetName()) .. ", IsAlive(): " .. tostring(mission.group:IsAlive()), true)
                local dcsGroup = mission.group:GetDCSObject()
                if dcsGroup then
                    local units = dcsGroup:getUnits()
                    if units and #units > 0 then
                        local pos = units[1]:getPoint()
                        log(string.format("[DEBUG] Group position: x=%.1f y=%.1f z=%.1f", pos.x, pos.y, pos.z), true)
                    else
                        log("[DEBUG] No units found in DCS group for mission to " .. tostring(mission.destination), true)
                    end
                else
                    log("[DEBUG] DCS group object is nil for mission to " .. tostring(mission.destination), true)
                end
            end

            local graceElapsed = mission._pendingStartTime and (timer.getTime() - mission._pendingStartTime > (mission._gracePeriod or 8))

            -- Only allow mission to be failed after grace period, and only if group is truly dead.
            -- Some DCS/MOOSE group objects may momentarily report IsAlive() == false while units still exist, so
            -- also check DCS object/unit presence before declaring failure.
            if (mission.status == "pending" or mission.status == "enroute") and graceElapsed then
                local isAlive = mission.group and mission.group:IsAlive()
                local dcsGroup = mission.group and mission.group:GetDCSObject()
                local unitsPresent = false
                if dcsGroup then
                    local units = dcsGroup:getUnits()
                    unitsPresent = units and (#units > 0)
                end
                if not isAlive and not unitsPresent then
                    mission.status = "failed"
                    log("Cargo mission failed (after grace period): " .. (mission.group and mission.group:GetName() or "nil group") .. " to " .. mission.destination)
                    announceToCoalition(coalitionKey, "Resupply mission to " .. mission.destination .. " failed!")
                else
                    log("DEBUG: Mission appears to still have DCS units despite IsAlive=false; skipping failure for " .. tostring(mission.destination), true)
                end
            end
        end
    end
    cleanupCargoMissions()
end

--[[
    MAIN DISPATCHER LOOP
    --------------------------------------------------------------------------
    Runs the main dispatcher logic on a timer interval.
]]
local function cargoDispatcherMain()
    log("═══════════════════════════════════════════════════════════════════════════════", true)
    log("Cargo Dispatcher main loop running.", true)
    
    -- Clean up completed/failed missions before processing
    local cleaned = 0
    for _, coalitionKey in ipairs({"red", "blue"}) do
        for idx = #cargoMissions[coalitionKey], 1, -1 do
            local mission = cargoMissions[coalitionKey][idx]
            if mission.status == "completed" or mission.status == "failed" then
                -- Remove missions completed/failed more than 5 minutes ago
                local age = timer.getTime() - (mission.completedAt or mission._pendingStartTime or 0)
                if age > 300 then
                    table.remove(cargoMissions[coalitionKey], idx)
                    cleaned = cleaned + 1
                end
            end
        end
    end
    if cleaned > 0 then
        log("Cleaned up " .. cleaned .. " old cargo missions from tracking", true)
    end
    
    monitorSquadrons()
    monitorCargoMissions()
    
    -- Incremental GC after each loop iteration
    collectgarbage('step', 100)
    
    -- Schedule the next run inside a protected call to avoid unhandled errors
    timer.scheduleFunction(function()
        local ok, err = pcall(cargoDispatcherMain)
        if not ok then
            log("FATAL: cargoDispatcherMain crashed on scheduled run: " .. tostring(err))
            -- do not reschedule to avoid crash loops
        end
    end, {}, timer.getTime() + DISPATCHER_CONFIG.interval)
end

-- Start the dispatcher
local ok, err = pcall(cargoDispatcherMain)
if not ok then
    log("FATAL: cargoDispatcherMain crashed on startup: " .. tostring(err))
end

log("═══════════════════════════════════════════════════════════════════════════════", true)
-- End Moose_TDAC_CargoDispatcher.lua


--[[
    DIAGNOSTIC CONSOLE HELPERS
    --------------------------------------------------------------------------
    Functions you can call from the DCS Lua console (F12) to debug issues.
]]

-- Check airbase coalition ownership for all configured supply airbases
-- Usage: _G.TDAC_CheckAirbaseOwnership()
function _G.TDAC_CheckAirbaseOwnership()
    env.info("[TDAC DIAGNOSTIC] ═══════════════════════════════════════")
    env.info("[TDAC DIAGNOSTIC] Checking Coalition Ownership of All Supply Airbases")
    env.info("[TDAC DIAGNOSTIC] ═══════════════════════════════════════")
    
    for _, coalitionKey in ipairs({"red", "blue"}) do
        local config = CARGO_SUPPLY_CONFIG[coalitionKey]
        local expectedCoalition = getCoalitionSide(coalitionKey)
        
        env.info(string.format("[TDAC DIAGNOSTIC] %s COALITION (expected coalition ID: %s)", coalitionKey:upper(), tostring(expectedCoalition)))
        
        if config and config.supplyAirfields then
            for _, airbaseName in ipairs(config.supplyAirfields) do
                local airbase = AIRBASE:FindByName(airbaseName)
                if not airbase then
                    env.info(string.format("[TDAC DIAGNOSTIC]   ✗ %-30s - NOT FOUND (invalid name or not on this map)", airbaseName))
                else
                    local actualCoalition = airbase:GetCoalition()
                    local coalitionName = "UNKNOWN"
                    local status = "✗"
                    
                    if actualCoalition == coalition.side.NEUTRAL then
                        coalitionName = "NEUTRAL"
                    elseif actualCoalition == coalition.side.RED then
                        coalitionName = "RED"
                    elseif actualCoalition == coalition.side.BLUE then
                        coalitionName = "BLUE"
                    end
                    
                    if actualCoalition == expectedCoalition then
                        status = "✓"
                    end
                    
                    env.info(string.format("[TDAC DIAGNOSTIC]   %s %-30s - %s (coalition ID: %s)", status, airbaseName, coalitionName, tostring(actualCoalition)))
                end
            end
        else
            env.info("[TDAC DIAGNOSTIC]   ERROR: No supply airfields configured!")
        end
        env.info("[TDAC DIAGNOSTIC] ───────────────────────────────────────")
    end
    
    env.info("[TDAC DIAGNOSTIC] ═══════════════════════════════════════")
    env.info("[TDAC DIAGNOSTIC] Check complete. ✓ = Owned by correct coalition, ✗ = Wrong coalition or not found")
    return true
end

-- Check specific airbase coalition ownership
-- Usage: _G.TDAC_CheckAirbase("Olenya")
function _G.TDAC_CheckAirbase(airbaseName)
    if type(airbaseName) ~= 'string' then
        env.info("[TDAC DIAGNOSTIC] ERROR: airbaseName must be a string")
        return false
    end
    
    local airbase = AIRBASE:FindByName(airbaseName)
    if not airbase then
        env.info(string.format("[TDAC DIAGNOSTIC] Airbase '%s' NOT FOUND (invalid name or not on this map)", airbaseName))
        return false, "not_found"
    end
    
    local actualCoalition = airbase:GetCoalition()
    local coalitionName = "UNKNOWN"
    
    if actualCoalition == coalition.side.NEUTRAL then
        coalitionName = "NEUTRAL"
    elseif actualCoalition == coalition.side.RED then
        coalitionName = "RED"
    elseif actualCoalition == coalition.side.BLUE then
        coalitionName = "BLUE"
    end
    
    env.info(string.format("[TDAC DIAGNOSTIC] Airbase '%s' - Coalition: %s (ID: %s)", airbaseName, coalitionName, tostring(actualCoalition)))
    env.info(string.format("[TDAC DIAGNOSTIC]   IsAlive: %s", tostring(airbase:IsAlive())))
    
    -- Check parking spots
    local function spotsFor(term, termName)
        local ok, n = pcall(function() return airbase:GetParkingSpotsNumber(term) end)
        if ok and n then
            env.info(string.format("[TDAC DIAGNOSTIC]   Parking %-15s: %d spots", termName, n))
        end
    end
    
    spotsFor(AIRBASE.TerminalType.OpenBig, "OpenBig")
    spotsFor(AIRBASE.TerminalType.OpenMed, "OpenMed")
    spotsFor(AIRBASE.TerminalType.OpenMedOrBig, "OpenMedOrBig")
    spotsFor(AIRBASE.TerminalType.Runway, "Runway")
    
    return true, coalitionName, actualCoalition
end

env.info("[TDAC DIAGNOSTIC] Console helpers loaded:")
env.info("[TDAC DIAGNOSTIC]   _G.TDAC_CheckAirbaseOwnership() - Check all supply airbases")
env.info("[TDAC DIAGNOSTIC]   _G.TDAC_CheckAirbase('Olenya') - Check specific airbase")
env.info("[TDAC DIAGNOSTIC]   _G.TDAC_RunConfigCheck() - Validate dispatcher config")
env.info("[TDAC DIAGNOSTIC]   _G.TDAC_LogAirbaseParking('Olenya') - Check parking availability")


-- Diagnostic helper: call from DCS console to test spawn-by-name and routing.
-- Example (paste into DCS Lua console):
-- _G.TDAC_CargoDispatcher_TestSpawn("CARGO_BLUE_C130_TEMPLATE", "Kittila", "Luostari Pechenga")
function _G.TDAC_CargoDispatcher_TestSpawn(templateName, originAirbase, destinationAirbase)
    log("[TDAC TEST] Starting test spawn for template: " .. tostring(templateName), true)
    local ok, err
    if type(templateName) ~= 'string' then
        env.info("[TDAC TEST] templateName must be a string")
        return false, "invalid templateName"
    end
    local spawnByName = nil
    ok, spawnByName = pcall(function() return SPAWN:New(templateName) end)
    if not ok or not spawnByName then
    log("[TDAC TEST] SPAWN:New failed for template " .. tostring(templateName) .. ". Error: " .. tostring(spawnByName), true)
    if debug and debug.traceback then log("TRACEBACK: " .. tostring(debug.traceback(tostring(spawnByName))), true) end
        return false, "spawn_new_failed"
    end

    spawnByName:OnSpawnGroup(function(spawnedGroup)
    log("[TDAC TEST] OnSpawnGroup called for: " .. tostring(spawnedGroup:GetName()), true)
        local dcsGroup = spawnedGroup:GetDCSObject()
        if dcsGroup then
            local units = dcsGroup:getUnits()
            if units and #units > 0 then
                local pos = units[1]:getPoint()
                log(string.format("[TDAC TEST] Spawned pos x=%.1f y=%.1f z=%.1f", pos.x, pos.y, pos.z), true)
            end
        end
        if destinationAirbase then
            local okAssign, errAssign = pcall(function()
                local base = AIRBASE:FindByName(destinationAirbase)
                if base and spawnedGroup and spawnedGroup.RouteToAirbase then
                    spawnedGroup:RouteToAirbase(base, AI_Task_Land.Runway)
                    log("[TDAC TEST] RouteToAirbase assigned to " .. tostring(destinationAirbase), true)
                else
                    log("[TDAC TEST] RouteToAirbase not available or base not found", true)
                end
            end)
            if not okAssign then
                log("[TDAC TEST] RouteToAirbase pcall failed: " .. tostring(errAssign), true)
                if debug and debug.traceback then log("TRACEBACK: " .. tostring(debug.traceback(tostring(errAssign))), true) end
            end
        end
    end)

    ok, err = pcall(function() spawnByName:Spawn() end)
    if not ok then
        log("[TDAC TEST] spawnByName:Spawn() failed: " .. tostring(err), true)
        if debug and debug.traceback then log("TRACEBACK: " .. tostring(debug.traceback(tostring(err))), true) end
        return false, "spawn_failed"
    end
    log("[TDAC TEST] spawnByName:Spawn() returned successfully", true)
    return true
end


log("═══════════════════════════════════════════════════════════════════════════════", true)
-- End Moose_TDAC_CargoDispatcher.lua

