extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

# =========================
# MOVEMENT SETTINGS
# =========================

const TILE_SIZE := 32.0
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

		var current_speed := NORMAL_SPEED

		# Tahan SHIFT untuk sprint
		if Input.is_key_pressed(KEY_SHIFT):
			current_speed = SPRINT_SPEED

		global_position = global_position.move_toward(
			target_position,
			current_speed * delta
		)

		# Sudah sampai tile tujuan
		if global_position.is_equal_approx(target_position):

			global_position = target_position
			is_moving = false

			play_idle_animation()

		return


	# =========================
	# INPUT
	# =========================

	var direction := Vector2.ZERO

	var up := Input.is_key_pressed(KEY_W)
	var down := Input.is_key_pressed(KEY_S)
	var left := Input.is_key_pressed(KEY_A)
	var right := Input.is_key_pressed(KEY_D)


	# =========================
	# DIAGONAL
	# =========================

	if up and left:
		direction = Vector2(-1, -1)

	elif up and right:
		direction = Vector2(1, -1)

	elif down and left:
		direction = Vector2(-1, 1)

	elif down and right:
		direction = Vector2(1, 1)


	# =========================
	# 4 ARAH
	# =========================

	elif up:
		direction = Vector2.UP

	elif down:
		direction = Vector2.DOWN

	elif left:
		direction = Vector2.LEFT

	elif right:
		direction = Vector2.RIGHT


	# =========================
	# MULAI BERGERAK
	# =========================

	if direction != Vector2.ZERO:

		last_direction = direction

		# Set target 1 tile
		target_position = global_position + direction.normalized() * TILE_SIZE

		is_moving = true

		play_walk_animation()


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
