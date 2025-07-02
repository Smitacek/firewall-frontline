extends Node2D

@onready var grid_system: GridSystem = $GameLayer/GridSystem
@onready var lane_system: LaneSystem = $GameLayer/LaneSystem
@onready var ui_layer: CanvasLayer = $UILayer
@onready var module_panel: ModulePanel = $UILayer/HUD/ModulePanel

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
    # Initialize module manager with references
    if GameManager.module_manager and grid_system and GameManager.economy_manager:
        GameManager.module_manager.initialize(grid_system, GameManager.economy_manager)
    
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