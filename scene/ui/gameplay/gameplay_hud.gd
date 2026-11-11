extends CanvasLayer

signal pause_menu_requested
signal skill_activated(hero_index: int)
signal leader_switch_requested(hero_index: int)
signal party_reordered(new_party_order: Array[CharacterBody2D])
signal item_used(item_data: Dictionary)
signal quest_selected(quest_data: Dictionary)
signal quest_tracked(quest_data: Dictionary)
signal quest_navigation_requested(quest_data: Dictionary)
signal settings_audio_changed(master: int, music: int, sfx: int, dialog: int)
signal save_game_requested(slot_id: int)
signal load_game_requested(slot_id: int)
signal return_to_title_requested
signal start_menu_settings_closed

@onready var root_control: Control = $RootControl

# Top-Left
@onready var btn_pause_menu: TextureButton = $RootControl/BtnPauseMenu
@onready var quest_header: Label = $RootControl/QuestHeader
@onready var quest_container: HBoxContainer = $RootControl/QuestContainer
@onready var quest_title: Label = $RootControl/QuestContainer/TextContainer/QuestTitle
@onready var quest_objective: Label = $RootControl/QuestContainer/TextContainer/QuestObjective

# Top-Center Location
@onready var location_banner: TextureRect = $RootControl/LocationBanner
@onready var location_label: Label = $RootControl/LocationBanner/LocationRow/LocationLabel

# Top-Right Inventory, Info & Settings Shortcuts
@onready var btn_hud_inventory: TextureButton = $RootControl/BtnHudInventory
@onready var btn_hud_info: TextureButton = $RootControl/BtnHudInfo
@onready var btn_hud_settings: TextureButton = $RootControl/BtnHudSettings

# Bottom-Left Controls Prompt
@onready var controls_prompt: VBoxContainer = $RootControl/ControlsPrompt

# Bottom-Left Party HUD
@onready var party_container: HBoxContainer = $RootControl/PartyContainer

# Bottom-Right Skill Bar
@onready var skill_container: HBoxContainer = $RootControl/SkillContainer

# Speech Bubble
@onready var speech_bubble: Control = $RootControl/SpeechBubble
@onready var bubble_label: Label = $RootControl/SpeechBubble/BubblePanel/BubbleLabel

# Pause Popup Overlay & Book Menu
@onready var pause_overlay: ColorRect = $RootControl/PauseOverlay
@onready var drag_ghost: Control = $RootControl/PauseOverlay/DragGhost
@onready var drag_ghost_portrait: TextureRect = $RootControl/PauseOverlay/DragGhost/Frame/Portrait
@onready var pause_book_root: Control = $RootControl/PauseOverlay/PauseBookRoot
@onready var pause_header_banner: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/HeaderContainer/HeaderBanner
@onready var pause_header_title: Label = $RootControl/PauseOverlay/PauseBookRoot/HeaderContainer/HeaderTitle
@onready var pause_book_bg: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/BookBg
@onready var pause_red_bookmark: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/RedBookmark
@onready var tabs_container: HBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/TabsContainer
@onready var btn_close_book: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/BtnCloseBook

# Tab Buttons
@onready var tab_btn_inventory: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/TabsContainer/Tab0
@onready var tab_btn_journal: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/TabsContainer/Tab1
@onready var tab_btn_info: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/TabsContainer/Tab2
@onready var tab_btn_settings: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/TabsContainer/Tab3
@onready var tab_btn_credits: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/TabsContainer/Tab4

# Pages
@onready var page_info: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi
@onready var page_inventory: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory
@onready var page_journal: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal
@onready var journal_scrollbar: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/LeftPage/JournalScrollBar
@onready var journal_scroll_container: ScrollContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/LeftPage/ScrollContainer
@onready var main_quest_container: VBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/LeftPage/ScrollContainer/QuestListVBox/MainQuestList
@onready var world_quest_container: VBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/LeftPage/ScrollContainer/QuestListVBox/WorldQuestList

@onready var journal_detail_scroll: ScrollContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/RightPage/DetailsScroll
@onready var journal_detail_title: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/RightPage/DetailsScroll/DetailsVBox/TitleLabel
@onready var journal_detail_location: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/RightPage/DetailsScroll/DetailsVBox/LocationRow/LocationLabel
@onready var journal_detail_objective: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/RightPage/DetailsScroll/DetailsVBox/ObjectiveBox/ObjectiveContent/ObjectiveLabel
@onready var journal_detail_desc: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/RightPage/DetailsScroll/DetailsVBox/DescLabel
@onready var journal_btn_navigasi: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageJournal/RightPage/BtnNavigasi
@onready var page_settings: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings
@onready var settings_btn_audio: NinePatchRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/LeftPage/SubmenuList/BtnSubmenuAudio
@onready var settings_btn_controls: NinePatchRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/LeftPage/SubmenuList/BtnSubmenuControls
@onready var settings_btn_save_load: NinePatchRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/LeftPage/SubmenuList/BtnSubmenuSaveLoad
@onready var settings_btn_title: NinePatchRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/LeftPage/SubmenuList/BtnSubmenuTitle

@onready var submenu_audio: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio
@onready var submenu_controls: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuControls
@onready var submenu_save_load: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad

@onready var slider_ctrl_master: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowMaster/ControlsRow/SliderMaster
@onready var slider_val_master: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowMaster/ControlsRow/ValBox/ValLabel
@onready var slider_ctrl_music: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowMusic/ControlsRow/SliderMusic
@onready var slider_val_music: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowMusic/ControlsRow/ValBox/ValLabel
@onready var slider_ctrl_sfx: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowSfx/ControlsRow/SliderSfx
@onready var slider_val_sfx: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowSfx/ControlsRow/ValBox/ValLabel
@onready var slider_ctrl_dialog: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowDialog/ControlsRow/SliderDialog
@onready var slider_val_dialog: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuAudio/AudioRows/RowDialog/ControlsRow/ValBox/ValLabel
@onready var control_rows_container: VBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuControls/ControlRows
@onready var page_credits: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageCredits

# Save & Load UI (SubmenuSaveLoad)
@onready var save_slot_rows: Array = [
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SlotsContainer/SlotRow1,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SlotsContainer/SlotRow2,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SlotsContainer/SlotRow3
]
@onready var save_load_scrollbar: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/DecorativeScrollbar
@onready var btn_simpan_box: NinePatchRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/BottomRow/BtnSimpan
@onready var btn_simpan_click: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/BottomRow/BtnSimpan/ClickBtn
@onready var btn_muat_box: NinePatchRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/BottomRow/BtnMuat
@onready var btn_muat_click: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/BottomRow/BtnMuat/ClickBtn
@onready var enter_hint: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/BottomRow/EnterHint
@onready var save_feedback_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SaveFeedback
@onready var save_confirm_modal: Control = $RootControl/PauseOverlay/SaveConfirmModal
@onready var save_confirm_dimmer: ColorRect = $RootControl/PauseOverlay/SaveConfirmModal/Dimmer
@onready var save_confirm_dialog_box: NinePatchRect = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox
@onready var save_confirm_msg: Label = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/DialogMessage
@onready var btn_confirm_yes_lbl: Label = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnYes/Label
@onready var btn_confirm_yes: TextureButton = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnYes/ClickBtn
@onready var btn_confirm_timpa_box: NinePatchRect = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnTimpa
@onready var btn_confirm_timpa: TextureButton = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnTimpa/ClickBtn
@onready var btn_confirm_no_lbl: Label = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnNo/Label
@onready var btn_confirm_no: TextureButton = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnNo/ClickBtn

# Biodata UI (Left Page)
@onready var bio_char_sprite: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/CharSprite
@onready var btn_prev_char: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/NameRow/BtnPrev
@onready var btn_next_char: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/NameRow/BtnNext
@onready var bio_name_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/NameRow/NameBox/NameLabel
@onready var bio_val_nama: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/BioFields/RowNama/Val
@onready var bio_val_gelar: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/BioFields/RowGelar/Val
@onready var bio_val_ras: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/BioFields/RowRas/Val
@onready var bio_val_bday: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/LeftPage/BioFields/RowBday/Val

# Stat & Skill UI (Right Page)
@onready var stat_val_hp: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/StatFields/RowHP/Val
@onready var stat_val_atk: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/StatFields/RowATK/Val
@onready var skill_preview_icon: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/SkillBox/Icon
@onready var skill_preview_desc: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/SkillBox/Desc

# Pause Party Slots (Right Page Bottom)
@onready var pause_party_slots: Array = [
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/PartySlots/Slot0,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/PartySlots/Slot1,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/PartySlots/Slot2,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInformasi/RightPage/PartySlots/Slot3
]

# Inventory Page UI (PageInventory)
@onready var inv_btn_prev_cat: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/CategoryRow/BtnPrevCategory
@onready var inv_btn_next_cat: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/CategoryRow/BtnNextCategory
@onready var inv_cat_btns: Array = [
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/CategoryRow/CatBtn0,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/CategoryRow/CatBtn1,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/CategoryRow/CatBtn2,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/CategoryRow/CatBtn3
]
@onready var inv_scrollbar: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/InventoryScrollBar
@onready var inv_scroll_container: ScrollContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/ScrollContainer
@onready var inv_item_grid: GridContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/ScrollContainer/ItemGrid
@onready var inv_btn_gunakan: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/BottomRow/BtnGunakan
@onready var inv_label_capacity: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/BottomRow/CapacityContainer/LabelCapacity

# Inventory Detail UI (Right Page)
@onready var inv_detail_icon: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailBox/DetailIcon
@onready var inv_detail_name: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailName
@onready var inv_detail_count_container: HBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailCountContainer
@onready var inv_detail_count_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailCountContainer/DetailCountLabel
@onready var inv_detail_desc: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailDesc

var party_members: Array[CharacterBody2D] = []
var active_leader_index: int = 0
var active_leader_node: CharacterBody2D = null

# Card node references for the 4 heroes in gameplay HUD
var hero_card_map: Dictionary = {} # hero_type -> Card node
var hero_skill_map: Dictionary = {} # hero_type -> Skill slot node
var skill_slot_nodes: Array = [] # Ordered SkillSlot1..SkillSlot4 nodes matching party_members[0..3]

var _bubble_tween: Tween = null

const LOCATION_BANNER_SLIDE_OFFSET: float = 52.0
const LOCATION_BANNER_IN_DURATION: float = 0.45
const LOCATION_BANNER_FADE_IN_DURATION: float = 0.38
const LOCATION_BANNER_HOLD_DURATION: float = 2.2
const LOCATION_BANNER_OUT_DURATION: float = 0.45
const LOCATION_BANNER_FADE_OUT_DURATION: float = 0.38
var _location_banner_rest_y: float = 32.0
var _location_banner_tween: Tween = null

# Pause Menu State
var current_tab_index: int = 2 # 0: Inventory, 1: Journal, 2: Informasi, 3: Settings, 4: Credits
var current_viewed_party_slot: int = 0 # Currently viewed character index in live party_members

# Textures
var tab_active_texture: Texture2D
var tab_inactive_texture: Texture2D
var hero_atlas_sprites: Dictionary = {}
var hero_anim_frames: Dictionary = {}
var _current_bio_hero_type: int = 0
var _bio_anim_timer: float = 0.0
var _bio_anim_frame: int = -1
const BIO_WALK_ANIM_FPS: float = 10.0
const BIO_CHAR_PIXEL_SCALE: float = 5.4
const BIO_CHAR_CENTER: Vector2 = Vector2(156.0, 120.0)
var hero_skill_icons: Dictionary = {}
var hero_portraits: Dictionary = {}
var is_start_menu_mode: bool = false
var _outside_pause_pressed: bool = false
var _outside_modal_pressed: bool = false
var cat_btn_normal_tex: Texture2D
var cat_btn_selected_tex: Texture2D
var item_slot_tex: Texture2D
var item_selected_tex: Texture2D
var quest_btn_panel_tex: Texture2D

# Journal State
var quest_list: Array[Dictionary] = []
var selected_quest_id: String = ""
var tracked_quest_id: String = ""
var _is_dragging_journal_slider: bool = false
var _journal_slider_drag_offset: float = 0.0

# Inventory State
var inventory_items: Array[Dictionary] = []
var current_inventory_category: int = 0 # 0: Consumable, 1: Key, 2: Collectible, 3: Notes
var selected_item_category_index: int = 0
var _filtered_inventory_items: Array[Dictionary] = []
var _is_dragging_inv_slider: bool = false
var _inv_slider_drag_offset: float = 0.0

const VSCROLL_INSET_TOP: float = 4.0
const VSCROLL_INSET_BOTTOM: float = 4.0
const VSCROLL_GRABBER_H: float = 14.0

var v_scroll_track_tex: ImageTexture = null
var v_scroll_grabber_tex: ImageTexture = null

const H_GRABBER_B64: String = "AAAAAAAAAAAAAAAAAAAAAFY4NP9WODT/Vjg0/1Y4NP9WODT/Vjg0/1Y4NP9WODT/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVjg0/1Y4NP/r2sr/69rK/+vayv/r2sr/69rK/+vayv/r2sr/69rK/1Y4NP9WODT/AAAAAAAAAAAAAAAAVjg0/+vayv/r2sr/xrCb/8awm//GsJv/xrCb/8awm//GsJv/xrCb/8awm/+chnb/nIZ2/1Y4NP8AAAAAAAAAAFY4NP/r2sr/xrCb/8awm/94YFT/xrCb/8awm//GsJv/eGBU/8awm/+chnb/nIZ2/5yGdv9WODT/AAAAAFY4NP/r2sr/69rK/8awm//GsJv/eGBU/8awm//GsJv/xrCb/3hgVP/GsJv/nIZ2/5yGdv+chnb/nIZ2/1Y4NP9WODT/69rK/+vayv/GsJv/xrCb/3hgVP/GsJv/xrCb/8awm/94YFT/xrCb/5yGdv+chnb/nIZ2/5yGdv9WODT/Vjg0/+vayv/r2sr/xrCb/8awm/94YFT/xrCb/8awm//GsJv/eGBU/8awm/+chnb/nIZ2/5yGdv+chnb/Vjg0/1Y4NP/r2sr/69rK/8awm//GsJv/eGBU/8awm//GsJv/xrCb/3hgVP/GsJv/nIZ2/5yGdv+chnb/nIZ2/1Y4NP9WODT/69rK/+vayv/GsJv/xrCb/3hgVP/GsJv/xrCb/8awm/94YFT/xrCb/5yGdv+chnb/nIZ2/5yGdv9WODT/Vjg0/+vayv/r2sr/xrCb/8awm/94YFT/xrCb/8awm//GsJv/eGBU/8awm/+chnb/nIZ2/5yGdv+chnb/Vjg0/1Y4NP/r2sr/69rK/8awm//GsJv/eGBU/8awm//GsJv/xrCb/3hgVP/GsJv/nIZ2/5yGdv+chnb/nIZ2/1Y4NP9WODT/69rK/+vayv/GsJv/xrCb/3hgVP/GsJv/xrCb/8awm/94YFT/xrCb/5yGdv+chnb/nIZ2/5yGdv9WODT/AAAAAFY4NP/r2sr/xrCb/8awm/94YFT/xrCb/8awm//GsJv/eGBU/8awm/+chnb/nIZ2/5yGdv9WODT/AAAAAAAAAABWODT/nIZ2/5yGdv/GsJv/xrCb/8awm//GsJv/xrCb/8awm//GsJv/xrCb/5yGdv+chnb/Vjg0/wAAAAAAAAAAAAAAAFY4NP9WODT/nIZ2/5yGdv+chnb/nIZ2/5yGdv+chnb/nIZ2/5yGdv9WODT/Vjg0/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFY4NP9WODT/Vjg0/1Y4NP9WODT/Vjg0/1Y4NP9WODT/AAAAAAAAAAAAAAAAAAAAAA=="

# Settings UI & Audio State
const SETTINGS_FILE_PATH := "user://settings.cfg"
var h_grabber_tex: ImageTexture = null
var submenu_btn_selected_tex: Texture2D = null
var submenu_btn_normal_tex: Texture2D = null
var slot_card_selected_tex: Texture2D = null
var active_settings_submenu: int = 0
var audio_settings: Dictionary = {
	"master": 65,
	"music": 50,
	"sfx": 50,
	"dialog": 50
}
var _active_dragging_slider: String = ""

# Settings Controls State
const CONTROL_ACTION_ORDER: Array[String] = [
	"switch_character",
	"party_attack",
	"party_follow",
	"skill_1",
	"skill_2",
	"skill_3",
	"skill_4",
	"interact",
	"skip",
	"open_journal"
]

