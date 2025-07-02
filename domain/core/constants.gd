class_name Constants

# Grid settings
const GRID_WIDTH: int = 8
const GRID_HEIGHT: int = 5
const CELL_SIZE: float = 64.0
const GRID_OFFSET: Vector2 = Vector2(160, 120)

# Lane settings  
const LANE_COUNT: int = 3
const LANE_SPACING: float = 128.0
const LANE_START_X: float = 1120.0
const LANE_END_X: float = 160.0

# Game balance
const STARTING_CPU: int = 150
const PASSIVE_CPU_RATE: float = 0.5  # CPU per second
const WAVE_PREP_TIME: float = 30.0

# Module types
enum ModuleType {
    POWER_NODE,
    FIREWALL,
    HONEYPOT,
    IDS,
    SANDBOX,
    ANTIVIRUS
}

# Enemy types
enum EnemyType {
    SCRIPT_KIDDIE,
    SPAM_BOT,
    PHISHING_SPEAR,
    BOTNET_SWARM,
    TROJAN_HORSE,
    ZERO_DAY,
    APT_BOSS
}

# Damage types
enum DamageType {
    PACKET,
    PAYLOAD,
    SOCIAL,
    ZERO_DAY
}

# Colors - neon cyberpunk palette
const COLOR_NEON_BLUE: Color = Color("#08F8FF")
const COLOR_NEON_GREEN: Color = Color("#0FFF0F") 
const COLOR_NEON_PINK: Color = Color("#FF0FFF")
const COLOR_DARK_BG: Color = Color("#0A0A0A")
const COLOR_GRID: Color = Color("#1A1A1A")

# Physics layers
const LAYER_WORLD: int = 1
const LAYER_MODULES: int = 2
const LAYER_ENEMIES: int = 3
const LAYER_PROJECTILES: int = 4
const LAYER_UI: int = 5

# File paths
const DATA_PATH: String = "res://data/"
const MODULES_DATA_PATH: String = "res://data/modules.json"
const ENEMIES_DATA_PATH: String = "res://data/enemies.json"
const WAVES_DATA_PATH: String = "res://data/waves/"