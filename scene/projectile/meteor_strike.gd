extends Node2D

const IMPACT_SCENE = preload("res://scene/projectile/meteor_impact.tscn")
const SFX_METEOR_FALL = preload("res://assets/audio/sfx/characters/mage/mage_meteor_fall.wav")

@export var speed: float = 750.0
var target_position: Vector2 = Vector2.ZERO
var caster: CharacterBody2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("default")
	play_sfx(SFX_METEOR_FALL, 0.0)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream or not get_parent():
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.global_position = global_position
	get_parent().add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func setup(target_pos: Vector2, p_caster: CharacterBody2D = null, custom_spawn_pos: Vector2 = Vector2.ZERO) -> void:
	target_position = target_pos
	caster = p_caster
	if custom_spawn_pos != Vector2.ZERO:
		global_position = custom_spawn_pos
	else:
		global_position = target_position + Vector2(0.0, -450.0)

	var move_dir := (target_position - global_position).normalized()
	if move_dir != Vector2.ZERO:
		rotation = move_dir.angle() - (PI / 2.0)


func _physics_process(delta: float) -> void:
	var move_dir := (target_position - global_position).normalized()
	if move_dir != Vector2.ZERO:
		rotation = move_dir.angle() - (PI / 2.0)

	var dist := global_position.distance_to(target_position)
	var step := speed * delta
	if dist <= step or dist <= 15.0:
		global_position = target_position
		trigger_impact()
	else:
		global_position = global_position.move_toward(target_position, step)


func trigger_impact() -> void:
	var impact = IMPACT_SCENE.instantiate()
	impact.global_position = target_position
	if "caster" in impact:
		impact.caster = caster
	if get_parent():
		get_parent().add_child(impact)
	else:
		get_tree().current_scene.add_child(impact)
	queue_free()