const CONTROL_ACTION_INFO: Dictionary = {
	"switch_character": { "name": "Beralih Karakter", "default_key": KEY_Q, "node_name": "RowSwitch" },
	"party_attack":     { "name": "Serang",            "default_key": KEY_V, "node_name": "RowAttack" },
	"party_follow":     { "name": "Ikuti",             "default_key": KEY_C, "node_name": "RowFollow" },
	"skill_1":          { "name": "Skill 1",           "default_key": KEY_1, "node_name": "RowSkill1" },
	"skill_2":          { "name": "Skill 2",           "default_key": KEY_2, "node_name": "RowSkill2" },
	"skill_3":          { "name": "Skill 3",           "default_key": KEY_3, "node_name": "RowSkill3" },
	"skill_4":          { "name": "Skill 4",           "default_key": KEY_4, "node_name": "RowSkill4" },
	"interact":         { "name": "Interaksi",         "default_key": KEY_E, "node_name": "RowInteract" },
	"skip":             { "name": "Skip",              "default_key": KEY_SPACE, "node_name": "RowSkip" },
	"open_journal":     { "name": "Jurnal",            "default_key": KEY_J, "node_name": "RowJournal" }
}

const ACTION_BUTTONS_SHEET: Texture2D = preload("res://assets/ui/icons/actions/action_buttons.png")

const CONTROL_KEYCAP_RECTS: Dictionary = {
	KEY_A: Rect2(0, 208, 16, 16), KEY_B: Rect2(16, 208, 16, 16), KEY_C: Rect2(32, 208, 16, 16),
	KEY_D: Rect2(48, 208, 16, 16), KEY_E: Rect2(64, 208, 16, 16), KEY_F: Rect2(80, 208, 16, 16),
	KEY_G: Rect2(96, 208, 16, 16),
	KEY_H: Rect2(0, 224, 16, 16), KEY_I: Rect2(16, 224, 16, 16), KEY_J: Rect2(32, 224, 16, 16),
	KEY_K: Rect2(48, 224, 16, 16), KEY_L: Rect2(64, 224, 16, 16), KEY_M: Rect2(80, 224, 16, 16),
	KEY_N: Rect2(96, 224, 16, 16),
	KEY_O: Rect2(0, 240, 16, 16), KEY_P: Rect2(16, 240, 16, 16), KEY_Q: Rect2(32, 240, 16, 16),
	KEY_R: Rect2(48, 240, 16, 16), KEY_S: Rect2(64, 240, 16, 16), KEY_T: Rect2(80, 240, 16, 16),
	KEY_U: Rect2(96, 240, 16, 16),
	KEY_V: Rect2(0, 256, 16, 16), KEY_W: Rect2(16, 256, 16, 16), KEY_X: Rect2(32, 256, 16, 16),
	KEY_Z: Rect2(48, 256, 16, 16),
	KEY_PLUS: Rect2(48, 272, 16, 16), KEY_MINUS: Rect2(64, 272, 16, 16), KEY_EQUAL: Rect2(80, 272, 16, 16),
	KEY_1: Rect2(0, 288, 16, 16), KEY_2: Rect2(16, 288, 16, 16), KEY_3: Rect2(32, 288, 16, 16),
	KEY_4: Rect2(48, 288, 16, 16), KEY_5: Rect2(64, 288, 16, 16), KEY_6: Rect2(80, 288, 16, 16),
	KEY_7: Rect2(96, 288, 16, 16), KEY_8: Rect2(112, 288, 16, 16), KEY_9: Rect2(128, 288, 16, 16),
	KEY_0: Rect2(144, 288, 16, 16),
	KEY_F1: Rect2(0, 304, 16, 16), KEY_F2: Rect2(16, 304, 16, 16), KEY_F3: Rect2(32, 304, 16, 16),
	KEY_F4: Rect2(48, 304, 16, 16), KEY_F5: Rect2(64, 304, 16, 16), KEY_F6: Rect2(80, 304, 16, 16),
	KEY_F7: Rect2(96, 304, 16, 16), KEY_F8: Rect2(112, 304, 16, 16), KEY_F9: Rect2(128, 304, 16, 16),
	KEY_LEFT: Rect2(0, 176, 16, 16), KEY_UP: Rect2(16, 176, 16, 16),
	KEY_DOWN: Rect2(0, 192, 16, 16), KEY_RIGHT: Rect2(16, 192, 16, 16),
	KEY_SPACE: Rect2(0, 336, 29, 16), KEY_SHIFT: Rect2(0, 352, 29, 16), KEY_TAB: Rect2(0, 368, 21, 16),
	KEY_CTRL: Rect2(0, 384, 25, 16), KEY_ALT: Rect2(0, 400, 21, 16), KEY_ENTER: Rect2(0, 416, 29, 16),
	KEY_KP_ENTER: Rect2(0, 416, 29, 16), KEY_BACKSPACE: Rect2(0, 432, 25, 16)
}

var control_bindings: Dictionary = {}
var _rebind_action_id: String = ""
var _control_row_nodes: Dictionary = {}
var _keycap_blank_tex: Texture2D = null
var _control_keycap_cache: Dictionary = {}

# Save & Load State (TASK 05C)
const DEFAULT_THUMB_B64: String = "iVBORw0KGgoAAAANSUhEUgAAAC4AAAAcCAIAAACRaRrGAAAGq0lEQVR4nK1X245dRxGtqu7et3PzXJTgXBARUUwwCBEki0hI4CCEeOCBT0HihUf+APEd+QSLKO9cEgJSgkMc2YwvcWLPnJlz2d1dVah6n7GdYcbjB9dTnz29e69etWpVDcaDf6ACACjC0xeKtj5rMewkBQLMqSenBPLxn997cPu/yHzp8ne2v/1yypkAnCCUF0+Ed/bX5xaKsGbVUFWkwIJZNSmKaua07jNBVVXaZ8RTPuqfJxAABQTvlURAHIpzwYEjkLaqAQwHEaF3IHoKFON2c8o5Cy3rsxabnacx/yiGJJ4VPnqB5xhKjgWUERQUBIVJVIEJwiM0ZwDypIRid1HSpy+U7IyzFsNOsp9CIIQMKIrKKEqWj8eEDWj+jz/vGVFNMKry9IWq8XfWYtgJIEUvYqw8oYiC85zwSgnRQ1IFYKeJHKIjIZ8E1epUke1UysafIigb9RZZNzgMCXoCAXAVSC9qZ6AgAyA6REAWh4Rq54GKkntCPQKQANT3mAIIOhWERBSD3c8TGdWWGcku6+YNNg0MVz8+JmBlv1gFsjB6tA2ChKDOkDzaaJbzNVHZ86J4NRoB0f/l6PMg7MFSy0jsHCKSQkMeC/9KLJZ1UaDUZy3sD0GCPocL7WxntF1DVVMNxtD5udjUnRrJjxP0p8+uVbxs4oJUDYUafkHwIRRB2iXtDcsWVqtSEeXepETsLvDke9+8/MPXf7AVZkFCiuJNu+fhECMMgYqEERAVxU/auuZeO4cgQSAIGgcOD+KRfVHBFV8v+oRuZ0yFFS5QPDuZI7UuNGZlxes3STknHnFhErUQAb/mhYdVbuLi8HAqblp1q369VmhmzTplWcVpN8s5L/qIqNnLmvt1TkmBFDvXBXSR42q5nFLreoTkwD8DlEE4ppJCIXpQ8VHzUhKz+NA0kcJhzpFjoP0cq7pt3BgPGmIdU+gmVUz3URyx1gE1s8bsFY1LdYEJJAALkIA7N0Nf+yVIDOCZBcnV6hrCLmb54gBFQ0ezetLASFZ668NbacXNeDp7cVxdVKJAwuDNRCUr4RDH/eMZ/ANQyj4pjliyj1C1rd9tdmj9MBzyJFK9d3BleqkZTz7d//KL/Xod4d5/7v3r3X8u5msBnybp13+42s06AlHmAN47MqYdiFNGBp+N8xNVe1oUkz5elCZ6e++2v3BfdyY786h+xXdu3Hn3+rV21Nzrj+Ztu1pL/zBdffvno2br5s27H9z+MCrvtCNK2OuiqqvGB52Xo0gZMzsGsXnlhCROzY8Wdz7uqdTUY7/8+MFLl1/+7P1PXO/GdCHsxhs3r3fTZouEFw/7xfIXv3x71G1f/+Tmt+KLD7fvL9JchFNODCoCITlkCYoBUJWd98pWbUWNYq5kXjDUv6XGVGQFrFbJm1IGMUd1nh6sPv/g+t61T/N+VohXf/XWC9/dnu52C5j/PX6099Xd3/7x94tVarrZzmvbP/r+61iFmlC9CS1nQfWozgmVyjnpKE8qZ1DT8bxXuBuaYnFUT95X3XTVry6OtpfLw/kq7n+1Lw3/e+/GHt+hSX3lN+984/KltUgEWafDWZuQs2QhAnUezHTIbq6egJw4tCd50xnOlG1hDKm0h+NG4ciPXtjiubvb3/cVjncnbqepOsLFglLbbncwCUs6CpN2VFe0DuSjWCvKTE5QqNCum+mQ7LrPUkFqsEuzOsaG6Jzzt8KtIzr4ye/e6fveB/rbR39txrXu4muvvjmejZpJfRj3+/glmaHrQWYCxYA5QFSBFGdkUij1mQHYMqByLqDSe8p8UxCRCiH40au09cr2AucC1Cu/8dM3VVmLEtjJkhcULLcqiYVNloiq2q9TBCImjtyv1n3fa6UGyFcQ48kPqyIiM4cQEBHcYwe0AUNVQaq68c5zYWyJwzSmBXJ5GW3CcKRB1TqLTSHovJjuoqhNK0JNDCNsWqorHxJnTQvvh9Hx/DimRgFyWh/5K6O30Fryaqgwm0sLEEXDbkm0Ki3QAZQl2BADSSXZ7OZmbftKc7HpKxEMdVum2fRsSEqBq50OQI6c/9kbP1YgZ2kWa7lgE4IYrGFwQQK3waFKToMggSTICU0gsJAdN5mGEfaOgcQGW1PzU9mwofO4mM17hr7vX+pHxWXaYaoyv7SvsiXVPN0R2MgIYpwxJQ+WNgbpycgT1JYDZpezhC4QquT1+akpFouQixGUR568YmeroVcDbAafJ/57s0kWN1r3UA0migDNcHPzKDvNObPnUxuidUtV54xdS35WmwpQbRiz6RFBKo35f/RIJjRcbHNWAAAAAElFTkSuQmCC"

var selected_save_slot: int = 1
var save_slots_data: Dictionary = {}
var _save_feedback_tween: Tween = null
var _pending_confirm_action: String = ""
var default_thumb_texture: Texture2D = null

# Drag & Drop Party Management State
var _drag_candidate_slot_idx: int = -1
var _dragging_slot_idx: int = -1
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
const DRAG_THRESHOLD: float = 6.0
var _current_hovered_target_slot: int = -1

const HERO_NAMES: Dictionary = {
	0: "Arthur",
	1: "Hellene",
	2: "Anastasya",
	3: "Magnus"
}

func get_hero_type_for_node(hero: CharacterBody2D) -> int:
	if not is_instance_valid(hero):
		return -1
	var script_path := ""
	if hero.get_script():
		script_path = str(hero.get_script().resource_path).to_lower()
	var n := str(hero.name).to_lower()
	if "knight" in script_path or "knight" in n or "arthur" in n:
		return 0 # Arthur
	elif "bandit" in script_path or "bandit" in n or "hellene" in n:
		return 1 # Hellene
	elif "archer" in script_path or "archer" in n or "anastasya" in n:
		return 2 # Anastasya
	elif "mage" in script_path or "mage" in n or "magnus" in n:
		return 3 # Magnus
	return -1


func get_member_by_hero_type(hero_type: int) -> CharacterBody2D:
	for member in party_members:
		if is_instance_valid(member) and get_hero_type_for_node(member) == hero_type:
			return member
	return null


func get_member_index_by_hero_type(hero_type: int) -> int:
	for i in range(party_members.size()):
		var member = party_members[i]
		if is_instance_valid(member) and get_hero_type_for_node(member) == hero_type:
			return i
	return -1

# Tab headers title
const TAB_TITLES: Dictionary = {
	0: "INVENTORI",
	1: "JURNAL",
	2: "INFORMASI",
	3: "PENGATURAN",
	4: "CREDIT"
}

# Character lore & bio data
const HERO_LORE: Dictionary = {
	0: {
		"display_name": "Arthur",
		"full_name": "Forzato Arthur",
		"title": "Ksatria Kerajaan",
		"race": "Manusia",
		"birthday": "31 Agustus",
		"skill_desc": "Shield seluruh tim\nselama 5 detik\nCD 5 detik"
	},
	1: {
		"display_name": "Hellene",
		"full_name": "-",
		"title": "Rogue / Bandit",
		"race": "Manusia",
		"birthday": "-",
		"skill_desc": "Dash & Triple Slash\nKombo tebasan 3x\nCD 5.0 detik"
	},
	2: {
		"display_name": "Anastasya",
		"full_name": "-",
		"title": "Pemanah Kerajaan",
		"race": "Manusia",
		"birthday": "-",
		"skill_desc": "Charged Line Snipe\nTembakan garis linear\nCD 5.0 detik"
	},
	3: {
		"display_name": "Magnus",
		"full_name": "-",
		"title": "Penyihir Kerajaan",
		"race": "Manusia",
		"birthday": "-",
		"skill_desc": "Meteor Strike\nSihir meteor AoE\nCD 6.0 detik"
	}
}


func _ready() -> void:
	layer = 15 # Di atas elemen world game, di bawah TransitionLayer (layer 100)
	process_mode = Node.PROCESS_MODE_ALWAYS

	speech_bubble.visible = false
	speech_bubble.modulate.a = 0.0
	pause_overlay.visible = false
	if is_instance_valid(location_banner):
		_location_banner_rest_y = location_banner.offset_top
		location_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		location_banner.visible = false
		location_banner.modulate.a = 0.0

	# Connect Pause Menu Buttons
	if btn_pause_menu:
		btn_pause_menu.pressed.connect(_on_btn_pause_menu_pressed)
	for hud_shortcut in [
		{ "btn": btn_hud_inventory, "tab": 0 },
		{ "btn": btn_hud_info, "tab": 2 },
		{ "btn": btn_hud_settings, "tab": 3 },
	]:
		var sc_btn := hud_shortcut["btn"] as TextureButton
		if is_instance_valid(sc_btn):
			sc_btn.pressed.connect(_open_book_tab_from_hud.bind(int(hud_shortcut["tab"])))
	for quest_widget in [quest_header, quest_container]:
		if is_instance_valid(quest_widget):
			quest_widget.mouse_filter = Control.MOUSE_FILTER_STOP
			quest_widget.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			quest_widget.gui_input.connect(_on_hud_shortcut_gui_input.bind(quest_widget, 1))
			if not quest_widget.mouse_entered.is_connected(_on_quest_container_mouse_entered):
				quest_widget.mouse_entered.connect(_on_quest_container_mouse_entered)
			if not quest_widget.mouse_exited.is_connected(_on_quest_container_mouse_exited):
				quest_widget.mouse_exited.connect(_on_quest_container_mouse_exited)

	_init_pause_menu_textures()
	_init_pause_menu_ui()
	_setup_skill_buttons()
	_setup_party_card_clicks()


