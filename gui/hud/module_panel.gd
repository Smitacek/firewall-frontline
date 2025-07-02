extends Control
class_name ModulePanel

signal module_purchase_requested(module_type: Constants.ModuleType)

@onready var power_node_button: Button = $ModuleButtons/PowerNodeButton
@onready var firewall_button: Button = $ModuleButtons/FirewallButton
@onready var honeypot_button: Button = $ModuleButtons/HoneypotButton
@onready var ids_button: Button = $ModuleButtons/IDSButton

var module_manager: ModuleManager
var economy_manager: EconomyManager

func _ready() -> void:
    _setup_buttons()
    _connect_signals()

func initialize(mod_manager: ModuleManager, econ_manager: EconomyManager) -> void:
    module_manager = mod_manager
    economy_manager = econ_manager
    
    if economy_manager:
        economy_manager.cpu_changed.connect(_on_cpu_changed)
    
    _update_button_states()

func _setup_buttons() -> void:
    # Set up button texts and tooltips
    if power_node_button:
        power_node_button.text = "Power Node\n50 CPU"
        power_node_button.tooltip_text = "Generates CPU cycles over time"
    
    if firewall_button:
        firewall_button.text = "Firewall\n100 CPU"
        firewall_button.tooltip_text = "Blocks packet-based attacks"
    
    if honeypot_button:
        honeypot_button.text = "Honeypot\n75 CPU"
        honeypot_button.tooltip_text = "Lures enemies and explodes"
    
    if ids_button:
        ids_button.text = "IDS\n150 CPU"
        ids_button.tooltip_text = "Detects threats and slows enemies"

func _connect_signals() -> void:
    if power_node_button:
        power_node_button.pressed.connect(_on_power_node_button_pressed)
    
    if firewall_button:
        firewall_button.pressed.connect(_on_firewall_button_pressed)
    
    if honeypot_button:
        honeypot_button.pressed.connect(_on_honeypot_button_pressed)
    
    if ids_button:
        ids_button.pressed.connect(_on_ids_button_pressed)

func _on_power_node_button_pressed() -> void:
    _request_module_purchase(Constants.ModuleType.POWER_NODE)

func _on_firewall_button_pressed() -> void:
    _request_module_purchase(Constants.ModuleType.FIREWALL)

func _on_honeypot_button_pressed() -> void:
    _request_module_purchase(Constants.ModuleType.HONEYPOT)

func _on_ids_button_pressed() -> void:
    _request_module_purchase(Constants.ModuleType.IDS)

func _request_module_purchase(module_type: Constants.ModuleType) -> void:
    module_purchase_requested.emit(module_type)
    
    if module_manager:
        module_manager.start_placement_mode(module_type)

func _on_cpu_changed(new_amount: int) -> void:
    _update_button_states()

func _update_button_states() -> void:
    if not economy_manager:
        return
    
    var current_cpu = economy_manager.cpu_cycles
    
    # Update button enabled states based on affordability
    if power_node_button:
        power_node_button.disabled = current_cpu < 50
        _update_button_style(power_node_button, current_cpu >= 50)
    
    if firewall_button:
        firewall_button.disabled = current_cpu < 100
        _update_button_style(firewall_button, current_cpu >= 100)
    
    if honeypot_button:
        honeypot_button.disabled = current_cpu < 75
        _update_button_style(honeypot_button, current_cpu >= 75)
    
    if ids_button:
        ids_button.disabled = current_cpu < 150
        _update_button_style(ids_button, current_cpu >= 150)

func _update_button_style(button: Button, can_afford: bool) -> void:
    if can_afford:
        button.add_theme_color_override("font_color", Constants.COLOR_NEON_GREEN)
        button.modulate = Color.WHITE
    else:
        button.add_theme_color_override("font_color", Color.GRAY)
        button.modulate = Color(0.7, 0.7, 0.7, 1.0)

func set_panel_visible(visible: bool) -> void:
    self.visible = visible

func highlight_affordable_modules() -> void:
    # Visual effect to highlight what player can afford
    _update_button_states()
    
    var tween = create_tween()
    tween.set_loops(3)
    tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)
    tween.tween_property(self, "modulate", Color.WHITE, 0.2)