extends Node
class_name ModuleManager

signal module_placed(module: BaseModule, grid_pos: Vector2)
signal module_removed(grid_pos: Vector2)
signal module_selected(module: BaseModule)
signal placement_failed(reason: String)

var active_modules: Dictionary = {}  # grid_pos -> BaseModule
var selected_module_type: Constants.ModuleType = Constants.ModuleType.POWER_NODE
var placement_mode: bool = false
var selected_module: BaseModule = null

# Module data loaded from JSON
var module_data: Dictionary = {}

# References to other systems
var grid_system: GridSystem
var economy_manager: EconomyManager

func _ready() -> void:
    _load_module_data()
    print("ModuleManager initialized")

func initialize(grid_sys: GridSystem, econ_manager: EconomyManager) -> void:
    grid_system = grid_sys
    economy_manager = econ_manager
    
    # Connect to grid signals
    if grid_system:
        grid_system.cell_clicked.connect(_on_grid_cell_clicked)
        grid_system.cell_hovered.connect(_on_grid_cell_hovered)

func _load_module_data() -> void:
    # For now, hardcoded data - will be replaced with JSON loader
    module_data = {
        Constants.ModuleType.POWER_NODE: {
            "name": "Power Node",
            "description": "Generates CPU cycles over time",
            "base_cost": 50,
            "upgrade_costs": [100, 200],
            "generation_rate": 25,
            "generation_interval": 5.0,
            "sprite_path": "res://assets/art/modules/power_node.png"
        },
        Constants.ModuleType.FIREWALL: {
            "name": "Firewall",
            "description": "Blocks packet-based attacks",
            "base_cost": 100,
            "upgrade_costs": [150, 300],
            "damage": 10,
            "attack_speed": 1.0,
            "range": 128,
            "damage_types": [Constants.DamageType.PACKET],
            "sprite_path": "res://assets/art/modules/firewall.png"
        },
        Constants.ModuleType.HONEYPOT: {
            "name": "Honeypot",
            "description": "Lures enemies and explodes when destroyed",
            "base_cost": 75,
            "upgrade_costs": [125, 250],
            "health": 200,
            "explosion_damage": 50,
            "lure_range": 96,
            "sprite_path": "res://assets/art/modules/honeypot.png"
        },
        Constants.ModuleType.IDS: {
            "name": "IDS",
            "description": "Detects threats and slows enemies",
            "base_cost": 150,
            "upgrade_costs": [200, 400],
            "slow_effect": 0.5,
            "detection_range": 96,
            "sprite_path": "res://assets/art/modules/ids.png"
        }
    }

func start_placement_mode(module_type: Constants.ModuleType) -> void:
    if not can_afford_module(module_type):
        placement_failed.emit("Insufficient CPU!")
        return
    
    selected_module_type = module_type
    placement_mode = true
    print("Started placement mode for: ", _get_module_name(module_type))

func cancel_placement_mode() -> void:
    placement_mode = false
    selected_module_type = Constants.ModuleType.POWER_NODE
    print("Cancelled placement mode")

func can_afford_module(module_type: Constants.ModuleType) -> bool:
    if not module_data.has(module_type):
        return false
    
    var cost = module_data[module_type].base_cost
    return economy_manager.can_afford(cost)

func can_place_at(grid_pos: Vector2) -> bool:
    if not grid_system.is_valid_grid_position(grid_pos):
        return false
    
    if not grid_system.is_cell_empty(grid_pos):
        return false
    
    # Additional placement rules can be added here
    # e.g., some modules only on certain lanes, etc.
    
    return true

func _on_grid_cell_clicked(grid_pos: Vector2) -> void:
    if placement_mode:
        _attempt_placement(grid_pos)
    else:
        _select_module_at(grid_pos)

func _attempt_placement(grid_pos: Vector2) -> void:
    if not can_place_at(grid_pos):
        placement_failed.emit("Cannot place module here!")
        return
    
    if not can_afford_module(selected_module_type):
        placement_failed.emit("Insufficient CPU!")
        return
    
    # Create the module
    var module = _create_module(selected_module_type, grid_pos)
    if module:
        # Pay the cost
        var cost = module_data[selected_module_type].base_cost
        if economy_manager.spend_cpu(cost):
            _place_module(module, grid_pos)
            cancel_placement_mode()
        else:
            module.queue_free()
            placement_failed.emit("Payment failed!")

