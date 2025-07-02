extends BaseModule
class_name Honeypot

signal enemy_lured(enemy: Node)
signal honeypot_exploded(damage: float)

var current_health: float
var max_health: float = 200.0
var explosion_damage: float = 50.0
var lure_range: float = 96.0
var respawn_timer: Timer = null
var can_respawn: bool = false
var respawn_delay: float = 10.0

var lure_effect_timer: Timer

func _setup_module() -> void:
    module_type = Constants.ModuleType.HONEYPOT
    current_health = max_health
    
    # Set up lure effect timer
    lure_effect_timer = Timer.new()
    lure_effect_timer.timeout.connect(_process_lure_effect)
    lure_effect_timer.wait_time = 1.0  # Check for enemies every second
    lure_effect_timer.autostart = true
    add_child(lure_effect_timer)

func _load_from_data(data: Dictionary) -> void:
    super._load_from_data(data)
    
    if data.has("health"):
        max_health = data.health
        current_health = max_health
    if data.has("explosion_damage"):
        explosion_damage = data.explosion_damage
    if data.has("lure_range"):
        lure_range = data.lure_range

func _process_lure_effect() -> void:
    if not is_active:
        return
    
    var enemies_in_range = find_enemies_in_lure_range()
    for enemy in enemies_in_range:
        _lure_enemy(enemy)

func find_enemies_in_lure_range() -> Array[Node]:
    var enemies: Array[Node] = []
    
    var enemy_container = get_tree().current_scene.get_node_or_null("GameLayer/EnemyContainer")
    if not enemy_container:
        return enemies
    
    for enemy in enemy_container.get_children():
        if is_instance_valid(enemy):
            var distance = global_position.distance_to(enemy.global_position)
            if distance <= lure_range:
                enemies.append(enemy)
    
    return enemies

func _lure_enemy(enemy: Node) -> void:
    # Set honeypot as priority target for the enemy
    if enemy.has_method("set_priority_target"):
        enemy.set_priority_target(self)
        enemy_lured.emit(enemy)
    elif enemy.has_method("change_target"):
        enemy.change_target(global_position)
        enemy_lured.emit(enemy)

func take_damage(amount: float, damage_type: Constants.DamageType) -> void:
    if not is_active:
        return
    
    current_health -= amount
    
    # Visual feedback
    _show_damage_effect(amount)
    
    print(module_name, " took ", amount, " damage. Health: ", current_health, "/", max_health)
    
    if current_health <= 0:
        _explode()

func _show_damage_effect(damage_amount: float) -> void:
    if sprite:
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color.RED, 0.1)
        tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _explode() -> void:
    print(module_name, " exploded!")
    
    # Find enemies in explosion range and damage them
    var enemies_in_explosion = find_enemies_in_explosion_range()
    for enemy in enemies_in_explosion:
        if enemy.has_method("take_damage"):
            enemy.take_damage(explosion_damage, Constants.DamageType.PAYLOAD)
    
    # Visual explosion effect
    _show_explosion_effect()
    
    honeypot_exploded.emit(explosion_damage)
    
    # Handle respawn for level 3
    if can_respawn and level >= 3:
        _start_respawn()
    else:
        destroy()

func find_enemies_in_explosion_range() -> Array[Node]:
    var enemies: Array[Node] = []
    var explosion_range = 64.0  # Explosion range
    
    if level >= 2:
        explosion_range = 96.0  # Bigger explosion at level 2+
    
    var enemy_container = get_tree().current_scene.get_node_or_null("GameLayer/EnemyContainer")
    if not enemy_container:
        return enemies
    
    for enemy in enemy_container.get_children():
        if is_instance_valid(enemy):
            var distance = global_position.distance_to(enemy.global_position)
            if distance <= explosion_range:
                enemies.append(enemy)
    
    return enemies

func _show_explosion_effect() -> void:
    if not effects:
        return
    
    # Create explosion visual
    var explosion_circle = ColorRect.new()
    explosion_circle.color = Constants.COLOR_NEON_PINK
    explosion_circle.size = Vector2(128, 128)
    explosion_circle.position = Vector2(-64, -64)  # Center the explosion
    effects.add_child(explosion_circle)
    
    # Animate explosion
    var tween = create_tween()
    tween.tween_property(explosion_circle, "scale", Vector2(2.0, 2.0), 0.3)
    tween.parallel().tween_property(explosion_circle, "modulate:a", 0.0, 0.3)
    tween.tween_callback(explosion_circle.queue_free)

func _start_respawn() -> void:
    is_active = false
    visible = false
    
    if not respawn_timer:
        respawn_timer = Timer.new()
        respawn_timer.timeout.connect(_respawn)
        respawn_timer.one_shot = true
        add_child(respawn_timer)
    
    respawn_timer.wait_time = respawn_delay
    respawn_timer.start()
    
    print(module_name, " will respawn in ", respawn_delay, " seconds")

func _respawn() -> void:
    current_health = max_health
    is_active = true
    visible = true
    
    # Visual respawn effect
    _show_respawn_effect()
    
    print(module_name, " respawned!")

func _show_respawn_effect() -> void:
    if sprite:
        sprite.modulate.a = 0.0
        var tween = create_tween()
        tween.tween_property(sprite, "modulate:a", 1.0, 0.5)

func _apply_upgrade() -> void:
    match level:
        2:
            # Level 2: +100% health, bigger explosion
            max_health *= 2.0
            current_health = max_health
            explosion_damage *= 1.5
            print(module_name, " Level 2: Enhanced durability and explosion")
            
        3:
            # Level 3: Auto-respawn
            can_respawn = true
            respawn_delay = 10.0
            print(module_name, " Level 3: Auto-respawn enabled!")

func show_range_indicator() -> void:
    super.show_range_indicator()
    
    if range_indicator:
        range_indicator.visible = true
        # Show lure range

func get_info_text() -> String:
    var info = super.get_info_text()
    
    info += "\nHealth: " + str(int(current_health)) + "/" + str(int(max_health))
    info += "\nExplosion Damage: " + str(int(explosion_damage))
    info += "\nLure Range: " + str(int(lure_range))
    
    if can_respawn:
        info += "\nSpecial: Auto-respawn (" + str(respawn_delay) + "s)"
    
    if respawn_timer and respawn_timer.time_left > 0:
        info += "\nRespawning in: " + str(int(respawn_timer.time_left)) + "s"
    
    return info