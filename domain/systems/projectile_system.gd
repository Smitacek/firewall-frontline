extends Node2D
class_name BaseProjectile

signal projectile_hit(target: Node, damage: float)
signal projectile_expired()

enum ProjectileType {
    BULLET,
    BEAM,
    MISSILE,
    AREA_EFFECT,
    CHAIN_LIGHTNING
}

# Projectile properties
var projectile_type: ProjectileType = ProjectileType.BULLET
var damage: float = 10.0
var speed: float = 300.0
var range: float = 200.0
var damage_type: Constants.DamageType = Constants.DamageType.PACKET
var source_module: Node = null  # Module that fired this projectile

# Target and movement
var target: Node = null
var target_position: Vector2
var start_position: Vector2
var direction: Vector2
var distance_traveled: float = 0.0

# Special properties
var pierce_count: int = 0  # How many enemies it can pass through
var splash_radius: float = 0.0  # Area damage on impact
var chain_targets: int = 0  # Chain lightning targets
var homing: bool = false  # Track moving targets

# Visual properties
var trail_enabled: bool = false
var trail_length: int = 5
var trail_points: Array[Vector2] = []

# Lifetime management
var lifetime: float = 2.0  # Max time before auto-destruction
var time_alive: float = 0.0

# Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: Area2D = $Area2D
@onready var trail_line: Line2D = $TrailLine

func _ready() -> void:
    _setup_projectile()
    _setup_collision()
    _setup_visuals()

func _setup_projectile() -> void:
    start_position = global_position
    
    if target and is_instance_valid(target):
        target_position = target.global_position
        if homing and target.has_method("get") and target.has_property("velocity"):
            target_position = TargetingSystem.predict_target_position(target, speed, global_position)
    
    direction = (target_position - global_position).normalized()
    
    # Set rotation to face target
    rotation = direction.angle()

func _setup_collision() -> void:
    if not collision:
        collision = Area2D.new()
        add_child(collision)
        
        var shape = CollisionShape2D.new()
        var circle = CircleShape2D.new()
        circle.radius = 8.0
        shape.shape = circle
        collision.add_child(shape)
    
    collision.collision_layer = Constants.LAYER_PROJECTILES
    collision.collision_mask = Constants.LAYER_ENEMIES
    collision.area_entered.connect(_on_area_entered)
    collision.body_entered.connect(_on_body_entered)

func _setup_visuals() -> void:
    # Create basic projectile sprite
    if not sprite:
        sprite = Sprite2D.new()
        add_child(sprite)
    
    # Set sprite based on type
    _create_projectile_sprite()
    
    # Setup trail
    if trail_enabled:
        if not trail_line:
            trail_line = Line2D.new()
            add_child(trail_line)
        
        trail_line.width = 2.0
        trail_line.default_color = _get_projectile_color()

func _create_projectile_sprite() -> void:
    var texture = ImageTexture.new()
    var image: Image
    var color = _get_projectile_color()
    
    match projectile_type:
        ProjectileType.BULLET:
            image = Image.create(8, 3, false, Image.FORMAT_RGBA8)
            image.fill(color)
        ProjectileType.BEAM:
            image = Image.create(16, 2, false, Image.FORMAT_RGBA8)
            image.fill(color)
        ProjectileType.MISSILE:
            image = Image.create(12, 4, false, Image.FORMAT_RGBA8)
            image.fill(color)
        ProjectileType.AREA_EFFECT:
            image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
            image.fill(color)
        _:
            image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
            image.fill(color)
    
    texture.set_image(image)
    sprite.texture = texture

func _get_projectile_color() -> Color:
    match damage_type:
        Constants.DamageType.PACKET:
            return Constants.COLOR_NEON_GREEN
        Constants.DamageType.PAYLOAD:
            return Constants.COLOR_NEON_PINK
        Constants.DamageType.SOCIAL:
            return Color.ORANGE
        Constants.DamageType.ZERO_DAY:
            return Color.RED
        _:
            return Color.WHITE

func initialize(source: Node, target_node: Node, proj_damage: float, proj_speed: float, proj_type: ProjectileType = ProjectileType.BULLET) -> void:
    target = target_node
    damage = proj_damage
    speed = proj_speed
    projectile_type = proj_type
    
    if target and is_instance_valid(target):
        target_position = target.global_position
    
    print("Projectile initialized: ", damage, " damage to ", target.name if target else "position")

func _physics_process(delta: float) -> void:
    time_alive += delta
    
    # Check lifetime
    if time_alive >= lifetime:
        _expire()
        return
    
    # Update target position if homing
    if homing and target and is_instance_valid(target):
        target_position = target.global_position
        direction = (target_position - global_position).normalized()
        rotation = direction.angle()
    
    # Move projectile
    var movement = direction * speed * delta
    global_position += movement
    distance_traveled += movement.length()
    
    # Check range
    if distance_traveled >= range:
        _expire()
        return
    
    # Update trail
    if trail_enabled:
        _update_trail()
    
    # Check if reached target position (for non-homing projectiles)
    if not homing and global_position.distance_to(target_position) < 5.0:
        _hit_target()

