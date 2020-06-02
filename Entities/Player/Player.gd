extends KinematicBody2D

# Player movement speed
export var speed = 75
var last_direction = Vector2(0, 1)
var attack_playing = false

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
	move_and_collide(movement) 
	
	# Animate player based on direction
	if not attack_playing:
		animate_player(direction)
	
	# Decreases speed when simultaneously moving and attacking 
	if attack_playing:
		movement = 0.3 * movement

func animate_player(direction: Vector2):
	if direction != Vector2.ZERO:
		# update last_direction
		last_direction = direction
		
		# Choose walk animation based on movement direction
		var animation = get_animation_direction(last_direction) + "_walk"
		
		# Joystick walking fix
		$Sprite.frames.set_animation_speed(animation, 2 + 8 * direction.length())
		# Plat walk animation
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
		attack_playing = true
		var animation = get_animation_direction(last_direction) + "_attack"
		$Sprite.play(animation)
	elif event.is_action_pressed("fireball"):
		attack_playing = true
		var animation = get_animation_direction(last_direction) + "_fireball"
		$Sprite.play(animation)


func _on_Sprite_animation_finished():
	attack_playing = false