func _unhandled_input(event: InputEvent) -> void:
	if is_start_menu_mode and not pause_overlay.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
				_close_confirm_modal()
				get_viewport().set_input_as_handled()
				return
			if pause_overlay.visible:
				if _is_dragging:
					_cancel_drag()
					_drag_candidate_slot_idx = -1
					_is_dragging = false
					_current_hovered_target_slot = -1
					get_viewport().set_input_as_handled()
				else:
					toggle_pause_menu()
					get_viewport().set_input_as_handled()
				return
		if (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and pause_overlay.visible:
			if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
				_on_confirm_yes_pressed()
				get_viewport().set_input_as_handled()
				return
			elif current_tab_index == 3 and active_settings_submenu == 2:
				_on_save_load_enter_pressed()
				get_viewport().set_input_as_handled()
				return
		if event.is_action_pressed("open_journal") and not is_start_menu_mode:
			if _toggle_or_switch_journal_menu():
				get_viewport().set_input_as_handled()
				return
		if event.is_action_pressed("interact"):
			if pause_overlay.visible:
				if current_tab_index == 0:
					_on_btn_gunakan_pressed()
					get_viewport().set_input_as_handled()
				elif current_tab_index == 1:
					_on_btn_navigasi_pressed()
					get_viewport().set_input_as_handled()
		elif event.is_action_pressed("skip"):
			if speech_bubble.visible:
				speech_bubble.visible = false
				get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not pause_overlay.visible:
		return

	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return

	if _rebind_action_id != "":
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.keycode == KEY_ESCAPE:
					_cancel_rebind()
					get_viewport().set_input_as_handled()
					return

				var captured_key: int = event.keycode
				if captured_key == 0:
					captured_key = event.physical_keycode

				if captured_key != 0:
					_apply_rebind(_rebind_action_id, captured_key)
			get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_rebind()
			get_viewport().set_input_as_handled()
			return

	if _is_dragging_inv_slider and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_is_dragging_inv_slider = false

	if _is_dragging_journal_slider and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_is_dragging_journal_slider = false

	if _active_dragging_slider != "" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_active_dragging_slider = ""
		save_audio_settings()

	if _active_dragging_slider != "" and event is InputEventMouseMotion:
		var s_ctrl = _get_slider_ctrl(_active_dragging_slider)
		if is_instance_valid(s_ctrl):
			var local_pos = s_ctrl.get_local_mouse_position()
			var track_w: float = s_ctrl.size.x if s_ctrl.size.x > 0.0 else 190.0
			var grab_w: float = 16.0
			var travel: float = maxf(1.0, track_w - grab_w)
			var target_ratio: float = clampf((local_pos.x - grab_w / 2.0) / travel, 0.0, 1.0)
			_set_slider_value_from_ratio(_active_dragging_slider, target_ratio)

	if _drag_candidate_slot_idx != -1:
		if event is InputEventMouseMotion:
			if not _is_dragging:
				if event.global_position.distance_to(_drag_start_pos) >= DRAG_THRESHOLD:
					_is_dragging = true
					_start_drag(_drag_candidate_slot_idx, event.global_position)
			if _is_dragging:
				_update_drag(event.global_position)

		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _is_dragging:
				_finish_drag(event.global_position)
			else:
				# Klik singkat: tampilkan biodata & stat karakter slot ini
				_on_party_slot_clicked(_drag_candidate_slot_idx)
			_drag_candidate_slot_idx = -1
			_is_dragging = false
			_current_hovered_target_slot = -1

		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_drag()
			_drag_candidate_slot_idx = -1
			_is_dragging = false
			_current_hovered_target_slot = -1


func setup(members: Array[CharacterBody2D], current_leader_idx: int, initial_inventory: Array[Dictionary] = [], initial_quests: Array[Dictionary] = []) -> void:
	party_members = members
	active_leader_index = current_leader_idx
	inventory_items = initial_inventory
	if not initial_quests.is_empty():
		set_quests(initial_quests)
	if current_leader_idx >= 0 and current_leader_idx < party_members.size():
		active_leader_node = party_members[current_leader_idx]
	current_viewed_party_slot = 0

	update_party_hud()
	update_leader_indicator()
	_refresh_inventory_ui()


func set_inventory(items: Array[Dictionary]) -> void:
	inventory_items = items
	_refresh_inventory_ui()




func set_active_leader(index: int) -> void:
	active_leader_index = index
	if index >= 0 and index < party_members.size():
		active_leader_node = party_members[index]
	update_leader_indicator()
	if pause_overlay.visible:
		_update_pause_party_display()


func _process(delta: float) -> void:
	if is_start_menu_mode:
		return
	_update_hp_bars()
	_update_skill_cooldowns()
	_update_speech_bubble_position()
	if pause_overlay.visible:
		_update_pause_party_hp_bars()
		if current_tab_index == 2:
			_update_bio_char_animation(delta)


# =========================================================
# PAUSE MENU SETUP & LOGIC
# =========================================================

func _init_pause_menu_textures() -> void:
	var sheet := preload("res://assets/ui/menus/common/ui_menu_sheet.png")
	var skills := preload("res://assets/ui/icons/skills/skill.png")

	tab_active_texture = _create_atlas(sheet, Rect2(70, 273, 20, 14))
	tab_inactive_texture = _create_atlas(sheet, Rect2(70, 273, 20, 14))

	var walk_configs: Dictionary = {
		0: { "tex": preload("res://assets/characters/knight/walk/walk-s.png"), "fw": 96, "rect": Rect2(39, 18, 18, 22) },
		1: { "tex": preload("res://assets/characters/bandit/walk/walk-s.png"), "fw": 96, "rect": Rect2(38, 40, 21, 16) },
		2: { "tex": preload("res://assets/characters/archer/walk/walk-s.png"), "fw": 32, "rect": Rect2(10, 7, 14, 23) },
		3: { "tex": preload("res://assets/characters/mage/walk/walk-s.png"),   "fw": 96, "rect": Rect2(40, 21, 17, 20) }
	}
	for h_type in walk_configs.keys():
		var cfg: Dictionary = walk_configs[h_type]
		var tex: Texture2D = cfg["tex"]
		var fw: int = int(cfg["fw"])
		var base_rect: Rect2 = cfg["rect"]
		var frames: Array = []
		var frame_count: int = maxi(1, int(float(tex.get_width()) / float(fw)))
		for f_idx in range(frame_count):
			var r := Rect2(float(f_idx * fw) + base_rect.position.x, base_rect.position.y, base_rect.size.x, base_rect.size.y)
			frames.append(_create_atlas(tex, r))
		hero_anim_frames[h_type] = frames
		hero_atlas_sprites[h_type] = frames[0]

	hero_skill_icons[0] = _create_atlas(skills, Rect2(16, 0, 16, 16)) # Arthur: Golden Shield
	hero_skill_icons[1] = _create_atlas(skills, Rect2(0, 0, 16, 16))  # Hellene: Triple Slash
	hero_skill_icons[2] = _create_atlas(skills, Rect2(32, 0, 16, 16)) # Anastasya: Line Snipe
	hero_skill_icons[3] = _create_atlas(skills, Rect2(48, 0, 16, 16)) # Magnus: Meteor Strike

	hero_portraits[0] = preload("res://assets/ui/gameplay/party_hud/portrait_arthur.png")
	hero_portraits[1] = preload("res://assets/ui/gameplay/party_hud/portrait_hellene.png")
	hero_portraits[2] = preload("res://assets/ui/gameplay/party_hud/portrait_anastasya.png")
	hero_portraits[3] = _create_atlas(preload("res://assets/ui/gameplay/party_hud/portrait_magnus.png"), Rect2(3, 1, 20, 16))

	cat_btn_normal_tex = _create_atlas(sheet, Rect2(113, 292, 14, 9))
	cat_btn_selected_tex = _create_atlas(sheet, Rect2(113, 305, 14, 9))
	item_slot_tex = _create_atlas(sheet, Rect2(65, 289, 30, 29))
	item_selected_tex = _create_atlas(sheet, Rect2(65, 385, 30, 30))

	quest_btn_panel_tex = _create_atlas(sheet, Rect2(65, 449, 62, 14))

	# Custom Vertical Scrollbar textures (2x crisp pixel art from ui_menu_sheet.png)
	var sheet_img: Image = sheet.get_image()
	if sheet_img:
		if sheet_img.is_compressed():
			sheet_img.decompress()
		var v_track_img := sheet_img.get_region(Rect2i(66, 485, 62, 4))
		v_track_img.rotate_90(CLOCKWISE)
		v_track_img.resize(8, 124, Image.INTERPOLATE_NEAREST)
		v_scroll_track_tex = ImageTexture.create_from_image(v_track_img)

		var v_grab_img := sheet_img.get_region(Rect2i(70, 515, 7, 8))
		v_grab_img.rotate_90(CLOCKWISE)
		v_grab_img.resize(16, 14, Image.INTERPOLATE_NEAREST)
		v_scroll_grabber_tex = ImageTexture.create_from_image(v_grab_img)

	for sb in [inv_scrollbar, journal_scrollbar, save_load_scrollbar]:
		if is_instance_valid(sb):
			var sb_track = sb.get_node_or_null("Track") as NinePatchRect
			if sb_track and v_scroll_track_tex:
				sb_track.texture = v_scroll_track_tex
			var sb_grabber = sb.get_node_or_null("Grabber") as TextureRect
			if sb_grabber and v_scroll_grabber_tex:
				sb_grabber.texture = v_scroll_grabber_tex
	_apply_v_scrollbar_visual(save_load_scrollbar, 0.0)

	# Audio Sliders Grabber & Submenu Textures
	var h_grab_raw := Marshalls.base64_to_raw(H_GRABBER_B64)
	var h_grab_img := Image.create_from_data(16, 16, false, Image.FORMAT_RGBA8, h_grab_raw)
	h_grabber_tex = ImageTexture.create_from_image(h_grab_img)

	for s_ctrl in [slider_ctrl_master, slider_ctrl_music, slider_ctrl_sfx, slider_ctrl_dialog]:
		if is_instance_valid(s_ctrl):
			var g_node = s_ctrl.get_node_or_null("Grabber") as TextureRect
			if g_node:
				g_node.texture = h_grabber_tex

	submenu_btn_selected_tex = _create_atlas(sheet, Rect2(65, 449, 62, 14))
	submenu_btn_normal_tex = _create_atlas(sheet, Rect2(145, 433, 62, 14))
	slot_card_selected_tex = _create_atlas(sheet, Rect2(145, 449, 62, 14))

	if is_instance_valid(btn_close_book):
		var outline_col := Color8(61, 35, 38, 255)
		btn_close_book.ignore_texture_size = true
		btn_close_book.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn_close_book.texture_normal = _build_close_button_texture(
			outline_col,
			Color8(248, 166, 162, 255),
			Color8(219, 77, 81, 255),
			Color8(161, 39, 46, 255),
			Color8(255, 246, 232, 255)
		)
		btn_close_book.texture_hover = _build_close_button_texture(
			outline_col,
			Color8(255, 186, 186, 255),
			Color8(237, 98, 102, 255),
			Color8(184, 54, 59, 255),
			Color(1.0, 1.0, 1.0, 1.0)
		)
		btn_close_book.texture_pressed = _build_close_button_texture(
			outline_col,
			Color8(161, 39, 46, 255),
			Color8(184, 54, 59, 255),
			Color8(140, 30, 36, 255),
			Color8(255, 246, 232, 255)
		)

	var frame_outline := Color8(66, 46, 47, 255)
	var hud_btn_normal := _build_hud_settings_button_texture(
		frame_outline,
		Color8(255, 244, 220, 255),
		Color8(252, 226, 184, 255),
		Color8(229, 182, 127, 255),
		Color8(199, 137, 93, 255)
	)
	var hud_btn_hover := _build_hud_settings_button_texture(
		frame_outline,
		Color8(255, 250, 238, 255),
		Color8(255, 238, 204, 255),
		Color8(244, 204, 156, 255),
		Color8(215, 155, 108, 255)
	)
	var hud_btn_pressed := _build_hud_settings_button_texture(
		frame_outline,
		Color8(199, 137, 93, 255),
		Color8(236, 202, 156, 255),
		Color8(216, 172, 122, 255),
		Color8(172, 114, 74, 255)
	)
	for hud_btn in [btn_hud_inventory, btn_hud_info, btn_hud_settings]:
		if is_instance_valid(hud_btn):
			hud_btn.ignore_texture_size = true
			hud_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			hud_btn.texture_normal = hud_btn_normal
			hud_btn.texture_hover = hud_btn_hover
			hud_btn.texture_pressed = hud_btn_pressed
	for icon_cfg in [
		[btn_hud_inventory, _build_backpack_icon_texture(frame_outline)],
		[btn_hud_settings, _build_gear_icon_texture(frame_outline)],
	]:
		var target_btn := icon_cfg[0] as TextureButton
		if is_instance_valid(target_btn):
			var btn_icon := target_btn.get_node_or_null("Icon") as TextureRect
			if btn_icon:
				btn_icon.texture = icon_cfg[1]


func _create_atlas(tex: Texture2D, rect: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = rect
	return a


## Builds an ImageTexture from a character grid pattern and color palette.
func _build_pixel_texture(width: int, height: int, pattern: Array[String], palette: Dictionary) -> ImageTexture:
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		var row: String = pattern[y]
		for x in range(width):
			var ch := row.substr(x, 1)
			if palette.has(ch):
				img.set_pixel(x, y, palette[ch])
	return ImageTexture.create_from_image(img)


## Builds a 12x12 pixel-art close-button ImageTexture using the provided palette.
func _build_close_button_texture(
	border_col: Color,
	top_col: Color,
	fill_col: Color,
	bottom_col: Color,
	x_col: Color
) -> ImageTexture:
	var pattern: Array[String] = [
		".##########.",
		"#HHHHHHHHHH#",
		"#FFFFFFFFFF#",
		"#FFWWFFWWFF#",
		"#FFFWWWWFFF#",
		"#FFFFWWFFFF#",
		"#FFFFWWFFFF#",
		"#FFFWWWWFFF#",
		"#FFWWFFWWFF#",
		"#FFFFFFFFFF#",
		"#DDDDDDDDDD#",
		".##########.",
	]
	var palette := {
		"#": border_col,
		"H": top_col,
		"F": fill_col,
		"D": bottom_col,
		"W": x_col,
	}
	return _build_pixel_texture(12, 12, pattern, palette)


## Builds a 19x19 rounded parchment button frame ImageTexture for the HUD settings button.
func _build_hud_settings_button_texture(
	border_col: Color,
	highlight_col: Color,
	fill_col: Color,
	shade_col: Color,
	shadow_col: Color
) -> ImageTexture:
	const SIZE := 19
	var pattern: Array[String] = []
	for y in range(SIZE):
		var row := ""
		for x in range(SIZE):
			if (x == 0 or x == SIZE - 1) and (y == 0 or y == SIZE - 1):
				row += "."
			elif x == 0 or x == SIZE - 1 or y == 0 or y == SIZE - 1:
				row += "#"
			elif y == 1:
				row += "H"
			elif y == SIZE - 2:
				row += "D"
			elif x == 1 or x == SIZE - 2:
				row += "S"
			else:
				row += "F"
		pattern.append(row)
	var palette := {
		"#": border_col,
		"H": highlight_col,
		"F": fill_col,
		"S": shade_col,
		"D": shadow_col,
	}
	return _build_pixel_texture(SIZE, SIZE, pattern, palette)


## Builds an 11x11 symmetrical pixel-art cogwheel ImageTexture for the HUD settings button.
func _build_gear_icon_texture(ink_col: Color) -> ImageTexture:
	var pattern: Array[String] = [
		"....###....",
		".##.###.##.",
		".#########.",
		"..#######..",
		"#####.#####",
		"####...####",
		"#####.#####",
		"..#######..",
		".#########.",
		".##.###.##.",
		"....###....",
	]
	return _build_pixel_texture(11, 11, pattern, {"#": ink_col})


## Builds an 11x11 symmetrical pixel-art backpack (tas ransel) ImageTexture for the HUD inventory button.
func _build_backpack_icon_texture(ink_col: Color) -> ImageTexture:
	var pattern: Array[String] = [
		"....###....",
		"...#...#...",
		"..#######..",
		".#########.",
		".#########.",
		".#...#...#.",
		"#.##...##.#",
		"#.#######.#",
		"#.#######.#",
		".#########.",
		"..#######.."]
	return _build_pixel_texture(11, 11, pattern, {"#": ink_col})


func _init_pause_menu_ui() -> void:
	# Click outside to close (backdrop overlays)
	if is_instance_valid(pause_overlay):
		pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		if not pause_overlay.gui_input.is_connected(_on_pause_overlay_gui_input):
			pause_overlay.gui_input.connect(_on_pause_overlay_gui_input)
	if is_instance_valid(save_confirm_dimmer):
		save_confirm_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		if not save_confirm_dimmer.gui_input.is_connected(_on_save_confirm_dimmer_gui_input):
			save_confirm_dimmer.gui_input.connect(_on_save_confirm_dimmer_gui_input)
	if is_instance_valid(btn_close_book):
		if not btn_close_book.pressed.is_connected(_on_btn_close_book_pressed):
			btn_close_book.pressed.connect(_on_btn_close_book_pressed)

	# Tab button signals
	_connect_tab_click(tab_btn_inventory, 0)
	_connect_tab_click(tab_btn_journal, 1)
	_connect_tab_click(tab_btn_info, 2)
	_connect_tab_click(tab_btn_settings, 3)
	_connect_tab_click(tab_btn_credits, 4)

	# Prev / Next character signals
	if btn_prev_char:
		btn_prev_char.pressed.connect(_on_btn_prev_char_pressed)
	if btn_next_char:
		btn_next_char.pressed.connect(_on_btn_next_char_pressed)

	# Party slot GUI inputs for drag-and-drop & click selection
	for i in range(pause_party_slots.size()):
		var slot_node = pause_party_slots[i]
		if is_instance_valid(slot_node):
			var frame = slot_node.get_node_or_null("Frame") as TextureRect
			if frame:
				var slot_idx: int = i
				frame.gui_input.connect(func(event: InputEvent): _on_party_slot_gui_input(slot_idx, event))

	# Inventory Category Buttons
	if inv_btn_prev_cat:
		inv_btn_prev_cat.pressed.connect(_on_btn_prev_category_pressed)
	if inv_btn_next_cat:
		inv_btn_next_cat.pressed.connect(_on_btn_next_category_pressed)
	for i in range(inv_cat_btns.size()):
		var cat_box = inv_cat_btns[i]
		if is_instance_valid(cat_box):
			var click_area = cat_box.get_node_or_null("ClickArea") as TextureButton
			if click_area:
				var cat_idx: int = i
				click_area.pressed.connect(func(): _set_inventory_category(cat_idx))

	# Inventory Gunakan Button
	if inv_btn_gunakan:
		inv_btn_gunakan.pressed.connect(_on_btn_gunakan_pressed)

	# Ensure ONLY ONE slider in inventory: hide built-in scrollbar of ScrollContainer
	if inv_scroll_container:
		inv_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		var v_bar = inv_scroll_container.get_v_scroll_bar()
		if v_bar:
			v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v_bar.custom_minimum_size = Vector2.ZERO
			v_bar.scale = Vector2.ZERO
			v_bar.visible = false
			v_bar.value_changed.connect(func(_val: float):
				_update_inv_slider_grabber_pos()
			)

	# Custom Inventory Scrollbar GUI input
	if inv_scrollbar:
		inv_scrollbar.gui_input.connect(_on_inv_scrollbar_gui_input)

	# Journal UI
	if journal_btn_navigasi:
		journal_btn_navigasi.pressed.connect(_on_btn_navigasi_pressed)

	if journal_scroll_container:
		journal_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		var j_v_bar = journal_scroll_container.get_v_scroll_bar()
		if j_v_bar:
			j_v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			j_v_bar.custom_minimum_size = Vector2.ZERO
			j_v_bar.scale = Vector2.ZERO
			j_v_bar.visible = false
			j_v_bar.value_changed.connect(func(_val: float):
				_update_journal_slider_grabber_pos()
			)

	if journal_scrollbar:
		journal_scrollbar.gui_input.connect(_on_journal_scrollbar_gui_input)

	# Settings Submenu Buttons
	_connect_submenu_click(settings_btn_audio, 0)
	_connect_submenu_click(settings_btn_controls, 1)
	_connect_submenu_click(settings_btn_save_load, 2)
	if is_instance_valid(settings_btn_title):
		var title_click = settings_btn_title.get_node_or_null("ClickArea") as TextureButton
		if title_click:
			title_click.pressed.connect(_on_btn_return_to_title_pressed)

	# Settings Audio Sliders GUI Input
	_connect_audio_slider(slider_ctrl_master, "master")
	_connect_audio_slider(slider_ctrl_music, "music")
	_connect_audio_slider(slider_ctrl_sfx, "sfx")
	_connect_audio_slider(slider_ctrl_dialog, "dialog")

	# Initialize Audio Buses & Load Persistence
	init_audio_system()

	# Initialize Controls System & Load Persistence
	_init_controls_system()

	# Initialize Save & Load System (TASK 05C)
	_init_save_load_system()


func enable_start_menu_mode() -> void:
	is_start_menu_mode = true
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	hide_location_banner()
	for hud_node in [btn_pause_menu, btn_hud_inventory, btn_hud_info, btn_hud_settings, quest_header, quest_container, location_banner, controls_prompt, party_container, skill_container, speech_bubble]:
		if is_instance_valid(hud_node):
			hud_node.visible = false
	current_tab_index = 3
	active_settings_submenu = 0
	_update_tab_navigation()
	_switch_settings_submenu(0)


func open_as_start_menu_settings() -> void:
	if not is_start_menu_mode:
		enable_start_menu_mode()
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	current_tab_index = 3
	active_settings_submenu = 0
	pause_overlay.visible = true
	_scan_all_save_slots()
	_update_tab_navigation()
	_switch_settings_submenu(0)


func close_start_menu_settings() -> void:
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	if _rebind_action_id != "":
		_cancel_rebind()
	_close_confirm_modal()
	if _save_feedback_tween and _save_feedback_tween.is_valid():
		_save_feedback_tween.kill()
	if is_instance_valid(save_feedback_label):
		save_feedback_label.visible = false
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = false
	start_menu_settings_closed.emit()


func toggle_pause_menu(initial_tab: int = 2) -> void:
	if is_start_menu_mode:
		if pause_overlay.visible:
			close_start_menu_settings()
		else:
			open_as_start_menu_settings()
		return

	_outside_pause_pressed = false
	_outside_modal_pressed = false
	pause_menu_requested.emit()
	var is_paused := not pause_overlay.visible
	pause_overlay.visible = is_paused
	get_tree().paused = is_paused

	if is_paused:
		_set_quest_hud_modulate(Color.WHITE)
		current_tab_index = initial_tab
		if active_leader_index >= 0 and active_leader_index < party_members.size():
			current_viewed_party_slot = active_leader_index
		else:
			current_viewed_party_slot = 0
		_update_tab_navigation()
		_update_character_info_ui()
		_update_pause_party_display()
		_refresh_inventory_ui()
		if initial_tab == 1 and tracked_quest_id != "":
			_select_quest(tracked_quest_id)
		elif initial_tab == 3:
			active_settings_submenu = 0
			_scan_all_save_slots()
			_switch_settings_submenu(0)
			_sync_all_audio_sliders()


	else:
		if _rebind_action_id != "":
			_cancel_rebind()
		_close_confirm_modal()
		_is_dragging_inv_slider = false
		if _is_dragging or _drag_candidate_slot_idx != -1:
			_cancel_drag()
			_drag_candidate_slot_idx = -1
			_is_dragging = false
			_current_hovered_target_slot = -1


func _on_btn_pause_menu_pressed() -> void:
	toggle_pause_menu()


## Opens the book pause menu directly on the requested tab from a gameplay HUD shortcut.
func _open_book_tab_from_hud(tab_idx: int) -> void:
	if is_start_menu_mode:
		return
	if is_instance_valid(pause_overlay) and pause_overlay.visible:
		return
	toggle_pause_menu(tab_idx)


## Handles the open_journal hotkey: opens to Journal, switches to Journal, or closes it.
func _toggle_or_switch_journal_menu() -> bool:
	if is_start_menu_mode:
		return false
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return false
	if _is_dragging or _drag_candidate_slot_idx != -1:
		return false
	if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
		toggle_pause_menu(1)
		return true
	if current_tab_index == 1:
		toggle_pause_menu()
		return true
	_on_tab_pressed(1)
	return true


## Updates hover tint across both the HUD quest header label and quest row.
func _set_quest_hud_modulate(col: Color) -> void:
	for quest_widget in [quest_header, quest_container]:
		if is_instance_valid(quest_widget):
			quest_widget.modulate = col


## Opens the target book tab directly when clicking an interactive gameplay HUD widget.
func _on_hud_shortcut_gui_input(event: InputEvent, source_widget: Control = null, tab_idx: int = 1) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_start_menu_mode or (is_instance_valid(pause_overlay) and pause_overlay.visible):
		return
	if is_instance_valid(source_widget):
		source_widget.accept_event()
	if mb.pressed:
		_open_book_tab_from_hud(tab_idx)


func _on_quest_container_mouse_entered() -> void:
	if not is_start_menu_mode and (not is_instance_valid(pause_overlay) or not pause_overlay.visible):
		_set_quest_hud_modulate(Color(1.08, 1.05, 0.92, 1.0))


func _on_quest_container_mouse_exited() -> void:
	_set_quest_hud_modulate(Color.WHITE)


func _on_tab_pressed(tab_idx: int) -> void:
	if is_start_menu_mode and tab_idx != 3:
		return
	if current_tab_index == tab_idx:
		return
	if tab_idx != 3:
		if _rebind_action_id != "":
			_cancel_rebind()
		_close_confirm_modal()
	current_tab_index = tab_idx
	_update_tab_navigation()
	if tab_idx == 0:
		_refresh_inventory_ui()
	elif tab_idx == 1:
		_sync_journal_scrollbar()
	elif tab_idx == 2:
		_update_character_info_ui()
		_update_pause_party_display()
	elif tab_idx == 3:
		_switch_settings_submenu(active_settings_submenu)
		if active_settings_submenu == 0:
			_sync_all_audio_sliders()
		elif active_settings_submenu == 1:
			_refresh_controls_ui()
		elif active_settings_submenu == 2:
			_refresh_save_load_ui()


func _connect_tab_click(tab_node: Control, tab_idx: int) -> void:
	if not is_instance_valid(tab_node):
		return
	tab_node.mouse_filter = Control.MOUSE_FILTER_STOP
	var click_area = tab_node.get_node_or_null("ClickArea") as BaseButton
	if click_area:
		click_area.mouse_filter = Control.MOUSE_FILTER_PASS
		click_area.pressed.connect(func(): _on_tab_pressed(tab_idx))
	tab_node.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_tab_pressed(tab_idx)
	)


func _update_tab_navigation() -> void:
	if pause_header_title:
		pause_header_title.text = TAB_TITLES.get(current_tab_index, "INFORMASI")

	var tab_btns: Array[Control] = [tab_btn_inventory, tab_btn_journal, tab_btn_info, tab_btn_settings]
	var pages: Array[Control] = [page_inventory, page_journal, page_info, page_settings, page_credits]

	if is_instance_valid(tab_btn_credits):
		tab_btn_credits.visible = false

	for i in range(tab_btns.size()):
		var tab_node = tab_btns[i]
		if is_instance_valid(tab_node):
			tab_node.visible = (not is_start_menu_mode) or (i == 3)
			var is_active := (i == current_tab_index)
			if tab_node is NinePatchRect:
				tab_node.texture = tab_active_texture if is_active else tab_inactive_texture
				tab_node.patch_margin_left = 4
				tab_node.patch_margin_top = 4
				tab_node.patch_margin_right = 4
				tab_node.patch_margin_bottom = 1
			tab_node.size_flags_vertical = Control.SIZE_SHRINK_END
			tab_node.custom_minimum_size = Vector2(54, 42) if is_active else Vector2(50, 36)
			tab_node.self_modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.88, 0.84, 0.80, 1.0)
			tab_node.z_index = 1 if is_active else 0
			tab_node.mouse_filter = Control.MOUSE_FILTER_STOP

			var icon = tab_node.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(1.0, 1.0, 1.0, 0.55)
				var target_icon_size: float = 22.0 if is_active else 20.0
				icon.custom_minimum_size = Vector2(target_icon_size, target_icon_size)
				icon.offset_left = -target_icon_size / 2.0
				icon.offset_top = -target_icon_size / 2.0
				icon.offset_right = target_icon_size / 2.0
				icon.offset_bottom = target_icon_size / 2.0

	for i in range(pages.size()):
		var p = pages[i]
		if is_instance_valid(p):
			p.visible = (i == current_tab_index)

	if current_tab_index == 0:
		_sync_inventory_scrollbar()
		call_deferred("_sync_inventory_scrollbar")
	elif current_tab_index == 1:
		_sync_journal_scrollbar()
		call_deferred("_sync_journal_scrollbar")
	elif current_tab_index == 3:
		_sync_all_audio_sliders()
		call_deferred("_sync_all_audio_sliders")
		_switch_settings_submenu(active_settings_submenu)


