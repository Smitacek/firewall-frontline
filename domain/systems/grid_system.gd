extends Node2D
class_name GridSystem

signal cell_clicked(grid_pos: Vector2)
signal cell_hovered(grid_pos: Vector2)

var grid_data: Array[Array] = []
var occupied_cells: Dictionary = {}

func _ready() -> void:
    _initialize_grid()
    _setup_visuals()

func _initialize_grid() -> void:
    # Initialize 8x5 grid with empty cells
    grid_data = []
    for y in range(Constants.GRID_HEIGHT):
        var row: Array = []
        for x in range(Constants.GRID_WIDTH):
            row.append(null)  # null = empty cell
        grid_data.append(row)
    
    print("Grid initialized: ", Constants.GRID_WIDTH, "x", Constants.GRID_HEIGHT)

func _setup_visuals() -> void:
    # Grid will be rendered in _draw()
    queue_redraw()

func _draw() -> void:
    # Draw grid lines
    var grid_color = Constants.COLOR_GRID
    var line_width = 1.0
    
    # Vertical lines
    for x in range(Constants.GRID_WIDTH + 1):
        var start_pos = Vector2(x * Constants.CELL_SIZE, 0) + Constants.GRID_OFFSET
        var end_pos = Vector2(x * Constants.CELL_SIZE, Constants.GRID_HEIGHT * Constants.CELL_SIZE) + Constants.GRID_OFFSET
        draw_line(start_pos, end_pos, grid_color, line_width)
    
    # Horizontal lines  
    for y in range(Constants.GRID_HEIGHT + 1):
        var start_pos = Vector2(0, y * Constants.CELL_SIZE) + Constants.GRID_OFFSET
        var end_pos = Vector2(Constants.GRID_WIDTH * Constants.CELL_SIZE, y * Constants.CELL_SIZE) + Constants.GRID_OFFSET
        draw_line(start_pos, end_pos, grid_color, line_width)
    
    # Draw occupied cells
    for pos in occupied_cells.keys():
        _draw_occupied_cell(pos)

func _draw_occupied_cell(grid_pos: Vector2) -> void:
    var world_pos = grid_to_world(grid_pos)
    var rect = Rect2(world_pos, Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE))
    draw_rect(rect, Constants.COLOR_NEON_BLUE, false, 2.0)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            var mouse_pos = get_global_mouse_position()
            var grid_pos = world_to_grid(mouse_pos)
            if is_valid_grid_position(grid_pos):
                cell_clicked.emit(grid_pos)
                print("Grid cell clicked: ", grid_pos)

func _on_mouse_moved() -> void:
    var mouse_pos = get_global_mouse_position()
    var grid_pos = world_to_grid(mouse_pos)
    if is_valid_grid_position(grid_pos):
        cell_hovered.emit(grid_pos)

func world_to_grid(world_pos: Vector2) -> Vector2:
    var local_pos = world_pos - Constants.GRID_OFFSET
    var grid_x = int(local_pos.x / Constants.CELL_SIZE)
    var grid_y = int(local_pos.y / Constants.CELL_SIZE)
    return Vector2(grid_x, grid_y)

func grid_to_world(grid_pos: Vector2) -> Vector2:
    return Vector2(grid_pos.x * Constants.CELL_SIZE, grid_pos.y * Constants.CELL_SIZE) + Constants.GRID_OFFSET

func is_valid_grid_position(grid_pos: Vector2) -> bool:
    return grid_pos.x >= 0 and grid_pos.x < Constants.GRID_WIDTH and \
           grid_pos.y >= 0 and grid_pos.y < Constants.GRID_HEIGHT

func is_cell_empty(grid_pos: Vector2) -> bool:
    if not is_valid_grid_position(grid_pos):
        return false
    return not occupied_cells.has(grid_pos)

func occupy_cell(grid_pos: Vector2, occupant: Node) -> bool:
    if not is_cell_empty(grid_pos):
        return false
    
    occupied_cells[grid_pos] = occupant
    grid_data[int(grid_pos.y)][int(grid_pos.x)] = occupant
    queue_redraw()
    return true

func free_cell(grid_pos: Vector2) -> void:
    if occupied_cells.has(grid_pos):
        occupied_cells.erase(grid_pos)
        grid_data[int(grid_pos.y)][int(grid_pos.x)] = null
        queue_redraw()

func get_occupant_at(grid_pos: Vector2) -> Node:
    return occupied_cells.get(grid_pos, null)