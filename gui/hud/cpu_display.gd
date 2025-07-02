extends Control
class_name CPUDisplay

@onready var cpu_label: Label = $CPULabel

func _ready() -> void:
    _setup_ui()
    _connect_signals()
    _update_display(GameManager.cpu_cycles)

func _setup_ui() -> void:
    # Set up styling
    if cpu_label:
        cpu_label.add_theme_color_override("font_color", Constants.COLOR_NEON_GREEN)

func _connect_signals() -> void:
    GameManager.cpu_changed.connect(_on_cpu_changed)

func _on_cpu_changed(new_amount: int) -> void:
    _update_display(new_amount)

func _update_display(amount: int) -> void:
    if cpu_label:
        cpu_label.text = "CPU: " + str(amount)
        
        # Flash effect when CPU changes
        var tween = create_tween()
        tween.tween_modulate_property(cpu_label, Color.WHITE, 0.1)
        tween.tween_modulate_property(cpu_label, Constants.COLOR_NEON_GREEN, 0.1)