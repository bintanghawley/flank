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
@onready var sword_glint: AnimatedSprite2D = $Characters/SwordGlint

@onready var logo_rect: TextureRect = $LogoRect
@onready var menu_container: VBoxContainer = $MenuContainer
@onready var btn_start: Button = $MenuContainer/BtnStart
@onready var btn_continue: Button = $MenuContainer/BtnContinue
@onready var btn_settings: Button = $MenuContainer/BtnSettings
@onready var btn_credits: Button = $MenuContainer/BtnCredits
@onready var btn_exit: Button = $MenuContainer/BtnExit

@onready var iris_mask: ColorRect = $IrisMask

const GAME_SCENE_PATH := "res://scene/game.tscn"
const GAMEPLAY_HUD_SCENE := preload("res://scene/ui/gameplay/gameplay_hud.tscn")

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
var _is_settings_open: bool = false
var _settings_overlay_hud: CanvasLayer = null
var _last_opened_menu_btn: Button = null

const SWORD_INDICATOR_PATH := "res://assets/ui/menus/start_menu/menu_sword_indicator.png"
var _sword_indicator: TextureRect = null
var _sword_indicator_tween: Tween = null

const BUTTON_TEXTS := {
	"BtnStart": "Mulai Permainan",
	"BtnContinue": "Lanjutkan",
	"BtnSettings": "Pengaturan",
	"BtnCredits": "Kredit",
	"BtnExit": "Keluar"
}

var _btn_tweens: Dictionary = {}
var _current_selected: Button = null

func _ready() -> void:
	# Pastikan material circular mask terbuka penuh saat menu muncul
	var mat: ShaderMaterial = iris_mask.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("radius", 1.45)
	
	if sword_glint:
		sword_glint.visible = false
		if not sword_glint.animation_finished.is_connected(_on_sword_glint_animation_finished):
			sword_glint.animation_finished.connect(_on_sword_glint_animation_finished)

	_settings_overlay_hud = GAMEPLAY_HUD_SCENE.instantiate() as CanvasLayer
	if _settings_overlay_hud:
		add_child(_settings_overlay_hud)
		if _settings_overlay_hud.has_method("enable_start_menu_mode"):
			_settings_overlay_hud.call("enable_start_menu_mode")
		if _settings_overlay_hud.has_signal("start_menu_settings_closed"):
			_settings_overlay_hud.connect("start_menu_settings_closed", _on_settings_closed)
		if _settings_overlay_hud.has_signal("load_game_requested"):
			_settings_overlay_hud.connect("load_game_requested", _on_load_game_requested)
	
	# Tunggu 1 frame agar ukuran container terkalkulasi sempurna
	await get_tree().process_frame
	
	_setup_sword_indicator()
	
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND as Control.CursorShape
			btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0)
			btn.mouse_entered.connect(_on_button_hovered.bind(btn))
			btn.focus_entered.connect(_on_button_hovered.bind(btn))
			if btn != btn_start and btn != btn_continue and btn != btn_settings and btn != btn_exit:
				btn.pressed.connect(_on_regular_button_clicked)
			_set_button_state(btn, false, true)
	
	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	get_viewport().size_changed.connect(func():
		if _current_selected and is_instance_valid(_current_selected) and not _is_settings_open and not _is_starting:
			_update_sword_indicator(_current_selected, true)
	)
	
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
	if _is_starting or _is_settings_open:
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
	if not _is_starting and not _is_settings_open:
		_select_button(btn)

func _set_button_state(btn: Button, is_selected: bool, instant: bool = false) -> void:
	var base_text: String = BUTTON_TEXTS.get(btn.name, btn.text)
	
	if _btn_tweens.has(btn):
		var old_t: Tween = _btn_tweens[btn]
		if old_t and old_t.is_valid():
			old_t.kill()
	
	btn.text = base_text
	btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0)
	
	var target_scale: Vector2
	var target_modulate: Color
	
	if is_selected:
		target_scale = Vector2(1.18, 1.18)
		target_modulate = Color(1.0, 1.0, 1.0, 1.0)
		_update_sword_indicator(btn, instant)
	else:
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


func _setup_sword_indicator() -> void:
	if not _sword_indicator:
		_sword_indicator = TextureRect.new()
		_sword_indicator.name = "MenuSwordIndicator"
		if ResourceLoader.exists(SWORD_INDICATOR_PATH):
			_sword_indicator.texture = load(SWORD_INDICATOR_PATH)
		_sword_indicator.texture_filter = Control.TEXTURE_FILTER_NEAREST as Control.TextureFilter
		_sword_indicator.stretch_mode = TextureRect.STRETCH_KEEP
		_sword_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
		_sword_indicator.scale = Vector2(2.0, 2.0)
		_sword_indicator.visible = false
		add_child(_sword_indicator)
		if is_instance_valid(iris_mask):
			move_child(_sword_indicator, iris_mask.get_index())


