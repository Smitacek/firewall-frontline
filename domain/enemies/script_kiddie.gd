extends BaseEnemy
class_name ScriptKiddie

var aggression_level: float = 1.0
var script_running: bool = false
var vulnerability_window: bool = false

func _setup_enemy() -> void:
    enemy_type = Constants.EnemyType.SCRIPT_KIDDIE
    enemy_name = "Script Kiddie"
    description = "Novice hacker using simple automated tools"
    tier = 1
    
    # Stats
    max_health = 50.0
    current_health = max_health
    base_movement_speed = 100.0
    current_movement_speed = base_movement_speed
    
    # Combat
    damage_type = Constants.DamageType.PACKET
    damage_amount = 5.0
    
    # Weaknesses and resistances
    vulnerabilities = [Constants.DamageType.PACKET]  # Vulnerable to Firewall
    resistances = []  # No resistances
    
    # Rewards
    reward_cpu = 10
    reward_research = 0
    
    print("Script Kiddie created with ", max_health, " HP")

func _setup_visuals() -> void:
    super._setup_visuals()
    
    # Create distinctive visual for Script Kiddie
    if not sprite:
        sprite = Sprite2D.new()
        add_child(sprite)
        sprite.position = Vector2(16, 16)
    
    # Create simple colored sprite for now
    var texture = ImageTexture.new()
    var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
    image.fill(Color.ORANGE)  # Orange for Script Kiddie
    texture.set_image(image)
    sprite.texture = texture

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    
    if is_alive:
        _update_script_behavior(delta)

func _update_script_behavior(delta: float) -> void:
    # Script Kiddie specific behavior - runs "scripts" periodically
    if not script_running and randf() < 0.01:  # 1% chance per frame to start script
        _start_script_execution()

func _start_script_execution() -> void:
    script_running = true
    vulnerability_window = true
    
    # Visual indication of script running
    _show_script_effect()
    
    # Slight speed boost while running script
    speed_multiplier *= 1.2
    
    print(enemy_name, " started running script!")
    
    # Script runs for 2 seconds, then vulnerability window
    await get_tree().create_timer(2.0).timeout
    
    if is_alive:
        _complete_script()

func _complete_script() -> void:
    script_running = false
    speed_multiplier /= 1.2  # Remove speed boost
    
    # Enter vulnerability window
    vulnerability_window = true
    
    # Visual indication of vulnerability
    _show_vulnerability_effect()
    
    print(enemy_name, " script completed - now vulnerable!")
    
    # Vulnerability lasts 1 second
    await get_tree().create_timer(1.0).timeout
    
    if is_alive:
        vulnerability_window = false

func _show_script_effect() -> void:
    if sprite:
        # Rapid blinking effect while running script
        var tween = create_tween()
        tween.set_loops(10)  # Blink 10 times
        tween.tween_property(sprite, "modulate", Color.GREEN, 0.1)
        tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _show_vulnerability_effect() -> void:
    if sprite:
        # Red tint during vulnerability
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color.RED, 0.2)
        tween.tween_property(sprite, "modulate", Color.WHITE, 0.8)

func take_damage(amount: float, damage_type: Constants.DamageType) -> void:
    var final_amount = amount
    
    # Double damage during vulnerability window
    if vulnerability_window:
        final_amount *= 2.0
        _create_floating_text("VULNERABLE!", Color.RED)
    
    # Script Kiddies are extra vulnerable to IDS detection
    if damage_type == Constants.DamageType.PACKET and vulnerability_window:
        final_amount *= 1.5  # Additional 50% damage
    
    super.take_damage(final_amount, damage_type)

func apply_slow(slow_amount: float) -> void:
    # Script Kiddies are extra susceptible to slow effects
    var enhanced_slow = min(slow_amount * 1.3, 0.9)  # 30% more effective, max 90%
    super.apply_slow(enhanced_slow)

func _die() -> void:
    # Script Kiddies have a chance to drop bonus CPU when killed during vulnerability
    if vulnerability_window:
        var bonus_cpu = reward_cpu
        GameManager.add_cpu(bonus_cpu)
        _create_floating_text("BONUS! +" + str(bonus_cpu), Constants.COLOR_NEON_GREEN)
        print(enemy_name, " killed during vulnerability - bonus reward!")
    
    super._die()

# Override movement for slightly erratic behavior
func _update_movement(delta: float) -> void:
    # Add slight random movement variation
    if script_running and randf() < 0.1:  # 10% chance for erratic movement
        var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
        target_position += random_offset
    
    super._update_movement(delta)

func get_info_text() -> String:
    var info = enemy_name + " (Tier " + str(tier) + ")\n"
    info += description + "\n"
    info += "Health: " + str(int(current_health)) + "/" + str(int(max_health)) + "\n"
    info += "Speed: " + str(int(current_movement_speed)) + "\n"
    info += "Damage Type: " + str(Constants.DamageType.keys()[damage_type]) + "\n"
    info += "Reward: " + str(reward_cpu) + " CPU\n"
    
    if script_running:
        info += "Status: Running Script\n"
    elif vulnerability_window:
        info += "Status: VULNERABLE\n"
    else:
        info += "Status: Normal\n"
    
    return info

# Special interaction with Honeypots
func set_priority_target(target: Node) -> void:
    super.set_priority_target(target)
    
    # Script Kiddies are easily distracted by honeypots
    if target and target.has_method("get") and target.module_type == Constants.ModuleType.HONEYPOT:
        # Increase movement speed towards honeypot
        speed_multiplier *= 1.5
        print(enemy_name, " is attracted to honeypot!")

func clear_priority_target() -> void:
    # Remove speed boost when no longer targeting honeypot
    if priority_target and priority_target.has_method("get"):
        speed_multiplier /= 1.5
    
    super.clear_priority_target()

# Special vulnerability to IDS systems
func _on_ids_detection() -> void:
    # IDS detection makes Script Kiddie panic and become more vulnerable
    vulnerability_window = true
    speed_multiplier *= 0.7  # 30% speed reduction from panic
    
    _create_floating_text("DETECTED!", Color.YELLOW)
    
    # Panic lasts 3 seconds
    await get_tree().create_timer(3.0).timeout
    
    if is_alive:
        vulnerability_window = false
        speed_multiplier /= 0.7  # Remove panic penalty