# =========================================================
# DRAG & DROP PARTY REORDERING LOGIC
# =========================================================

func _on_party_slot_gui_input(slot_idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if slot_idx < party_members.size() and is_instance_valid(party_members[slot_idx]):
			_drag_candidate_slot_idx = slot_idx
			_drag_start_pos = event.global_position
			_is_dragging = false
			_current_hovered_target_slot = -1


func _start_drag(slot_idx: int, global_pos: Vector2) -> void:
	_dragging_slot_idx = slot_idx
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	var hero = party_members[slot_idx]
	if not is_instance_valid(hero):
		return
	var hero_type := get_hero_type_for_node(hero)

	if is_instance_valid(drag_ghost):
		if drag_ghost_portrait and hero_portraits.has(hero_type):
			drag_ghost_portrait.texture = hero_portraits[hero_type]
		drag_ghost.global_position = global_pos - Vector2(31.5, 31.5)
		drag_ghost.visible = true

	# Redupkan frame slot sumber
	if slot_idx < pause_party_slots.size():
		var slot_node = pause_party_slots[slot_idx]
		if is_instance_valid(slot_node):
			var frame = slot_node.get_node_or_null("Frame") as CanvasItem
			if frame:
				frame.modulate = Color(0.5, 0.5, 0.5, 0.6)


func _update_drag(global_pos: Vector2) -> void:
	if is_instance_valid(drag_ghost):
		drag_ghost.global_position = global_pos - Vector2(31.5, 31.5)

	var target_slot := _get_slot_at_pos(global_pos)
	if target_slot != _current_hovered_target_slot:
		_current_hovered_target_slot = target_slot
		_update_drag_hover_visuals()


func _update_drag_hover_visuals() -> void:
	for i in range(pause_party_slots.size()):
		var slot_node = pause_party_slots[i]
		if not is_instance_valid(slot_node):
			continue
		var frame = slot_node.get_node_or_null("Frame") as CanvasItem
		if not frame:
			continue

		if i == _dragging_slot_idx:
			frame.modulate = Color(0.5, 0.5, 0.5, 0.6)
		elif i == _current_hovered_target_slot and _current_hovered_target_slot != _dragging_slot_idx:
			# Highlight hangat keemasan pada target hover
			frame.modulate = Color(1.3, 1.2, 0.7, 1.0)
		else:
			frame.modulate = Color.WHITE


func _get_slot_at_pos(global_pos: Vector2) -> int:
	for slot_idx in range(party_members.size()):
		if slot_idx >= pause_party_slots.size():
			break
		var slot_node = pause_party_slots[slot_idx]
		if not is_instance_valid(slot_node) or not slot_node.visible:
			continue
		var frame = slot_node.get_node_or_null("Frame") as Control
		if not is_instance_valid(frame):
			continue
		var rect: Rect2 = frame.get_global_rect().grow(8.0)
		if rect.has_point(global_pos):
			return slot_idx
	return -1


func _finish_drag(global_pos: Vector2) -> void:
	var from_idx := _dragging_slot_idx
	var to_idx := _get_slot_at_pos(global_pos)

	_reset_drag_visuals()

	if from_idx != -1 and to_idx != -1 and from_idx != to_idx:
		_reorder_party_members(from_idx, to_idx)

	_dragging_slot_idx = -1
	_current_hovered_target_slot = -1


func _cancel_drag() -> void:
	_reset_drag_visuals()
	_dragging_slot_idx = -1
	_current_hovered_target_slot = -1


func _reset_drag_visuals() -> void:
	if is_instance_valid(drag_ghost):
		drag_ghost.visible = false
	for slot_node in pause_party_slots:
		if is_instance_valid(slot_node):
			var frame = slot_node.get_node_or_null("Frame") as CanvasItem
			if frame:
				frame.modulate = Color.WHITE


func _on_party_slot_clicked(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < party_members.size():
		current_viewed_party_slot = slot_idx
		_update_character_info_ui()


func _reorder_party_members(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= party_members.size():
		return
	if to_idx < 0 or to_idx >= party_members.size():
		return
	if from_idx == to_idx:
		return

	# Simpan referensi hero yang sedang dilihat agar seleksi tetap terjaga
	var currently_viewed_hero: CharacterBody2D = null
	if current_viewed_party_slot >= 0 and current_viewed_party_slot < party_members.size():
		currently_viewed_hero = party_members[current_viewed_party_slot]

	# Sisipkan hero ke posisi target
	var moving_hero = party_members.pop_at(from_idx)
	party_members.insert(to_idx, moving_hero)

	# Karakter di slot 0 otomatis menjadi leader
	active_leader_index = 0
	active_leader_node = party_members[0]

	# Pertahankan tampilan karakter yang sedang dilihat
	if is_instance_valid(currently_viewed_hero):
		var new_slot_idx = party_members.find(currently_viewed_hero)
		if new_slot_idx != -1:
			current_viewed_party_slot = new_slot_idx

	# Pancarkan signal ke game controller untuk sinkronisasi runtime gameplay
	party_reordered.emit(party_members)

	# Perbarui UI pause menu
	_update_pause_party_display()
	_update_character_info_ui()

	# Perbarui gameplay HUD
	update_leader_indicator()
	update_party_hud()


# =========================================================
# CHARACTER BIODATA & STAT NAVIGATION
# =========================================================

func _on_btn_prev_char_pressed() -> void:
	if party_members.is_empty():
		return
	var total_chars := party_members.size()
	current_viewed_party_slot = (current_viewed_party_slot - 1 + total_chars) % total_chars
	_update_character_info_ui()


func _on_btn_next_char_pressed() -> void:
	if party_members.is_empty():
		return
	var total_chars := party_members.size()
	current_viewed_party_slot = (current_viewed_party_slot + 1) % total_chars
	_update_character_info_ui()


func _update_character_info_ui() -> void:
	if party_members.is_empty():
		return
	if current_viewed_party_slot < 0 or current_viewed_party_slot >= party_members.size():
		current_viewed_party_slot = 0

	var hero = party_members[current_viewed_party_slot]
	if not is_instance_valid(hero):
		return

	var hero_type := get_hero_type_for_node(hero)
	var data: Dictionary = HERO_LORE.get(hero_type, {
		"display_name": "-",
		"full_name": "-",
		"title": "-",
		"race": "-",
		"birthday": "-",
		"skill_desc": "-"
	}).duplicate()

	var hp_str: String = "10"
	var atk_str: String = "1"

	# Baca data aktual live hero node jika tersedia
	if hero.get("character_name"):
		data["display_name"] = str(hero.get("character_name"))
	elif hero.get("name"):
		data["display_name"] = HERO_NAMES.get(hero_type, str(hero.name))

	if hero.get("full_name"):
		data["full_name"] = str(hero.get("full_name"))
	if hero.get("title"):
		data["title"] = str(hero.get("title"))
	if hero.get("race"):
		data["race"] = str(hero.get("race"))
	if hero.get("birthday"):
		data["birthday"] = str(hero.get("birthday"))

	if "max_health" in hero:
		hp_str = str(hero.get("max_health"))
	if "attack_damage" in hero:
		atk_str = str(hero.get("attack_damage"))
	elif "damage" in hero:
		atk_str = str(hero.get("damage"))

	# Update Biodata Page (Left)
	_current_bio_hero_type = hero_type
	_bio_anim_timer = 0.0
	_bio_anim_frame = 0
	if bio_char_sprite:
		var display_tex: Texture2D = null
		if hero_anim_frames.has(hero_type) and not hero_anim_frames[hero_type].is_empty():
			display_tex = hero_anim_frames[hero_type][0]
		elif hero_atlas_sprites.has(hero_type):
			display_tex = hero_atlas_sprites[hero_type]
		if display_tex:
			bio_char_sprite.texture = display_tex
			if display_tex is AtlasTexture:
				var reg_size: Vector2 = (display_tex as AtlasTexture).region.size
				var box_size := Vector2(round(reg_size.x * BIO_CHAR_PIXEL_SCALE), round(reg_size.y * BIO_CHAR_PIXEL_SCALE))
				bio_char_sprite.custom_minimum_size = box_size
				bio_char_sprite.offset_left = BIO_CHAR_CENTER.x - box_size.x * 0.5
				bio_char_sprite.offset_top = BIO_CHAR_CENTER.y - box_size.y * 0.5
				bio_char_sprite.offset_right = BIO_CHAR_CENTER.x + box_size.x * 0.5
				bio_char_sprite.offset_bottom = BIO_CHAR_CENTER.y + box_size.y * 0.5

	if bio_name_label:
		bio_name_label.text = data.get("display_name", "-")

	if bio_val_nama:
		bio_val_nama.text = data.get("full_name", "-")
	if bio_val_gelar:
		bio_val_gelar.text = data.get("title", "-")
	if bio_val_ras:
		bio_val_ras.text = data.get("race", "-")
	if bio_val_bday:
		bio_val_bday.text = data.get("birthday", "-")

	# Update Stat Page (Right)
	if stat_val_hp:
		stat_val_hp.text = hp_str
	if stat_val_atk:
		stat_val_atk.text = atk_str

	# Update Skill Preview (Right)
	if skill_preview_icon and hero_skill_icons.has(hero_type):
		skill_preview_icon.texture = hero_skill_icons[hero_type]

	if skill_preview_desc:
		skill_preview_desc.text = data.get("skill_desc", "-")


func _update_bio_char_animation(delta: float) -> void:
	if not is_instance_valid(bio_char_sprite):
		return
	if not hero_anim_frames.has(_current_bio_hero_type):
		return
	var frames: Array = hero_anim_frames[_current_bio_hero_type]
	if frames.is_empty():
		return
	var cycle_dur: float = float(frames.size()) / BIO_WALK_ANIM_FPS
	_bio_anim_timer = fmod(_bio_anim_timer + delta, cycle_dur)
	var next_frame: int = int(_bio_anim_timer * BIO_WALK_ANIM_FPS) % frames.size()
	if next_frame != _bio_anim_frame:
		_bio_anim_frame = next_frame
		bio_char_sprite.texture = frames[next_frame]


func _update_pause_party_display() -> void:
	for slot_idx in range(pause_party_slots.size()):
		var slot_node = pause_party_slots[slot_idx]
		if not is_instance_valid(slot_node):
			continue

		if slot_idx < party_members.size() and is_instance_valid(party_members[slot_idx]):
			var hero = party_members[slot_idx]
			var hero_type := get_hero_type_for_node(hero)
			slot_node.visible = true

			var frame := slot_node.get_node_or_null("Frame") as TextureRect
			var portrait := slot_node.get_node_or_null("Frame/Portrait") as TextureRect
			var leader_lbl := slot_node.get_node_or_null("Leader") as Label
			var hp_bar := slot_node.get_node_or_null("HpBar") as TextureProgressBar

			if portrait and hero_portraits.has(hero_type):
				portrait.texture = hero_portraits[hero_type]

			if leader_lbl:
				# Slot 0 selalu menjadi Leader; pertahankan ruang layout di semua slot agar sejajar
				leader_lbl.visible = true
				leader_lbl.modulate.a = 1.0 if (slot_idx == 0) else 0.0

			if hp_bar:
				var max_hp = hero.get("max_health") if "max_health" in hero else 10
				var cur_hp = hero.get("current_health") if "current_health" in hero else max_hp
				hp_bar.max_value = max_hp
				hp_bar.value = cur_hp

			if frame:
				frame.modulate = Color.WHITE
		else:
			slot_node.visible = false


func _update_pause_party_hp_bars() -> void:
	for slot_idx in range(pause_party_slots.size()):
		var slot_node = pause_party_slots[slot_idx]
		if not is_instance_valid(slot_node) or not slot_node.visible:
			continue

		if slot_idx < party_members.size() and is_instance_valid(party_members[slot_idx]):
			var hero = party_members[slot_idx]
			var hp_bar := slot_node.get_node_or_null("HpBar") as TextureProgressBar
			if hp_bar:
				var cur_hp = hero.get("current_health") if "current_health" in hero else 0
				hp_bar.value = cur_hp

			var leader_lbl := slot_node.get_node_or_null("Leader") as Label
			if leader_lbl:
				leader_lbl.visible = true
				leader_lbl.modulate.a = 1.0 if (slot_idx == 0) else 0.0


# =========================================================
# GAMEPLAY HUD PARTY CARDS & SKILL SLOTS
# =========================================================

func _setup_skill_buttons() -> void:
	skill_slot_nodes = [
		$RootControl/SkillContainer/SkillSlot1,
		$RootControl/SkillContainer/SkillSlot2,
		$RootControl/SkillContainer/SkillSlot3,
		$RootControl/SkillContainer/SkillSlot4
	]

	for i in range(skill_slot_nodes.size()):
		var slot := skill_slot_nodes[i] as Control
		var slot_idx: int = i
		var btn := slot.get_node_or_null("SkillBtn") as TextureButton if is_instance_valid(slot) else null
		if btn:
			btn.pressed.connect(func(): trigger_skill_slot(slot_idx))

	update_skill_slots_hud()


func _setup_party_card_clicks() -> void:
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


func _connect_card_click(card: Control, hero_type: int) -> void:
	if not card:
		return
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var idx := get_member_index_by_hero_type(hero_type)
			if idx != -1 and idx < party_members.size() and is_instance_valid(party_members[idx]):
				var hero = party_members[idx]
				if "is_dead" in hero and hero.is_dead:
					return
				leader_switch_requested.emit(idx)
	)


func trigger_skill_slot(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < party_members.size() and is_instance_valid(party_members[slot_idx]):
		var hero = party_members[slot_idx]
		if "is_dead" in hero and hero.is_dead:
			return
		skill_activated.emit(slot_idx)


func trigger_skill_slot_by_type(hero_type: int) -> void:
	var idx := get_member_index_by_hero_type(hero_type)
	if idx != -1:
		trigger_skill_slot(idx)


func update_skill_slots_hud() -> void:
	if skill_slot_nodes.is_empty():
		return
	if party_members.is_empty():
		return

	hero_skill_map.clear()
	for i in range(skill_slot_nodes.size()):
		var slot := skill_slot_nodes[i] as Control
		if not is_instance_valid(slot):
			continue
		if i < party_members.size() and is_instance_valid(party_members[i]):
			slot.visible = true
			var h_type := get_hero_type_for_node(party_members[i])
			hero_skill_map[h_type] = slot
			var btn := slot.get_node_or_null("SkillBtn") as TextureButton
			if btn and hero_skill_icons.has(h_type):
				btn.texture_normal = hero_skill_icons[h_type]
		else:
			slot.visible = false

	_update_skill_cooldowns()


func update_party_hud() -> void:
	# Urutkan posisi kartu di PartyContainer sesuai urutan party_members
	for i in range(party_members.size()):
		var hero = party_members[i]
		if not is_instance_valid(hero):
			continue
		var hero_type := get_hero_type_for_node(hero)
		if hero_card_map.has(hero_type):
			var card = hero_card_map[hero_type]
			if is_instance_valid(card) and party_container:
				party_container.move_child(card, i)

	update_skill_slots_hud()
	_update_hp_bars()
	update_leader_indicator()


func _update_hp_bars() -> void:
	for h_type in hero_card_map.keys():
		var card = hero_card_map[h_type]
		if not is_instance_valid(card):
			continue
		var hero := get_member_by_hero_type(h_type)
		if is_instance_valid(hero):
			var max_hp = hero.get("max_health") if "max_health" in hero else 10
			var cur_hp: int = hero.get("current_health") if "current_health" in hero else max_hp
			var is_dead: bool = hero.get("is_dead") if "is_dead" in hero else (cur_hp <= 0)

			var hp_bar = card.get_node_or_null("LifeBar") as TextureProgressBar
			if hp_bar:
				hp_bar.max_value = max_hp
				hp_bar.value = cur_hp

			var portrait = card.get_node_or_null("Portrait") as TextureRect
			if portrait:
				portrait.modulate = Color(0.35, 0.35, 0.35, 0.55) if is_dead else Color.WHITE

			var name_label = card.get_node_or_null("NameLabel") as Label
			if name_label:
				var def_name: String = HERO_NAMES.get(h_type, hero.name)
				if is_dead:
					name_label.text = "KO"
					name_label.add_theme_color_override("font_color", Color(0.78, 0.16, 0.16, 1.0))
				else:
					name_label.text = def_name
					name_label.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))


func _update_skill_cooldowns() -> void:
	for i in range(skill_slot_nodes.size()):
		var slot := skill_slot_nodes[i] as Control
		if not is_instance_valid(slot):
			continue
		var cd_overlay = slot.find_child("CooldownOverlay", true, false) as ColorRect
		var cd_label = slot.find_child("CooldownLabel", true, false) as Label
		if not cd_overlay:
			continue

		var hero: CharacterBody2D = party_members[i] if (i < party_members.size()) else null
		if is_instance_valid(hero):
			var is_dead: bool = hero.get("is_dead") if "is_dead" in hero else false
			var cd: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
			if is_dead:
				cd_overlay.visible = true
				if cd_label:
					cd_label.visible = false
			elif cd > 0.05:
				cd_overlay.visible = true
				if cd_label:
					cd_label.visible = true
					cd_label.text = "%.1f" % cd
			else:
				cd_overlay.visible = false
				if cd_label:
					cd_label.visible = false
		else:
			cd_overlay.visible = false
			if cd_label:
				cd_label.visible = false


func update_leader_indicator() -> void:
	var active_type := get_hero_type_for_node(active_leader_node)
	for h_type in hero_card_map.keys():
		var card = hero_card_map[h_type]
		if not is_instance_valid(card):
			continue
		var indicator = card.get_node_or_null("LeaderIndicator") as Control
		if indicator:
			indicator.visible = (h_type == active_type)


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
# LOCATION BANNER NOTIFICATION
# =========================================================

func hide_location_banner() -> void:
	"""Menghentikan animasi banner lokasi yang berjalan dan menyembunyikannya dengan rapi."""
	if _location_banner_tween and _location_banner_tween.is_valid():
		_location_banner_tween.kill()
	_location_banner_tween = null
	if is_instance_valid(location_banner):
		location_banner.visible = false
		location_banner.modulate.a = 0.0
		location_banner.position.y = _location_banner_rest_y


func show_location_banner(location_name: String) -> void:
	"""Menampilkan banner lokasi dengan slide turun + fade in, tahan sejenak, lalu fade out + slide ke atas."""
	if is_start_menu_mode or not is_instance_valid(location_banner) or not is_instance_valid(location_label):
		return

	var clean_name := location_name.strip_edges()
	if clean_name.is_empty():
		return

	hide_location_banner()
	location_label.text = clean_name

	var hidden_y := _location_banner_rest_y - LOCATION_BANNER_SLIDE_OFFSET
	location_banner.position.y = hidden_y
	location_banner.modulate.a = 0.0
	location_banner.visible = true

	_location_banner_tween = create_tween()
	_location_banner_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)

	# Masuk: slide dari atas ke bawah bersamaan dengan fade in
	_location_banner_tween.tween_property(location_banner, "position:y", _location_banner_rest_y, LOCATION_BANNER_IN_DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_location_banner_tween.parallel().tween_property(location_banner, "modulate:a", 1.0, LOCATION_BANNER_FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Tahan agar terbaca jelas oleh pemain
	_location_banner_tween.tween_interval(LOCATION_BANNER_HOLD_DURATION)

	# Keluar: fade out bersamaan dengan slide kembali ke atas
	_location_banner_tween.tween_property(location_banner, "position:y", hidden_y, LOCATION_BANNER_OUT_DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_location_banner_tween.parallel().tween_property(location_banner, "modulate:a", 0.0, LOCATION_BANNER_FADE_OUT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_location_banner_tween.tween_callback(func():
		if is_instance_valid(location_banner):
			location_banner.visible = false
			location_banner.position.y = _location_banner_rest_y
		_location_banner_tween = null
	)


# =========================================================
# INVENTORY SYSTEM & CATEGORY NAVIGATION
# =========================================================

func _set_inventory_category(cat_idx: int) -> void:
	current_inventory_category = clampi(cat_idx, 0, 3)
	selected_item_category_index = 0
	if inv_scroll_container:
		inv_scroll_container.scroll_vertical = 0
	_refresh_inventory_ui()




func _on_btn_prev_category_pressed() -> void:
	var next_cat: int = (current_inventory_category - 1 + 4) % 4
	_set_inventory_category(next_cat)


func _on_btn_next_category_pressed() -> void:
	var next_cat: int = (current_inventory_category + 1) % 4
	_set_inventory_category(next_cat)


func _get_filtered_inventory_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in inventory_items:
		if item.get("category", 0) == current_inventory_category:
			result.append(item)
	return result


func _refresh_inventory_ui() -> void:
	if not is_instance_valid(page_inventory):
		return

	# Update category button styles
	for i in range(inv_cat_btns.size()):
		var cat_box = inv_cat_btns[i] as NinePatchRect
		if is_instance_valid(cat_box):
			var is_sel: bool = (i == current_inventory_category)
			cat_box.texture = cat_btn_selected_tex if is_sel else cat_btn_normal_tex
			cat_box.patch_margin_left = 4
			cat_box.patch_margin_top = 3
			cat_box.patch_margin_right = 4
			cat_box.patch_margin_bottom = 3

	# Filter items by current category
	_filtered_inventory_items = _get_filtered_inventory_items()

	# Clamp selected index
	if _filtered_inventory_items.is_empty():
		selected_item_category_index = -1
	else:
		selected_item_category_index = clampi(selected_item_category_index, 0, _filtered_inventory_items.size() - 1)

	# Update capacity label (e.g. 1/50)
	if inv_label_capacity:
		inv_label_capacity.text = "%d/50" % inventory_items.size()

	# Rebuild item grid
	if is_instance_valid(inv_item_grid):
		for child in inv_item_grid.get_children():
			child.queue_free()

		var total_slots: int = maxi(12, _filtered_inventory_items.size())
		for slot_idx in range(total_slots):
			var slot_node = _create_inventory_slot_node(slot_idx)
			inv_item_grid.add_child(slot_node)

	# Update right page detail panel
	_update_inventory_detail_panel()

	# Synchronize scrollbar
	_sync_inventory_scrollbar.call_deferred()


func _create_inventory_slot_node(slot_idx: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(60, 58)
	slot.mouse_filter = Control.MOUSE_FILTER_PASS

	# Base slot background
	var bg := NinePatchRect.new()
	bg.texture = item_slot_tex
	bg.patch_margin_left = 6
	bg.patch_margin_top = 6
	bg.patch_margin_right = 6
	bg.patch_margin_bottom = 6
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(bg)

	var has_item: bool = (slot_idx < _filtered_inventory_items.size())
	if has_item:
		var item: Dictionary = _filtered_inventory_items[slot_idx]

		# Item Icon
		var icon := TextureRect.new()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(36, 36)
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.offset_left = -18
		icon.offset_top = -18
		icon.offset_right = 18
		icon.offset_bottom = 18
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if item.has("icon_texture") and item["icon_texture"] != null:
			icon.texture = item["icon_texture"]
		elif item.has("icon_rect"):
			icon.texture = _create_atlas(preload("res://assets/ui/menus/common/ui_menu_sheet.png"), item["icon_rect"])
		slot.add_child(icon)

		# Quantity badge (if > 1)
		var qty: int = item.get("quantity", 1)
		if qty > 1:
			var count_lbl := Label.new()
			count_lbl.text = str(qty)
			count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_lbl.offset_left = -30
			count_lbl.offset_top = -18
			count_lbl.offset_right = -4
			count_lbl.offset_bottom = -2
			count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_lbl.add_theme_font_override("font", preload("res://assets/ui/fonts/Beholden-Bold.ttf"))
			count_lbl.add_theme_font_size_override("font_size", 13)
			count_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.85, 1))
			count_lbl.add_theme_color_override("font_shadow_color", Color(0.15, 0.10, 0.10, 0.9))
			count_lbl.add_theme_constant_override("shadow_offset_x", 1)
			count_lbl.add_theme_constant_override("shadow_offset_y", 1)
			count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(count_lbl)

	# Selected bracket frame
	var is_selected: bool = (has_item and slot_idx == selected_item_category_index)
	var sel_frame := NinePatchRect.new()
	sel_frame.name = "SelectedBorder"
	sel_frame.texture = item_selected_tex
	sel_frame.patch_margin_left = 6
	sel_frame.patch_margin_top = 6
	sel_frame.patch_margin_right = 6
	sel_frame.patch_margin_bottom = 6
	sel_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	sel_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sel_frame.visible = is_selected
	slot.add_child(sel_frame)

	# Click area button
	var btn := TextureButton.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if has_item:
		var click_idx: int = slot_idx
		btn.pressed.connect(func(): _on_inventory_slot_clicked(click_idx))
	slot.add_child(btn)

	return slot


func _on_inventory_slot_clicked(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < _filtered_inventory_items.size():
		selected_item_category_index = slot_idx
		_update_inventory_selection_visuals()
		_update_inventory_detail_panel()


func _update_inventory_selection_visuals() -> void:
	if not is_instance_valid(inv_item_grid):
		return
	var children = inv_item_grid.get_children()
	for i in range(children.size()):
		var slot_node = children[i] as Control
		if is_instance_valid(slot_node):
			var sel = slot_node.get_node_or_null("SelectedBorder") as NinePatchRect
			if sel:
				sel.visible = (i == selected_item_category_index)


func _update_inventory_detail_panel() -> void:
	if selected_item_category_index >= 0 and selected_item_category_index < _filtered_inventory_items.size():
		var item: Dictionary = _filtered_inventory_items[selected_item_category_index]
		if inv_detail_icon:
			if item.has("icon_texture") and item["icon_texture"] != null:
				inv_detail_icon.texture = item["icon_texture"]
			elif item.has("icon_rect"):
				inv_detail_icon.texture = _create_atlas(preload("res://assets/ui/menus/common/ui_menu_sheet.png"), item["icon_rect"])
			else:
				inv_detail_icon.texture = null
		if inv_detail_name:
			inv_detail_name.text = item.get("name", "Nama Barang")
		if inv_detail_count_label:
			inv_detail_count_label.text = str(item.get("quantity", 1))
		if inv_detail_count_container:
			inv_detail_count_container.visible = true
		if inv_detail_desc:
			inv_detail_desc.text = item.get("description", "")
		if inv_btn_gunakan:
			var can_use: bool = item.get("usable", false)
			inv_btn_gunakan.disabled = not can_use
			inv_btn_gunakan.modulate = Color.WHITE if can_use else Color(0.6, 0.6, 0.6, 0.5)
	else:
		# Empty State
		if inv_detail_icon:
			inv_detail_icon.texture = null
		if inv_detail_name:
			inv_detail_name.text = "Tidak Ada Barang"
		if inv_detail_count_container:
			inv_detail_count_container.visible = false
		if inv_detail_desc:
			inv_detail_desc.text = "Kategori ini masih kosong."
		if inv_btn_gunakan:
			inv_btn_gunakan.disabled = true
			inv_btn_gunakan.modulate = Color(0.6, 0.6, 0.6, 0.5)


func _apply_v_scrollbar_visual(scrollbar: Control, ratio: float) -> void:
	if not is_instance_valid(scrollbar):
		return
	var r: float = clampf(ratio, 0.0, 1.0)
	var track_h: float = scrollbar.size.y if scrollbar.size.y > 0.0 else 280.0
	var grabber = scrollbar.get_node_or_null("Grabber") as Control
	var grab_h: float = grabber.size.y if (grabber and grabber.size.y > 0.0) else VSCROLL_GRABBER_H
	var travel: float = maxf(1.0, track_h - grab_h - VSCROLL_INSET_TOP - VSCROLL_INSET_BOTTOM)
	if grabber:
		grabber.position.y = VSCROLL_INSET_TOP + r * travel


func _update_v_scrollbar_from_scroll(scrollbar: Control, scroll_container: ScrollContainer) -> void:
	if not is_instance_valid(scrollbar) or not is_instance_valid(scroll_container):
		return
	var v_bar = scroll_container.get_v_scroll_bar()
	if not is_instance_valid(v_bar):
		return
	var max_scroll: float = maxf(0.0, v_bar.max_value - v_bar.page)
	var ratio: float = clampf(float(scroll_container.scroll_vertical) / max_scroll, 0.0, 1.0) if max_scroll > 0.0 else 0.0
	_apply_v_scrollbar_visual(scrollbar, ratio)


func _apply_v_scrollbar_pos(scrollbar: Control, scroll_container: ScrollContainer, ratio: float, max_scroll: float) -> void:
	_apply_v_scrollbar_visual(scrollbar, ratio)
	if max_scroll > 0.0 and is_instance_valid(scroll_container):
		scroll_container.scroll_vertical = int(round(ratio * max_scroll))


func _handle_v_scrollbar_gui_input(scrollbar: Control, scroll_container: ScrollContainer, event: InputEvent, is_inventory: bool) -> void:
	if not is_instance_valid(scrollbar) or not is_instance_valid(scroll_container):
		return
	var grabber = scrollbar.get_node_or_null("Grabber") as Control
	var track_h: float = scrollbar.size.y
	var grab_h: float = grabber.size.y if (grabber and grabber.size.y > 0.0) else VSCROLL_GRABBER_H
	var travel: float = maxf(1.0, track_h - grab_h - VSCROLL_INSET_TOP - VSCROLL_INSET_BOTTOM)
	var v_bar = scroll_container.get_v_scroll_bar()
	var max_scroll: float = maxf(0.0, v_bar.max_value - v_bar.page) if v_bar else 0.0

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var click_y: float = event.position.y
			var drag_off: float
			if grabber and click_y >= grabber.position.y and click_y <= grabber.position.y + grab_h:
				drag_off = click_y - grabber.position.y
			else:
				drag_off = grab_h / 2.0
				var ratio: float = clampf((click_y - drag_off - VSCROLL_INSET_TOP) / travel, 0.0, 1.0)
				_apply_v_scrollbar_pos(scrollbar, scroll_container, ratio, max_scroll)
			if is_inventory:
				_is_dragging_inv_slider = true
				_inv_slider_drag_offset = drag_off
			else:
				_is_dragging_journal_slider = true
				_journal_slider_drag_offset = drag_off
		else:
			if is_inventory:
				_is_dragging_inv_slider = false
			else:
				_is_dragging_journal_slider = false
	elif event is InputEventMouseMotion:
		var active: bool = _is_dragging_inv_slider if is_inventory else _is_dragging_journal_slider
		if active:
			var drag_off: float = _inv_slider_drag_offset if is_inventory else _journal_slider_drag_offset
			var ratio: float = clampf((event.position.y - drag_off - VSCROLL_INSET_TOP) / travel, 0.0, 1.0)
			_apply_v_scrollbar_pos(scrollbar, scroll_container, ratio, max_scroll)


func _on_inv_scrollbar_gui_input(event: InputEvent) -> void:
	_handle_v_scrollbar_gui_input(inv_scrollbar, inv_scroll_container, event, true)


func _update_inv_slider_grabber_pos() -> void:
	_update_v_scrollbar_from_scroll(inv_scrollbar, inv_scroll_container)


func _sync_inventory_scrollbar() -> void:
	_update_inv_slider_grabber_pos()


func _on_btn_gunakan_pressed() -> void:
	if selected_item_category_index < 0 or selected_item_category_index >= _filtered_inventory_items.size():
		return
	var item: Dictionary = _filtered_inventory_items[selected_item_category_index]
	if not item.get("usable", false):
		return

	# Emit item_used signal so game logic applies effects (e.g. healing)
	item_used.emit(item)

	var qty: int = item.get("quantity", 1) - 1
	item["quantity"] = qty

	if qty <= 0:
		inventory_items.erase(item)
		_filtered_inventory_items = _get_filtered_inventory_items()
		if _filtered_inventory_items.is_empty():
			selected_item_category_index = -1
		else:
			selected_item_category_index = clampi(selected_item_category_index, 0, _filtered_inventory_items.size() - 1)

	_refresh_inventory_ui()


# =========================================================
# JOURNAL / QUEST SYSTEM LOGIC
# =========================================================

func set_quests(quests: Array[Dictionary], initial_tracked_id: String = "") -> void:
	quest_list = quests
	if initial_tracked_id != "":
		tracked_quest_id = initial_tracked_id
	elif tracked_quest_id == "" and quest_list.size() > 0:
		tracked_quest_id = quest_list[0].get("id", "")
	_refresh_journal_ui()


func _refresh_journal_ui() -> void:
	if not is_instance_valid(main_quest_container) or not is_instance_valid(world_quest_container):
		return

	# Clear previous quest item nodes
	for child in main_quest_container.get_children():
		child.queue_free()
	for child in world_quest_container.get_children():
		child.queue_free()

	# Validate selection: if selected_quest_id is empty or not in quest_list, select first valid active quest
	var found_selected: bool = false
	var first_active_main: String = ""
	var first_active_world: String = ""
	var first_any_valid: String = ""

	for q in quest_list:
		var q_id: String = q.get("id", "")
		var cat: String = str(q.get("category", "main")).to_lower()
		var status: String = str(q.get("status", "active")).to_lower()
		if first_any_valid == "":
			first_any_valid = q_id
		if status == "active":
			if (cat == "main" or cat == "story") and first_active_main == "":
				first_active_main = q_id
			elif (cat == "world" or cat == "side") and first_active_world == "":
				first_active_world = q_id
		if q_id == selected_quest_id:
			found_selected = true

	if not found_selected:
		if first_active_main != "":
			selected_quest_id = first_active_main
		elif first_active_world != "":
			selected_quest_id = first_active_world
		elif first_any_valid != "":
			selected_quest_id = first_any_valid
		else:
			selected_quest_id = ""

	var selected_quest_data: Dictionary = {}

	# Populate Main Quests
	for q in quest_list:
		var cat: String = str(q.get("category", "main")).to_lower()
		if cat == "main" or cat == "story":
			var is_sel: bool = (q.get("id", "") == selected_quest_id)
			if is_sel:
				selected_quest_data = q
			var item_node := _create_quest_item_node(q, is_sel)
			main_quest_container.add_child(item_node)

	# Populate World Quests
	for q in quest_list:
		var cat: String = str(q.get("category", "main")).to_lower()
		if cat == "world" or cat == "side":
			var is_sel: bool = (q.get("id", "") == selected_quest_id)
			if is_sel:
				selected_quest_data = q
			var item_node := _create_quest_item_node(q, is_sel)
			world_quest_container.add_child(item_node)

	# Update Detail Panel
	_update_journal_detail_panel(selected_quest_data)

	# Update Scrollbar
	call_deferred("_sync_journal_scrollbar")


func _create_quest_item_node(quest: Dictionary, is_selected: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var serif_font: Font = preload("res://assets/ui/fonts/Beholden-Bold.ttf")

	# Arrow indicator (visible if is_selected)
	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.custom_minimum_size = Vector2(14, 0)
	if serif_font:
		arrow.add_theme_font_override("font", serif_font)
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.44, 0.31, 0.27, 1.0))
	arrow.text = "▶"
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.modulate.a = 1.0 if is_selected else 0.0
	row.add_child(arrow)

	# Button panel box
	var box := NinePatchRect.new()
	box.name = "Box"
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.custom_minimum_size = Vector2(180, 32)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.texture = quest_btn_panel_tex
	box.patch_margin_left = 5
	box.patch_margin_top = 4
	box.patch_margin_right = 5
	box.patch_margin_bottom = 4
	box.mouse_filter = Control.MOUSE_FILTER_PASS

	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.layout_mode = 1
	title_lbl.anchors_preset = Control.PRESET_FULL_RECT
	title_lbl.offset_left = 10.0
	title_lbl.offset_right = -10.0
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.clip_text = true
	title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_lbl.text = quest.get("title", "Judul Misi")
	title_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
	if serif_font:
		title_lbl.add_theme_font_override("font", serif_font)
	title_lbl.add_theme_font_size_override("font_size", 16)
	box.add_child(title_lbl)

	# Click Area Button
	var btn := TextureButton.new()
	btn.name = "ClickArea"
	btn.layout_mode = 1
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var q_id: String = quest.get("id", "")
	btn.pressed.connect(func(): _select_quest(q_id))
	box.add_child(btn)

	row.set_meta("quest_id", q_id)
	row.add_child(box)
	return row


func _select_quest(q_id: String) -> void:
	selected_quest_id = q_id
	var found_quest: Dictionary = {}
	for q in quest_list:
		if q.get("id", "") == q_id:
			found_quest = q
			break

	# Update visual selection markers in both list containers
	_update_quest_list_selection_visuals(main_quest_container)
	_update_quest_list_selection_visuals(world_quest_container)

	_update_journal_detail_panel(found_quest)
	quest_selected.emit(found_quest)


func _update_quest_list_selection_visuals(container: VBoxContainer) -> void:
	if not is_instance_valid(container):
		return
	for row in container.get_children():
		var arrow = row.get_node_or_null("Arrow")
		if arrow:
			var row_qid: String = str(row.get_meta("quest_id", ""))
			arrow.modulate.a = 1.0 if (row_qid == selected_quest_id and row_qid != "") else 0.0


func _update_journal_detail_panel(quest: Dictionary) -> void:
	if is_instance_valid(journal_detail_scroll):
		journal_detail_scroll.scroll_vertical = 0
	if quest.is_empty():
		if journal_detail_title:
			journal_detail_title.text = "Tidak Ada Misi"
		if journal_detail_location:
			journal_detail_location.text = "-"
		if journal_detail_objective:
			journal_detail_objective.text = "Tidak ada petunjuk misi aktif."
		if journal_detail_desc:
			journal_detail_desc.text = "Pilih misi dari daftar di sebelah kiri untuk melihat detail petunjuk."
		if journal_btn_navigasi:
			journal_btn_navigasi.disabled = true
			journal_btn_navigasi.modulate = Color(0.6, 0.6, 0.6, 0.5)
		return

	if journal_detail_title:
		journal_detail_title.text = quest.get("title", "Judul Misi")
	if journal_detail_location:
		journal_detail_location.text = quest.get("location", "Lokasi")
	if journal_detail_objective:
		journal_detail_objective.text = quest.get("objective", "Petunjuk Misi")
	if journal_detail_desc:
		journal_detail_desc.text = quest.get("description", "Deskripsi petunjuk.")

	var has_valid_loc: bool = quest.get("location", "") != ""
	var is_active: bool = str(quest.get("status", "active")).to_lower() == "active"
	var can_nav: bool = has_valid_loc and is_active

	if journal_btn_navigasi:
		journal_btn_navigasi.disabled = not can_nav
		journal_btn_navigasi.modulate = Color.WHITE if can_nav else Color(0.6, 0.6, 0.6, 0.5)


func _on_btn_navigasi_pressed() -> void:
	var selected_quest: Dictionary = {}
	for q in quest_list:
		if q.get("id", "") == selected_quest_id:
			selected_quest = q
			break
	if selected_quest.is_empty():
		return

	tracked_quest_id = selected_quest.get("id", "")
	update_hud_quest_display(selected_quest)
	quest_tracked.emit(selected_quest)
	quest_navigation_requested.emit(selected_quest)


func update_hud_quest_display(quest: Dictionary) -> void:
	if is_instance_valid(quest_title):
		quest_title.text = quest.get("title", "Judul utama misi")
	if is_instance_valid(quest_objective):
		quest_objective.text = quest.get("objective", "objektif misi")


# --- Journal Custom Vertical Scrollbar ---

func _on_journal_scrollbar_gui_input(event: InputEvent) -> void:
	_handle_v_scrollbar_gui_input(journal_scrollbar, journal_scroll_container, event, false)


func _update_journal_slider_grabber_pos() -> void:
	_update_v_scrollbar_from_scroll(journal_scrollbar, journal_scroll_container)


func _sync_journal_scrollbar() -> void:
	_update_journal_slider_grabber_pos()


# =========================================================
# SETTINGS & AUDIO SYSTEM LOGIC (TASK 05A)
# =========================================================

func _connect_submenu_click(btn_node: Control, sub_idx: int) -> void:
	if not is_instance_valid(btn_node):
		return
	var click_area = btn_node.get_node_or_null("ClickArea") as TextureButton
	if click_area:
		click_area.pressed.connect(func(): _switch_settings_submenu(sub_idx))


func _connect_audio_slider(slider_ctrl: Control, type: String) -> void:
	if not is_instance_valid(slider_ctrl):
		return
	slider_ctrl.gui_input.connect(func(event: InputEvent):
		_on_audio_slider_gui_input(type, event, slider_ctrl)
	)


func init_audio_system() -> void:
	_ensure_audio_buses()
	load_audio_settings()


func _ensure_audio_buses() -> void:
	var needed_buses: Array[String] = ["Music", "SFX", "Dialog"]
	for bus_name in needed_buses:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			var new_idx = AudioServer.bus_count
			AudioServer.add_bus(new_idx)
			AudioServer.set_bus_name(new_idx, bus_name)
			AudioServer.set_bus_send(new_idx, &"Master")


func save_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE_PATH)
	config.set_value("audio", "master_volume", audio_settings.get("master", 65))
	config.set_value("audio", "music_volume", audio_settings.get("music", 50))
	config.set_value("audio", "sfx_volume", audio_settings.get("sfx", 50))
	config.set_value("audio", "dialog_volume", audio_settings.get("dialog", 50))
	config.save(SETTINGS_FILE_PATH)


func load_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE_PATH)
	if err == OK:
		audio_settings["master"] = int(config.get_value("audio", "master_volume", 65))
		audio_settings["music"] = int(config.get_value("audio", "music_volume", 50))
		audio_settings["sfx"] = int(config.get_value("audio", "sfx_volume", 50))
		audio_settings["dialog"] = int(config.get_value("audio", "dialog_volume", 50))
	else:
		audio_settings["master"] = 65
		audio_settings["music"] = 50
		audio_settings["sfx"] = 50
		audio_settings["dialog"] = 50

	_apply_all_audio_settings()


func _apply_all_audio_settings() -> void:
	_apply_bus_volume("Master", audio_settings.get("master", 65))
	_apply_bus_volume("Music", audio_settings.get("music", 50))
	_apply_bus_volume("SFX", audio_settings.get("sfx", 50))
	_apply_bus_volume("Dialog", audio_settings.get("dialog", 50))


func _apply_bus_volume(bus_name: String, int_val: int) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	if int_val <= 0:
		AudioServer.set_bus_mute(bus_idx, true)
		AudioServer.set_bus_volume_db(bus_idx, -80.0)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var linear: float = float(int_val) / 100.0
		var db: float = linear_to_db(linear)
		AudioServer.set_bus_volume_db(bus_idx, db)


func _switch_settings_submenu(sub_idx: int) -> void:
	if sub_idx != 1 and _rebind_action_id != "":
		_cancel_rebind()
	active_settings_submenu = sub_idx
	if is_instance_valid(submenu_audio):
		submenu_audio.visible = (sub_idx == 0)
		if sub_idx == 0:
			_sync_all_audio_sliders()
			call_deferred("_sync_all_audio_sliders")
	if is_instance_valid(submenu_controls):
		submenu_controls.visible = (sub_idx == 1)
		if sub_idx == 1:
			_refresh_controls_ui()
	if is_instance_valid(submenu_save_load):
		submenu_save_load.visible = (sub_idx == 2)
		if sub_idx == 2:
			_refresh_save_load_ui()

	_update_submenu_buttons_visual()


func _update_submenu_buttons_visual() -> void:
	if is_instance_valid(settings_btn_title):
		var back_lbl = settings_btn_title.get_node_or_null("Title") as Label
		if back_lbl:
			back_lbl.text = "Kembali" if is_start_menu_mode else "Kembali ke Judul"

	var btns: Array[NinePatchRect] = [settings_btn_audio, settings_btn_controls, settings_btn_save_load, settings_btn_title]
	for i in range(btns.size()):
		var b = btns[i]
		if is_instance_valid(b):
			var is_sel: bool = (i == active_settings_submenu)
			b.texture = submenu_btn_selected_tex if is_sel else submenu_btn_normal_tex
			var title_lbl = b.get_node_or_null("Title") as Label
			if title_lbl:
				title_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0) if is_sel else Color(0.40, 0.30, 0.30, 1.0))


