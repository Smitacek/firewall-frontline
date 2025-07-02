# Firewall Frontline - System Architecture

## 1. Přehled architektury

### Design principy
- **Separation of Concerns**: Oddělení logiky od prezentace
- **Data-Driven Design**: Všechny balance hodnoty v externích souborech
- **Dependency Injection**: Pro testovatelnost
- **Signal-Based Communication**: Minimalizace přímých závislostí
- **State Machine Pattern**: Pro AI a game flow

### Vrstvy aplikace
```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│         (GUI, Scenes, Visual)           │
├─────────────────────────────────────────┤
│            Game Logic Layer             │
│      (Domain, Systems, Managers)        │
├─────────────────────────────────────────┤
│             Data Layer                  │
│    (Resources, Configs, Save Data)      │
└─────────────────────────────────────────┘
```

## 2. Core Systems

### 2.1 Game Manager (Singleton)
```gdscript
# domain/core/game_manager.gd
class_name GameManager

signal game_state_changed(new_state: GameState)
signal wave_completed(wave_number: int)
signal game_over(victory: bool)

enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    WAVE_PREP,
    GAME_OVER
}

var current_state: GameState
var current_level: LevelData
var economy_manager: EconomyManager
var wave_manager: WaveManager
var module_manager: ModuleManager
```

### 2.2 Module System Architecture

#### Base Module Class
```gdscript
# domain/modules/base_module.gd
class_name BaseModule

signal module_upgraded(level: int)
signal module_destroyed()
signal target_acquired(enemy: BaseEnemy)

# Module stats
var module_type: String
var level: int = 1
var max_level: int = 3
var base_cost: int
var upgrade_costs: Array[int]

# Combat stats
var damage: float
var attack_speed: float
var range: float
var damage_types: Array[DamageType]

# Abstract methods
func _can_target(enemy: BaseEnemy) -> bool:
    pass

func _apply_effect(enemy: BaseEnemy) -> void:
    pass

func upgrade() -> bool:
    pass
```

#### Module Factory
```gdscript
# domain/modules/module_factory.gd
class_name ModuleFactory

static func create_module(type: ModuleType, position: Vector2) -> BaseModule:
    var module_scene = _get_module_scene(type)
    var instance = module_scene.instantiate()
    instance.position = position
    return instance

static func _get_module_scene(type: ModuleType) -> PackedScene:
    match type:
        ModuleType.POWER_NODE:
            return preload("res://scenes/modules/PowerNode.tscn")
        ModuleType.FIREWALL:
            return preload("res://scenes/modules/Firewall.tscn")
        # ... další moduly
```

### 2.3 Enemy System Architecture

#### Base Enemy Class
```gdscript
# domain/enemies/base_enemy.gd
class_name BaseEnemy

signal enemy_destroyed(reward: int)
signal reached_target()
signal status_effect_applied(effect: StatusEffect)

# Enemy stats
var enemy_type: String
var tier: int
var max_health: float
var current_health: float
var movement_speed: float
var damage_type: DamageType
var reward_cpu: int
var vulnerabilities: Array[DamageType]
var resistances: Array[DamageType]

# AI State Machine
var state_machine: StateMachine
var current_path: Array[Vector2]

func take_damage(amount: float, damage_type: DamageType) -> void:
    var final_damage = calculate_damage(amount, damage_type)
    current_health -= final_damage
    if current_health <= 0:
        _on_destroyed()
```

#### Enemy AI State Machine
```gdscript
# domain/ai/enemy_state_machine.gd
class_name EnemyStateMachine

enum State {
    SPAWNING,
    MOVING,
    ATTACKING,
    STUNNED,
    DYING
}

var current_state: State
var enemy: BaseEnemy

func transition_to(new_state: State) -> void:
    _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)

func _enter_state(state: State) -> void:
    match state:
        State.MOVING:
            enemy.start_pathfinding()
        State.ATTACKING:
            enemy.begin_attack_sequence()
        State.STUNNED:
            enemy.apply_stun_effect()
```

### 2.4 Lane System

```gdscript
# domain/lanes/lane_system.gd
class_name LaneSystem

signal enemy_reached_end(lane_id: int)

var lanes: Array[Lane]
var grid_size: Vector2 = Vector2(8, 5)
var cell_size: float = 64.0

class Lane:
    var id: int
    var path_points: Array[Vector2]
    var spawn_point: Vector2
    var end_point: Vector2
    var active_enemies: Array[BaseEnemy]
    var module_slots: Array[ModuleSlot]
    
    func can_place_module(position: Vector2) -> bool:
        var slot = get_slot_at_position(position)
        return slot != null and slot.is_empty
```

### 2.5 Economy System

```gdscript
# domain/economy/economy_manager.gd
class_name EconomyManager

signal cpu_changed(new_amount: int)
signal research_changed(new_amount: int)
signal insufficient_funds()

var cpu_cycles: int = 150
var research_tokens: int = 0
var passive_income_rate: float = 0.5  # CPU per second
var income_multiplier: float = 1.0

func can_afford(cost: int) -> bool:
    return cpu_cycles >= cost

func spend_cpu(amount: int) -> bool:
    if can_afford(amount):
        cpu_cycles -= amount
        cpu_changed.emit(cpu_cycles)
        return true
    else:
        insufficient_funds.emit()
        return false

func add_income_source(source: IncomeSource) -> void:
    # Power Nodes a další zdroje
    pass
```

### 2.6 Wave Management System

