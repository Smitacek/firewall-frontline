extends Node
class_name EnemyManager

signal enemy_spawned(enemy: BaseEnemy, lane_id: int)
signal enemy_destroyed(enemy: BaseEnemy)
signal all_enemies_defeated()
signal enemy_reached_end(enemy: BaseEnemy)

var active_enemies: Array[BaseEnemy] = []
var spawn_queue: Array[Dictionary] = []
var spawn_timer: Timer

# Enemy data
var enemy_data: Dictionary = {}

# Spawning control
var spawning_active: bool = false
var enemies_remaining_to_spawn: int = 0
var current_spawn_delay: float = 2.0

# References
var lane_system: LaneSystem
var enemy_container: Node2D

func _ready() -> void:
    _load_enemy_data()
    _setup_spawn_timer()
    print("EnemyManager initialized")

func initialize(lanes: LaneSystem, container: Node2D) -> void:
    lane_system = lanes
    enemy_container = container

func _load_enemy_data() -> void:
    # Hardcoded data for now - will be replaced with JSON loader
    enemy_data = {
        Constants.EnemyType.SCRIPT_KIDDIE: {
            "name": "Script Kiddie",
            "health": 50,
            "speed": 100,
            "damage_type": Constants.DamageType.PACKET,
            "damage": 5,
            "reward_cpu": 10,
            "vulnerabilities": [Constants.DamageType.PACKET],
            "resistances": [],
            "spawn_weight": 10
        }
    }

func _setup_spawn_timer() -> void:
    spawn_timer = Timer.new()
    spawn_timer.timeout.connect(_process_spawn_queue)
    spawn_timer.one_shot = false
    add_child(spawn_timer)

func start_spawning(spawn_data: Array[Dictionary]) -> void:
    spawning_active = true
    spawn_queue = spawn_data.duplicate()
    enemies_remaining_to_spawn = spawn_queue.size()
    
    if spawn_queue.size() > 0:
        current_spawn_delay = spawn_queue[0].get("spawn_delay", 2.0)
        spawn_timer.wait_time = current_spawn_delay
        spawn_timer.start()
    
    print("Started spawning ", enemies_remaining_to_spawn, " enemies")

func stop_spawning() -> void:
    spawning_active = false
    spawn_timer.stop()
    spawn_queue.clear()

func _process_spawn_queue() -> void:
    if not spawning_active or spawn_queue.is_empty():
        return
    
    var spawn_info = spawn_queue.pop_front()
    _spawn_enemy_from_data(spawn_info)
    
    enemies_remaining_to_spawn -= 1
    
    if spawn_queue.size() > 0:
        # Set timer for next spawn
        current_spawn_delay = spawn_queue[0].get("spawn_delay", 2.0)
        spawn_timer.wait_time = current_spawn_delay
    else:
        # No more enemies to spawn
        spawning_active = false
        spawn_timer.stop()
        print("All enemies spawned")

func _spawn_enemy_from_data(spawn_info: Dictionary) -> void:
    var enemy_type = spawn_info.get("enemy_type", Constants.EnemyType.SCRIPT_KIDDIE)
    var lane_id = spawn_info.get("lane", -1)
    
    # Select random lane if not specified
    if lane_id == -1:
        lane_id = randi() % Constants.LANE_COUNT
    
    spawn_enemy(enemy_type, lane_id)

func spawn_enemy(enemy_type: Constants.EnemyType, lane_id: int) -> BaseEnemy:
    if not lane_system or not enemy_container:
        print("Cannot spawn enemy - missing systems")
        return null
    
    # Get lane path
    var path = lane_system.get_path_for_lane(lane_id)
    if path.is_empty():
        print("Cannot spawn enemy - invalid lane ", lane_id)
        return null
    
    # Create enemy
    var enemy = _create_enemy(enemy_type)
    if not enemy:
        print("Failed to create enemy of type ", enemy_type)
        return null
    
    # Initialize enemy
    var data = enemy_data.get(enemy_type, {})
    enemy.initialize(lane_id, path, data)
    
    # Add to scene
    enemy_container.add_child(enemy)
    
    # Register enemy
    active_enemies.append(enemy)
    
    # Connect signals
    enemy.enemy_destroyed.connect(_on_enemy_destroyed)
    enemy.reached_target.connect(_on_enemy_reached_end)
    
    # Emit signal
    enemy_spawned.emit(enemy, lane_id)
    
    print("Spawned ", enemy.enemy_name, " on lane ", lane_id)
    return enemy