func _get_slider_ctrl(type: String) -> Control:
	match type:
		"master":
			return slider_ctrl_master
		"music":
			return slider_ctrl_music
		"sfx":
			return slider_ctrl_sfx
		"dialog":
			return slider_ctrl_dialog
	return null


func _get_slider_val_label(type: String) -> Label:
	match type:
		"master":
			return slider_val_master
		"music":
			return slider_val_music
		"sfx":
			return slider_val_sfx
		"dialog":
			return slider_val_dialog
	return null


func _on_audio_slider_gui_input(type: String, event: InputEvent, slider_ctrl: Control) -> void:
	if not is_instance_valid(slider_ctrl):
		return
	var track_w: float = slider_ctrl.size.x if slider_ctrl.size.x > 0.0 else 190.0
	var grab_w: float = 16.0
	var travel: float = maxf(1.0, track_w - grab_w)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_active_dragging_slider = type
				var click_x: float = event.position.x
				var target_ratio: float = clampf((click_x - grab_w / 2.0) / travel, 0.0, 1.0)
				_set_slider_value_from_ratio(type, target_ratio)
			else:
				if _active_dragging_slider == type:
					_active_dragging_slider = ""
					save_audio_settings()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var cur_val: int = audio_settings.get(type, 50)
			_set_slider_value(type, mini(100, cur_val + 5))
			save_audio_settings()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var cur_val: int = audio_settings.get(type, 50)
			_set_slider_value(type, maxi(0, cur_val - 5))
			save_audio_settings()

	elif event is InputEventMouseMotion and _active_dragging_slider == type:
		var current_x: float = event.position.x
		var target_ratio: float = clampf((current_x - grab_w / 2.0) / travel, 0.0, 1.0)
		_set_slider_value_from_ratio(type, target_ratio)


