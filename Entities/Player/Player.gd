extends KinematicBody2D

# Player movement speed
export var speed = 75
var last_direction = Vector2(0, 1)
var attack_playing = false

# Player stats
var health = 100
var health_max = 100
var health_regen = 1
var mana = 100
var mana_max = 100
var mana_regen = 2

# Attack Variables
var attack_cooldown_time = 1000
var next_attack_time = 0
var attack_damage = 30

# Fireball variables
var fireball_damage = 50
var fireball_cooldown_time = 1000
var next_fireball_time = 0
var fireball_scene = preload("res://Entities/Fireball/Fireball.tscn")

func _physics_process(delta):
	# Get player input
	var direction: Vector2
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# If input is digital, normalize it for diagonala movement
	if abs(direction.x) == 1 and abs(direction.y) == 1:
		direction = direction.normalized()
	
	# Apply movement
	var movement = speed * direction * delta
# warning-ignore:return_value_discarded
	move_and_collide(movement) 
	
	# Animate player based on direction
	if not attack_playing:
		animate_player(direction)
	
	# Decreases speed when simultaneously moving and attacking 
	if attack_playing:
		movement = 0.3 * movement
	
	# Turn RayCast2D toward movement direction
	if direction != Vector2.ZERO:
		$RayCast2D.cast_to = direction.normalized() * 8
	

func animate_player(direction: Vector2):
	if direction != Vector2.ZERO:
		# update last_direction
		last_direction = direction
		
		# Choose walk animation based on movement direction
		var animation = get_animation_direction(last_direction) + "_walk"
		
		# Joystick walking fix
		$Sprite.frames.set_animation_speed(animation, 2 + 8 * direction.length())
		# Play walk animation
		$Sprite.play(animation)
	else:
		# Choose idle animation based on last movement direction and play it
		var animation = get_animation_direction(last_direction) + "_idle"
		$Sprite.play(animation)

func get_animation_direction(direction: Vector2):
	var norm_direction = direction.normalized()
	if norm_direction.y >= 0.707:
		return "down"
	elif norm_direction.y <= -0.707:
		return "up"
	elif norm_direction.x >= 0.707:
		return "right"
	elif norm_direction.x <= -0.707:
		return "left"
	return "down"

func _input(event):
	if event.is_action_pressed("attack"):
		# Check if player can attack
		var now = OS.get_ticks_msec()
		if now >= next_attack_time:
			# What's the target
			var target = $RayCast2D.get_collider()
			if target != null:
				if target.name.find("Skeleton") >= 0:
					# Skeleton hit!
					target.hit(attack_damage) 
			
			# Play attack animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_attack"
			$Sprite.play(animation)
			
			# Add cooldown time to current time
			next_attack_time = now + attack_cooldown_time
	elif event.is_action_pressed("fireball"):
		var now = OS.get_ticks_msec()
		if mana >= 25 and now >= next_fireball_time:
			# Update mana
			mana -= 25
			emit_signal("player_stats_changed", self)
			# Play fireball animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_fireball"
			$Sprite.play(animation)
			# Add cooldown time to current time
			next_fireball_time = now + fireball_cooldown_time
	


func _on_Sprite_animation_finished():
	attack_playing = false
	if $Sprite.animation.ends_with("_fireball"):
		# Instantiate fireball
		var fireball = fireball_scene.instance()
		fireball.attack_damage = fireball_damage
		fireball.direction = last_direction.normalized()
		fireball.position = position + last_direction.normalized() * 4
		get_tree().root.get_node("Root").add_child(fireball)

signal player_stats_changed

func _ready():
	emit_signal("player_stats_changed", self)
	
func _process(delta):
	# Regenerates mana
	var new_mana = min(mana + mana_regen * delta, mana_max)
	if new_mana != mana:
		mana = new_mana
		emit_signal("player_stats_changed", self)
		
	# Regenerates health
	var new_health = min(health + health_regen * delta, health_max)
	if new_health != health:
		health = new_health
		emit_signal("player_stats_changed",self)
	
func hit(damage):
	health -= damage
	emit_signal("player_stats_changed", self)
	if health <= 0:
		set_process(false)
		$AnimationPlayer.play("Game Over")
	else:
		$AnimationPlayer.play("Hit")
