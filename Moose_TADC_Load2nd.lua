---@diagnostic disable: undefined-field
--[[
═══════════════════════════════════════════════════════════════════════════════
                              UNIVERSAL TADC
                  Dual-Coalition Tactical Air Defense Controller
                           Advanced Zone-Based System
═══════════════════════════════════════════════════════════════════════════════

DESCRIPTION:
This script provides a sophisticated automated air defense system for BOTH RED and 
BLUE coalitions operating independently. Features advanced zone-based area of 
responsibility (AOR) management, allowing squadrons to respond differently based 
on threat location and priority levels. Perfect for complex scenarios requiring 
realistic air defense behavior and tactical depth.

CORE FEATURES:
• Dual-coalition support with completely independent operation
• Advanced zone-based area of responsibility system (Primary/Secondary/Tertiary)
• Automatic threat detection with intelligent interceptor allocation
• Multi-squadron management with individual cooldowns and aircraft tracking
• Dynamic cargo aircraft replenishment system
• Configurable intercept ratios with zone-specific response modifiers
• Smart interceptor routing, engagement, and RTB (Return to Base) behavior
• Real-time airbase status monitoring (operational/captured/destroyed)
• Comprehensive configuration validation and error reporting
• Asymmetric warfare support with coalition-specific capabilities
• Emergency cleanup systems and safety nets for mission stability

ADVANCED ZONE SYSTEM:
Each squadron can be configured with up to three zone types:
• PRIMARY ZONE: Main area of responsibility (full response ratio)
• SECONDARY ZONE: Support area (reduced response, optional low-priority filtering)
• TERTIARY ZONE: Emergency/fallback area (enhanced response when base threatened)
• Squadrons will respond based on threat location relative to their zones
• Zone-specific response modifiers can be configured for each squadron
• Zones may overlap between squadrons for layered defense.  

ADVANCED ZONE SETUP:
• Create zones in the mission editor (MOOSE polygons, circles, etc.)
• Assign zone names to squadrons in the configuration (exact match required)
• Leave zones as nil for global threat response (no zone restrictions)
• Each zone is defined by placing a helicopter group with waypoints outlining the area
• The script will create polygon zones from the helicopter waypoints automatically

Zone response behaviors include:
• Distance-based engagement limits (max range from airbase)
• Priority thresholds for threat classification (major vs minor threats)
• Fallback conditions (auto-switch to tertiary when squadron weakened)
• Response ratio multipliers per zone type
• Low-priority threat filtering in secondary zones

REPLENISHMENT SYSTEM:
• Automated cargo aircraft detection system that monitors for transport aircraft
  flyovers to replenish squadron aircraft counts (fixed wing only):
• Detects cargo aircraft by name patterns (CARGO, TRANSPORT, C130, C-130, AN26, AN-26)
• Monitors flyover proximity to friendly airbases (no landing required)
• Replenishes squadron aircraft up to maximum capacity per airbase
• Prevents duplicate processing of the same cargo delivery
• Coalition-specific replenishment amounts configurable independently
• Supports sustained operations over extended mission duration

*** This system does not spawn or manage cargo aircraft - it only detects when
your existing cargo aircraft complete deliveries via flyover. Create and route your own
transport missions to maintain squadron strength. Aircraft can deliver supplies by
flying within 3000m of any configured airbase without needing to land. ***

INTERCEPT RATIO SYSTEM:
Sophisticated threat response calculation with zone-based modifiers:
• Base intercept ratio (e.g., 0.8 = 8 interceptors per 10 threats)
• Zone-specific multipliers (primary: 1.0, secondary: 0.6, tertiary: 1.4)
• Threat size considerations (larger formations get proportional response)
• Squadron selection based on zone priority and proximity
• Aircraft availability and cooldown status factored into decisions

SETUP INSTRUCTIONS:
1. Load MOOSE framework in mission before this script
2. Configure Squadrons: Create fighter aircraft GROUP templates for both coalitions in mission editor
3. Configure RED squadrons in RED_SQUADRON_CONFIG section
4. Configure BLUE squadrons in BLUE_SQUADRON_CONFIG section
5. Optionally create zones in mission editor for area-of-responsibility using helicopter groups with waypoints.
6. Set coalition behavior parameters in TADC_SETTINGS
7. Configure cargo patterns in ADVANCED_SETTINGS if using replenishment
8. Add this script as "DO SCRIPT" trigger at mission start (after MOOSE loaded)
9. Create and manage cargo aircraft missions for replenishment (optional)

CONFIGURATION VALIDATION:
Built-in validation system checks for:
• Template existence and proper naming
• Airbase name accuracy and coalition control
• Zone existence in mission editor
• Parameter ranges and logical consistency
• Coalition enablement and squadron availability
• Prevents common configuration errors before mission starts

TACTICAL SCENARIOS SUPPORTED:
• Balanced air warfare with equal capabilities and symmetric response
• Asymmetric scenarios with different coalition strengths and capabilities
• Layered air defense with overlapping squadron zones
• Border/perimeter defense with primary and fallback positions
• Training missions for AI vs AI air combat observation
• Dynamic frontline battles with shifting territorial control
• Long-duration missions with cargo resupply operations
• Emergency response scenarios with threat priority management

LOGGING AND MONITORING:
• Real-time threat detection and interceptor launch notifications
• Squadron status reports including aircraft counts and cooldown timers
• Airbase operational status with capture/destruction detection
• Cargo delivery tracking and replenishment confirmations
• Zone-based engagement decisions with detailed reasoning
• Configuration validation results and error reporting
• Performance monitoring with emergency cleanup notifications

REQUIREMENTS:
• MOOSE framework (https://github.com/FlightControl-Master/MOOSE)
• Fighter aircraft GROUP templates (not UNIT templates) for each coalition
• Airbases must exist in mission and be under correct coalition control
• Zone objects in mission editor (if using zone-based features)
• Proper template naming matching squadron configuration

AUTHOR:
• Based off MOOSE framework by FlightControl-Master
• Developed and customized by Mission Designer "F99th-TracerFacer"

VERSION: 1.0
═══════════════════════════════════════════════════════════════════════════════
]]
---@diagnostic disable: undefined-global, lowercase-global
-- MOOSE framework globals are defined at runtime by DCS World

--[[
═══════════════════════════════════════════════════════════════════════════════
                                MAIN SETTINGS
═══════════════════════════════════════════════════════════════════════════════
]]

-- Core TADC behavior settings - applies to BOTH coalitions unless overridden
local TADC_SETTINGS = {
    -- Enable/Disable coalitions
    enableRed = true,            -- Set to false to disable RED TADC
    enableBlue = true,           -- Set to false to disable BLUE TADC
    
    -- Timing settings (applies to both coalitions)
    checkInterval = 30,          -- How often to scan for threats (seconds)
    monitorInterval = 30,        -- How often to check interceptor status (seconds)
    statusReportInterval = 1805,  -- How often to report airbase status (seconds)
    squadronSummaryInterval = 1800, -- How often to broadcast squadron summary (seconds)
    cargoCheckInterval = 15,     -- How often to check for cargo deliveries (seconds)
    
    -- RED Coalition Settings
    red = {
        maxActiveCAP = 24,           -- Maximum RED fighters airborne at once
        squadronCooldown = 600,      -- RED cooldown after squadron launch (seconds)
        interceptRatio = 1.2,        -- RED interceptors per threat aircraft
        cargoReplenishmentAmount = 4, -- RED aircraft added per cargo delivery
        emergencyCleanupTime = 7200, -- RED force cleanup time (seconds)
        rtbFlightBuffer = 300,       -- RED extra landing time before cleanup (seconds)
    },
    
    -- BLUE Coalition Settings  
    blue = {
        maxActiveCAP = 24,           -- Maximum BLUE fighters airborne at once
        squadronCooldown = 600,      -- BLUE cooldown after squadron launch (seconds)
        interceptRatio = 1.2,        -- BLUE interceptors per threat aircraft
        cargoReplenishmentAmount = 4, -- BLUE aircraft added per cargo delivery
        emergencyCleanupTime = 7200, -- BLUE force cleanup time (seconds)
        rtbFlightBuffer = 300,       -- BLUE extra landing time before cleanup (seconds)
    },
}


--[[
INTERCEPT RATIO CHART - How many interceptors launch per threat aircraft:

Threat Size:        1    2    4    8    12   16   (aircraft)
====================================================================
interceptRatio 0.2: 1    1    1    2     3    4   (conservative)
interceptRatio 0.5: 1    1    2    4     6    8   (light response)
interceptRatio 0.8: 1    2    4    7    10   13   (balanced) <- DEFAULT
interceptRatio 1.0: 1    2    4    8    12   16   (1:1 parity)
interceptRatio 1.2: 2    3    5   10    15   20   (slight advantage)
interceptRatio 1.4: 2    3    6   12    17   23   (good advantage)
interceptRatio 1.6: 2    4    7   13    20   26   (strong response)
interceptRatio 1.8: 2    4    8   15    22   29   (overwhelming)
interceptRatio 2.0: 2    4    8   16    24   32   (overkill)

TACTICAL EFFECTS:
• 0.2-0.5: Minimal response, may be overwhelmed by large formations
• 0.8-1.0: Realistic parity, creates balanced dogfights
• 1.2-1.4: Coalition advantage, challenging for enemy
• 1.6-1.8: Strong defense, difficult penetration missions
• 1.9-2.0: Nearly impenetrable, may exhaust squadrons quickly

SQUADRON IMPACT:
• Low ratios (0.2-0.8): Squadrons last longer, sustained defense
• High ratios (1.6-2.0): Rapid squadron depletion, coverage gaps
• Sweet spot (1.0-1.4): Balanced response with good coverage duration

ASYMMETRIC SCENARIOS:
• Set RED ratio 1.2, BLUE ratio 0.8 = RED advantage
• Set RED ratio 0.6, BLUE ratio 1.4 = BLUE advantage
• Different maxActiveCAP values create capacity imbalances
]]


--[[
═══════════════════════════════════════════════════════════════════════════════
                            ADVANCED SETTINGS
═══════════════════════════════════════════════════════════════════════════════

These settings control more detailed behavior. Most users won't need to change these.
]]

local ADVANCED_SETTINGS = {
    -- Cargo aircraft detection patterns (aircraft with these names will replenish squadrons (Currently only fixed wing aircraft supported)) 
    cargoPatterns = {"CARGO", "TRANSPORT", "C130", "C-130", "AN26", "AN-26"},
    
    -- Distance from airbase to consider cargo "delivered" via flyover (meters)
    -- Aircraft flying within this range will count as supply delivery (no landing required)
    cargoLandingDistance = 3000,
    -- Distance from airbase to consider a landing as delivered (wheel touchdown)
    -- Use a slightly larger radius than 1000m to account for runway offsets from airbase center
    cargoLandingEventRadius = 2000,
    
    -- Velocity below which aircraft is considered "landed" (km/h)
    cargoLandedVelocity = 5,
    
    -- RTB settings
    rtbAltitude = 6000,    -- Return to base altitude (feet)
    rtbSpeed = 430,        -- Return to base speed (knots)
    
    -- Logging settings
    enableDetailedLogging = false,  -- Set to false to reduce log spam
    logPrefix = "[Universal TADC]", -- Prefix for all log messages
    -- Proxy/raw-fallback verbose logging (set true to debug proxy behavior)
    verboseProxyLogging = false,
}

--[[
═══════════════════════════════════════════════════════════════════════════════
                              SYSTEM CODE
                    (DO NOT MODIFY BELOW THIS LINE)
═══════════════════════════════════════════════════════════════════════════════
]]



-- Internal tracking variables - separate for each coalition
local activeInterceptors = {
    red = {},
    blue = {}
}
local lastLaunchTime = {
    red = {},
    blue = {}
}
local assignedThreats = {
    red = {},
    blue = {}
}
local squadronCooldowns = {
    red = {},
    blue = {}
}
squadronAircraftCounts = {
    red = {},
    blue = {}
}

-- Aircraft spawn tracking for stuck detection
local aircraftSpawnTracking = {
    red = {}, -- groupName -> {spawnPos, spawnTime, squadron, airbase}
    blue = {}
}

-- Airbase health status
local airbaseHealthStatus = {
    red = {}, -- airbaseName -> "operational"|"stuck-aircraft"|"unusable"
    blue = {}
}

local function coalitionKeyFromSide(side)
    if side == coalition.side.RED then return "red" end
    if side == coalition.side.BLUE then return "blue" end
    return nil
end

local function cleanupInterceptorEntry(interceptorName, coalitionKey)
    if not interceptorName or not coalitionKey then return end
    if activeInterceptors[coalitionKey] then
        activeInterceptors[coalitionKey][interceptorName] = nil
    end
    if aircraftSpawnTracking[coalitionKey] then
        aircraftSpawnTracking[coalitionKey][interceptorName] = nil
    end
end

local function destroyInterceptorGroup(interceptor, coalitionKey, delaySeconds)
    if not interceptor then return end

    local name = nil
    if interceptor.GetName then
        local ok, value = pcall(function() return interceptor:GetName() end)
        if ok then name = value end
    end

    local resolvedKey = coalitionKey
    if not resolvedKey and interceptor.GetCoalition then
        local ok, side = pcall(function() return interceptor:GetCoalition() end)
        if ok then
            resolvedKey = coalitionKeyFromSide(side)
        end
    end

    local function doDestroy()
        if interceptor and interceptor.IsAlive and interceptor:IsAlive() then
            pcall(function() interceptor:Destroy() end)
        end
        if name and resolvedKey then
            cleanupInterceptorEntry(name, resolvedKey)
        end
    end

    if delaySeconds and delaySeconds > 0 then
        timer.scheduleFunction(function()
            doDestroy()
            return
        end, {}, timer.getTime() + delaySeconds)
    else
        doDestroy()
    end
end

local function finalizeCargoMission(cargoGroup, squadron, coalitionKey)
    if not cargoMissions or not coalitionKey or not squadron or not squadron.airbaseName then
        return
    end

    local coalitionBucket = cargoMissions[coalitionKey]
    if type(coalitionBucket) ~= "table" then
        return
    end

    local groupName = nil
    if cargoGroup and cargoGroup.GetName then
        local ok, value = pcall(function() return cargoGroup:GetName() end)
        if ok then groupName = value end
    end

    for idx = #coalitionBucket, 1, -1 do
        local mission = coalitionBucket[idx]
        if mission and mission.destination == squadron.airbaseName then
            local missionGroupName = nil
            if mission.group and mission.group.GetName then
                local ok, value = pcall(function() return mission.group:GetName() end)
                if ok then missionGroupName = value end
            end

            if not groupName or missionGroupName == groupName then
                mission.status = "completed"
                mission.completedAt = timer.getTime()

                if mission.group and mission.group.Destroy then
                    local targetGroup = mission.group
                    timer.scheduleFunction(function()
                        pcall(function()
                            if targetGroup and targetGroup.IsAlive and targetGroup:IsAlive() then
                                targetGroup:Destroy()
                            end
                        end)
                        return
                    end, {}, timer.getTime() + 90)
                end

                table.remove(coalitionBucket, idx)
            end
        end
    end
end

-- Logging function
local function log(message, detailed)
    if not detailed or ADVANCED_SETTINGS.enableDetailedLogging then
        env.info(ADVANCED_SETTINGS.logPrefix .. " " .. message)
    end
end

local function safeCoordinate(object)
    if not object or type(object) ~= "table" or not object.GetCoordinate then
        return nil
    end
    local ok, coord = pcall(function() return object:GetCoordinate() end)
    if ok and coord then
        return coord
    end
    return nil
end

-- Performance optimization: Cache SET_GROUP objects to avoid repeated creation
local cachedSets = {
    redCargo = nil,
    blueCargo = nil,
    redAircraft = nil,
    blueAircraft = nil
}

if type(RED_SQUADRON_CONFIG) ~= "table" then
    local msg = "CONFIG ERROR: RED_SQUADRON_CONFIG is missing or not loaded. Make sure Moose_TADC_SquadronConfigs_Load1st.lua is loaded before this script."
    log(msg, true)
    MESSAGE:New(msg, 30):ToAll()
end
if type(BLUE_SQUADRON_CONFIG) ~= "table" then
    local msg = "CONFIG ERROR: BLUE_SQUADRON_CONFIG is missing or not loaded. Make sure Moose_TADC_SquadronConfigs_Load1st.lua is loaded before this script."
    log(msg, true)
    MESSAGE:New(msg, 30):ToAll()
end

for _, squadron in pairs(RED_SQUADRON_CONFIG) do
    if squadron.aircraft and squadron.templateName then
        squadronAircraftCounts.red[squadron.templateName] = squadron.aircraft
    end
end

for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
    if squadron.aircraft and squadron.templateName then
        squadronAircraftCounts.blue[squadron.templateName] = squadron.aircraft
    end
end

-- Squadron resource summary generator

local function getSquadronResourceSummary(coalitionSide)
    local function getStatus(remaining, max, state)
        if state == "captured" then return "[CAPTURED]" end
        if state == "destroyed" then return "[DESTROYED]" end
        if state ~= "operational" then return "[OFFLINE]" end
        
        local percent = (remaining / max) * 100
        if percent <= 10 then return "[CRITICAL]" end
        if percent <= 25 then return "[LOW]" end
        return "OK"
    end

    local lines = {}
    table.insert(lines, "-=[ Tactical Air Defense Controller ]=-\n")
    table.insert(lines, "Squadron Resource Summary:\n")
    table.insert(lines, "| Squadron     | Aircraft Remaining | Status      |")
    table.insert(lines, "|--------------|--------------------|-------------|")

    if coalitionSide == coalition.side.RED then
        for _, squadron in pairs(RED_SQUADRON_CONFIG) do
            local remaining = squadronAircraftCounts.red[squadron.templateName] or 0
            local max = squadron.aircraft or 0
            local state = squadron.state or "operational"
            local status = getStatus(remaining, max, state)
            table.insert(lines, string.format("| %-13s | %2d / %-15d | %-11s |", squadron.displayName or squadron.templateName, remaining, max, status))
        end
    elseif coalitionSide == coalition.side.BLUE then
        for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
            local remaining = squadronAircraftCounts.blue[squadron.templateName] or 0
            local max = squadron.aircraft or 0
            local state = squadron.state or "operational"
            local status = getStatus(remaining, max, state)
            table.insert(lines, string.format("| %-13s | %2d / %-15d | %-11s |", squadron.displayName or squadron.templateName, remaining, max, status))
        end
    end

    table.insert(lines, "\n- [CAPTURED]: Airbase captured by enemy\n- [LOW]: Below 25%\n- [CRITICAL]: Below 10%\n- OK: Above 25%")
    return table.concat(lines, "\n")
end

-- Broadcast squadron summary to all players
local function broadcastSquadronSummary()
    if TADC_SETTINGS.enableRed then
        local summaryRed = getSquadronResourceSummary(coalition.side.RED)
        MESSAGE:New(summaryRed, 20):ToCoalition(coalition.side.RED)
    end
    if TADC_SETTINGS.enableBlue then
        local summaryBlue = getSquadronResourceSummary(coalition.side.BLUE)
        MESSAGE:New(summaryBlue, 20):ToCoalition(coalition.side.BLUE)
    end
end

-- Coalition-specific settings helper
local function getCoalitionSettings(coalitionSide)
    if coalitionSide == coalition.side.RED then
        return TADC_SETTINGS.red, "RED"
    elseif coalitionSide == coalition.side.BLUE then
        return TADC_SETTINGS.blue, "BLUE"
    else
        return nil, "UNKNOWN"
    end
end

-- Get squadron config for coalition
local function getSquadronConfig(coalitionSide)
    if coalitionSide == coalition.side.RED then
        return RED_SQUADRON_CONFIG
    elseif coalitionSide == coalition.side.BLUE then
        return BLUE_SQUADRON_CONFIG
    else
        return {}
    end
end

-- Check if coordinate is within a zone
local function isInZone(coordinate, zoneName)
    if not zoneName or zoneName == "" then
        return false
    end
    
    -- Try to find the zone
    local zone = ZONE:FindByName(zoneName)
    if zone then
        return zone:IsCoordinateInZone(coordinate)
    else
        -- Try to create polygon zone from helicopter group waypoints if not found
        local group = GROUP:FindByName(zoneName)
        if group then
            -- Create polygon zone using the group's waypoints as vertices
            zone = ZONE_POLYGON:NewFromGroupName(zoneName, zoneName)
            if zone then
                log("Created polygon zone '" .. zoneName .. "' from helicopter waypoints")
                return zone:IsCoordinateInZone(coordinate)
            else
                log("Warning: Could not create polygon zone from group '" .. zoneName .. "' - check waypoints")
            end
        else
            log("Warning: No group named '" .. zoneName .. "' found for zone creation")
        end
        
        log("Warning: Zone '" .. zoneName .. "' not found in mission and could not create from helicopter group", true)
        return false
    end
end

-- Get default zone configuration
local function getDefaultZoneConfig()
    return {
        primaryResponse = 1.0,
        secondaryResponse = 0.6,
        tertiaryResponse = 1.4,
        maxRange = 200,
        enableFallback = false,
        priorityThreshold = 4,
        ignoreLowPriority = false,
    }
end

-- Check if squadron should respond to fallback conditions
local function checkFallbackConditions(squadron, coalitionSide)
    local coalitionKey = (coalitionSide == coalition.side.RED) and "red" or "blue"
    
    -- Check if airbase is under attack (simplified - check if base has low aircraft)
    local currentAircraft = squadronAircraftCounts[coalitionKey][squadron.templateName] or 0
    local maxAircraft = squadron.aircraft
    local aircraftRatio = currentAircraft / maxAircraft
    
    -- Trigger fallback if squadron is below 50% strength or base is threatened
    if aircraftRatio < 0.5 then
        return true
    end
    
    -- Could add more complex conditions here (base under attack, etc.)
    return false
end

-- Get threat zone priority and response ratio for squadron
local function getThreatZonePriority(threatCoord, squadron, coalitionSide)
    local zoneConfig = squadron.zoneConfig or getDefaultZoneConfig()
    
    -- Check distance from airbase first
    local airbase = AIRBASE:FindByName(squadron.airbaseName)
    if airbase then
        local airbaseCoord = airbase:GetCoordinate()
        local distance = airbaseCoord:Get2DDistance(threatCoord) / 1852 -- Convert meters to nautical miles
        
        if distance > zoneConfig.maxRange then
            return "none", 0, "out of range (" .. math.floor(distance) .. "nm > " .. zoneConfig.maxRange .. "nm)"
        end
    end
    
    -- Check tertiary zone first (highest priority if fallback enabled)
    if squadron.tertiaryZone and zoneConfig.enableFallback then
        if checkFallbackConditions(squadron, coalitionSide) then
            if isInZone(threatCoord, squadron.tertiaryZone) then
                return "tertiary", zoneConfig.tertiaryResponse, "fallback zone (enhanced response)"
            end
        end
    end
    
    -- Check primary zone
    if squadron.primaryZone and isInZone(threatCoord, squadron.primaryZone) then
        return "primary", zoneConfig.primaryResponse, "primary AOR"
    end
    
    -- Check secondary zone
    if squadron.secondaryZone and isInZone(threatCoord, squadron.secondaryZone) then
        return "secondary", zoneConfig.secondaryResponse, "secondary AOR"
    end
    
    -- Check tertiary zone (normal priority)
    if squadron.tertiaryZone and isInZone(threatCoord, squadron.tertiaryZone) then
        return "tertiary", zoneConfig.tertiaryResponse, "tertiary zone"
    end
    
    -- If no zones are defined, use global response
    if not squadron.primaryZone and not squadron.secondaryZone and not squadron.tertiaryZone then
        return "global", 1.0, "global response (no zones defined)"
    end
    
    -- Outside all defined zones
    return "none", 0, "outside defined zones"
end

-- Startup validation
local function validateConfiguration()
    local errors = {}
    
    -- Check coalition enablement
    if not TADC_SETTINGS.enableRed and not TADC_SETTINGS.enableBlue then
        table.insert(errors, "Both coalitions disabled - enable at least one in TADC_SETTINGS")
    end
    
    -- Validate RED squadrons if enabled
    if TADC_SETTINGS.enableRed then
        if #RED_SQUADRON_CONFIG == 0 then
            table.insert(errors, "No RED squadrons configured but RED TADC is enabled")
        else
            for i, squadron in pairs(RED_SQUADRON_CONFIG) do
                local prefix = "RED Squadron " .. i .. ": "
                
                if not squadron.templateName or squadron.templateName == "" or 
                   squadron.templateName == "RED_CAP_SQUADRON_1" or 
                   squadron.templateName == "RED_CAP_SQUADRON_2" then
                    table.insert(errors, prefix .. "templateName not configured or using default example")
                end
                
                if not squadron.displayName or squadron.displayName == "" then
                    table.insert(errors, prefix .. "displayName not configured")
                end
                
                if not squadron.airbaseName or squadron.airbaseName == "" or 
                   squadron.airbaseName:find("YOUR_RED_AIRBASE") then
                    table.insert(errors, prefix .. "airbaseName not configured or using default example")
                end
                
                if not squadron.aircraft or squadron.aircraft <= 0 then
                    table.insert(errors, prefix .. "aircraft count not configured or invalid")
                end
                
                -- Validate zone configuration if zones are specified
                if squadron.primaryZone or squadron.secondaryZone or squadron.tertiaryZone then
                    if squadron.zoneConfig then
                        local zc = squadron.zoneConfig
                        if zc.primaryResponse and (zc.primaryResponse < 0 or zc.primaryResponse > 5) then
                            table.insert(errors, prefix .. "primaryResponse ratio out of range (0-5)")
                        end
                        if zc.secondaryResponse and (zc.secondaryResponse < 0 or zc.secondaryResponse > 5) then
                            table.insert(errors, prefix .. "secondaryResponse ratio out of range (0-5)")
                        end
                        if zc.tertiaryResponse and (zc.tertiaryResponse < 0 or zc.tertiaryResponse > 5) then
                            table.insert(errors, prefix .. "tertiaryResponse ratio out of range (0-5)")
                        end
                        if zc.maxRange and (zc.maxRange < 10 or zc.maxRange > 1000) then
                            table.insert(errors, prefix .. "maxRange out of range (10-1000 nm)")
                        end
                    end
                    
                    -- Check if specified zones exist in mission
                    local zones = {}
                    if squadron.primaryZone then table.insert(zones, squadron.primaryZone) end
                    if squadron.secondaryZone then table.insert(zones, squadron.secondaryZone) end
                    if squadron.tertiaryZone then table.insert(zones, squadron.tertiaryZone) end
                    
                    for _, zoneName in ipairs(zones) do
                        local zoneObj = ZONE:FindByName(zoneName)
                        if not zoneObj then
                            -- Check if there's a helicopter unit/group with this name for zone creation
                            local unit = UNIT:FindByName(zoneName)
                            local group = GROUP:FindByName(zoneName)
                            if not unit and not group then
                                table.insert(errors, prefix .. "zone '" .. zoneName .. "' not found in mission (no zone or helicopter unit named '" .. zoneName .. "')")
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Validate BLUE squadrons if enabled
    if TADC_SETTINGS.enableBlue then
        if #BLUE_SQUADRON_CONFIG == 0 then
            table.insert(errors, "No BLUE squadrons configured but BLUE TADC is enabled")
        else
            for i, squadron in pairs(BLUE_SQUADRON_CONFIG) do
                local prefix = "BLUE Squadron " .. i .. ": "
                
                if not squadron.templateName or squadron.templateName == "" or 
                   squadron.templateName == "BLUE_CAP_SQUADRON_1" or 
                   squadron.templateName == "BLUE_CAP_SQUADRON_2" then
                    table.insert(errors, prefix .. "templateName not configured or using default example")
                end
                
                if not squadron.displayName or squadron.displayName == "" then
                    table.insert(errors, prefix .. "displayName not configured")
                end
                
                if not squadron.airbaseName or squadron.airbaseName == "" or 
                   squadron.airbaseName:find("YOUR_BLUE_AIRBASE") then
                    table.insert(errors, prefix .. "airbaseName not configured or using default example")
                end
                
                if not squadron.aircraft or squadron.aircraft <= 0 then
                    table.insert(errors, prefix .. "aircraft count not configured or invalid")
                end
                
                -- Validate zone configuration if zones are specified
                if squadron.primaryZone or squadron.secondaryZone or squadron.tertiaryZone then
                    if squadron.zoneConfig then
                        local zc = squadron.zoneConfig
                        if zc.primaryResponse and (zc.primaryResponse < 0 or zc.primaryResponse > 5) then
                            table.insert(errors, prefix .. "primaryResponse ratio out of range (0-5)")
                        end
                        if zc.secondaryResponse and (zc.secondaryResponse < 0 or zc.secondaryResponse > 5) then
                            table.insert(errors, prefix .. "secondaryResponse ratio out of range (0-5)")
                        end
                        if zc.tertiaryResponse and (zc.tertiaryResponse < 0 or zc.tertiaryResponse > 5) then
                            table.insert(errors, prefix .. "tertiaryResponse ratio out of range (0-5)")
                        end
                        if zc.maxRange and (zc.maxRange < 10 or zc.maxRange > 1000) then
                            table.insert(errors, prefix .. "maxRange out of range (10-1000 nm)")
                        end
                    end
                    
                    -- Check if specified zones exist in mission
                    local zones = {}
                    if squadron.primaryZone then table.insert(zones, squadron.primaryZone) end
                    if squadron.secondaryZone then table.insert(zones, squadron.secondaryZone) end
                    if squadron.tertiaryZone then table.insert(zones, squadron.tertiaryZone) end
                    
                    for _, zoneName in ipairs(zones) do
                        local zoneObj = ZONE:FindByName(zoneName)
                        if not zoneObj then
                            -- Check if there's a helicopter unit/group with this name for zone creation
                            local unit = UNIT:FindByName(zoneName)
                            local group = GROUP:FindByName(zoneName)
                            if not unit and not group then
                                table.insert(errors, prefix .. "zone '" .. zoneName .. "' not found in mission (no zone or helicopter unit named '" .. zoneName .. "')")
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Report errors
    if #errors > 0 then
    log("CONFIGURATION ERRORS DETECTED:")
    MESSAGE:New("CONFIGURATION ERRORS DETECTED:", 30):ToAll()
        for _, error in pairs(errors) do
            log("  ✗ " .. error)
            MESSAGE:New("CONFIG ERROR: " .. error, 30):ToAll()
        end
    log("Please fix configuration before using Universal TADC!")
    MESSAGE:New("Please fix configuration before using Universal TADC!", 30):ToAll()
        return false
    else
    log("Configuration validation passed ✓")
    MESSAGE:New("Universal TADC configuration passed ✓", 10):ToAll()
        return true
    end
end

-- Process cargo delivery for a squadron
local function processCargoDelivery(cargoGroup, squadron, coalitionSide, coalitionKey)
    -- Simple delivery processor: dedupe by group ID and credit supplies directly.
    if not _G.processedDeliveries then
        _G.processedDeliveries = {}
    end

    -- Use group ID + squadron airbase + coalition as dedupe key to avoid double crediting when the same group
    -- triggers multiple events or moves between airbases rapidly.
    local okId, grpId = pcall(function() return cargoGroup and cargoGroup.GetID and cargoGroup:GetID() end)
    local groupIdStr = (okId and grpId) and tostring(grpId) or "<no-id>"
    local deliveryKey = coalitionKey:upper() .. "_" .. groupIdStr .. "_" .. tostring(squadron.airbaseName)

    -- Diagnostic log: show group name, id, and delivery key when processor invoked
    local okName, grpName = pcall(function() return cargoGroup and cargoGroup.GetName and cargoGroup:GetName() end)
    local groupNameStr = (okName and grpName) and tostring(grpName) or "<no-name>"
    log("PROCESS CARGO: invoked for group=" .. groupNameStr .. " id=" .. groupIdStr .. " targetAirbase=" .. tostring(squadron.airbaseName) .. " deliveryKey=" .. deliveryKey, true)

    if _G.processedDeliveries[deliveryKey] then
        -- Already processed recently, ignore
        log("PROCESS CARGO: deliveryKey " .. deliveryKey .. " already processed at " .. tostring(_G.processedDeliveries[deliveryKey]), true)
        return
    end

    -- Mark processed immediately
    _G.processedDeliveries[deliveryKey] = timer.getTime()

    -- Credit the squadron
    local currentCount = squadronAircraftCounts[coalitionKey][squadron.templateName] or 0
    local maxCount = squadron.aircraft or 0
    local addAmount = TADC_SETTINGS[coalitionKey].cargoReplenishmentAmount or 0
    local newCount = math.min(currentCount + addAmount, maxCount)
    local actualAdded = newCount - currentCount

    if actualAdded > 0 then
        squadronAircraftCounts[coalitionKey][squadron.templateName] = newCount
        local msg = coalitionKey:upper() .. " CARGO DELIVERY: " .. cargoGroup:GetName() .. " delivered " .. actualAdded ..
            " aircraft to " .. (squadron.displayName or squadron.templateName) ..
            " (" .. newCount .. "/" .. maxCount .. ")"
        log(msg)
        MESSAGE:New(msg, 20):ToCoalition(coalitionSide)
        USERSOUND:New("Cargo_Delivered.ogg"):ToCoalition(coalitionSide)
    else
        local msg = coalitionKey:upper() .. " CARGO DELIVERY: " .. (squadron.displayName or squadron.templateName) .. " already at max capacity"
        log(msg, true)
        MESSAGE:New(msg, 10):ToCoalition(coalitionSide)
        USERSOUND:New("Cargo_Delivered.ogg"):ToCoalition(coalitionSide)
    end

    finalizeCargoMission(cargoGroup, squadron, coalitionKey)
end

-- Event handler for cargo aircraft landing (backup for actual landings)
local cargoEventHandler = {}
function cargoEventHandler:onEvent(event)
    if event.id == world.event.S_EVENT_LAND then
        local unit = event.initiator
        
        -- Safe unit name retrieval
        local unitName = "unknown"
        if unit and type(unit) == "table" then
            local ok, name = pcall(function() return unit:GetName() end)
            if ok and name then
                unitName = name
            end
        end
        
        log("LANDING EVENT: Received S_EVENT_LAND for unit: " .. unitName, true)
        
        if unit and type(unit) == "table" and unit.IsAlive and unit:IsAlive() then
            local group = unit:GetGroup()
            if group and type(group) == "table" and group.IsAlive and group:IsAlive() then
                -- Safe group name retrieval
                local cargoName = "unknown"
                local ok, name = pcall(function() return group:GetName():upper() end)
                if ok and name then
                    cargoName = name
                end
                
                log("LANDING EVENT: Processing group: " .. cargoName, true)
                
                local isCargoAircraft = false
                
                -- Check if aircraft name matches cargo patterns
                for _, pattern in pairs(ADVANCED_SETTINGS.cargoPatterns) do
                    if string.find(cargoName, pattern) then
                        isCargoAircraft = true
                        log("LANDING EVENT: Matched cargo pattern '" .. pattern .. "' for " .. cargoName, true)
                        break
                    end
                end
                
                if isCargoAircraft then
                    -- Safe coordinate and coalition retrieval
                    local cargoCoord = nil
                    local ok, coord = pcall(function() return unit:GetCoordinate() end)
                    if ok and coord then
                        cargoCoord = coord
                    end
                    
                    log("LANDING EVENT: Cargo aircraft " .. cargoName .. " at coord: " .. tostring(cargoCoord), true)

                    if cargoCoord then
                        local closestAirbase = nil
                        local closestDistance = math.huge
                        local closestSquadron = nil

                        -- Search RED squadron configs
                        for _, squadron in pairs(RED_SQUADRON_CONFIG) do
                            local airbase = AIRBASE:FindByName(squadron.airbaseName)
                            if airbase then
                                local distance = cargoCoord:Get2DDistance(airbase:GetCoordinate())
                                log("LANDING EVENT: Checking distance to " .. squadron.airbaseName .. ": " .. math.floor(distance) .. "m", true)
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestAirbase = airbase
                                    closestSquadron = squadron
                                end
                            end
                        end

                        -- Search BLUE squadron configs
                        for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
                            local airbase = AIRBASE:FindByName(squadron.airbaseName)
                            if airbase then
                                local distance = cargoCoord:Get2DDistance(airbase:GetCoordinate())
                                log("LANDING EVENT: Checking distance to " .. squadron.airbaseName .. ": " .. math.floor(distance) .. "m", true)
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestAirbase = airbase
                                    closestSquadron = squadron
                                end
                            end
                        end

                        if closestAirbase and closestSquadron then
                            local abCoalition = closestAirbase:GetCoalition()
                            local coalitionKey = (abCoalition == coalition.side.RED) and "red" or "blue"
                            if closestDistance < ADVANCED_SETTINGS.cargoLandingEventRadius then
                                log("LANDING DELIVERY: " .. cargoName .. " landed and delivered at " .. closestSquadron.airbaseName .. " (distance: " .. math.floor(closestDistance) .. "m)")
                                processCargoDelivery(group, closestSquadron, abCoalition, coalitionKey)
                            else
                                log("LANDING DETECTED: " .. cargoName .. " landed but no valid airbase found within range (closest: " .. (closestDistance and math.floor(closestDistance) .. "m" or "none") .. ")")
                            end
                        else
                            log("LANDING DETECTED: " .. cargoName .. " landed but no configured squadron airbases available to check", true)
                        end
                    else
                        log("LANDING EVENT: Could not get coordinates for cargo aircraft " .. cargoName, true)
                    end
                else
                    log("LANDING EVENT: " .. cargoName .. " is not a cargo aircraft", true)
                end
            else
                log("LANDING EVENT: Group is nil or not alive", true)
            end
        else
            -- Fallback: unit was nil or not alive (race/despawn). Try to retrieve group and name safely
            log("LANDING EVENT: Unit is nil or not alive - attempting fallback group retrieval", true)

            local fallbackGroup = nil
            local okGetGroup, grp = pcall(function()
                if unit and type(unit) == "table" and unit.GetGroup then
                    return unit:GetGroup()
                end
                -- Try event.initiator (may be raw DCS object)
                if event and event.initiator and type(event.initiator) == 'table' and event.initiator.GetGroup then
                    return event.initiator:GetGroup()
                end
                return nil
            end)

            if okGetGroup and grp then
                fallbackGroup = grp
            end

            if fallbackGroup then
                -- Try to get group name even if group:IsAlive() is false
                local okName, gname = pcall(function() return fallbackGroup:GetName():upper() end)
                local cargoName = "unknown"
                if okName and gname then
                    cargoName = gname
                end

                log("LANDING EVENT (fallback): Processing group: " .. cargoName, true)

                local isCargoAircraft = false
                for _, pattern in pairs(ADVANCED_SETTINGS.cargoPatterns) do
                    if string.find(cargoName, pattern) then
                        isCargoAircraft = true
                        log("LANDING EVENT (fallback): Matched cargo pattern '" .. pattern .. "' for " .. cargoName, true)
                        break
                    end
                end

                if isCargoAircraft then
                    -- Try to get coordinate and coalition via multiple safe methods
                    local cargoCoord = nil
                    local okCoord, coord = pcall(function()
                        if unit and unit.GetCoordinate then return unit:GetCoordinate() end
                        if fallbackGroup and fallbackGroup.GetCoordinate then return fallbackGroup:GetCoordinate() end
                        return nil
                    end)
                    if okCoord and coord then cargoCoord = coord end

                    log("LANDING EVENT (fallback): Cargo aircraft " .. cargoName .. " at coord: " .. tostring(cargoCoord), true)

                    if cargoCoord then
                        local closestAirbase = nil
                        local closestDistance = math.huge
                        local closestSquadron = nil

                        for _, squadron in pairs(RED_SQUADRON_CONFIG) do
                            local airbase = AIRBASE:FindByName(squadron.airbaseName)
                            if airbase then
                                local distance = cargoCoord:Get2DDistance(airbase:GetCoordinate())
                                log("LANDING EVENT (fallback): Checking distance to " .. squadron.airbaseName .. ": " .. math.floor(distance) .. "m", true)
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestAirbase = airbase
                                    closestSquadron = squadron
                                end
                            end
                        end

                        for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
                            local airbase = AIRBASE:FindByName(squadron.airbaseName)
                            if airbase then
                                local distance = cargoCoord:Get2DDistance(airbase:GetCoordinate())
                                log("LANDING EVENT (fallback): Checking distance to " .. squadron.airbaseName .. ": " .. math.floor(distance) .. "m", true)
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestAirbase = airbase
                                    closestSquadron = squadron
                                end
                            end
                        end

                        if closestAirbase and closestSquadron then
                            local abCoalition = closestAirbase:GetCoalition()
                            local coalitionKey = (abCoalition == coalition.side.RED) and "red" or "blue"
                            if closestDistance < ADVANCED_SETTINGS.cargoLandingEventRadius then
                                log("LANDING DELIVERY (fallback): " .. cargoName .. " landed and delivered at " .. closestSquadron.airbaseName .. " (distance: " .. math.floor(closestDistance) .. "m)")
                                processCargoDelivery(fallbackGroup, closestSquadron, abCoalition, coalitionKey)
                            else
                                log("LANDING DETECTED (fallback): " .. cargoName .. " landed but no valid airbase found within range (closest: " .. (closestDistance and math.floor(closestDistance) .. "m" or "none") .. ")")
                            end
                        else
                            log("LANDING EVENT (fallback): No configured squadron airbases available to check", true)
                        end
                    else
                        log("LANDING EVENT (fallback): Could not get coordinates for cargo aircraft " .. cargoName, true)
                    end
                else
                    log("LANDING EVENT (fallback): " .. cargoName .. " is not a cargo aircraft", true)
                end
            else
                log("LANDING EVENT: Fallback group retrieval failed", true)
                -- Additional fallback: try raw DCS object methods (lowercase) and resolve by name
                local okRaw, rawGroup = pcall(function()
                    if event and event.initiator and type(event.initiator) == 'table' and event.initiator.getGroup then
                        return event.initiator:getGroup()
                    end
                    return nil
                end)

                if okRaw and rawGroup then
                    -- Try to get raw group name
                    local okRawName, rawName = pcall(function()
                        if rawGroup.getName then return rawGroup:getName() end
                        return nil
                    end)

                    if okRawName and rawName then
                        local rawNameUp = tostring(rawName):upper()
                        log("LANDING EVENT: Resolved raw DCS group name: " .. rawNameUp, true)

                        -- Try to find MOOSE GROUP by that name
                        local okFind, mooseGroup = pcall(function() return GROUP:FindByName(rawNameUp) end)
                        if okFind and mooseGroup and type(mooseGroup) == 'table' then
                            log("LANDING EVENT: Found MOOSE GROUP for raw name: " .. rawNameUp, true)
                            -- Reuse the fallback logic using mooseGroup
                            local cargoName = rawNameUp
                            local isCargoAircraft = false
                            for _, pattern in pairs(ADVANCED_SETTINGS.cargoPatterns) do
                                if string.find(cargoName, pattern) then
                                    isCargoAircraft = true
                                    break
                                end
                            end
                            if isCargoAircraft then
                                -- Try to get coordinate from raw group if possible
                                local cargoCoord = nil
                                local okPoint, point = pcall(function()
                                    if rawGroup.getController then
                                        -- Raw DCS unit list -> first unit point
                                        local dcs = rawGroup
                                        if dcs.getUnits then
                                            local units = dcs:getUnits()
                                            if units and #units > 0 and units[1].getPoint then
                                                return units[1]:getPoint()
                                            end
                                        end
                                    end
                                    return nil
                                end)
                                if okPoint and point then cargoCoord = point end

                                -- If we have a coordinate, find nearest squadron and process
                                if cargoCoord then
                                    local closestAirbase = nil
                                    local closestDistance = math.huge
                                    local closestSquadron = nil

                                    for _, squadron in pairs(RED_SQUADRON_CONFIG) do
                                        local airbase = AIRBASE:FindByName(squadron.airbaseName)
                                        if airbase then
                                            local distance = math.huge
                                            if type(cargoCoord) == 'table' and cargoCoord.Get2DDistance then
                                                local okDist, d = pcall(function() return cargoCoord:Get2DDistance(airbase:GetCoordinate()) end)
                                                if okDist and d then distance = d end
                                            else
                                                local okVec, aVec = pcall(function() return airbase:GetCoordinate():GetVec2() end)
                                                if okVec and aVec and type(aVec) == 'table' then
                                                    local cx, cy
                                                    if cargoCoord.x and cargoCoord.z then
                                                        cx, cy = cargoCoord.x, cargoCoord.z
                                                    elseif cargoCoord.x and cargoCoord.y then
                                                        cx, cy = cargoCoord.x, cargoCoord.y
                                                    elseif cargoCoord[1] and cargoCoord[3] then
                                                        cx, cy = cargoCoord[1], cargoCoord[3]
                                                    elseif cargoCoord[1] and cargoCoord[2] then
                                                        cx, cy = cargoCoord[1], cargoCoord[2]
                                                    end
                                                    if cx and cy then
                                                        local dx = cx - aVec.x
                                                        local dy = cy - aVec.y
                                                        distance = math.sqrt(dx*dx + dy*dy)
                                                    end
                                                end
                                            end

                                            if distance < closestDistance then
                                                closestDistance = distance
                                                closestAirbase = airbase
                                                closestSquadron = squadron
                                            end
                                        end
                                    end

                                    for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
                                        local airbase = AIRBASE:FindByName(squadron.airbaseName)
                                        if airbase then
                                            local distance = math.huge
                                            if type(cargoCoord) == 'table' and cargoCoord.Get2DDistance then
                                                local okDist, d = pcall(function() return cargoCoord:Get2DDistance(airbase:GetCoordinate()) end)
                                                if okDist and d then distance = d end
                                            else
                                                local okVec, aVec = pcall(function() return airbase:GetCoordinate():GetVec2() end)
                                                if okVec and aVec and type(aVec) == 'table' then
                                                    local cx, cy
                                                    if cargoCoord.x and cargoCoord.z then
                                                        cx, cy = cargoCoord.x, cargoCoord.z
                                                    elseif cargoCoord.x and cargoCoord.y then
                                                        cx, cy = cargoCoord.x, cargoCoord.y
                                                    elseif cargoCoord[1] and cargoCoord[3] then
                                                        cx, cy = cargoCoord[1], cargoCoord[3]
                                                    elseif cargoCoord[1] and cargoCoord[2] then
                                                        cx, cy = cargoCoord[1], cargoCoord[2]
                                                    end
                                                    if cx and cy then
                                                        local dx = cx - aVec.x
                                                        local dy = cy - aVec.y
                                                        distance = math.sqrt(dx*dx + dy*dy)
                                                    end
                                                end
                                            end

                                            if distance < closestDistance then
                                                closestDistance = distance
                                                closestAirbase = airbase
                                                closestSquadron = squadron
                                            end
                                        end
                                    end

                                    if closestAirbase and closestSquadron and closestDistance and closestDistance < ADVANCED_SETTINGS.cargoLandingEventRadius then
                                        local abCoalition = closestAirbase:GetCoalition()
                                        local coalitionKey = (abCoalition == coalition.side.RED) and "red" or "blue"
                                        log("LANDING DELIVERY (raw-fallback): " .. rawNameUp .. " landed and delivered at " .. closestSquadron.airbaseName .. " (distance: " .. math.floor(closestDistance) .. "m)")
                                        processCargoDelivery(mooseGroup, closestSquadron, abCoalition, coalitionKey)
                                    else
                                        log("LANDING DETECTED (raw-fallback): " .. rawNameUp .. " landed but no valid airbase found within range (closest: " .. (closestDistance and math.floor(closestDistance) .. "m" or "none") .. ")")
                                    end
                                else
                                    log("LANDING EVENT: Could not extract coordinate from raw DCS group: " .. tostring(rawName), true)
                                end
                            else
                                log("LANDING EVENT: Raw group " .. tostring(rawName) .. " is not a cargo aircraft", true)
                            end
                        else
                            log("LANDING EVENT: Could not find MOOSE GROUP for raw name: " .. tostring(rawName) .. " - attempting raw-group proxy processing", true)

                            -- Even if we can't find a MOOSE GROUP, try to extract coordinates from the raw DCS group
                            local okPoint2, point2 = pcall(function()
                                if rawGroup and rawGroup.getUnits then
                                    local units = rawGroup:getUnits()
                                    if units and #units > 0 and units[1].getPoint then
                                        return units[1]:getPoint()
                                    end
                                end
                                return nil
                            end)

                            if okPoint2 and point2 then
                                local cargoCoord = point2
                                -- Find nearest configured squadron airbase (RED + BLUE)
                                local closestAirbase = nil
                                local closestDistance = math.huge
                                local closestSquadron = nil

                                for _, squadron in pairs(RED_SQUADRON_CONFIG) do
                                    local airbase = AIRBASE:FindByName(squadron.airbaseName)
                                    if airbase then
                                        local distance = math.huge
                                        local okVec, aVec = pcall(function() return airbase:GetCoordinate():GetVec2() end)
                                        if okVec and aVec and type(aVec) == 'table' then
                                            local cx, cy
                                            if cargoCoord.x and cargoCoord.z then
                                                cx, cy = cargoCoord.x, cargoCoord.z
                                            elseif cargoCoord.x and cargoCoord.y then
                                                cx, cy = cargoCoord.x, cargoCoord.y
                                            elseif cargoCoord[1] and cargoCoord[3] then
                                                cx, cy = cargoCoord[1], cargoCoord[3]
                                            elseif cargoCoord[1] and cargoCoord[2] then
                                                cx, cy = cargoCoord[1], cargoCoord[2]
                                            end
                                            if cx and cy then
                                                local dx = cx - aVec.x
                                                local dy = cy - aVec.y
                                                distance = math.sqrt(dx*dx + dy*dy)
                                            end
                                        end

                                        if distance < closestDistance then
                                            closestDistance = distance
                                            closestAirbase = airbase
                                            closestSquadron = squadron
                                        end
                                    end
                                end

                                for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
                                    local airbase = AIRBASE:FindByName(squadron.airbaseName)
                                    if airbase then
                                        local distance = math.huge
                                        local okVec, aVec = pcall(function() return airbase:GetCoordinate():GetVec2() end)
                                        if okVec and aVec and type(aVec) == 'table' then
                                            local cx, cy
                                            if cargoCoord.x and cargoCoord.z then
                                                cx, cy = cargoCoord.x, cargoCoord.z
                                            elseif cargoCoord.x and cargoCoord.y then
                                                cx, cy = cargoCoord.x, cargoCoord.y
                                            elseif cargoCoord[1] and cargoCoord[3] then
                                                cx, cy = cargoCoord[1], cargoCoord[3]
                                            elseif cargoCoord[1] and cargoCoord[2] then
                                                cx, cy = cargoCoord[1], cargoCoord[2]
                                            end
                                            if cx and cy then
                                                local dx = cx - aVec.x
                                                local dy = cy - aVec.y
                                                distance = math.sqrt(dx*dx + dy*dy)
                                            end
                                        end

                                        if distance < closestDistance then
                                            closestDistance = distance
                                            closestAirbase = airbase
                                            closestSquadron = squadron
                                        end
                                    end
                                end

                                if closestAirbase and closestSquadron and closestDistance and closestDistance < ADVANCED_SETTINGS.cargoLandingEventRadius then
                                    local abCoalition = closestAirbase:GetCoalition()
                                    local coalitionKey = (abCoalition == coalition.side.RED) and "red" or "blue"

                                    -- Ensure the raw group name actually looks like a cargo aircraft before crediting
                                    local rawNameUpCheck = tostring(rawName):upper()
                                    local isCargoProxy = false
                                    for _, pattern in pairs(ADVANCED_SETTINGS.cargoPatterns) do
                                        if string.find(rawNameUpCheck, pattern) then
                                            isCargoProxy = true
                                            break
                                        end
                                    end

                                    if not isCargoProxy then
                                        if ADVANCED_SETTINGS.verboseProxyLogging then
                                            log("LANDING IGNORED (raw-proxy): " .. tostring(rawName) .. " is not a cargo-type name, skipping delivery proxy", true)
                                        else
                                            log("LANDING IGNORED (raw-proxy): " .. tostring(rawName) .. " is not a cargo-type name, skipping delivery proxy", true)
                                        end
                                    else
                                        -- Build a small proxy object that exposes GetName and GetID so processCargoDelivery can use it
                                        local cargoProxy = {}
                                        function cargoProxy:GetName()
                                            local okn, nm = pcall(function()
                                                if rawGroup and rawGroup.getName then return rawGroup:getName() end
                                                return tostring(rawName)
                                            end)
                                            return (okn and nm) and tostring(nm) or tostring(rawName)
                                        end
                                        function cargoProxy:GetID()
                                            local okid, id = pcall(function()
                                                if rawGroup and rawGroup.getID then return rawGroup:getID() end
                                                if rawGroup and rawGroup.getID == nil and rawGroup.getController then
                                                    -- Try to hash name as fallback unique-ish id
                                                    return tostring(rawName) .. "_proxy"
                                                end
                                                return nil
                                            end)
                                            return (okid and id) and id or tostring(rawName) .. "_proxy"
                                        end

                                        if ADVANCED_SETTINGS.verboseProxyLogging then
                                            local distanceStr = closestDistance and math.floor(closestDistance) .. "m" or "unknown"
                                            log("LANDING DELIVERY (raw-proxy): " .. tostring(rawName) .. " landed and delivered at " .. closestSquadron.airbaseName .. " (distance: " .. distanceStr .. ") - using proxy object", true)
                                        end
                                        processCargoDelivery(cargoProxy, closestSquadron, abCoalition, coalitionKey)
                                    end
                                else
                                    if ADVANCED_SETTINGS.verboseProxyLogging then
                                        log("LANDING DETECTED (raw-proxy): " .. tostring(rawName) .. " landed but no valid airbase found within range (closest: " .. (closestDistance and math.floor(closestDistance) .. "m" or "none") .. ")", true)
                                    end
                                end
                            else
                                log("LANDING EVENT: Could not extract coordinate from raw DCS group for proxy processing: " .. tostring(rawName), true)
                            end
                        end
                    else
                        log("LANDING EVENT: rawGroup:getName() failed", true)
                    end
                else
                    log("LANDING EVENT: raw DCS group retrieval failed", true)
                end
            end
        end
    end
end

-- Reassign squadron to an alternative airbase when primary airbase has issues
local function reassignSquadronToAlternativeAirbase(squadron, coalitionKey)
    local coalitionSide = (coalitionKey == "red") and coalition.side.RED or coalition.side.BLUE
    local coalitionName = (coalitionKey == "red") and "RED" or "BLUE"
    local squadronConfig = getSquadronConfig(coalitionSide)
    
    -- Find alternative airbases (other squadrons' airbases that are operational)
    local alternativeAirbases = {}
    for _, altSquadron in pairs(squadronConfig) do
        if altSquadron.airbaseName ~= squadron.airbaseName then
            local usable, status = isAirbaseUsable(altSquadron.airbaseName, coalitionSide)
            local healthStatus = airbaseHealthStatus[coalitionKey][altSquadron.airbaseName] or "operational"
            
            if usable and healthStatus == "operational" then
                table.insert(alternativeAirbases, altSquadron.airbaseName)
            end
        end
    end
    
    if #alternativeAirbases > 0 then
        -- Select random alternative airbase
        local newAirbase = alternativeAirbases[math.random(1, #alternativeAirbases)]
        
        -- Update squadron configuration (this is a runtime change)
        squadron.airbaseName = newAirbase
        airbaseHealthStatus[coalitionKey][squadron.airbaseName] = "operational" -- Reset health for new assignment
        
        log("REASSIGNED: " .. coalitionName .. " Squadron " .. squadron.displayName .. " moved from " .. squadron.airbaseName .. " to " .. newAirbase)
        MESSAGE:New(coalitionName .. " Squadron " .. squadron.displayName .. " reassigned to " .. newAirbase .. " due to airbase issues", 20):ToCoalition(coalitionSide)
    else
        log("WARNING: No alternative airbases available for " .. coalitionName .. " Squadron " .. squadron.displayName)
        MESSAGE:New("WARNING: No alternative airbases available for " .. squadron.displayName, 30):ToCoalition(coalitionSide)
    end
end

-- Monitor for stuck aircraft at airbases
local function monitorStuckAircraft()
    local currentTime = timer.getTime()
    local stuckThreshold = 300 -- 5 minutes before considering aircraft stuck
    local movementThreshold = 50 -- meters - aircraft must move at least this far to not be considered stuck
    
    for _, coalitionKey in ipairs({"red", "blue"}) do
        local coalitionName = (coalitionKey == "red") and "RED" or "BLUE"
        
        for aircraftName, trackingData in pairs(aircraftSpawnTracking[coalitionKey]) do
            if trackingData and trackingData.group and trackingData.group:IsAlive() then
                local timeSinceSpawn = currentTime - trackingData.spawnTime
                
                -- Only check aircraft that have been spawned for at least the threshold time
                if timeSinceSpawn >= stuckThreshold then
                    local currentPos = safeCoordinate(trackingData.group)
                    local spawnPos = trackingData.spawnPos
                    local distanceMoved = nil

                    if currentPos and spawnPos and type(spawnPos) == "table" and spawnPos.Get2DDistance then
                        local okDist, dist = pcall(function() return spawnPos:Get2DDistance(currentPos) end)
                        if okDist and dist then
                            distanceMoved = dist
                        end
                    end

                    if distanceMoved then
                        
                        -- Check if aircraft has moved less than threshold (stuck)
                        if distanceMoved < movementThreshold then
                            log("STUCK AIRCRAFT DETECTED: " .. aircraftName .. " at " .. trackingData.airbase .. 
                                " has only moved " .. math.floor(distanceMoved) .. "m in " .. math.floor(timeSinceSpawn/60) .. " minutes")
                            
                            -- Mark airbase as having stuck aircraft
                            airbaseHealthStatus[coalitionKey][trackingData.airbase] = "stuck-aircraft"
                            
                            -- Remove the stuck aircraft and clear tracking
                            pcall(function() trackingData.group:Destroy() end)
                            cleanupInterceptorEntry(aircraftName, coalitionKey)
                            
                            -- Reassign squadron to alternative airbase
                            reassignSquadronToAlternativeAirbase(trackingData.squadron, coalitionKey)
                            
                            MESSAGE:New(coalitionName .. " aircraft stuck at " .. trackingData.airbase .. " - destroyed and squadron reassigned", 15):ToCoalition(coalitionKey == "red" and coalition.side.RED or coalition.side.BLUE)
                        else
                            -- Aircraft has moved sufficiently, remove from tracking (no longer needs monitoring)
                            log("Aircraft " .. aircraftName .. " has moved " .. math.floor(distanceMoved) .. "m - removing from stuck monitoring", true)
                            aircraftSpawnTracking[coalitionKey][aircraftName] = nil
                        end
                    else
                        log("Stuck monitor: no coordinate data for " .. aircraftName .. "; removing from tracking", true)
                        aircraftSpawnTracking[coalitionKey][aircraftName] = nil
                    end
                end
            else
                -- Clean up dead aircraft from tracking
                aircraftSpawnTracking[coalitionKey][aircraftName] = nil
            end
        end
    end
end

-- Send interceptor back to base
local function sendInterceptorHome(interceptor, coalitionSide)
    if not interceptor or not interceptor:IsAlive() then
        return
    end
    
    -- Find nearest friendly airbase
    local interceptorCoord = safeCoordinate(interceptor)
    if not interceptorCoord then
        log("ERROR: Could not get interceptor coordinates for RTB", true)
        return
    end
    local nearestAirbase = nil
    local nearestAirbaseCoord = nil
    local shortestDistance = math.huge
    local squadronConfig = getSquadronConfig(coalitionSide)
    
    -- Check all squadron airbases to find the nearest one that's still friendly
    for _, squadron in pairs(squadronConfig) do
        local airbase = AIRBASE:FindByName(squadron.airbaseName)
        if airbase and airbase:GetCoalition() == coalitionSide and airbase:IsAlive() then
            local airbaseCoord = safeCoordinate(airbase)
            if airbaseCoord then
                local okDist, distance = pcall(function() return interceptorCoord:Get2DDistance(airbaseCoord) end)
                if okDist and distance and distance < shortestDistance then
                    shortestDistance = distance
                    nearestAirbase = airbase
                    nearestAirbaseCoord = airbaseCoord
                end
            end
        end
    end
    
    if nearestAirbase and nearestAirbaseCoord then
        local airbaseName = "airbase"
        local okABName, fetchedABName = pcall(function() return nearestAirbase:GetName() end)
        if okABName and fetchedABName then
            airbaseName = fetchedABName
        end

        local rtbAltitude = ADVANCED_SETTINGS.rtbAltitude * 0.3048 -- Convert feet to meters
        local okRtb, rtbCoord = pcall(function() return nearestAirbaseCoord:SetAltitude(rtbAltitude) end)
        if not okRtb or not rtbCoord then
            log("ERROR: Failed to compute RTB coordinate for " .. airbaseName, true)
            return
        end
        
        -- Clear current tasks and route home
        pcall(function() interceptor:ClearTasks() end)
        local routeOk, routeErr = pcall(function() interceptor:RouteAirTo(rtbCoord, ADVANCED_SETTINGS.rtbSpeed * 0.5144, "BARO") end)
        
        local _, coalitionName = getCoalitionSettings(coalitionSide)
        local interceptorName = "interceptor"
        local okName, fetchedName = pcall(function() return interceptor:GetName() end)
        if okName and fetchedName then
            interceptorName = fetchedName
        end

        if not routeOk and routeErr then
            log("ERROR: Failed to assign RTB route for " .. interceptorName .. " -> " .. airbaseName .. ": " .. tostring(routeErr), true)
        else
            log("Sending " .. coalitionName .. " " .. interceptorName .. " back to " .. airbaseName, true)
        end
        
        -- Schedule cleanup after they should have landed
        local coalitionSettings = getCoalitionSettings(coalitionSide)
        local rtbBuffer = (coalitionSettings and coalitionSettings.rtbFlightBuffer) or 300
        local flightTime = math.ceil(shortestDistance / (ADVANCED_SETTINGS.rtbSpeed * 0.5144)) + rtbBuffer
        
        SCHEDULER:New(nil, function()
            local coalitionKey = (coalitionSide == coalition.side.RED) and "red" or "blue"
            local name = nil
            if interceptor and interceptor.GetName then
                local ok, value = pcall(function() return interceptor:GetName() end)
                if ok then name = value end
            end
            if name and activeInterceptors[coalitionKey][name] then
                destroyInterceptorGroup(interceptor, coalitionKey, 0)
                log("Cleaned up " .. coalitionName .. " " .. name .. " after RTB", true)
            end
        end, {}, flightTime)
    else
        local _, coalitionName = getCoalitionSettings(coalitionSide)
        log("No friendly airbase found for " .. coalitionName .. " " .. interceptor:GetName() .. ", will clean up normally")
    end
end

-- Check if airbase is still usable
local function isAirbaseUsable(airbaseName, expectedCoalition)
    local airbase = AIRBASE:FindByName(airbaseName)
    if not airbase then
        return false, "not found"
    elseif airbase:GetCoalition() ~= expectedCoalition then
        local capturedBy = "Unknown"
        if airbase:GetCoalition() == coalition.side.RED then
            capturedBy = "Red"
        elseif airbase:GetCoalition() == coalition.side.BLUE then
            capturedBy = "Blue"
        else
            capturedBy = "Neutral"
        end
        return false, "captured by " .. capturedBy
    elseif not airbase:IsAlive() then
        return false, "destroyed"
    else
        return true, "operational"
    end
end

-- Count active fighters for coalition
local function countActiveFighters(coalitionSide)
    local count = 0
    local coalitionKey = (coalitionSide == coalition.side.RED) and "red" or "blue"
    
    for _, interceptorData in pairs(activeInterceptors[coalitionKey]) do
        if interceptorData and interceptorData.group and interceptorData.group:IsAlive() then
            count = count + interceptorData.group:GetSize()
        end
    end
    return count
end

-- Find best squadron to launch for coalition using zone-based priorities
local function findBestSquadron(threatCoord, threatSize, coalitionSide)
    local bestSquadron = nil
    local bestPriority = "none"
    local bestResponseRatio = 0
    local shortestDistance = math.huge
    local currentTime = timer.getTime()
    local squadronConfig = getSquadronConfig(coalitionSide)
    local coalitionSettings, coalitionName = getCoalitionSettings(coalitionSide)
    local coalitionKey = (coalitionSide == coalition.side.RED) and "red" or "blue"
    local zonePriorityOrder = {"tertiary", "primary", "secondary", "global"}
    
    -- First pass: find squadrons that can respond to this threat
    local availableSquadrons = {}
    
    for _, squadron in pairs(squadronConfig) do
        -- Check basic availability
        local squadronAvailable = true
        local unavailableReason = ""
        
        -- Check squadron state first
        if squadron.state and squadron.state ~= "operational" then
            squadronAvailable = false
            if squadron.state == "captured" then
                unavailableReason = "airbase captured by enemy"
            elseif squadron.state == "destroyed" then
                unavailableReason = "airbase destroyed"
            else
                unavailableReason = "squadron not operational (state: " .. tostring(squadron.state) .. ")"
            end
        end
        
        -- Check cooldown
        if squadronAvailable and squadronCooldowns[coalitionKey][squadron.templateName] then
            local cooldownEnd = squadronCooldowns[coalitionKey][squadron.templateName]
            if currentTime < cooldownEnd then
                local timeLeft = math.ceil((cooldownEnd - currentTime) / 60)
                squadronAvailable = false
                unavailableReason = "on cooldown for " .. timeLeft .. "m"
            else
                -- Cooldown expired, remove it
                squadronCooldowns[coalitionKey][squadron.templateName] = nil
                log(coalitionName .. " Squadron " .. squadron.displayName .. " cooldown expired, available for launch", true)
            end
        end
        
        -- Check aircraft availability
        if squadronAvailable then
            local availableAircraft = squadronAircraftCounts[coalitionKey][squadron.templateName] or 0
            if availableAircraft <= 0 then
                squadronAvailable = false
                unavailableReason = "no aircraft available (" .. availableAircraft .. "/" .. squadron.aircraft .. ")"
            end
        end
        
        -- Check airbase status
        if squadronAvailable then
            local airbase = AIRBASE:FindByName(squadron.airbaseName)
            if not airbase then
                squadronAvailable = false
                unavailableReason = "airbase not found"
            elseif airbase:GetCoalition() ~= coalitionSide then
                squadronAvailable = false
                unavailableReason = "airbase no longer under " .. coalitionName .. " control"
            elseif not airbase:IsAlive() then
                squadronAvailable = false
                unavailableReason = "airbase destroyed"
            end
        end
        
        -- Check template exists (Note: Templates are validated during SPAWN:New() call)
        -- Template validation is handled by MOOSE SPAWN class during actual spawning
        
        if squadronAvailable then
            -- Get zone priority and response ratio
            local zonePriority, responseRatio, zoneDescription = getThreatZonePriority(threatCoord, squadron, coalitionSide)
            
            -- Check if threat meets priority threshold for secondary zones
            local zoneConfig = squadron.zoneConfig or getDefaultZoneConfig()
            if zonePriority == "secondary" and zoneConfig.ignoreLowPriority then
                if threatSize < zoneConfig.priorityThreshold then
                    log(coalitionName .. " " .. squadron.displayName .. " ignoring low-priority threat in secondary zone (" .. 
                        threatSize .. " < " .. zoneConfig.priorityThreshold .. ")", true)
                    responseRatio = 0
                    zonePriority = "none"
                end
            end
            
            if responseRatio > 0 then
                local airbase = AIRBASE:FindByName(squadron.airbaseName)
                local airbaseCoord = airbase:GetCoordinate()
                local distance = airbaseCoord:Get2DDistance(threatCoord)
                
                table.insert(availableSquadrons, {
                    squadron = squadron,
                    zonePriority = zonePriority,
                    responseRatio = responseRatio,
                    distance = distance,
                    zoneDescription = zoneDescription
                })
                
                log(coalitionName .. " " .. squadron.displayName .. " can respond: " .. zoneDescription .. 
                    " (ratio: " .. responseRatio .. ", distance: " .. math.floor(distance/1852) .. "nm)", true)
            else
                log(coalitionName .. " " .. squadron.displayName .. " will not respond: " .. zoneDescription, true)
            end
        else
            log(coalitionName .. " " .. squadron.displayName .. " unavailable: " .. unavailableReason, true)
        end
    end
    
    -- Second pass: select best squadron by priority and distance
    if #availableSquadrons > 0 then
        -- Sort by zone priority (higher priority first), then by distance (closer first)
        table.sort(availableSquadrons, function(a, b)
            -- Get priority indices
            local aPriorityIndex = 5
            local bPriorityIndex = 5
            for i, priority in ipairs(zonePriorityOrder) do
                if a.zonePriority == priority then aPriorityIndex = i end
                if b.zonePriority == priority then bPriorityIndex = i end
            end
            
            -- First sort by priority (lower index = higher priority)
            if aPriorityIndex ~= bPriorityIndex then
                return aPriorityIndex < bPriorityIndex
            end
            
            -- Then sort by distance (closer is better)
            return a.distance < b.distance
        end)
        
        local selected = availableSquadrons[1]
        log("Selected " .. coalitionName .. " " .. selected.squadron.displayName .. " for response: " .. 
            selected.zoneDescription .. " (distance: " .. math.floor(selected.distance/1852) .. "nm)")
        
        return selected.squadron, selected.responseRatio, selected.zoneDescription
    end
    
    if ADVANCED_SETTINGS.enableDetailedLogging then
        log("No " .. coalitionName .. " squadron available for threat at coordinates")
    end
    return nil, 0, "no available squadrons"
end

-- Launch interceptor for coalition
local function launchInterceptor(threatGroup, coalitionSide)
    if not threatGroup or not threatGroup:IsAlive() then
        return
    end
    
    local threatCoord = threatGroup:GetCoordinate()
    local threatName = threatGroup:GetName()
    local threatSize = threatGroup:GetSize()
    local coalitionSettings, coalitionName = getCoalitionSettings(coalitionSide)
    local coalitionKey = (coalitionSide == coalition.side.RED) and "red" or "blue"
    
    -- Check if threat already has interceptors assigned
    if assignedThreats[coalitionKey][threatName] then
        local assignedInterceptors = assignedThreats[coalitionKey][threatName]
        local aliveCount = 0
        
        -- Check if assigned interceptors are still alive
        if type(assignedInterceptors) == "table" then
            for _, interceptor in pairs(assignedInterceptors) do
                if interceptor and interceptor:IsAlive() then
                    aliveCount = aliveCount + 1
                end
            end
        else
            -- Handle legacy single interceptor assignment
            if assignedInterceptors and assignedInterceptors:IsAlive() then
                aliveCount = 1
            end
        end
        
        if aliveCount > 0 then
            return -- Still being intercepted
        else
            -- All interceptors are dead, clear the assignment
            assignedThreats[coalitionKey][threatName] = nil
        end
    end
    
    -- Find best squadron using zone-based priority system first
    local squadron, zoneResponseRatio, zoneDescription = findBestSquadron(threatCoord, threatSize, coalitionSide)
    
    if not squadron then
        if ADVANCED_SETTINGS.enableDetailedLogging then
            log("No " .. coalitionName .. " squadron available")
        end
        return
    end
    
    -- Calculate how many interceptors to launch using zone-modified ratio
    local baseInterceptRatio = (coalitionSettings and coalitionSettings.interceptRatio) or 1.0
    local finalInterceptRatio = baseInterceptRatio * zoneResponseRatio
    local interceptorsNeeded = math.max(1, math.ceil(threatSize * finalInterceptRatio))
    
    -- Check if we have capacity
    if coalitionSettings and countActiveFighters(coalitionSide) + interceptorsNeeded > coalitionSettings.maxActiveCAP then
        interceptorsNeeded = coalitionSettings.maxActiveCAP - countActiveFighters(coalitionSide)
        if interceptorsNeeded <= 0 then
            log(coalitionName .. " max fighters airborne, skipping launch")
            return
        end
    end
    if not squadron then
        if ADVANCED_SETTINGS.enableDetailedLogging then
            log("No " .. coalitionName .. " squadron available")
        end
        return
    end
    
    -- Limit interceptors to available aircraft
    local availableAircraft = squadronAircraftCounts[coalitionKey][squadron.templateName] or 0
    interceptorsNeeded = math.min(interceptorsNeeded, availableAircraft)
    
    if interceptorsNeeded <= 0 then
        log(coalitionName .. " Squadron " .. squadron.displayName .. " has no aircraft to launch")
        return
    end
    
    -- Launch multiple interceptors to match threat
    local spawn = SPAWN:New(squadron.templateName)
    if not spawn then
        log("ERROR: Failed to create SPAWN object for " .. coalitionName .. " " .. squadron.templateName)
        return
    end
    spawn:InitCleanUp(900)
    
    local interceptors = {}
    
    for i = 1, interceptorsNeeded do
        local interceptor = spawn:Spawn()
        
        if interceptor then
            table.insert(interceptors, interceptor)
            
            -- Wait a moment for initialization
            SCHEDULER:New(nil, function()
                if interceptor and interceptor:IsAlive() then
                    -- Set aggressive AI
                    interceptor:OptionROEOpenFire()
                    interceptor:OptionROTVertical()
                    
                    -- Route to threat
                    local currentThreatCoord = safeCoordinate(threatGroup)
                    if currentThreatCoord then
                        local okIntercept, interceptCoord = pcall(function()
                            return currentThreatCoord:SetAltitude(squadron.altitude * 0.3048)
                        end)
                        if okIntercept and interceptCoord then
                            pcall(function()
                                interceptor:RouteAirTo(interceptCoord, squadron.speed * 0.5144, "BARO")
                            end)
                        end
                        
                        -- Attack the threat
                        local attackTask = {
                            id = 'AttackGroup',
                            params = {
                                groupId = threatGroup:GetID(),
                                weaponType = 'Auto',
                                attackQtyLimit = 0,
                                priority = 1
                            }
                        }
                        interceptor:PushTask(attackTask, 1)
                    end
                end
            end, {}, 3)
            
            -- Track the interceptor with squadron info
            local interceptorName = "interceptor"
            local okName, fetchedName = pcall(function() return interceptor:GetName() end)
            if okName and fetchedName then
                interceptorName = fetchedName
            end

            activeInterceptors[coalitionKey][interceptorName] = {
                group = interceptor,
                squadron = squadron.templateName,
                displayName = squadron.displayName
            }
            
            -- Track spawn position for stuck aircraft detection
            local spawnPos = safeCoordinate(interceptor)
            if spawnPos then
                aircraftSpawnTracking[coalitionKey][interceptorName] = {
                    spawnPos = spawnPos,
                    spawnTime = timer.getTime(),
                    squadron = squadron,
                    airbase = squadron.airbaseName
                }
                log("Tracking spawn position for " .. interceptorName .. " at " .. squadron.airbaseName, true)
            end
            
            -- Emergency cleanup (safety net)
            local cleanupTime = (coalitionSettings and coalitionSettings.emergencyCleanupTime) or 7200
            SCHEDULER:New(nil, function()
                local name = nil
                if interceptor and interceptor.GetName then
                    local ok, value = pcall(function() return interceptor:GetName() end)
                    if ok then name = value end
                end
                if name and activeInterceptors[coalitionKey][name] then
                    log("Emergency cleanup of " .. coalitionName .. " " .. name .. " (should have RTB'd)")
                    destroyInterceptorGroup(interceptor, coalitionKey, 0)
                end
            end, {}, cleanupTime)
        end
    end
    
    -- Log the launch and track assignment
    if #interceptors > 0 then
        -- Decrement squadron aircraft count
        local currentCount = squadronAircraftCounts[coalitionKey][squadron.templateName] or 0
        squadronAircraftCounts[coalitionKey][squadron.templateName] = math.max(0, currentCount - #interceptors)
        local remainingCount = squadronAircraftCounts[coalitionKey][squadron.templateName]
        
        log("Launched " .. #interceptors .. " x " .. coalitionName .. " " .. squadron.displayName .. " to intercept " .. 
            threatSize .. " x " .. threatName .. " (" .. zoneDescription .. ", ratio: " .. string.format("%.1f", finalInterceptRatio) .. 
            ", remaining: " .. remainingCount .. "/" .. squadron.aircraft .. ")")
        assignedThreats[coalitionKey][threatName] = interceptors
        lastLaunchTime[coalitionKey][threatName] = timer.getTime()
        
        -- Apply cooldown immediately when squadron launches
        local currentTime = timer.getTime()
        if coalitionSettings and coalitionSettings.squadronCooldown then
            squadronCooldowns[coalitionKey][squadron.templateName] = currentTime + coalitionSettings.squadronCooldown
            local cooldownMinutes = coalitionSettings.squadronCooldown / 60
            cooldownMinutes = coalitionSettings.squadronCooldown / 60
        end
        log(coalitionName .. " Squadron " .. squadron.displayName .. " LAUNCHED! Applying " .. cooldownMinutes .. " minute cooldown")
    end
end

-- Main threat detection loop for coalition
local function detectThreatsForCoalition(coalitionSide)
    local coalitionSettings, coalitionName = getCoalitionSettings(coalitionSide)
    local enemyCoalition = (coalitionSide == coalition.side.RED) and "blue" or "red"
    local coalitionKey = (coalitionSide == coalition.side.RED) and "red" or "blue"
    
    log("Scanning for " .. coalitionName .. " threats...", true)
    
    -- Clean up dead threats from tracking
    local currentThreats = {}
    
    -- Find all enemy aircraft using cached set for performance
    local cacheKey = enemyCoalition .. "Aircraft"
    if not cachedSets[cacheKey] then
        cachedSets[cacheKey] = SET_GROUP:New():FilterCoalitions(enemyCoalition):FilterCategoryAirplane():FilterStart()
    end
    local enemyAircraft = cachedSets[cacheKey]
    local threatCount = 0
    
    if enemyAircraft then
        enemyAircraft:ForEach(function(enemyGroup)
        if enemyGroup and enemyGroup:IsAlive() then
            threatCount = threatCount + 1
            currentThreats[enemyGroup:GetName()] = true
            log("Found " .. coalitionName .. " threat: " .. enemyGroup:GetName() .. " (" .. enemyGroup:GetTypeName() .. ")", true)
            
            -- Launch interceptor for this threat
            launchInterceptor(enemyGroup, coalitionSide)
        end
    end)
    
    -- Clean up assignments for threats that no longer exist and send interceptors home
    for threatName, assignedInterceptors in pairs(assignedThreats[coalitionKey]) do
        if not currentThreats[threatName] then
            log("Threat " .. threatName .. " eliminated, sending " .. coalitionName .. " interceptors home...")
            
            -- Send assigned interceptors back to base
            if type(assignedInterceptors) == "table" then
                for _, interceptor in pairs(assignedInterceptors) do
                    if interceptor and interceptor:IsAlive() then
                        sendInterceptorHome(interceptor, coalitionSide)
                    end
                end
            else
                -- Handle legacy single interceptor assignment
                if assignedInterceptors and assignedInterceptors:IsAlive() then
                    sendInterceptorHome(assignedInterceptors, coalitionSide)
                end
            end
            
            assignedThreats[coalitionKey][threatName] = nil
        end
    end
    
    -- Count assigned threats
    local assignedCount = 0
    for _ in pairs(assignedThreats[coalitionKey]) do assignedCount = assignedCount + 1 end
    
    log(coalitionName .. " scan complete: " .. threatCount .. " threats, " .. countActiveFighters(coalitionSide) .. " active fighters, " .. 
        assignedCount .. " assigned")
    end
end

-- Main threat detection loop - calls both coalitions
local function detectThreats()
    if TADC_SETTINGS.enableRed then
        detectThreatsForCoalition(coalition.side.RED)
    end
    
    if TADC_SETTINGS.enableBlue then
        detectThreatsForCoalition(coalition.side.BLUE)
    end
end

-- Monitor interceptor groups for cleanup when destroyed
local function monitorInterceptors()
    -- Check RED interceptors
    if TADC_SETTINGS.enableRed then
        for interceptorName, interceptorData in pairs(activeInterceptors.red) do
            if interceptorData and interceptorData.group then
                if not interceptorData.group:IsAlive() then
                    -- Interceptor group is destroyed - just clean up tracking
                    local displayName = interceptorData.displayName
                    log("RED Interceptor from " .. displayName .. " destroyed: " .. interceptorName, true)
                    
                    -- Remove from active tracking
                    activeInterceptors.red[interceptorName] = nil
                end
            end
        end
    end
    
    -- Check BLUE interceptors
    if TADC_SETTINGS.enableBlue then
        for interceptorName, interceptorData in pairs(activeInterceptors.blue) do
            if interceptorData and interceptorData.group then
                if not interceptorData.group:IsAlive() then
                    -- Interceptor group is destroyed - just clean up tracking
                    local displayName = interceptorData.displayName
                    log("BLUE Interceptor from " .. displayName .. " destroyed: " .. interceptorName, true)
                    
                    -- Remove from active tracking
                    activeInterceptors.blue[interceptorName] = nil
                end
            end
        end
    end
end

-- Periodic airbase status check
local function checkAirbaseStatus()
    log("=== AIRBASE STATUS REPORT ===")
    
    local redUsableCount = 0
    local blueUsableCount = 0
    local currentTime = timer.getTime()
    
    -- Check RED airbases
    if TADC_SETTINGS.enableRed then
        log("=== RED COALITION STATUS ===")
        for _, squadron in pairs(RED_SQUADRON_CONFIG) do
            local airbase = AIRBASE:FindByName(squadron.airbaseName)
            local aircraftCount = squadronAircraftCounts.red[squadron.templateName] or 0
            local maxAircraft = squadron.aircraft
            
            -- Determine status based on squadron state
            local statusPrefix = "✗"
            local statusText = ""
            local usable = false
            
            if squadron.state == "operational" then
                statusPrefix = "✓"
                statusText = "Operational: " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
                usable = true
            elseif squadron.state == "captured" then
                -- Determine who captured it
                local capturedBy = "enemy"
                if airbase and airbase:IsAlive() then
                    local airbaseCoalition = airbase:GetCoalition()
                    if airbaseCoalition == coalition.side.BLUE then
                        capturedBy = "Blue"
                    elseif airbaseCoalition == coalition.side.NEUTRAL then
                        capturedBy = "neutral forces"
                    end
                end
                statusText = "Captured by " .. capturedBy .. ": " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
            elseif squadron.state == "destroyed" then
                statusText = "Destroyed: " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
            else
                statusText = "Unknown state: " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
            end
            
            -- Add zone information if configured
            local zoneStatus = ""
            if squadron.primaryZone or squadron.secondaryZone or squadron.tertiaryZone then
                local zones = {}
                if squadron.primaryZone then table.insert(zones, "P:" .. squadron.primaryZone) end
                if squadron.secondaryZone then table.insert(zones, "S:" .. squadron.secondaryZone) end
                if squadron.tertiaryZone then table.insert(zones, "T:" .. squadron.tertiaryZone) end
                zoneStatus = " Zones: " .. table.concat(zones, " ")
            end
            
            -- Check if squadron is on cooldown (only show for operational squadrons)
            local cooldownStatus = ""
            if squadron.state == "operational" and squadronCooldowns.red[squadron.templateName] then
                local cooldownEnd = squadronCooldowns.red[squadron.templateName]
                if currentTime < cooldownEnd then
                    local timeLeft = math.ceil((cooldownEnd - currentTime) / 60)
                    cooldownStatus = " (COOLDOWN: " .. timeLeft .. "m)"
                end
            end
            
            local fullStatus = statusText .. zoneStatus .. cooldownStatus
            
            if usable and cooldownStatus == "" and aircraftCount > 0 then
                redUsableCount = redUsableCount + 1
            end
            
            log(statusPrefix .. " " .. squadron.displayName .. " (" .. squadron.airbaseName .. ") - " .. fullStatus)
        end
        log("RED Status: " .. redUsableCount .. "/" .. #RED_SQUADRON_CONFIG .. " airbases operational")
    end
    
    -- Check BLUE airbases
    if TADC_SETTINGS.enableBlue then
        log("=== BLUE COALITION STATUS ===")
        for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
            local airbase = AIRBASE:FindByName(squadron.airbaseName)
            local aircraftCount = squadronAircraftCounts.blue[squadron.templateName] or 0
            local maxAircraft = squadron.aircraft
            
            -- Determine status based on squadron state
            local statusPrefix = "✗"
            local statusText = ""
            local usable = false
            
            if squadron.state == "operational" then
                statusPrefix = "✓"
                statusText = "Operational: " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
                usable = true
            elseif squadron.state == "captured" then
                -- Determine who captured it
                local capturedBy = "enemy"
                if airbase and airbase:IsAlive() then
                    local airbaseCoalition = airbase:GetCoalition()
                    if airbaseCoalition == coalition.side.RED then
                        capturedBy = "Red"
                    elseif airbaseCoalition == coalition.side.NEUTRAL then
                        capturedBy = "neutral forces"
                    end
                end
                statusText = "Captured by " .. capturedBy .. ": " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
            elseif squadron.state == "destroyed" then
                statusText = "Destroyed: " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
            else
                statusText = "Unknown state: " .. aircraftCount .. "/" .. maxAircraft .. " aircraft"
            end
            
            -- Add zone information if configured
            local zoneStatus = ""
            if squadron.primaryZone or squadron.secondaryZone or squadron.tertiaryZone then
                local zones = {}
                if squadron.primaryZone then table.insert(zones, "P:" .. squadron.primaryZone) end
                if squadron.secondaryZone then table.insert(zones, "S:" .. squadron.secondaryZone) end
                if squadron.tertiaryZone then table.insert(zones, "T:" .. squadron.tertiaryZone) end
                zoneStatus = " Zones: " .. table.concat(zones, " ")
            end
            
            -- Check if squadron is on cooldown (only show for operational squadrons)
            local cooldownStatus = ""
            if squadron.state == "operational" and squadronCooldowns.blue[squadron.templateName] then
                local cooldownEnd = squadronCooldowns.blue[squadron.templateName]
                if currentTime < cooldownEnd then
                    local timeLeft = math.ceil((cooldownEnd - currentTime) / 60)
                    cooldownStatus = " (COOLDOWN: " .. timeLeft .. "m)"
                end
            end
            
            local fullStatus = statusText .. zoneStatus .. cooldownStatus
            
            if usable and cooldownStatus == "" and aircraftCount > 0 then
                blueUsableCount = blueUsableCount + 1
            end
            
            log(statusPrefix .. " " .. squadron.displayName .. " (" .. squadron.airbaseName .. ") - " .. fullStatus)
        end
        log("BLUE Status: " .. blueUsableCount .. "/" .. #BLUE_SQUADRON_CONFIG .. " airbases operational")
    end
end

-- Cleanup old delivery records to prevent memory buildup
local function cleanupOldDeliveries()
    if _G.processedDeliveries then
        local currentTime = timer.getTime()
        local cleanupAge = 3600 -- Remove delivery records older than 1 hour
        local removedCount = 0
        
        for deliveryKey, timestamp in pairs(_G.processedDeliveries) do
            if currentTime - timestamp > cleanupAge then
                _G.processedDeliveries[deliveryKey] = nil
                removedCount = removedCount + 1
            end
        end
        
        if removedCount > 0 then
            log("Cleaned up " .. removedCount .. " old cargo delivery records", true)
        end
    end
end

-- Update squadron states based on airbase coalition control
local function updateSquadronStates()
    -- Update RED squadrons
    for _, squadron in pairs(RED_SQUADRON_CONFIG) do
        local airbase = AIRBASE:FindByName(squadron.airbaseName)
        if airbase and airbase:IsAlive() then
            local airbaseCoalition = airbase:GetCoalition()
            if airbaseCoalition == coalition.side.RED then
                -- Only update to operational if not already operational (avoid spam)
                if squadron.state ~= "operational" then
                    squadron.state = "operational"
                    log("RED Squadron " .. squadron.displayName .. " at " .. squadron.airbaseName .. " is now operational")
                end
            else
                -- Airbase captured
                if squadron.state ~= "captured" then
                    squadron.state = "captured"
                    log("RED Squadron " .. squadron.displayName .. " at " .. squadron.airbaseName .. " has been captured by enemy")
                end
            end
        else
            -- Airbase destroyed or not found
            if squadron.state ~= "destroyed" then
                squadron.state = "destroyed"
                log("RED Squadron " .. squadron.displayName .. " at " .. squadron.airbaseName .. " airbase destroyed or not found")
            end
        end
    end
    
    -- Update BLUE squadrons
    for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
        local airbase = AIRBASE:FindByName(squadron.airbaseName)
        if airbase and airbase:IsAlive() then
            local airbaseCoalition = airbase:GetCoalition()
            if airbaseCoalition == coalition.side.BLUE then
                -- Only update to operational if not already operational (avoid spam)
                if squadron.state ~= "operational" then
                    squadron.state = "operational"
                    log("BLUE Squadron " .. squadron.displayName .. " at " .. squadron.airbaseName .. " is now operational")
                end
            else
                -- Airbase captured
                if squadron.state ~= "captured" then
                    squadron.state = "captured"
                    log("BLUE Squadron " .. squadron.displayName .. " at " .. squadron.airbaseName .. " has been captured by enemy")
                end
            end
        else
            -- Airbase destroyed or not found
            if squadron.state ~= "destroyed" then
                squadron.state = "destroyed"
                log("BLUE Squadron " .. squadron.displayName .. " at " .. squadron.airbaseName .. " airbase destroyed or not found")
            end
        end
    end
end

-- System initialization
local function initializeSystem()
    log("Universal Dual-Coalition TADC starting...")
    
    -- Create zones from late-activated helicopter units (MOOSE method)
    -- This allows using helicopters named "RED_BORDER", "BLUE_BORDER" etc. as zone markers
    -- Uses the helicopter's waypoints as polygon vertices (standard MOOSE method)
    local function createZoneFromUnit(unitName)
        -- Try to find as a group first (this is the standard MOOSE way)
        local group = GROUP:FindByName(unitName)
        if group then
            -- Create polygon zone using the group's waypoints as vertices
            local zone = ZONE_POLYGON:NewFromGroupName(unitName, unitName)
            if zone then
                log("Created polygon zone '" .. unitName .. "' from helicopter waypoints")
                return zone
            else
                log("Warning: Could not create polygon zone from group '" .. unitName .. "' - check waypoints")
            end
        else
            log("Warning: No group named '" .. unitName .. "' found for zone creation")
        end
        return nil
    end
    
    -- Try to create zones for all configured zone names
    local zoneNames = {}
    for _, squadron in pairs(RED_SQUADRON_CONFIG) do
        if squadron.primaryZone then table.insert(zoneNames, squadron.primaryZone) end
        if squadron.secondaryZone then table.insert(zoneNames, squadron.secondaryZone) end
        if squadron.tertiaryZone then table.insert(zoneNames, squadron.tertiaryZone) end
    end
    for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
        if squadron.primaryZone then table.insert(zoneNames, squadron.primaryZone) end
        if squadron.secondaryZone then table.insert(zoneNames, squadron.secondaryZone) end
        if squadron.tertiaryZone then table.insert(zoneNames, squadron.tertiaryZone) end
    end
    
    -- Create zones from helicopters
    for _, zoneName in ipairs(zoneNames) do
        if not ZONE:FindByName(zoneName) then
            createZoneFromUnit(zoneName)
        end
    end
    
    -- Validate configuration
    if not validateConfiguration() then
        log("System startup aborted due to configuration errors!")
        return false
    end
    
    -- Initialize squadron states
    for _, squadron in pairs(RED_SQUADRON_CONFIG) do
        squadron.state = "operational"
    end
    for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
        squadron.state = "operational"
    end
    log("Squadron states initialized")
    
    -- Log enabled coalitions
    local enabledCoalitions = {}
    if TADC_SETTINGS.enableRed then
        table.insert(enabledCoalitions, "RED (" .. #RED_SQUADRON_CONFIG .. " squadrons)")
    end
    if TADC_SETTINGS.enableBlue then
        table.insert(enabledCoalitions, "BLUE (" .. #BLUE_SQUADRON_CONFIG .. " squadrons)")
    end
    log("Enabled coalitions: " .. table.concat(enabledCoalitions, ", "))
    
    -- Log initial squadron aircraft counts
    if TADC_SETTINGS.enableRed then
        for _, squadron in pairs(RED_SQUADRON_CONFIG) do
            local count = squadronAircraftCounts.red[squadron.templateName]
            log("Initial RED: " .. squadron.displayName .. " has " .. count .. "/" .. squadron.aircraft .. " aircraft")
        end
    end
    
    if TADC_SETTINGS.enableBlue then
        for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
            local count = squadronAircraftCounts.blue[squadron.templateName]
            log("Initial BLUE: " .. squadron.displayName .. " has " .. count .. "/" .. squadron.aircraft .. " aircraft")
        end
    end
    
    -- Start schedulers
    -- Set up event handler for cargo landing detection (handled via MOOSE EVENTHANDLER wrapper below)

    -- Re-register world event handler for robust detection (handles raw DCS initiators and race cases)
    world.addEventHandler(cargoEventHandler)

    -- MOOSE-style EVENTHANDLER wrapper for readability: logs EventData but does NOT delegate to avoid double-processing
    if EVENTHANDLER then
        local TADC_CARGO_LANDING_HANDLER = EVENTHANDLER:New()
        function TADC_CARGO_LANDING_HANDLER:OnEventLand(EventData)
            -- Convert MOOSE EventData to raw world.event format and reuse existing handler logic
            if ADVANCED_SETTINGS.enableDetailedLogging then
                -- Log presence and types of key fields
                local function safeName(obj)
                    if not obj then return "<nil>" end
                    local ok, n = pcall(function()
                        if obj.GetName then return obj:GetName() end
                        if obj.getName then return obj:getName() end
                        return nil
                    end)
                    return (ok and n) and tostring(n) or "<unavailable>"
                end

                local iniUnitPresent = EventData.IniUnit ~= nil
                local iniGroupPresent = EventData.IniGroup ~= nil
                local placePresent = EventData.Place ~= nil
                local iniUnitName = safeName(EventData.IniUnit)
                local iniGroupName = safeName(EventData.IniGroup)
                local placeName = safeName(EventData.Place)

                log("MOOSE LAND EVENT: IniUnitPresent=" .. tostring(iniUnitPresent) .. ", IniUnitName=" .. tostring(iniUnitName) .. ", IniGroupPresent=" .. tostring(iniGroupPresent) .. ", IniGroupName=" .. tostring(iniGroupName) .. ", PlacePresent=" .. tostring(placePresent) .. ", PlaceName=" .. tostring(placeName), true)
            end

            local rawEvent = {
                id = world.event.S_EVENT_LAND,
                initiator = EventData.IniUnit or EventData.IniGroup or nil,
                place = EventData.Place or nil,
                -- Provide the original EventData for potential fallback use
                _moose_original = EventData
            }
            -- Log and return; the world event handler `cargoEventHandler` will handle the actual processing.
            return
        end
        -- Register the MOOSE handler
        TADC_CARGO_LANDING_HANDLER:HandleEvent(EVENTS.Land)
    end
    
    SCHEDULER:New(nil, detectThreats, {}, 5, TADC_SETTINGS.checkInterval)
    SCHEDULER:New(nil, monitorInterceptors, {}, 10, TADC_SETTINGS.monitorInterval)
    SCHEDULER:New(nil, checkAirbaseStatus, {}, 30, TADC_SETTINGS.statusReportInterval)
    SCHEDULER:New(nil, updateSquadronStates, {}, 60, 30) -- Update squadron states every 30 seconds (60 sec initial delay to allow DCS airbase coalition to stabilize)
    SCHEDULER:New(nil, cleanupOldDeliveries, {}, 60, 3600) -- Cleanup old delivery records every hour

    -- Start periodic squadron summary broadcast
    SCHEDULER:New(nil, broadcastSquadronSummary, {}, 10, TADC_SETTINGS.squadronSummaryInterval)
    
    log("Universal Dual-Coalition TADC operational!")
    log("RED Replenishment: " .. TADC_SETTINGS.red.cargoReplenishmentAmount .. " aircraft per cargo delivery")
    log("BLUE Replenishment: " .. TADC_SETTINGS.blue.cargoReplenishmentAmount .. " aircraft per cargo delivery")
    
    return true
end


initializeSystem()

-- Add F10 menu command for squadron summary
-- Use MenuManager to create coalition-specific menus (not mission-wide)
local menuRootBlue, menuRootRed

if MenuManager then
  menuRootBlue = MenuManager.CreateCoalitionMenu(coalition.side.BLUE, "TADC Utilities")
  menuRootRed = MenuManager.CreateCoalitionMenu(coalition.side.RED, "TADC Utilities")
else
  menuRootBlue = MENU_COALITION:New(coalition.side.BLUE, "TADC Utilities")
  menuRootRed = MENU_COALITION:New(coalition.side.RED, "TADC Utilities")
end

MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Squadron Resource Summary", menuRootRed, function()
    local summary = getSquadronResourceSummary(coalition.side.RED)
    MESSAGE:New(summary, 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Squadron Resource Summary", menuRootBlue, function()
    local summary = getSquadronResourceSummary(coalition.side.BLUE)
    MESSAGE:New(summary, 20):ToCoalition(coalition.side.BLUE)
end)

-- 1. Show Airbase Status Report
MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Airbase Status Report", menuRootRed, function()
    local report = "=== RED Airbase Status ===\n"
    for _, squadron in pairs(RED_SQUADRON_CONFIG) do
        local usable, status = isAirbaseUsable(squadron.airbaseName, coalition.side.RED)
        local aircraftCount = squadronAircraftCounts.red[squadron.templateName] or 0
        local maxAircraft = squadron.aircraft
        local cooldown = squadronCooldowns.red[squadron.templateName]
        local cooldownStatus = ""
        if cooldown then
            local timeLeft = math.ceil((cooldown - timer.getTime()) / 60)
            if timeLeft > 0 then cooldownStatus = " (COOLDOWN: " .. timeLeft .. "m)" end
        end
        report = report .. string.format("%s: %s | Aircraft: %d/%d%s\n", squadron.displayName, status, aircraftCount, maxAircraft, cooldownStatus)
    end
    MESSAGE:New(report, 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Airbase Status Report", menuRootBlue, function()
    local report = "=== BLUE Airbase Status ===\n"
    for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
        local usable, status = isAirbaseUsable(squadron.airbaseName, coalition.side.BLUE)
        local aircraftCount = squadronAircraftCounts.blue[squadron.templateName] or 0
        local maxAircraft = squadron.aircraft
        local cooldown = squadronCooldowns.blue[squadron.templateName]
        local cooldownStatus = ""
        if cooldown then
            local timeLeft = math.ceil((cooldown - timer.getTime()) / 60)
            if timeLeft > 0 then cooldownStatus = " (COOLDOWN: " .. timeLeft .. "m)" end
        end
        report = report .. string.format("%s: %s | Aircraft: %d/%d%s\n", squadron.displayName, status, aircraftCount, maxAircraft, cooldownStatus)
    end
    MESSAGE:New(report, 20):ToCoalition(coalition.side.BLUE)
end)

-- 2. Show Active Interceptors
MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Active Interceptors", menuRootRed, function()
    local lines = {"Active RED Interceptors:"}
    for name, data in pairs(activeInterceptors.red) do
        if data and data.group and data.group:IsAlive() then
            table.insert(lines, string.format("%s (Squadron: %s, Threat: %s)", name, data.displayName or data.squadron, assignedThreats.red[name] or "N/A"))
        end
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Active Interceptors", menuRootBlue, function()
    local lines = {"Active BLUE Interceptors:"}
    for name, data in pairs(activeInterceptors.blue) do
        if data and data.group and data.group:IsAlive() then
            table.insert(lines, string.format("%s (Squadron: %s, Threat: %s)", name, data.displayName or data.squadron, assignedThreats.blue[name] or "N/A"))
        end
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.BLUE)
end)

-- 3. Show Threat Summary
MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Threat Summary", menuRootRed, function()
    local lines = {"Detected BLUE Threats:"}
    if cachedSets.blueAircraft then
        cachedSets.blueAircraft:ForEach(function(group)
            if group and group:IsAlive() then
                table.insert(lines, string.format("%s (Size: %d)", group:GetName(), group:GetSize()))
            end
        end)
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Threat Summary", menuRootBlue, function()
    local lines = {"Detected RED Threats:"}
    if cachedSets.redAircraft then
        cachedSets.redAircraft:ForEach(function(group)
            if group and group:IsAlive() then
                table.insert(lines, string.format("%s (Size: %d)", group:GetName(), group:GetSize()))
            end
        end)
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.BLUE)
end)

-- 4. Request Immediate Squadron Summary Broadcast
MENU_COALITION_COMMAND:New(coalition.side.RED, "Broadcast Squadron Summary Now", menuRootRed, function()
    local summary = getSquadronResourceSummary(coalition.side.RED)
    MESSAGE:New(summary, 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Broadcast Squadron Summary Now", menuRootBlue, function()
    local summary = getSquadronResourceSummary(coalition.side.BLUE)
    MESSAGE:New(summary, 20):ToCoalition(coalition.side.BLUE)
end)

-- 5. Show Cargo Delivery Log
MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Cargo Delivery Log", menuRootRed, function()
    local lines = {"Recent RED Cargo Deliveries:"}
    if _G.processedDeliveries then
        for key, timestamp in pairs(_G.processedDeliveries) do
            if string.find(key, "RED") then
                table.insert(lines, string.format("%s at %d", key, timestamp))
            end
        end
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Cargo Delivery Log", menuRootBlue, function()
    local lines = {"Recent BLUE Cargo Deliveries:"}
    if _G.processedDeliveries then
        for key, timestamp in pairs(_G.processedDeliveries) do
            if string.find(key, "BLUE") then
                table.insert(lines, string.format("%s at %d", key, timestamp))
            end
        end
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.BLUE)
end)

-- 6. Show Zone Coverage Map
MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Zone Coverage Map", menuRootRed, function()
    local lines = {"RED Zone Coverage:"}
    for _, squadron in pairs(RED_SQUADRON_CONFIG) do
        local zones = {}
        if squadron.primaryZone then table.insert(zones, "Primary: " .. squadron.primaryZone) end
        if squadron.secondaryZone then table.insert(zones, "Secondary: " .. squadron.secondaryZone) end
        if squadron.tertiaryZone then table.insert(zones, "Tertiary: " .. squadron.tertiaryZone) end
        table.insert(lines, string.format("%s: %s", squadron.displayName, table.concat(zones, ", ")))
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.RED)
end)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Zone Coverage Map", menuRootBlue, function()
    local lines = {"BLUE Zone Coverage:"}
    for _, squadron in pairs(BLUE_SQUADRON_CONFIG) do
        local zones = {}
        if squadron.primaryZone then table.insert(zones, "Primary: " .. squadron.primaryZone) end
        if squadron.secondaryZone then table.insert(zones, "Secondary: " .. squadron.secondaryZone) end
        if squadron.tertiaryZone then table.insert(zones, "Tertiary: " .. squadron.tertiaryZone) end
        table.insert(lines, string.format("%s: %s", squadron.displayName, table.concat(zones, ", ")))
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToCoalition(coalition.side.BLUE)
end)

-- 7. Admin/Debug Commands - Create submenus under each coalition's TADC Utilities
local menuAdminBlue = MENU_COALITION:New(coalition.side.BLUE, "Admin / Debug", menuRootBlue)
local menuAdminRed = MENU_COALITION:New(coalition.side.RED, "Admin / Debug", menuRootRed)

MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Emergency Cleanup Interceptors", menuAdminBlue, function()
    local cleaned = 0
    for name, interceptors in pairs(activeInterceptors.red) do
        if interceptors and interceptors.group and not interceptors.group:IsAlive() then
            cleanupInterceptorEntry(name, "red")
            cleaned = cleaned + 1
        end
    end
    for name, interceptors in pairs(activeInterceptors.blue) do
        if interceptors and interceptors.group and not interceptors.group:IsAlive() then
            cleanupInterceptorEntry(name, "blue")
            cleaned = cleaned + 1
        end
    end
    MESSAGE:New("Cleaned up " .. cleaned .. " dead interceptor groups.", 20):ToBlue()
end)