func _update_trail() -> void:
    if not trail_line:
        return
    
    trail_points.append(global_position)
    
    if trail_points.size() > trail_length:
        trail_points.pop_front()
    
    trail_line.clear_points()
    for point in trail_points:
        trail_line.add_point(to_local(point))

func _on_area_entered(area: Area2D) -> void:
    var enemy = area.get_parent()
    if enemy and enemy.has_method("take_damage"):
        _hit_enemy(enemy)

func _on_body_entered(body: Node) -> void:
    if body and body.has_method("take_damage"):
        _hit_enemy(body)

func _hit_enemy(enemy: Node) -> void:
    # Apply damage
    if enemy.has_method("take_damage"):
        enemy.take_damage(damage, damage_type)
        projectile_hit.emit(enemy, damage)
    
    # Handle special projectile effects
    match projectile_type:
        ProjectileType.AREA_EFFECT:
            _explode()
        ProjectileType.CHAIN_LIGHTNING:
            _chain_to_next_target(enemy)
        _:
            # Check pierce
            if pierce_count > 0:
                pierce_count -= 1
                return
    
    # Destroy projectile
    _destroy()

func _hit_target() -> void:
    if target and is_instance_valid(target):
        _hit_enemy(target)
    else:
        # Target was destroyed, explode at position if area effect
        if projectile_type == ProjectileType.AREA_EFFECT:
            _explode()
        else:
            _destroy()

func _explode() -> void:
    if splash_radius <= 0:
        _destroy()
        return
    
    # Find enemies in splash radius
    var enemies_in_area = GameManager.enemy_manager.get_enemies_in_range(global_position, splash_radius)
    
    for enemy in enemies_in_area:
        if enemy.has_method("take_damage"):
            # Reduced damage based on distance
            var distance = global_position.distance_to(enemy.global_position)
            var damage_multiplier = 1.0 - (distance / splash_radius) * 0.5  # 50% falloff
            var splash_damage = damage * damage_multiplier
            
            enemy.take_damage(splash_damage, damage_type)
            projectile_hit.emit(enemy, splash_damage)
    
    # Visual explosion effect
    _show_explosion_effect()
    
    _destroy()

func _chain_to_next_target(hit_enemy: Node) -> void:
    if chain_targets <= 0:
        _destroy()
        return
    
    # Find next target
    var nearby_enemies = GameManager.enemy_manager.get_enemies_in_range(global_position, 100.0)
    nearby_enemies.erase(hit_enemy)  # Don't chain back to same enemy
    
    if nearby_enemies.is_empty():
        _destroy()
        return
    
    var next_target = TargetingSystem.select_target(nearby_enemies, TargetingSystem.Priority.CLOSEST, global_position)
    
    if next_target:
        # Create new projectile for chain
        var chain_projectile = duplicate()
        get_parent().add_child(chain_projectile)
        
        chain_projectile.target = next_target
        chain_projectile.damage = damage * 0.8  # Reduce damage by 20% per chain
        chain_projectile.chain_targets = chain_targets - 1
        chain_projectile.global_position = global_position
        chain_projectile._setup_projectile()
    
    _destroy()

func _show_explosion_effect() -> void:
    # Create explosion visual
    var explosion = ColorRect.new()
    explosion.color = _get_projectile_color()
    explosion.size = Vector2(splash_radius * 2, splash_radius * 2)
    explosion.position = -explosion.size / 2
    add_child(explosion)
    
    var tween = create_tween()
    tween.tween_property(explosion, "scale", Vector2(1.5, 1.5), 0.3)
    tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.3)
    tween.tween_callback(explosion.queue_free)

func _expire() -> void:
    projectile_expired.emit()
    _destroy()

func _destroy() -> void:
    queue_free()

# Factory methods for different projectile types
static func create_bullet(source: Node, target: Node, damage: float, speed: float = 300.0) -> BaseProjectile:
    var projectile = preload("res://domain/systems/projectile_system.gd").new()
    projectile.initialize(source, target, damage, speed, ProjectileType.BULLET)
    return projectile

static func create_missile(source: Node, target: Node, damage: float, speed: float = 200.0, splash: float = 50.0) -> BaseProjectile:
    var projectile = preload("res://domain/systems/projectile_system.gd").new()
    projectile.initialize(source, target, damage, speed, ProjectileType.MISSILE)
    projectile.splash_radius = splash
    projectile.homing = true
    return projectile

static func create_beam(source: Node, target: Node, damage: float) -> BaseProjectile:
    var projectile = preload("res://domain/systems/projectile_system.gd").new()
    projectile.initialize(source, target, damage, 1000.0, ProjectileType.BEAM)
    projectile.lifetime = 0.1  # Instant beam
    return projectile

static func create_chain_lightning(source: Node, target: Node, damage: float, chains: int = 3) -> BaseProjectile:
    var projectile = preload("res://domain/systems/projectile_system.gd").new()
    projectile.initialize(source, target, damage, 500.0, ProjectileType.CHAIN_LIGHTNING)
    projectile.chain_targets = chains
    projectile.trail_enabled = true
    return projectile