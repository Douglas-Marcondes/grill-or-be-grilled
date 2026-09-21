extends CharacterBody2D

# Configurações de movimento físico
@export var speed: float = 3000.0
@export var jump_velocity: float = -450.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Dano causado pelo golpe
@export var dano_ataque: int = 1

# Nós de referência
@onready var pivo_arma: Node2D = get_node_or_null("PivoArma")
@onready var sprite_arma: Sprite2D = get_node_or_null("PivoArma/Sprite2D")
@onready var hitbox_col: CollisionShape2D = get_node_or_null("PivoArma/Hitbox/CollisionShape2D")

# Localiza Sprite2D ou AnimatedSprite2D automaticamente
@onready var sprite_player: Node2D = get_node_or_null("Sprite2D") if has_node("Sprite2D") else get_node_or_null("AnimatedSprite2D")

# Variáveis de controle de ataque
var esta_atacando: bool = false

# Lista de armas para trocar (adicione texturas pelo Inspetor)
@export var lista_armas: Array[Texture2D] = []
var indice_arma_atual: int = 0

func _ready() -> void:
	# Garante que a arma comece escondida e desativada
	if pivo_arma:
		pivo_arma.visible = false
	if hitbox_col:
		hitbox_col.disabled = true
	
	if lista_armas.size() > 0 and sprite_arma:
		sprite_arma.texture = lista_armas[0]

func _physics_process(delta: float) -> void:
	# 1. Aplica gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Pulo configurado na SETINHA PARA CIMA ("ui_up")
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not esta_atacando:
		velocity.y = jump_velocity

	# 3. Movimento horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0 and not esta_atacando:
		velocity.x = direction * speed
		
		# Vira o zumbi e a arma na direção certa
		if sprite_player and "flip_h" in sprite_player:
			sprite_player.flip_h = (direction < 0)
		if pivo_arma:
			pivo_arma.scale.x = -1.0 if direction < 0 else 1.0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ataque") and not esta_atacando:
		executar_ataque()
		
	if event.is_action_pressed("trocar_arma") and not esta_atacando:
		trocar_arma()

# Garante referência direta à Hitbox (Area2D)
@onready var hitbox: Area2D = get_node_or_null("PivoArma/Hitbox")

# Lista de inimigos atingidos no golpe atual (evita dano duplicado no mesmo swing)
var alvos_atingidos: Array = []

func executar_ataque() -> void:
	if not pivo_arma or not hitbox_col or not hitbox:
		return
		
	esta_atacando = true
	alvos_atingidos.clear() # Limpa o histórico para permitir acertar no novo golpe
	
	pivo_arma.visible = true
	
	# Usamos set_deferred para ligar/desligar a física com segurança
	hitbox.set_deferred("monitoring", true)
	hitbox_col.set_deferred("disabled", false)
	
	var tween := create_tween()
	pivo_arma.rotation_degrees = -45.0
	tween.tween_property(pivo_arma, "rotation_degrees", 65.0, 0.12)
	
	await tween.finished
	
	# Desativa a detecção ao terminar o corte
	hitbox.set_deferred("monitoring", false)
	hitbox_col.set_deferred("disabled", true)
	pivo_arma.visible = false
	pivo_arma.rotation_degrees = 0.0
	esta_atacando = false

func trocar_arma() -> void:
	if lista_armas.size() <= 1 or not sprite_arma:
		return
		
	indice_arma_atual = (indice_arma_atual + 1) % lista_armas.size()
	sprite_arma.texture = lista_armas[indice_arma_atual]

# Função chamada automaticamente quando a lâmina acerta qualquer Area2D
func _on_hitbox_area_entered(area: Area2D) -> void:
	# Verifica se acertou numa área de dano
	if area.name == "Hurtbox":
		var alvo = area.get_parent()
		
		# Se o nó pai direto não tiver o método, procura no dono da cena
		if not alvo.has_method("levar_dano") and area.owner:
			alvo = area.owner
			
		if alvo and alvo.has_method("levar_dano"):
			print("Espada acertou no alvo válido!")
			alvo.levar_dano(dano_ataque)
		else:
			print("Hurtbox atingida, mas não encontrou 'levar_dano' no pai:", alvo.name)
