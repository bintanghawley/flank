extends AnimatedSprite2D

func _ready():
	offset = Vector2(0, -0.5)
	frame = 0
	play("default")
	if not animation_finished.is_connected(queue_free):
		animation_finished.connect(queue_free)

