extends CanvasLayer

signal pause_menu_requested
signal skill_activated(hero_index: int)
signal leader_switch_requested(hero_index: int)

@onready var root_control: Control = $RootControl

# Top-Left
@onready var btn_pause_menu: TextureButton = $RootControl/BtnPauseMenu
@onready var quest_container: HBoxContainer = $RootControl/QuestContainer
@onready var quest_title: Label = $RootControl/QuestContainer/TextContainer/QuestTitle
@onready var quest_objective: Label = $RootControl/QuestContainer/TextContainer/QuestObjective

# Top-Center Location
@onready var location_banner: TextureRect = $RootControl/LocationBanner
@onready var location_label: Label = $RootControl/LocationBanner/LocationLabel

# Bottom-Left Controls Prompt
@onready var controls_prompt: VBoxContainer = $RootControl/ControlsPrompt

# Bottom-Left Party HUD
@onready var party_container: HBoxContainer = $RootControl/PartyContainer

# Bottom-Right Skill Bar
@onready var skill_container: HBoxContainer = $RootControl/SkillContainer

# Speech Bubble
@onready var speech_bubble: Control = $RootControl/SpeechBubble
@onready var bubble_label: Label = $RootControl/SpeechBubble/BubblePanel/BubbleLabel

# Pause Popup Overlay
@onready var pause_overlay: ColorRect = $RootControl/PauseOverlay
@onready var btn_resume: Button = $RootControl/PauseOverlay/PausePanel/VBox/BtnResume
@onready var btn_main_menu: Button = $RootControl/PauseOverlay/PausePanel/VBox/BtnMainMenu

var party_members: Array[CharacterBody2D] = []
var active_leader_index: int = 0
var active_leader_node: CharacterBody2D = null

# Card node references for the 4 heroes
# Order in cards: Arthur (0), Magnus (3), Anastasya (2), Hellene (1)
var hero_card_map: Dictionary = {} # hero_index -> Card node
var hero_skill_map: Dictionary = {} # hero_index -> Skill slot node

var _bubble_tween: Tween = null


func _ready() -> void:
	layer = 15 # Di atas elemen world game, di bawah TransitionLayer (layer 100)
	speech_bubble.visible = false
	speech_bubble.modulate.a = 0.0
	pause_overlay.visible = false

	# Connect Pause Menu Buttons
	if btn_pause_menu:
		btn_pause_menu.pressed.connect(_on_btn_pause_menu_pressed)
	if btn_resume:
		btn_resume.pressed.connect(_on_btn_resume_pressed)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_btn_main_menu_pressed)

	_setup_skill_buttons()
	_setup_party_card_clicks()


func setup(members: Array[CharacterBody2D], current_leader_idx: int) -> void:
	party_members = members
	active_leader_index = current_leader_idx
	if current_leader_idx >= 0 and current_leader_idx < party_members.size():
		active_leader_node = party_members[current_leader_idx]

	update_party_hud()
	update_leader_indicator()


func set_active_leader(index: int) -> void:
	active_leader_index = index
	if index >= 0 and index < party_members.size():
		active_leader_node = party_members[index]
	update_leader_indicator()


func _process(_delta: float) -> void:
	_update_hp_bars()
	_update_skill_cooldowns()
	_update_speech_bubble_position()


func _setup_skill_buttons() -> void:
	# Skill Slot 0 (Arthur / Knight) -> Hotkey 1
	# Skill Slot 1 (Hellene / Bandit) -> Hotkey 2
	# Skill Slot 2 (Anastasya / Archer) -> Hotkey 3
	# Skill Slot 3 (Magnus / Mage) -> Hotkey 4
	var slots := [
		$RootControl/SkillContainer/SkillSlot1,
		$RootControl/SkillContainer/SkillSlot2,
		$RootControl/SkillContainer/SkillSlot3,
		$RootControl/SkillContainer/SkillSlot4
	]
	var hero_indices := [0, 1, 2, 3] # Arthur, Hellene, Anastasya, Magnus

	for i in range(slots.size()):
		var slot = slots[i]
		var h_idx: int = hero_indices[i]
		hero_skill_map[h_idx] = slot
		var btn := slot.get_node_or_null("SkillBtn") as TextureButton
		if btn:
			btn.pressed.connect(func(): trigger_skill_slot(h_idx))


func _setup_party_card_clicks() -> void:
	# Card Arthur: Hero index 0
	# Card Magnus: Hero index 3
	# Card Anastasya: Hero index 2
	# Card Hellene: Hero index 1
	var card_arthur := $RootControl/PartyContainer/CardArthur
	var card_magnus := $RootControl/PartyContainer/CardMagnus
	var card_anastasya := $RootControl/PartyContainer/CardAnastasya
	var card_hellene := $RootControl/PartyContainer/CardHellene

	hero_card_map[0] = card_arthur
	hero_card_map[3] = card_magnus
	hero_card_map[2] = card_anastasya
	hero_card_map[1] = card_hellene

	_connect_card_click(card_arthur, 0)
	_connect_card_click(card_magnus, 3)
	_connect_card_click(card_anastasya, 2)
	_connect_card_click(card_hellene, 1)