func _set_slider_value_from_ratio(type: String, ratio: float) -> void:
	var int_val: int = int(round(clampf(ratio, 0.0, 1.0) * 100.0))
	_set_slider_value(type, int_val)


func _set_slider_value(type: String, int_val: int) -> void:
	int_val = clampi(int_val, 0, 100)
	audio_settings[type] = int_val

	# Terapkan langsung ke audio bus
	var bus_map := {
		"master": "Master",
		"music": "Music",
		"sfx": "SFX",
		"dialog": "Dialog"
	}
	var bus_name: String = bus_map.get(type, "Master")
	_apply_bus_volume(bus_name, int_val)

	_update_audio_slider_visual(type, int_val)
	settings_audio_changed.emit(
		audio_settings.get("master", 65),
		audio_settings.get("music", 50),
		audio_settings.get("sfx", 50),
		audio_settings.get("dialog", 50)
	)


func _update_audio_slider_visual(type: String, int_val: int) -> void:
	var val_lbl = _get_slider_val_label(type)
	if is_instance_valid(val_lbl):
		val_lbl.text = str(int_val)

	var s_ctrl = _get_slider_ctrl(type)
	if not is_instance_valid(s_ctrl):
		return

	var track_fill = s_ctrl.get_node_or_null("TrackFill") as Control
	var grabber = s_ctrl.get_node_or_null("Grabber") as TextureRect
	var track_w: float = s_ctrl.size.x if s_ctrl.size.x > 0.0 else 190.0
	var grab_w: float = 16.0
	var travel: float = maxf(1.0, track_w - grab_w)
	var ratio: float = float(int_val) / 100.0

	if grabber:
		if grabber.texture == null and h_grabber_tex != null:
			grabber.texture = h_grabber_tex
		var target_x: float = ratio * travel
		grabber.offset_left = target_x
		grabber.offset_right = target_x + grab_w
		grabber.offset_top = 2.0
		grabber.offset_bottom = 18.0
	if track_fill:
		track_fill.visible = (int_val > 0)
		var fill_right: float = minf(ratio * travel + grab_w / 2.0, track_w - 3.0)
		track_fill.offset_left = 3.0
		track_fill.offset_right = maxf(3.0, fill_right)
		track_fill.offset_top = 8.0
		track_fill.offset_bottom = 12.0