MENU_COALITION_COMMAND:New(coalition.side.RED, "Emergency Cleanup Interceptors", menuAdminRed, function()
    local cleaned = 0
    for name, interceptors in pairs(activeInterceptors.red) do
        if interceptors and interceptors.group and not interceptors.group:IsAlive() then
            cleanupInterceptorEntry(name, "red")
            cleaned = cleaned + 1
        end
    end
    for name, interceptors in pairs(activeInterceptors.blue) do
        if interceptors and interceptors.group and not interceptors.group:IsAlive() then
            cleanupInterceptorEntry(name, "blue")
            cleaned = cleaned + 1
        end
    end
    MESSAGE:New("Cleaned up " .. cleaned .. " dead interceptor groups.", 20):ToRed()
end)

-- 9. Show System Uptime/Status
local systemStartTime = timer.getTime()
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show TADC System Status", menuAdminBlue, function()
    local uptime = math.floor((timer.getTime() - systemStartTime) / 60)
    local status = string.format("TADC System Uptime: %d minutes\nCheck Interval: %ds\nMonitor Interval: %ds\nStatus Report Interval: %ds\nSquadron Summary Interval: %ds\nCargo Check Interval: %ds", uptime, TADC_SETTINGS.checkInterval, TADC_SETTINGS.monitorInterval, TADC_SETTINGS.statusReportInterval, TADC_SETTINGS.squadronSummaryInterval, TADC_SETTINGS.cargoCheckInterval)
    MESSAGE:New(status, 20):ToBlue()