func _create_enemy(enemy_type: Constants.EnemyType) -> BaseEnemy:
    var enemy: BaseEnemy = null
    
    match enemy_type:
        Constants.EnemyType.SCRIPT_KIDDIE:
            enemy = ScriptKiddie.new()
    
    return enemy

func _on_enemy_destroyed(enemy: BaseEnemy, reward: int) -> void:
    active_enemies.erase(enemy)
    enemy_destroyed.emit(enemy)
    
    # Check if all enemies are defeated
    if active_enemies.is_empty() and not spawning_active:
        all_enemies_defeated.emit()
        print("All enemies defeated!")

func _on_enemy_reached_end(enemy: BaseEnemy) -> void:
    active_enemies.erase(enemy)
    enemy_reached_end.emit(enemy)
    
    # Game over logic handled in GameManager
    print("Enemy reached end: ", enemy.enemy_name)

func get_enemies_in_range(position: Vector2, range: float) -> Array[BaseEnemy]:
    var enemies_in_range: Array[BaseEnemy] = []
    
    for enemy in active_enemies:
        if is_instance_valid(enemy) and enemy.is_alive:
            var distance = position.distance_to(enemy.global_position)
            if distance <= range:
                enemies_in_range.append(enemy)
    
    return enemies_in_range

func get_closest_enemy_to(position: Vector2, max_range: float = -1) -> BaseEnemy:
    var closest_enemy: BaseEnemy = null
    var closest_distance: float = INF
    
    for enemy in active_enemies:
        if is_instance_valid(enemy) and enemy.is_alive:
            var distance = position.distance_to(enemy.global_position)
            if (max_range < 0 or distance <= max_range) and distance < closest_distance:
                closest_distance = distance
                closest_enemy = enemy
    
    return closest_enemy

func get_enemy_count() -> int:
    return active_enemies.size()

func get_enemies_on_lane(lane_id: int) -> Array[BaseEnemy]:
    var lane_enemies: Array[BaseEnemy] = []
    
    for enemy in active_enemies:
        if is_instance_valid(enemy) and enemy.lane_id == lane_id:
            lane_enemies.append(enemy)
    
    return lane_enemies

func clear_all_enemies() -> void:
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.destroy()
    
    active_enemies.clear()
    stop_spawning()

func pause_enemies() -> void:
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.set_physics_process(false)

func resume_enemies() -> void:
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.set_physics_process(true)

# Wave management integration
func spawn_wave(wave_data: Dictionary) -> void:
    var spawn_groups = wave_data.get("spawn_groups", [])
    var total_spawns: Array[Dictionary] = []
    
    var current_time = 0.0
    
    for group in spawn_groups:
        var enemy_type_str = group.get("enemy_type", "script_kiddie")
        var enemy_type = _string_to_enemy_type(enemy_type_str)
        var count = group.get("count", 1)
        var spawn_interval = group.get("spawn_interval", 2.0)
        var lane = group.get("lane", "random")
        
        for i in range(count):
            var spawn_info = {
                "enemy_type": enemy_type,
                "lane": -1 if lane == "random" else int(lane),
                "spawn_delay": current_time
            }
            total_spawns.append(spawn_info)
            current_time += spawn_interval
    
    # Sort by spawn time
    total_spawns.sort_custom(func(a, b): return a.spawn_delay < b.spawn_delay)
    
    # Convert absolute times to relative delays
    for i in range(total_spawns.size() - 1, 0, -1):
        total_spawns[i].spawn_delay -= total_spawns[i-1].spawn_delay
    
    start_spawning(total_spawns)

func _string_to_enemy_type(type_string: String) -> Constants.EnemyType:
    match type_string.to_lower():
        "script_kiddie":
            return Constants.EnemyType.SCRIPT_KIDDIE
        _:
            return Constants.EnemyType.SCRIPT_KIDDIE

func get_spawn_progress() -> float:
    if enemies_remaining_to_spawn <= 0:
        return 1.0
    
    var total_enemies = enemies_remaining_to_spawn + (spawn_queue.size() if spawn_queue else 0)
    if total_enemies <= 0:
        return 1.0
    
    return 1.0 - (float(enemies_remaining_to_spawn) / total_enemies)