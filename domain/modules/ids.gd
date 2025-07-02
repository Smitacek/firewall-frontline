extends BaseModule
class_name IDS

signal threat_detected(enemy: Node)
signal enemy_analyzed(enemy: Node)

var detection_range: float = 96.0
var slow_effect: float = 0.5  # 50% speed reduction
var analysis_time: float = 3.0
var instant_kill_chance: float = 0.0

var detection_timer: Timer
var detected_enemies: Dictionary = {}  # enemy -> detection_time
var slowed_enemies: Array[Node] = []

func _setup_module() -> void:
    module_type = Constants.ModuleType.IDS
    
    # Set up detection timer
    detection_timer = Timer.new()
    detection_timer.timeout.connect(_process_detection)
    detection_timer.wait_time = 0.5  # Check twice per second
    detection_timer.autostart = true
    add_child(detection_timer)

func _load_from_data(data: Dictionary) -> void:
    super._load_from_data(data)
    
    if data.has("detection_range"):
        detection_range = data.detection_range
    if data.has("slow_effect"):
        slow_effect = data.slow_effect

func _process_detection() -> void:
    if not is_active:
        return
    
    var enemies_in_range = find_enemies_in_detection_range()
    
    # Process currently detected enemies
    for enemy in enemies_in_range:
        if not detected_enemies.has(enemy):
            _detect_enemy(enemy)
        else:
            _update_enemy_analysis(enemy)
    
    # Clean up enemies that left range
    _cleanup_out_of_range_enemies(enemies_in_range)

func find_enemies_in_detection_range() -> Array[Node]:
    if not GameManager.enemy_manager:
        return []
    
    var enemies: Array[Node] = []
    var nearby_enemies = GameManager.enemy_manager.get_enemies_in_range(global_position, detection_range)
    
    for enemy in nearby_enemies:
        enemies.append(enemy)
    
    return enemies

func _detect_enemy(enemy: Node) -> void:
    detected_enemies[enemy] = Time.get_time_dict_from_system()
    threat_detected.emit(enemy)
    
    # Apply slow effect
    _apply_slow_effect(enemy)
    
    # Visual detection effect
    _show_detection_effect(enemy)
    
    print(module_name, " detected threat: ", enemy.name if enemy.has_method("get") else "Enemy")

func _apply_slow_effect(enemy: Node) -> void:
    if enemy in slowed_enemies:
        return
    
    if enemy.has_method("apply_slow"):
        enemy.apply_slow(slow_effect)
        slowed_enemies.append(enemy)
    elif enemy.has_method("set_speed_multiplier"):
        enemy.set_speed_multiplier(1.0 - slow_effect)
        slowed_enemies.append(enemy)

func _remove_slow_effect(enemy: Node) -> void:
    if enemy not in slowed_enemies:
        return
    
    if enemy.has_method("remove_slow"):
        enemy.remove_slow()
    elif enemy.has_method("set_speed_multiplier"):
        enemy.set_speed_multiplier(1.0)
    
    slowed_enemies.erase(enemy)

func _update_enemy_analysis(enemy: Node) -> void:
    if not detected_enemies.has(enemy):
        return
    
    var detection_start = detected_enemies[enemy]
    var current_time = Time.get_time_dict_from_system()
    var elapsed = _calculate_time_difference(current_time, detection_start)
    
    if elapsed >= analysis_time:
        _complete_analysis(enemy)

func _calculate_time_difference(current: Dictionary, start: Dictionary) -> float:
    var current_seconds = current.hour * 3600 + current.minute * 60 + current.second
    var start_seconds = start.hour * 3600 + start.minute * 60 + start.second
    return current_seconds - start_seconds

func _complete_analysis(enemy: Node) -> void:
    enemy_analyzed.emit(enemy)
    
    # Level 3 special: Instant kill chance for Script Kiddies
    if level >= 3 and instant_kill_chance > 0:
        if enemy.has_method("get_enemy_type") and enemy.get_enemy_type() == Constants.EnemyType.SCRIPT_KIDDIE:
            if randf() < instant_kill_chance:
                _instant_kill_enemy(enemy)
                return
    
    # Enhanced slow effect after analysis
    if level >= 2:
        _apply_enhanced_slow(enemy)
    
    print(module_name, " completed analysis of threat")

