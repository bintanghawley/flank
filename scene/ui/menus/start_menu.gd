extends Control

@onready var sky_container: Control = $SkyContainer
@onready var bg_sky_1: TextureRect = $SkyContainer/BgSky1
@onready var bg_sky_2: TextureRect = $SkyContainer/BgSky2
@onready var bg_sky_3: TextureRect = $SkyContainer/BgSky3

@onready var grass_container: Control = $GrassContainer
@onready var bg_grass_1: TextureRect = $GrassContainer/BgGrass1
@onready var bg_grass_2: TextureRect = $GrassContainer/BgGrass2
@onready var bg_grass_3: TextureRect = $GrassContainer/BgGrass3

@onready var characters: Node2D = $Characters
@onready var knight: AnimatedSprite2D = $Characters/Knight
@onready var mage: AnimatedSprite2D = $Characters/Mage
@onready var archer: AnimatedSprite2D = $Characters/Archer
@onready var bandit: AnimatedSprite2D = $Characters/Bandit

@onready var logo_rect: TextureRect = $LogoRect
@onready var menu_container: VBoxContainer = $MenuContainer
@onready var btn_start: Button = $MenuContainer/BtnStart
@onready var btn_continue: Button = $MenuContainer/BtnContinue
@onready var btn_settings: Button = $MenuContainer/BtnSettings
@onready var btn_credits: Button = $MenuContainer/BtnCredits
@onready var btn_exit: Button = $MenuContainer/BtnExit

@onready var iris_mask: ColorRect = $IrisMask

const GAME_SCENE_PATH := "res://scene/game.tscn"

const SFX_HOVER = preload("res://assets/audio/sfx/ui/ui_hover.wav")
const SFX_CLICK = preload("res://assets/audio/sfx/ui/ui_click.wav")
const SFX_SWORD_RAISE = preload("res://assets/audio/sfx/ui/start_sword_raise.wav")
const SFX_IRIS_CLOSE = preload("res://assets/audio/sfx/ui/transition_iris.wav")

# Kecepatan dasar parallax
const BASE_CLOUD_SPEED: float = 20.0
const BASE_GROUND_SPEED: float = 75.0

var _cloud_speed: float = BASE_CLOUD_SPEED
var _ground_speed: float = BASE_GROUND_SPEED
var _cloud_offset: float = 0.0
var _ground_offset: float = 0.0

var _is_starting: bool = false

const BUTTON_TEXTS := {
	"BtnStart": "Mulai Permainan",
	"BtnContinue": "Lanjutkan",
	"BtnSettings": "Pengaturan",
	"BtnCredits": "Credits",
	"BtnExit": "Exit"
}

var _btn_tweens: Dictionary = {}
var _current_selected: Button = null

