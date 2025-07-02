extends BaseModule
class_name Firewall

signal damage_blocked(amount: float)
signal damage_reflected(amount: float, target: Node)

var current_health: float
var max_health: float
var reflection_damage_percent: float = 0.0
var packet_resistance: float = 1.0  # 1.0 = normal damage, 0.5 = 50% resistance

var attack_timer: Timer
var current_target: Node = null
var targeting_priority: TargetingSystem.Priority = TargetingSystem.Priority.CLOSEST

func _setup_module() -> void:
    module_type = Constants.ModuleType.FIREWALL
    
    # Set up combat timer
    attack_timer = Timer.new()
    attack_timer.timeout.connect(_process_combat)
    attack_timer.wait_time = 1.0 / attack_speed if attack_speed > 0 else 1.0
    attack_timer.autostart = true
    add_child(attack_timer)

func _load_from_data(data: Dictionary) -> void:
    super._load_from_data(data)
    
    # Firewall-specific stats
    max_health = 100.0  # Default health
    current_health = max_health
    
    # Update attack timer
    if attack_speed > 0:
        attack_timer.wait_time = 1.0 / attack_speed

func _process_combat() -> void:
    if not is_active:
        return
    
    var targets = find_targets_in_range()
    if targets.size() > 0:
        current_target = _select_best_target(targets)
        if current_target:
            attack_target(current_target)

func find_targets_in_range() -> Array[Node]:
    return super.find_targets_in_range()

func _select_best_target(targets: Array[Node]) -> Node:
    return TargetingSystem.select_target(targets, targeting_priority, global_position)

func _execute_attack(target: Node) -> void:
    if not target or not is_instance_valid(target):
        return
    
    # Calculate final damage
    var damage_amount = damage
    
    # Level bonuses
    if level >= 2:
        damage_amount *= 1.5  # 50% more damage at level 2
    
    # Create projectile
    var projectile = BaseProjectile.create_bullet(self, target, damage_amount, 400.0)
    projectile.damage_type = Constants.DamageType.PACKET
    
    # Add projectile to scene
    get_tree().current_scene.get_node("GameLayer").add_child(projectile)
    projectile.global_position = global_position + Vector2(Constants.CELL_SIZE / 2, Constants.CELL_SIZE / 2)
    
    # Muzzle flash effect
    _show_muzzle_flash()
    
    print(module_name, " fired projectile at ", target.name if target.name else "enemy")

func _show_muzzle_flash() -> void:
    if not effects:
        return
    
    # Create muzzle flash effect
    var flash = ColorRect.new()
    flash.color = Constants.COLOR_NEON_GREEN
    flash.size = Vector2(16, 16)
    flash.position = Vector2(Constants.CELL_SIZE / 2 - 8, Constants.CELL_SIZE / 2 - 8)
    effects.add_child(flash)
    
    # Animate flash
    var tween = create_tween()
    tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.1)
    tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.1)
    tween.tween_callback(flash.queue_free)

func take_damage(amount: float, damage_type: Constants.DamageType) -> void:
    if not is_active:
        return
    
    var final_damage = amount
    
    # Packet resistance
    if damage_type == Constants.DamageType.PACKET:
        final_damage *= packet_resistance
        damage_blocked.emit(amount - final_damage)
    
    current_health -= final_damage
    
    # Level 3 special: Damage reflection
    if level >= 3 and reflection_damage_percent > 0:
        var reflected = amount * reflection_damage_percent
        # Find attacker and reflect damage (would need enemy reference)
        damage_reflected.emit(reflected, null)
    
    # Visual feedback
    _show_damage_effect(final_damage)
    
    if current_health <= 0:
        destroy()
    
    print(module_name, " took ", final_damage, " damage. Health: ", current_health, "/", max_health)

func _show_damage_effect(damage_amount: float) -> void:
    # Screen shake or damage indicator
    if sprite:
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color.RED, 0.1)
        tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _apply_upgrade() -> void:
    match level:
        2:
            # Level 2: +100% health, +50% damage, target strongest
            max_health *= 2.0
            current_health = max_health
            damage *= 1.5
            packet_resistance = 0.75  # 25% packet resistance
            targeting_priority = TargetingSystem.Priority.STRONGEST
            print(module_name, " Level 2: Enhanced defense and damage, targets strongest enemies")
            
        3:
            # Level 3: Damage reflection, target farthest
            reflection_damage_percent = 0.25  # Reflect 25% of damage
            packet_resistance = 0.5  # 50% packet resistance
            targeting_priority = TargetingSystem.Priority.FARTHEST
            print(module_name, " Level 3: Damage reflection activated, targets enemies closest to end!")

func show_range_indicator() -> void:
    super.show_range_indicator()
    
    if range_indicator and attack_range > 0:
        range_indicator.visible = true
        # Draw attack range circle

func get_info_text() -> String:
    var info = super.get_info_text()
    
    info += "\nHealth: " + str(int(current_health)) + "/" + str(int(max_health))
    
    if packet_resistance < 1.0:
        var resistance_percent = int((1.0 - packet_resistance) * 100)
        info += "\nPacket Resistance: " + str(resistance_percent) + "%"
    
    if reflection_damage_percent > 0:
        var reflection_percent = int(reflection_damage_percent * 100)
        info += "\nDamage Reflection: " + str(reflection_percent) + "%"
    
    if current_target:
        info += "\nTargeting: Enemy"
    
    return info

func heal(amount: float) -> void:
    current_health = min(current_health + amount, max_health)
    print(module_name, " healed for ", amount, ". Health: ", current_health, "/", max_health)