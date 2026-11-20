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

@onready var mode_container: VBoxContainer = get_node_or_null("ModeContainer")
@onready var btn_story: Button = get_node_or_null("ModeContainer/BtnStory")
@onready var btn_open_world: Button = get_node_or_null("ModeContainer/BtnOpenWorld")
@onready var btn_back: Button = get_node_or_null("ModeContainer/BtnBack")

@onready var iris_mask: ColorRect = $IrisMask

const GAME_SCENE_PATH := "res://scene/game.tscn"
const GAMEPLAY_HUD_SCENE := preload("res://scene/ui/gameplay/gameplay_hud.tscn")

const BGM_START_MENU = preload("res://assets/audio/bgm/start_menu.ogg")
const SFX_HOVER = preload("res://assets/audio/sfx/ui/ui_hover.wav")
const SFX_CLICK = preload("res://assets/audio/sfx/ui/ui_click.wav")
const SFX_SWORD_RAISE = preload("res://assets/audio/sfx/ui/start_sword_raise.wav")
const SFX_IRIS_CLOSE = preload("res://assets/audio/sfx/ui/transition_iris.wav")
const SWORD_INDICATOR_TEXTURE = preload("res://assets/ui/menus/start_menu/menu_sword_indicator.png")

# Sistem Musik Latar (BGM) Start Menu - Dual-Deck Equal-Power Seamless Crossfade
var _bgm_player_a: AudioStreamPlayer = null
var _bgm_player_b: AudioStreamPlayer = null
var _active_bgm_player: AudioStreamPlayer = null
var _next_bgm_player: AudioStreamPlayer = null
var _bgm_tween: Tween = null
var _is_crossfading: bool = false
const BGM_CROSSFADE_DURATION: float = 2.5
const BGM_BASE_VOLUME_DB: float = -4.0 # Dikalibrasi seimbang saat volume UI 100%

# Kecepatan dasar parallax
const BASE_CLOUD_SPEED: float = 20.0
const BASE_GROUND_SPEED: float = 75.0

var _cloud_speed: float = BASE_CLOUD_SPEED
var _ground_speed: float = BASE_GROUND_SPEED
var _cloud_offset: float = 0.0
var _ground_offset: float = 0.0

var _is_starting: bool = false
var _is_settings_open: bool = false
var _is_credits_open: bool = false
var _is_mode_select_open: bool = false
var _settings_overlay_hud: CanvasLayer = null
var _last_opened_menu_btn: Button = null

const SWORD_INDICATOR_PATH := "res://assets/ui/menus/start_menu/menu_sword_indicator.png"
var _sword_indicator: TextureRect = null
var _sword_indicator_tween: Tween = null

const BASE_FONT_SIZE: int = 32
const SELECTED_FONT_SIZE: int = 38

const BUTTON_TEXTS := {
	"BtnStart": "Mulai Permainan",
	"BtnContinue": "Lanjutkan",
	"BtnSettings": "Pengaturan",
	"BtnCredits": "Kredit",
	"BtnExit": "Keluar",
	"BtnStory": "Mode Cerita",
	"BtnOpenWorld": "Mode Jelajah",
	"BtnBack": "Kembali"
}

var _btn_tweens: Dictionary = {}
var _current_selected: Button = null

