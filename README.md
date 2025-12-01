# Universal TADC System

**Tactical Air Defense Controller with Automated Logistics for DCS World**

[![MOOSE Compatible](https://img.shields.io/badge/MOOSE-Compatible-green)](https://github.com/FlightControl-Master/MOOSE)
[![DCS World](https://img.shields.io/badge/DCS-World-blue)](https://www.digitalcombatsimulator.com/)

An automated air defense system for DCS World missions that creates realistic, dynamic fighter aircraft responses to airborne threats. Features dual-coalition support, zone-based defense, squadron resource management, and automated cargo replenishment for sustained operations (optional system). Player C130 landings at an airbase will replenish AI squadron resources.

This system is broken up in to several lua files to make future upgrades easier on the mission maker. Keeping the squadron configs in a seperate file allows you to simply drop the  main updated logic script into your mission as I apply updates in the future. Making upgrades super easy. The Cargo Dispatch system is optional if you do not want automated cargo flights to resupply the squadrons. The TADC looks for cargo landings. You can have player provide these, or use the Cargo Dispatch system to supply the airbaes. OR - no resupply for limited resource configurations.

## 🎯 Key Features

### Core Air Defense
- **Automatic Threat Detection**: Continuously scans for enemy aircraft and launches appropriate responses
- **Intelligent Squadron Selection**: Chooses the best squadron based on zone priorities, distance, and availability
- **Dynamic Interception**: Launches multiple fighters based on threat size and configurable ratios
- **Realistic AI Behavior**: Fighters engage threats aggressively and return to base when threats are eliminated

### Zone-Based Defense System
- **Primary Zones**: Main areas of responsibility with full response capability
- **Secondary Zones**: Support areas with reduced response ratios
- **Tertiary Zones**: Emergency fallback zones for weakened squadrons
- **Flexible Configuration**: Create layered defense networks or simple border patrols

### Squadron Management
- **Resource Tracking**: Monitors aircraft counts and squadron availability
- **Cooldown System**: Prevents spam launches with configurable cooldown periods
- **Airbase Health Monitoring**: Tracks airbase status and handles captures/destruction
- **Stuck Aircraft Detection**: Automatically cleans up aircraft that fail to spawn properly

### Automated Logistics
- **Cargo Replenishment**: Automatically dispatches transport aircraft when squadrons run low
- **Supply Chain Management**: Routes cargo from rear supply bases to frontline airbases
- **Delivery Detection**: Credits squadrons upon successful cargo delivery
- **Configurable Thresholds**: Set when resupply triggers and how many aircraft are added

### Dual-Coalition Support
- **Independent Operation**: RED and BLUE coalitions operate simultaneously and independently
- **Balanced or Asymmetric**: Configure different capabilities for each side
- **Coalition-Specific Settings**: Separate intercept ratios, cooldowns, and limits per coalition

### Mission Integration
- **F10 Menu Interface**: Real-time status reports and diagnostics for pilots
- **Comprehensive Logging**: Detailed system status and event logging
- **Validation System**: Automatic configuration checking at mission start
- **Performance Optimized**: Efficient scanning and caching for minimal impact

## 🚀 Quick Start

### Prerequisites
- DCS World with MOOSE Framework installed
- Mission editor access
- Basic understanding of DCS mission creation

### 5-Minute Setup

1. **Download the Scripts**
   - Copy `Moose_TADC_SquadronConfigs_Load1st.lua`, `Moose_TADC_Load2nd.lua`, and optionally `Moose_TADC_CargoDispatcher.lua`

2. **Load MOOSE Framework**
   - In mission editor → Triggers → New trigger (MISSION START)
   - Add action: DO SCRIPT FILE → Select your MOOSE.lua file

3. **Configure Squadrons**
   - Edit `Moose_TADC_SquadronConfigs_Load1st.lua`
   - Add your fighter squadron templates and airbase assignments

4. **Load Main System**
   - Add DO SCRIPT FILE action for `Moose_TADC_Load2nd.lua`

5. **Optional: Enable Cargo**
   - Add DO SCRIPT FILE action for `Moose_TADC_CargoDispatcher.lua`

**Load Order**: MOOSE → Squadron Configs → Main TADC → Cargo Dispatcher

## 📋 Configuration

### Squadron Configuration

Edit `Moose_TADC_SquadronConfigs_Load1st.lua` to define your squadrons:

```lua
RED_SQUADRON_CONFIG = {
    {
        templateName = "RED_CAP_Kilpyavr_MiG29",     -- Must match mission editor group name
        displayName = "Kilpyavr CAP MiG-29A",        -- Human-readable name
        airbaseName = "Kilpyavr",                    -- Exact DCS airbase name
        aircraft = 12,                               -- Maximum squadron size
        skill = AI.Skill.EXCELLENT,                  -- AI pilot skill level
        altitude = 20000,                            -- Patrol altitude (feet)
        speed = 350,                                 -- Patrol speed (knots)
        patrolTime = 30,                             -- Minutes on station
        type = "FIGHTER",                            -- Aircraft role
        
        -- Optional zone configuration
        primaryZone = "RED BORDER",                  -- Main defense zone
        secondaryZone = "CONTESTED ZONE",            -- Support zone
        tertiaryZone = nil,                          -- Emergency fallback
        
        -- Zone behavior customization
        zoneConfig = {
            primaryResponse = 1.0,                   -- Full response in primary zone
            secondaryResponse = 0.6,                 -- 60% response in secondary
            tertiaryResponse = 1.4,                  -- 140% in tertiary
            enableFallback = false,                  -- Auto-switch to tertiary
            fallbackThreshold = 0.3,                 -- Switch at 30% strength
            ignoreLowPriority = true,                -- Skip small threats in secondary
            priorityThreshold = 2                    -- "Small" = 2 or fewer aircraft
        }
    }
}
```

### Main System Settings

Edit `Moose_TADC_Load2nd.lua` for global settings:

```lua
local TADC_SETTINGS = {
    enableRed = true,                    -- Enable RED coalition
    enableBlue = true,                   -- Enable BLUE coalition
    
    red = {
        interceptRatio = 0.8,            -- Fighters per enemy aircraft
        maxActiveCAP = 8,                -- Max simultaneous groups
        squadronCooldown = 300,          -- Seconds between launches
        cargoReplenishmentAmount = 4,     -- Aircraft per cargo delivery
        rtbFlightBuffer = 300,           -- Extra time for RTB
        emergencyCleanupTime = 7200      -- Cleanup stuck interceptors
    },
    
    blue = {
        interceptRatio = 1.2,            -- BLUE gets advantage
        maxActiveCAP = 10,
        squadronCooldown = 300,
        cargoReplenishmentAmount = 4,
        rtbFlightBuffer = 300,
        emergencyCleanupTime = 7200
    },
    
    -- Global timing
    checkInterval = 5,                  -- Threat scan frequency (seconds)
    monitorInterval = 10,               -- Interceptor monitoring (seconds)
    statusReportInterval = 30,          -- Status broadcasts (seconds)
    squadronSummaryInterval = 60        -- Summary broadcasts (seconds)
}
```

### Cargo System Configuration

Edit `Moose_TADC_CargoDispatcher.lua` for logistics:

```lua
local CARGO_SUPPLY_CONFIG = {
    red = {
        cargoTemplate = "CARGO_RED_AN26",           -- Transport template name
        supplyAirfields = {                          -- Rear supply bases
            "Sochi-Adler",
            "Nalchik",
            "Beslan"
        },
        replenishAmount = 4,                        -- Aircraft per delivery
        threshold = 0.90                            -- Trigger at 90% capacity
    },
    
    blue = {
        cargoTemplate = "CARGO_BLUE_C130",
        supplyAirfields = {
            "Batumi",
            "Kobuleti",
            "Senaki-Kolkhi"
        },
        replenishAmount = 4,
        threshold = 0.90
    }
}
```

## 🎮 Usage

### Creating Zones

1. **Place Helicopter Groups**: Create late-activation helicopter groups in the mission editor
2. **Name the Zones**: Name groups like "RED BORDER", "BLUE FRONTLINE", etc.
3. **Add Waypoints**: Place waypoints to outline the zone boundary
4. **Assign to Squadrons**: Reference zone names in squadron configuration

### Fighter Templates

1. **Create Groups**: Place fighter aircraft as LATE ACTIVATION GROUPS (not units)
2. **Position Strategically**: Place near intended airbases
3. **Name Consistently**: Use clear naming like "RED_CAP_BaseName_AircraftType"
4. **Set Coalition**: Ensure correct RED/BLUE coalition assignment

### Cargo Templates

1. **Create Transport Groups**: Place C-130, An-26, etc. as late activation
2. **Name with Keywords**: Include "CARGO", "TRANSPORT", or aircraft type in name
3. **Position Anywhere**: Starting position doesn't matter (script repositions)

### In-Game Monitoring

Access F10 menu during mission:
- **Squadron Resource Summary**: Current aircraft counts and status
- **Airbase Status Report**: Operational status of all bases
- **Active Interceptors**: Currently airborne fighters
- **Threat Summary**: Detected enemy aircraft
- **Cargo Delivery Log**: Recent supply missions

## 📖 Examples

### Simple Border Defense

```lua
-- RED defends northern border
RED_SQUADRON_CONFIG = {
    {
        templateName = "RED_CAP_North_MiG29",
        displayName = "Northern Border CAP",
        airbaseName = "Kilpyavr",
        aircraft = 12,
        skill = AI.Skill.EXCELLENT,
        primaryZone = "RED BORDER"
    }
}

-- BLUE defends southern border  
BLUE_SQUADRON_CONFIG = {
    {
        templateName = "BLUE_CAP_South_F16",
        displayName = "Southern Border CAP", 
        airbaseName = "Batumi",
        aircraft = 12,
        skill = AI.Skill.EXCELLENT,
        primaryZone = "BLUE BORDER"
    }
}
```

### Layered Defense Network

```lua
RED_SQUADRON_CONFIG = {
    -- Outer layer: Long-range interceptors
    {
        templateName = "RED_LongRange_MiG31",
        displayName = "Long Range Interceptors",
        airbaseName = "Forward_Base",
        aircraft = 8,
        altitude = 35000,
        primaryZone = "OUTER PERIMETER"
    },
    
    -- Middle layer: General defense
    {
        templateName = "RED_CAP_MiG29", 
        displayName = "Middle Defense CAP",
        airbaseName = "Central_Base",
        aircraft = 12,
        primaryZone = "MIDDLE PERIMETER",
        secondaryZone = "OUTER PERIMETER"
    },
    
    -- Inner layer: Base defense with fallback
    {
        templateName = "RED_BaseDefense_SU27",
        displayName = "Base Defense",
        airbaseName = "Main_Base", 
        aircraft = 16,
        primaryZone = "BASE PERIMETER",
        tertiaryZone = "BASE PERIMETER",
        zoneConfig = {
            enableFallback = true,
            fallbackThreshold = 0.3
        }
    }
}
```

### Sustained Operations with Resupply

```lua
-- Squadron configuration
RED_SQUADRON_CONFIG = {
    {
        templateName = "RED_CAP_Frontline_MiG29",
        displayName = "Frontline CAP",
        airbaseName = "Frontline_Base",
        aircraft = 12,
        primaryZone = "COMBAT ZONE"
    }
}

-- Cargo configuration
local CARGO_SUPPLY_CONFIG = {
    red = {
        cargoTemplate = "CARGO_RED_AN26",
        supplyAirfields = {"Rear_Base_1", "Rear_Base_2"},
        replenishAmount = 4,
        threshold = 0.75  -- Trigger at 9/12 aircraft
    }
}
```

## 🔧 Troubleshooting

### Common Issues

**"Template not found"**
- Verify exact template name matches mission editor
- Ensure template is a GROUP, not a single UNIT
- Check spelling and case sensitivity

**"Airbase not found"**
- Copy airbase name exactly from mission editor
- Verify airbase exists and is under correct coalition control
- Check for typos in airbase names

**No interceptors launching**
- Check F10 → Threat Summary for detected enemies
- Verify squadrons have available aircraft
- Check airbase status and cooldown timers
- Review intercept ratio settings

**Cargo not delivering**
- Verify cargo template name and supply airfields
- Check destination airbase is operational
- Look for parking space availability
- Check DCS log for "Cargo delivery detected" messages

### Diagnostic Tools

**F10 Menu Commands**:
- Show Squadron Resource Summary
- Show Airbase Status Report  
- Show Active Interceptors
- Show Threat Summary
- Show Cargo Delivery Log

**Console Commands** (F12 console):
```lua
_G.TDAC_CheckAirbase("AirbaseName")           -- Check specific airbase
_G.TDAC_RunConfigCheck()                      -- Validate configuration
_G.TDAC_LogAirbaseParking("AirbaseName")      -- Check parking spots
```

### Performance Tips

- Limit `maxActiveCAP` to prevent FPS drops
- Use smaller zones to reduce scanning overhead
- Set reasonable cargo cooldowns
- Start with 3-5 squadrons per coalition

## 📄 License

This project is released under the MIT License. See LICENSE file for details.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly in DCS
4. Submit a pull request

## 🙏 Acknowledgments

- Built on the MOOSE Framework by FlightControl
- Inspired by dynamic air combat in DCS World
- Thanks to the DCS community for feedback and testing

## 📞 Support

- Check the troubleshooting section above
- Review DCS.log for detailed error messages
- Use F10 menus for real-time diagnostics
- Start with simple configurations and expand gradually

---

**Author**: F99th-TracerFacer  
**Version**: 1.0  
**Compatible with**: DCS World + MOOSE Framework</content>
<parameter name="filePath">README.md