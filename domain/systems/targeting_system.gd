class_name TargetingSystem

enum Priority {
    CLOSEST,        # Nearest enemy
    FARTHEST,       # Enemy closest to end
    STRONGEST,      # Highest health
    WEAKEST,        # Lowest health
    FASTEST,        # Highest speed
    SLOWEST,        # Lowest speed
    FIRST,          # First in path
    LAST           # Last spawned
}

static func select_target(targets: Array[Node], priority: Priority, source_position: Vector2) -> Node:
    if targets.is_empty():
        return null
    
    if targets.size() == 1:
        return targets[0]
    
    match priority:
        Priority.CLOSEST:
            return _find_closest(targets, source_position)
        Priority.FARTHEST:
            return _find_farthest_along_path(targets)
        Priority.STRONGEST:
            return _find_strongest(targets)
        Priority.WEAKEST:
            return _find_weakest(targets)
        Priority.FASTEST:
            return _find_fastest(targets)
        Priority.SLOWEST:
            return _find_slowest(targets)
        Priority.FIRST:
            return _find_first_in_path(targets)
        Priority.LAST:
            return _find_last_spawned(targets)
        _:
            return targets[0]

static func _find_closest(targets: Array[Node], source_position: Vector2) -> Node:
    var closest_target = targets[0]
    var closest_distance = source_position.distance_to(closest_target.global_position)
    
    for target in targets:
        var distance = source_position.distance_to(target.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_target = target
    
    return closest_target

static func _find_farthest_along_path(targets: Array[Node]) -> Node:
    var farthest_target = targets[0]
    var shortest_distance_to_end = INF
    
    for target in targets:
        if target.has_method("get_distance_to_end"):
            var distance = target.get_distance_to_end()
            if distance < shortest_distance_to_end:
                shortest_distance_to_end = distance
                farthest_target = target
    
    return farthest_target

static func _find_strongest(targets: Array[Node]) -> Node:
    var strongest_target = targets[0]
    var highest_health = 0.0
    
    for target in targets:
        if target.has_method("get") and target.has_property("current_health"):
            if target.current_health > highest_health:
                highest_health = target.current_health
                strongest_target = target
        elif target.has_method("get_health"):
            var health = target.get_health()
            if health > highest_health:
                highest_health = health
                strongest_target = target
    
    return strongest_target

static func _find_weakest(targets: Array[Node]) -> Node:
    var weakest_target = targets[0]
    var lowest_health = INF
    
    for target in targets:
        var health = 0.0
        if target.has_method("get") and target.has_property("current_health"):
            health = target.current_health
        elif target.has_method("get_health"):
            health = target.get_health()
        
        if health < lowest_health:
            lowest_health = health
            weakest_target = target
    
    return weakest_target

static func _find_fastest(targets: Array[Node]) -> Node:
    var fastest_target = targets[0]
    var highest_speed = 0.0
    
    for target in targets:
        var speed = 0.0
        if target.has_method("get") and target.has_property("current_movement_speed"):
            speed = target.current_movement_speed
        elif target.has_method("get_speed"):
            speed = target.get_speed()
        
        if speed > highest_speed:
            highest_speed = speed
            fastest_target = target
    
    return fastest_target

static func _find_slowest(targets: Array[Node]) -> Node:
    var slowest_target = targets[0]
    var lowest_speed = INF
    
    for target in targets:
        var speed = 0.0
        if target.has_method("get") and target.has_property("current_movement_speed"):
            speed = target.current_movement_speed
        elif target.has_method("get_speed"):
            speed = target.get_speed()
        
        if speed < lowest_speed:
            lowest_speed = speed
            slowest_target = target
    
    return slowest_target

static func _find_first_in_path(targets: Array[Node]) -> Node:
    var first_target = targets[0]
    var max_progress = -1.0
    
    for target in targets:
        if target.has_method("get") and target.has_property("current_path_index"):
            var progress = float(target.current_path_index)
            if target.has_property("path_points") and target.path_points.size() > 0:
                progress += target.global_position.distance_to(target.target_position) / 64.0
            
            if progress > max_progress:
                max_progress = progress
                first_target = target
    
    return first_target

static func _find_last_spawned(targets: Array[Node]) -> Node:
    # Assumes newer enemies have higher node positions in tree (spawned later)
    var last_target = targets[0]
    var latest_position = -1
    
    for target in targets:
        var position = target.get_index()
        if position > latest_position:
            latest_position = position
            last_target = target
    
    return last_target

# Line of sight calculation
static func has_line_of_sight(from: Vector2, to: Vector2, obstacles: Array[Node] = []) -> bool:
    if obstacles.is_empty():
        return true
    
    var space_state = from.get_viewport().world_2d.direct_space_state
    if not space_state:
        return true
    
    var query = PhysicsRayQueryParameters2D.create(from, to)
    query.collision_mask = Constants.LAYER_MODULES  # Only check modules as obstacles
    query.exclude = []
    
    var result = space_state.intersect_ray(query)
    return result.is_empty()

# Prediction for moving targets
static func predict_target_position(target: Node, projectile_speed: float, source_position: Vector2) -> Vector2:
    if not target.has_method("get") or not target.has_property("velocity"):
        return target.global_position
    
    var target_velocity = target.velocity if target.has_property("velocity") else Vector2.ZERO
    var distance = source_position.distance_to(target.global_position)
    var time_to_hit = distance / projectile_speed if projectile_speed > 0 else 0.0
    
    return target.global_position + target_velocity * time_to_hit

# Area targeting (for splash damage)
static func get_targets_in_area(center: Vector2, radius: float, targets: Array[Node]) -> Array[Node]:
    var area_targets: Array[Node] = []
    
    for target in targets:
        if target.global_position.distance_to(center) <= radius:
            area_targets.append(target)
    
    return area_targets

# Filter targets by type/condition
static func filter_targets(targets: Array[Node], condition: Callable) -> Array[Node]:
    var filtered: Array[Node] = []
    
    for target in targets:
        if condition.call(target):
            filtered.append(target)
    
    return filtered

# Range checking utilities
static func is_in_range(source: Vector2, target: Vector2, range: float) -> bool:
    return source.distance_to(target) <= range

static func get_angle_to_target(source: Vector2, target: Vector2) -> float:
    return source.angle_to_point(target)

# Multi-target selection (for modules that can hit multiple enemies)
static func select_multiple_targets(targets: Array[Node], count: int, priority: Priority, source_position: Vector2) -> Array[Node]:
    if targets.size() <= count:
        return targets
    
    var selected: Array[Node] = []
    var remaining = targets.duplicate()
    
    for i in range(count):
        var target = select_target(remaining, priority, source_position)
        if target:
            selected.append(target)
            remaining.erase(target)
    
    return selected