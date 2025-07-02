extends CharacterBody2D
class_name BaseEnemy

signal enemy_destroyed(enemy: BaseEnemy, reward: int)
signal reached_target(enemy: BaseEnemy)
signal health_changed(current: float, max: float)
signal status_effect_applied(effect: String)

# Enemy identification
var enemy_type: Constants.EnemyType
var enemy_name: String
var description: String
var tier: int = 1

# Health system
var max_health: float = 50.0
var current_health: float = 50.0
var is_alive: bool = true

# Movement system
var base_movement_speed: float = 100.0
var current_movement_speed: float = 100.0
var speed_multiplier: float = 1.0

# Combat system
var damage_type: Constants.DamageType = Constants.DamageType.PACKET
var damage_amount: float = 10.0
var vulnerabilities: Array[Constants.DamageType] = []
var resistances: Array[Constants.DamageType] = []

# Reward system
var reward_cpu: int = 10
var reward_research: int = 0

# Pathfinding
var lane_id: int = 0
var path_points: Array[Vector2] = []
var current_path_index: int = 0
var target_position: Vector2
var has_reached_end: bool = false

# Status effects
var active_effects: Dictionary = {}
var is_slowed: bool = false
var is_stunned: bool = false
var priority_target: Node = null

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var effects_container: Node2D = $Effects
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    _setup_enemy()
    _setup_visuals()
    _setup_physics()

func _setup_enemy() -> void:
    # Override in derived classes
    pass

func _setup_visuals() -> void:
    # Set up health bar
    if health_bar:
        health_bar.min_value = 0
        health_bar.max_value = max_health
        health_bar.value = current_health
        health_bar.visible = false  # Show only when damaged
    
    # Set up sprite
    if sprite:
        sprite.position = Vector2(16, 16)  # Center in 32x32 cell

func _setup_physics() -> void:
    # Set up collision
    if not collision_shape:
        collision_shape = CollisionShape2D.new()
        add_child(collision_shape)
        
        var shape = RectangleShape2D.new()
        shape.size = Vector2(24, 24)
        collision_shape.shape = shape
    
    # Set collision layers
    collision_layer = Constants.LAYER_ENEMIES
    collision_mask = Constants.LAYER_MODULES | Constants.LAYER_PROJECTILES

func initialize(lane: int, path: Array[Vector2], enemy_data: Dictionary) -> void:
    lane_id = lane
    path_points = path.duplicate()
    current_path_index = 0
    
    if path_points.size() > 0:
        target_position = path_points[0]
        global_position = target_position
        if path_points.size() > 1:
            target_position = path_points[1]
            current_path_index = 1
    
    _load_from_data(enemy_data)
    _register_with_systems()
    
    print("Enemy initialized: ", enemy_name, " on lane ", lane_id)

func _load_from_data(data: Dictionary) -> void:
    if data.has("name"):
        enemy_name = data.name
    if data.has("health"):
        max_health = data.health
        current_health = max_health
    if data.has("speed"):
        base_movement_speed = data.speed
        current_movement_speed = data.speed
    if data.has("damage_type"):
        damage_type = data.damage_type
    if data.has("damage"):
        damage_amount = data.damage
    if data.has("reward_cpu"):
        reward_cpu = data.reward_cpu
    if data.has("vulnerabilities"):
        vulnerabilities = data.vulnerabilities
    if data.has("resistances"):
        resistances = data.resistances

func _register_with_systems() -> void:
    # Register with lane system
    if GameManager.lane_system:
        GameManager.lane_system.register_enemy(lane_id, self)

func _physics_process(delta: float) -> void:
    if not is_alive or is_stunned:
        return
    
    _update_movement(delta)
    _update_status_effects(delta)

func _update_movement(delta: float) -> void:
    if has_reached_end:
        return
    
    # Check for priority target (from Honeypot)
    if priority_target and is_instance_valid(priority_target):
        target_position = priority_target.global_position
    elif current_path_index < path_points.size():
        target_position = path_points[current_path_index]
    else:
        _reach_end()
        return
    
    # Move towards target
    var direction = (target_position - global_position).normalized()
    var effective_speed = current_movement_speed * speed_multiplier
    
    velocity = direction * effective_speed
    move_and_slide()
    
    # Check if reached current waypoint
    if global_position.distance_to(target_position) < 5.0:
        if priority_target:
            # Reached priority target (Honeypot)
            _attack_target(priority_target)
        else:
            # Reached waypoint, move to next
            current_path_index += 1
            if current_path_index >= path_points.size():
                _reach_end()