func _connect_card_click(card: Control, hero_idx: int) -> void:
	if not card:
		return
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			leader_switch_requested.emit(hero_idx)
	)


func trigger_skill_slot(hero_idx: int) -> void:
	skill_activated.emit(hero_idx)


func update_party_hud() -> void:
	for h_idx in hero_card_map.keys():
		var card = hero_card_map[h_idx]
		if not is_instance_valid(card):
			continue
		if h_idx < party_members.size() and is_instance_valid(party_members[h_idx]):
			var hero = party_members[h_idx]
			var hp_bar = card.get_node_or_null("LifeBar") as TextureProgressBar
			if hp_bar:
				var max_hp = hero.get("max_health") if "max_health" in hero else 10
				var cur_hp = hero.get("current_health") if "current_health" in hero else max_hp
				hp_bar.max_value = max_hp
				hp_bar.value = cur_hp


func _update_hp_bars() -> void:
	for h_idx in hero_card_map.keys():
		var card = hero_card_map[h_idx]
		if not is_instance_valid(card):
			continue
		if h_idx < party_members.size() and is_instance_valid(party_members[h_idx]):
			var hero = party_members[h_idx]
			var hp_bar = card.get_node_or_null("LifeBar") as TextureProgressBar
			if hp_bar:
				var cur_hp = hero.get("current_health") if "current_health" in hero else 0
				hp_bar.value = cur_hp


func _update_skill_cooldowns() -> void:
	for h_idx in hero_skill_map.keys():
		var slot = hero_skill_map[h_idx]
		if not is_instance_valid(slot):
			continue
		var cd_overlay = slot.find_child("CooldownOverlay", true, false) as ColorRect
		var cd_label = slot.find_child("CooldownLabel", true, false) as Label
		if not cd_overlay:
			continue

		if h_idx < party_members.size() and is_instance_valid(party_members[h_idx]):
			var hero = party_members[h_idx]
			var cd: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
			if cd > 0.05:
				cd_overlay.visible = true
				if cd_label:
					cd_label.visible = true
					cd_label.text = str(ceil(cd))
			else:
				cd_overlay.visible = false
				if cd_label:
					cd_label.visible = false
		else:
			cd_overlay.visible = false
			if cd_label:
				cd_label.visible = false


func update_leader_indicator() -> void:
	for h_idx in hero_card_map.keys():
		var card = hero_card_map[h_idx]
		if not is_instance_valid(card):
			continue
		var indicator = card.get_node_or_null("LeaderIndicator") as Control
		if indicator:
			indicator.visible = (h_idx == active_leader_index)


# =========================================================
# SPEECH BUBBLE POPUP ("Serang" / "Ikuti")
# =========================================================

func show_speech_bubble(text: String) -> void:
	if not speech_bubble or not bubble_label:
		return

	bubble_label.text = text
	speech_bubble.visible = true
	_update_speech_bubble_position()

	if _bubble_tween and _bubble_tween.is_valid():
		_bubble_tween.kill()

	speech_bubble.scale = Vector2(0.6, 0.6)
	speech_bubble.modulate.a = 0.0

	_bubble_tween = create_tween()
	# Pop in
	_bubble_tween.parallel().tween_property(speech_bubble, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble_tween.parallel().tween_property(speech_bubble, "modulate:a", 1.0, 0.12)
	# Tahan 1.2 detik
	_bubble_tween.tween_interval(1.2)
	# Fade out
	_bubble_tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.25)
	_bubble_tween.tween_callback(func(): speech_bubble.visible = false)


func _update_speech_bubble_position() -> void:
	if not speech_bubble.visible or not is_instance_valid(active_leader_node):
		return

	var vp := get_viewport()
	if not vp:
		return
	var canvas_transform := vp.get_canvas_transform()
	var screen_pos := canvas_transform * active_leader_node.global_position
	# Posisikan bubble tepat di atas kepala karakter leader (offset Y sekitar -96px, X sesuai pivot tail)
	speech_bubble.position = screen_pos + Vector2(-28, -96)


# =========================================================
# PAUSE MENU HANDLERS
# =========================================================

func _on_btn_pause_menu_pressed() -> void:
	toggle_pause_menu()


func toggle_pause_menu() -> void:
	var is_paused := not pause_overlay.visible
	pause_overlay.visible = is_paused
	get_tree().paused = is_paused


func _on_btn_resume_pressed() -> void:
	pause_overlay.visible = false
	get_tree().paused = false


func _on_btn_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/ui/menus/start_menu.tscn")