func _sync_all_audio_sliders() -> void:
	if h_grabber_tex == null:
		var h_grab_raw := Marshalls.base64_to_raw(H_GRABBER_B64)
		var h_grab_img := Image.create_from_data(16, 16, false, Image.FORMAT_RGBA8, h_grab_raw)
		h_grabber_tex = ImageTexture.create_from_image(h_grab_img)

	for t in ["master", "music", "sfx", "dialog"]:
		var s_ctrl = _get_slider_ctrl(t)
		if is_instance_valid(s_ctrl):
			var g_node = s_ctrl.get_node_or_null("Grabber") as TextureRect
			if g_node and g_node.texture == null:
				g_node.texture = h_grabber_tex
		var val: int = audio_settings.get(t, 50)
		_update_audio_slider_visual(t, val)


# ==========================================
# CONTROLS & KEY BINDING SYSTEM (TASK 05B)
# ==========================================

func _init_controls_system() -> void:
	load_control_settings()

	if _keycap_blank_tex == null:
		_keycap_blank_tex = _create_atlas(ACTION_BUTTONS_SHEET, Rect2(32, 464, 32, 16))

	if not is_instance_valid(control_rows_container):
		return

	for action_name in CONTROL_ACTION_ORDER:
		var info: Dictionary = CONTROL_ACTION_INFO[action_name]
		var node_name: String = info["node_name"]
		var row: Control = control_rows_container.get_node_or_null(node_name) as Control
		if row:
			var key_box: NinePatchRect = row.get_node_or_null("KeyBox") as NinePatchRect
			var key_icon: TextureRect = key_box.get_node_or_null("KeyIcon") as TextureRect if key_box else null
			var key_label: Label = key_box.get_node_or_null("KeyLabel") if key_box else null
			var click_btn: TextureButton = key_box.get_node_or_null("ClickBtn") if key_box else null
			_control_row_nodes[action_name] = {
				"row": row,
				"key_box": key_box,
				"key_icon": key_icon,
				"key_label": key_label,
				"click_btn": click_btn
			}
			if click_btn:
				click_btn.pressed.connect(_start_rebind.bind(action_name))

	_refresh_controls_ui()


func _get_control_keycap_tex(keycode: int) -> AtlasTexture:
	if _control_keycap_cache.has(keycode):
		return _control_keycap_cache[keycode]
	if CONTROL_KEYCAP_RECTS.has(keycode):
		var tex: AtlasTexture = _create_atlas(ACTION_BUTTONS_SHEET, CONTROL_KEYCAP_RECTS[keycode])
		_control_keycap_cache[keycode] = tex
		return tex
	return null


func load_control_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE_PATH)
	control_bindings.clear()
	for action_name in CONTROL_ACTION_ORDER:
		var def_k: int = CONTROL_ACTION_INFO[action_name]["default_key"]
		if err == OK and config.has_section_key("controls", action_name):
			control_bindings[action_name] = int(config.get_value("controls", action_name, def_k))
		else:
			control_bindings[action_name] = def_k

	_apply_all_control_settings()


func save_control_settings() -> void:
	var config := ConfigFile.new()
	var _err := config.load(SETTINGS_FILE_PATH)
	for action_name in CONTROL_ACTION_ORDER:
		config.set_value("controls", action_name, control_bindings.get(action_name, CONTROL_ACTION_INFO[action_name]["default_key"]))
	config.save(SETTINGS_FILE_PATH)


func _apply_all_control_settings() -> void:
	for action_name in control_bindings:
		var keycode: int = control_bindings[action_name]
		_bind_action_key(action_name, keycode)


func _bind_action_key(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	else:
		InputMap.action_erase_events(action_name)

	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)


func _format_key_name(keycode: int) -> String:
	match keycode:
		KEY_SPACE:
			return "SPACE"
		KEY_ENTER:
			return "ENTER"
		KEY_ESCAPE:
			return "ESC"
		KEY_TAB:
			return "TAB"
		KEY_SHIFT:
			return "SHIFT"
		KEY_CTRL:
			return "CTRL"
		KEY_ALT:
			return "ALT"
		KEY_UP:
			return "UP"
		KEY_DOWN:
			return "DOWN"
		KEY_LEFT:
			return "LEFT"
		KEY_RIGHT:
			return "RIGHT"
		_:
			var s: String = OS.get_keycode_string(keycode)
			if s.is_empty():
				return str(keycode)
			return s.to_upper()


func _refresh_controls_ui() -> void:
	for action_name in CONTROL_ACTION_ORDER:
		if not _control_row_nodes.has(action_name):
			continue
		var nodes: Dictionary = _control_row_nodes[action_name]
		var key_box: NinePatchRect = nodes.get("key_box")
		var key_icon: TextureRect = nodes.get("key_icon")
		var key_label: Label = nodes.get("key_label")
		if not is_instance_valid(key_box) or not is_instance_valid(key_label):
			continue

		if _rebind_action_id == action_name:
			if is_instance_valid(key_icon):
				key_icon.visible = false
			key_box.texture = _keycap_blank_tex
			key_box.self_modulate = Color(1.3, 1.15, 0.75, 1.0)
			key_box.custom_minimum_size = Vector2(36, 32)
			key_label.visible = true
			key_label.text = "..."
			key_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
		else:
			var key: int = control_bindings.get(action_name, CONTROL_ACTION_INFO[action_name]["default_key"])
			var icon_tex: AtlasTexture = _get_control_keycap_tex(key)
			if icon_tex and is_instance_valid(key_icon):
				key_box.texture = null
				key_box.self_modulate = Color.WHITE
				key_icon.texture = icon_tex
				key_icon.visible = true
				key_label.visible = false
				var reg_size: Vector2 = icon_tex.region.size
				key_box.custom_minimum_size = Vector2(reg_size.x * 2.0, reg_size.y * 2.0)
			else:
				if is_instance_valid(key_icon):
					key_icon.visible = false
				var key_str: String = _format_key_name(key)
				key_box.texture = _keycap_blank_tex
				key_box.self_modulate = Color.WHITE
				key_label.visible = true
				key_label.text = key_str
				key_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.8, 1.0))
				key_box.custom_minimum_size = Vector2(58, 32) if key_str.length() > 2 else Vector2(32, 32)

	_sync_gameplay_hud_controls_prompts()


func _sync_gameplay_hud_controls_prompts() -> void:
	var hud_bindings := {
		"party_attack": { "node": controls_prompt.get_node_or_null("ActionV/Icon") if is_instance_valid(controls_prompt) else null, "fixed_square": false, "target_h": 18.0 },
		"party_follow": { "node": controls_prompt.get_node_or_null("ActionC/Icon") if is_instance_valid(controls_prompt) else null, "fixed_square": false, "target_h": 18.0 },
		"switch_character": { "node": controls_prompt.get_node_or_null("ActionQ/Icon") if is_instance_valid(controls_prompt) else null, "fixed_square": false, "target_h": 18.0 },
		"skill_1": { "node": skill_container.get_node_or_null("SkillSlot1/Hotkey") if is_instance_valid(skill_container) else null, "fixed_square": false, "target_h": 18.0 },
		"skill_2": { "node": skill_container.get_node_or_null("SkillSlot2/Hotkey") if is_instance_valid(skill_container) else null, "fixed_square": false, "target_h": 18.0 },
		"skill_3": { "node": skill_container.get_node_or_null("SkillSlot3/Hotkey") if is_instance_valid(skill_container) else null, "fixed_square": false, "target_h": 18.0 },
		"skill_4": { "node": skill_container.get_node_or_null("SkillSlot4/Hotkey") if is_instance_valid(skill_container) else null, "fixed_square": false, "target_h": 18.0 },
		"open_journal": { "node": quest_container.get_node_or_null("QuestIcon") if is_instance_valid(quest_container) else null, "fixed_square": false, "target_h": 26.0 },
	}
	for action_name in hud_bindings.keys():
		var cfg: Dictionary = hud_bindings[action_name]
		var target_rect := cfg.get("node") as TextureRect
		if is_instance_valid(target_rect):
			var keycode: int = control_bindings.get(action_name, CONTROL_ACTION_INFO[action_name]["default_key"])
			_apply_hud_keycap_widget(target_rect, keycode, float(cfg.get("target_h", 18.0)), bool(cfg.get("fixed_square", false)))

	var interact_key: int = control_bindings.get("interact", CONTROL_ACTION_INFO["interact"]["default_key"])
	for btn_node in [inv_btn_gunakan, journal_btn_navigasi]:
		if is_instance_valid(btn_node):
			var icon_e := btn_node.get_node_or_null("IconE") as TextureRect
			if is_instance_valid(icon_e):
				_apply_hud_keycap_widget(icon_e, interact_key, 18.0, true)


