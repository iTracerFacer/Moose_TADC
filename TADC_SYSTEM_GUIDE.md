# Universal TADC System - Mission Maker's Guide
## Tactical Air Defense Controller with Automated Logistics

---

## 📋 Table of Contents

1. [What is TADC?](#what-is-tadc)
2. [System Overview](#system-overview)
3. [Quick Start Guide](#quick-start-guide)
4. [Detailed Configuration](#detailed-configuration)
5. [Zone-Based Defense Setup](#zone-based-defense-setup)
6. [Cargo Replenishment System](#cargo-replenishment-system)
7. [Testing & Troubleshooting](#testing--troubleshooting)
8. [Advanced Features](#advanced-features)
9. [Common Scenarios](#common-scenarios)

---

## What is TADC?

**TADC (Tactical Air Defense Controller)** is an automated air defense system for DCS missions that creates realistic, dynamic fighter aircraft responses to airborne threats. Think of it as an AI commander that:

- **Detects enemy aircraft** automatically
- **Launches fighters** to intercept threats
- **Manages squadron resources** (aircraft availability, cooldowns)
- **Replenishes squadrons** through cargo aircraft deliveries
- **Operates independently** for both RED and BLUE coalitions

### Why Use TADC?

✅ **Realistic Air Defense** - Squadrons respond intelligently to threats  
✅ **Dynamic Gameplay** - Air battles happen organically without manual triggers  
✅ **Balanced Competition** - Both sides operate with equal capabilities  
✅ **Sustainable Operations** - Cargo system allows long missions with resupply  
✅ **Easy Configuration** - Simple tables instead of complex scripting  

---

## System Overview

The TADC system consists of **three main scripts** that work together:

### 1. Squadron Configuration (`Moose_TADC_SquadronConfigs_Load1st.lua`)
**Purpose:** Define all fighter squadrons for RED and BLUE coalitions  
**Contains:** Aircraft templates, airbases, patrol parameters, zone assignments  
**Load Order:** **FIRST** (must load before main TADC script)

### 2. Main TADC System (`Moose_TADC_Load2nd.lua`)
**Purpose:** Core threat detection and interceptor management  
**Contains:** Threat scanning, squadron selection, intercept logic, F10 menus  
**Load Order:** **SECOND** (after squadron config)

### 3. Cargo Dispatcher (`Moose_TADC_CargoDispatcher.lua`)
**Purpose:** Automated squadron resupply through cargo aircraft  
**Contains:** Squadron monitoring, cargo spawning, delivery tracking  
**Load Order:** **THIRD** (optional, only if using resupply system)

---

## Quick Start Guide

### Prerequisites

Before setting up TADC, you need:

- ✅ **MOOSE Framework** loaded in your mission (download from [MOOSE GitHub](https://github.com/FlightControl-Master/MOOSE))
- ✅ **Fighter aircraft templates** created in DCS mission editor (as GROUPS, not units)
- ✅ **Airbases** under correct coalition control
- ✅ (Optional) **Cargo aircraft templates** for resupply missions

### 5-Minute Setup

#### Step 1: Create Fighter Templates

1. Open your mission in DCS Mission Editor
2. Place fighter aircraft as **LATE ACTIVATION GROUPS** (not individual units)
3. Name them clearly (example: `RED_CAP_Kilpyavr_MiG29`)
4. Position them at or near the airbases they'll operate from
5. Set them to the correct coalition (RED or BLUE)

**Important:** Use GROUP templates, not UNIT templates!

#### Step 2: Load MOOSE Framework

1. In mission editor, go to **Triggers**
2. Create a new trigger: **MISSION START**
3. Add action: **DO SCRIPT FILE**
4. Select your MOOSE.lua file
5. This must be the FIRST script loaded

#### Step 3: Load Squadron Configuration

1. Create another **DO SCRIPT FILE** action (after MOOSE)
2. Select `Moose_TADC_SquadronConfigs_Load1st.lua`
3. Edit the file to configure your squadrons (see below)

#### Step 4: Load Main TADC System

1. Create another **DO SCRIPT FILE** action
2. Select `Moose_TADC_Load2nd.lua`
3. (Optional) Adjust settings in the file if needed

#### Step 5: (Optional) Load Cargo Dispatcher

1. If using resupply system, create another **DO SCRIPT FILE** action
2. Select `Moose_TADC_CargoDispatcher.lua`

**Load Order in Mission Editor:**
```
1. MOOSE.lua
2. Moose_TADC_SquadronConfigs_Load1st.lua
3. Moose_TADC_Load2nd.lua
4. Moose_TADC_CargoDispatcher.lua (optional)
```

---

## Detailed Configuration

### Squadron Configuration Explained

Open `Moose_TADC_SquadronConfigs_Load1st.lua` and find the squadron configuration sections.

#### Basic Squadron Example

```lua
{
    templateName = "RED_CAP_Kilpyavr_MiG29",     -- Must match mission editor template name
    displayName = "Kilpyavr CAP MiG-29A",        -- Human-readable name for logs/messages
    airbaseName = "Kilpyavr",                    -- Exact airbase name from DCS
    aircraft = 12,                                -- Maximum aircraft in squadron
    skill = AI.Skill.EXCELLENT,                   -- AI pilot skill level
    altitude = 20000,                             -- Patrol altitude (feet)
    speed = 350,                                  -- Patrol speed (knots)
    patrolTime = 30,                              -- Time on station (minutes)
    type = "FIGHTER"                              -- Aircraft role
}
```

#### Parameter Guide

| Parameter | Description | Example Values |
|-----------|-------------|----------------|
| **templateName** | Group name from mission editor (EXACT match) | `"RED_CAP_Base_F15"` |
| **displayName** | Friendly name shown in messages | `"Kilpyavr CAP Squadron"` |
| **airbaseName** | DCS airbase name (case sensitive) | `"Kilpyavr"`, `"Nellis AFB"` |
| **aircraft** | Max squadron size | `8`, `12`, `16` |
| **skill** | AI difficulty | `AI.Skill.AVERAGE`, `GOOD`, `HIGH`, `EXCELLENT`, `ACE` |
| **altitude** | CAP patrol altitude | `15000` (feet) |
| **speed** | CAP patrol speed | `300` (knots) |
| **patrolTime** | Minutes on station before RTB | `20`, `30`, `40` |
| **type** | Aircraft role | `"FIGHTER"` |

### Finding Airbase Names

**Method 1: Mission Editor**
1. Open mission editor
2. Click on any airbase
3. The exact name appears in the properties panel
4. Copy this name EXACTLY (case sensitive!)

**Method 2: Common Airbases**

**Kola Peninsula (Example Map):**
- RED: `"Kilpyavr"`, `"Severomorsk-1"`, `"Severomorsk-3"`, `"Murmansk International"`
- BLUE: `"Luostari Pechenga"`, `"Ivalo"`, `"Alakurtti"`

**Nevada:**
- `"Nellis AFB"`, `"McCarran International"`, `"Creech AFB"`, `"Tonopah Test Range"`

**Caucasus:**
- `"Batumi"`, `"Gudauta"`, `"Senaki-Kolkhi"`, `"Kobuleti"`, `"Kutaisi"`

### Adding Multiple Squadrons

You can add as many squadrons as you want. Just copy the squadron block and modify the values:

```lua
RED_SQUADRON_CONFIG = {
    -- First Squadron
    {
        templateName = "RED_CAP_Base1_MiG29",
        displayName = "Base 1 CAP",
        airbaseName = "Kilpyavr",
        aircraft = 12,
        skill = AI.Skill.EXCELLENT,
        altitude = 20000,
        speed = 350,
        patrolTime = 30,
        type = "FIGHTER"
    },
    
    -- Second Squadron (different base)
    {
        templateName = "RED_CAP_Base2_SU27",
        displayName = "Base 2 CAP",
        airbaseName = "Severomorsk-1",
        aircraft = 16,
        skill = AI.Skill.ACE,
        altitude = 25000,
        speed = 380,
        patrolTime = 25,
        type = "FIGHTER"
    },
    
    -- Add more squadrons here...
}
```

**Repeat the same process for BLUE squadrons** in the `BLUE_SQUADRON_CONFIG` section.

---

## Zone-Based Defense Setup

Zones allow squadrons to have specific areas of responsibility, creating realistic layered defense.

### Why Use Zones?

- **Border Defense:** Squadrons patrol specific sectors
- **Layered Defense:** Multiple squadrons cover overlapping areas
- **Priority Response:** Squadrons respond differently based on threat location
- **Realistic Behavior:** Fighters don't fly across the entire map for minor threats

### Zone Types

Each squadron can have up to 3 zone types:

1. **Primary Zone** - Main area of responsibility (full response)
2. **Secondary Zone** - Support area (reduced response, 60% by default)
3. **Tertiary Zone** - Emergency fallback (enhanced response when squadron weakened)

### Creating Zones in Mission Editor

**Method: Helicopter Waypoint Method**

1. Place a **helicopter group** (late activation, any type)
2. Name it clearly (example: `"RED BORDER"`)
3. Add waypoints that outline your zone boundary
4. The script will automatically create a polygon zone from these waypoints
5. Repeat for each zone you want to create

**Example Zone Setup:**
```
Mission Editor:
- Helicopter Group: "RED BORDER" with waypoints forming a polygon
- Helicopter Group: "BLUE BORDER" with waypoints forming a polygon
- Helicopter Group: "CONTESTED ZONE" with waypoints forming a polygon
```

### Configuring Zone Response

Add zone configuration to your squadron:

```lua
{
    templateName = "RED_CAP_Kilpyavr_MiG29",
    displayName = "Kilpyavr CAP",
    airbaseName = "Kilpyavr",
    aircraft = 12,
    skill = AI.Skill.EXCELLENT,
    altitude = 20000,
    speed = 350,
    patrolTime = 30,
    type = "FIGHTER",
    
    -- Zone Configuration
    primaryZone = "RED BORDER",                    -- Main responsibility area
    secondaryZone = "CONTESTED ZONE",              -- Backup coverage
    tertiaryZone = nil,                            -- No tertiary zone
    
    -- Optional: Customize zone behavior
    zoneConfig = {
        primaryResponse = 1.0,                     -- Full response in primary zone
        secondaryResponse = 0.6,                   -- 60% response in secondary
        tertiaryResponse = 1.4,                    -- 140% response in tertiary
        enableFallback = false,                    -- Don't auto-switch to tertiary
        fallbackThreshold = 0.3,                   -- Switch when <30% aircraft remain
        secondaryLowPriorityFilter = true,         -- Ignore small threats in secondary
        secondaryLowPriorityThreshold = 2          -- "Small threat" = 2 or fewer aircraft
    }
}
```

### Zone Behavior Examples

**Example 1: Border Defense Squadron**
```lua
primaryZone = "RED BORDER",          -- Patrols the border
secondaryZone = "INTERIOR",          -- Helps with interior threats if needed
tertiaryZone = nil                   -- No fallback
```

**Example 2: Base Defense with Fallback**
```lua
primaryZone = "NORTHERN SECTOR",     -- Main patrol area
secondaryZone = nil,                 -- No secondary
tertiaryZone = "BASE PERIMETER",     -- Falls back to defend base when weakened
enableFallback = true,               -- Auto-switch to tertiary when low
fallbackThreshold = 0.4              -- Switch at 40% strength
```

**Example 3: Layered Defense**
```lua
-- Squadron A: Outer layer
primaryZone = "OUTER PERIMETER"

-- Squadron B: Middle layer
primaryZone = "MIDDLE PERIMETER"

-- Squadron C: Inner/base defense
primaryZone = "BASE DEFENSE"
```

### Global Response (No Zones)

If you **DON'T** want zone restrictions, simply leave all zones as `nil`:

```lua
{
    templateName = "RED_CAP_Base_MiG29",
    displayName = "Global Response CAP",
    airbaseName = "Kilpyavr",
    aircraft = 12,
    skill = AI.Skill.EXCELLENT,
    altitude = 20000,
    speed = 350,
    patrolTime = 30,
    type = "FIGHTER",
    
    -- No zones = responds to threats anywhere on the map
    primaryZone = nil,
    secondaryZone = nil,
    tertiaryZone = nil
}
```

---

## Cargo Replenishment System

The cargo system automatically replenishes squadrons by spawning transport aircraft that fly supplies to airbases.

### How Cargo Works

1. **Monitoring:** Script checks squadron aircraft counts every minute
2. **Detection:** When squadron drops below threshold (90% by default), cargo is dispatched
3. **Spawning:** Transport aircraft spawns at a supply airfield
4. **Delivery:** Flies to destination airbase and lands
5. **Replenishment:** Squadron aircraft count increases upon delivery
6. **Cooldown:** 5-minute cooldown before next delivery to same base

### Cargo Aircraft Detection

The system detects cargo by aircraft name patterns:
- `CARGO`
- `TRANSPORT`
- `C130` or `C-130`
- `AN26` or `AN-26`

**Delivery Methods:**
- **Landing:** Aircraft lands at destination airbase

### Configuring Cargo Templates

Edit `Moose_TADC_CargoDispatcher.lua` and find `CARGO_SUPPLY_CONFIG`:

```lua
local CARGO_SUPPLY_CONFIG = {
    red = {
        cargoTemplate = "CARGO_RED_AN26_TEMPLATE",         -- Template name from mission editor
        supplyAirfields = {"Airbase1", "Airbase2"},        -- List of supply bases
        replenishAmount = 4,                               -- Aircraft added per delivery
        threshold = 0.90                                   -- Trigger at 90% capacity
    },
    blue = {
        cargoTemplate = "CARGO_BLUE_C130_TEMPLATE",
        supplyAirfields = {"Airbase3", "Airbase4"},
        replenishAmount = 4,
        threshold = 0.90
    }
}
```

### Creating Cargo Templates

1. **In Mission Editor:**
   - Place transport aircraft group (C-130, An-26, etc.)
   - Name it: `CARGO_RED_AN26_TEMPLATE` or `CARGO_BLUE_C130_TEMPLATE`
   - Set **LATE ACTIVATION**
   - Position at any friendly airbase (starting position doesn't matter)

2. **In Configuration:**
   - Use the EXACT template name in `cargoTemplate` field
   - List supply airbases in `supplyAirfields` array
   - Set how many aircraft each delivery adds (`replenishAmount`)

### Supply Airfield Strategy

**Choose rear/safe airbases for supplies:**

```lua
red = {
    cargoTemplate = "CARGO_RED_AN26_TEMPLATE",
    supplyAirfields = {
        "Rear_Base_1",              -- Far from frontline, safe
        "Rear_Base_2",              -- Alternate supply source
        "Central_Logistics_Hub"     -- Main supply depot
    },
    replenishAmount = 4,
    threshold = 0.90
}
```

**Tips:**
- Use 3-5 supply airbases for redundancy
- Choose bases far from combat zones
- Ensure supply bases are well-defended
- Balance geographic coverage

### Disabling Cargo System

If you don't want automated resupply:
1. **Don't load** `Moose_TADC_CargoDispatcher.lua`
2. Squadrons will operate with their initial aircraft count only
3. System still works perfectly for shorter missions

---

## Testing & Troubleshooting

### Validation Tools

The system includes built-in validation. Check the DCS log file after mission start for:

```
[Universal TADC] ═══════════════════════════════════════
[Universal TADC] Configuration Validation Results:
[Universal TADC] ✓ All templates exist
[Universal TADC] ✓ All airbases valid
[Universal TADC] ✓ All zones found
[Universal TADC] Configuration is VALID
[Universal TADC] ═══════════════════════════════════════
```

### In-Game F10 Menu Commands

Press **F10** in-game to access TADC utilities:

**Available to Each Coalition:**
- **Show Squadron Resource Summary** - Current aircraft counts
- **Show Airbase Status Report** - Operational status of all bases
- **Show Active Interceptors** - Currently airborne fighters
- **Show Threat Summary** - Detected enemy aircraft
- **Broadcast Squadron Summary Now** - Force immediate status update
- **Show Cargo Delivery Log** - Recent supply missions
- **Show Zone Coverage Map** - Squadron zone assignments

**Available to All (Mission Commands):**
- **Emergency Cleanup Interceptors** - Remove stuck/dead groups
- **Show TADC System Status** - Uptime and system health
- **Check for Stuck Aircraft** - Manual stuck aircraft check
- **Show Airbase Health Status** - Parking/spawn issues

### Common Issues & Solutions

#### Issue: "Template not found in mission"

**Cause:** Template name in config doesn't match mission editor  
**Solution:**
1. Check exact spelling and case
2. Ensure template is in mission editor
3. Verify template is a GROUP (not a unit)
4. Check template name in mission editor properties

#### Issue: "Airbase not found or wrong coalition"

**Cause:** Airbase name wrong or captured by enemy  
**Solution:**
1. Check exact airbase spelling (case sensitive)
2. Verify airbase is owned by correct coalition in mission editor
3. Use `_G.TDAC_CheckAirbase("AirbaseName")` in DCS console

#### Issue: "No interceptors launching"

**Check:**
1. Are enemy aircraft detected? (F10 → Show Threat Summary)
2. Are squadrons operational? (F10 → Show Squadron Resource Summary)
3. Is airbase captured/destroyed? (F10 → Show Airbase Status Report)
4. Are squadrons on cooldown? (F10 → Show Squadron Resource Summary)
5. Check intercept ratio settings (might be too low)

#### Issue: "Cargo not delivering"

**Check:**
1. Is cargo template name correct?
2. Are supply airbases valid and friendly?
3. Is destination airbase captured/operational?
4. Check parking availability (F10 → Show Airbase Health Status)
5. Look for "Cargo delivery detected" messages in log

#### Issue: "Aircraft spawning stuck at parking"

**Cause:** Parking spots occupied or insufficient space  
**Solution:**
1. Use F10 → Check for Stuck Aircraft
2. Use F10 → Emergency Cleanup Interceptors
3. Check airbase parking capacity (larger aircraft need more space)
4. Reduce squadron sizes if parking is limited

### DCS Console Diagnostics

Open DCS Lua console (**F12** or scripting console) and run:

```lua
-- Check all supply airbase ownership
_G.TDAC_CheckAirbaseOwnership()

-- Check specific airbase
_G.TDAC_CheckAirbase("Kilpyavr")

-- Validate dispatcher configuration
_G.TDAC_RunConfigCheck()

-- Check airbase parking availability
_G.TDAC_LogAirbaseParking("Kilpyavr")

-- Test cargo spawn (debugging)
_G.TDAC_CargoDispatcher_TestSpawn("CARGO_RED_AN26_TEMPLATE", "SupplyBase", "DestinationBase")
```

---

## Advanced Features

### Intercept Ratio System

The `interceptRatio` setting controls how many fighters launch per enemy aircraft.

**In `Moose_TADC_Load2nd.lua`:**

```lua
local TADC_SETTINGS = {
    red = {
        interceptRatio = 0.8,          -- RED launches 0.8 fighters per threat
        maxActiveCAP = 8,              -- Max 8 groups in air simultaneously
        defaultCooldown = 300,         -- 5-minute cooldown after engagement
    },
    blue = {
        interceptRatio = 1.2,          -- BLUE launches 1.2 fighters per threat
        maxActiveCAP = 10,             -- Max 10 groups in air simultaneously
        defaultCooldown = 300,
    }
}
```

**Intercept Ratio Chart:**

| Ratio | 1 Enemy | 4 Enemies | 8 Enemies | Effect |
|-------|---------|-----------|-----------|--------|
| 0.5 | 1 fighter | 2 fighters | 4 fighters | Conservative response |
| 0.8 | 1 fighter | 4 fighters | 7 fighters | **Balanced (default)** |
| 1.0 | 1 fighter | 4 fighters | 8 fighters | 1:1 parity |
| 1.4 | 2 fighters | 6 fighters | 12 fighters | Strong response |
| 2.0 | 2 fighters | 8 fighters | 16 fighters | Overwhelming force |

**Tactical Effects:**
- **Low (0.5-0.8):** Sustainable defense, squadrons last longer
- **Medium (0.8-1.2):** Balanced dogfights, realistic attrition
- **High (1.4-2.0):** Strong defense, rapid squadron depletion

**Asymmetric Scenarios:**
```lua
-- RED advantage
red = { interceptRatio = 1.4 },
blue = { interceptRatio = 0.8 }

-- BLUE advantage
red = { interceptRatio = 0.8 },
blue = { interceptRatio = 1.4 }
```

### Distance-Based Engagement

Control how far squadrons will chase threats:

```lua
{
    templateName = "RED_CAP_Base_MiG29",
    displayName = "Base Defense",
    airbaseName = "Kilpyavr",
    aircraft = 12,
    -- ... other settings ...
    
    zoneConfig = {
        maxEngagementRange = 50000,      -- Won't engage threats >50km from base
        primaryResponse = 1.0,
        secondaryResponse = 0.6
    }
}
```

### Cooldown System

After launching interceptors, squadrons go on cooldown to prevent spam:

```lua
local TADC_SETTINGS = {
    red = {
        defaultCooldown = 300,           -- 5 minutes between launches
        -- ... other settings ...
    }
}
```

**Per-Squadron Cooldown (optional):**
```lua
{
    templateName = "RED_CAP_Base_MiG29",
    cooldownOverride = 600,              -- This squadron: 10-minute cooldown
    -- ... other settings ...
}
```

### Aircraft Skill Levels

Adjust AI difficulty per squadron:

```lua
skill = AI.Skill.AVERAGE      -- Easiest, good for training
skill = AI.Skill.GOOD         -- Below average
skill = AI.Skill.HIGH         -- Average pilots
skill = AI.Skill.EXCELLENT    -- Above average (recommended)
skill = AI.Skill.ACE          -- Hardest, expert pilots
```

**Mixed Difficulty Example:**
```lua
RED_SQUADRON_CONFIG = {
    {
        displayName = "Elite Squadron",
        skill = AI.Skill.ACE,             -- Best pilots
        aircraft = 8,
        -- ...
    },
    {
        displayName = "Regular Squadron",
        skill = AI.Skill.GOOD,            -- Average pilots
        aircraft = 12,
        -- ...
    }
}
```

---

## Common Scenarios

### Scenario 1: Simple Border Defense

**Goal:** RED defends northern border, BLUE defends southern border

```lua
-- RED Configuration
RED_SQUADRON_CONFIG = {
    {
        templateName = "RED_CAP_North_MiG29",
        displayName = "Northern Border CAP",
        airbaseName = "Northern_Base",
        aircraft = 12,
        skill = AI.Skill.EXCELLENT,
        altitude = 20000,
        speed = 350,
        patrolTime = 30,
        type = "FIGHTER",
        primaryZone = "RED BORDER"
    }
}

-- BLUE Configuration
BLUE_SQUADRON_CONFIG = {
    {
        templateName = "BLUE_CAP_South_F16",
        displayName = "Southern Border CAP",
        airbaseName = "Southern_Base",
        aircraft = 12,
        skill = AI.Skill.EXCELLENT,
        altitude = 20000,
        speed = 350,
        patrolTime = 30,
        type = "FIGHTER",
        primaryZone = "BLUE BORDER"
    }
}
```

**In Mission Editor:**
- Create zone "RED BORDER" (helicopter waypoints on northern border)
- Create zone "BLUE BORDER" (helicopter waypoints on southern border)

---

### Scenario 2: Layered Defense Network

**Goal:** Multiple squadrons covering overlapping zones with different priorities

```lua
RED_SQUADRON_CONFIG = {
    -- Outer Layer: Long-range interceptors
    {
        templateName = "RED_LONG_RANGE_MiG31",
        displayName = "Long Range Interceptors",
        airbaseName = "Forward_Base",
        aircraft = 8,
        skill = AI.Skill.EXCELLENT,
        altitude = 35000,
        speed = 450,
        patrolTime = 20,
        type = "FIGHTER",
        primaryZone = "OUTER PERIMETER"
    },
    
    -- Middle Layer: General defense
    {
        templateName = "RED_CAP_MiG29",
        displayName = "Middle Defense CAP",
        airbaseName = "Central_Base",
        aircraft = 12,
        skill = AI.Skill.EXCELLENT,
        altitude = 25000,
        speed = 350,
        patrolTime = 30,
        type = "FIGHTER",
        primaryZone = "MIDDLE PERIMETER",
        secondaryZone = "OUTER PERIMETER"
    },
    
    -- Inner Layer: Point defense
    {
        templateName = "RED_BASE_DEFENSE_SU27",
        displayName = "Base Defense",
        airbaseName = "Main_Base",
        aircraft = 16,
        skill = AI.Skill.ACE,
        altitude = 20000,
        speed = 320,
        patrolTime = 40,
        type = "FIGHTER",
        primaryZone = "BASE PERIMETER",
        tertiaryZone = "BASE PERIMETER",
        zoneConfig = {
            enableFallback = true,
            fallbackThreshold = 0.3
        }
    }
}
```

---

### Scenario 3: Sustained Operations with Resupply

**Goal:** Long mission with automated squadron replenishment

**Squadron Config:**
```lua
RED_SQUADRON_CONFIG = {
    {
        templateName = "RED_CAP_Frontline_MiG29",
        displayName = "Frontline CAP",
        airbaseName = "Frontline_Base",
        aircraft = 12,                    -- Will be resupplied
        skill = AI.Skill.EXCELLENT,
        altitude = 20000,
        speed = 350,
        patrolTime = 30,
        type = "FIGHTER",
        primaryZone = "COMBAT ZONE"
    }
}
```

**Cargo Config** (in `Moose_TADC_CargoDispatcher.lua`):
```lua
local CARGO_SUPPLY_CONFIG = {
    red = {
        cargoTemplate = "CARGO_RED_AN26",
        supplyAirfields = {
            "Rear_Base_1",                -- Safe logistics hub
            "Rear_Base_2",                -- Backup supply source
            "Central_Depot"               -- Main supply depot
        },
        replenishAmount = 4,              -- +4 aircraft per delivery
        threshold = 0.75                  -- Trigger at 75% (9/12 aircraft)
    }
}
```

**Mission Flow:**
1. Frontline squadron intercepts threats
2. Squadron drops to 9 aircraft (75%)
3. Cargo automatically dispatched from rear base
4. Transport flies to frontline base
5. Cargo delivers, squadron back to 12 aircraft
6. Cycle repeats throughout mission

---

### Scenario 4: Asymmetric Warfare

**Goal:** RED has numerical superiority, BLUE has quality advantage

```lua
-- RED: More squadrons, lower skill
local TADC_SETTINGS = {
    red = {
        interceptRatio = 0.8,            -- Conservative response
        maxActiveCAP = 12,               -- More groups allowed
    }
}

RED_SQUADRON_CONFIG = {
    {
        templateName = "RED_CAP_1",
        airbaseName = "Base_1",
        aircraft = 16,                    -- Large squadron
        skill = AI.Skill.GOOD,            -- Average skill
        -- ...
    },
    {
        templateName = "RED_CAP_2",
        airbaseName = "Base_2",
        aircraft = 16,
        skill = AI.Skill.GOOD,
        -- ...
    },
    {
        templateName = "RED_CAP_3",
        airbaseName = "Base_3",
        aircraft = 16,
        skill = AI.Skill.GOOD,
        -- ...
    }
}

-- BLUE: Fewer squadrons, higher skill
local TADC_SETTINGS = {
    blue = {
        interceptRatio = 1.2,            -- Aggressive response
        maxActiveCAP = 8,                -- Fewer groups
    }
}

BLUE_SQUADRON_CONFIG = {
    {
        templateName = "BLUE_CAP_1",
        airbaseName = "Base_1",
        aircraft = 10,                    -- Smaller squadron
        skill = AI.Skill.ACE,             -- Elite pilots
        -- ...
    },
    {
        templateName = "BLUE_CAP_2",
        airbaseName = "Base_2",
        aircraft = 10,
        skill = AI.Skill.ACE,
        -- ...
    }
}
```

---

## Tips for New Mission Makers

### Start Simple

1. **First Mission:** Use 1-2 squadrons per side with no zones
2. **Second Mission:** Add zone-based defense
3. **Third Mission:** Add cargo resupply system
4. **Advanced:** Multi-squadron layered defense with fallback

### Realistic Aircraft Numbers

**Small Airbase:** 6-8 aircraft per squadron  
**Medium Airbase:** 10-12 aircraft per squadron  
**Large Airbase:** 14-18 aircraft per squadron  

**Balance across map:** If RED has 40 total aircraft, BLUE should have similar unless asymmetric

### Performance Considerations

- **Limit active groups:** Use `maxActiveCAP` to prevent FPS drops
- **Zone sizes matter:** Smaller zones = less scanning overhead
- **Cargo cooldowns:** Prevent cargo spam with reasonable cooldowns
- **Squadron counts:** 3-5 squadrons per side is a good starting point

### Testing Workflow

1. **Create minimal setup** (1 squadron each side)
2. **Test in mission editor** using "Fly Now"
3. **Check F10 menus** for squadron status
4. **Spawn enemy aircraft** to test intercepts
5. **Review DCS.log** for validation messages
6. **Expand gradually** once basic system works

### Common Mistakes to Avoid

❌ **Using UNIT templates instead of GROUP templates**  
✅ Use GROUP templates (late activation groups)

❌ **Misspelling airbase names**  
✅ Copy exact names from mission editor

❌ **Loading scripts in wrong order**  
✅ Squadron Config → Main TADC → Cargo Dispatcher

❌ **Setting intercept ratio too high**  
✅ Start with 0.8-1.0, adjust after testing

❌ **Forgetting to load MOOSE first**  
✅ MOOSE must be first script loaded

---

## Conclusion

The Universal TADC system provides mission makers with powerful, automated air defense capabilities that create dynamic, realistic air combat scenarios. By following this guide, even new mission makers can create sophisticated missions with minimal scripting knowledge.

### Key Takeaways

✅ **Three scripts work together:** Squadron Config → Main TADC → Cargo Dispatcher  
✅ **Configuration is simple:** Edit tables, not complex code  
✅ **Both coalitions operate independently:** Balanced or asymmetric scenarios  
✅ **Zones enable tactical behavior:** Realistic area-of-responsibility system  
✅ **Cargo enables sustained operations:** Long missions with automatic resupply  
✅ **Built-in validation:** Checks configuration before mission starts  
✅ **F10 menus provide visibility:** Monitor system status in real-time  

### Getting Help

If you encounter issues:

1. Check DCS.log for validation errors
2. Use F10 menu diagnostics
3. Run console commands for detailed info
4. Review this guide's troubleshooting section
5. Start simple and expand gradually

### Next Steps

1. Set up your first squadron (1 RED, 1 BLUE)
2. Test basic intercept behavior
3. Add zones for tactical depth
4. Implement cargo resupply for long missions
5. Experiment with advanced features

Happy mission making! 🚁✈️

---
*Author: F99th-TracerFacer
*Document Version: 1.0*  
*Last Updated: October 2025*  
*Compatible with: MOOSE Framework & DCS World*