func _get_sword_target_pos(btn: Button) -> Vector2:
	if not is_instance_valid(btn):
		return Vector2.ZERO
	var font: Font = btn.get_theme_font("font")
	var font_size: int = btn.get_theme_font_size("font_size")
	var base_text: String = BUTTON_TEXTS.get(btn.name, btn.text)
	var tw: float = font.get_string_size(base_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	var btn_center_x: float = btn.global_position.x + btn.size.x / 2.0
	var btn_center_y: float = btn.global_position.y + btn.size.y / 2.0
	
	# Skala visual tombol yang sedang aktif adalah 1.18
	var text_left: float = btn_center_x - (tw * 1.18) / 2.0
	var sword_w: float = 24.0 * 2.0
	var sword_h: float = 9.0 * 2.0
	if _sword_indicator and _sword_indicator.texture:
		sword_w = _sword_indicator.texture.get_width() * _sword_indicator.scale.x
		sword_h = _sword_indicator.texture.get_height() * _sword_indicator.scale.y
		
	return Vector2(text_left - sword_w - 10.0, btn_center_y - sword_h / 2.0)


func _update_sword_indicator(btn: Button, instant: bool = false) -> void:
	if not _sword_indicator or not is_instance_valid(btn):
		return
	if _is_settings_open or _is_starting:
		_sword_indicator.visible = false
		return
		
	var target_pos := _get_sword_target_pos(btn)
	_sword_indicator.visible = true
	_sword_indicator.modulate.a = 1.0
	
	if _sword_indicator_tween and _sword_indicator_tween.is_valid():
		_sword_indicator_tween.kill()
		
	if instant:
		_sword_indicator.global_position = target_pos
	else:
		_sword_indicator_tween = create_tween().set_parallel(true)
		_sword_indicator_tween.tween_property(_sword_indicator, "global_position", target_pos, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_start_pressed() -> void:
	if _is_starting or _is_settings_open:
		return
	_is_starting = true
	_play_sfx(SFX_CLICK, -2.0)
	_play_sfx(SFX_SWORD_RAISE, 0.0)
	
	# Matikan interaksi menu
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
	
	# Fade out menu buttons, logo, dan indikator pedang
	var fade_tween: Tween = create_tween().set_parallel(true)
	fade_tween.tween_property(menu_container, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(logo_rect, "modulate:a", 0.0, 0.3)
	if _sword_indicator:
		fade_tween.tween_property(_sword_indicator, "modulate:a", 0.0, 0.3)
	
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
	
	# Mulai efek Circular Mask (Iris Wipe) menutup ke ujung pedang bersamaan dengan kilau senjata
	_play_sfx(SFX_IRIS_CLOSE, -2.0)
	if sword_glint:
		sword_glint.position = sword_tip_pos
		sword_glint.visible = true
		sword_glint.frame = 0
		sword_glint.play("glint")

	if mat:
		var iris_tween: Tween = create_tween()
		iris_tween.tween_property(mat, "shader_parameter/radius", 0.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await iris_tween.finished
	else:
		await get_tree().create_timer(0.85).timeout
	
	if sword_glint:
		sword_glint.stop()
		sword_glint.visible = false
	
	# Jeda sejenak saat layar sudah hitam total sebelum masuk ke scene game utama
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_sword_glint_animation_finished() -> void:
	# Setelah intro kilau mencapai puncak, beralih ke animasi shimmer berulang agar terus berkilauan
	if sword_glint and sword_glint.visible and sword_glint.animation == "glint":
		sword_glint.play("shimmer")

func _on_regular_button_clicked() -> void:
	_play_sfx(SFX_CLICK, -2.0)

func _on_settings_pressed() -> void:
	if _is_starting or _is_settings_open:
		return
	_is_settings_open = true
	_last_opened_menu_btn = btn_settings
	_play_sfx(SFX_CLICK, -2.0)
	if _sword_indicator:
		_sword_indicator.visible = false

	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
			btn.focus_mode = Control.FOCUS_NONE as Control.FocusMode
	get_viewport().gui_release_focus()

	if is_instance_valid(_settings_overlay_hud) and _settings_overlay_hud.has_method("open_as_start_menu_settings"):
		_settings_overlay_hud.call("open_as_start_menu_settings")

func _on_continue_pressed() -> void:
	if _is_starting or _is_settings_open:
		return
	_is_settings_open = true
	_last_opened_menu_btn = btn_continue
	_play_sfx(SFX_CLICK, -2.0)
	if _sword_indicator:
		_sword_indicator.visible = false

	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
			btn.focus_mode = Control.FOCUS_NONE as Control.FocusMode
	get_viewport().gui_release_focus()

	if is_instance_valid(_settings_overlay_hud) and _settings_overlay_hud.has_method("open_as_start_menu_save_load"):
		_settings_overlay_hud.call("open_as_start_menu_save_load")

func _on_settings_closed() -> void:
	_is_settings_open = false
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
			btn.focus_mode = Control.FOCUS_ALL as Control.FocusMode
	var restore_btn: Button = _last_opened_menu_btn if is_instance_valid(_last_opened_menu_btn) else btn_settings
	_select_button(restore_btn, true)

func _on_load_game_requested(slot_id: int) -> void:
	if _is_starting:
		return
	var game_script = load(GAME_SCENE_PATH.replace(".tscn", ".gd"))
	if game_script and "pending_load_slot_id" in game_script:
		game_script.pending_load_slot_id = slot_id
	if is_instance_valid(_settings_overlay_hud) and _settings_overlay_hud.has_method("close_start_menu_settings"):
		_settings_overlay_hud.call("close_start_menu_settings")
	_on_start_pressed()

func _on_exit_pressed() -> void:
	if _is_starting or _is_settings_open:
		return
	_play_sfx(SFX_CLICK, -2.0)
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()

func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	if AudioServer.get_bus_index("SFX") != -1:
		player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
