extends Node2D

@onready var grid_system: Node2D = $GridSystem
@onready var lane_system: Node2D = $LaneSystem
@onready var ui_layer: CanvasLayer = $UILayer

func _ready() -> void:
    print("Main scene loaded")
    _setup_game()
    
func _setup_game() -> void:
    # Connect to GameManager signals
    GameManager.game_state_changed.connect(_on_game_state_changed)
    GameManager.cpu_changed.connect(_on_cpu_changed)
    
    # Start the game in preparation state
    GameManager.start_game()

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