func _ready() -> void:
	# Pastikan material circular mask terbuka penuh saat menu muncul
	var mat: ShaderMaterial = iris_mask.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("radius", 1.45)
	
	# Tunggu 1 frame agar ukuran container terkalkulasi sempurna
	await get_tree().process_frame
	
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0)
			btn.mouse_entered.connect(_on_button_hovered.bind(btn))
			btn.focus_entered.connect(_on_button_hovered.bind(btn))
			if btn != btn_start:
				btn.pressed.connect(_on_regular_button_clicked)
			_set_button_state(btn, false, true)
	
	btn_start.pressed.connect(_on_start_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	# Set pilihan awal ke tombol Mulai Permainan
	_select_button(btn_start, true)

func _process(delta: float) -> void:
	if _is_starting:
		# Melambat hingga berhenti saat animasi transisi dimulai
		_ground_speed = move_toward(_ground_speed, 0.0, 160.0 * delta)
		_cloud_speed = move_toward(_cloud_speed, 0.0, 40.0 * delta)
	
	_update_parallax_movement(delta)

func _update_parallax_movement(delta: float) -> void:
	var w: float = size.x if size.x > 0.0 else 1152.0
	var h: float = size.y if size.y > 0.0 else 648.0
	
	# Update pergerakan awan (lapisan latar belakang jauh)
	if bg_sky_1 and bg_sky_2 and bg_sky_3:
		bg_sky_1.size = Vector2(w, h)
		bg_sky_2.size = Vector2(w, h)
		bg_sky_3.size = Vector2(w, h)
		
		_cloud_offset = fposmod(_cloud_offset + _cloud_speed * delta, w)
		bg_sky_1.position.x = _cloud_offset - w
		bg_sky_2.position.x = _cloud_offset
		bg_sky_3.position.x = _cloud_offset + w
	
	# Update pergerakan tanah / rumput (lapisan pijakan karakter)
	if bg_grass_1 and bg_grass_2 and bg_grass_3:
		bg_grass_1.size = Vector2(w, h)
		bg_grass_2.size = Vector2(w, h)
		bg_grass_3.size = Vector2(w, h)
		
		_ground_offset = fposmod(_ground_offset + _ground_speed * delta, w)
		bg_grass_1.position.x = _ground_offset - w
		bg_grass_2.position.x = _ground_offset
		bg_grass_3.position.x = _ground_offset + w

func _select_button(btn: Button, instant: bool = false) -> void:
	if _is_starting:
		return
	if _current_selected == btn and not instant:
		return
	
	if not instant and _current_selected != null and _current_selected != btn:
		_play_sfx(SFX_HOVER, -6.0)
	
	if _current_selected and is_instance_valid(_current_selected) and _current_selected != btn:
		_set_button_state(_current_selected, false)
	
	_current_selected = btn
	if _current_selected and is_instance_valid(_current_selected):
		_set_button_state(_current_selected, true, instant)
		if not _current_selected.has_focus():
			_current_selected.grab_focus()

func _on_button_hovered(btn: Button) -> void:
	if not _is_starting:
		_select_button(btn)

func _set_button_state(btn: Button, is_selected: bool, instant: bool = false) -> void:
	var base_text: String = BUTTON_TEXTS.get(btn.name, btn.text)
	
	if _btn_tweens.has(btn):
		var old_t: Tween = _btn_tweens[btn]
		if old_t and old_t.is_valid():
			old_t.kill()
	
	btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0)
	
	var target_scale: Vector2
	var target_modulate: Color
	
	if is_selected:
		btn.text = "▶ " + base_text + " ◀"
		btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0)
		target_scale = Vector2(1.18, 1.18)
		target_modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		btn.text = base_text
		btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0)
		target_scale = Vector2(1.0, 1.0)
		target_modulate = Color(1.0, 1.0, 1.0, 0.85)
	
	if instant:
		btn.scale = target_scale
		btn.modulate = target_modulate
	else:
		var tween: Tween = create_tween().set_parallel(true)
		_btn_tweens[btn] = tween
		tween.tween_property(btn, "scale", target_scale, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "modulate", target_modulate, 0.12)

func _on_start_pressed() -> void:
	if _is_starting:
		return
	_is_starting = true
	_play_sfx(SFX_CLICK, -2.0)
	_play_sfx(SFX_SWORD_RAISE, 0.0)
	
	# Matikan interaksi menu
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Fade out menu buttons dan logo
	var fade_tween: Tween = create_tween().set_parallel(true)
	fade_tween.tween_property(menu_container, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(logo_rect, "modulate:a", 0.0, 0.3)
	
	# Ubah animasi kawan-kawan party menjadi idle saat Knight cast skill
	mage.play("idle_w")
	archer.play("idle_w")
	bandit.play("idle_w")
	
	# Knight memainkan animasi mengangkat pedang ke atas
	knight.play("skill_w")
	
	# Hitung koordinat UV ujung pedang Knight yang terangkat
	var screen_w: float = size.x if size.x > 0.0 else 1152.0
	var screen_h: float = size.y if size.y > 0.0 else 648.0
	# Knight berada di Vector2(820, 353). Ujung pedang terangkat ada di offset (-17 px X, -36 px Y)
	var sword_tip_pos: Vector2 = knight.position + Vector2(-17.0, -36.0)
	var sword_uv: Vector2 = Vector2(sword_tip_pos.x / screen_w, sword_tip_pos.y / screen_h)
	
	var mat: ShaderMaterial = iris_mask.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("center", sword_uv)
		mat.set_shader_parameter("radius", 1.45)
	
	# Tunggu jeda agar pedang terangkat penuh ke atas (sekitar frame 5-6 pada 10 FPS = ~0.4 detik)
	await get_tree().create_timer(0.4).timeout
	
	# Mulai efek Circular Mask (Iris Wipe) menutup ke ujung pedang
	_play_sfx(SFX_IRIS_CLOSE, -2.0)
	if mat:
		var iris_tween: Tween = create_tween()
		iris_tween.tween_property(mat, "shader_parameter/radius", 0.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await iris_tween.finished
	else:
		await get_tree().create_timer(0.85).timeout
	
	# Jeda sejenak saat layar sudah hitam total sebelum masuk ke scene game utama
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_regular_button_clicked() -> void:
	_play_sfx(SFX_CLICK, -2.0)

func _on_exit_pressed() -> void:
	_play_sfx(SFX_CLICK, -2.0)
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()

func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
