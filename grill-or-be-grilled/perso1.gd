extends CharacterBody2D

# Configurações de física (ajustáveis pelo painel Inspetor)
@export var speed: float = 250.0
@export var jump_velocity: float = -420.0

# Puxa o valor da gravidade padrão configurado no projeto da Godot
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. Aplica gravidade contínua quando o personagem não estiver no chão
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Lida com o pulo (tecla Espaço ou seta para cima por padrão na ação ui_accept)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Lê o movimento horizontal do teclado (Setas Esquerda/Direita ou Teclas A/D)
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * speed
		# Inverte o sprite horizontalmente para olhar na direção que anda
		$Sprite2D.flip_h = (direction < 0)
	else:
		# Desaceleração suave ao soltar as teclas
		velocity.x = move_toward(velocity.x, 0, speed)

	# 4. Executa o cálculo de física contra chão e paredes
	move_and_slide()
