extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Destroy bullet after 2 seconds if it doesn't hit anything
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Bullets ignore the player
	if body is CharacterBody2D and body.name == "Player":
		return

func _on_area_entered(area: Area2D) -> void:
	# If we hit a zombie (Area2D), that's handled in the Zombie script (Coin.gd)
	# or we can handle it here if the zombie has a specific method
	if area.has_method("die"):
		area.die()
		queue_free()
