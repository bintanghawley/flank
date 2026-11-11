extends AnimatedSprite2D

func _ready() -> void:
	play("default")
	if not animation_finished.is_connected(queue_free):
		animation_finished.connect(queue_free)
