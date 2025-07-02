# Firewall Frontline - Vertical Slice Implementation Plan

## 1. Cíl Vertical Slice

### Co implementovat
Minimální hratelná verze demonstrující core loop hry:
- 3 lanes tower defense
- 4 základní moduly (PWR, FWL, HPT, IDS)
- 1 typ nepřítele (Script Kiddie)
- Základní ekonomika (CPU cycles)
- 5 vln + sandbox mode
- Tutorial

### Success Criteria
- ✅ Hráč může umístit moduly na grid
- ✅ Nepřátelé spawn a pohybují se po lanes
- ✅ Moduly střílí a ničí nepřátele
- ✅ Ekonomický systém funguje (generování/utrácení CPU)
- ✅ Vlny se postupně zvyšují obtížnost
- ✅ Win/Lose conditions
- ✅ Základní tutorial

## 2. Fáze implementace

### Fáze 1: Core Infrastructure (Týden 1)
**Cíl**: Základní systémy a Godot projekt setup

#### 1.1 Projekt setup
- [x] Vytvořit Godot 4.x projekt
- [x] Nastavit folder strukturu podle specifikace
- [x] Git repository s .gitignore
- [x] CI/CD pipeline (GitHub Actions)

#### 1.2 Base systémy
- [ ] GameManager singleton
- [ ] Scene management (Main.tscn)
- [ ] Basic UI framework
- [ ] Signal system setup

#### 1.3 Grid a Lane system
- [ ] 8x5 grid overlay
- [ ] 3 lanes s pathfinding body
- [ ] Module placement validation
- [ ] Visual feedback pro placement

**Deliverable**: Prázdná scéna s gridem kde můžeme kliknout a vidět valid placement zones.

### Fáze 2: Economy & Module System (Týden 2)
**Cíl**: Fungující ekonomika a umísťování modulů

#### 2.1 Economy Manager
- [ ] CPU cycles tracking
- [ ] Income generation system
- [ ] Spend/earn mechanics
- [ ] UI zobrazení resources

#### 2.2 Base Module System
- [ ] BaseModule abstract class
- [ ] Module placement logic
- [ ] Module upgrade system (basic)
- [ ] Module data loading (JSON)

#### 2.3 První moduly
- [ ] Power Node - CPU generation
- [ ] Firewall - basic tower
- [ ] Honeypot - enemy lure
- [ ] IDS - area effect detection

**Deliverable**: Můžeme kupovat a umísťovat moduly, Power Node generuje CPU.

### Fáze 3: Enemy System (Týden 3)
**Cíl**: Nepřátelé se spawní a pohybují

#### 3.1 Base Enemy System
- [ ] BaseEnemy class s health/movement
- [ ] Pathfinding systém (A* nebo simple)
- [ ] Enemy spawning system
- [ ] Health bars a visual feedback

#### 3.2 Script Kiddie Implementation
- [ ] Sprite a animace
- [ ] Movement behavior
- [ ] Damage/death mechanics
- [ ] Drop rewards (CPU)

#### 3.3 Lane Navigation
- [ ] Path definition pro každou lane
- [ ] Smooth movement mezi body
- [ ] Collision detection s modules
- [ ] End-of-lane damage to player

**Deliverable**: Script Kiddies spawn, jdou po lanes a můžeme je zabít.

### Fáze 4: Combat System (Týden 4)
**Cíl**: Moduly útočí na nepřátele

#### 4.1 Targeting System
- [ ] Range detection pro moduly
- [ ] Target priority (closest, strongest, etc.)
- [ ] Line of sight calculation
- [ ] Target switching logic

#### 4.2 Combat Mechanics
- [ ] Projectile system (bullets/effects)
- [ ] Damage calculation
- [ ] Status effects (slow, stun)
- [ ] Module special abilities

#### 4.3 Visual Effects
- [ ] Muzzle flashes
- [ ] Projectile trails
- [ ] Hit effects
- [ ] Death animations

**Deliverable**: Kompletní combat loop - moduly střílí, nepřátelé umírají.

### Fáze 5: Wave System (Týden 5)
**Cíl**: Structured gameplay s progressí

#### 5.1 Wave Manager
- [ ] Wave definition system (JSON)
- [ ] Timed spawning
- [ ] Wave preparation phase
- [ ] Difficulty scaling

#### 5.2 Game Flow
- [ ] Pre-wave preparation time
- [ ] Wave start/end conditions
- [ ] Victory/defeat detection
- [ ] Score/statistics tracking

#### 5.3 5 Tutorial Waves
- [ ] Wave 1: 3 Script Kiddies, basic tutorial
- [ ] Wave 2: 5 enemies, introduce Firewall
- [ ] Wave 3: 8 enemies, introduce Honeypot
- [ ] Wave 4: 10 enemies, introduce IDS
- [ ] Wave 5: 15 enemies, test all mechanics

**Deliverable**: 5 strukturovaných vln s postupnou obtížností.

### Fáze 6: Tutorial & Polish (Týden 6)
**Cíl**: Hratelná verze připravená na testování

#### 6.1 Tutorial System
- [ ] Interactive tooltips
- [ ] Forced placement v tutorial
- [ ] Step-by-step guidance
- [ ] Skip tutorial option

#### 6.2 UI/UX Polish
- [ ] Module selection panel
- [ ] Resource displays
- [ ] Wave progress indicator
- [ ] Game over/victory screens

#### 6.3 Audio Integration
- [ ] Basic sound effects
- [ ] Background music
- [ ] Audio mixing

