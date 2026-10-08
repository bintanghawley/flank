extends AnimatedSprite2D

func _ready():
	play("default")
	if not animation_finished.is_connected(queue_free):
		animation_finished.connect(queue_free)