func _ready() -> void:
	# Mulai muat scene game utama di background thread sedini mungkin agar tidak ada freeze saat transisi
	if ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH) != ResourceLoader.THREAD_LOAD_IN_PROGRESS and ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH) != ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_request(GAME_SCENE_PATH)

	# Pastikan material circular mask terbuka penuh saat menu muncul
	var mat: ShaderMaterial = iris_mask.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("radius", 1.45)
	
	# Warmup sword_glint di GPU agar tidak stutter saat pertama kali dimainkan
	if sword_glint:
		sword_glint.modulate.a = 0.0
		sword_glint.visible = true
		sword_glint.frame = 0
		if not sword_glint.animation_finished.is_connected(_on_sword_glint_animation_finished):
			sword_glint.animation_finished.connect(_on_sword_glint_animation_finished)

	# Inisialisasi dan putar musik latar (BGM) Start Menu
	_init_and_play_bgm()

	# Warmup tekstur skill Knight agar tidak hitch saat animasi skill pertama kali dipanggil
	if knight and knight.sprite_frames:
		var _warmup_tex = knight.sprite_frames.get_frame_texture("skill_w", 0)

	_settings_overlay_hud = GAMEPLAY_HUD_SCENE.instantiate() as CanvasLayer
	if _settings_overlay_hud:
		add_child(_settings_overlay_hud)
		if _settings_overlay_hud.has_method("enable_start_menu_mode"):
			_settings_overlay_hud.call("enable_start_menu_mode")
		if _settings_overlay_hud.has_signal("start_menu_settings_closed"):
			_settings_overlay_hud.connect("start_menu_settings_closed", _on_settings_closed)
		if _settings_overlay_hud.has_signal("load_game_requested"):
			_settings_overlay_hud.connect("load_game_requested", _on_load_game_requested)
	
	# Pastikan container mode terinisialisasi layout-nya di frame pertama (transparan)
	if is_instance_valid(mode_container):
		mode_container.visible = true
		mode_container.modulate.a = 0.0
		mode_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Tunggu 1 frame agar ukuran container terkalkulasi sempurna
	await get_tree().process_frame

	_setup_sword_indicator()
	
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if not btn:
			btn = get_node_or_null("ModeContainer/" + btn_name)
		if btn:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND as Control.CursorShape
			btn.scale = Vector2.ONE
			btn.add_theme_font_size_override("font_size", BASE_FONT_SIZE)
			btn.mouse_entered.connect(_on_button_hovered.bind(btn))
			btn.focus_entered.connect(_on_button_hovered.bind(btn))
			if btn != btn_start and btn != btn_continue and btn != btn_settings and btn != btn_credits and btn != btn_exit and btn != btn_story and btn != btn_open_world and btn != btn_back:
				btn.pressed.connect(_on_regular_button_clicked)
			_set_button_state(btn, false, true)

	if is_instance_valid(mode_container):
		mode_container.visible = false
	
	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	if btn_story:
		btn_story.pressed.connect(_on_mode_story_pressed)
	if btn_open_world:
		btn_open_world.pressed.connect(_on_mode_open_world_pressed)
	if btn_back:
		btn_back.pressed.connect(_on_mode_back_pressed)
	
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
	_update_bgm_loop()

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
		if is_instance_valid(btn) and btn.get_theme_font_size("font_size") != SELECTED_FONT_SIZE:
			_set_button_state(btn, true)
		return
	
	if not instant and _current_selected != null and _current_selected != btn:
		_play_sfx(SFX_HOVER, -6.0)
	
	# Pastikan seluruh tombol lain di container yang sama dinormalisasi ke ukuran normal
	var parent_container := btn.get_parent()
	if parent_container:
		for sibling in parent_container.get_children():
			if sibling is Button and sibling != btn:
				_set_button_state(sibling, false)
	elif _current_selected and is_instance_valid(_current_selected) and _current_selected != btn:
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
	if not is_instance_valid(btn):
		return

	var base_text: String = BUTTON_TEXTS.get(btn.name, btn.text)
	
	if _btn_tweens.has(btn):
		var old_t: Tween = _btn_tweens[btn]
		if old_t and old_t.is_valid():
			old_t.kill()
	
	btn.text = base_text
	btn.scale = Vector2.ONE
	
	var target_font_size: int = SELECTED_FONT_SIZE if is_selected else BASE_FONT_SIZE
	var target_modulate: Color = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(1.0, 1.0, 1.0, 0.85)
	var cur_font_size: int = btn.get_theme_font_size("font_size")
	if cur_font_size <= 0:
		cur_font_size = BASE_FONT_SIZE
	
	if instant:
		btn.add_theme_font_size_override("font_size", target_font_size)
		btn.modulate = target_modulate
		if is_selected:
			_update_sword_indicator(btn, true)
	else:
		var tween: Tween = create_tween().set_parallel(true)
		_btn_tweens[btn] = tween
		tween.tween_property(btn, "modulate", target_modulate, 0.12)
		if cur_font_size != target_font_size:
			tween.tween_method(
				func(sz: int):
					if is_instance_valid(btn):
						btn.add_theme_font_size_override("font_size", sz)
						if is_selected and _current_selected == btn:
							_update_sword_indicator(btn, true),
				cur_font_size,
				target_font_size,
				0.12
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if is_selected:
			_update_sword_indicator(btn, false)


func _setup_sword_indicator() -> void:
	if not _sword_indicator:
		_sword_indicator = TextureRect.new()
		_sword_indicator.name = "MenuSwordIndicator"
		_sword_indicator.texture = SWORD_INDICATOR_TEXTURE
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
	if font_size <= 0:
		font_size = BASE_FONT_SIZE
	var base_text: String = BUTTON_TEXTS.get(btn.name, btn.text)
	var tw: float = font.get_string_size(base_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	var btn_center_x: float = btn.global_position.x + btn.size.x / 2.0
	var btn_center_y: float = btn.global_position.y + btn.size.y / 2.0
	
	var text_left: float = btn_center_x - tw / 2.0
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
	if _is_starting or _is_settings_open or _is_mode_select_open:
		return
	_play_sfx(SFX_CLICK, -2.0)
	_open_mode_selection()


func _open_mode_selection() -> void:
	if not is_instance_valid(mode_container):
		_launch_game("story")
		return
	_is_mode_select_open = true

	# Sembunyikan pedang sejenak saat transisi antar menu agar tidak melayang di posisi lama
	if _sword_indicator:
		_sword_indicator.visible = false

	# Nonaktifkan interaksi menu utama dan pastikan tombolnya ternormalisasi
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in menu_container.get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			child.focus_mode = Control.FOCUS_NONE
			_set_button_state(child, false, true)

	mode_container.visible = true
	mode_container.modulate.a = 0.0
	mode_container.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in mode_container.get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			child.focus_mode = Control.FOCUS_ALL
			_set_button_state(child, false, true)

	# Tunggu 1 frame agar engine menyelesaikan pass layout dan penempatan posisi tombol
	await get_tree().process_frame
	if not _is_mode_select_open:
		return

	if btn_story and is_instance_valid(btn_story):
		_select_button(btn_story, true)

	var t := create_tween().set_parallel(true)
	t.tween_property(menu_container, "modulate:a", 0.0, 0.15)
	t.tween_property(mode_container, "modulate:a", 1.0, 0.15)
	await t.finished

	if _is_mode_select_open:
		menu_container.visible = false


func _close_mode_selection() -> void:
	if not _is_mode_select_open:
		return
	_is_mode_select_open = false
	_play_sfx(SFX_CLICK, -2.0)

	if _sword_indicator:
		_sword_indicator.visible = false

	if is_instance_valid(mode_container):
		mode_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in mode_container.get_children():
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
				child.focus_mode = Control.FOCUS_NONE
				_set_button_state(child, false, true)

	menu_container.visible = true
	menu_container.modulate.a = 0.0
	menu_container.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in menu_container.get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			child.focus_mode = Control.FOCUS_ALL
			_set_button_state(child, false, true)

	await get_tree().process_frame
	if _is_mode_select_open:
		return

	_select_button(btn_start, true)

	var t := create_tween().set_parallel(true)
	if is_instance_valid(mode_container):
		t.tween_property(mode_container, "modulate:a", 0.0, 0.15)
	t.tween_property(menu_container, "modulate:a", 1.0, 0.15)
	await t.finished

	if not _is_mode_select_open and is_instance_valid(mode_container):
		mode_container.visible = false


func _on_mode_story_pressed() -> void:
	_launch_game("story")


func _on_mode_open_world_pressed() -> void:
	_launch_game("open_world")


func _on_mode_back_pressed() -> void:
	_close_mode_selection()


func _input(event: InputEvent) -> void:
	# Nonaktifkan navigasi fokus menggunakan tombol Tab di Start Menu
	if (event is InputEventKey and event.keycode == KEY_TAB) or event.is_action("ui_focus_next") or event.is_action("ui_focus_prev"):
		get_viewport().set_input_as_handled()
		return


func _unhandled_input(event: InputEvent) -> void:
	if _is_starting or _is_settings_open or _is_credits_open:
		return
	if _is_mode_select_open and event.is_action_pressed("ui_cancel"):
		_close_mode_selection()
		get_viewport().set_input_as_handled()


func _launch_game(mode: String) -> void:
	if _is_starting:
		return
	_is_starting = true
	_play_sfx(SFX_CLICK, -2.0)
	_play_sfx(SFX_SWORD_RAISE, 0.0)

	var game_script = load("res://scene/game.gd")
	if game_script and "selected_game_mode" in game_script:
		game_script.selected_game_mode = mode

	# Pastikan proses background loading game.tscn sudah dimulai
	if ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH) != ResourceLoader.THREAD_LOAD_IN_PROGRESS and ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH) != ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_request(GAME_SCENE_PATH)

	# Matikan interaksi menu
	for container in [menu_container, mode_container]:
		if is_instance_valid(container):
			container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for child in container.get_children():
				if child is Button:
					child.disabled = true
					child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Fade out menu buttons, mode container, logo, dan indikator pedang
	var fade_tween: Tween = create_tween().set_parallel(true)
	if is_instance_valid(menu_container):
		fade_tween.tween_property(menu_container, "modulate:a", 0.0, 0.3)
	if is_instance_valid(mode_container):
		fade_tween.tween_property(mode_container, "modulate:a", 0.0, 0.3)
	if is_instance_valid(logo_rect):
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
	_fade_out_bgm_on_launch(0.85)
	if sword_glint:
		sword_glint.position = sword_tip_pos
		sword_glint.modulate.a = 1.0
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
		sword_glint.modulate.a = 0.0

	# Jeda sejenak saat layar sudah hitam total sebelum masuk ke scene game utama
	await get_tree().create_timer(0.15).timeout
	if ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_game: PackedScene = ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
		if packed_game:
			get_tree().change_scene_to_packed(packed_game)
			return
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_sword_glint_animation_finished() -> void:
	# Setelah intro kilau mencapai puncak, beralih ke animasi shimmer berulang agar terus berkilauan
	if sword_glint and sword_glint.modulate.a > 0.0 and sword_glint.animation == "glint":
		sword_glint.play("shimmer")