#### 6.4 Bug fixes & Testing
- [ ] Performance optimization
- [ ] Balance tweaking
- [ ] Bug fixing
- [ ] Playtesting s feedbackem

**Deliverable**: Kompletní vertical slice připravený na first external playtest.

## 3. Technické detaily implementace

### 3.1 Data Structure Setup

#### Module Data (data/modules.json)
```json
{
  "power_node": {
    "name": "Power Node",
    "cost": 50,
    "generation_rate": 25,
    "generation_interval": 5.0,
    "sprite": "res://assets/art/modules/power_node.png"
  },
  "firewall": {
    "name": "Firewall",
    "cost": 100,
    "damage": 10,
    "attack_speed": 1.0,
    "range": 128,
    "sprite": "res://assets/art/modules/firewall.png"
  }
}
```

#### Wave Data (data/waves/wave_1.json)
```json
{
  "preparation_time": 30,
  "enemies": [
    {
      "type": "script_kiddie",
      "count": 3,
      "spawn_interval": 2.0,
      "lane": "random"
    }
  ],
  "rewards": {
    "cpu": 50
  }
}
```

### 3.2 Scene Structure
```
Main.tscn
├── UI Layer
│   ├── HUD
│   │   ├── CPUDisplay
│   │   ├── WaveInfo
│   │   └── ModulePanel
│   └── Dialogs
├── Game Layer
│   ├── GridOverlay
│   ├── LaneSystem
│   ├── ModuleContainer
│   └── EnemyContainer
└── Background
```

### 3.3 Script Organization
```
domain/
├── core/
│   ├── game_manager.gd
│   └── constants.gd
├── modules/
│   ├── base_module.gd
│   ├── power_node.gd
│   ├── firewall.gd
│   ├── honeypot.gd
│   └── ids.gd
├── enemies/
│   ├── base_enemy.gd
│   └── script_kiddie.gd
├── systems/
│   ├── economy_manager.gd
│   ├── wave_manager.gd
│   └── lane_system.gd
└── utils/
    ├── data_loader.gd
    └── grid_helper.gd
```

## 4. Art Assets Needed

### 4.1 Module Sprites (32x32)
- [ ] Power Node - Neonová věž s elektrickými efekty
- [ ] Firewall - Cyberpunk štít/barrier
- [ ] Honeypot - Atraktivní "nástražný" server
- [ ] IDS - Scanner s radarovým efektem

### 4.2 Enemy Sprites (32x32)
- [ ] Script Kiddie - Pixelová postavička s hoodie
- [ ] Death animation (4 frames)
- [ ] Walking animation (4 frames)

### 4.3 Environment
- [ ] Grid overlay texture
- [ ] Lane path markers
- [ ] Background (cyber-matrix style)
- [ ] UI panels a buttony

### 4.4 Effects
- [ ] Projectile sprites
- [ ] Explosion/hit effects
- [ ] Muzzle flash
- [ ] Health bar assets

## 5. Testing Strategy

### 5.1 Unit Tests (WAT framework)
```gdscript
# tests/test_economy.gd
func test_cpu_spending():
    var economy = EconomyManager.new()
    economy.cpu_cycles = 100
    asserts.is_true(economy.spend_cpu(50))
    asserts.is_equal(economy.cpu_cycles, 50)
```

### 5.2 Integration Tests
- [ ] Module placement workflow
- [ ] Combat loop (spawn → target → damage → destroy)
- [ ] Wave progression
- [ ] Save/load state

### 5.3 Performance Tests
- [ ] 50+ enemies na scéně současně
- [ ] 20+ modulů současně
- [ ] Memory usage během dlouhé hry
- [ ] 60 FPS na mid-range hardware

## 6. Risk Mitigation

### 6.1 Technical Risks
**Risk**: Pathfinding performance s více enemies
**Mitigation**: Využít Godot Navigation2D, A* optimalizace

**Risk**: Combat targeting calculations
**Mitigation**: Spatial partitioning, range checks only když potřeba

**Risk**: State synchronization bugs
**Mitigation**: Single source of truth v GameManager

### 6.2 Design Risks
**Risk**: Gameplay je nudný/moc jednoduchý
**Mitigation**: Časté playtesty, iterace na balance

**Risk**: Tutorial je moc složitý
**Mitigation**: User testing s neznalými hráči

### 6.3 Scope Risks
**Risk**: Feature creep
**Mitigation**: Striktní adherence k vertical slice scope

## 7. Definition of Done

### Pro každou featuru:
- [ ] Implementováno podle specifikace
- [ ] Unit testy píší a passed
- [ ] Code review dokončen
- [ ] Performance testováno (60 FPS target)
- [ ] Integrováno do main build
- [ ] Dokumentace aktualizována

### Pro vertical slice:
- [ ] Všechny fáze dokončeny
- [ ] End-to-end playtest successful
- [ ] External playtest provedeny (min 5 osob)
- [ ] Kritické bugy opraveny
- [ ] Build exports úspěšně
- [ ] Ready pro další dev fázi

## 8. Post Vertical Slice

### Immediate Next Steps
1. **Metrics Collection** - Sledování player behavior
2. **Feedback Integration** - Implementace změn z playtestů
3. **Additional Enemies** - Spam Bot, různé behavior
4. **Module Upgrades** - Level 2/3 pro existující moduly
5. **More Waves** - 10-15 vln s postupnou obtížností

### Long-term Roadmap
- Advanced enemy types (T2-T4)
- All 6 module types
- Campaign levels s unique challenges
- Endless mode s leaderboards
- Educational content integration