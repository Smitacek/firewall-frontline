extends Node2D

@onready var grid_system: GridSystem = $GameLayer/GridSystem
@onready var lane_system: LaneSystem = $GameLayer/LaneSystem
@onready var ui_layer: CanvasLayer = $UILayer
@onready var module_panel: ModulePanel = $UILayer/HUD/ModulePanel
@onready var enemy_container: Node2D = $GameLayer/EnemyContainer

func _ready() -> void:
    print("Main scene loaded")
    _setup_game()
    
func _setup_game() -> void:
    # Connect to GameManager signals
    GameManager.game_state_changed.connect(_on_game_state_changed)
    GameManager.cpu_changed.connect(_on_cpu_changed)
    
    # Initialize systems after GameManager is ready
    await get_tree().process_frame
    _initialize_systems()
    
    # Start the game in preparation state
    GameManager.start_game()

func _initialize_systems() -> void:
    # Store lane system reference in GameManager
    GameManager.lane_system = lane_system
    
    # Initialize module manager with references
    if GameManager.module_manager and grid_system and GameManager.economy_manager:
        GameManager.module_manager.initialize(grid_system, GameManager.economy_manager)
    
    # Initialize enemy manager with references
    if GameManager.enemy_manager and lane_system and enemy_container:
        GameManager.enemy_manager.initialize(lane_system, enemy_container)
    
    # Initialize module panel
    if module_panel and GameManager.module_manager and GameManager.economy_manager:
        module_panel.initialize(GameManager.module_manager, GameManager.economy_manager)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
    match new_state:
        GameManager.GameState.WAVE_PREP:
            print("Wave preparation phase")
        GameManager.GameState.PLAYING:
            print("Wave in progress")
        GameManager.GameState.PAUSED:
            print("Game paused")
        GameManager.GameState.GAME_OVER:
            print("Game over")

func _on_cpu_changed(new_amount: int) -> void:
    # This will be handled by UI when implemented
    pass

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause_game"):
        if GameManager.current_state == GameManager.GameState.PLAYING:
            GameManager.change_state(GameManager.GameState.PAUSED)
        elif GameManager.current_state == GameManager.GameState.PAUSED:
            GameManager.change_state(GameManager.GameState.PLAYING)
    
    # Test enemy spawning (temporary)
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                _test_spawn_enemy()
            KEY_2:
                _test_spawn_wave()

func _test_spawn_enemy() -> void:
    if GameManager.enemy_manager:
        var lane_id = randi() % Constants.LANE_COUNT
        GameManager.enemy_manager.spawn_enemy(Constants.EnemyType.SCRIPT_KIDDIE, lane_id)
        print("Test spawned Script Kiddie on lane ", lane_id)

func _test_spawn_wave() -> void:
    if GameManager.enemy_manager:
        var test_wave = {
            "spawn_groups": [
                {
                    "enemy_type": "script_kiddie",
                    "count": 3,
                    "spawn_interval": 1.0,
                    "lane": "random"
                }
            ]
        }
        GameManager.enemy_manager.spawn_wave(test_wave)
        print("Test wave spawned!")