extends BaseModule
class_name PowerNode

signal cpu_generated(amount: int)

var generation_timer: Timer
var aoe_boost_active: bool = false
var boost_range: float = 96.0

func _setup_module() -> void:
    module_type = Constants.ModuleType.POWER_NODE
    
    # Set up generation timer
    generation_timer = Timer.new()
    generation_timer.timeout.connect(_generate_cpu)
    generation_timer.autostart = true
    add_child(generation_timer)

func _load_from_data(data: Dictionary) -> void:
    super._load_from_data(data)
    
    # Start generation timer
    if generation_interval > 0:
        generation_timer.wait_time = generation_interval
        generation_timer.start()

func _generate_cpu() -> void:
    if not is_active:
        return
    
    var amount = generation_rate
    
    # Level 3 special: AoE boost effect
    if level >= 3 and aoe_boost_active:
        amount = int(amount * 1.5)  # 50% bonus for AoE
    
    GameManager.add_cpu(amount)
    cpu_generated.emit(amount)
    
    # Visual effect
    _show_generation_effect(amount)
    
    print(module_name, " generated ", amount, " CPU")

func _show_generation_effect(amount: int) -> void:
    # Create floating text effect
    if effects:
        var label = Label.new()
        label.text = "+" + str(amount)
        label.add_theme_color_override("font_color", Constants.COLOR_NEON_GREEN)
        label.position = Vector2(Constants.CELL_SIZE / 2, 0)
        effects.add_child(label)
        
        # Animate the text
        var tween = create_tween()
        tween.tween_property(label, "position", label.position + Vector2(0, -30), 1.0)
        tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
        tween.tween_callback(label.queue_free)

func _apply_upgrade() -> void:
    match level:
        2:
            # Level 2: +60% generation rate
            generation_rate = int(generation_rate * 1.6)
            generation_timer.wait_time = generation_interval * 0.8  # 20% faster
            print(module_name, " Level 2: Increased generation to ", generation_rate)
            
        3:
            # Level 3: +100% generation rate + AoE boost
            generation_rate = int(generation_rate * 1.25)  # Additional 25% (total 2x from base)
            generation_timer.wait_time = generation_interval * 0.75  # Even faster
            aoe_boost_active = true
            _activate_aoe_boost()
            print(module_name, " Level 3: AoE boost activated!")

func _activate_aoe_boost() -> void:
    # Find nearby Power Nodes and boost them
    var nearby_modules = _find_nearby_power_nodes()
    for node in nearby_modules:
        if node != self and node.level < 3:  # Don't boost other level 3 nodes
            node._receive_aoe_boost()

func _find_nearby_power_nodes() -> Array[PowerNode]:
    var nearby: Array[PowerNode] = []
    
    # Get all modules from module manager
    var module_manager = get_tree().get_first_node_in_group("module_manager")
    if not module_manager:
        return nearby
    
    for module in module_manager.get_modules_of_type(Constants.ModuleType.POWER_NODE):
        if module != self:
            var distance = global_position.distance_to(module.global_position)
            if distance <= boost_range:
                nearby.append(module)
    
    return nearby

func _receive_aoe_boost() -> void:
    # Temporary boost from nearby Level 3 Power Node
    if generation_timer:
        generation_timer.wait_time = generation_interval * 0.9  # 10% faster when boosted

func show_range_indicator() -> void:
    super.show_range_indicator()
    
    if level >= 3 and range_indicator:
        # Show AoE boost range
        range_indicator.visible = true
        _update_range_visual()

func _update_range_visual() -> void:
    if not range_indicator:
        return
    
    # Clear previous drawings
    range_indicator.queue_redraw()
    
    if level >= 3:
        # Draw AoE boost range
        var circle_color = Constants.COLOR_NEON_BLUE
        circle_color.a = 0.3
        # This would need a custom _draw method in range_indicator

func get_info_text() -> String:
    var info = super.get_info_text()
    
    if level >= 3:
        info += "\nSpecial: AoE Boost - enhances nearby Power Nodes"
    
    info += "\nNext generation: " + str(int(generation_timer.time_left)) + "s"
    
    return info

func destroy() -> void:
    if generation_timer:
        generation_timer.stop()
    
    super.destroy()