func _on_regular_button_clicked() -> void:
	_play_sfx(SFX_CLICK, -2.0)

func _on_settings_pressed() -> void:
	if _is_starting or _is_settings_open or _is_mode_select_open:
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
	if _is_starting or _is_settings_open or _is_mode_select_open:
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
	_is_credits_open = false
	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
			btn.focus_mode = Control.FOCUS_ALL as Control.FocusMode
			_set_button_state(btn, false, true)
	var restore_btn: Button = _last_opened_menu_btn if is_instance_valid(_last_opened_menu_btn) else btn_settings
	_select_button(restore_btn, true)

func _on_load_game_requested(slot_id: int) -> void:
	if _is_starting:
		return
	var game_script = load("res://scene/game.gd")
	if game_script and "pending_load_slot_id" in game_script:
		game_script.pending_load_slot_id = slot_id
	if is_instance_valid(_settings_overlay_hud) and _settings_overlay_hud.has_method("close_start_menu_settings"):
		_settings_overlay_hud.call("close_start_menu_settings")
	_launch_game("story")

func _on_credits_pressed() -> void:
	if _is_starting or _is_settings_open or _is_mode_select_open or _is_credits_open:
		return
	_is_credits_open = true
	_last_opened_menu_btn = btn_credits
	_play_sfx(SFX_CLICK, -2.0)
	if _sword_indicator:
		_sword_indicator.visible = false

	for btn_name in BUTTON_TEXTS:
		var btn: Button = get_node_or_null("MenuContainer/" + btn_name)
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
			btn.focus_mode = Control.FOCUS_NONE as Control.FocusMode
	get_viewport().gui_release_focus()

	if is_instance_valid(_settings_overlay_hud) and _settings_overlay_hud.has_method("open_as_start_menu_credits"):
		_settings_overlay_hud.call("open_as_start_menu_credits")