func _create_module(module_type: Constants.ModuleType, grid_pos: Vector2) -> BaseModule:
    var module: BaseModule = null
    var data = module_data[module_type]
    
    match module_type:
        Constants.ModuleType.POWER_NODE:
            module = preload("res://domain/modules/power_node.gd").new()
        Constants.ModuleType.FIREWALL:
            module = preload("res://domain/modules/firewall.gd").new()
        Constants.ModuleType.HONEYPOT:
            module = preload("res://domain/modules/honeypot.gd").new()
        Constants.ModuleType.IDS:
            module = preload("res://domain/modules/ids.gd").new()
    
    if module:
        module.module_type = module_type
        module.initialize(grid_pos, data)
        _setup_module_visuals(module)
    
    return module

func _setup_module_visuals(module: BaseModule) -> void:
    # Add sprite if doesn't exist
    if not module.get_node_or_null("Sprite2D"):
        var sprite = Sprite2D.new()
        sprite.name = "Sprite2D"
        module.add_child(sprite)
        
        # Create a placeholder colored rectangle for now
        var color = _get_module_color(module.module_type)
        var texture = ImageTexture.new()
        var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
        image.fill(color)
        texture.set_image(image)
        sprite.texture = texture
        sprite.position = Vector2(Constants.CELL_SIZE / 2, Constants.CELL_SIZE / 2)

func _get_module_color(module_type: Constants.ModuleType) -> Color:
    match module_type:
        Constants.ModuleType.POWER_NODE:
            return Constants.COLOR_NEON_BLUE
        Constants.ModuleType.FIREWALL:
            return Constants.COLOR_NEON_GREEN
        Constants.ModuleType.HONEYPOT:
            return Constants.COLOR_NEON_PINK
        Constants.ModuleType.IDS:
            return Color.YELLOW
        _:
            return Color.WHITE

func _place_module(module: BaseModule, grid_pos: Vector2) -> void:
    # Add to scene
    get_tree().current_scene.get_node("GameLayer/ModuleContainer").add_child(module)
    
    # Register with grid
    grid_system.occupy_cell(grid_pos, module)
    
    # Register with manager
    active_modules[grid_pos] = module
    
    # Connect module signals
    module.module_destroyed.connect(_on_module_destroyed.bind(grid_pos))
    module.module_upgraded.connect(_on_module_upgraded.bind(module))
    
    # Special handling for Power Nodes (add to economy)
    if module.module_type == Constants.ModuleType.POWER_NODE:
        economy_manager.add_income_source(module, module.generation_rate, module.generation_interval)
    
    module_placed.emit(module, grid_pos)
    print("Placed ", module.module_name, " at ", grid_pos)

func _select_module_at(grid_pos: Vector2) -> void:
    if active_modules.has(grid_pos):
        if selected_module:
            selected_module._on_module_deselected()
        
        selected_module = active_modules[grid_pos]
        selected_module._on_module_selected()
        module_selected.emit(selected_module)
        print("Selected module: ", selected_module.module_name)
    else:
        if selected_module:
            selected_module._on_module_deselected()
            selected_module = null

func _on_grid_cell_hovered(grid_pos: Vector2) -> void:
    # Visual feedback for placement mode
    if placement_mode:
        # Could add hover preview here
        pass

func _on_module_destroyed(grid_pos: Vector2) -> void:
    if active_modules.has(grid_pos):
        active_modules.erase(grid_pos)
        module_removed.emit(grid_pos)

func _on_module_upgraded(module: BaseModule) -> void:
    # Handle module upgrade effects
    if module.module_type == Constants.ModuleType.POWER_NODE:
        # Update income source
        economy_manager.remove_income_source(module)
        economy_manager.add_income_source(module, module.generation_rate, module.generation_interval)

func remove_module_at(grid_pos: Vector2) -> bool:
    if active_modules.has(grid_pos):
        var module = active_modules[grid_pos]
        module.destroy()
        return true
    return false

func get_module_at(grid_pos: Vector2) -> BaseModule:
    return active_modules.get(grid_pos, null)

func get_all_modules() -> Array[BaseModule]:
    var modules: Array[BaseModule] = []
    for module in active_modules.values():
        modules.append(module)
    return modules

func get_modules_of_type(module_type: Constants.ModuleType) -> Array[BaseModule]:
    var modules: Array[BaseModule] = []
    for module in active_modules.values():
        if module.module_type == module_type:
            modules.append(module)
    return modules

func _get_module_name(module_type: Constants.ModuleType) -> String:
    if module_data.has(module_type):
        return module_data[module_type].name
    return "Unknown Module"

func get_module_cost(module_type: Constants.ModuleType) -> int:
    if module_data.has(module_type):
        return module_data[module_type].base_cost
    return 0