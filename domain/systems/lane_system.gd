extends Node2D
class_name LaneSystem

signal enemy_reached_end(lane_id: int)

var lanes: Array[Lane] = []

class Lane:
    var id: int
    var path_points: Array[Vector2] = []
    var spawn_point: Vector2
    var end_point: Vector2
    var active_enemies: Array[Node] = []
    
    func _init(lane_id: int, spawn_pos: Vector2, end_pos: Vector2):
        id = lane_id
        spawn_point = spawn_pos
        end_point = end_pos
        _generate_path()
    
    func _generate_path() -> void:
        # Simple straight path for now
        path_points = [spawn_point, end_point]
    
    func get_path() -> Array[Vector2]:
        return path_points
    
    func add_enemy(enemy: Node) -> void:
        active_enemies.append(enemy)
    
    func remove_enemy(enemy: Node) -> void:
        active_enemies.erase(enemy)

func _ready() -> void:
    _initialize_lanes()
    _setup_visuals()

func _initialize_lanes() -> void:
    lanes.clear()
    
    # Create 3 lanes with equal spacing
    var start_y = Constants.GRID_OFFSET.y + Constants.CELL_SIZE * 0.5
    var lane_spacing = Constants.CELL_SIZE * 1.5
    
    for i in range(Constants.LANE_COUNT):
        var y_pos = start_y + (i * lane_spacing)
        var spawn_pos = Vector2(Constants.LANE_START_X, y_pos)
        var end_pos = Vector2(Constants.LANE_END_X, y_pos)
        
        var lane = Lane.new(i, spawn_pos, end_pos)
        lanes.append(lane)
        
        print("Lane ", i, " created from ", spawn_pos, " to ", end_pos)

func _setup_visuals() -> void:
    queue_redraw()

func _draw() -> void:
    # Draw lane paths
    for lane in lanes:
        _draw_lane_path(lane)

func _draw_lane_path(lane: Lane) -> void:
    var path = lane.get_path()
    if path.size() < 2:
        return
    
    # Draw path line
    var color = Constants.COLOR_NEON_GREEN
    color.a = 0.3  # Semi-transparent
    
    for i in range(path.size() - 1):
        draw_line(path[i], path[i + 1], color, 4.0)
    
    # Draw spawn point
    draw_circle(lane.spawn_point, 8.0, Constants.COLOR_NEON_PINK)
    
    # Draw end point  
    draw_circle(lane.end_point, 8.0, Constants.COLOR_NEON_BLUE)

func get_lane(lane_id: int) -> Lane:
    if lane_id >= 0 and lane_id < lanes.size():
        return lanes[lane_id]
    return null

func get_random_lane() -> Lane:
    if lanes.size() > 0:
        return lanes[randi() % lanes.size()]
    return null

func get_spawn_position(lane_id: int) -> Vector2:
    var lane = get_lane(lane_id)
    if lane:
        return lane.spawn_point
    return Vector2.ZERO

func get_path_for_lane(lane_id: int) -> Array[Vector2]:
    var lane = get_lane(lane_id)
    if lane:
        return lane.get_path()
    return []

func register_enemy(lane_id: int, enemy: Node) -> void:
    var lane = get_lane(lane_id)
    if lane:
        lane.add_enemy(enemy)

func unregister_enemy(lane_id: int, enemy: Node) -> void:
    var lane = get_lane(lane_id)
    if lane:
        lane.remove_enemy(enemy)

func enemy_reached_end_handler(lane_id: int) -> void:
    enemy_reached_end.emit(lane_id)
    print("Enemy reached end of lane ", lane_id)