```gdscript
# domain/waves/wave_manager.gd
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal enemy_spawned(enemy: BaseEnemy, lane: int)

var current_wave: int = 0
var wave_data: WaveData
var spawn_timer: Timer
var enemies_remaining: int = 0
var wave_in_progress: bool = false

func start_wave(wave_number: int) -> void:
    current_wave = wave_number
    wave_data = _load_wave_data(wave_number)
    wave_in_progress = true
    wave_started.emit(wave_number)
    _begin_spawning()

func _load_wave_data(wave_number: int) -> WaveData:
    # Načte data z JSON/Resource
    var file_path = "res://data/waves/wave_%d.json" % wave_number
    return WaveDataLoader.load(file_path)
```

## 3. Data Architecture

### 3.1 Module Data Structure
```json
{
  "power_node": {
    "display_name": "Power Node",
    "description": "Generates CPU cycles over time",
    "base_stats": {
      "cost": 50,
      "generation_rate": 5,
      "generation_interval": 5.0
    },
    "upgrades": [
      {
        "level": 2,
        "cost": 100,
        "generation_rate": 8,
        "generation_interval": 4.0
      },
      {
        "level": 3,
        "cost": 200,
        "generation_rate": 12,
        "generation_interval": 3.0,
        "special": "aoe_boost"
      }
    ]
  }
}
```

### 3.2 Enemy Data Structure
```json
{
  "script_kiddie": {
    "display_name": "Script Kiddie",
    "tier": 1,
    "health": 50,
    "speed": 100,
    "damage_type": "packet",
    "reward": 10,
    "vulnerabilities": ["packet"],
    "resistances": [],
    "ai_behavior": "direct_path"
  }
}
```

### 3.3 Wave Data Structure
```json
{
  "wave_1": {
    "preparation_time": 30,
    "spawn_groups": [
      {
        "enemy_type": "script_kiddie",
        "count": 5,
        "spawn_delay": 2.0,
        "lane": "random"
      }
    ],
    "completion_bonus": {
      "cpu": 100,
      "research": 1
    }
  }
}
```

## 4. Signal Flow Diagram

```
User Input
    ↓
GUI Layer → Module Placement Signal
    ↓
Module Manager → Validate Placement
    ↓
Economy Manager → Check Funds
    ↓
Lane System → Place Module
    ↓
Module Instance → Start Operating
    ↓
Enemy Detection → Combat System
    ↓
Damage Calculation → Enemy State
    ↓
Enemy Destroyed → Reward System
    ↓
Economy Update → GUI Update
```

## 5. Performance Optimizations

### 5.1 Object Pooling
```gdscript
# domain/utils/object_pool.gd
class_name ObjectPool

var pool_scene: PackedScene
var available_objects: Array = []
var active_objects: Array = []
var max_pool_size: int = 100

func get_object() -> Node:
    if available_objects.is_empty():
        return pool_scene.instantiate()
    else:
        var obj = available_objects.pop_back()
        active_objects.append(obj)
        return obj

func return_object(obj: Node) -> void:
    active_objects.erase(obj)
    available_objects.append(obj)
    obj.reset()
```

### 5.2 Spatial Partitioning
```gdscript
# domain/utils/spatial_grid.gd
class_name SpatialGrid

var grid: Dictionary = {}
var cell_size: float = 128.0

func add_entity(entity: Node2D) -> void:
    var cell = _get_cell_coords(entity.position)
    if not grid.has(cell):
        grid[cell] = []
    grid[cell].append(entity)

func get_entities_in_range(position: Vector2, range: float) -> Array:
    var entities = []
    var cells_to_check = _get_cells_in_range(position, range)
    for cell in cells_to_check:
        if grid.has(cell):
            entities.append_array(grid[cell])
    return entities
```

## 6. Testing Strategy

### 6.1 Unit Tests
```gdscript
# tests/test_economy_manager.gd
extends WAT.Test

func test_can_afford_with_sufficient_funds():
    var economy = EconomyManager.new()
    economy.cpu_cycles = 100
    asserts.is_true(economy.can_afford(50))

func test_spend_cpu_deducts_correctly():
    var economy = EconomyManager.new()
    economy.cpu_cycles = 100
    economy.spend_cpu(30)
    asserts.is_equal(economy.cpu_cycles, 70)
```

### 6.2 Integration Tests
```gdscript
# tests/test_module_placement.gd
extends WAT.Test

func test_module_placement_full_flow():
    var game = preload("res://tests/mocks/MockGameSetup.tscn").instantiate()
    var module_pos = Vector2(100, 100)
    
    game.module_manager.request_placement(ModuleType.FIREWALL, module_pos)
    yield(game.get_tree().create_timer(0.1), "timeout")
    
    asserts.is_not_null(game.lane_system.get_module_at(module_pos))
    asserts.is_equal(game.economy_manager.cpu_cycles, 50)  # 150 - 100
```

## 7. Návrhové vzory použité v architektuře

1. **Singleton**: GameManager pro globální stav
2. **Factory**: ModuleFactory pro vytváření modulů
3. **State Machine**: Pro AI nepřátel a game flow
4. **Observer**: Signal system pro event-driven komunikaci
5. **Object Pool**: Pro projectily a časté objekty
6. **Strategy**: Pro různé AI chování nepřátel
7. **Component**: Modulární systém schopností

## 8. Rozšiřitelnost

### Přidání nového modulu
1. Vytvořit novou třídu dědící z BaseModule
2. Přidat data do module_data.json
3. Registrovat v ModuleFactory
4. Vytvořit vizuální scénu v scenes/modules/

### Přidání nového nepřítele
1. Vytvořit novou třídu dědící z BaseEnemy
2. Definovat unikátní AI behavior
3. Přidat data do enemy_data.json
4. Vytvořit vizuální scénu v scenes/enemies/

### Přidání nové mechaniky
1. Vytvořit nový systém v domain/systems/
2. Registrovat v GameManager
3. Propojit pomocí signálů
4. Přidat UI v gui/ pokud potřeba