extends Node

signal game_state_changed(new_state: GameState)
signal wave_completed(wave_number: int)
signal game_over(victory: bool)
signal cpu_changed(new_amount: int)

enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    WAVE_PREP,
    GAME_OVER
}

var current_state: GameState = GameState.MENU
var current_level: int = 1
var current_wave: int = 0

# Economy
var cpu_cycles: int = 150
var research_tokens: int = 0

# Systems - will be initialized when needed
var economy_manager: EconomyManager
var wave_manager: Node
var module_manager: ModuleManager
var enemy_manager: EnemyManager
var lane_system: Node

func _ready() -> void:
    print("GameManager initialized")
    _initialize_systems()

func _initialize_systems() -> void:
    # Create economy manager
    economy_manager = EconomyManager.new()
    economy_manager.name = "EconomyManager"
    add_child(economy_manager)
    
    # Create module manager
    module_manager = ModuleManager.new()
    module_manager.name = "ModuleManager"
    add_child(module_manager)
    
    # Create enemy manager
    enemy_manager = EnemyManager.new()
    enemy_manager.name = "EnemyManager"
    add_child(enemy_manager)
    
    # Connect economy to our signals
    economy_manager.cpu_changed.connect(_on_economy_cpu_changed)
    
    # Connect enemy manager signals
    enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
    enemy_manager.enemy_reached_end.connect(_on_enemy_reached_end)

func _on_all_enemies_defeated() -> void:
    wave_completed_handler()

func _on_enemy_reached_end(enemy: BaseEnemy) -> void:
    # For now, any enemy reaching end triggers game over
    trigger_game_over(false)

func _on_economy_cpu_changed(new_amount: int) -> void:
    cpu_cycles = new_amount
    cpu_changed.emit(new_amount)

func change_state(new_state: GameState) -> void:
    if current_state != new_state:
        var old_state = current_state
        current_state = new_state
        print("Game state changed from ", GameState.keys()[old_state], " to ", GameState.keys()[new_state])
        game_state_changed.emit(new_state)

func can_afford(cost: int) -> bool:
    return cpu_cycles >= cost

func spend_cpu(amount: int) -> bool:
    if can_afford(amount):
        cpu_cycles -= amount
        cpu_changed.emit(cpu_cycles)
        print("Spent ", amount, " CPU. Remaining: ", cpu_cycles)
        return true
    else:
        print("Insufficient CPU! Need ", amount, ", have ", cpu_cycles)
        return false

func add_cpu(amount: int) -> void:
    cpu_cycles += amount
    cpu_changed.emit(cpu_cycles)
    print("Gained ", amount, " CPU. Total: ", cpu_cycles)

func add_research_tokens(amount: int) -> void:
    research_tokens += amount
    print("Gained ", amount, " research tokens. Total: ", research_tokens)

func start_game() -> void:
    change_state(GameState.WAVE_PREP)
    current_wave = 0
    cpu_cycles = 150
    research_tokens = 0
    cpu_changed.emit(cpu_cycles)

func next_wave() -> void:
    current_wave += 1
    print("Starting wave ", current_wave)
    change_state(GameState.PLAYING)

func wave_completed_handler() -> void:
    change_state(GameState.WAVE_PREP)
    wave_completed.emit(current_wave)
    
    # Wave completion bonus
    var bonus_cpu = 25 + (current_wave * 5)
    add_cpu(bonus_cpu)

func trigger_game_over(victory: bool) -> void:
    change_state(GameState.GAME_OVER)
    game_over.emit(victory)
    if victory:
        print("Victory! Wave ", current_wave, " completed!")
    else:
        print("Defeat! Game over at wave ", current_wave)