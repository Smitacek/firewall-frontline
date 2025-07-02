extends Node2D
class_name BaseModule

signal module_upgraded(new_level: int)
signal module_destroyed()
signal target_acquired(enemy: Node)
signal module_activated()

# Module identification
var module_type: Constants.ModuleType
var module_name: String
var description: String

# Position and grid
var grid_position: Vector2
var world_position: Vector2

# Level and upgrade system
var level: int = 1
var max_level: int = 3
var base_cost: int = 0
var upgrade_costs: Array[int] = []

# Combat stats (if applicable)
var damage: float = 0.0
var attack_speed: float = 1.0
var attack_range: float = 0.0
var damage_types: Array[Constants.DamageType] = []

# Special stats (vary by module type)
var generation_rate: int = 0
var generation_interval: float = 0.0
var special_effects: Dictionary = {}

# State
var is_active: bool = true
var last_action_time: float = 0.0

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var range_indicator: Node2D = $RangeIndicator
@onready var effects: Node2D = $Effects
@onready var ui_info: Control = $UIInfo

func _ready() -> void:
    _setup_module()
    _setup_visuals()
    _connect_signals()

func _setup_module() -> void:
    # Override in derived classes
    pass

func _setup_visuals() -> void:
    # Set up visual components
    if range_indicator:
        range_indicator.visible = false
    
    # Position sprite at center of cell
    if sprite:
        sprite.position = Vector2(Constants.CELL_SIZE / 2, Constants.CELL_SIZE / 2)

func _connect_signals() -> void:
    # Connect to game events
    pass

func initialize(grid_pos: Vector2, module_data: Dictionary) -> void:
    grid_position = grid_pos
    world_position = grid_pos * Constants.CELL_SIZE + Constants.GRID_OFFSET
    position = world_position
    
    # Load stats from data
    _load_from_data(module_data)
    
    print("Module initialized: ", module_name, " at ", grid_pos)

func _load_from_data(data: Dictionary) -> void:
    if data.has("name"):
        module_name = data.name
    if data.has("description"):
        description = data.description
    if data.has("base_cost"):
        base_cost = data.base_cost
    if data.has("upgrade_costs"):
        upgrade_costs = data.upgrade_costs
    if data.has("damage"):
        damage = data.damage
    if data.has("attack_speed"):
        attack_speed = data.attack_speed
    if data.has("range"):
        attack_range = data.range
    if data.has("generation_rate"):
        generation_rate = data.generation_rate
    if data.has("generation_interval"):
        generation_interval = data.generation_interval

func can_upgrade() -> bool:
    return level < max_level and level <= upgrade_costs.size()

func get_upgrade_cost() -> int:
    if can_upgrade():
        return upgrade_costs[level - 1]  # level 1->2 uses index 0
    return 0

func upgrade() -> bool:
    if not can_upgrade():
        return false
    
    var cost = get_upgrade_cost()
    if GameManager.economy_manager and GameManager.economy_manager.spend_cpu(cost):
        level += 1
        _apply_upgrade()
        module_upgraded.emit(level)
        print(module_name, " upgraded to level ", level)
        return true
    
    return false

func _apply_upgrade() -> void:
    # Override in derived classes to apply level-specific bonuses
    pass

func get_total_cost() -> int:
    var total = base_cost
    for i in range(level - 1):
        if i < upgrade_costs.size():
            total += upgrade_costs[i]
    return total

# Combat-related methods (for offensive modules)
func can_attack() -> bool:
    if not is_active:
        return false
    
    var current_time = Time.get_time_dict_from_system()
    var time_passed = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - last_action_time
    return time_passed >= (1.0 / attack_speed)

func find_targets_in_range() -> Array[Node]:
    # Override in derived classes
    return []

func attack_target(target: Node) -> void:
    if not can_attack():
        return
    
    last_action_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
    _execute_attack(target)
    target_acquired.emit(target)

func _execute_attack(target: Node) -> void:
    # Override in derived classes
    pass

# Utility methods
func show_range_indicator() -> void:
    if range_indicator and attack_range > 0:
        range_indicator.visible = true
        # Draw circle for range visualization
        _update_range_visual()

func hide_range_indicator() -> void:
    if range_indicator:
        range_indicator.visible = false

func _update_range_visual() -> void:
    # Override to customize range visualization
    pass

func get_info_text() -> String:
    var info = module_name + " (Level " + str(level) + ")\n"
    info += description + "\n"
    if damage > 0:
        info += "Damage: " + str(damage) + "\n"
    if attack_range > 0:
        info += "Range: " + str(attack_range) + "\n"
    if generation_rate > 0:
        info += "Generates: " + str(generation_rate) + " CPU every " + str(generation_interval) + "s\n"
    if can_upgrade():
        info += "Upgrade cost: " + str(get_upgrade_cost()) + " CPU"
    return info

func destroy() -> void:
    # Remove from economy if it's an income source
    if GameManager.economy_manager and generation_rate > 0:
        GameManager.economy_manager.remove_income_source(self)
    
    # Remove from grid
    if GameManager.lane_system and GameManager.lane_system.grid_system:
        GameManager.lane_system.grid_system.free_cell(grid_position)
    
    module_destroyed.emit()
    queue_free()

# Virtual methods to override
func _process_special_ability() -> void:
    # Override for special module abilities
    pass

func _on_enemy_in_range(enemy: Node) -> void:
    # Override for enemy detection logic
    pass

func _on_module_selected() -> void:
    show_range_indicator()

func _on_module_deselected() -> void:
    hide_range_indicator()