end)

MENU_COALITION_COMMAND:New(coalition.side.RED, "Show TADC System Status", menuAdminRed, function()
    local uptime = math.floor((timer.getTime() - systemStartTime) / 60)
    local status = string.format("TADC System Uptime: %d minutes\nCheck Interval: %ds\nMonitor Interval: %ds\nStatus Report Interval: %ds\nSquadron Summary Interval: %ds\nCargo Check Interval: %ds", uptime, TADC_SETTINGS.checkInterval, TADC_SETTINGS.monitorInterval, TADC_SETTINGS.statusReportInterval, TADC_SETTINGS.squadronSummaryInterval, TADC_SETTINGS.cargoCheckInterval)
    MESSAGE:New(status, 20):ToRed()
end)

-- 10. Check for Stuck Aircraft (manual trigger)
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Check for Stuck Aircraft", menuAdminBlue, function()
    monitorStuckAircraft()
    MESSAGE:New("Stuck aircraft check completed", 10):ToBlue()
end)

MENU_COALITION_COMMAND:New(coalition.side.RED, "Check for Stuck Aircraft", menuAdminRed, function()
    monitorStuckAircraft()
    MESSAGE:New("Stuck aircraft check completed", 10):ToRed()
end)

-- 11. Show Airbase Health Status
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Show Airbase Health Status", menuAdminBlue, function()
    local lines = {"Airbase Health Status:"}
    for _, coalitionKey in ipairs({"red", "blue"}) do
        local coalitionName = (coalitionKey == "red") and "RED" or "BLUE"
        table.insert(lines, coalitionName .. " Coalition:")
        for airbaseName, status in pairs(airbaseHealthStatus[coalitionKey]) do
            table.insert(lines, "  " .. airbaseName .. ": " .. status)
        end
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToBlue()
end)

MENU_COALITION_COMMAND:New(coalition.side.RED, "Show Airbase Health Status", menuAdminRed, function()
    local lines = {"Airbase Health Status:"}
    for _, coalitionKey in ipairs({"red", "blue"}) do
        local coalitionName = (coalitionKey == "red") and "RED" or "BLUE"
        table.insert(lines, coalitionName .. " Coalition:")
        for airbaseName, status in pairs(airbaseHealthStatus[coalitionKey]) do
            table.insert(lines, "  " .. airbaseName .. ": " .. status)
        end
    end
    MESSAGE:New(table.concat(lines, "\n"), 20):ToRed()
end)

-- Initialize airbase health status for all configured airbases
for _, coalitionKey in ipairs({"red", "blue"}) do
    local squadronConfig = getSquadronConfig(coalitionKey == "red" and coalition.side.RED or coalition.side.BLUE)
    for _, squadron in pairs(squadronConfig) do
        if not airbaseHealthStatus[coalitionKey][squadron.airbaseName] then
            airbaseHealthStatus[coalitionKey][squadron.airbaseName] = "operational"
        end
    end
end

-- Set up periodic stuck aircraft monitoring (every 2 minutes)
SCHEDULER:New(nil, monitorStuckAircraft, {}, 120, 120)