func _attack_target(target: Node) -> void:
    if target.has_method("take_damage"):
        target.take_damage(damage_amount, damage_type)
        print(enemy_name, " attacked ", target.name if target.name else "target")

func _reach_end() -> void:
    has_reached_end = true
    reached_target.emit(self)
    
    # Damage player
    GameManager.trigger_game_over(false)  # For now, any enemy reaching end = game over
    
    print(enemy_name, " reached the end!")
    destroy()

func take_damage(amount: float, damage_type: Constants.DamageType, attacker: Node = null) -> void:
    if not is_alive:
        return
    
    var final_damage = CombatSystem.calculate_damage(amount, damage_type, attacker, self)
    current_health = max(0, current_health - final_damage)
    
    # Show health bar when damaged
    if health_bar:
        health_bar.value = current_health
        health_bar.visible = true
    
    # Visual feedback
    _show_damage_effect(final_damage)
    
    # Combat log
    CombatSystem.log_combat_event(attacker, self, final_damage, damage_type)
    
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        _die()

func _show_damage_effect(damage_amount: float) -> void:
    # Flash red
    if sprite:
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color.RED, 0.1)
        tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
    
    # Floating damage text
    _create_floating_text(str(int(damage_amount)), Color.WHITE)

func _create_floating_text(text: String, color: Color) -> void:
    if not effects_container:
        return
    
    var label = Label.new()
    label.text = text
    label.add_theme_color_override("font_color", color)
    label.position = Vector2(0, -20)
    effects_container.add_child(label)
    
    var tween = create_tween()
    tween.tween_property(label, "position", label.position + Vector2(0, -30), 1.0)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
    tween.tween_callback(label.queue_free)

func _die() -> void:
    is_alive = false
    
    # Drop rewards
    GameManager.add_cpu(reward_cpu)
    if reward_research > 0:
        GameManager.add_research_tokens(reward_research)
    
    # Visual death effect
    _show_death_effect()
    
    # Emit signal
    enemy_destroyed.emit(self, reward_cpu)
    
    print(enemy_name, " destroyed! Reward: ", reward_cpu, " CPU")
    
    # Clean up after short delay for death effect
    await get_tree().create_timer(0.5).timeout
    destroy()

func _show_death_effect() -> void:
    if sprite:
        var tween = create_tween()
        tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
        tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)

func destroy() -> void:
    # Unregister from systems
    if GameManager.lane_system:
        GameManager.lane_system.unregister_enemy(lane_id, self)
    
    # Remove status effects
    _clear_all_effects()
    
    queue_free()

# Status effect system
func apply_slow(slow_amount: float) -> void:
    is_slowed = true
    speed_multiplier = 1.0 - slow_amount
    active_effects["slow"] = slow_amount
    status_effect_applied.emit("slow")
    
    _show_status_effect("SLOW", Color.BLUE)

func remove_slow() -> void:
    is_slowed = false
    speed_multiplier = 1.0
    active_effects.erase("slow")

func apply_stun(duration: float) -> void:
    is_stunned = true
    active_effects["stun"] = duration
    status_effect_applied.emit("stun")
    
    _show_status_effect("STUN", Color.YELLOW)
    
    # Auto-remove after duration
    await get_tree().create_timer(duration).timeout
    remove_stun()

func remove_stun() -> void:
    is_stunned = false
    active_effects.erase("stun")

func set_priority_target(target: Node) -> void:
    priority_target = target
    print(enemy_name, " now targeting priority: ", target.name if target.name else "target")

func clear_priority_target() -> void:
    priority_target = null

func _show_status_effect(effect_name: String, color: Color) -> void:
    _create_floating_text(effect_name, color)

func _update_status_effects(delta: float) -> void:
    # Update timed effects (like stun duration)
    for effect in active_effects.keys():
        if effect == "stun":
            active_effects[effect] -= delta
            if active_effects[effect] <= 0:
                remove_stun()

func _clear_all_effects() -> void:
    active_effects.clear()
    is_slowed = false
    is_stunned = false
    speed_multiplier = 1.0

# Utility methods
func get_enemy_type() -> Constants.EnemyType:
    return enemy_type

func get_health_percentage() -> float:
    return current_health / max_health

func is_at_full_health() -> bool:
    return current_health >= max_health

func get_distance_to_end() -> float:
    if path_points.size() == 0:
        return 0.0
    
    var distance = global_position.distance_to(path_points[-1])
    
    # Add remaining path segments
    for i in range(current_path_index, path_points.size() - 1):
        distance += path_points[i].distance_to(path_points[i + 1])
    
    return distance