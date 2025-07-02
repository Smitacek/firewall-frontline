extends Node
class_name EconomyManager

signal cpu_changed(new_amount: int)
signal research_tokens_changed(new_amount: int)
signal insufficient_funds()
signal income_generated(amount: int)

var cpu_cycles: int = Constants.STARTING_CPU
var research_tokens: int = 0
var passive_income_rate: float = Constants.PASSIVE_CPU_RATE
var income_multiplier: float = 1.0

# Income sources (Power Nodes, etc.)
var income_sources: Array[IncomeSource] = []
var income_timer: Timer

class IncomeSource:
    var source_node: Node
    var generation_rate: int
    var generation_interval: float
    var last_generation_time: float
    
    func _init(node: Node, rate: int, interval: float):
        source_node = node
        generation_rate = rate
        generation_interval = interval
        last_generation_time = 0.0
    
    func can_generate() -> bool:
        var current_time = Time.get_time_dict_from_system()
        var time_passed = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - last_generation_time
        return time_passed >= generation_interval
    
    func generate() -> int:
        last_generation_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
        return generation_rate

func _ready() -> void:
    _setup_passive_income()
    print("EconomyManager initialized with ", cpu_cycles, " CPU")

func _setup_passive_income() -> void:
    income_timer = Timer.new()
    income_timer.wait_time = 1.0  # Check every second
    income_timer.timeout.connect(_process_income)
    income_timer.autostart = true
    add_child(income_timer)

func _process_income() -> void:
    # Passive income
    var passive_income = int(passive_income_rate * income_multiplier)
    if passive_income > 0:
        add_cpu(passive_income)
        income_generated.emit(passive_income)
    
    # Process income sources (Power Nodes)
    for source in income_sources:
        if source.source_node != null and is_instance_valid(source.source_node):
            if source.can_generate():
                var generated = source.generate()
                add_cpu(generated)
                income_generated.emit(generated)
        else:
            # Remove invalid sources
            income_sources.erase(source)

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
        insufficient_funds.emit()
        return false

func add_cpu(amount: int) -> void:
    cpu_cycles += amount
    cpu_changed.emit(cpu_cycles)

func add_research_tokens(amount: int) -> void:
    research_tokens += amount
    research_tokens_changed.emit(research_tokens)
    print("Gained ", amount, " research tokens. Total: ", research_tokens)

func can_afford_research(cost: int) -> bool:
    return research_tokens >= cost

func spend_research_tokens(amount: int) -> bool:
    if can_afford_research(amount):
        research_tokens -= amount
        research_tokens_changed.emit(research_tokens)
        return true
    return false

func add_income_source(node: Node, rate: int, interval: float) -> void:
    var source = IncomeSource.new(node, rate, interval)
    income_sources.append(source)
    print("Added income source: ", rate, " CPU every ", interval, " seconds")

func remove_income_source(node: Node) -> void:
    for i in range(income_sources.size() - 1, -1, -1):
        if income_sources[i].source_node == node:
            income_sources.remove_at(i)
            print("Removed income source from node")
            break

func get_total_income_rate() -> float:
    var total = passive_income_rate
    for source in income_sources:
        if source.source_node != null and is_instance_valid(source.source_node):
            total += float(source.generation_rate) / source.generation_interval
    return total * income_multiplier

func set_income_multiplier(multiplier: float) -> void:
    income_multiplier = multiplier
    print("Income multiplier set to: ", multiplier)

func reset_economy() -> void:
    cpu_cycles = Constants.STARTING_CPU
    research_tokens = 0
    income_sources.clear()
    income_multiplier = 1.0
    cpu_changed.emit(cpu_cycles)
    research_tokens_changed.emit(research_tokens)
    print("Economy reset")