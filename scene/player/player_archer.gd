extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

# =========================
# MOVEMENT SETTINGS
# =========================

const NORMAL_SPEED := 128.0
const SPRINT_SPEED := 220.0

var target_position: Vector2
var is_moving := false

# Arah terakhir karakter
var last_direction := Vector2.DOWN


func _ready():
	target_position = global_position
	play_idle_animation()


func _physics_process(delta):

	# =========================
	# SEDANG BERGERAK
	# =========================

	if is_moving:

		# Tentukan kecepatan
		var current_speed := NORMAL_SPEED

		if Input.is_key_pressed(KEY_SHIFT):
			current_speed = SPRINT_SPEED

		# Arah menuju target
		var direction := global_position.direction_to(target_position)

		# Gerakkan karakter
		global_position = global_position.move_toward(
			target_position,
			current_speed * delta
		)

		# Update arah animasi
		update_direction_animation(direction)

		# Sudah sampai tujuan
		if global_position.distance_to(target_position) < 2.0:

			global_position = target_position
			is_moving = false

			play_idle_animation()

		return


# =========================================================
# INPUT MOUSE
# =========================================================

func _unhandled_input(event):

	# Klik kanan untuk bergerak
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:

			target_position = get_global_mouse_position()

			is_moving = true

			# Tentukan arah awal
			var direction := global_position.direction_to(target_position)

			update_direction_animation(direction)


# =========================================================
# UPDATE ARAH ANIMASI
# =========================================================

func update_direction_animation(direction: Vector2):

	if direction == Vector2.ZERO:
		return

	# Simpan arah terakhir
	last_direction = get_8_direction(direction)

	# Jalankan animasi walk
	play_walk_animation()


# =========================================================
# KONVERSI ARAH MENJADI 8 ARAH
# =========================================================

func get_8_direction(direction: Vector2) -> Vector2:

	var angle := direction.angle()

	# 8 arah
	if angle >= -PI / 8 and angle < PI / 8:
		# KANAN
		return Vector2.RIGHT

	elif angle >= PI / 8 and angle < 3 * PI / 8:
		# KANAN BAWAH ↘
		return Vector2(1, 1)

	elif angle >= 3 * PI / 8 and angle < 5 * PI / 8:
		# BAWAH
		return Vector2.DOWN

	elif angle >= 5 * PI / 8 and angle < 7 * PI / 8:
		# KIRI BAWAH ↙
		return Vector2(-1, 1)

	elif angle >= 7 * PI / 8 or angle < -7 * PI / 8:
		# KIRI
		return Vector2.LEFT

	elif angle >= -7 * PI / 8 and angle < -5 * PI / 8:
		# KIRI ATAS ↖
		return Vector2(-1, -1)

	elif angle >= -5 * PI / 8 and angle < -3 * PI / 8:
		# ATAS
		return Vector2.UP

	else:
		# KANAN ATAS ↗
		return Vector2(1, -1)


# =========================================================
# WALK ANIMATION
# =========================================================

func play_walk_animation():

	# Reset flip
	animated_sprite.flip_h = false


	# =========================
	# ATAS
	# =========================

	if last_direction == Vector2.UP:

		animated_sprite.play("walk_n")


	# =========================
	# BAWAH
	# =========================

	elif last_direction == Vector2.DOWN:

		animated_sprite.play("walk_s")


	# =========================
	# KIRI
	# =========================

	elif last_direction == Vector2.LEFT:

		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = false


	# =========================
	# KANAN
	# =========================

	elif last_direction == Vector2.RIGHT:

		animated_sprite.play("walk_se")
		animated_sprite.flip_h = false


	# =========================
	# DIAGONAL ↖
	# =========================

	elif last_direction == Vector2(-1, -1):

		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = false


	# =========================
	# DIAGONAL ↗
	# =========================

	elif last_direction == Vector2(1, -1):

		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = true


	# =========================
	# DIAGONAL ↙
	# =========================

	elif last_direction == Vector2(-1, 1):

		animated_sprite.play("walk_se")
		animated_sprite.flip_h = true


	# =========================
	# DIAGONAL ↘
	# =========================

	elif last_direction == Vector2(1, 1):

		animated_sprite.play("walk_se")
		animated_sprite.flip_h = false


# =========================================================
# IDLE ANIMATION
# =========================================================

func play_idle_animation():

	# Reset flip
	animated_sprite.flip_h = false


	# =========================
	# ATAS
	# =========================

	if last_direction == Vector2.UP:

		animated_sprite.play("idle_n")


	# =========================
	# BAWAH
	# =========================

	elif last_direction == Vector2.DOWN:

		animated_sprite.play("idle_s")


	# =========================
	# KIRI
	# =========================

	elif last_direction == Vector2.LEFT:

		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = false


	# =========================
	# KANAN
	# =========================

	elif last_direction == Vector2.RIGHT:

		animated_sprite.play("idle_se")
		animated_sprite.flip_h = false


	# =========================
	# DIAGONAL ↖
	# =========================

	elif last_direction == Vector2(-1, -1):

		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = false


	# =========================
	# DIAGONAL ↗
	# =========================

	elif last_direction == Vector2(1, -1):

		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = true


	# =========================
	# DIAGONAL ↙
	# =========================

	elif last_direction == Vector2(-1, 1):

		animated_sprite.play("idle_se")
		animated_sprite.flip_h = true


	# =========================
	# DIAGONAL ↘
	# =========================

	elif last_direction == Vector2(1, 1):

		animated_sprite.play("idle_se")
		animated_sprite.flip_h = false
