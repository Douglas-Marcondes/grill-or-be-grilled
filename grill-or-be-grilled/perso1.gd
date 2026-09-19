extends CharacterBody2D

@export var speed: float = 250.0
@export var jump_velocity: float = -600.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Aplica gravidade no ar
	if not is_on_floor():
		velocity.y += gravity * delta

	# Pulo com a SETA PARA CIMA quando pisando no chão
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	# Movimento horizontal com as setas esquerda e direita
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = direction * speed
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = (direction < 0)
		elif has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
