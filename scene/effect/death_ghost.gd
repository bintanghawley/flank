extends AnimatedSprite2D

@export var float_distance: float = 85.0
@export var float_duration: float = 1.3


func _ready() -> void:
	play("default")
	z_index = 25

	# Animasi melayang naik sederhana dan mulus
	var tween := create_tween()
	tween.set_parallel(true)

	# Melayang naik ke atas
	tween.tween_property(self, "position:y", position.y - float_distance, float_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# Memudar perlahan di paruh kedua durasi
	var fade_tween := create_tween()
	fade_tween.tween_interval(float_duration * 0.45)
	fade_tween.tween_property(self, "modulate:a", 0.0, float_duration * 0.55)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# Hapus otomatis setelah selesai
	tween.chain().tween_callback(queue_free)