func _apply_hud_keycap_widget(tex_rect: TextureRect, keycode: int, target_h: float = 18.0, fixed_square: bool = false) -> void:
	if not is_instance_valid(tex_rect):
		return
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_tex: AtlasTexture = _get_control_keycap_tex(keycode)
	var fallback_lbl := tex_rect.get_node_or_null("KeyText") as Label

	if icon_tex:
		tex_rect.texture = icon_tex
		if is_instance_valid(fallback_lbl):
			fallback_lbl.visible = false
		if not fixed_square:
			var reg_size: Vector2 = icon_tex.region.size
			var w: float = round(reg_size.x * (target_h / maxf(1.0, reg_size.y)))
			tex_rect.custom_minimum_size = Vector2(maxf(target_h, w), target_h)
	else:
		tex_rect.texture = _keycap_blank_tex
		var key_str: String = _format_key_name(keycode)
		if not fixed_square:
			tex_rect.custom_minimum_size = Vector2(36.0 if key_str.length() > 2 else target_h, target_h)
		if not is_instance_valid(fallback_lbl):
			fallback_lbl = Label.new()
			fallback_lbl.name = "KeyText"
			fallback_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			fallback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fallback_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fallback_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fallback_lbl.add_theme_font_override("font", preload("res://assets/ui/fonts/Beholden-Bold.ttf"))
			fallback_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.8, 1.0))
			tex_rect.add_child(fallback_lbl)
		fallback_lbl.add_theme_font_size_override("font_size", 8 if key_str.length() > 2 else 10)
		fallback_lbl.text = key_str
		fallback_lbl.visible = true


func _start_rebind(action_name: String) -> void:
	_rebind_action_id = action_name
	_refresh_controls_ui()


func _cancel_rebind() -> void:
	_rebind_action_id = ""
	_refresh_controls_ui()


func _apply_rebind(action_name: String, new_key: int) -> void:
	if new_key == KEY_ESCAPE:
		_cancel_rebind()
		return

	# Duplicate / conflict handling: swap keys if another action already uses this key
	var conflict_action: String = ""
	for act in control_bindings:
		if act != action_name and control_bindings[act] == new_key:
			conflict_action = act
			break

	if conflict_action != "":
		var old_key: int = control_bindings.get(action_name, CONTROL_ACTION_INFO[action_name]["default_key"])
		control_bindings[conflict_action] = old_key
		_bind_action_key(conflict_action, old_key)

	control_bindings[action_name] = new_key
	_bind_action_key(action_name, new_key)
	save_control_settings()

	_rebind_action_id = ""
	_refresh_controls_ui()


# ==========================================
# SAVE & LOAD SYSTEM (TASK 05C)
# ==========================================

func _init_save_load_system() -> void:
	# Inisialisasi texture thumbnail default
	if default_thumb_texture == null:
		var img := Image.new()
		var raw_bytes := Marshalls.base64_to_raw(DEFAULT_THUMB_B64)
		if img.load_png_from_buffer(raw_bytes) == OK:
			default_thumb_texture = ImageTexture.create_from_image(img)

	# Scan existing slot files (1..3)
	_scan_all_save_slots()

	# Hubungkan tombol klik pada setiap kartu slot
	for i in range(save_slot_rows.size()):
		var slot_idx: int = i + 1
		var row: Control = save_slot_rows[i]
		if is_instance_valid(row):
			var click_btn = row.get_node_or_null("SlotCard/ClickBtn") as TextureButton
			if click_btn and not click_btn.pressed.is_connected(_select_save_slot):
				click_btn.pressed.connect(_select_save_slot.bind(slot_idx))

	# Hubungkan Tombol Aksi Simpan & Muat
	if is_instance_valid(btn_simpan_click) and not btn_simpan_click.pressed.is_connected(_on_btn_simpan_pressed):
		btn_simpan_click.pressed.connect(_on_btn_simpan_pressed)

	if is_instance_valid(btn_muat_click) and not btn_muat_click.pressed.is_connected(_on_btn_muat_pressed):
		btn_muat_click.pressed.connect(_on_btn_muat_pressed)

	# Hubungkan Tombol Modal Konfirmasi
	if is_instance_valid(btn_confirm_yes) and not btn_confirm_yes.pressed.is_connected(_on_confirm_yes_pressed):
		btn_confirm_yes.pressed.connect(_on_confirm_yes_pressed)

	if is_instance_valid(btn_confirm_timpa) and not btn_confirm_timpa.pressed.is_connected(_on_confirm_timpa_pressed):
		btn_confirm_timpa.pressed.connect(_on_confirm_timpa_pressed)

	if is_instance_valid(btn_confirm_no) and not btn_confirm_no.pressed.is_connected(_on_confirm_no_pressed):
		btn_confirm_no.pressed.connect(_on_confirm_no_pressed)

	if is_instance_valid(enter_hint) and not enter_hint.gui_input.is_connected(_on_enter_hint_gui_input):
		enter_hint.gui_input.connect(_on_enter_hint_gui_input)

	_refresh_save_load_ui()


func _scan_all_save_slots() -> void:
	save_slots_data.clear()
	for slot_idx in range(1, 4):
		var path := "user://save_slot_%d.json" % slot_idx
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var text := f.get_as_text()
				f.close()
				var json = JSON.new()
				var err := json.parse(text)
				if err == OK and json.data is Dictionary:
					var dict: Dictionary = json.data
					# Validasi integritas data
					if dict.has("party") and dict.has("chapter"):
						save_slots_data[slot_idx] = dict
					else:
						save_slots_data[slot_idx] = {
							"corrupted": true,
							"chapter": "Data Rusak",
							"location": "-",
							"playtime": 0.0,
							"save_time_str": "-",
							"slot_id": slot_idx
						}
				else:
					save_slots_data[slot_idx] = {
						"corrupted": true,
						"chapter": "Data Rusak",
						"location": "-",
						"playtime": 0.0,
						"save_time_str": "-",
						"slot_id": slot_idx
					}
		else:
			save_slots_data[slot_idx] = null


func _select_save_slot(slot_idx: int) -> void:
	selected_save_slot = clampi(slot_idx, 1, 3)
	_refresh_save_load_ui()


func _refresh_save_load_ui() -> void:
	for i in range(save_slot_rows.size()):
		var slot_idx: int = i + 1
		var row: Control = save_slot_rows[i]
		if not is_instance_valid(row):
			continue

		var is_sel: bool = (slot_idx == selected_save_slot)
		var card = row.get_node_or_null("SlotCard") as NinePatchRect
		if card:
			card.texture = slot_card_selected_tex if is_sel else submenu_btn_normal_tex

		var occ_view = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView") as Control
		var emp_view = row.get_node_or_null("SlotCard/ContentMargin/EmptyView") as Control

		var data = save_slots_data.get(slot_idx, null)
		if data != null and data is Dictionary:
			if occ_view: occ_view.visible = true
			if emp_view: emp_view.visible = false

			var is_corrupt: bool = data.get("corrupted", false)
			var chapter_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/InfoCol/Chapter") as Label
			var loc_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/InfoCol/Location") as Label
			var play_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/InfoCol/Playtime") as Label
			var time_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/SaveTime") as Label
			var thumb = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/Thumbnail") as TextureRect

			if chapter_lbl:
				chapter_lbl.text = data.get("chapter", "Chapter 1.1")
				chapter_lbl.add_theme_color_override("font_color", Color(0.75, 0.2, 0.2, 1.0) if is_corrupt else Color(0.24, 0.15, 0.16, 1.0))
			if loc_lbl:
				loc_lbl.text = "Lokasi: " + str(data.get("location", "Istana Kerajaan"))
			if play_lbl:
				var pt: float = float(data.get("playtime", 0.0))
				play_lbl.text = "Waktu Bermain: " + _format_playtime_str(pt)
			if time_lbl:
				time_lbl.text = "Waktu Simpan: " + str(data.get("save_time_str", "-"))
			if thumb:
				thumb.visible = not is_corrupt
				if default_thumb_texture:
					thumb.texture = default_thumb_texture
		else:
			if occ_view: occ_view.visible = false
			if emp_view: emp_view.visible = true

	# Update Tombol Aksi Bawah
	var cur_data = save_slots_data.get(selected_save_slot, null)
	var has_data: bool = (cur_data != null and cur_data is Dictionary)
	var is_cur_corrupt: bool = has_data and cur_data.get("corrupted", false)

	# Tombol Simpan selalu aktif
	if is_instance_valid(btn_simpan_click):
		btn_simpan_click.disabled = false
	if is_instance_valid(btn_simpan_box):
		btn_simpan_box.modulate = Color(1.0, 1.0, 1.0, 1.0)
		btn_simpan_box.texture = submenu_btn_selected_tex

	# Tombol Muat hanya aktif jika slot terisi dan data valid
	var can_load: bool = has_data and not is_cur_corrupt
	if is_instance_valid(btn_muat_click):
		btn_muat_click.disabled = not can_load
	if is_instance_valid(btn_muat_box):
		btn_muat_box.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_load else Color(0.65, 0.65, 0.65, 0.5)
		btn_muat_box.texture = submenu_btn_normal_tex


func _format_playtime_str(seconds: float) -> String:
	var total_secs := int(seconds)
	var hrs := total_secs / 3600
	var mins := (total_secs % 3600) / 60
	var secs := total_secs % 60
	return "%02d:%02d:%02d" % [hrs, mins, secs]


func _open_confirm_modal(message: String, action: String, show_timpa: bool = false, yes_text: String = "Ya", no_text: String = "Tidak") -> void:
	_outside_modal_pressed = false
	_outside_pause_pressed = false
	_pending_confirm_action = action
	if is_instance_valid(save_confirm_msg):
		save_confirm_msg.text = message
	if is_instance_valid(btn_confirm_yes_lbl):
		btn_confirm_yes_lbl.text = yes_text
	if is_instance_valid(btn_confirm_no_lbl):
		btn_confirm_no_lbl.text = no_text
	if is_instance_valid(btn_confirm_timpa_box):
		btn_confirm_timpa_box.visible = show_timpa
	if is_instance_valid(save_confirm_modal):
		save_confirm_modal.visible = true


func _close_confirm_modal() -> void:
	_outside_modal_pressed = false
	if is_instance_valid(save_confirm_modal):
		save_confirm_modal.visible = false
	if is_instance_valid(btn_confirm_timpa_box):
		btn_confirm_timpa_box.visible = false
	_pending_confirm_action = ""


func _is_point_inside_pause_book(global_pos: Vector2) -> bool:
	for rect_node in [pause_header_banner, pause_book_bg, pause_red_bookmark, btn_close_book]:
		if is_instance_valid(rect_node) and rect_node.visible and rect_node.get_global_rect().has_point(global_pos):
			return true
	for tab_node in [tab_btn_inventory, tab_btn_journal, tab_btn_info, tab_btn_settings]:
		if is_instance_valid(tab_node) and tab_node.visible and tab_node.get_global_rect().has_point(global_pos):
			return true
	return false


## Closes the active book menu, returning either to the start menu or to live gameplay.
func _close_pause_book() -> void:
	_outside_pause_pressed = false
	if is_start_menu_mode:
		close_start_menu_settings()
	else:
		toggle_pause_menu()


## Handles pressing the top-right [X] close button on the book cover.
func _on_btn_close_book_pressed() -> void:
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return
	_close_pause_book()


func _on_pause_overlay_gui_input(event: InputEvent) -> void:
	if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	pause_overlay.accept_event()

	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		_outside_pause_pressed = false
		return
	if _is_dragging or _drag_candidate_slot_idx != -1 or _active_dragging_slider != "" or _is_dragging_inv_slider or _is_dragging_journal_slider:
		_outside_pause_pressed = false
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var inside_panel := _is_point_inside_pause_book(mb.global_position)
	if mb.pressed:
		_outside_pause_pressed = not inside_panel
	else:
		if _outside_pause_pressed and not inside_panel:
			_close_pause_book()
		else:
			_outside_pause_pressed = false


func _on_save_confirm_dimmer_gui_input(event: InputEvent) -> void:
	if not is_instance_valid(save_confirm_modal) or not save_confirm_modal.visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	save_confirm_dimmer.accept_event()
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var inside_dialog := is_instance_valid(save_confirm_dialog_box) and save_confirm_dialog_box.get_global_rect().has_point(mb.global_position)
	if mb.pressed:
		_outside_modal_pressed = not inside_dialog
	else:
		if _outside_modal_pressed and not inside_dialog:
			_outside_modal_pressed = false
			_close_confirm_modal()
		else:
			_outside_modal_pressed = false


func _on_enter_hint_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_save_load_enter_pressed()


func _on_btn_simpan_pressed() -> void:
	if is_start_menu_mode:
		_show_save_feedback("Simpan & Muat hanya tersedia saat bermain!")
		return
	var cur_data = save_slots_data.get(selected_save_slot, null)
	if cur_data != null:
		_open_confirm_modal("Timpa data simpan ini?", "overwrite")
	else:
		save_game_requested.emit(selected_save_slot)


func _on_btn_muat_pressed() -> void:
	if is_start_menu_mode:
		_show_save_feedback("Simpan & Muat hanya tersedia saat bermain!")
		return
	var cur_data = save_slots_data.get(selected_save_slot, null)
	if cur_data != null and not cur_data.get("corrupted", false):
		_open_confirm_modal("Muat data simpan ini?", "load")


func _on_save_load_enter_pressed() -> void:
	if is_start_menu_mode:
		_show_save_feedback("Simpan & Muat hanya tersedia saat bermain!")
		return
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		_on_confirm_yes_pressed()
		return

	var cur_data = save_slots_data.get(selected_save_slot, null)
	if cur_data == null:
		save_game_requested.emit(selected_save_slot)
	elif cur_data.get("corrupted", false):
		_open_confirm_modal("Data slot ini rusak.\nTimpa dengan data baru?", "overwrite")
	else:
		_open_confirm_modal("Slot %d sudah terisi.\nPilih Muat atau Timpa:" % selected_save_slot, "slot_action", true, "Muat", "Batal")


func _on_btn_return_to_title_pressed() -> void:
	if is_start_menu_mode:
		close_start_menu_settings()
		return

	if _rebind_action_id != "":
		_cancel_rebind()

	if is_instance_valid(save_confirm_modal):
		_open_confirm_modal("Kembali ke Start Menu?\nData belum disimpan akan hilang.", "return_to_title")
	else:
		_execute_return_to_title()


func _execute_return_to_title() -> void:
	if _rebind_action_id != "":
		_cancel_rebind()
	if return_to_title_requested.get_connections().size() > 0:
		return_to_title_requested.emit()
	else:
		get_tree().paused = false
		if is_instance_valid(pause_overlay):
			pause_overlay.visible = false
		get_tree().change_scene_to_file("res://scene/ui/menus/start_menu.tscn")


func _on_confirm_yes_pressed() -> void:
	var action := _pending_confirm_action
	_close_confirm_modal()

	if action == "overwrite" or action == "save":
		save_game_requested.emit(selected_save_slot)
	elif action == "load" or action == "slot_action":
		load_game_requested.emit(selected_save_slot)
	elif action == "return_to_title":
		_execute_return_to_title()


func _on_confirm_timpa_pressed() -> void:
	_close_confirm_modal()
	save_game_requested.emit(selected_save_slot)


func _on_confirm_no_pressed() -> void:
	_close_confirm_modal()


func _show_save_feedback(message: String) -> void:
	if not is_instance_valid(save_feedback_label):
		return
	save_feedback_label.text = message
	save_feedback_label.modulate.a = 1.0
	save_feedback_label.visible = true
	if _save_feedback_tween and _save_feedback_tween.is_valid():
		_save_feedback_tween.kill()
	_save_feedback_tween = create_tween()
	_save_feedback_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_save_feedback_tween.tween_interval(1.8)
	_save_feedback_tween.tween_property(save_feedback_label, "modulate:a", 0.0, 0.4)
	_save_feedback_tween.tween_callback(func():
		if is_instance_valid(save_feedback_label):
			save_feedback_label.visible = false
	)


func on_save_completed(slot_id: int, saved_data: Dictionary) -> void:
	save_slots_data[slot_id] = saved_data
	_refresh_save_load_ui()
	_show_save_feedback("Progress berhasil disimpan di Slot %d!" % slot_id)


func on_load_completed(slot_id: int, _loaded_data: Dictionary) -> void:
	if _save_feedback_tween and _save_feedback_tween.is_valid():
		_save_feedback_tween.kill()
	if is_instance_valid(save_feedback_label):
		save_feedback_label.visible = false
	_scan_all_save_slots()
	_refresh_save_load_ui()
	show_speech_bubble("Progress berhasil dimuat dari Slot %d!" % slot_id)
