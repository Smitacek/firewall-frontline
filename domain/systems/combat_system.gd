class_name CombatSystem

# Damage calculation with all modifiers
static func calculate_damage(base_damage: float, damage_type: Constants.DamageType, attacker: Node, target: Node) -> float:
    var final_damage = base_damage
    
    # Apply attacker bonuses
    final_damage = _apply_attacker_modifiers(final_damage, damage_type, attacker)
    
    # Apply target resistance/vulnerabilities
    final_damage = _apply_target_modifiers(final_damage, damage_type, target)
    
    # Apply global modifiers (research upgrades, etc.)
    final_damage = _apply_global_modifiers(final_damage, damage_type)
    
    return max(final_damage, 1.0)  # Minimum 1 damage

static func _apply_attacker_modifiers(damage: float, damage_type: Constants.DamageType, attacker: Node) -> float:
    var modified_damage = damage
    
    if not attacker:
        return modified_damage
    
    # Module level bonuses
    if attacker.has_method("get") and attacker.has_property("level"):
        var level = attacker.level
        match level:
            2:
                modified_damage *= 1.25  # 25% bonus at level 2
            3:
                modified_damage *= 1.5   # 50% bonus at level 3
    
    # Module type specific bonuses
    if attacker.has_method("get") and attacker.has_property("module_type"):
        match attacker.module_type:
            Constants.ModuleType.FIREWALL:
                if damage_type == Constants.DamageType.PACKET:
                    modified_damage *= 1.2  # 20% bonus against packet attacks
            Constants.ModuleType.IDS:
                # IDS gets bonus against detected enemies
                if attacker.has_method("get") and attacker.has_property("detected_enemies"):
                    if attacker.detected_enemies.has(attacker):
                        modified_damage *= 1.3  # 30% bonus against detected enemies
    
    return modified_damage

static func _apply_target_modifiers(damage: float, damage_type: Constants.DamageType, target: Node) -> float:
    var modified_damage = damage
    
    if not target:
        return modified_damage
    
    # Check resistances
    if target.has_method("get") and target.has_property("resistances"):
        if damage_type in target.resistances:
            modified_damage *= 0.5  # 50% damage reduction
    
    # Check vulnerabilities
    if target.has_method("get") and target.has_property("vulnerabilities"):
        if damage_type in target.vulnerabilities:
            modified_damage *= 1.5  # 50% damage increase
    
    # Status effect modifiers
    if target.has_method("get") and target.has_property("active_effects"):
        if target.active_effects.has("vulnerable"):
            modified_damage *= 1.3  # 30% more damage when vulnerable
        if target.active_effects.has("armored"):
            modified_damage *= 0.7  # 30% damage reduction when armored
    
    # Special enemy conditions
    if target.has_method("get"):
        # Script Kiddie vulnerability window
        if target.has_property("vulnerability_window") and target.vulnerability_window:
            modified_damage *= 2.0  # Double damage during vulnerability
        
        # Low health bonus damage (execute mechanic)
        if target.has_property("current_health") and target.has_property("max_health"):
            var health_percent = target.current_health / target.max_health
            if health_percent < 0.25:  # Below 25% health
                modified_damage *= 1.2  # 20% execute bonus
    
    return modified_damage

static func _apply_global_modifiers(damage: float, damage_type: Constants.DamageType) -> float:
    var modified_damage = damage
    
    # Research upgrades (would be implemented later)
    # if GameManager.research_manager:
    #     var research_multiplier = GameManager.research_manager.get_damage_multiplier(damage_type)
    #     modified_damage *= research_multiplier
    
    return modified_damage

# Status effect application
static func apply_status_effect(target: Node, effect_type: String, duration: float, strength: float) -> bool:
    if not target or not target.has_method("apply_status_effect"):
        return false
    
    match effect_type:
        "slow":
            if target.has_method("apply_slow"):
                target.apply_slow(strength)
                return true
        "stun":
            if target.has_method("apply_stun"):
                target.apply_stun(duration)
                return true
        "vulnerable":
            if target.has_method("apply_vulnerability"):
                target.apply_vulnerability(duration, strength)
                return true
        "poison":
            if target.has_method("apply_poison"):
                target.apply_poison(duration, strength)
                return true
    
    return false

# Critical hit calculation
static func calculate_critical_hit(base_damage: float, crit_chance: float, crit_multiplier: float = 2.0) -> Array:
    var is_critical = randf() < crit_chance
    var final_damage = base_damage
    
    if is_critical:
        final_damage *= crit_multiplier
    
    return [final_damage, is_critical]

# Armor penetration calculation
static func calculate_armor_penetration(damage: float, armor: float, penetration: float = 0.0) -> float:
    var effective_armor = max(0.0, armor - penetration)
    var damage_reduction = effective_armor / (effective_armor + 100.0)  # Diminishing returns formula
    return damage * (1.0 - damage_reduction)

# Area of effect damage calculation
static func calculate_aoe_damage(center: Vector2, targets: Array[Node], base_damage: float, max_radius: float, falloff: float = 0.5) -> Dictionary:
    var damage_map = {}
    
    for target in targets:
        if not target:
            continue
            
        var distance = center.distance_to(target.global_position)
        if distance <= max_radius:
            var distance_ratio = distance / max_radius
            var damage_multiplier = 1.0 - (distance_ratio * falloff)
            var final_damage = base_damage * damage_multiplier
            damage_map[target] = final_damage
    
    return damage_map

# Chain damage calculation (for chain lightning, etc.)
static func calculate_chain_damage(initial_damage: float, chain_count: int, damage_falloff: float = 0.2) -> Array[float]:
    var chain_damages: Array[float] = []
    var current_damage = initial_damage
    
    for i in range(chain_count):
        chain_damages.append(current_damage)
        current_damage *= (1.0 - damage_falloff)
    
    return chain_damages

# Healing calculation
static func calculate_healing(base_healing: float, healer: Node, target: Node) -> float:
    var final_healing = base_healing
    
    # Healer bonuses
    if healer and healer.has_method("get") and healer.has_property("healing_multiplier"):
        final_healing *= healer.healing_multiplier
    
    # Target modifiers
    if target and target.has_method("get"):
        if target.has_property("active_effects"):
            if target.active_effects.has("poison"):
                final_healing *= 0.5  # Reduced healing when poisoned
            if target.active_effects.has("regeneration"):
                final_healing *= 1.5  # Increased healing with regen
    
    return final_healing

# Damage over time calculation
static func calculate_dot_damage(base_dps: float, tick_rate: float, duration: float) -> Array:
    var total_ticks = int(duration / tick_rate)
    var damage_per_tick = base_dps * tick_rate
    var tick_schedule: Array = []
    
    for i in range(total_ticks):
        tick_schedule.append({
            "time": i * tick_rate,
            "damage": damage_per_tick
        })
    
    return tick_schedule

# Combat log for debugging
static func log_combat_event(attacker: Node, target: Node, damage: float, damage_type: Constants.DamageType, is_critical: bool = false) -> void:
    var attacker_name = attacker.name if attacker else "Unknown"
    var target_name = target.name if target else "Unknown"
    var crit_text = " (CRITICAL)" if is_critical else ""
    var type_text = Constants.DamageType.keys()[damage_type] if damage_type < Constants.DamageType.size() else "UNKNOWN"
    
    print("[COMBAT] ", attacker_name, " → ", target_name, ": ", damage, " ", type_text, " damage", crit_text)