func _instant_kill_enemy(enemy: Node) -> void:
    if enemy.has_method("take_damage"):
        enemy.take_damage(9999, Constants.DamageType.PACKET)  # Massive damage for instant kill
    
    _show_instant_kill_effect(enemy)
    print(module_name, " executed instant kill on Script Kiddie!")

func _apply_enhanced_slow(enemy: Node) -> void:
    # Level 2+: Even stronger slow effect
    var enhanced_slow = min(slow_effect * 1.5, 0.8)  # Max 80% slow
    
    if enemy.has_method("apply_slow"):
        enemy.apply_slow(enhanced_slow)
    elif enemy.has_method("set_speed_multiplier"):
        enemy.set_speed_multiplier(1.0 - enhanced_slow)

func _show_detection_effect(enemy: Node) -> void:
    if not effects:
        return
    
    # Create scan line effect to enemy
    var line = Line2D.new()
    line.add_point(Vector2(Constants.CELL_SIZE / 2, Constants.CELL_SIZE / 2))
    line.add_point(to_local(enemy.global_position) + Vector2(Constants.CELL_SIZE / 2, Constants.CELL_SIZE / 2))
    line.default_color = Color.YELLOW
    line.width = 2.0
    effects.add_child(line)
    
    # Animate scan effect
    var tween = create_tween()
    tween.tween_property(line, "modulate:a", 0.3, 0.5)
    tween.tween_property(line, "modulate:a", 1.0, 0.5)
    tween.tween_callback(line.queue_free)

func _show_instant_kill_effect(enemy: Node) -> void:
    # Special effect for instant kill
    if not effects:
        return
    
    var kill_indicator = Label.new()
    kill_indicator.text = "ELIMINATED"
    kill_indicator.add_theme_color_override("font_color", Color.RED)
    kill_indicator.position = to_local(enemy.global_position)
    effects.add_child(kill_indicator)
    
    var tween = create_tween()
    tween.tween_property(kill_indicator, "position", kill_indicator.position + Vector2(0, -50), 1.0)
    tween.parallel().tween_property(kill_indicator, "modulate:a", 0.0, 1.0)
    tween.tween_callback(kill_indicator.queue_free)

func _cleanup_out_of_range_enemies(current_enemies: Array[Node]) -> void:
    var enemies_to_remove: Array[Node] = []
    
    for enemy in detected_enemies.keys():
        if not is_instance_valid(enemy) or enemy not in current_enemies:
            enemies_to_remove.append(enemy)
    
    for enemy in enemies_to_remove:
        detected_enemies.erase(enemy)
        _remove_slow_effect(enemy)

func _apply_upgrade() -> void:
    match level:
        2:
            # Level 2: +1 range, 75% slow effect
            detection_range += 32.0  # +1 grid cell
            slow_effect = 0.75
            print(module_name, " Level 2: Enhanced range and slow effect")
            
        3:
            # Level 3: Instant kill chance for Script Kiddies
            instant_kill_chance = 0.5  # 50% chance
            print(module_name, " Level 3: Instant elimination protocol activated!")

func show_range_indicator() -> void:
    super.show_range_indicator()
    
    if range_indicator:
        range_indicator.visible = true
        # Show detection range

func get_info_text() -> String:
    var info = super.get_info_text()
    
    info += "\nDetection Range: " + str(int(detection_range))
    info += "\nSlow Effect: " + str(int(slow_effect * 100)) + "%"
    
    if instant_kill_chance > 0:
        info += "\nInstant Kill Chance: " + str(int(instant_kill_chance * 100)) + "% (Script Kiddies)"
    
    info += "\nThreats Detected: " + str(detected_enemies.size())
    info += "\nEnemies Slowed: " + str(slowed_enemies.size())
    
    return info

func destroy() -> void:
    # Remove slow effects from all enemies
    for enemy in slowed_enemies:
        if is_instance_valid(enemy):
            _remove_slow_effect(enemy)
    
    detected_enemies.clear()
    slowed_enemies.clear()
    
    super.destroy()