func _close_credits() -> void:
	if is_instance_valid(_settings_overlay_hud) and _settings_overlay_hud.has_method("close_start_menu_settings"):
		_settings_overlay_hud.call("close_start_menu_settings")
	else:
		_on_settings_closed()


func _on_exit_pressed() -> void:
	if _is_starting or _is_settings_open or _is_mode_select_open:
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


# ==========================================
# BGM AUTO-FADE NATURAL LOOPING SYSTEM
# ==========================================

func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, &"Master")


func _init_and_play_bgm(fade_in_at_start: bool = false) -> void:
	if not BGM_START_MENU:
		return
	_ensure_music_bus()
	
	if not is_instance_valid(_bgm_player_a):
		_bgm_player_a = AudioStreamPlayer.new()
		_bgm_player_a.name = "BgmPlayerA"
		_bgm_player_a.stream = BGM_START_MENU
		_bgm_player_a.bus = &"Music"
		_bgm_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_bgm_player_a)
	
	if not is_instance_valid(_bgm_player_b):
		_bgm_player_b = AudioStreamPlayer.new()
		_bgm_player_b.name = "BgmPlayerB"
		_bgm_player_b.stream = BGM_START_MENU
		_bgm_player_b.bus = &"Music"
		_bgm_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_bgm_player_b)
	
	if _bgm_player_a.stream is AudioStreamOggVorbis:
		(_bgm_player_a.stream as AudioStreamOggVorbis).loop = false
	if _bgm_player_b.stream is AudioStreamOggVorbis:
		(_bgm_player_b.stream as AudioStreamOggVorbis).loop = false
	
	_active_bgm_player = _bgm_player_a
	_next_bgm_player = _bgm_player_b
	_next_bgm_player.stop()
	_next_bgm_player.volume_db = -80.0
	_is_crossfading = false
	
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	
	if fade_in_at_start:
		_active_bgm_player.volume_db = -80.0
		_active_bgm_player.play(0.0)
		var base_linear := db_to_linear(BGM_BASE_VOLUME_DB)
		_bgm_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_bgm_tween.tween_method(func(val: float):
			if is_instance_valid(_active_bgm_player) and _active_bgm_player.playing:
				_active_bgm_player.volume_db = linear_to_db(maxf(val, 0.0001) * base_linear) if val > 0.001 else -80.0
		, 0.0, 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		# Bagian awal langsung memutar di volume penuh tanpa fade-in sesuai permintaan
		_active_bgm_player.volume_db = BGM_BASE_VOLUME_DB
		_active_bgm_player.play(0.0)


func _update_bgm_loop() -> void:
	if _is_crossfading or not is_instance_valid(_active_bgm_player) or not _active_bgm_player.playing:
		return
	if not _active_bgm_player.stream:
		return
	
	var total_len: float = _active_bgm_player.stream.get_length()
	if total_len <= BGM_CROSSFADE_DURATION + 0.5:
		return
	
	var pos: float = _active_bgm_player.get_playback_position()
	# Hanya picu crossfade di paruh kedua lagu ketika tepat mendekati akhir lagu
	if pos > total_len * 0.5:
		var time_left: float = total_len - pos
		if time_left <= BGM_CROSSFADE_DURATION:
			_start_bgm_crossfade(time_left)


func _start_bgm_crossfade(time_left: float) -> void:
	if _is_crossfading or not is_instance_valid(_active_bgm_player) or not is_instance_valid(_next_bgm_player):
		return
	_is_crossfading = true
	
	var outgoing := _active_bgm_player
	var incoming := _next_bgm_player
	var fade_time := clampf(time_left, 1.0, BGM_CROSSFADE_DURATION)
	var base_linear := db_to_linear(BGM_BASE_VOLUME_DB)
	
	incoming.volume_db = -80.0
	incoming.play(0.0)
	
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Equal-power crossfade (cosinus/sinus) menjaga amplitudo perseptual tetap konstan (bebas dip/jeda)
	_bgm_tween.tween_method(func(progress: float):
		if is_instance_valid(outgoing) and outgoing.playing:
			var out_factor: float = cos(progress * 0.5 * PI)
			outgoing.volume_db = linear_to_db(maxf(out_factor * base_linear, 0.0001)) if out_factor > 0.001 else -80.0
		if is_instance_valid(incoming) and incoming.playing:
			var in_factor: float = sin(progress * 0.5 * PI)
			incoming.volume_db = linear_to_db(maxf(in_factor * base_linear, 0.0001)) if in_factor > 0.001 else -80.0
	, 0.0, 1.0, fade_time)
	
	_bgm_tween.tween_callback(func():
		if is_instance_valid(outgoing):
			outgoing.stop()
			outgoing.volume_db = -80.0
		if is_instance_valid(incoming):
			incoming.volume_db = BGM_BASE_VOLUME_DB
		_active_bgm_player = incoming
		_next_bgm_player = outgoing
		_is_crossfading = false
	)


func _fade_out_bgm_on_launch(duration: float = 0.85) -> void:
	_is_crossfading = false
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	if is_instance_valid(_bgm_player_a) and _bgm_player_a.playing:
		t.tween_property(_bgm_player_a, "volume_db", -80.0, duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_bgm_player_b) and _bgm_player_b.playing:
		t.tween_property(_bgm_player_b, "volume_db", -80.0, duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func():
		if is_instance_valid(_bgm_player_a):
			_bgm_player_a.stop()
		if is_instance_valid(_bgm_player_b):
			_bgm_player_b.stop()
	)
