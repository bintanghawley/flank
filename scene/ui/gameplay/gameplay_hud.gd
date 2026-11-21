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
signal dialogue_started(dialogue_id: String)
signal dialogue_advanced(entry_index: int, total_entries: int)
signal dialogue_finished(dialogue_id: String)
signal interaction_pressed(action_type: String)

@onready var root_control: Control = $RootControl

# Top-Left
@onready var btn_pause_menu: TextureButton = $RootControl/BtnPauseMenu
@onready var quest_header: Label = $RootControl/QuestHeader
@onready var quest_container: Control = $RootControl/QuestContainer
@onready var btn_hud_quest: TextureButton = $RootControl/QuestContainer/HBox/BtnHudQuest if has_node("RootControl/QuestContainer/HBox/BtnHudQuest") else ($RootControl/QuestContainer/BtnHudQuest if has_node("RootControl/QuestContainer/BtnHudQuest") else null)
@onready var quest_title: Label = $RootControl/QuestContainer/HBox/TextContainer/QuestTitle if has_node("RootControl/QuestContainer/HBox/TextContainer/QuestTitle") else ($RootControl/QuestContainer/TextContainer/QuestTitle if has_node("RootControl/QuestContainer/TextContainer/QuestTitle") else null)
@onready var quest_objective: Label = $RootControl/QuestContainer/HBox/TextContainer/QuestObjective if has_node("RootControl/QuestContainer/HBox/TextContainer/QuestObjective") else ($RootControl/QuestContainer/TextContainer/QuestObjective if has_node("RootControl/QuestContainer/TextContainer/QuestObjective") else null)

# Top-Center Location
@onready var location_banner: TextureRect = $RootControl/LocationBanner
@onready var location_label: Label = $RootControl/LocationBanner/LocationRow/LocationLabel

# Top-Right Inventory & Info Shortcuts
@onready var btn_hud_inventory: TextureButton = $RootControl/BtnHudInventory
@onready var btn_hud_info: TextureButton = $RootControl/BtnHudInfo

# Bottom-Left Controls Prompt
@onready var controls_prompt: VBoxContainer = $RootControl/ControlsPrompt

# Bottom-Left Party HUD
@onready var party_container: HBoxContainer = $RootControl/PartyContainer

# Bottom-Right Skill Bar
@onready var skill_container: HBoxContainer = $RootControl/SkillContainer

# Bottom-Center Dialogue System
@onready var dialogue_container: Control = $RootControl/DialogueContainer
@onready var dialogue_speaker_label: Label = $RootControl/DialogueContainer/NameBanner/SpeakerLabel
@onready var dialogue_portrait_frame: NinePatchRect = $RootControl/DialogueContainer/PortraitFrame
@onready var dialogue_portrait: TextureRect = $RootControl/DialogueContainer/PortraitFrame/PortraitTexture
@onready var dialogue_text: Label = $RootControl/DialogueContainer/ContentContainer/DialogueLabel
@onready var dialogue_click_btn: TextureButton = $RootControl/DialogueContainer/ClickAdvanceBtn
@onready var dialogue_prompt_arrow: TextureRect = $RootControl/DialogueContainer/AdvancePrompt/PromptArrow
@onready var dialogue_prompt_key: Label = $RootControl/DialogueContainer/AdvancePrompt/PromptKey
@onready var dialogue_prompt_text: Label = $RootControl/DialogueContainer/AdvancePrompt/PromptText

# Interaction Prompt & Objective Navigation
var _interact_prompt_panel: PanelContainer = null
var _interact_prompt_label: Label = null
var _interact_key_label: Label = null
var _interact_action_type: String = ""

var _nav_tracker_panel: Control = null
var _nav_tracker_arrow: Label = null
var _nav_tracker_label: Label = null
var _nav_target_pos: Vector2 = Vector2.ZERO
var _nav_target_name: String = ""
var _is_nav_active: bool = false

# Pause Popup Overlay & Book Menu
@onready var pause_overlay: ColorRect = $RootControl/PauseOverlay
@onready var drag_ghost: Control = $RootControl/PauseOverlay/DragGhost
@onready var drag_ghost_portrait: TextureRect = $RootControl/PauseOverlay/DragGhost/Frame/Portrait
@onready var drag_ghost_indicator: TextureRect = $RootControl/PauseOverlay/DragGhost/Indicator
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
var btn_tab_prev: TextureButton = null
var btn_tab_next: TextureButton = null
var tab_btn_prev_tex: Texture2D = null
var tab_btn_next_tex: Texture2D = null

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
@onready var controls_scroll_container: ScrollContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuControls/ControlsScroll
@onready var controls_scrollbar: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuControls/ControlsScrollBar
@onready var control_rows_container: VBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuControls/ControlsScroll/ControlRows
@onready var page_credits: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageCredits

# Save & Load UI (SubmenuSaveLoad)
@onready var save_slot_rows: Array = [
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SlotsContainer/SlotRow1,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SlotsContainer/SlotRow2,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/SlotsContainer/SlotRow3
]
@onready var save_page_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/PageIndicator/PageLabel
@onready var btn_save_prev_page: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/PageIndicator/BtnPrevPage
@onready var btn_save_next_page: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/PageIndicator/BtnNextPage
@onready var save_bottom_row: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageSettings/RightPage/SubmenuSaveLoad/BottomRow
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
@onready var btn_confirm_yes_box: NinePatchRect = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnYes
@onready var btn_confirm_yes_lbl: Label = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnYes/Label
@onready var btn_confirm_yes: TextureButton = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnYes/ClickBtn
@onready var btn_confirm_timpa_box: NinePatchRect = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnTimpa
@onready var btn_confirm_timpa: TextureButton = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnTimpa/ClickBtn
@onready var btn_confirm_no_box: NinePatchRect = $RootControl/PauseOverlay/SaveConfirmModal/DialogBox/ButtonsRow/BtnNo
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
@onready var inv_empty_state_container: VBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/EmptyStateContainer if has_node("RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/EmptyStateContainer") else null
@onready var inv_btn_gunakan: TextureButton = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/BottomRow/BtnGunakan
@onready var inv_label_gunakan: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/BottomRow/BtnGunakan/LabelGunakan if has_node("RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/BottomRow/BtnGunakan/LabelGunakan") else null
@onready var inv_label_capacity: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/LeftPage/BottomRow/CapacityContainer/LabelCapacity

# Inventory Detail UI (Right Page)
@onready var inv_detail_icon: TextureRect = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailBox/DetailIcon
@onready var inv_detail_name: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailName
@onready var inv_detail_count_container: HBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailCountContainer
@onready var inv_detail_count_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailCountContainer/DetailCountLabel
@onready var inv_detail_desc: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/DetailDesc
@onready var note_content_panel: Control = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel if has_node("RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel") else null
@onready var note_header_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel/NoteHeader/HeaderLabel if has_node("RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel/NoteHeader/HeaderLabel") else null
@onready var note_body_label: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel/ScrollContainer/BodyLabel if has_node("RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel/ScrollContainer/BodyLabel") else null
@onready var note_footer_hint: Label = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel/FooterHint if has_node("RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/NoteContentPanel/FooterHint") else null
var _reading_note_id: String = ""

const DEFAULT_NOTE_CONTENTS: Dictionary = {
	"intel_report": "LAPORAN INTELIJEN - RAHASIA ISTANA\n\nKepada: Yang Mulia Pangeran Arthur\nPengirim: Skuadron Pengintai Sayap Bayangan\n\nAktivitas komplotan bandit di sekitar perbatasan selatan meningkat pesat dalam tiga hari terakhir. Jalur pasokan logistik dan kafilah dagang mulai dihadang.\n\nMata-mata kami mengonfirmasi adanya keterlibatan sosok misterius bertopeng yang memegang lambang terlarang. Diperkirakan mereka sedang mempersiapkan serangan pengalihan di gerbang utama untuk menyusup ke ruang arsip kuno istana.\n\nHarap seluruh penjaga gerbang diperintahkan waspada penuh dan mengamankan seluruh artefak penting.",
	"soldier_diary": "CATATAN HARIAN PRAJURIT PENJAGA\n\nHari ke-14:\nKabut tebal di pos benteng utara tidak kunjung sirna. Suara gemerisik aneh terdengar dari semak belukar setiap malam. Kami mulai kekurangan persediaan obor.\n\nHari ke-21:\nGandum cadangan di lumbung mulai berjamur, namun moral prajurit tetap tegak. Kami mendengar kabar bahwa Yang Mulia Arthur dan Tuan Magnus sedang mengumpulkan para kesatria terbaik di aula istana.\n\nHari ke-28:\nSerbuan makhluk bayangan akhirnya dimulai saat fajar menyingsing. Jika pos pertahanan terluar ini runtuh, aku telah menyembunyikan kunci gerbang darurat di balik salah satu nisan tua di dekat monumen barat.\n\nSemoga dewa penjaga melindungi kerajaan ini dari kehancuran."
}
@onready var inv_target_slots_container: HBoxContainer = $RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/TargetPartySlots
@onready var inv_target_slots: Array = [
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/TargetPartySlots/Slot0,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/TargetPartySlots/Slot1,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/TargetPartySlots/Slot2,
	$RootControl/PauseOverlay/PauseBookRoot/BookContainer/PagesContainer/PageInventory/RightPage/TargetPartySlots/Slot3
]
var _is_selecting_item_target: bool = false
var selected_target_slot_index: int = -1

var party_members: Array[CharacterBody2D] = []
var active_leader_index: int = 0
var active_leader_node: CharacterBody2D = null

# Card node references for the 4 heroes in gameplay HUD
var hero_card_map: Dictionary = {} # hero_type -> Card node
var hero_card_cached_nodes: Dictionary = {} # hero_type -> { "hp_bar": TextureProgressBar, "portrait": TextureRect, "name_label": Label }
var hero_skill_map: Dictionary = {} # hero_type -> Skill slot node
var skill_slot_nodes: Array = [] # Ordered SkillSlot1..SkillSlot4 nodes matching party_members[0..3]
var skill_slot_cd_overlays: Array[ColorRect] = []
var skill_slot_cd_labels: Array[Label] = []

const LOCATION_BANNER_SLIDE_OFFSET: float = 52.0
const LOCATION_BANNER_IN_DURATION: float = 0.45
const LOCATION_BANNER_FADE_IN_DURATION: float = 0.38
const LOCATION_BANNER_HOLD_DURATION: float = 2.2
const LOCATION_BANNER_OUT_DURATION: float = 0.45
const LOCATION_BANNER_FADE_OUT_DURATION: float = 0.38
var _location_banner_rest_y: float = 32.0
var _location_banner_tween: Tween = null

# Book Menu UI SFX
const SFX_UI_HOVER: AudioStream = preload("res://assets/audio/sfx/ui/ui_hover.wav")
const SFX_BOOK_OPEN: AudioStream = preload("res://assets/audio/sfx/ui/book_open.wav")
const SFX_BOOK_CLOSE: AudioStream = preload("res://assets/audio/sfx/ui/book_close.wav")
const SFX_BOOK_PAGE_FLIP: AudioStream = preload("res://assets/audio/sfx/ui/book_page_flip.wav")
const SFX_BOOK_FLIP: AudioStream = SFX_BOOK_PAGE_FLIP
const SFX_BOOK_TAB_SELECT: AudioStream = preload("res://assets/audio/sfx/ui/book_tab_select.wav")
const SFX_BOOK_CONFIRM: AudioStream = preload("res://assets/audio/sfx/ui/book_confirm.wav")
var _last_hover_sfx_msec: int = 0

# Dialogue State & Portraits
const RAVEN_SHEET: Texture2D = preload("res://assets/characters/animal/raven/raven.png")
var portrait_raven: Texture2D = null
var portrait_king: Texture2D = null
var portrait_queen: Texture2D = null
var portrait_alaric: Texture2D = null
var portrait_wizandy: Texture2D = null
var portrait_wizashley: Texture2D = null
const PORTRAIT_ARTHUR: Texture2D = preload("res://assets/ui/gameplay/party_hud/portrait_arthur.png")
const PORTRAIT_MAGNUS: Texture2D = preload("res://assets/ui/gameplay/party_hud/portrait_magnus.png")
const PORTRAIT_ANASTASYA: Texture2D = preload("res://assets/ui/gameplay/party_hud/portrait_anastasya.png")
const PORTRAIT_HELLENE: Texture2D = preload("res://assets/ui/gameplay/party_hud/portrait_hellene.png")
const SFX_UI_CLICK: AudioStream = preload("res://assets/audio/sfx/ui/ui_click.wav")

var _is_dialogue_active: bool = false
var _last_typed_char_count: int = 0
var _dialogue_queue: Array[Dictionary] = []
var _dialogue_index: int = 0
var _dialogue_id: String = ""
var _dialogue_callback: Callable = Callable()
var _typewriter_tween: Tween = null
var _arrow_tween: Tween = null
var _is_typing: bool = false
var _current_full_text: String = ""

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
const BIO_CHAR_PIXEL_SCALE: float = 5.0
const BIO_CHAR_CENTER: Vector2 = Vector2(156.0, 120.0)
var hero_skill_icons: Dictionary = {}
var hero_portraits: Dictionary = {}
var is_start_menu_mode: bool = false
var is_hud_input_blocked: bool = false
var is_combat_hud_visible: bool = false
var is_character_switch_unlocked: bool = true
var _combat_hud_tween: Tween = null
var _outside_pause_pressed: bool = false
var _outside_modal_pressed: bool = false
var cat_btn_normal_tex: Texture2D
var cat_btn_selected_tex: Texture2D
var item_slot_tex: Texture2D
var item_selected_tex: Texture2D
var quest_btn_panel_tex: Texture2D
var _inventory_item_textures: Dictionary = {}

const CARD_FRAME_NORMAL_TEX: Texture2D = preload("res://assets/ui/gameplay/party_hud/hud_frame_character.png")
const CARD_FRAME_SELECTED_TEX: Texture2D = preload("res://assets/ui/gameplay/party_hud/hud_frame_character-selected.png")

# Journal State
var is_open_world_mode: bool = false
var quest_list: Array[Dictionary] = []
var selected_quest_id: String = ""
var tracked_quest_id: String = ""

# Inventory State
var inventory_items: Array[Dictionary] = []
var current_inventory_category: int = 0 # 0: Consumable, 1: Key, 2: Collectible, 3: Notes
var selected_item_category_index: int = 0
var _filtered_inventory_items: Array[Dictionary] = []
var _active_v_scrollbar: Control = null
var _v_scrollbar_drag_offset: float = 0.0

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
var submenu_btn_hover_tex: Texture2D = null
var ui_arrow_indicator_tex: Texture2D = null
var slot_card_selected_tex: Texture2D = null
var active_settings_submenu: int = 0
var hovered_settings_submenu: int = -1
var confirm_modal_selected_idx: int = 0
var _submenu_arrow_tweens: Dictionary = {}
var audio_settings: Dictionary = {
	"master": 100,
	"music": 100,
	"sfx": 100,
	"dialog": 100
}
var _active_dragging_slider: String = ""

# Settings Controls State
const CONTROL_ACTION_ORDER: Array[String] = [
	"use_skill",
	"interact",
	"skill_1",
	"skill_2",
	"skill_3",
	"skill_4",
	"skip",
	"open_journal",
	"open_inventory",
	"open_info"
]

const CONTROL_ACTION_INFO: Dictionary = {
	"use_skill":        { "name": "Gunakan Skill",     "default_key": KEY_E, "node_name": "RowSkill" },
	"interact":         { "name": "Interaksi",         "default_key": KEY_E, "node_name": "RowInteract" },
	"skill_1":          { "name": "Karakter 1",        "default_key": KEY_1, "node_name": "RowSkill1" },
	"skill_2":          { "name": "Karakter 2",        "default_key": KEY_2, "node_name": "RowSkill2" },
	"skill_3":          { "name": "Karakter 3",        "default_key": KEY_3, "node_name": "RowSkill3" },
	"skill_4":          { "name": "Karakter 4",        "default_key": KEY_4, "node_name": "RowSkill4" },
	"skip":             { "name": "Skip",              "default_key": KEY_SPACE, "node_name": "RowSkip" },
	"open_journal":     { "name": "Jurnal",            "default_key": KEY_J, "node_name": "RowJournal" },
	"open_inventory":   { "name": "Inventori",         "default_key": KEY_B, "node_name": "RowInventory" },
	"open_info":        { "name": "Karakter",          "default_key": KEY_C, "node_name": "RowInfo" }
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
const DEFAULT_THUMB_B64: String = "iVBORw0KGgoAAAANSUhEUgAAACwAAAAcCAIAAACVnMr7AAAFb0lEQVR4nMVXXYscVRCte/v2TM/Mzsx+kZhowIAoGnyJsBAQZBURH3zwpwi++Og/EH9HfkJAfDeaGAXjxmzYdU02MdnZ2Z2Z/rp95ZzqmWnBh4UV0g89t6vvrTpVdaqqx+THP4uICbK4gpFzSnSt11kkLirt8uklXe7lQxBxdRhleWmMzyNpZOlMEpe76jxO/C+XswEJMdXSq2DDOSW61ussEuc8RIZQanWhOqdE17XJM0hcsAVeGIenAugUoY/wW9iIb3G3FQ67Qo3RG+4Nxi9OVbbETo2u0i3o2yYHyiWHuNNlBiBioWoa1hgXFq/zeOmfo0R9N1Ri6U0ZUWmjaVRCw4zxUtYIxWIZmxY0/3D6CA8VjjkeFoMD3sCcjzQSUKdJTCxiZhrBDBanKp4KeifUIlNwhNDEw8tS5MoY928f3hKRlp/CQD6hMViLaLgGTfuqyMXxAujcJTVPQBRpIlozOmMVlkJhLBlX6+Hequ9DZ7/TFpG2z7C1S7+plHmQmJZrLyOsj/PThWEFwRzOPa4Djlt3YwXGGpHwDRCOIKox45F6eO9khuwmuYhMTk5EZFBh06DVFZFZlopIqukYJlgXCHU1w/5Bd4izJSSTDBJDdCU7UEr30rKY814s8XYjaI5JeZcHHJ5W2OQ9jrkYZpIceOMTvC1zZD2PIRmVMNNqd7Angq/mGPuth4UVi2R1+6BbXjxj3qLF23bMmipJ27xcNGynhg1LsR1wTxjBLjdVT4+pCCriLkAM28hiIj1GAvL9u/vwcgbVycoAey4CXOsSK4iwLImvk6oi56qSb8k8t5ls4CE9ot/Y2mcM2gcwvzV4i6ph+MHobxF5OgKHUoRDDv84FJFfb/6CRIyRskpQO0Ufcf3s6204M0TYrZLXQ3/MPS5SfhDb6jP8bvQBZZxj7ejT493HInJzB7XT6SHghxkoOe4gEbMUSrMjGNu+8ZGI9JI1EdnbeyIid/66i3SwTW10EDNbwOMsgH+tNpKVOEQojAli+tsLEbl87VURefj9fbA9Q1JW7CpQb8Ll3b0d+DQAlDWWnJ8gctkEhf3xJzcAorsuIjv390Tk9fyiiBytgxOTAnYqpqMgPT0LttLqK0hM+wJ18egOzBzcegAajrStwvz2p9dF5MI7MDDYRGAnAqU/5few/zn8/uKbryCfwUDCStm4iv3vvfsG+NSCx23yLJATZIeUpRY5U9PqgkqzDFAu9XB4OkWJjll+o+cjoE5w8PeDXRj2SJPtgxlbn38oIq9cA29SupYz92kBDcMOp5InwWmSfV9CxDkl0aK3ut4F5NKPIXqSIYCuBdQrmyBjtIEUtFgXZsJ+WoATnXVERfrwcmrBlbgPeY/5tikrwuWLsHs2As8a1NanM6juwvsxCuzUohbe/xKeZRnai2NX+PHebVYH/A6bOHH1ytuAOATdEsbjJEe0shy1Yyt6SdIfsx9YMsCwQ3BQSK5zpwDEIRnmeldgbO01JGJiSCKizMjtNz+AyaDjmINKB7GPcHjKbmvj5VQM2vRIQ8+wO3aCwN6QpXibU7/15AfboIscVQeGx4Ltph5O+umxnAuqSCeq4RQwbG42xAug9UDjAf0K0a9HnTI5m145//RgX+YU3epdX6gzBvTUmTcfSFh7mg/qE1XXc4rriPNKIeq9jgp7cVx/eTADTETBh8B2PmTXMX9OvluwNKrLp1rOPa3pBiAFMf/C4F153jTPteV41TmsHbNgKguerefthJy4nPWW/4cq4NJJrBLf+CLSgKt5vSKat3SgBsGA12f54eiozTIfqi3TSCgUyl0wLLb6c2e5VFPuX6L//qNUfz/qATal+VmUa82Shs6k+R+Don8AFcyt7Pq6YtsAAAAASUVORK5CYII="

const SLOTS_PER_PAGE: int = 3
var selected_save_slot: int = 1
var current_save_page: int = 1
var total_save_pages: int = 1
var save_slots_data: Dictionary = {}
var _save_feedback_tween: Tween = null
var _pending_confirm_action: String = ""
var default_thumb_texture: Texture2D = null
var last_gameplay_thumbnail_tex: Texture2D = null
var last_gameplay_thumbnail_b64: String = ""
var _slot_thumbnail_cache: Dictionary = {}

# Drag & Drop Party Management State
var _drag_candidate_slot_idx: int = -1
var _dragging_slot_idx: int = -1
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
const DRAG_THRESHOLD: float = 6.0
var _current_hovered_target_slot: int = -1
var _drag_indicator_tween: Tween = null
var drag_triangle_indicator_tex: ImageTexture = null

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
	4: "KREDIT"
}

# Character lore & bio data
const HERO_LORE: Dictionary = {
	0: {
		"display_name": "Arthur",
		"full_name": "Forzato Arthur",
		"title": "Ksatria Kerajaan",
		"race": "Manusia",
		"birthday": "31 Agustus",
		"skill_desc": "+300 Shield Point (5 dtk)\nPerisai pelindung tim\nCD 12 detik"
	},
	1: {
		"display_name": "Hellene",
		"full_name": "Carina Hellene",
		"title": "Bandit",
		"race": "Manusia",
		"birthday": "27 Mei",
		"skill_desc": "210 Damage (5x Tebasan)\nDash & Flurry Slash\nCD 8 detik"
	},
	2: {
		"display_name": "Anastasya",
		"full_name": "Astuta Anastasya",
		"title": "Pemanah Kerajaan",
		"race": "Elf",
		"birthday": "10 Maret",
		"skill_desc": "280 Piercing Damage\nTembakan panah linear\nCD 9 detik"
	},
	3: {
		"display_name": "Magnus",
		"full_name": "Pensatore Magnus",
		"title": "Penyihir Kerajaan",
		"race": "Manusia",
		"birthday": "22 November",
		"skill_desc": "220 Area Damage\nSihir ledakan meteor AoE\nCD 10 detik"
	}
}


func _ready() -> void:
	layer = 15 # Di atas elemen world game, di bawah TransitionLayer (layer 100)
	process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode

	pause_overlay.visible = false
	if is_instance_valid(location_banner):
		_location_banner_rest_y = location_banner.offset_top
		location_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
		location_banner.visible = false
		location_banner.modulate.a = 0.0

	set_combat_hud_visible(false, false)
	_setup_interact_prompt_ui()
	_setup_quest_navigation_ui()
	_check_initial_game_mode()

	# Connect Pause Menu Buttons
	if btn_pause_menu:
		btn_pause_menu.pressed.connect(_on_btn_pause_menu_pressed)
		_connect_book_hover_sfx(btn_pause_menu, true)
	for hud_shortcut in [
		{ "btn": btn_hud_inventory, "tab": 0 },
		{ "btn": btn_hud_quest, "tab": 1 },
		{ "btn": btn_hud_info, "tab": 2 },
	]:
		var sc_btn := hud_shortcut["btn"] as TextureButton
		if is_instance_valid(sc_btn):
			sc_btn.pressed.connect(_open_book_tab_from_hud.bind(int(hud_shortcut["tab"])))
			_connect_book_hover_sfx(sc_btn, true)
	for quest_widget in [quest_header, quest_container]:
		if is_instance_valid(quest_widget):
			quest_widget.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
			quest_widget.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND as Control.CursorShape
			quest_widget.gui_input.connect(_on_hud_shortcut_gui_input.bind(quest_widget, 1))
			if not quest_widget.mouse_entered.is_connected(_on_quest_container_mouse_entered):
				quest_widget.mouse_entered.connect(_on_quest_container_mouse_entered)
			if not quest_widget.mouse_exited.is_connected(_on_quest_container_mouse_exited):
				quest_widget.mouse_exited.connect(_on_quest_container_mouse_exited)

	_init_pause_menu_textures()
	_init_pause_menu_ui()
	_setup_skill_buttons()
	_setup_party_card_clicks()

	if is_instance_valid(dialogue_container):
		dialogue_container.visible = false
	if is_instance_valid(dialogue_click_btn):
		if not dialogue_click_btn.pressed.is_connected(_on_dialogue_clicked):
			dialogue_click_btn.pressed.connect(_on_dialogue_clicked)


func _safe_set_input_handled() -> void:
	if is_inside_tree():
		var vp := get_viewport()
		if is_instance_valid(vp):
			vp.set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if is_hud_input_blocked:
		return
	if _is_dialogue_active:
		if event is InputEventKey and event.pressed and not event.echo:
			var key_event := event as InputEventKey
			var kcode: int = key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
			if kcode == KEY_SPACE or kcode == KEY_ENTER or kcode == KEY_KP_ENTER or kcode == KEY_F or kcode == KEY_E:
				_advance_or_complete_dialogue()
				get_viewport().set_input_as_handled()
				return
		elif event is InputEventMouseButton and event.pressed:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_advance_or_complete_dialogue()
				get_viewport().set_input_as_handled()
				return
		get_viewport().set_input_as_handled()
		return
	if is_start_menu_mode and not pause_overlay.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if not key_event:
			return
		var key_code: int = key_event.keycode
		if key_code == 0:
			key_code = key_event.physical_keycode

		if key_code == KEY_ESCAPE:
			if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
				_safe_set_input_handled()
				_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
				_close_confirm_modal()
				return
			if pause_overlay.visible:
				if _is_selecting_item_target:
					_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
					_cancel_item_targeting()
					_safe_set_input_handled()
					return
				if _is_dragging:
					_cancel_drag()
					_drag_candidate_slot_idx = -1
					_is_dragging = false
					_current_hovered_target_slot = -1
					_safe_set_input_handled()
				else:
					toggle_pause_menu()
					_safe_set_input_handled()
				return
			else:
				if not is_start_menu_mode and not is_hud_input_blocked:
					toggle_pause_menu()
					_safe_set_input_handled()
					return

		if (key_code == KEY_ENTER or key_code == KEY_KP_ENTER or key_code == KEY_SPACE or key_code == KEY_F) and pause_overlay.visible:
			if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
				_safe_set_input_handled()
				_execute_selected_confirm_modal_button()
				return
			elif current_tab_index == 3:
				if active_settings_submenu == 2:
					_safe_set_input_handled()
					_on_save_load_enter_pressed()
					return
				elif active_settings_submenu == 3:
					_safe_set_input_handled()
					_on_btn_return_to_title_pressed()
					return
			elif current_tab_index == 0:
				_safe_set_input_handled()
				_play_tab_nav_btn_feedback(inv_btn_gunakan)
				_on_btn_gunakan_pressed()
				return
			elif current_tab_index == 1:
				_safe_set_input_handled()
				_play_tab_nav_btn_feedback(journal_btn_navigasi)
				_on_btn_navigasi_pressed()
				return

		if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
			if key_code == KEY_LEFT or key_code == KEY_A or key_code == KEY_UP or key_code == KEY_W:
				_safe_set_input_handled()
				_navigate_confirm_modal_buttons(-1)
				return
			elif key_code == KEY_RIGHT or key_code == KEY_D or key_code == KEY_DOWN or key_code == KEY_S or key_code == KEY_TAB:
				_safe_set_input_handled()
				_navigate_confirm_modal_buttons(1)
				return

		if current_tab_index == 0 and pause_overlay.visible:
			if _is_dragging:
				return
			if _reading_note_id != "":
				if key_code == KEY_ESCAPE:
					_reading_note_id = ""
					_update_inventory_detail_panel()
					_safe_set_input_handled()
					return
			if _is_selecting_item_target:
				if key_code == KEY_ESCAPE:
					_cancel_item_targeting()
					_safe_set_input_handled()
					return
				if key_code >= KEY_1 and key_code <= KEY_4:
					var target_slot: int = key_code - KEY_1
					if target_slot < party_members.size():
						_safe_set_input_handled()
						selected_target_slot_index = target_slot
						_use_item_on_party_member(target_slot)
						return
				if key_code == KEY_A or key_code == KEY_LEFT:
					_safe_set_input_handled()
					_navigate_target_slot(-1)
					return
				elif key_code == KEY_D or key_code == KEY_RIGHT:
					_safe_set_input_handled()
					_navigate_target_slot(1)
					return
				elif key_code == KEY_F or key_code == KEY_ENTER or key_code == KEY_SPACE:
					if selected_target_slot_index >= 0 and selected_target_slot_index < party_members.size():
						_safe_set_input_handled()
						_use_item_on_party_member(selected_target_slot_index)
						return
			else:
				if key_code == KEY_A or key_code == KEY_LEFT:
					_play_tab_nav_btn_feedback(inv_btn_prev_cat)
					_on_btn_prev_category_pressed()
					_safe_set_input_handled()
					return
				elif key_code == KEY_D or key_code == KEY_RIGHT:
					_play_tab_nav_btn_feedback(inv_btn_next_cat)
					_on_btn_next_category_pressed()
					_safe_set_input_handled()
					return

		if current_tab_index == 1 and pause_overlay.visible:
			if key_code == KEY_UP or key_code == KEY_W:
				_navigate_quest_relative(-1)
				_safe_set_input_handled()
				return
			elif key_code == KEY_DOWN or key_code == KEY_S:
				_navigate_quest_relative(1)
				_safe_set_input_handled()
				return

		if current_tab_index == 3 and pause_overlay.visible:
			if active_settings_submenu == 2:
				if key_code == KEY_A or key_code == KEY_LEFT:
					_change_save_page(-1)
					_safe_set_input_handled()
					return
				elif key_code == KEY_D or key_code == KEY_RIGHT:
					_change_save_page(1)
					_safe_set_input_handled()
					return
			if active_settings_submenu == 2:
				if key_code == KEY_A or key_code == KEY_LEFT:
					_change_save_page(-1)
					_safe_set_input_handled()
					return
				elif key_code == KEY_D or key_code == KEY_RIGHT:
					_change_save_page(1)
					_safe_set_input_handled()
					return
			if key_code == KEY_UP or key_code == KEY_W:
				_navigate_submenu_relative(-1)
				_safe_set_input_handled()
				return
			elif key_code == KEY_DOWN or key_code == KEY_S:
				_navigate_submenu_relative(1)
				_safe_set_input_handled()
				return

		if not is_start_menu_mode and pause_overlay.visible:
			if key_code == KEY_Q:
				_play_tab_nav_btn_feedback(btn_tab_prev)
				_navigate_tab_relative(-1)
				_safe_set_input_handled()
				return
			elif key_code == KEY_E:
				_play_tab_nav_btn_feedback(btn_tab_next)
				_navigate_tab_relative(1)
				_safe_set_input_handled()
				return
		if event.is_action_pressed("open_inventory") and not is_start_menu_mode:
			if _toggle_or_switch_book_tab(0):
				_safe_set_input_handled()
				return
		if event.is_action_pressed("open_info") and not is_start_menu_mode:
			if _toggle_or_switch_book_tab(2):
				_safe_set_input_handled()
				return
		if event.is_action_pressed("open_journal") and not is_start_menu_mode:
			if _toggle_or_switch_book_tab(1):
				_safe_set_input_handled()
				return


func _input(event: InputEvent) -> void:
	if is_hud_input_blocked:
		return
	if not pause_overlay.visible:
		return

	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			var key_code: int = event.keycode
			if key_code == 0:
				key_code = event.physical_keycode
			if key_code == KEY_ESCAPE:
				_safe_set_input_handled()
				_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
				_close_confirm_modal()
				return
			elif key_code == KEY_LEFT or key_code == KEY_A or key_code == KEY_UP or key_code == KEY_W:
				_safe_set_input_handled()
				_navigate_confirm_modal_buttons(-1)
				return
			elif key_code == KEY_RIGHT or key_code == KEY_D or key_code == KEY_DOWN or key_code == KEY_S or key_code == KEY_TAB:
				_safe_set_input_handled()
				_navigate_confirm_modal_buttons(1)
				return
			elif key_code == KEY_ENTER or key_code == KEY_KP_ENTER or key_code == KEY_SPACE or key_code == KEY_F:
				_safe_set_input_handled()
				_execute_selected_confirm_modal_button()
				return
		return

	if _rebind_action_id != "":
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.keycode == KEY_ESCAPE:
					_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
					_cancel_rebind()
					_safe_set_input_handled()
					return

				var captured_key: int = event.keycode
				if captured_key == 0:
					captured_key = event.physical_keycode

				if captured_key != 0:
					_apply_rebind(_rebind_action_id, captured_key)
			_safe_set_input_handled()
			return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
			_cancel_rebind()
			_safe_set_input_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event:
			var key_code: int = key_event.keycode
			if key_code == 0:
				key_code = key_event.physical_keycode

			if key_code == KEY_ESCAPE and _is_selecting_item_target:
				_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
				_cancel_item_targeting()
				_safe_set_input_handled()
				return

			if current_tab_index == 1:
				if key_code == KEY_UP or key_code == KEY_W:
					_navigate_quest_relative(-1)
					_safe_set_input_handled()
					return
				elif key_code == KEY_DOWN or key_code == KEY_S:
					_navigate_quest_relative(1)
					_safe_set_input_handled()
					return

			if current_tab_index == 3:
				if active_settings_submenu == 2:
					if key_code == KEY_A or key_code == KEY_LEFT:
						_change_save_page(-1)
						_safe_set_input_handled()
						return
					elif key_code == KEY_D or key_code == KEY_RIGHT:
						_change_save_page(1)
						_safe_set_input_handled()
						return
				if key_code == KEY_UP or key_code == KEY_W:
					_navigate_submenu_relative(-1)
					_safe_set_input_handled()
					return
				elif key_code == KEY_DOWN or key_code == KEY_S:
					_navigate_submenu_relative(1)
					_safe_set_input_handled()
					return
				elif (key_code == KEY_ENTER or key_code == KEY_KP_ENTER or key_code == KEY_SPACE) and active_settings_submenu == 2:
					_safe_set_input_handled()
					_on_save_load_enter_pressed()
					return
				elif (key_code == KEY_ENTER or key_code == KEY_KP_ENTER or key_code == KEY_SPACE) and active_settings_submenu == 3:
					_safe_set_input_handled()
					_on_btn_return_to_title_pressed()
					return

			if not is_start_menu_mode:
				if key_code == KEY_Q:
					_play_tab_nav_btn_feedback(btn_tab_prev)
					_navigate_tab_relative(-1)
					_safe_set_input_handled()
					return
				elif key_code == KEY_E:
					_play_tab_nav_btn_feedback(btn_tab_next)
					_navigate_tab_relative(1)
					_safe_set_input_handled()
					return

				if current_tab_index == 0:
					if _is_dragging:
						return
					if _reading_note_id != "":
						if key_code == KEY_ESCAPE:
							_reading_note_id = ""
							_update_inventory_detail_panel()
							_safe_set_input_handled()
							return
					if _is_selecting_item_target:
						if key_code == KEY_ESCAPE:
							_cancel_item_targeting()
							_safe_set_input_handled()
							return
						if key_code >= KEY_1 and key_code <= KEY_4:
							var target_slot := key_code - KEY_1
							if target_slot < party_members.size():
								_safe_set_input_handled()
								selected_target_slot_index = target_slot
								_use_item_on_party_member(target_slot)
								return
						if key_code == KEY_A or key_code == KEY_LEFT:
							_safe_set_input_handled()
							_navigate_target_slot(-1)
							return
						elif key_code == KEY_D or key_code == KEY_RIGHT:
							_safe_set_input_handled()
							_navigate_target_slot(1)
							return
						elif key_code == KEY_F or key_code == KEY_ENTER or key_code == KEY_SPACE:
							if selected_target_slot_index >= 0 and selected_target_slot_index < party_members.size():
								_safe_set_input_handled()
								_use_item_on_party_member(selected_target_slot_index)
								return
					else:
						if key_code == KEY_A or key_code == KEY_LEFT:
							_play_tab_nav_btn_feedback(inv_btn_prev_cat)
							_on_btn_prev_category_pressed()
							_safe_set_input_handled()
							return
						elif key_code == KEY_D or key_code == KEY_RIGHT:
							_play_tab_nav_btn_feedback(inv_btn_next_cat)
							_on_btn_next_category_pressed()
							_safe_set_input_handled()
							return

				if current_tab_index == 2:
					if key_code == KEY_A or key_code == KEY_LEFT:
						_play_tab_nav_btn_feedback(btn_prev_char)
						_on_btn_prev_char_pressed()
						_safe_set_input_handled()
						return
					elif key_code == KEY_D or key_code == KEY_RIGHT:
						_play_tab_nav_btn_feedback(btn_next_char)
						_on_btn_next_char_pressed()
						_safe_set_input_handled()
						return
					elif key_code >= KEY_1 and key_code <= KEY_4:
						var target_slot := key_code - KEY_1
						if target_slot < party_members.size():
							_on_party_slot_clicked(target_slot)
							_safe_set_input_handled()
							return

			if key_code == KEY_F or key_code == KEY_ENTER or key_code == KEY_KP_ENTER or key_code == KEY_SPACE:
				if current_tab_index == 0:
					_play_tab_nav_btn_feedback(inv_btn_gunakan)
					_on_btn_gunakan_pressed()
					_safe_set_input_handled()
					return
				elif current_tab_index == 1:
					_play_tab_nav_btn_feedback(journal_btn_navigasi)
					_on_btn_navigasi_pressed()
					_safe_set_input_handled()
					return

	if is_instance_valid(_active_v_scrollbar) and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_active_v_scrollbar = null

	if _active_dragging_slider != "" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_active_dragging_slider = ""
		save_audio_settings()
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -5.0)

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
		current_viewed_party_slot = current_leader_idx
	else:
		current_viewed_party_slot = 0

	update_party_hud()
	update_leader_indicator()
	_update_pause_party_display()
	_update_character_info_ui()
	_refresh_inventory_ui()


func _check_initial_game_mode() -> void:
	var game_script = load("res://scene/game.gd")
	if game_script and "selected_game_mode" in game_script:
		if str(game_script.selected_game_mode) == "open_world":
			set_open_world_mode(true)


func set_open_world_mode(enabled: bool) -> void:
	is_open_world_mode = enabled
	if is_open_world_mode:
		hide_quest_navigation()
		if is_instance_valid(quest_header):
			quest_header.visible = false
		if is_instance_valid(quest_container):
			quest_container.visible = false
	_refresh_journal_ui()


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
	hero_portraits[3] = preload("res://assets/ui/gameplay/party_hud/portrait_magnus.png")

	cat_btn_normal_tex = _create_atlas(sheet, Rect2(113, 292, 14, 9))
	cat_btn_selected_tex = _create_atlas(sheet, Rect2(113, 305, 14, 9))
	item_slot_tex = _create_atlas(sheet, Rect2(65, 289, 30, 30))
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

	for sb in [inv_scrollbar, journal_scrollbar, controls_scrollbar]:
		if is_instance_valid(sb):
			var sb_track = sb.get_node_or_null("Track") as NinePatchRect
			if sb_track and v_scroll_track_tex:
				sb_track.texture = v_scroll_track_tex
			var sb_grabber = sb.get_node_or_null("Grabber") as TextureRect
			if sb_grabber and v_scroll_grabber_tex:
				sb_grabber.texture = v_scroll_grabber_tex

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
	submenu_btn_hover_tex = _create_atlas(sheet, Rect2(145, 449, 62, 14))
	slot_card_selected_tex = _create_atlas(sheet, Rect2(145, 449, 62, 14))
	var action_sheet: Texture2D = preload("res://assets/ui/icons/actions/action_buttons.png")
	tab_btn_prev_tex = _create_atlas(action_sheet, Rect2(32, 240, 16, 16))
	tab_btn_next_tex = _create_atlas(action_sheet, Rect2(64, 208, 16, 16))

	if is_instance_valid(btn_close_book):
		var outline_col := Color8(61, 35, 38, 255)
		btn_close_book.ignore_texture_size = true
		btn_close_book.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED as TextureButton.StretchMode
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
	for hud_btn in [btn_hud_inventory, btn_hud_info]:
		if is_instance_valid(hud_btn):
			hud_btn.ignore_texture_size = true
			hud_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED as TextureButton.StretchMode
			hud_btn.texture_normal = hud_btn_normal
			hud_btn.texture_hover = hud_btn_hover
			hud_btn.texture_pressed = hud_btn_pressed
	var backpack_icon_tex := _build_backpack_icon_texture(frame_outline)
	for icon_cfg in [
		[btn_hud_inventory, backpack_icon_tex],
		[tab_btn_inventory, backpack_icon_tex],
	]:
		var target_btn := icon_cfg[0] as Control
		if is_instance_valid(target_btn):
			var btn_icon := target_btn.get_node_or_null("Icon") as TextureRect
			if btn_icon:
				btn_icon.texture = icon_cfg[1]
	if is_instance_valid(btn_hud_quest):
		btn_hud_quest.ignore_texture_size = true
		btn_hud_quest.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED as TextureButton.StretchMode
		btn_hud_quest.texture_normal = _build_hud_quest_banner_texture(
			frame_outline,
			Color8(199, 137, 93, 255),
			Color8(236, 202, 156, 255),
			Color8(255, 250, 238, 255),
			Color8(255, 244, 204, 255),
			Color8(215, 165, 110, 255),
			Color8(163, 76, 56, 255)
		)
		btn_hud_quest.texture_hover = _build_hud_quest_banner_texture(
			frame_outline,
			Color8(216, 155, 108, 255),
			Color8(252, 226, 184, 255),
			Color8(255, 255, 250, 255),
			Color8(255, 250, 224, 255),
			Color8(229, 182, 127, 255),
			Color8(192, 92, 68, 255)
		)
		btn_hud_quest.texture_pressed = _build_hud_quest_banner_texture(
			frame_outline,
			Color8(172, 114, 74, 255),
			Color8(199, 137, 93, 255),
			Color8(244, 220, 176, 255),
			Color8(236, 202, 156, 255),
			Color8(196, 142, 90, 255),
			Color8(140, 60, 44, 255)
		)

	_init_inventory_item_textures()
	if is_instance_valid(inv_detail_icon):
		inv_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST as CanvasItem.TextureFilter


func _create_atlas(tex: Texture2D, rect: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = rect
	return a


## Builds an ImageTexture from a character grid pattern and color palette.
func _build_pixel_texture(width: int, height: int, pattern: Array, palette: Dictionary) -> ImageTexture:
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


## Builds a 23x27 pixel-art banner ImageTexture with exclamation mark for the HUD quest button.
func _build_hud_quest_banner_texture(
	outline_col: Color,
	pole_col: Color,
	pole_hi_col: Color,
	cloth_hi_col: Color,
	cloth_fill_col: Color,
	seam_col: Color,
	exclamation_col: Color
) -> ImageTexture:
	var pattern: Array[String] = [
		"...#################...",
		".##ppppppppppppppppp##.",
		"#PP#################PP#",
		"#PP#HHHHHHHHHHHHHHH#PP#",
		".##FLHHHHHHHHHHHHHLF##.",
		"..#FLFFFFFFFFFFFFFLF#..",
		"..#FLFFFF!!!!!FFFFLF#..",
		"..#FLFFF!!!!!!!FFFLF#..",
		"..#FLFFF!!!!!!!FFFLF#..",
		"..#FLFFFF!!!!!FFFFLF#..",
		"..#FLFFFFF!!!FFFFFLF#..",
		"..#FLFFFFF!!!FFFFFLF#..",
		"..#FLFFFFFF!FFFFFFLF#..",
		"..#FLFFFFFF!FFFFFFLF#..",
		"..#FLFFFFFFFFFFFFFLF#..",
		"..#FLFFFFF!!!FFFFFLF#..",
		"..#FLFFFF!!!!!FFFFLF#..",
		"..#FLFFFF!!!!!FFFFLF#..",
		"..#FLFFFFF!!!FFFFFLF#..",
		"..#FLFFFFFFFFFFFFFLF#..",
		"..#FLFFFFFFFFFFFFFLF#..",
		"..#FLFFFFFF#FFFFFFLF#..",
		"..#FLFFFFF#.#FFFFFLF#..",
		"..#FLFFFF#...#FFFFLF#..",
		"..#FLFFF#.....#FFFLF#..",
		"..#FLFF#.......#FFLF#..",
		"..###.............###..",
	]
	var palette := {
		".": Color(0, 0, 0, 0),
		"#": outline_col,
		"P": pole_col,
		"p": pole_hi_col,
		"H": cloth_hi_col,
		"F": cloth_fill_col,
		"L": seam_col,
		"!": exclamation_col,
	}
	return _build_pixel_texture(23, 27, pattern, palette)


## Builds a 13x13 symmetrical pixel-art trash can ImageTexture for the save slot delete button.
func _build_trash_icon_texture(color: Color) -> ImageTexture:
	var pattern: Array[String] = [
		".............",
		".....###.....",
		"..#########..",
		".............",
		"...#######...",
		"...#.#.#.#...",
		"...#.#.#.#...",
		"...#.#.#.#...",
		"...#.#.#.#...",
		"...#######...",
		".............",
		".............",
		".............",
	]
	return _build_pixel_texture(13, 13, pattern, {"#": color})


const INVENTORY_ITEMS_SHEET_TEX: Texture2D = preload("res://assets/ui/icons/items/items_sheets.png")
const INVENTORY_BOOKS_SHEET_TEX: Texture2D = preload("res://assets/ui/menus/inventory/books.png")
const INVENTORY_CONSUMABLES_SHEET_TEX: Texture2D = preload("res://assets/ui/menus/inventory/consumables.png")

## Default icon definitions for all recognized items (fallback jika item tidak memiliki icon_rect/icon_path spesifik)
const DEFAULT_ITEM_ICON_MAPPING: Dictionary = {
	"potion_hp": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(16, 496, 16, 16)},
	"apple": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(48, 560, 16, 16)},
	"bread": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(192, 528, 16, 16)},
	"meat": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 512, 16, 16)},
	"holy_water": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(48, 496, 16, 16)},
	"carrot": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 560, 16, 16)},
	"herb": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 560, 16, 16)},
	"honey": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 496, 16, 16)},
	"cheese": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 544, 16, 16)},
	"soup": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 576, 16, 16)},
	"big_potion": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(128, 496, 16, 16)},
	"berry": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(96, 560, 16, 16)},
	"soul_elixir": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(144, 496, 16, 16)},
	"pumpkin_pie": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(208, 528, 16, 16)},
	"palace_key": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(16, 176, 16, 16)},
	"dungeon_key": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 176, 16, 16)},
	"ancient_coin": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(16, 128, 16, 16)},
	"honor_chalice": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(64, 352, 16, 16)},
	"intel_report": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 304, 16, 16)},
	"soldier_diary": {"tex": INVENTORY_ITEMS_SHEET_TEX, "rect": Rect2(0, 96, 16, 16)},
}


## Membangun cache ikon atlas item inventori dari asset asli (items_sheets.png, books.png, consumables.png).
func _init_inventory_item_textures() -> void:
	_inventory_item_textures.clear()
	for item_id in DEFAULT_ITEM_ICON_MAPPING.keys():
		var def: Dictionary = DEFAULT_ITEM_ICON_MAPPING[item_id]
		_inventory_item_textures[item_id] = _create_atlas(def["tex"], def["rect"])


## Mengambil tekstur ikon terbaik untuk item inventori dari asset asli (prioritas tekstur custom, icon_path + icon_rect, fallback atlas default).
func _resolve_inventory_item_texture(item: Dictionary) -> Texture2D:
	if item.has("icon_texture") and item["icon_texture"] != null:
		return item["icon_texture"]

	var item_id: String = str(item.get("id", ""))

	# Jika item memiliki rect daerah atlas spesifik
	if item.has("icon_rect") and item["icon_rect"] is Rect2:
		var rect: Rect2 = item["icon_rect"]
		var path_str: String = str(item.get("icon_path", ""))
		var cache_key: String = "%s_%d_%d_%d_%d" % [path_str, int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)]
		if _inventory_item_textures.has(cache_key):
			return _inventory_item_textures[cache_key]

		var base_tex: Texture2D = null
		if path_str == "res://assets/ui/menus/inventory/books.png":
			base_tex = INVENTORY_BOOKS_SHEET_TEX
		elif path_str == "res://assets/ui/menus/inventory/consumables.png":
			base_tex = INVENTORY_CONSUMABLES_SHEET_TEX
		elif path_str == "res://assets/ui/icons/items/items_sheets.png" or path_str.is_empty():
			base_tex = INVENTORY_ITEMS_SHEET_TEX
		elif ResourceLoader.exists(path_str):
			base_tex = load(path_str) as Texture2D
		else:
			base_tex = INVENTORY_ITEMS_SHEET_TEX

		if base_tex:
			var atlas := _create_atlas(base_tex, rect)
			_inventory_item_textures[cache_key] = atlas
			return atlas

	if _inventory_item_textures.has(item_id):
		return _inventory_item_textures[item_id]

	if DEFAULT_ITEM_ICON_MAPPING.has(item_id):
		var def: Dictionary = DEFAULT_ITEM_ICON_MAPPING[item_id]
		var atlas := _create_atlas(def["tex"], def["rect"])
		_inventory_item_textures[item_id] = atlas
		return atlas

	return null


## Memainkan efek suara UI secara one-shot pada bus SFX (tetap aktif saat game di-pause).
func _play_ui_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if not stream or not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
	if AudioServer.get_bus_index("SFX") != -1:
		player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	if pitch_jitter > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _on_book_ctrl_hover(ctrl: Control, only_when_unpaused: bool, is_modal_ctrl: bool, tab_idx: int) -> void:
	if not is_instance_valid(ctrl) or not ctrl.visible or not ctrl.is_visible_in_tree():
		return
	if ctrl is BaseButton and ctrl.disabled:
		return
	if only_when_unpaused:
		if is_start_menu_mode or (is_instance_valid(pause_overlay) and pause_overlay.visible):
			return
	else:
		if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
			return
	if not is_modal_ctrl and is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return
	if _is_dragging:
		return
	if tab_idx != -1 and tab_idx == current_tab_index:
		return

	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_hover_sfx_msec < 45:
		return
	_last_hover_sfx_msec = now_msec
	_play_ui_sfx(SFX_UI_HOVER, -9.0, 0.03)


func _connect_book_hover_sfx(ctrl: Control, only_when_unpaused: bool = false, is_modal_ctrl: bool = false, tab_idx: int = -1) -> void:
	if not is_instance_valid(ctrl):
		return
	if not ctrl.mouse_entered.is_connected(_on_book_ctrl_hover):
		ctrl.mouse_entered.connect(_on_book_ctrl_hover.bind(ctrl, only_when_unpaused, is_modal_ctrl, tab_idx))


func _init_pause_menu_ui() -> void:
	# Click outside to close (backdrop overlays)
	if is_instance_valid(pause_overlay):
		pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
		if not pause_overlay.gui_input.is_connected(_on_pause_overlay_gui_input):
			pause_overlay.gui_input.connect(_on_pause_overlay_gui_input)
	if is_instance_valid(save_confirm_dimmer):
		save_confirm_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
		if not save_confirm_dimmer.gui_input.is_connected(_on_save_confirm_dimmer_gui_input):
			save_confirm_dimmer.gui_input.connect(_on_save_confirm_dimmer_gui_input)
	if is_instance_valid(btn_close_book):
		if not btn_close_book.pressed.is_connected(_on_btn_close_book_pressed):
			btn_close_book.pressed.connect(_on_btn_close_book_pressed)
		_connect_book_hover_sfx(btn_close_book)

	# Tab button signals
	_connect_tab_click(tab_btn_inventory, 0)
	_connect_tab_click(tab_btn_journal, 1)
	_connect_tab_click(tab_btn_info, 2)
	_connect_tab_click(tab_btn_settings, 3)
	_connect_tab_click(tab_btn_credits, 4)
	_init_tab_navigation_buttons()
	if is_instance_valid(tab_btn_inventory):
		var tab_icon := tab_btn_inventory.get_node_or_null("Icon") as TextureRect
		if is_instance_valid(tab_icon):
			tab_icon.texture = _build_backpack_icon_texture(Color8(66, 46, 47, 255))

	# Prev / Next character signals
	if btn_prev_char:
		btn_prev_char.pressed.connect(_on_btn_prev_char_pressed)
		_connect_book_hover_sfx(btn_prev_char)
	if btn_next_char:
		btn_next_char.pressed.connect(_on_btn_next_char_pressed)
		_connect_book_hover_sfx(btn_next_char)

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
		_connect_book_hover_sfx(inv_btn_prev_cat)
	if inv_btn_next_cat:
		inv_btn_next_cat.pressed.connect(_on_btn_next_category_pressed)
		_connect_book_hover_sfx(inv_btn_next_cat)
	for i in range(inv_cat_btns.size()):
		var cat_box = inv_cat_btns[i]
		if is_instance_valid(cat_box):
			var click_area = cat_box.get_node_or_null("ClickArea") as TextureButton
			if click_area:
				var cat_idx: int = i
				click_area.pressed.connect(func(): _set_inventory_category(cat_idx))
				_connect_book_hover_sfx(click_area)

	# Inventory Gunakan Button
	if inv_btn_gunakan:
		inv_btn_gunakan.pressed.connect(_on_btn_gunakan_pressed)
		_connect_book_hover_sfx(inv_btn_gunakan)
		var icon_f := inv_btn_gunakan.get_node_or_null("IconE") as TextureRect
		if is_instance_valid(icon_f):
			_apply_hud_keycap_widget(icon_f, KEY_F, 18.0, true)

	# Inventory Target Party Slots
	for i in range(inv_target_slots.size()):
		var slot_node = inv_target_slots[i]
		if is_instance_valid(slot_node):
			var slot_idx: int = i
			var frame = slot_node.get_node_or_null("Frame") as Control
			if frame:
				frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				frame.gui_input.connect(func(event: InputEvent):
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						_on_target_slot_clicked(slot_idx)
				)
				frame.mouse_entered.connect(func(): _on_inv_target_slot_hover(slot_idx, true))
				frame.mouse_exited.connect(func(): _on_inv_target_slot_hover(slot_idx, false))

	# Ensure ONLY ONE slider in inventory, journal, and controls: hide built-in ScrollContainer bars
	_setup_custom_v_scrollbar(inv_scroll_container, inv_scrollbar, _update_inv_slider_grabber_pos)

	# Journal UI
	if journal_btn_navigasi:
		journal_btn_navigasi.pressed.connect(_on_btn_navigasi_pressed)
		_connect_book_hover_sfx(journal_btn_navigasi)
		var icon_f := journal_btn_navigasi.get_node_or_null("IconE") as TextureRect
		if is_instance_valid(icon_f):
			_apply_hud_keycap_widget(icon_f, KEY_F, 18.0, true)

	_setup_custom_v_scrollbar(journal_scroll_container, journal_scrollbar, _update_journal_slider_grabber_pos)
	_setup_custom_v_scrollbar(controls_scroll_container, controls_scrollbar, _sync_controls_scrollbar)

	if is_instance_valid(journal_detail_scroll):
		var v_bar = journal_detail_scroll.get_v_scroll_bar()
		if is_instance_valid(v_bar):
			var grabber_style := StyleBoxFlat.new()
			grabber_style.bg_color = Color(0.44, 0.31, 0.27, 0.7)
			grabber_style.set_corner_radius_all(3)
			var track_style := StyleBoxFlat.new()
			track_style.bg_color = Color(0.24, 0.15, 0.16, 0.12)
			track_style.set_corner_radius_all(2)
			v_bar.add_theme_stylebox_override("grabber", grabber_style)
			v_bar.add_theme_stylebox_override("grabber_highlight", grabber_style)
			v_bar.add_theme_stylebox_override("grabber_pressed", grabber_style)
			v_bar.add_theme_stylebox_override("scroll", track_style)

	# Settings Submenu Buttons
	_connect_submenu_click(settings_btn_audio, 0)
	_connect_submenu_click(settings_btn_controls, 1)
	_connect_submenu_click(settings_btn_save_load, 2)
	if is_instance_valid(settings_btn_title):
		var title_click = settings_btn_title.get_node_or_null("ClickArea") as TextureButton
		if title_click:
			title_click.pressed.connect(_on_btn_return_to_title_pressed)
			_connect_book_hover_sfx(title_click)
			title_click.mouse_entered.connect(func():
				_on_submenu_btn_hover(3, true)
			)
			title_click.mouse_exited.connect(func():
				_on_submenu_btn_hover(3, false)
			)

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
	is_combat_hud_visible = false
	if _combat_hud_tween and _combat_hud_tween.is_valid():
		_combat_hud_tween.kill()
	_combat_hud_tween = null
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	hide_location_banner()
	for hud_node in [btn_pause_menu, btn_hud_inventory, btn_hud_info, btn_hud_quest, quest_header, quest_container, location_banner, controls_prompt, party_container, skill_container]:
		if is_instance_valid(hud_node):
			hud_node.visible = false
	current_tab_index = 3
	active_settings_submenu = 0
	_update_tab_navigation()
	_switch_settings_submenu(0)


func open_as_start_menu_settings() -> void:
	if not is_start_menu_mode:
		enable_start_menu_mode()
	var was_open := is_instance_valid(pause_overlay) and pause_overlay.visible
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	current_tab_index = 3
	active_settings_submenu = 0
	pause_overlay.visible = true
	if not was_open:
		_play_ui_sfx(SFX_BOOK_OPEN, -2.0)
	_scan_all_save_slots()
	_update_tab_navigation()
	_switch_settings_submenu(0)


func open_as_start_menu_save_load() -> void:
	if not is_start_menu_mode:
		enable_start_menu_mode()
	var was_open := is_instance_valid(pause_overlay) and pause_overlay.visible
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	current_tab_index = 3
	active_settings_submenu = 2
	pause_overlay.visible = true
	if not was_open:
		_play_ui_sfx(SFX_BOOK_OPEN, -2.0)
	_scan_all_save_slots()
	_update_tab_navigation()
	_switch_settings_submenu(2)


func open_as_start_menu_credits() -> void:
	if not is_start_menu_mode:
		enable_start_menu_mode()
	var was_open := is_instance_valid(pause_overlay) and pause_overlay.visible
	_outside_pause_pressed = false
	_outside_modal_pressed = false
	current_tab_index = 4
	pause_overlay.visible = true
	if not was_open:
		_play_ui_sfx(SFX_BOOK_OPEN, -2.0)
	_update_tab_navigation()
	var credits_scroll: ScrollContainer = page_credits.get_node_or_null("RightPage/ScrollContainer")
	if is_instance_valid(credits_scroll):
		credits_scroll.scroll_vertical = 0


func close_start_menu_settings() -> void:
	var was_open := is_instance_valid(pause_overlay) and pause_overlay.visible
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
	if was_open:
		_play_ui_sfx(SFX_BOOK_CLOSE, -2.0)
	_reset_submenu_hover_state()
	start_menu_settings_closed.emit()


func toggle_pause_menu(initial_tab: int = 3) -> void:
	if is_hud_input_blocked:
		return
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
	if is_paused:
		_capture_gameplay_screenshot()
		hide_interact_prompt(true)
	pause_overlay.visible = is_paused
	get_tree().paused = is_paused
	_play_ui_sfx(SFX_BOOK_OPEN if is_paused else SFX_BOOK_CLOSE, -2.0)

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
		if initial_tab == 1:
			_refresh_journal_ui()
			if not is_open_world_mode and tracked_quest_id != "":
				_select_quest(tracked_quest_id)
		elif initial_tab == 3:
			active_settings_submenu = 0
			_scan_all_save_slots()
			_switch_settings_submenu(0)
			_sync_all_audio_sliders()


	else:
		_cancel_item_targeting()
		if _rebind_action_id != "":
			_cancel_rebind()
		_close_confirm_modal()
		_active_v_scrollbar = null
		if _is_dragging or _drag_candidate_slot_idx != -1:
			_cancel_drag()
			_drag_candidate_slot_idx = -1
			_is_dragging = false
			_current_hovered_target_slot = -1
		_reset_submenu_hover_state()


func _on_btn_pause_menu_pressed() -> void:
	toggle_pause_menu()


## Opens the book pause menu directly on the requested tab from a gameplay HUD shortcut.
func _open_book_tab_from_hud(tab_idx: int) -> void:
	if is_start_menu_mode:
		return
	hide_interact_prompt(true)
	if is_instance_valid(pause_overlay) and pause_overlay.visible:
		return
	toggle_pause_menu(tab_idx)


## Handles book menu tab hotkeys: opens directly to target_tab, switches to it, or closes if already open on it.
func _toggle_or_switch_book_tab(target_tab: int) -> bool:
	if is_hud_input_blocked:
		return false
	if is_start_menu_mode:
		return false
	hide_interact_prompt(true)
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return false
	if _is_dragging or _drag_candidate_slot_idx != -1:
		return false
	if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
		toggle_pause_menu(target_tab)
		return true
	if current_tab_index == target_tab:
		toggle_pause_menu()
		return true
	_on_tab_pressed(target_tab)
	return true


## Updates hover tint across both the HUD quest header label and quest row.
func _set_quest_hud_modulate(col: Color) -> void:
	for quest_widget in [quest_header, quest_container]:
		if is_instance_valid(quest_widget):
			quest_widget.modulate = col


## Opens the target book tab directly when clicking an interactive gameplay HUD widget.
func _on_hud_shortcut_gui_input(event: InputEvent, source_widget: Control = null, tab_idx: int = 1) -> void:
	if is_hud_input_blocked:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_start_menu_mode or is_combat_hud_visible or (is_instance_valid(pause_overlay) and pause_overlay.visible):
		return
	if is_instance_valid(source_widget):
		source_widget.accept_event()
	if mb.pressed:
		_open_book_tab_from_hud(tab_idx)


func _on_quest_container_mouse_entered() -> void:
	if not is_start_menu_mode and not is_combat_hud_visible and (not is_instance_valid(pause_overlay) or not pause_overlay.visible):
		_set_quest_hud_modulate(Color(1.08, 1.05, 0.92, 1.0))
		var now_msec := Time.get_ticks_msec()
		if now_msec - _last_hover_sfx_msec >= 45:
			_last_hover_sfx_msec = now_msec
			_play_ui_sfx(SFX_UI_HOVER, -9.0, 0.03)


func _on_quest_container_mouse_exited() -> void:
	if not is_combat_hud_visible:
		_set_quest_hud_modulate(Color.WHITE)


func _on_tab_pressed(tab_idx: int) -> void:
	if is_start_menu_mode and tab_idx != 3:
		return
	if current_tab_index == tab_idx:
		return
	_play_ui_sfx(SFX_BOOK_PAGE_FLIP, -2.5, 0.03)
	if tab_idx != 3:
		if _rebind_action_id != "":
			_cancel_rebind()
		_close_confirm_modal()
	_cancel_item_targeting()
	current_tab_index = tab_idx
	_update_tab_navigation()
	if tab_idx == 0:
		_refresh_inventory_ui()
	elif tab_idx == 1:
		_refresh_journal_ui()
		_sync_journal_scrollbar()
	elif tab_idx == 2:
		if active_leader_index >= 0 and active_leader_index < party_members.size():
			current_viewed_party_slot = active_leader_index
		else:
			current_viewed_party_slot = 0
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
	tab_node.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
	_connect_book_hover_sfx(tab_node, false, false, tab_idx)
	var click_area = tab_node.get_node_or_null("ClickArea") as BaseButton
	if click_area:
		click_area.mouse_filter = Control.MOUSE_FILTER_PASS as Control.MouseFilter
		click_area.pressed.connect(func(): _on_tab_pressed(tab_idx))
	tab_node.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_tab_pressed(tab_idx)
	)


func _init_tab_navigation_buttons() -> void:
	if not is_instance_valid(tabs_container):
		return
	if is_instance_valid(btn_tab_prev) and is_instance_valid(btn_tab_next):
		return

	if not tab_btn_prev_tex or not tab_btn_next_tex:
		var action_sheet: Texture2D = preload("res://assets/ui/icons/actions/action_buttons.png")
		tab_btn_prev_tex = _create_atlas(action_sheet, Rect2(32, 240, 16, 16))
		tab_btn_next_tex = _create_atlas(action_sheet, Rect2(64, 208, 16, 16))

	tabs_container.z_index = 2

	# Tombol Q (Pindah Tab ke Kiri)
	btn_tab_prev = TextureButton.new()
	btn_tab_prev.name = "BtnTabPrevQ"
	btn_tab_prev.texture_normal = tab_btn_prev_tex
	btn_tab_prev.ignore_texture_size = true
	btn_tab_prev.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED as TextureButton.StretchMode
	btn_tab_prev.custom_minimum_size = Vector2(22, 22)
	btn_tab_prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER as Control.SizeFlags
	btn_tab_prev.texture_filter = Control.TEXTURE_FILTER_NEAREST as Control.TextureFilter
	btn_tab_prev.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_tab_prev.pivot_offset = Vector2(11.0, 11.0)
	btn_tab_prev.z_index = 2
	btn_tab_prev.pressed.connect(func():
		_play_tab_nav_btn_feedback(btn_tab_prev)
		_navigate_tab_relative(-1)
	)
	_connect_book_hover_sfx(btn_tab_prev)
	btn_tab_prev.mouse_entered.connect(func():
		btn_tab_prev.modulate = Color(1.25, 1.2, 1.0, 1.0)
	)
	btn_tab_prev.mouse_exited.connect(func():
		btn_tab_prev.modulate = Color(1.0, 1.0, 1.0, 1.0)
	)

	# Tombol E (Pindah Tab ke Kanan)
	btn_tab_next = TextureButton.new()
	btn_tab_next.name = "BtnTabNextE"
	btn_tab_next.texture_normal = tab_btn_next_tex
	btn_tab_next.ignore_texture_size = true
	btn_tab_next.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED as TextureButton.StretchMode
	btn_tab_next.custom_minimum_size = Vector2(22, 22)
	btn_tab_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER as Control.SizeFlags
	btn_tab_next.texture_filter = Control.TEXTURE_FILTER_NEAREST as Control.TextureFilter
	btn_tab_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_tab_next.pivot_offset = Vector2(11.0, 11.0)
	btn_tab_next.z_index = 2
	btn_tab_next.pressed.connect(func():
		_play_tab_nav_btn_feedback(btn_tab_next)
		_navigate_tab_relative(1)
	)
	_connect_book_hover_sfx(btn_tab_next)
	btn_tab_next.mouse_entered.connect(func():
		btn_tab_next.modulate = Color(1.25, 1.2, 1.0, 1.0)
	)
	btn_tab_next.mouse_exited.connect(func():
		btn_tab_next.modulate = Color(1.0, 1.0, 1.0, 1.0)
	)

	tabs_container.add_child(btn_tab_prev)
	tabs_container.move_child(btn_tab_prev, 0)
	tabs_container.add_child(btn_tab_next)


func _play_tab_nav_btn_feedback(btn: Control) -> void:
	if not is_instance_valid(btn):
		return
	if btn.pivot_offset == Vector2.ZERO and btn.size != Vector2.ZERO:
		btn.pivot_offset = btn.size * 0.5
	var tw = create_tween()
	tw.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _navigate_tab_relative(direction: int) -> void:
	if is_start_menu_mode:
		return
	if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
		return
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return
	if _rebind_action_id != "":
		return
	if _is_dragging:
		return

	const VALID_TABS: Array[int] = [0, 1, 2, 3]
	var current_pos := VALID_TABS.find(current_tab_index)
	if current_pos == -1:
		current_pos = 0

	# Siklus tanpa mentok (modulo wrap-around)
	var next_pos := (current_pos + direction) % VALID_TABS.size()
	if next_pos < 0:
		next_pos += VALID_TABS.size()

	var target_tab: int = VALID_TABS[next_pos]
	_on_tab_pressed(target_tab)


func _update_tab_navigation() -> void:
	if pause_header_title:
		if is_start_menu_mode and active_settings_submenu == 2 and current_tab_index == 3:
			pause_header_title.text = "MEMUAT PERMAINAN"
		elif is_start_menu_mode and current_tab_index == 4:
			pause_header_title.text = "KREDIT"
		else:
			pause_header_title.text = TAB_TITLES.get(current_tab_index, "INFORMASI")

	var tab_btns: Array[Control] = [tab_btn_inventory, tab_btn_journal, tab_btn_info, tab_btn_settings]
	var pages: Array[Control] = [page_inventory, page_journal, page_info, page_settings, page_credits]

	if is_instance_valid(tab_btn_credits):
		tab_btn_credits.visible = false

	if is_instance_valid(btn_tab_prev):
		btn_tab_prev.visible = not is_start_menu_mode
	if is_instance_valid(btn_tab_next):
		btn_tab_next.visible = not is_start_menu_mode

	for i in range(tab_btns.size()):
		var tab_node = tab_btns[i]
		if is_instance_valid(tab_node):
			tab_node.visible = (not is_start_menu_mode) or (i == 3 and current_tab_index == 3)
			var is_active := (i == current_tab_index)
			if tab_node is NinePatchRect:
				tab_node.texture = tab_active_texture if is_active else tab_inactive_texture
				tab_node.patch_margin_left = 4
				tab_node.patch_margin_top = 4
				tab_node.patch_margin_right = 4
				tab_node.patch_margin_bottom = 1
			tab_node.size_flags_vertical = Control.SIZE_SHRINK_END as Control.SizeFlags
			tab_node.custom_minimum_size = Vector2(54, 42) if is_active else Vector2(50, 36)
			tab_node.self_modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.88, 0.84, 0.80, 1.0)
			tab_node.z_index = 1 if is_active else 0
			tab_node.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter

			var icon = tab_node.get_node_or_null("Icon") as TextureRect
			if icon:
				icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(1.0, 1.0, 1.0, 0.55)
				var target_icon_size: float = 22.0 if is_active else 20.0
				icon.custom_minimum_size = Vector2(target_icon_size, target_icon_size)
				var y_nudge: float = 2.0 if is_active else 1.0
				icon.offset_left = -target_icon_size / 2.0
				icon.offset_top = -target_icon_size / 2.0 + y_nudge
				icon.offset_right = target_icon_size / 2.0
				icon.offset_bottom = target_icon_size / 2.0 + y_nudge

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
	elif current_tab_index == 4:
		var credits_scroll: ScrollContainer = page_credits.get_node_or_null("RightPage/ScrollContainer")
		if is_instance_valid(credits_scroll):
			credits_scroll.scroll_vertical = 0
	else:
		_reset_submenu_hover_state()


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


func _get_drag_triangle_indicator_texture() -> ImageTexture:
	if not drag_triangle_indicator_tex:
		var pattern: Array[String] = [
			"###############",
			"#YYYYYYYYYYYYY#",
			".#YYYYYYYYYYY#.",
			"..#YYYYYYYYY#..",
			"...#YYYYYYY#...",
			"....#YYYYY#....",
			".....#YYY#.....",
			"......#Y#......",
			".......#......."
		]
		var palette := {
			"#": Color(0.11, 0.07, 0.08, 1.0),
			"Y": Color(1.0, 0.88, 0.36, 1.0),
			".": Color(0, 0, 0, 0)
		}
		drag_triangle_indicator_tex = _build_pixel_texture(15, 9, pattern, palette)
	return drag_triangle_indicator_tex


func _get_or_create_drag_indicator() -> TextureRect:
	if is_instance_valid(drag_ghost_indicator):
		if not drag_ghost_indicator.texture:
			drag_ghost_indicator.texture = _get_drag_triangle_indicator_texture()
		return drag_ghost_indicator
	if not is_instance_valid(drag_ghost):
		return null
	var indicator = drag_ghost.get_node_or_null("Indicator") as TextureRect
	if not indicator:
		indicator = TextureRect.new()
		indicator.name = "Indicator"
		indicator.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST as CanvasItem.TextureFilter
		indicator.texture = _get_drag_triangle_indicator_texture()
		indicator.custom_minimum_size = Vector2(15, 9)
		indicator.size = Vector2(15, 9)
		indicator.position = Vector2((drag_ghost.size.x - 15.0) * 0.5, -14.0)
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
		drag_ghost.add_child(indicator)
	else:
		if not indicator.texture:
			indicator.texture = _get_drag_triangle_indicator_texture()
	drag_ghost_indicator = indicator
	return indicator


func _start_drag(slot_idx: int, global_pos: Vector2) -> void:
	_dragging_slot_idx = slot_idx
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	var hero = party_members[slot_idx]
	if not is_instance_valid(hero):
		return
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -4.0, 0.03)
	var hero_type := get_hero_type_for_node(hero)

	if is_instance_valid(drag_ghost):
		if drag_ghost_portrait and hero_portraits.has(hero_type):
			drag_ghost_portrait.texture = hero_portraits[hero_type]
		drag_ghost.global_position = global_pos - Vector2(31.5, 31.5)
		drag_ghost.visible = true

		var indicator := _get_or_create_drag_indicator()
		if is_instance_valid(indicator):
			indicator.visible = true
			indicator.position.y = -14.0
			if _drag_indicator_tween and _drag_indicator_tween.is_valid():
				_drag_indicator_tween.kill()
			_drag_indicator_tween = create_tween().set_loops()
			_drag_indicator_tween.tween_property(indicator, "position:y", -17.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_drag_indicator_tween.tween_property(indicator, "position:y", -12.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
		elif i < party_members.size():
			if i == current_viewed_party_slot:
				frame.modulate = Color(1.35, 1.25, 0.75, 1.0)
			else:
				frame.modulate = Color.WHITE
		else:
			frame.modulate = Color(0.7, 0.7, 0.7, 0.45)


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
		_play_ui_sfx(SFX_BOOK_CONFIRM, -4.0)

	_dragging_slot_idx = -1
	_current_hovered_target_slot = -1


func _cancel_drag() -> void:
	_reset_drag_visuals()
	_dragging_slot_idx = -1
	_current_hovered_target_slot = -1


func _reset_drag_visuals() -> void:
	if _drag_indicator_tween and _drag_indicator_tween.is_valid():
		_drag_indicator_tween.kill()
		_drag_indicator_tween = null
	if is_instance_valid(drag_ghost):
		drag_ghost.visible = false
		var indicator := _get_or_create_drag_indicator()
		if is_instance_valid(indicator):
			indicator.visible = false
			indicator.position.y = -14.0
	for slot_idx in range(pause_party_slots.size()):
		var slot_node = pause_party_slots[slot_idx]
		if is_instance_valid(slot_node):
			var frame = slot_node.get_node_or_null("Frame") as CanvasItem
			if frame:
				if slot_idx < party_members.size():
					if slot_idx == current_viewed_party_slot:
						frame.modulate = Color(1.35, 1.25, 0.75, 1.0)
					else:
						frame.modulate = Color.WHITE
				else:
					frame.modulate = Color(0.7, 0.7, 0.7, 0.45)


func _on_party_slot_clicked(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < party_members.size():
		if current_viewed_party_slot != slot_idx:
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5, 0.03)
		current_viewed_party_slot = slot_idx
		_update_character_info_ui()
		_update_pause_party_display()


func _reorder_party_members(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= party_members.size():
		return
	if to_idx < 0 or to_idx >= party_members.size():
		return
	if from_idx == to_idx:
		return

	# Sisipkan hero ke posisi target
	var moving_hero = party_members.pop_at(from_idx)
	party_members.insert(to_idx, moving_hero)

	# Karakter di slot 0 otomatis menjadi leader
	active_leader_index = 0
	active_leader_node = party_members[0]

	# Jika hero ditaruh di slot 0 (Leader) atau posisi slot 0 berubah, langsung tampilkan biodata hero leader di slot 0
	if to_idx == 0 or from_idx == 0:
		current_viewed_party_slot = 0
	else:
		current_viewed_party_slot = to_idx

	# Pancarkan signal ke game controller untuk sinkronisasi runtime gameplay
	party_reordered.emit(party_members)

	# Perbarui UI pause menu
	_update_character_info_ui()
	_update_pause_party_display()

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
	if total_chars > 1:
		_play_ui_sfx(SFX_BOOK_PAGE_FLIP, -3.5, 0.04)
	current_viewed_party_slot = (current_viewed_party_slot - 1 + total_chars) % total_chars
	_update_character_info_ui()
	_update_pause_party_display()


func _on_btn_next_char_pressed() -> void:
	if party_members.is_empty():
		return
	var total_chars := party_members.size()
	if total_chars > 1:
		_play_ui_sfx(SFX_BOOK_PAGE_FLIP, -3.5, 0.04)
	current_viewed_party_slot = (current_viewed_party_slot + 1) % total_chars
	_update_character_info_ui()
	_update_pause_party_display()


func _format_clean_number(val: Variant) -> String:
	if val == null:
		return "0"
	if typeof(val) == TYPE_INT:
		return str(val)
	if typeof(val) == TYPE_FLOAT:
		var f: float = float(val)
		if is_equal_approx(f, roundf(f)):
			return str(int(roundf(f)))
		var snapped_str := str(snappedf(f, 0.01))
		if snapped_str.ends_with(".0"):
			return snapped_str.substr(0, snapped_str.length() - 2)
		return snapped_str
	var text_val := str(val).strip_edges()
	if text_val.ends_with(".0"):
		return text_val.substr(0, text_val.length() - 2)
	return text_val


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
		hp_str = _format_clean_number(hero.get("max_health"))
	if "attack_damage" in hero:
		atk_str = _format_clean_number(hero.get("attack_damage"))
	elif "damage" in hero:
		atk_str = _format_clean_number(hero.get("damage"))

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
				var left: float = floor(BIO_CHAR_CENTER.x - box_size.x * 0.5)
				var top: float = floor(BIO_CHAR_CENTER.y - box_size.y * 0.5)
				bio_char_sprite.offset_left = left
				bio_char_sprite.offset_top = top
				bio_char_sprite.offset_right = left + box_size.x
				bio_char_sprite.offset_bottom = top + box_size.y

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

	# Navigasi tombol panah biodata (hanya tampil jika anggota party > 1)
	if is_instance_valid(btn_prev_char):
		btn_prev_char.visible = (party_members.size() > 1)
	if is_instance_valid(btn_next_char):
		btn_next_char.visible = (party_members.size() > 1)


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
			var key_hint := slot_node.get_node_or_null("KeyHint") as TextureRect

			var is_dead_char: bool = hero.get("is_dead") if "is_dead" in hero else false
			if "current_health" in hero and hero.current_health <= 0:
				is_dead_char = true

			if portrait:
				portrait.visible = true
				if hero_portraits.has(hero_type):
					portrait.texture = hero_portraits[hero_type]
					portrait.modulate = Color(0.4, 0.4, 0.4, 0.7) if is_dead_char else Color.WHITE

			if leader_lbl:
				leader_lbl.visible = true
				leader_lbl.modulate.a = 1.0 if (slot_idx == 0 and not is_dead_char) else 0.0

			if key_hint:
				key_hint.texture = _get_control_keycap_tex(KEY_1 + slot_idx)
				key_hint.visible = true

			if hp_bar:
				hp_bar.visible = true
				var max_hp = hero.get("max_health") if "max_health" in hero else 10
				var cur_hp = hero.get("current_health") if "current_health" in hero else max_hp
				if is_dead_char:
					cur_hp = 0
				hp_bar.max_value = max_hp
				hp_bar.value = cur_hp

			if frame:
				if slot_idx == current_viewed_party_slot:
					frame.modulate = Color(1.35, 1.25, 0.75, 1.0)
				else:
					frame.modulate = Color.WHITE
		else:
			# Kotak party kosong untuk slot yang belum direkrut
			slot_node.visible = true
			var frame := slot_node.get_node_or_null("Frame") as TextureRect
			var portrait := slot_node.get_node_or_null("Frame/Portrait") as TextureRect
			var leader_lbl := slot_node.get_node_or_null("Leader") as Label
			var hp_bar := slot_node.get_node_or_null("HpBar") as TextureProgressBar
			var key_hint := slot_node.get_node_or_null("KeyHint") as TextureRect

			if leader_lbl:
				leader_lbl.modulate.a = 0.0
			if portrait:
				portrait.visible = false
				portrait.texture = null
			if hp_bar:
				hp_bar.visible = false
			if key_hint:
				key_hint.visible = false
			if frame:
				frame.modulate = Color(0.7, 0.7, 0.7, 0.45)


func _update_pause_party_hp_bars() -> void:
	for slot_idx in range(pause_party_slots.size()):
		var slot_node = pause_party_slots[slot_idx]
		if not is_instance_valid(slot_node) or not slot_node.visible:
			continue

		if slot_idx < party_members.size() and is_instance_valid(party_members[slot_idx]):
			var hero = party_members[slot_idx]
			var is_dead_char: bool = hero.get("is_dead") if "is_dead" in hero else false
			if "current_health" in hero and hero.current_health <= 0:
				is_dead_char = true

			var hp_bar := slot_node.get_node_or_null("HpBar") as TextureProgressBar
			if hp_bar:
				var cur_hp = hero.get("current_health") if "current_health" in hero else 0
				if is_dead_char:
					cur_hp = 0
				hp_bar.value = cur_hp

			var leader_lbl := slot_node.get_node_or_null("Leader") as Label
			if leader_lbl:
				leader_lbl.visible = true
				leader_lbl.modulate.a = 1.0 if (slot_idx == 0 and not is_dead_char) else 0.0


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
	skill_slot_cd_overlays.clear()
	skill_slot_cd_labels.clear()

	for i in range(skill_slot_nodes.size()):
		var slot := skill_slot_nodes[i] as Control
		var slot_idx: int = i
		var btn: TextureButton = slot.get_node_or_null("SkillBtn") as TextureButton if is_instance_valid(slot) else null
		if btn:
			btn.pressed.connect(func(): trigger_skill_slot(slot_idx))
			skill_slot_cd_overlays.append(btn.get_node_or_null("CooldownOverlay") as ColorRect)
			skill_slot_cd_labels.append(btn.get_node_or_null("CooldownLabel") as Label)
		else:
			skill_slot_cd_overlays.append(null)
			skill_slot_cd_labels.append(null)

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

	hero_card_cached_nodes.clear()
	for h_type in hero_card_map.keys():
		var card: Control = hero_card_map[h_type]
		if is_instance_valid(card):
			hero_card_cached_nodes[h_type] = {
				"hp_bar": card.get_node_or_null("LifeBar") as TextureProgressBar,
				"portrait": card.get_node_or_null("Portrait") as TextureRect,
				"name_label": card.get_node_or_null("NameLabel") as Label
			}


func _connect_card_click(card: Control, hero_type: int) -> void:
	if not card:
		return
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var idx := get_member_index_by_hero_type(hero_type)
			if idx != -1 and idx < party_members.size() and is_instance_valid(party_members[idx]):
				if not is_character_switch_unlocked:
					return
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


# =========================================================
# COMBAT HUD VISIBILITY (ARENA ONLY)
# =========================================================

func set_combat_hud_visible(active: bool, animated: bool = true) -> void:
	if is_start_menu_mode:
		return
	is_combat_hud_visible = active
	if is_instance_valid(controls_prompt):
		var action_q = controls_prompt.get_node_or_null("ActionQ")
		if is_instance_valid(action_q):
			var lbl = action_q.get_node_or_null("Label") as Label
			var ico = action_q.get_node_or_null("Icon") as TextureRect
			if active and party_members.size() > 1 and is_character_switch_unlocked:
				action_q.visible = true
				if lbl:
					lbl.text = "Ganti Karakter (1-4)"
				if ico:
					ico.visible = false
			else:
				action_q.visible = false
	if _combat_hud_tween and _combat_hud_tween.is_valid():
		_combat_hud_tween.kill()
	_combat_hud_tween = null

	var targets: Array[Control] = []
	if is_instance_valid(party_container):
		targets.append(party_container)
	if is_instance_valid(skill_container):
		targets.append(skill_container)
	if is_instance_valid(controls_prompt):
		targets.append(controls_prompt)

	var quest_targets: Array[Control] = []
	if is_instance_valid(quest_header):
		quest_targets.append(quest_header)
	if is_instance_valid(quest_container):
		quest_targets.append(quest_container)

	if not animated:
		for node in targets:
			node.visible = active
			node.modulate.a = 1.0 if active else 0.0
		var show_quest: bool = (not active) and (not _is_dialogue_active) and (not is_open_world_mode)
		for node in quest_targets:
			node.visible = show_quest
			node.modulate.a = 1.0 if show_quest else 0.0
		return

	# Animasi Fade Tersinkronisasi Sempurna:
	# Mulai dan selesai pada milidetik yang sama persis dengan kurva identik (TRANS_SINE, EASE_IN_OUT).
	_combat_hud_tween = create_tween().set_parallel(true)
	var fade_dur: float = 0.35

	if active:
		# --- MODE PERANG MULAI ---
		# UI Perang: fade IN dari 0.0 -> 1.0
		for node in targets:
			if is_instance_valid(node):
				node.visible = true
				node.modulate.a = 0.0
				_combat_hud_tween.tween_property(node, "modulate:a", 1.0, fade_dur)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# UI Quest: fade OUT dari 1.0 -> 0.0 (mulai dan selesai barengan)
		for node in quest_targets:
			if is_instance_valid(node):
				node.visible = true
				node.modulate.a = 1.0
				_combat_hud_tween.tween_property(node, "modulate:a", 0.0, fade_dur)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		# --- MODE PERANG SELESAI ---
		# UI Perang: fade OUT dari 1.0 -> 0.0
		for node in targets:
			if is_instance_valid(node):
				node.visible = true
				_combat_hud_tween.tween_property(node, "modulate:a", 0.0, fade_dur)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# UI Quest: fade IN dari 0.0 -> 1.0 (mulai dan selesai barengan)
		var show_quest: bool = (not _is_dialogue_active) and (not is_open_world_mode)
		for node in quest_targets:
			if is_instance_valid(node):
				if show_quest:
					node.visible = true
					node.modulate.a = 0.0
					_combat_hud_tween.tween_property(node, "modulate:a", 1.0, fade_dur)\
						.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				else:
					node.visible = false
					node.modulate.a = 0.0

	_combat_hud_tween.chain().tween_callback(func():
		if is_combat_hud_visible:
			for node in quest_targets:
				if is_instance_valid(node) and is_combat_hud_visible:
					node.visible = false
					node.modulate.a = 0.0
			for node in targets:
				if is_instance_valid(node) and is_combat_hud_visible:
					node.visible = true
					node.modulate.a = 1.0
		else:
			for node in targets:
				if is_instance_valid(node) and not is_combat_hud_visible:
					node.visible = false
					node.modulate.a = 0.0
			if not _is_dialogue_active and not is_open_world_mode:
				for node in quest_targets:
					if is_instance_valid(node) and not is_combat_hud_visible:
						node.visible = true
						node.modulate.a = 1.0
			else:
				for node in quest_targets:
					if is_instance_valid(node):
						node.visible = false
						node.modulate.a = 0.0
	)


func update_party_order(new_party: Array[CharacterBody2D], new_leader_idx: int = 0) -> void:
	party_members = new_party
	active_leader_index = clampi(new_leader_idx, 0, max(0, party_members.size() - 1))
	if active_leader_index < party_members.size():
		active_leader_node = party_members[active_leader_index]
	current_viewed_party_slot = active_leader_index
	update_party_hud()
	update_leader_indicator()
	_update_pause_party_display()
	_update_character_info_ui()


func update_party_hud() -> void:
	# Update visibilitas kartu party: hanya kartu hero yang ada di party_members yang ditampilkan
	for h_type in hero_card_map.keys():
		var card = hero_card_map[h_type]
		if is_instance_valid(card):
			var member = get_member_by_hero_type(h_type)
			card.visible = is_instance_valid(member)

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
				var key_hint := card.get_node_or_null("KeyHint") as TextureRect
				if is_instance_valid(key_hint):
					key_hint.texture = _get_control_keycap_tex(KEY_1 + i)

	update_skill_slots_hud()
	_update_hp_bars()
	update_leader_indicator()
	_sync_gameplay_hud_controls_prompts()


func _update_hp_bars() -> void:
	for h_type in hero_card_map.keys():
		var card = hero_card_map[h_type]
		if not is_instance_valid(card):
			continue
		var hero := get_member_by_hero_type(h_type)
		if not is_instance_valid(hero):
			card.visible = false
			continue
		card.visible = true

		var max_hp = hero.get("max_health") if "max_health" in hero else 10
		var cur_hp: int = hero.get("current_health") if "current_health" in hero else max_hp
		var is_dead: bool = hero.get("is_dead") if "is_dead" in hero else (cur_hp <= 0)

		var cached: Dictionary = hero_card_cached_nodes.get(h_type, {})
		var hp_bar: TextureProgressBar = cached.get("hp_bar")
		if hp_bar:
			if hp_bar.max_value != max_hp:
				hp_bar.max_value = max_hp
			if hp_bar.value != cur_hp:
				hp_bar.value = cur_hp

		var portrait: TextureRect = cached.get("portrait")
		if portrait:
			var target_modulate: Color = Color(0.35, 0.35, 0.35, 0.55) if is_dead else Color.WHITE
			if portrait.modulate != target_modulate:
				portrait.modulate = target_modulate

		var name_label: Label = cached.get("name_label")
		if name_label:
			var def_name: String = HERO_NAMES.get(h_type, hero.name)
			var target_text: String = "KO" if is_dead else def_name
			if name_label.text != target_text:
				name_label.text = target_text
				var target_color: Color = Color(0.78, 0.16, 0.16, 1.0) if is_dead else Color(0.18, 0.10, 0.11, 1.0)
				name_label.add_theme_color_override("font_color", target_color)


func _update_skill_cooldowns() -> void:
	for i in range(skill_slot_nodes.size()):
		var slot := skill_slot_nodes[i] as Control
		if not is_instance_valid(slot):
			continue
		var cd_overlay: ColorRect = skill_slot_cd_overlays[i] if i < skill_slot_cd_overlays.size() else null
		var cd_label: Label = skill_slot_cd_labels[i] if i < skill_slot_cd_labels.size() else null
		if not cd_overlay:
			continue

		var hero: CharacterBody2D = party_members[i] if (i < party_members.size()) else null
		if is_instance_valid(hero):
			var is_dead: bool = hero.get("is_dead") if "is_dead" in hero else false
			var cd: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
			if is_dead:
				if not cd_overlay.visible:
					cd_overlay.visible = true
				if cd_label and cd_label.visible:
					cd_label.visible = false
			elif cd > 0.05:
				if not cd_overlay.visible:
					cd_overlay.visible = true
				if cd_label:
					if not cd_label.visible:
						cd_label.visible = true
					var cd_text: String = "%.1f" % cd
					if cd_label.text != cd_text:
						cd_label.text = cd_text
			else:
				if cd_overlay.visible:
					cd_overlay.visible = false
				if cd_label and cd_label.visible:
					cd_label.visible = false
		else:
			if cd_overlay.visible:
				cd_overlay.visible = false
			if cd_label and cd_label.visible:
				cd_label.visible = false


func update_leader_indicator() -> void:
	var active_type := get_hero_type_for_node(active_leader_node)
	if is_instance_valid(active_leader_node):
		if ("is_dead" in active_leader_node and active_leader_node.is_dead) or ("current_health" in active_leader_node and active_leader_node.current_health <= 0):
			active_type = -1
	for h_type in hero_card_map.keys():
		var card = hero_card_map[h_type]
		if not is_instance_valid(card):
			continue
		var is_active: bool = (h_type == active_type)
		var indicator = card.get_node_or_null("LeaderIndicator") as Control
		if indicator:
			indicator.visible = is_active
		var frame = card.get_node_or_null("Frame") as TextureRect
		if frame:
			frame.texture = CARD_FRAME_SELECTED_TEX if is_active else CARD_FRAME_NORMAL_TEX


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
	var target_cat := clampi(cat_idx, 0, 3)
	if target_cat != current_inventory_category:
		_play_ui_sfx(SFX_BOOK_PAGE_FLIP, -3.5, 0.04)
	_cancel_item_targeting()
	current_inventory_category = target_cat
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

	# Rebuild item grid or show empty state message
	if is_instance_valid(inv_item_grid):
		for child in inv_item_grid.get_children():
			child.queue_free()

		if _filtered_inventory_items.is_empty():
			if is_instance_valid(inv_scroll_container):
				inv_scroll_container.visible = false
			if is_instance_valid(inv_scrollbar):
				inv_scrollbar.visible = false
			if is_instance_valid(inv_empty_state_container):
				inv_empty_state_container.visible = true
		else:
			if is_instance_valid(inv_scroll_container):
				inv_scroll_container.visible = true
			if is_instance_valid(inv_scrollbar):
				inv_scrollbar.visible = true
			if is_instance_valid(inv_empty_state_container):
				inv_empty_state_container.visible = false

			var total_slots: int = maxi(9, _filtered_inventory_items.size())
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
	slot.mouse_filter = Control.MOUSE_FILTER_PASS as Control.MouseFilter

	var has_item: bool = (slot_idx < _filtered_inventory_items.size())
	var is_selected: bool = (has_item and slot_idx == selected_item_category_index)

	# Base slot background
	var bg := NinePatchRect.new()
	bg.name = "SlotBg"
	bg.texture = item_slot_tex
	bg.patch_margin_left = 6
	bg.patch_margin_top = 6
	bg.patch_margin_right = 6
	bg.patch_margin_bottom = 6
	bg.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
	bg.modulate = Color(1.3, 1.2, 1.05, 1.0) if is_selected else Color(1.0, 1.0, 1.0, 1.0)
	slot.add_child(bg)

	# Selected Golden Highlight Panel (2px Gold Border & Warm Amber Inner Glow)
	var sel_panel := Panel.new()
	sel_panel.name = "SelectedHighlight"
	var sel_sb := StyleBoxFlat.new()
	sel_sb.draw_center = true
	sel_sb.bg_color = Color(0.96, 0.76, 0.30, 0.16)
	sel_sb.border_width_left = 2
	sel_sb.border_width_top = 2
	sel_sb.border_width_right = 2
	sel_sb.border_width_bottom = 2
	sel_sb.border_color = Color(0.96, 0.76, 0.30, 1.0)
	sel_sb.corner_radius_top_left = 2
	sel_sb.corner_radius_top_right = 2
	sel_sb.corner_radius_bottom_left = 2
	sel_sb.corner_radius_bottom_right = 2
	sel_panel.add_theme_stylebox_override("panel", sel_sb)
	sel_panel.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	sel_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
	sel_panel.visible = is_selected
	slot.add_child(sel_panel)

	# Hover Highlight Panel (Subtle White Tint & Outline)
	var hov_panel := Panel.new()
	hov_panel.name = "HoverHighlight"
	var hov_sb := StyleBoxFlat.new()
	hov_sb.draw_center = true
	hov_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hov_sb.border_width_left = 1
	hov_sb.border_width_top = 1
	hov_sb.border_width_right = 1
	hov_sb.border_width_bottom = 1
	hov_sb.border_color = Color(1.0, 1.0, 1.0, 0.35)
	hov_sb.corner_radius_top_left = 2
	hov_sb.corner_radius_top_right = 2
	hov_sb.corner_radius_bottom_left = 2
	hov_sb.corner_radius_bottom_right = 2
	hov_panel.add_theme_stylebox_override("panel", hov_sb)
	hov_panel.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	hov_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
	hov_panel.visible = false
	slot.add_child(hov_panel)

	if has_item:
		var item: Dictionary = _filtered_inventory_items[slot_idx]

		# Item Icon
		var icon := TextureRect.new()
		icon.name = "ItemIcon"
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST as CanvasItem.TextureFilter
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED as TextureRect.StretchMode
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE as TextureRect.ExpandMode
		icon.custom_minimum_size = Vector2(32, 32)
		icon.set_anchors_preset(Control.PRESET_CENTER as Control.LayoutPreset)
		icon.pivot_offset = Vector2(16.0, 16.0)
		icon.offset_left = -16
		icon.offset_top = -16
		icon.offset_right = 16
		icon.offset_bottom = 16
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
		icon.texture = _resolve_inventory_item_texture(item)
		if is_selected:
			icon.scale = Vector2(1.10, 1.10)
		slot.add_child(icon)

		# Quantity badge (if > 1)
		var qty_val = item.get("quantity", 1)
		var qty_num: int = int(round(float(qty_val)))
		if qty_num > 1:
			var count_lbl := Label.new()
			count_lbl.text = _format_clean_number(qty_val)
			count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT as Control.LayoutPreset)
			count_lbl.offset_left = -30
			count_lbl.offset_top = -18
			count_lbl.offset_right = -4
			count_lbl.offset_bottom = -2
			count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT as HorizontalAlignment
			count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM as VerticalAlignment
			count_lbl.add_theme_font_override("font", preload("res://assets/ui/fonts/beholden-bold.ttf"))
			count_lbl.add_theme_font_size_override("font_size", 13)
			count_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.85, 1))
			count_lbl.add_theme_color_override("font_shadow_color", Color(0.15, 0.10, 0.10, 0.9))
			count_lbl.add_theme_constant_override("shadow_offset_x", 1)
			count_lbl.add_theme_constant_override("shadow_offset_y", 1)
			count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
			slot.add_child(count_lbl)

	# Selected bracket frame
	var sel_frame := NinePatchRect.new()
	sel_frame.name = "SelectedBorder"
	sel_frame.texture = item_selected_tex
	sel_frame.patch_margin_left = 6
	sel_frame.patch_margin_top = 6
	sel_frame.patch_margin_right = 6
	sel_frame.patch_margin_bottom = 6
	sel_frame.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	sel_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
	sel_frame.modulate = Color(1.25, 1.15, 0.85, 1.0)
	sel_frame.visible = is_selected
	slot.add_child(sel_frame)

	# Click area button
	var btn := TextureButton.new()
	btn.name = "SlotBtn"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_item else Control.CURSOR_ARROW
	if has_item:
		var click_idx: int = slot_idx
		btn.pressed.connect(func(): _on_inventory_slot_clicked(click_idx))
		btn.mouse_entered.connect(func():
			if click_idx != selected_item_category_index:
				hov_panel.visible = true
				_play_ui_sfx(SFX_UI_HOVER, -9.0)
		)
		btn.mouse_exited.connect(func():
			hov_panel.visible = false
		)
	slot.add_child(btn)

	return slot


func _on_inventory_slot_clicked(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < _filtered_inventory_items.size():
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5, 0.04)
		_cancel_item_targeting()
		selected_item_category_index = slot_idx
		_update_inventory_selection_visuals()
		_update_inventory_detail_panel()
		if is_instance_valid(inv_item_grid) and slot_idx < inv_item_grid.get_child_count():
			var clicked_slot = inv_item_grid.get_child(slot_idx) as Control
			if is_instance_valid(clicked_slot):
				clicked_slot.pivot_offset = clicked_slot.size / 2.0
				var tw := create_tween()
				tw.tween_property(clicked_slot, "scale", Vector2(0.95, 0.95), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(clicked_slot, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_inventory_selection_visuals() -> void:
	if not is_instance_valid(inv_item_grid):
		return
	var children = inv_item_grid.get_children()
	for i in range(children.size()):
		var slot_node = children[i] as Control
		if is_instance_valid(slot_node):
			var is_sel: bool = (i == selected_item_category_index)
			var sel_panel = slot_node.get_node_or_null("SelectedHighlight") as Control
			if sel_panel:
				sel_panel.visible = is_sel
			var sel_brackets = slot_node.get_node_or_null("SelectedBorder") as Control
			if sel_brackets:
				sel_brackets.visible = is_sel
			var hov = slot_node.get_node_or_null("HoverHighlight") as Control
			if hov and is_sel:
				hov.visible = false
			var bg = slot_node.get_node_or_null("SlotBg") as CanvasItem
			if bg:
				bg.modulate = Color(1.3, 1.2, 1.05, 1.0) if is_sel else Color(1.0, 1.0, 1.0, 1.0)
			var icon = slot_node.get_node_or_null("ItemIcon") as Control
			if icon:
				icon.scale = Vector2(1.10, 1.10) if is_sel else Vector2(1.0, 1.0)


func _update_inventory_detail_panel() -> void:
	if selected_item_category_index >= 0 and selected_item_category_index < _filtered_inventory_items.size():
		var item: Dictionary = _filtered_inventory_items[selected_item_category_index]
		var item_id: String = item.get("id", "")
		var is_note_item: bool = (current_inventory_category == 3 or item.get("category", 0) == 3 or item.has("content"))
		var is_reading_this_note: bool = (is_note_item and _reading_note_id == item_id and not item_id.is_empty())

		if inv_detail_icon:
			inv_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST as CanvasItem.TextureFilter
			inv_detail_icon.texture = _resolve_inventory_item_texture(item)
		if inv_detail_name:
			inv_detail_name.text = item.get("name", "Nama Barang")
		if inv_detail_count_label:
			inv_detail_count_label.text = _format_clean_number(item.get("quantity", 1))
		if inv_detail_count_container:
			inv_detail_count_container.visible = true

		if is_reading_this_note:
			# Mode Baca Catatan: Tampilkan NoteContentPanel di kanan
			if inv_detail_desc:
				inv_detail_desc.visible = false
			if is_instance_valid(note_content_panel):
				note_content_panel.visible = true
				if is_instance_valid(note_header_label):
					note_header_label.text = "--- %s ---" % item.get("name", "ISI DOKUMEN").to_upper()
				if is_instance_valid(note_body_label):
					var note_text: String = item.get("content", "")
					if note_text.is_empty():
						note_text = DEFAULT_NOTE_CONTENTS.get(item_id, item.get("description", ""))
					note_body_label.text = note_text
		else:
			# Mode Normal / Deskripsi Barang
			if is_instance_valid(note_content_panel):
				note_content_panel.visible = false
			if inv_detail_desc:
				inv_detail_desc.visible = true
				var base_desc: String = item.get("description", "")
				if is_note_item:
					inv_detail_desc.text = "%s\n\n[Tekan 'Gunakan' (E) untuk membaca isi dokumen]" % base_desc
				else:
					inv_detail_desc.text = base_desc

		if inv_btn_gunakan:
			var can_use: bool = item.get("usable", false) or is_note_item
			inv_btn_gunakan.disabled = not can_use
			inv_btn_gunakan.modulate = Color.WHITE if can_use else Color(0.6, 0.6, 0.6, 0.5)
			if is_instance_valid(inv_label_gunakan):
				if is_reading_this_note:
					inv_label_gunakan.text = "Tutup"
				else:
					inv_label_gunakan.text = "Gunakan"
	else:
		# Empty State
		_reading_note_id = ""
		if is_instance_valid(note_content_panel):
			note_content_panel.visible = false
		if inv_detail_icon:
			inv_detail_icon.texture = null
		if inv_detail_name:
			inv_detail_name.text = "Tidak Ada Barang"
		if inv_detail_count_container:
			inv_detail_count_container.visible = false
		if inv_detail_desc:
			inv_detail_desc.visible = true
			inv_detail_desc.text = "Tidak ada barang di bagian ini, silakan eksplorasi."
		if inv_btn_gunakan:
			inv_btn_gunakan.disabled = true
			inv_btn_gunakan.modulate = Color(0.6, 0.6, 0.6, 0.5)
			if is_instance_valid(inv_label_gunakan):
				inv_label_gunakan.text = "Gunakan"

	_update_inventory_target_slots()


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


## Hides the native vertical scrollbar and connects a matching custom parchment scrollbar.
func _setup_custom_v_scrollbar(scroll_container: ScrollContainer, scrollbar: Control, on_changed: Callable) -> void:
	if is_instance_valid(scroll_container):
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER as ScrollContainer.ScrollMode
		var v_bar = scroll_container.get_v_scroll_bar()
		if v_bar:
			v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
			v_bar.custom_minimum_size = Vector2.ZERO
			v_bar.scale = Vector2.ZERO
			v_bar.visible = false
			if not v_bar.value_changed.is_connected(on_changed):
				v_bar.value_changed.connect(func(_val: float): on_changed.call())
	if is_instance_valid(scrollbar):
		scrollbar.gui_input.connect(func(event: InputEvent):
			_handle_v_scrollbar_gui_input(scrollbar, scroll_container, event)
		)


func _handle_v_scrollbar_gui_input(scrollbar: Control, scroll_container: ScrollContainer, event: InputEvent) -> void:
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
			_active_v_scrollbar = scrollbar
			_v_scrollbar_drag_offset = drag_off
		else:
			if _active_v_scrollbar == scrollbar:
				_active_v_scrollbar = null
	elif event is InputEventMouseMotion:
		if _active_v_scrollbar == scrollbar:
			var ratio: float = clampf((event.position.y - _v_scrollbar_drag_offset - VSCROLL_INSET_TOP) / travel, 0.0, 1.0)
			_apply_v_scrollbar_pos(scrollbar, scroll_container, ratio, max_scroll)


func _update_inv_slider_grabber_pos() -> void:
	_update_v_scrollbar_from_scroll(inv_scrollbar, inv_scroll_container)


func _sync_inventory_scrollbar() -> void:
	_update_inv_slider_grabber_pos()


func _sync_controls_scrollbar() -> void:
	_update_v_scrollbar_from_scroll(controls_scrollbar, controls_scroll_container)


func _on_btn_gunakan_pressed() -> void:
	if inv_btn_gunakan and inv_btn_gunakan.disabled:
		return
	if selected_item_category_index < 0 or selected_item_category_index >= _filtered_inventory_items.size():
		return
	var item: Dictionary = _filtered_inventory_items[selected_item_category_index]
	var item_id: String = item.get("id", "")
	var is_note_item: bool = (current_inventory_category == 3 or item.get("category", 0) == 3 or item.has("content"))

	if not (item.get("usable", false) or is_note_item):
		return

	# Handle Notes reading toggle
	if is_note_item:
		if _reading_note_id == item_id and not item_id.is_empty():
			_reading_note_id = ""
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -2.5)
		else:
			_reading_note_id = item_id
			_play_ui_sfx(SFX_BOOK_PAGE_FLIP, -2.0)
		_update_inventory_detail_panel()
		return

	if item.has("heal_amount") or current_inventory_category == 0:
		if not _is_selecting_item_target:
			_start_item_targeting()
			return
		else:
			if selected_target_slot_index >= 0 and selected_target_slot_index < party_members.size():
				_use_item_on_party_member(selected_target_slot_index)
			return

	_play_ui_sfx(SFX_BOOK_CONFIRM, -2.5)
	item_used.emit(item)

	var qty: int = int(round(float(item.get("quantity", 1)))) - 1
	item["quantity"] = qty

	if qty <= 0:
		inventory_items.erase(item)
		_filtered_inventory_items = _get_filtered_inventory_items()
		if _filtered_inventory_items.is_empty():
			selected_item_category_index = -1
		else:
			selected_item_category_index = clampi(selected_item_category_index, 0, _filtered_inventory_items.size() - 1)

	_refresh_inventory_ui()


func _start_item_targeting() -> void:
	_is_selecting_item_target = true
	selected_target_slot_index = -1
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.0)
	_update_inventory_target_slots()


func _navigate_target_slot(delta: int) -> void:
	if party_members.is_empty():
		return
	if selected_target_slot_index < 0:
		if delta > 0:
			selected_target_slot_index = 0
		else:
			selected_target_slot_index = party_members.size() - 1
	else:
		selected_target_slot_index = clampi(selected_target_slot_index + delta, 0, party_members.size() - 1)
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.0)
	_update_target_slot_selection_visuals()


func _on_target_slot_clicked(slot_idx: int) -> void:
	if not _is_selecting_item_target:
		return
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	selected_target_slot_index = slot_idx
	_use_item_on_party_member(slot_idx)


func _update_target_slot_selection_visuals() -> void:
	for slot_idx in range(inv_target_slots.size()):
		var slot_node = inv_target_slots[slot_idx]
		if not is_instance_valid(slot_node):
			continue
		var frame := slot_node.get_node_or_null("Frame") as CanvasItem
		if frame:
			if selected_target_slot_index >= 0 and slot_idx == selected_target_slot_index:
				frame.modulate = Color(1.35, 1.25, 0.75, 1.0)
			else:
				frame.modulate = Color.WHITE


func _cancel_item_targeting() -> void:
	_is_selecting_item_target = false
	selected_target_slot_index = -1
	_reading_note_id = ""
	if is_instance_valid(inv_target_slots_container):
		inv_target_slots_container.visible = false
	for i in range(inv_target_slots.size()):
		var slot_node = inv_target_slots[i]
		if is_instance_valid(slot_node):
			var frame = slot_node.get_node_or_null("Frame") as CanvasItem
			if frame:
				frame.modulate = Color.WHITE


func _update_inventory_target_slots() -> void:
	if not is_instance_valid(inv_target_slots_container):
		return

	var is_consumable: bool = false
	if selected_item_category_index >= 0 and selected_item_category_index < _filtered_inventory_items.size():
		var item: Dictionary = _filtered_inventory_items[selected_item_category_index]
		if item.get("usable", false) and (item.has("heal_amount") or current_inventory_category == 0):
			is_consumable = true

	if not _is_selecting_item_target or not is_consumable:
		inv_target_slots_container.visible = false
		return

	inv_target_slots_container.visible = true

	for slot_idx in range(inv_target_slots.size()):
		var slot_node = inv_target_slots[slot_idx]
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
			var hp_label := slot_node.get_node_or_null("HpLabel") as Label

			var is_dead_char: bool = hero.get("is_dead") if "is_dead" in hero else false
			if "current_health" in hero and hero.current_health <= 0:
				is_dead_char = true

			if portrait and hero_portraits.has(hero_type):
				portrait.texture = hero_portraits[hero_type]
				portrait.modulate = Color(0.4, 0.4, 0.4, 0.7) if is_dead_char else Color.WHITE

			if leader_lbl:
				leader_lbl.visible = true
				leader_lbl.modulate.a = 1.0 if (slot_idx == 0 and not is_dead_char) else 0.0

			var max_hp: int = hero.get("max_health") if "max_health" in hero else 10
			var cur_hp: int = hero.get("current_health") if "current_health" in hero else max_hp

			if hp_bar:
				hp_bar.max_value = max_hp
				hp_bar.value = cur_hp

			if hp_label:
				hp_label.text = "%d/%d" % [cur_hp, max_hp]
				hp_label.modulate = Color(0.24, 0.15, 0.16, 1.0)

			if frame:
				if selected_target_slot_index >= 0 and slot_idx == selected_target_slot_index:
					frame.modulate = Color(1.35, 1.25, 0.75, 1.0)
				else:
					frame.modulate = Color.WHITE
		else:
			slot_node.visible = false


func _on_inv_target_slot_hover(slot_idx: int, is_hover: bool) -> void:
	if not _is_selecting_item_target:
		return
	if slot_idx < 0 or slot_idx >= party_members.size() or slot_idx >= inv_target_slots.size():
		return
	var slot_node = inv_target_slots[slot_idx]
	if not is_instance_valid(slot_node) or not slot_node.visible:
		return

	var hero = party_members[slot_idx]
	if not is_instance_valid(hero):
		return

	var hp_label = slot_node.get_node_or_null("HpLabel") as Label
	var frame = slot_node.get_node_or_null("Frame") as CanvasItem

	var max_hp: int = hero.get("max_health") if "max_health" in hero else 10
	var cur_hp: int = hero.get("current_health") if "current_health" in hero else max_hp

	if is_hover:
		if frame:
			if selected_target_slot_index >= 0 and slot_idx == selected_target_slot_index:
				frame.modulate = Color(1.45, 1.35, 0.85, 1.0)
			else:
				frame.modulate = Color(1.2, 1.2, 1.15, 1.0)
		if hp_label:
			hp_label.text = "%d/%d" % [cur_hp, max_hp]
			if cur_hp < max_hp:
				hp_label.modulate = Color(0.12, 0.65, 0.2, 1.0)
			else:
				hp_label.modulate = Color(0.24, 0.15, 0.16, 1.0)
	else:
		if frame:
			if selected_target_slot_index >= 0 and slot_idx == selected_target_slot_index:
				frame.modulate = Color(1.35, 1.25, 0.75, 1.0)
			else:
				frame.modulate = Color.WHITE
		if hp_label:
			hp_label.text = "%d/%d" % [cur_hp, max_hp]
			hp_label.modulate = Color(0.24, 0.15, 0.16, 1.0)


func _use_item_on_party_member(slot_idx: int) -> void:
	if selected_item_category_index < 0 or selected_item_category_index >= _filtered_inventory_items.size():
		return
	var item: Dictionary = _filtered_inventory_items[selected_item_category_index]
	if not item.get("usable", false):
		return
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	var hero = party_members[slot_idx]
	if not is_instance_valid(hero):
		return

	var is_revive_item: bool = item.get("is_revive", false) or item.get("id") == "bread"
	var is_dead_char: bool = hero.get("is_dead") if "is_dead" in hero else false
	if "current_health" in hero and hero.current_health <= 0:
		is_dead_char = true

	# Karakter KO hanya dapat dipulihkan dengan item revive (seperti roti gandum)
	if is_dead_char and not is_revive_item:
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -2.5)
		return

	var heal_val: int = int(item.get("heal_amount", 150))
	var old_hp: int = hero.get("current_health") if "current_health" in hero else 10
	var max_hp: int = hero.get("max_health") if "max_health" in hero else 10

	var new_hp: int = 0
	if is_dead_char and is_revive_item:
		if hero.has_method("respawn"):
			hero.respawn()
			hero.current_health = mini(max_hp, heal_val)
		else:
			hero.is_dead = false
			hero.current_health = mini(max_hp, heal_val)
		new_hp = hero.current_health
	else:
		new_hp = mini(max_hp, old_hp + heal_val)
		hero.current_health = new_hp

	_play_ui_sfx(SFX_BOOK_CONFIRM, -2.5)

	# Emit signal dengan target_index agar game.gd dan sistem lain sinkron
	var payload := item.duplicate()
	payload["target_index"] = slot_idx
	item_used.emit(payload)

	var qty: int = int(round(float(item.get("quantity", 1)))) - 1
	item["quantity"] = qty
	if qty <= 0:
		inventory_items.erase(item)
		_filtered_inventory_items = _get_filtered_inventory_items()
		if _filtered_inventory_items.is_empty():
			selected_item_category_index = -1
		else:
			selected_item_category_index = clampi(selected_item_category_index, 0, _filtered_inventory_items.size() - 1)
		_cancel_item_targeting()

	# Animasi feedback visual perubahan HP pada slot terpilih
	if slot_idx < inv_target_slots.size():
		var slot_node = inv_target_slots[slot_idx]
		if is_instance_valid(slot_node):
			var hp_bar = slot_node.get_node_or_null("HpBar") as TextureProgressBar
			var hp_label = slot_node.get_node_or_null("HpLabel") as Label
			var frame = slot_node.get_node_or_null("Frame") as CanvasItem
			var float_lbl = slot_node.get_node_or_null("Frame/FloatFeedback") as Label

			if float_lbl:
				float_lbl.text = "REVIVE!" if is_dead_char else "+%d" % heal_val
				float_lbl.modulate = Color(1.0, 0.85, 0.2, 1.0) if is_dead_char else Color(0.2, 0.9, 0.3, 1.0)
				float_lbl.visible = true
				var ftw := create_tween()
				ftw.tween_property(float_lbl, "position:y", float_lbl.position.y - 14.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				ftw.parallel().tween_property(float_lbl, "modulate:a", 0.0, 0.5).set_delay(0.2)
				ftw.tween_callback(func():
					float_lbl.visible = false
					float_lbl.position.y += 14.0
					float_lbl.modulate.a = 1.0
				)

			if hp_bar:
				var tw := create_tween()
				tw.tween_property(hp_bar, "value", float(new_hp), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			if hp_label:
				hp_label.text = "%d/%d" % [new_hp, max_hp]
				hp_label.modulate = Color(0.12, 0.65, 0.2, 1.0)
				var tw_lbl := create_tween()
				tw_lbl.tween_property(hp_label, "modulate", Color(0.24, 0.15, 0.16, 1.0), 0.8)

			if frame:
				var tw_fr := create_tween()
				tw_fr.tween_property(frame, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw_fr.tween_property(frame, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				frame.modulate = Color(1.5, 1.5, 1.2, 1.0)
				tw_fr.tween_property(frame, "modulate", Color(1.35, 1.25, 0.75, 1.0) if slot_idx == selected_target_slot_index else Color.WHITE, 0.35)

	_update_hp_bars()
	_update_pause_party_hp_bars()
	_refresh_inventory_ui()


# =========================================================
# JOURNAL / QUEST SYSTEM LOGIC
# =========================================================

func _get_open_world_journal_data() -> Dictionary:
	return {
		"id": "mode_jelajah",
		"category": "main",
		"title": "Mode Jelajah",
		"location": "Dunia Terbuka",
		"objective": "Eksplorasi Bebas",
		"description": "Kamu sedang berada dalam Mode Jelajah. Kamu tidak memiliki tanggungan quest di mode ini.\n\nJelajahi seluruh penjuru dunia dengan bebas tanpa batasan misi cerita!",
		"status": "active"
	}


func set_quests(quests: Array[Dictionary], initial_tracked_id: String = "") -> void:
	quest_list = quests
	if is_open_world_mode:
		tracked_quest_id = ""
		selected_quest_id = "mode_jelajah"
	else:
		if initial_tracked_id != "":
			tracked_quest_id = initial_tracked_id
		elif tracked_quest_id == "" and quest_list.size() > 0:
			for q in quest_list:
				if str(q.get("status", "")).to_lower() == "active":
					tracked_quest_id = q.get("id", "")
					break
			if tracked_quest_id == "":
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

	var w_header = world_quest_container.get_parent().get_node_or_null("WorldQuestHeader")
	var quest_spacer = main_quest_container.get_parent().get_node_or_null("Spacer")
	var m_title = main_quest_container.get_parent().get_node_or_null("MainQuestHeader/Title") as Label

	if is_open_world_mode:
		if is_instance_valid(w_header):
			w_header.visible = false
		if is_instance_valid(quest_spacer):
			quest_spacer.visible = false
		if is_instance_valid(m_title):
			m_title.text = "Mode Permainan"

		var open_world_data := _get_open_world_journal_data()
		selected_quest_id = "mode_jelajah"
		var item_node := _create_quest_item_node(open_world_data, true)
		main_quest_container.add_child(item_node)
		_update_journal_detail_panel(open_world_data)
		call_deferred("_sync_journal_scrollbar")
		return

	if is_instance_valid(w_header):
		w_header.visible = true
	if is_instance_valid(quest_spacer):
		quest_spacer.visible = true
	if is_instance_valid(m_title):
		m_title.text = "Misi Utama"

	# Inisialisasi seleksi awal: cari misi aktif pertama atau selesai yang valid
	var first_active_main: String = ""
	var first_active_world: String = ""
	var first_any_valid: String = ""
	var found_selected: bool = false

	for q in quest_list:
		var q_id: String = q.get("id", "")
		var cat: String = str(q.get("category", "main")).to_lower()
		var status: String = str(q.get("status", "active")).to_lower()
		# Quest yang akan datang / inactive belum muncul
		if status != "active" and status != "completed":
			continue

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

	# Populate Main Quests (hanya yang aktif atau selesai)
	for q in quest_list:
		var status: String = str(q.get("status", "active")).to_lower()
		if status != "active" and status != "completed":
			continue # Sembunyikan misi yang belum dibuka

		var cat: String = str(q.get("category", "main")).to_lower()
		if cat == "main" or cat == "story":
			var is_sel: bool = (q.get("id", "") == selected_quest_id)
			if is_sel:
				selected_quest_data = q
			var item_node := _create_quest_item_node(q, is_sel)
			main_quest_container.add_child(item_node)

	# Populate World Quests (hanya yang aktif atau selesai)
	for q in quest_list:
		var status: String = str(q.get("status", "active")).to_lower()
		if status != "active" and status != "completed":
			continue # Sembunyikan misi yang belum dibuka

		var cat: String = str(q.get("category", "main")).to_lower()
		if cat == "world" or cat == "side":
			var is_sel: bool = (q.get("id", "") == selected_quest_id)
			if is_sel:
				selected_quest_data = q
			var item_node := _create_quest_item_node(q, is_sel)
			world_quest_container.add_child(item_node)

	var has_world_quests: bool = world_quest_container.get_child_count() > 0
	if is_instance_valid(w_header):
		w_header.visible = has_world_quests
	if is_instance_valid(quest_spacer):
		quest_spacer.visible = has_world_quests

	# Update Detail Panel
	_update_journal_detail_panel(selected_quest_data)

	# Update Scrollbar
	call_deferred("_sync_journal_scrollbar")


func _create_quest_item_node(quest: Dictionary, is_selected: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_PASS as Control.MouseFilter

	var serif_font: Font = preload("res://assets/ui/fonts/beholden-bold.ttf")
	var status: String = str(quest.get("status", "active")).to_lower()
	var is_completed: bool = (status == "completed")

	# Arrow indicator (visible if is_selected)
	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.custom_minimum_size = Vector2(14, 0)
	if serif_font:
		arrow.add_theme_font_override("font", serif_font)
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.44, 0.31, 0.27, 1.0))
	arrow.text = "▶"
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER as VerticalAlignment
	arrow.modulate.a = 1.0 if is_selected else 0.0
	row.add_child(arrow)

	# Button panel box
	var box := NinePatchRect.new()
	box.name = "Box"
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST as CanvasItem.TextureFilter
	box.custom_minimum_size = Vector2(180, 32)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL as Control.SizeFlags
	box.texture = quest_btn_panel_tex
	box.patch_margin_left = 5
	box.patch_margin_top = 4
	box.patch_margin_right = 5
	box.patch_margin_bottom = 4
	box.mouse_filter = Control.MOUSE_FILTER_PASS as Control.MouseFilter

	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	title_lbl.offset_left = 10.0
	title_lbl.offset_right = -10.0
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER as VerticalAlignment
	title_lbl.clip_text = true
	title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS as TextServer.OverrunBehavior
	title_lbl.text = quest.get("title", "Judul Misi")
	if is_completed:
		title_lbl.add_theme_color_override("font_color", Color(0.48, 0.38, 0.36, 0.85))
	else:
		title_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
	if serif_font:
		title_lbl.add_theme_font_override("font", serif_font)
	title_lbl.add_theme_font_size_override("font_size", 16)
	box.add_child(title_lbl)

	# Coretan garis horizontal jika misi sudah selesai (dicoret)
	if is_completed:
		var strike := ColorRect.new()
		strike.name = "StrikeLine"
		strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strike.color = Color(0.40, 0.22, 0.20, 0.90) # Tinta coretan pena buku
		strike.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		strike.offset_left = 8.0
		var title_text: String = quest.get("title", "Judul Misi")
		var text_w: float = 160.0
		if serif_font:
			text_w = serif_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		strike.offset_right = 8.0 + minf(text_w + 4.0, 168.0)
		strike.offset_top = -1.0
		strike.offset_bottom = 1.0
		box.add_child(strike)

	# Click Area Button
	var btn := TextureButton.new()
	btn.name = "ClickArea"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP as Control.MouseFilter
	var q_id: String = quest.get("id", "")
	btn.pressed.connect(func():
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5, 0.04)
		_select_quest(q_id)
	)
	box.add_child(btn)

	row.set_meta("quest_id", q_id)
	row.add_child(box)
	return row


func _select_quest(q_id: String) -> void:
	selected_quest_id = q_id
	var found_quest: Dictionary = {}
	if is_open_world_mode or q_id == "mode_jelajah":
		found_quest = _get_open_world_journal_data()
	else:
		for q in quest_list:
			if q.get("id", "") == q_id:
				found_quest = q
				break

	# Update visual selection markers in both list containers
	_update_quest_list_selection_visuals(main_quest_container)
	_update_quest_list_selection_visuals(world_quest_container)

	_update_journal_detail_panel(found_quest)
	quest_selected.emit(found_quest)


func _navigate_quest_relative(direction: int) -> void:
	if is_start_menu_mode:
		return
	if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
		return
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return
	if _rebind_action_id != "":
		return
	if current_tab_index != 1:
		return

	var quest_nodes: Array[Control] = []
	if is_instance_valid(main_quest_container):
		for child in main_quest_container.get_children():
			if child is Control and not child.is_queued_for_deletion() and child.has_meta("quest_id"):
				quest_nodes.append(child as Control)
	if is_instance_valid(world_quest_container):
		for child in world_quest_container.get_children():
			if child is Control and not child.is_queued_for_deletion() and child.has_meta("quest_id"):
				quest_nodes.append(child as Control)

	if quest_nodes.is_empty():
		return

	var current_idx: int = -1
	for i in range(quest_nodes.size()):
		if str(quest_nodes[i].get_meta("quest_id", "")) == selected_quest_id:
			current_idx = i
			break

	var next_idx: int = 0
	if current_idx == -1:
		next_idx = 0 if direction > 0 else (quest_nodes.size() - 1)
	else:
		next_idx = (current_idx + direction) % quest_nodes.size()
		if next_idx < 0:
			next_idx += quest_nodes.size()

	var target_node := quest_nodes[next_idx]
	var target_qid: String = str(target_node.get_meta("quest_id", ""))
	if target_qid != "":
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5, 0.03)
		_select_quest(target_qid)
		if is_instance_valid(journal_scroll_container):
			journal_scroll_container.ensure_control_visible(target_node)
			call_deferred("_sync_journal_scrollbar")


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

	if is_open_world_mode or quest.get("id") == "mode_jelajah":
		if journal_detail_title:
			journal_detail_title.text = "Mode Jelajah"
		if journal_detail_location:
			journal_detail_location.text = "Dunia Terbuka"
		if journal_detail_objective:
			journal_detail_objective.text = "Eksplorasi Bebas"
		if journal_detail_desc:
			journal_detail_desc.text = "Kamu sedang berada dalam Mode Jelajah. Kamu tidak memiliki tanggungan quest di mode ini.\n\nJelajahi seluruh penjuru dunia dengan bebas tanpa batasan misi cerita!"
		_update_journal_rewards({})
		if journal_btn_navigasi:
			journal_btn_navigasi.disabled = true
			journal_btn_navigasi.visible = false
		return

	if quest.is_empty():
		if journal_detail_title:
			journal_detail_title.text = "Tidak Ada Misi"
		if journal_detail_location:
			journal_detail_location.text = "-"
		if journal_detail_objective:
			journal_detail_objective.text = "Tidak ada petunjuk misi aktif."
		if journal_detail_desc:
			journal_detail_desc.text = "Pilih misi dari daftar di sebelah kiri untuk melihat detail petunjuk."
		_update_journal_rewards({})
		if journal_btn_navigasi:
			journal_btn_navigasi.visible = true
			journal_btn_navigasi.disabled = true
			journal_btn_navigasi.modulate = Color(0.6, 0.6, 0.6, 0.5)
		return

	var q_status: String = str(quest.get("status", "active")).to_lower()
	var is_completed: bool = (q_status == "completed")

	if journal_detail_title:
		journal_detail_title.text = quest.get("title", "Judul Misi")
		if is_completed:
			journal_detail_title.add_theme_color_override("font_color", Color(0.48, 0.38, 0.36, 0.85))
		else:
			journal_detail_title.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))

		# Coret judul detail jika misi selesai
		var title_strike = journal_detail_title.get_node_or_null("StrikeLine")
		if is_completed:
			if not title_strike:
				title_strike = ColorRect.new()
				title_strike.name = "StrikeLine"
				title_strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
				title_strike.color = Color(0.40, 0.22, 0.20, 0.90)
				journal_detail_title.add_child(title_strike)
			title_strike.visible = true
			title_strike.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			title_strike.offset_left = 0.0
			var title_font = journal_detail_title.get_theme_font("font")
			var title_size: int = journal_detail_title.get_theme_font_size("font_size")
			if title_size <= 0:
				title_size = 22
			var t_w: float = 240.0
			if title_font:
				t_w = title_font.get_string_size(journal_detail_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
			title_strike.offset_right = minf(t_w + 6.0, 255.0)
			title_strike.offset_top = -1.0
			title_strike.offset_bottom = 1.0
		elif title_strike:
			title_strike.visible = false

	if journal_detail_location:
		journal_detail_location.text = quest.get("location", "Lokasi")

	if journal_detail_objective:
		if is_completed:
			journal_detail_objective.text = "%s [Selesai]" % quest.get("objective", "Petunjuk Misi")
			journal_detail_objective.add_theme_color_override("font_color", Color(0.48, 0.38, 0.36, 0.85))
		else:
			journal_detail_objective.text = quest.get("objective", "Petunjuk Misi")
			journal_detail_objective.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))

	if journal_detail_desc:
		journal_detail_desc.text = quest.get("description", "Deskripsi petunjuk.")

	_update_journal_rewards(quest.get("rewards", {}))

	var has_valid_loc: bool = quest.get("location", "") != ""
	var is_active: bool = (q_status == "active")
	var can_nav: bool = has_valid_loc and is_active

	if journal_btn_navigasi:
		if is_completed:
			journal_btn_navigasi.visible = false
			journal_btn_navigasi.disabled = true
		else:
			journal_btn_navigasi.visible = true
			journal_btn_navigasi.disabled = not can_nav
			journal_btn_navigasi.modulate = Color.WHITE if can_nav else Color(0.6, 0.6, 0.6, 0.5)


func _update_journal_rewards(rewards_data: Variant) -> void:
	if not is_instance_valid(journal_detail_scroll):
		return
	var vbox = journal_detail_scroll.get_node_or_null("DetailsVBox")
	if not is_instance_valid(vbox):
		return

	var reward_section = vbox.get_node_or_null("RewardSection") as VBoxContainer
	if not is_instance_valid(reward_section):
		reward_section = _create_journal_reward_section(vbox)

	# Evaluasi apakah quest memiliki hadiah nyata
	var has_rewards: bool = false
	var exp_val: int = 0
	var gold_val: int = 0
	var item_list: Array = []

	if rewards_data is Dictionary and not rewards_data.is_empty():
		exp_val = int(rewards_data.get("exp", 0))
		gold_val = int(rewards_data.get("gold", rewards_data.get("coins", 0)))
		var raw_items = rewards_data.get("items", [])
		if raw_items is Array:
			item_list = raw_items
		if exp_val > 0 or gold_val > 0 or not item_list.is_empty():
			has_rewards = true
	elif rewards_data is Array and not rewards_data.is_empty():
		has_rewards = true
		for entry in rewards_data:
			if entry is Dictionary:
				var t: String = str(entry.get("type", "")).to_lower()
				if t == "exp":
					exp_val += int(entry.get("amount", 0))
				elif t == "gold" or t == "coins":
					gold_val += int(entry.get("amount", 0))
				elif t == "item":
					item_list.append(entry)
			elif entry is String and entry.strip_edges() != "":
				item_list.append({"name": entry})

	# Jika tidak ada hadiah, sembunyikan section sepenuhnya (tapi kalo emang ga ada rewardnya gausah)
	if not has_rewards:
		reward_section.visible = false
		return

	reward_section.visible = true
	var list_container = reward_section.get_node_or_null("RewardList") as VBoxContainer
	if not is_instance_valid(list_container):
		return

	# Bersihkan kartu hadiah sebelumnya
	for child in list_container.get_children():
		child.queue_free()

	var serif_font: Font = preload("res://assets/ui/fonts/beholden-bold.ttf")
	var ink_color := Color(0.24, 0.15, 0.16, 1.0)

	# 1. EXP Reward Card
	if exp_val > 0:
		var exp_card := _create_reward_badge_card("exp", "+%d EXP" % exp_val, serif_font, ink_color)
		list_container.add_child(exp_card)

	# 2. Gold / Koin Reward Card
	if gold_val > 0:
		var gold_card := _create_reward_badge_card("gold", "+%d Koin Emas" % gold_val, serif_font, ink_color)
		list_container.add_child(gold_card)

	# 3. Item Rewards Cards
	for itm in item_list:
		var item_card := _create_reward_item_card(itm, serif_font, ink_color)
		if is_instance_valid(item_card):
			list_container.add_child(item_card)


func _create_journal_reward_section(vbox: Control) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = "RewardSection"
	section.add_theme_constant_override("separation", 6)
	vbox.add_child(section)

	# Spacer pemisah dari teks deskripsi di atasnya
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	section.add_child(spacer)

	# Header baris judul hadiah dengan dots divider
	var header := HBoxContainer.new()
	header.name = "HeaderRow"
	header.add_theme_constant_override("separation", 8)
	section.add_child(header)

	var serif_font: Font = preload("res://assets/ui/fonts/beholden-bold.ttf")
	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.text = "Hadiah Misi"
	if serif_font:
		title_lbl.add_theme_font_override("font", serif_font)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
	header.add_child(title_lbl)

	var dots := TextureRect.new()
	dots.name = "Dots"
	dots.custom_minimum_size = Vector2(40, 4)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dots_tex := AtlasTexture.new()
	dots_tex.atlas = preload("res://assets/ui/menus/common/ui_menu_sheet.png")
	dots_tex.region = Rect2(65, 263, 30, 3)
	dots.texture = dots_tex
	dots.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dots.stretch_mode = TextureRect.STRETCH_TILE
	header.add_child(dots)

	# Container list kartu hadiah
	var list := VBoxContainer.new()
	list.name = "RewardList"
	list.add_theme_constant_override("separation", 5)
	section.add_child(list)

	# Bottom padding spacer agar tidak mepet di scroll bawah
	var b_spacer := Control.new()
	b_spacer.custom_minimum_size = Vector2(0, 14)
	section.add_child(b_spacer)

	return section


func _create_reward_badge_card(badge_type: String, text: String, font: Font, text_color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 26)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.76, 0.56, 0.75) # Warm parchment fill
	style.border_color = Color(0.71, 0.55, 0.37, 0.85) # Sepia border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	if badge_type == "gold":
		var ico := TextureRect.new()
		ico.custom_minimum_size = Vector2(16, 16)
		ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var coin_tex := AtlasTexture.new()
		coin_tex.atlas = INVENTORY_ITEMS_SHEET_TEX
		coin_tex.region = Rect2(16, 128, 16, 16) # Ancient coin
		ico.texture = coin_tex
		hbox.add_child(ico)
	elif badge_type == "exp":
		var star := Label.new()
		star.text = "★"
		if font:
			star.add_theme_font_override("font", font)
		star.add_theme_font_size_override("font_size", 14)
		star.add_theme_color_override("font_color", Color(0.85, 0.58, 0.12, 1.0))
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(star)

	var lbl := Label.new()
	lbl.text = text
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	return panel


func _create_reward_item_card(item_info: Variant, font: Font, text_color: Color) -> Control:
	var item_dict: Dictionary = {}
	if item_info is Dictionary:
		item_dict = item_info
	elif item_info is String:
		item_dict = {"name": item_info}
	else:
		return null

	var item_name: String = item_dict.get("name", "Item Hadiah")
	var qty: int = int(item_dict.get("quantity", item_dict.get("amount", 1)))
	var display_text: String = "%s (x%d)" % [item_name, qty] if qty > 1 else item_name

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 26)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.76, 0.56, 0.75)
	style.border_color = Color(0.71, 0.55, 0.37, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var ico := TextureRect.new()
	ico.custom_minimum_size = Vector2(16, 16)
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var item_tex: Texture2D = _resolve_inventory_item_texture(item_dict)
	if not item_tex and item_dict.has("icon_rect") and item_dict["icon_rect"] is Rect2:
		var atlas := AtlasTexture.new()
		atlas.atlas = INVENTORY_ITEMS_SHEET_TEX
		atlas.region = item_dict["icon_rect"]
		item_tex = atlas
	if not item_tex:
		var atlas := AtlasTexture.new()
		atlas.atlas = INVENTORY_ITEMS_SHEET_TEX
		atlas.region = Rect2(48, 560, 16, 16) # Fallback ke icon apel
		item_tex = atlas

	ico.texture = item_tex
	hbox.add_child(ico)

	var lbl := Label.new()
	lbl.text = display_text
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	return panel


func _on_btn_navigasi_pressed() -> void:
	if is_open_world_mode or (journal_btn_navigasi and (journal_btn_navigasi.disabled or not journal_btn_navigasi.visible)):
		return
	var selected_quest: Dictionary = {}
	for q in quest_list:
		if q.get("id", "") == selected_quest_id:
			selected_quest = q
			break
	if selected_quest.is_empty():
		return

	_play_ui_sfx(SFX_BOOK_CONFIRM, -2.5)
	tracked_quest_id = selected_quest.get("id", "")
	update_hud_quest_display(selected_quest)
	quest_tracked.emit(selected_quest)
	quest_navigation_requested.emit(selected_quest)


func update_hud_quest_display(quest: Dictionary) -> void:
	if is_open_world_mode:
		if is_instance_valid(quest_header):
			quest_header.visible = false
		if is_instance_valid(quest_container):
			quest_container.visible = false
		return
	if is_instance_valid(quest_title):
		quest_title.text = quest.get("title", "Judul utama misi")
	if is_instance_valid(quest_objective):
		quest_objective.text = quest.get("objective", "objektif misi")


# --- Journal Custom Vertical Scrollbar ---

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
		_connect_book_hover_sfx(click_area)
		click_area.pressed.connect(func():
			if active_settings_submenu != sub_idx:
				_play_ui_sfx(SFX_BOOK_PAGE_FLIP, -3.5, 0.03)
			_switch_settings_submenu(sub_idx)
		)
		click_area.mouse_entered.connect(func():
			_on_submenu_btn_hover(sub_idx, true)
		)
		click_area.mouse_exited.connect(func():
			_on_submenu_btn_hover(sub_idx, false)
		)


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
	var _err := config.load(SETTINGS_FILE_PATH)
	config.set_value("audio", "master_volume", audio_settings.get("master", 100))
	config.set_value("audio", "music_volume", audio_settings.get("music", 100))
	config.set_value("audio", "sfx_volume", audio_settings.get("sfx", 100))
	config.set_value("audio", "dialog_volume", audio_settings.get("dialog", 100))
	config.save(SETTINGS_FILE_PATH)


func load_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE_PATH)
	if err == OK:
		audio_settings["master"] = int(config.get_value("audio", "master_volume", 100))
		audio_settings["music"] = int(config.get_value("audio", "music_volume", 100))
		audio_settings["sfx"] = int(config.get_value("audio", "sfx_volume", 100))
		audio_settings["dialog"] = int(config.get_value("audio", "dialog_volume", 100))
		# Migrasi otomatis: jika sfx atau dialog masih bernilai 50 (bawaan lama), perbarui ke 100
		var needs_resave := false
		if config.get_value("audio", "sfx_volume", 100) == 50:
			audio_settings["sfx"] = 100
			needs_resave = true
		if config.get_value("audio", "dialog_volume", 100) == 50:
			audio_settings["dialog"] = 100
			needs_resave = true
		if needs_resave:
			save_audio_settings()
	else:
		audio_settings["master"] = 100
		audio_settings["music"] = 100
		audio_settings["sfx"] = 100
		audio_settings["dialog"] = 100
		save_audio_settings()

	_apply_all_audio_settings()


func _apply_all_audio_settings() -> void:
	_apply_bus_volume("Master", audio_settings.get("master", 100))
	_apply_bus_volume("Music", audio_settings.get("music", 100))
	_apply_bus_volume("SFX", audio_settings.get("sfx", 100))
	_apply_bus_volume("Dialog", audio_settings.get("dialog", 100))


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
			_sync_controls_scrollbar()
			call_deferred("_sync_controls_scrollbar")
	if is_instance_valid(submenu_save_load):
		submenu_save_load.visible = (sub_idx == 2)
		if sub_idx == 2:
			_refresh_save_load_ui()

	if pause_header_title and is_start_menu_mode:
		if sub_idx == 2:
			pause_header_title.text = "MEMUAT PERMAINAN"
		else:
			pause_header_title.text = "PENGATURAN"

	_update_submenu_buttons_visual()


func _navigate_submenu_relative(direction: int) -> void:
	if not is_instance_valid(pause_overlay) or not pause_overlay.visible:
		return
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return
	if _rebind_action_id != "":
		return
	if current_tab_index != 3:
		return

	hovered_settings_submenu = -1
	var total_submenus: int = 4
	if is_start_menu_mode:
		if active_settings_submenu == 2:
			return
		total_submenus = 2

	# Jangan wrap ke atas jika sudah di paling atas (Musik & Suara), agar tidak sengaja memicu popup Kembali
	if active_settings_submenu == 0 and direction < 0:
		return

	var next_sub: int = (active_settings_submenu + direction) % total_submenus
	if next_sub < 0:
		next_sub += total_submenus

	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5, 0.03)
	if next_sub == 3:
		active_settings_submenu = 3
		_update_submenu_buttons_visual()
		_on_btn_return_to_title_pressed()
	else:
		_switch_settings_submenu(next_sub)


func _update_submenu_buttons_visual() -> void:
	if is_start_menu_mode:
		# Saat diakses dari start menu:
		# Jika sedang membuka Pengaturan (submenu 0 Musik & Suara atau 1 Kontrol),
		# sembunyikan tombol Simpan & Muat serta tombol Kembali agar murni hanya berisi Pengaturan.
		var is_load_mode := (active_settings_submenu == 2)
		if is_instance_valid(settings_btn_audio):
			settings_btn_audio.visible = not is_load_mode
		if is_instance_valid(settings_btn_controls):
			settings_btn_controls.visible = not is_load_mode
		if is_instance_valid(settings_btn_save_load):
			settings_btn_save_load.visible = is_load_mode
			if is_load_mode:
				var save_lbl = settings_btn_save_load.get_node_or_null("Title") as Label
				if save_lbl:
					save_lbl.text = "Muat Permainan"
		if is_instance_valid(settings_btn_title):
			settings_btn_title.visible = false
	else:
		if is_instance_valid(settings_btn_audio):
			settings_btn_audio.visible = true
		if is_instance_valid(settings_btn_controls):
			settings_btn_controls.visible = true
		if is_instance_valid(settings_btn_save_load):
			settings_btn_save_load.visible = true
			var save_lbl = settings_btn_save_load.get_node_or_null("Title") as Label
			if save_lbl:
				save_lbl.text = "Simpan & Muat"
		if is_instance_valid(settings_btn_title):
			settings_btn_title.visible = true
			var back_lbl = settings_btn_title.get_node_or_null("Title") as Label
			if back_lbl:
				back_lbl.text = "Kembali ke Judul"

	var btns: Array[NinePatchRect] = [settings_btn_audio, settings_btn_controls, settings_btn_save_load, settings_btn_title]
	for i in range(btns.size()):
		var b = btns[i]
		if not is_instance_valid(b) or not b.visible:
			if is_instance_valid(b):
				var arrow = b.get_node_or_null("ArrowIndicator") as TextureRect
				if arrow:
					arrow.visible = false
			continue
		var is_sel: bool = (i == active_settings_submenu)
		var is_hov: bool = (i == hovered_settings_submenu)
		if is_sel:
			b.texture = submenu_btn_selected_tex
		elif is_hov:
			b.texture = submenu_btn_hover_tex
		else:
			b.texture = submenu_btn_normal_tex

		var title_lbl = b.get_node_or_null("Title") as Label
		if title_lbl:
			if is_sel:
				title_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
			elif is_hov:
				title_lbl.add_theme_color_override("font_color", Color(0.22, 0.14, 0.15, 1.0))
			else:
				title_lbl.add_theme_color_override("font_color", Color(0.40, 0.30, 0.30, 1.0))

		var show_arrow: bool = is_hov or (hovered_settings_submenu == -1 and is_sel)
		_update_submenu_arrow_indicator(b, i, show_arrow)


func _on_submenu_btn_hover(sub_idx: int, is_hover: bool) -> void:
	if is_hover:
		hovered_settings_submenu = sub_idx
	else:
		if hovered_settings_submenu == sub_idx:
			hovered_settings_submenu = -1
	_update_submenu_buttons_visual()


func _reset_submenu_hover_state() -> void:
	hovered_settings_submenu = -1
	for idx in _submenu_arrow_tweens.keys():
		if is_instance_valid(_submenu_arrow_tweens[idx]):
			_submenu_arrow_tweens[idx].kill()
	_submenu_arrow_tweens.clear()
	var btns: Array[NinePatchRect] = [settings_btn_audio, settings_btn_controls, settings_btn_save_load, settings_btn_title]
	for i in range(btns.size()):
		var b = btns[i]
		if is_instance_valid(b):
			var arrow = b.get_node_or_null("ArrowIndicator") as TextureRect
			if arrow:
				arrow.visible = false
				arrow.modulate.a = 0.0
				arrow.position.x = -19.0


func _get_arrow_indicator_texture() -> Texture2D:
	if ui_arrow_indicator_tex:
		return ui_arrow_indicator_tex
	if ResourceLoader.exists("res://assets/ui/menus/common/ui_arrow_indicator.png"):
		ui_arrow_indicator_tex = load("res://assets/ui/menus/common/ui_arrow_indicator.png") as Texture2D
	if not ui_arrow_indicator_tex:
		var pattern := [
			"##.......",
			"###......",
			"#####....",
			"######...",
			"########.",
			"#########",
			"########.",
			"######...",
			"#####....",
			"###......",
			"##......."
		]
		var palette := {
			"#": Color8(61, 35, 20, 255),
			".": Color(0, 0, 0, 0)
		}
		ui_arrow_indicator_tex = _build_pixel_texture(9, 11, pattern, palette)
	return ui_arrow_indicator_tex


func _get_or_create_submenu_arrow(btn_node: Control) -> TextureRect:
	var arrow = btn_node.get_node_or_null("ArrowIndicator") as TextureRect
	if not arrow:
		arrow = TextureRect.new()
		arrow.name = "ArrowIndicator"
		arrow.texture = _get_arrow_indicator_texture()
		arrow.texture_filter = Control.TEXTURE_FILTER_NEAREST as Control.TextureFilter
		arrow.stretch_mode = TextureRect.STRETCH_KEEP
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.position = Vector2(-19.0, 12.0)
		arrow.size = Vector2(9.0, 11.0)
		arrow.modulate.a = 0.0
		arrow.visible = false
		btn_node.add_child(arrow)
	return arrow


func _update_submenu_arrow_indicator(btn_node: Control, idx: int, show_arrow: bool) -> void:
	var arrow := _get_or_create_submenu_arrow(btn_node)
	if not arrow:
		return

	if _submenu_arrow_tweens.has(idx) and is_instance_valid(_submenu_arrow_tweens[idx]):
		_submenu_arrow_tweens[idx].kill()

	var tween := create_tween().set_parallel(true)
	_submenu_arrow_tweens[idx] = tween

	if show_arrow:
		arrow.visible = true
		if arrow.modulate.a < 0.1:
			arrow.position.x = -19.0
		tween.tween_property(arrow, "position:x", -15.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(arrow, "modulate:a", 1.0, 0.10)
	else:
		tween.tween_property(arrow, "position:x", -19.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(arrow, "modulate:a", 0.0, 0.10)
		tween.chain().tween_callback(func():
			if is_instance_valid(arrow):
				var should_be_shown: bool = (hovered_settings_submenu == idx) or (hovered_settings_submenu == -1 and active_settings_submenu == idx)
				if not should_be_shown:
					arrow.visible = false
		)


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
				_play_ui_sfx(SFX_BOOK_TAB_SELECT, -5.0)
			else:
				if _active_dragging_slider == type:
					_active_dragging_slider = ""
					save_audio_settings()
					_play_ui_sfx(SFX_BOOK_TAB_SELECT, -5.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var cur_val: int = audio_settings.get(type, 100)
			_set_slider_value(type, mini(100, cur_val + 5))
			save_audio_settings()
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -6.0, 0.02)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var cur_val: int = audio_settings.get(type, 100)
			_set_slider_value(type, maxi(0, cur_val - 5))
			save_audio_settings()
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -6.0, 0.02)

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
		audio_settings.get("master", 100),
		audio_settings.get("music", 100),
		audio_settings.get("sfx", 100),
		audio_settings.get("dialog", 100)
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
		var val: int = audio_settings.get(t, 100)
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
			var loaded_key: int = int(config.get_value("controls", action_name, def_k))
			# Migrasi otomatis jika settings.cfg lama masih menyimpan KEY_U pada open_info yang sebelumnya dipindah
			if action_name == "open_info" and loaded_key == KEY_U:
				loaded_key = def_k
			control_bindings[action_name] = loaded_key
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
		if action_name == "use_skill":
			_bind_action_key("ui_skill", keycode)


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
	if is_instance_valid(controls_prompt):
		var action_q = controls_prompt.get_node_or_null("ActionQ")
		if is_instance_valid(action_q):
			var can_switch: bool = is_combat_hud_visible and (party_members.size() > 1) and is_character_switch_unlocked
			action_q.visible = can_switch
			if can_switch:
				var lbl = action_q.get_node_or_null("Label") as Label
				var ico = action_q.get_node_or_null("Icon") as TextureRect
				if lbl:
					lbl.text = "Ganti Karakter (1-4)"
				if ico:
					ico.visible = false
	var hud_bindings := {
		"use_skill": { "node": controls_prompt.get_node_or_null("ActionE/Icon") if is_instance_valid(controls_prompt) else null, "fixed_square": false, "target_h": 24.0 },
		"interact": { "node": null, "fixed_square": false, "target_h": 24.0 },
		"open_journal": { "node": null, "fixed_square": false, "target_h": 26.0 },
		"open_inventory": { "node": btn_hud_inventory.get_node_or_null("KeyHint") if is_instance_valid(btn_hud_inventory) else null, "fixed_square": false, "target_h": 20.0 },
		"open_info": { "node": btn_hud_info.get_node_or_null("KeyHint") if is_instance_valid(btn_hud_info) else null, "fixed_square": false, "target_h": 20.0 },
	}
	for action_name in hud_bindings.keys():
		var cfg: Dictionary = hud_bindings[action_name]
		var target_rect := cfg.get("node") as TextureRect
		if is_instance_valid(target_rect):
			var keycode: int = control_bindings.get(action_name, CONTROL_ACTION_INFO[action_name]["default_key"])
			_apply_hud_keycap_widget(target_rect, keycode, float(cfg.get("target_h", 18.0)), bool(cfg.get("fixed_square", false)))

	for btn_node in [inv_btn_gunakan, journal_btn_navigasi]:
		if is_instance_valid(btn_node):
			var icon_e := btn_node.get_node_or_null("IconE") as TextureRect
			if is_instance_valid(icon_e):
				_apply_hud_keycap_widget(icon_e, KEY_F, 18.0, true)


func _apply_hud_keycap_widget(tex_rect: TextureRect, keycode: int, target_h: float = 18.0, fixed_square: bool = false) -> void:
	if not is_instance_valid(tex_rect):
		return
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE as TextureRect.ExpandMode
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED as TextureRect.StretchMode
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
			fallback_lbl.set_anchors_preset(Control.PRESET_FULL_RECT as Control.LayoutPreset)
			fallback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER as HorizontalAlignment
			fallback_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER as VerticalAlignment
			fallback_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
			fallback_lbl.add_theme_font_override("font", preload("res://assets/ui/fonts/beholden-bold.ttf"))
			fallback_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.8, 1.0))
			tex_rect.add_child(fallback_lbl)
		fallback_lbl.add_theme_font_size_override("font_size", 8 if key_str.length() > 2 else 10)
		fallback_lbl.text = key_str
		fallback_lbl.visible = true


func _start_rebind(action_name: String) -> void:
	_rebind_action_id = action_name
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
	_refresh_controls_ui()


func _cancel_rebind() -> void:
	_rebind_action_id = ""
	_refresh_controls_ui()


func _apply_rebind(action_name: String, new_key: int) -> void:
	if new_key == KEY_ESCAPE:
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
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
	if action_name == "use_skill":
		_bind_action_key("ui_skill", new_key)
	if conflict_action == "use_skill":
		_bind_action_key("ui_skill", control_bindings["use_skill"])
	save_control_settings()
	_play_ui_sfx(SFX_BOOK_CONFIRM, -3.0)

	_rebind_action_id = ""
	_refresh_controls_ui()


# ==========================================
# SAVE & LOAD SYSTEM (TASK 05C)
# ==========================================

func _capture_gameplay_screenshot() -> void:
	var vp := get_viewport()
	if not is_instance_valid(vp):
		return
	var vp_tex := vp.get_texture()
	if not is_instance_valid(vp_tex):
		return
	var img := vp_tex.get_image()
	if not is_instance_valid(img) or img.is_empty():
		return

	var img_w: float = float(img.get_width())
	var img_h: float = float(img.get_height())
	if img_w <= 0.0 or img_h <= 0.0:
		return

	var target_ratio: float = 66.0 / 42.0
	var crop_w: float = img_w
	var crop_h: float = img_h

	if (img_w / img_h) > target_ratio:
		crop_w = img_h * target_ratio
	else:
		crop_h = img_w / target_ratio

	var crop_w_int: int = maxi(1, int(crop_w))
	var crop_h_int: int = maxi(1, int(crop_h))
	var crop_x: int = clampi(int(round((img_w - float(crop_w_int)) / 2.0)), 0, img.get_width() - crop_w_int)
	var crop_y: int = clampi(int(round((img_h - float(crop_h_int)) / 2.0)), 0, img.get_height() - crop_h_int)
	var crop_rect := Rect2i(crop_x, crop_y, crop_w_int, crop_h_int)
	var cropped_img := img.get_region(crop_rect)

	if cropped_img.get_format() != Image.FORMAT_RGBA8:
		cropped_img.convert(Image.FORMAT_RGBA8)

	cropped_img.resize(66, 42, Image.INTERPOLATE_BILINEAR)

	var png_buffer := cropped_img.save_png_to_buffer()
	if png_buffer.is_empty():
		return

	last_gameplay_thumbnail_tex = ImageTexture.create_from_image(cropped_img)
	last_gameplay_thumbnail_b64 = Marshalls.raw_to_base64(png_buffer)


func _get_slot_thumbnail_texture(slot_idx: int, data: Dictionary) -> Texture2D:
	if _slot_thumbnail_cache.has(slot_idx) and is_instance_valid(_slot_thumbnail_cache[slot_idx]):
		return _slot_thumbnail_cache[slot_idx]

	var b64: String = str(data.get("thumbnail_b64", "")).strip_edges()
	if not b64.is_empty():
		var raw_bytes := Marshalls.base64_to_raw(b64)
		if not raw_bytes.is_empty():
			var img := Image.new()
			if img.load_png_from_buffer(raw_bytes) == OK:
				var tex := ImageTexture.create_from_image(img)
				_slot_thumbnail_cache[slot_idx] = tex
				return tex

	return default_thumb_texture


func _init_save_load_system() -> void:
	# Inisialisasi texture thumbnail default
	if default_thumb_texture == null:
		var img := Image.new()
		var raw_bytes := Marshalls.base64_to_raw(DEFAULT_THUMB_B64)
		if img.load_png_from_buffer(raw_bytes) == OK:
			default_thumb_texture = ImageTexture.create_from_image(img)

	# Scan existing slot files (1..3)
	_scan_all_save_slots()

	# Inisialisasi tekstur tombol hapus tempat sampah
	var trash_tex_normal := _build_trash_icon_texture(Color8(140, 70, 70, 230))
	var trash_tex_hover := _build_trash_icon_texture(Color8(230, 60, 60, 255))
	var trash_tex_pressed := _build_trash_icon_texture(Color8(160, 30, 30, 255))

	# Hubungkan tombol klik dan tombol hapus pada setiap kartu slot (berdasarkan row_idx 0..2)
	for i in range(save_slot_rows.size()):
		var row_idx: int = i
		var row: Control = save_slot_rows[i]
		if is_instance_valid(row):
			var click_btn = row.get_node_or_null("SlotCard/ClickBtn") as TextureButton
			if click_btn:
				if click_btn.pressed.is_connected(_select_save_slot):
					click_btn.pressed.disconnect(_select_save_slot)
				if not click_btn.pressed.is_connected(_on_save_slot_row_clicked):
					click_btn.pressed.connect(_on_save_slot_row_clicked.bind(row_idx))
				_connect_book_hover_sfx(click_btn)

			var del_btn = row.get_node_or_null("SlotCard/BtnDelete") as TextureButton
			if del_btn:
				del_btn.texture_normal = trash_tex_normal
				del_btn.texture_hover = trash_tex_hover
				del_btn.texture_pressed = trash_tex_pressed
				del_btn.ignore_texture_size = true
				del_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED as TextureButton.StretchMode
				if not del_btn.pressed.is_connected(_on_save_slot_row_delete_pressed):
					del_btn.pressed.connect(_on_save_slot_row_delete_pressed.bind(row_idx))
				_connect_book_hover_sfx(del_btn)

	# Hubungkan interaksi tombol ganti halaman simpan & muat
	if is_instance_valid(btn_save_prev_page):
		if not btn_save_prev_page.gui_input.is_connected(_on_btn_save_prev_page_gui_input):
			btn_save_prev_page.gui_input.connect(_on_btn_save_prev_page_gui_input)
		if not btn_save_prev_page.mouse_entered.is_connected(_on_btn_save_prev_page_entered):
			btn_save_prev_page.mouse_entered.connect(_on_btn_save_prev_page_entered)
		if not btn_save_prev_page.mouse_exited.is_connected(_on_btn_save_prev_page_exited):
			btn_save_prev_page.mouse_exited.connect(_on_btn_save_prev_page_exited)

	if is_instance_valid(btn_save_next_page):
		if not btn_save_next_page.gui_input.is_connected(_on_btn_save_next_page_gui_input):
			btn_save_next_page.gui_input.connect(_on_btn_save_next_page_gui_input)
		if not btn_save_next_page.mouse_entered.is_connected(_on_btn_save_next_page_entered):
			btn_save_next_page.mouse_entered.connect(_on_btn_save_next_page_entered)
		if not btn_save_next_page.mouse_exited.is_connected(_on_btn_save_next_page_exited):
			btn_save_next_page.mouse_exited.connect(_on_btn_save_next_page_exited)

	if is_instance_valid(save_page_label):
		if not save_page_label.gui_input.is_connected(_on_save_page_label_gui_input):
			save_page_label.gui_input.connect(_on_save_page_label_gui_input)

	# Pastikan Baris Bawah Disembunyikan Sesuai Permintaan
	if is_instance_valid(save_bottom_row):
		save_bottom_row.visible = false
	if is_instance_valid(btn_simpan_box):
		btn_simpan_box.visible = false
	if is_instance_valid(btn_muat_box):
		btn_muat_box.visible = false
	if is_instance_valid(enter_hint):
		enter_hint.visible = false

	# Hubungkan Tombol Aksi Simpan & Muat
	if is_instance_valid(btn_simpan_click) and not btn_simpan_click.pressed.is_connected(_on_btn_simpan_pressed):
		btn_simpan_click.pressed.connect(_on_btn_simpan_pressed)
		_connect_book_hover_sfx(btn_simpan_click)

	if is_instance_valid(btn_muat_click) and not btn_muat_click.pressed.is_connected(_on_btn_muat_pressed):
		btn_muat_click.pressed.connect(_on_btn_muat_pressed)
		_connect_book_hover_sfx(btn_muat_click)

	# Hubungkan Tombol Modal Konfirmasi
	if is_instance_valid(btn_confirm_yes) and not btn_confirm_yes.pressed.is_connected(_on_confirm_yes_pressed):
		btn_confirm_yes.pressed.connect(_on_confirm_yes_pressed)
		_connect_book_hover_sfx(btn_confirm_yes, false, true)
	if is_instance_valid(btn_confirm_yes) and not btn_confirm_yes.mouse_entered.is_connected(_on_confirm_yes_hovered):
		btn_confirm_yes.mouse_entered.connect(_on_confirm_yes_hovered)

	if is_instance_valid(btn_confirm_timpa) and not btn_confirm_timpa.pressed.is_connected(_on_confirm_timpa_pressed):
		btn_confirm_timpa.pressed.connect(_on_confirm_timpa_pressed)
		_connect_book_hover_sfx(btn_confirm_timpa, false, true)
	if is_instance_valid(btn_confirm_timpa) and not btn_confirm_timpa.mouse_entered.is_connected(_on_confirm_timpa_hovered):
		btn_confirm_timpa.mouse_entered.connect(_on_confirm_timpa_hovered)

	if is_instance_valid(btn_confirm_no) and not btn_confirm_no.pressed.is_connected(_on_confirm_no_pressed):
		btn_confirm_no.pressed.connect(_on_confirm_no_pressed)
		_connect_book_hover_sfx(btn_confirm_no, false, true)
	if is_instance_valid(btn_confirm_no) and not btn_confirm_no.mouse_entered.is_connected(_on_confirm_no_hovered):
		btn_confirm_no.mouse_entered.connect(_on_confirm_no_hovered)

	if is_instance_valid(enter_hint) and not enter_hint.gui_input.is_connected(_on_enter_hint_gui_input):
		enter_hint.gui_input.connect(_on_enter_hint_gui_input)

	_refresh_save_load_ui()


func _scan_all_save_slots() -> void:
	save_slots_data.clear()
	_slot_thumbnail_cache.clear()
	var dir := DirAccess.open("user://")
	var found_slots: Array[int] = []
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("save_slot_") and file_name.ends_with(".json"):
				var num_part := file_name.trim_prefix("save_slot_").trim_suffix(".json")
				if num_part.is_valid_int():
					var s_id := num_part.to_int()
					if s_id > 0:
						found_slots.append(s_id)
			file_name = dir.get_next()
		dir.list_dir_end()

	for slot_idx in found_slots:
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

	_recalculate_save_pages()


func _recalculate_save_pages() -> void:
	var highest_occupied_slot: int = 0
	for s_id in save_slots_data.keys():
		if save_slots_data[s_id] != null:
			if int(s_id) > highest_occupied_slot:
				highest_occupied_slot = int(s_id)

	var base_pages: int = maxi(1, int(ceil(float(highest_occupied_slot) / float(SLOTS_PER_PAGE))))

	# Periksa apakah semua slot pada rentang base_pages sudah terisi (tidak ada slot kosong)
	var has_empty_slot: bool = false
	for s_id in range(1, base_pages * SLOTS_PER_PAGE + 1):
		if save_slots_data.get(s_id, null) == null:
			has_empty_slot = true
			break

	# Jika semua slot penuh (tidak ada slot kosong sama sekali), otomatis tambah 1 halaman baru!
	if not has_empty_slot:
		total_save_pages = base_pages + 1
	else:
		total_save_pages = base_pages

	current_save_page = clampi(current_save_page, 1, total_save_pages)
	var max_selectable: int = total_save_pages * SLOTS_PER_PAGE
	selected_save_slot = clampi(selected_save_slot, 1, max_selectable)


func _change_save_page(direction: int) -> void:
	var target_page := clampi(current_save_page + direction, 1, total_save_pages)
	if target_page == current_save_page:
		return
	current_save_page = target_page
	var row_in_page: int = (selected_save_slot - 1) % SLOTS_PER_PAGE
	selected_save_slot = (current_save_page - 1) * SLOTS_PER_PAGE + row_in_page + 1
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.0)
	_refresh_save_load_ui()


func _on_btn_save_prev_page_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_save_page > 1:
			_change_save_page(-1)


func _on_btn_save_next_page_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_save_page < total_save_pages:
			_change_save_page(1)


func _on_save_page_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if total_save_pages > 1:
			var dir := 1 if current_save_page < total_save_pages else -(total_save_pages - 1)
			_change_save_page(dir)


func _on_btn_save_prev_page_entered() -> void:
	if is_instance_valid(btn_save_prev_page) and current_save_page > 1:
		btn_save_prev_page.add_theme_color_override("font_color", Color(0.85, 0.45, 0.2, 1.0))


func _on_btn_save_prev_page_exited() -> void:
	if is_instance_valid(btn_save_prev_page):
		btn_save_prev_page.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3, 1.0))


func _on_btn_save_next_page_entered() -> void:
	if is_instance_valid(btn_save_next_page) and current_save_page < total_save_pages:
		btn_save_next_page.add_theme_color_override("font_color", Color(0.85, 0.45, 0.2, 1.0))


func _on_btn_save_next_page_exited() -> void:
	if is_instance_valid(btn_save_next_page):
		btn_save_next_page.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3, 1.0))


func _update_save_page_indicator() -> void:
	if is_instance_valid(save_page_label):
		save_page_label.text = "%d / %d" % [current_save_page, total_save_pages]

	if is_instance_valid(btn_save_prev_page):
		var can_prev := (current_save_page > 1)
		btn_save_prev_page.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_prev else Color(0.5, 0.45, 0.4, 0.35)
		btn_save_prev_page.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_prev else Control.CURSOR_ARROW
		btn_save_prev_page.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3, 1.0))

	if is_instance_valid(btn_save_next_page):
		var can_next := (current_save_page < total_save_pages)
		btn_save_next_page.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_next else Color(0.5, 0.45, 0.4, 0.35)
		btn_save_next_page.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_next else Control.CURSOR_ARROW
		btn_save_next_page.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3, 1.0))


func _on_save_slot_row_clicked(row_idx: int) -> void:
	var slot_idx: int = (current_save_page - 1) * SLOTS_PER_PAGE + row_idx + 1
	_on_save_slot_clicked(slot_idx)


func _on_save_slot_row_delete_pressed(row_idx: int) -> void:
	var slot_idx: int = (current_save_page - 1) * SLOTS_PER_PAGE + row_idx + 1
	_on_btn_delete_slot_pressed(slot_idx)


func _select_save_slot(slot_idx: int) -> void:
	selected_save_slot = clampi(slot_idx, 1, total_save_pages * SLOTS_PER_PAGE)
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5, 0.03)
	_refresh_save_load_ui()


func _on_save_slot_clicked(slot_idx: int) -> void:
	selected_save_slot = clampi(slot_idx, 1, total_save_pages * SLOTS_PER_PAGE)
	_refresh_save_load_ui()

	if is_start_menu_mode:
		var cur_data = save_slots_data.get(selected_save_slot, null)
		if cur_data != null and not cur_data.get("corrupted", false):
			_open_confirm_modal("Muat data simpan ini?", "load")
		else:
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -4.0)
			_show_save_feedback("Slot ini kosong atau rusak!")
	else:
		# Mode in-game: otomatis simpan atau timpa slot yang dipencet
		save_game_requested.emit(selected_save_slot)


func _refresh_save_load_ui() -> void:
	for i in range(save_slot_rows.size()):
		var slot_idx: int = (current_save_page - 1) * SLOTS_PER_PAGE + i + 1
		var row: Control = save_slot_rows[i]
		if not is_instance_valid(row):
			continue

		var slot_num_lbl = row.get_node_or_null("SlotNum") as Label
		if slot_num_lbl:
			slot_num_lbl.text = str(slot_idx)

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
			var mode_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/InfoCol/Mode") as Label
			var loc_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/InfoCol/Location") as Label
			var play_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/InfoCol/Playtime") as Label
			var time_lbl = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/SaveTime") as Label
			var thumb = row.get_node_or_null("SlotCard/ContentMargin/OccupiedView/TopRow/Thumbnail") as TextureRect

			var raw_mode: String = str(data.get("game_mode", "")).to_lower().strip_edges()
			var chapter_val: String = str(data.get("chapter", "")).strip_edges()
			var is_explore: bool = (raw_mode == "open_world" or raw_mode == "jelajah" or chapter_val == "Mode Jelajah" or chapter_val.to_lower().contains("jelajah"))
			var mode_display: String = "Mode: Jelajah" if is_explore else "Mode: Cerita"

			if chapter_lbl:
				if is_corrupt:
					chapter_lbl.text = "Data Rusak"
				elif is_explore:
					chapter_lbl.text = "Mode Jelajah"
				else:
					chapter_lbl.text = data.get("chapter", "Chapter 1.1")
				chapter_lbl.add_theme_color_override("font_color", Color(0.75, 0.2, 0.2, 1.0) if is_corrupt else Color(0.24, 0.15, 0.16, 1.0))
			if mode_lbl:
				mode_lbl.visible = not is_corrupt
				mode_lbl.text = mode_display
			if loc_lbl:
				loc_lbl.text = "Lokasi: " + str(data.get("location", "Istana Kerajaan"))
			if play_lbl:
				var pt: float = float(data.get("playtime", 0.0))
				play_lbl.text = "Waktu Bermain: " + _format_playtime_str(pt)
			if time_lbl:
				time_lbl.text = "Waktu Simpan: " + str(data.get("save_time_str", "-"))
			if thumb:
				thumb.visible = not is_corrupt
				thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				thumb.texture = _get_slot_thumbnail_texture(slot_idx, data)
		else:
			if occ_view: occ_view.visible = false
			if emp_view: emp_view.visible = true

		var del_btn = row.get_node_or_null("SlotCard/BtnDelete") as TextureButton
		if del_btn:
			del_btn.visible = (data != null and data is Dictionary)

	# Update Tombol Aksi Bawah (Disembunyikan sepenuhnya sesuai permintaan user)
	if is_instance_valid(save_bottom_row):
		save_bottom_row.visible = false
	if is_instance_valid(btn_simpan_box):
		btn_simpan_box.visible = false
	if is_instance_valid(btn_muat_box):
		btn_muat_box.visible = false
	if is_instance_valid(enter_hint):
		enter_hint.visible = false

	_update_save_page_indicator()


func _format_playtime_str(seconds: float) -> String:
	var total_secs := int(seconds)
	var hrs := int(float(total_secs) / 3600.0)
	var mins := int(float(total_secs % 3600) / 60.0)
	var secs := total_secs % 60
	return "%02d:%02d:%02d" % [hrs, mins, secs]


func _open_confirm_modal(message: String, action: String, show_timpa: bool = false, yes_text: String = "Ya", no_text: String = "Tidak") -> void:
	hide_interact_prompt(true)
	_outside_modal_pressed = false
	_outside_pause_pressed = false
	_pending_confirm_action = action
	confirm_modal_selected_idx = 0
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
		_update_confirm_modal_buttons_visual()
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.0)


func _close_confirm_modal() -> void:
	_outside_modal_pressed = false
	if is_instance_valid(save_confirm_modal):
		save_confirm_modal.visible = false
	if is_instance_valid(btn_confirm_timpa_box):
		btn_confirm_timpa_box.visible = false
	var btns := _get_confirm_modal_buttons()
	for b in btns:
		if is_instance_valid(b):
			var arrow := b.get_node_or_null("ArrowIndicator") as TextureRect
			if arrow:
				arrow.visible = false
			b.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _pending_confirm_action == "return_to_title" and active_settings_submenu == 3:
		active_settings_submenu = 2
		_update_submenu_buttons_visual()
	_pending_confirm_action = ""


func _on_confirm_yes_hovered() -> void:
	var btns := _get_confirm_modal_buttons()
	var idx := btns.find(btn_confirm_yes_box)
	if idx != -1 and confirm_modal_selected_idx != idx:
		confirm_modal_selected_idx = idx
		_update_confirm_modal_buttons_visual()


func _on_confirm_timpa_hovered() -> void:
	var btns := _get_confirm_modal_buttons()
	var idx := btns.find(btn_confirm_timpa_box)
	if idx != -1 and confirm_modal_selected_idx != idx:
		confirm_modal_selected_idx = idx
		_update_confirm_modal_buttons_visual()


func _on_confirm_no_hovered() -> void:
	var btns := _get_confirm_modal_buttons()
	var idx := btns.find(btn_confirm_no_box)
	if idx != -1 and confirm_modal_selected_idx != idx:
		confirm_modal_selected_idx = idx
		_update_confirm_modal_buttons_visual()


func _get_confirm_modal_buttons() -> Array[NinePatchRect]:
	var list: Array[NinePatchRect] = []
	if is_instance_valid(btn_confirm_yes_box) and btn_confirm_yes_box.visible:
		list.append(btn_confirm_yes_box)
	if is_instance_valid(btn_confirm_timpa_box) and btn_confirm_timpa_box.visible:
		list.append(btn_confirm_timpa_box)
	if is_instance_valid(btn_confirm_no_box) and btn_confirm_no_box.visible:
		list.append(btn_confirm_no_box)
	return list


func _get_or_create_confirm_btn_arrow(btn_node: Control) -> TextureRect:
	var arrow = btn_node.get_node_or_null("ArrowIndicator") as TextureRect
	if not arrow:
		arrow = TextureRect.new()
		arrow.name = "ArrowIndicator"
		arrow.texture = _get_arrow_indicator_texture()
		arrow.texture_filter = Control.TEXTURE_FILTER_NEAREST as Control.TextureFilter
		arrow.stretch_mode = TextureRect.STRETCH_KEEP
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.position = Vector2(-18.0, 13.5)
		arrow.size = Vector2(9.0, 11.0)
		arrow.visible = false
		btn_node.add_child(arrow)
	return arrow


func _update_confirm_modal_buttons_visual() -> void:
	var btns := _get_confirm_modal_buttons()
	if btns.is_empty():
		return
	if confirm_modal_selected_idx < 0:
		confirm_modal_selected_idx = 0
	elif confirm_modal_selected_idx >= btns.size():
		confirm_modal_selected_idx = btns.size() - 1

	for i in range(btns.size()):
		var b := btns[i]
		if not is_instance_valid(b):
			continue
		var is_sel := (i == confirm_modal_selected_idx)
		if is_sel:
			b.texture = submenu_btn_hover_tex if submenu_btn_hover_tex else submenu_btn_normal_tex
			b.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			b.texture = submenu_btn_normal_tex
			b.modulate = Color(0.85, 0.82, 0.78, 1.0)

		var lbl := b.get_node_or_null("Label") as Label
		if lbl:
			if is_sel:
				lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
			else:
				lbl.add_theme_color_override("font_color", Color(0.48, 0.38, 0.38, 1.0))

		var arrow := _get_or_create_confirm_btn_arrow(b)
		if arrow:
			arrow.visible = is_sel


func _navigate_confirm_modal_buttons(delta: int) -> void:
	var btns := _get_confirm_modal_buttons()
	if btns.size() <= 1:
		return
	var new_idx := (confirm_modal_selected_idx + delta) % btns.size()
	if new_idx < 0:
		new_idx += btns.size()
	if new_idx != confirm_modal_selected_idx:
		confirm_modal_selected_idx = new_idx
		_play_ui_sfx(SFX_UI_HOVER, -4.0)
		_update_confirm_modal_buttons_visual()


func _execute_selected_confirm_modal_button() -> void:
	var btns := _get_confirm_modal_buttons()
	if btns.is_empty():
		return
	var sel_box := btns[clampi(confirm_modal_selected_idx, 0, btns.size() - 1)]
	if sel_box == btn_confirm_yes_box:
		_on_confirm_yes_pressed()
	elif sel_box == btn_confirm_timpa_box:
		_on_confirm_timpa_pressed()
	elif sel_box == btn_confirm_no_box:
		_on_confirm_no_pressed()


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
	if _is_dragging or _drag_candidate_slot_idx != -1 or _active_dragging_slider != "" or is_instance_valid(_active_v_scrollbar):
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
			_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
			_close_confirm_modal()
		else:
			_outside_modal_pressed = false


func _on_enter_hint_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_save_load_enter_pressed()


func _on_btn_simpan_pressed() -> void:
	if is_start_menu_mode:
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -4.0)
		_show_save_feedback("Simpan & Muat hanya tersedia saat bermain!")
		return
	var cur_data = save_slots_data.get(selected_save_slot, null)
	if cur_data != null:
		_open_confirm_modal("Timpa data simpan ini?", "overwrite")
	else:
		save_game_requested.emit(selected_save_slot)


func _on_btn_muat_pressed() -> void:
	var cur_data = save_slots_data.get(selected_save_slot, null)
	if cur_data != null and not cur_data.get("corrupted", false):
		_open_confirm_modal("Muat data simpan ini?", "load")
	else:
		_play_ui_sfx(SFX_BOOK_TAB_SELECT, -4.0)
		_show_save_feedback("Slot ini kosong atau rusak!")


func _on_save_load_enter_pressed() -> void:
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		_safe_set_input_handled()
		_execute_selected_confirm_modal_button()
		return

	_on_save_slot_clicked(selected_save_slot)


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


func _on_btn_delete_slot_pressed(slot_idx: int) -> void:
	selected_save_slot = clampi(slot_idx, 1, total_save_pages * SLOTS_PER_PAGE)
	_refresh_save_load_ui()
	_open_confirm_modal("Hapus data simpan Slot %d?\nData yang dihapus tidak dapat dipulihkan." % slot_idx, "delete_slot")


func _delete_save_slot_file(slot_id: int) -> void:
	var dir := DirAccess.open("user://")
	if dir:
		var file_name := "save_slot_%d.json" % slot_id
		if dir.file_exists(file_name):
			dir.remove(file_name)
		var tmp_name := "save_slot_%d.json.tmp" % slot_id
		if dir.file_exists(tmp_name):
			dir.remove(tmp_name)
	save_slots_data.erase(slot_id)
	_slot_thumbnail_cache.erase(slot_id)
	_recalculate_save_pages()
	_refresh_save_load_ui()
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -2.0)
	_show_save_feedback("Data Slot %d berhasil dihapus!" % slot_id)


func _on_confirm_yes_pressed() -> void:
	var action := _pending_confirm_action
	_close_confirm_modal()

	if action == "overwrite" or action == "save":
		save_game_requested.emit(selected_save_slot)
	elif action == "load" or action == "slot_action":
		load_game_requested.emit(selected_save_slot)
	elif action == "delete_slot":
		_delete_save_slot_file(selected_save_slot)
	elif action == "return_to_title":
		_execute_return_to_title()


func _on_confirm_timpa_pressed() -> void:
	_close_confirm_modal()
	save_game_requested.emit(selected_save_slot)


func _on_confirm_no_pressed() -> void:
	_play_ui_sfx(SFX_BOOK_TAB_SELECT, -3.5)
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
	if is_instance_valid(last_gameplay_thumbnail_tex):
		_slot_thumbnail_cache[slot_id] = last_gameplay_thumbnail_tex
	elif saved_data.has("thumbnail_b64"):
		_slot_thumbnail_cache.erase(slot_id)
	_recalculate_save_pages()
	_refresh_save_load_ui()
	_play_ui_sfx(SFX_BOOK_CONFIRM, -2.0)
	_show_save_feedback("Progress berhasil disimpan di Slot %d!" % slot_id)


func on_load_completed(slot_id: int, _loaded_data: Dictionary) -> void:
	if _save_feedback_tween and _save_feedback_tween.is_valid():
		_save_feedback_tween.kill()
	if is_instance_valid(save_feedback_label):
		save_feedback_label.visible = false
	if _loaded_data.has("thumbnail_b64") and not str(_loaded_data.get("thumbnail_b64", "")).is_empty():
		last_gameplay_thumbnail_b64 = str(_loaded_data.get("thumbnail_b64", ""))
		var loaded_thumb := _get_slot_thumbnail_texture(slot_id, _loaded_data)
		if is_instance_valid(loaded_thumb) and loaded_thumb != default_thumb_texture:
			last_gameplay_thumbnail_tex = loaded_thumb
	_scan_all_save_slots()
	_refresh_save_load_ui()
	_play_ui_sfx(SFX_BOOK_CONFIRM, -2.0)
	_show_save_feedback("Progress berhasil dimuat dari Slot %d!" % slot_id)


# =========================================================
# DIALOGUE SYSTEM (SISTEM DIALOG & NARASI CERITA)
# =========================================================

func _play_dialog_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if not stream or not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
	if AudioServer.get_bus_index("Dialog") != -1:
		player.bus = "Dialog"
	elif AudioServer.get_bus_index("SFX") != -1:
		player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	if pitch_jitter > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func show_dialogue(dialogue_id: String, entries: Array[Dictionary], on_complete: Callable = Callable()) -> void:
	hide_interact_prompt(true)
	if entries.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return

	_dialogue_id = dialogue_id
	_dialogue_queue = entries.duplicate()
	_dialogue_index = 0
	_dialogue_callback = on_complete
	_is_dialogue_active = true

	# Sembunyikan elemen gameplay HUD agar fokus ke narasi
	_set_gameplay_hud_visible_for_dialogue(false)

	if is_instance_valid(dialogue_container):
		dialogue_container.modulate.a = 0.0
		dialogue_container.visible = true
		var fade_in := create_tween()
		fade_in.tween_property(dialogue_container, "modulate:a", 1.0, 0.18)

	_start_arrow_animation()
	_display_current_dialogue_entry()
	emit_signal("dialogue_started", _dialogue_id)


func _set_gameplay_hud_visible_for_dialogue(show_hud: bool) -> void:
	if is_instance_valid(party_container):
		party_container.visible = show_hud
	if is_instance_valid(skill_container):
		skill_container.visible = show_hud
	if is_instance_valid(controls_prompt):
		controls_prompt.visible = show_hud
	if is_instance_valid(btn_hud_inventory):
		btn_hud_inventory.visible = show_hud
	if is_instance_valid(btn_hud_info):
		btn_hud_info.visible = show_hud
	if is_instance_valid(btn_pause_menu):
		btn_pause_menu.visible = show_hud
	if is_instance_valid(quest_header):
		quest_header.visible = show_hud and not is_combat_hud_visible and not is_open_world_mode
	if is_instance_valid(quest_container):
		quest_container.visible = show_hud and not is_combat_hud_visible and not is_open_world_mode
	if not show_hud and is_instance_valid(_interact_prompt_panel):
		_interact_prompt_panel.visible = false
		_interact_prompt_panel.modulate.a = 0.0


func _display_current_dialogue_entry() -> void:
	if _dialogue_index < 0 or _dialogue_index >= _dialogue_queue.size():
		return

	var entry: Dictionary = _dialogue_queue[_dialogue_index]
	var speaker: String = entry.get("speaker", "")
	var text_content: String = entry.get("text", "")
	var portrait_key: String = entry.get("portrait", "")

	if is_instance_valid(dialogue_speaker_label):
		dialogue_speaker_label.text = speaker

	_current_full_text = text_content
	_last_typed_char_count = 0
	if is_instance_valid(dialogue_text):
		dialogue_text.text = text_content
		dialogue_text.visible_characters = 0

	_is_typing = true

	# Resolusi portret pembicara
	var port_tex: Texture2D = null
	if entry.has("portrait_texture") and entry["portrait_texture"] is Texture2D:
		port_tex = entry["portrait_texture"]
	else:
		port_tex = resolve_dialogue_portrait(portrait_key if not portrait_key.is_empty() else speaker)

	if is_instance_valid(dialogue_portrait):
		dialogue_portrait.texture = port_tex
	if is_instance_valid(dialogue_portrait_frame):
		dialogue_portrait_frame.visible = (port_tex != null)

	# Animasi typewriter dengan suara blip per karakter
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var char_count: int = text_content.length()
	var duration: float = clampf(float(char_count) * 0.024, 0.4, 2.4)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_method(_on_typewriter_step, 0, char_count, duration)
	_typewriter_tween.finished.connect(func():
		if is_instance_valid(dialogue_text):
			dialogue_text.visible_characters = -1
		_is_typing = false
	)


func _on_typewriter_step(curr_chars: int) -> void:
	if not is_instance_valid(dialogue_text):
		return
	dialogue_text.visible_characters = curr_chars
	if curr_chars > _last_typed_char_count + 1:
		_last_typed_char_count = curr_chars
		if curr_chars <= _current_full_text.length():
			var c: String = _current_full_text[curr_chars - 1]
			if c != " " and c != "\n" and c != "\t":
				_play_dialog_sfx(SFX_UI_CLICK, -15.0, 0.08)


func resolve_dialogue_portrait(key: String) -> Texture2D:
	var lower := key.to_lower().strip_edges()
	if "gagak" in lower or "raven" in lower or "crow" in lower:
		if portrait_raven == null:
			portrait_raven = _create_atlas(RAVEN_SHEET, Rect2(6, 8, 18, 18))
		return portrait_raven
	elif "arthur" in lower or "knight" in lower or "pangeran" in lower:
		return PORTRAIT_ARTHUR
	elif "magnus" in lower or "mage" in lower or "wizard" in lower or "penasehat" in lower:
		return PORTRAIT_MAGNUS
	elif "anastasya" in lower or "archer" in lower or "carina" in lower:
		return PORTRAIT_ANASTASYA
	elif "hellene" in lower or "bandit" in lower or "assassin" in lower:
		return PORTRAIT_HELLENE
	elif "raja" in lower or "king" in lower or "petinggi" in lower:
		if portrait_king == null:
			var tex: Texture2D = load("res://assets/characters/npc/king/idle-s.png")
			if tex:
				portrait_king = _create_atlas(tex, Rect2(36, 16, 24, 24))
		return portrait_king
	elif "ratu" in lower or "queen" in lower:
		if portrait_queen == null:
			var tex: Texture2D = load("res://assets/characters/npc/queen/idle-s.png")
			if tex:
				portrait_queen = _create_atlas(tex, Rect2(36, 16, 24, 24))
		return portrait_queen
	elif "wizandy" in lower:
		if portrait_wizandy == null:
			portrait_wizandy = load("res://assets/characters/npc/seer/Wizandy.png")
		return portrait_wizandy
	elif "wizashley" in lower:
		if portrait_wizashley == null:
			portrait_wizashley = load("res://assets/characters/npc/seer/Wizashley.png")
		return portrait_wizashley
	elif "peramal" in lower or "oracle" in lower or "seer" in lower:
		return PORTRAIT_MAGNUS
	elif "alaric" in lower or "pelatih" in lower or "trainer" in lower:
		if portrait_alaric == null:
			var tex: Texture2D = load("res://assets/characters/npc/alaric/idle-s.png")
			if tex:
				portrait_alaric = _create_atlas(tex, Rect2(36, 16, 24, 24))
		return portrait_alaric
	elif "archon" in lower or "mindfulness" in lower or "penjaga" in lower:
		return PORTRAIT_MAGNUS
	return null


func _on_dialogue_clicked() -> void:
	if not _is_dialogue_active:
		return
	_advance_or_complete_dialogue()


func _advance_or_complete_dialogue() -> void:
	if not _is_dialogue_active:
		return
	if _is_typing:
		_finish_typewriter_instantly()
	else:
		_advance_dialogue()


func _finish_typewriter_instantly() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
		_typewriter_tween = null
	if is_instance_valid(dialogue_text):
		dialogue_text.visible_characters = -1
	_is_typing = false


func _advance_dialogue() -> void:
	_play_dialog_sfx(SFX_BOOK_TAB_SELECT, -3.5)
	_dialogue_index += 1
	if _dialogue_index < _dialogue_queue.size():
		_display_current_dialogue_entry()
		emit_signal("dialogue_advanced", _dialogue_index, _dialogue_queue.size())
	else:
		close_dialogue()


func close_dialogue() -> void:
	if not _is_dialogue_active:
		return
	_is_dialogue_active = false
	_play_dialog_sfx(SFX_BOOK_PAGE_FLIP, -3.0)

	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
		_typewriter_tween = null
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
		_arrow_tween = null

	if is_instance_valid(dialogue_container):
		var fade_out := create_tween()
		fade_out.tween_property(dialogue_container, "modulate:a", 0.0, 0.15)
		fade_out.tween_callback(func():
			if is_instance_valid(dialogue_container):
				dialogue_container.visible = false
				dialogue_container.modulate.a = 1.0
			_set_gameplay_hud_visible_for_dialogue(true)
		)
	else:
		_set_gameplay_hud_visible_for_dialogue(true)

	var cb := _dialogue_callback
	var finished_id := _dialogue_id
	_dialogue_queue = []
	_dialogue_index = 0
	_dialogue_id = ""
	_dialogue_callback = Callable()

	emit_signal("dialogue_finished", finished_id)
	if cb.is_valid():
		cb.call()


func is_dialogue_active() -> bool:
	return _is_dialogue_active


func _start_arrow_animation() -> void:
	if not is_instance_valid(dialogue_prompt_arrow):
		return
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	dialogue_prompt_arrow.position.y = 0.0
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(dialogue_prompt_arrow, "position:y", 3.0, 0.45).set_trans(Tween.TRANS_SINE)
	_arrow_tween.tween_property(dialogue_prompt_arrow, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_SINE)


# =========================================================
# INTERACTION PROMPT & OBJECTIVE NAVIGATION
# =========================================================

func _setup_interact_prompt_ui() -> void:
	if not is_instance_valid(root_control):
		return

	_interact_prompt_panel = PanelContainer.new()
	_interact_prompt_panel.name = "InteractPromptPanel"
	_interact_prompt_panel.anchor_left = 0.5
	_interact_prompt_panel.anchor_right = 0.5
	_interact_prompt_panel.anchor_top = 0.82
	_interact_prompt_panel.anchor_bottom = 0.82
	_interact_prompt_panel.offset_left = -130
	_interact_prompt_panel.offset_right = 130
	_interact_prompt_panel.offset_top = -22
	_interact_prompt_panel.offset_bottom = 22
	_interact_prompt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_interact_prompt_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_interact_prompt_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.90)
	style.border_color = Color(0.9, 0.78, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_interact_prompt_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	_interact_prompt_panel.add_child(hbox)

	var key_panel := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color(0.22, 0.20, 0.28, 1.0)
	key_style.border_color = Color(1.0, 0.85, 0.35, 1.0)
	key_style.set_border_width_all(1)
	key_style.set_corner_radius_all(3)
	key_style.content_margin_left = 6
	key_style.content_margin_right = 6
	key_style.content_margin_top = 2
	key_style.content_margin_bottom = 2
	key_panel.add_theme_stylebox_override("panel", key_style)
	hbox.add_child(key_panel)

	var font: Font = preload("res://assets/ui/fonts/beholden-bold.ttf")

	_interact_key_label = Label.new()
	_interact_key_label.text = "[E]"
	_interact_key_label.add_theme_font_override("font", font)
	_interact_key_label.add_theme_font_size_override("font_size", 13)
	_interact_key_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	key_panel.add_child(_interact_key_label)

	_interact_prompt_label = Label.new()
	_interact_prompt_label.text = "Masuk ke Aula Kastil"
	_interact_prompt_label.add_theme_font_override("font", font)
	_interact_prompt_label.add_theme_font_size_override("font_size", 14)
	_interact_prompt_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.94, 1.0))
	hbox.add_child(_interact_prompt_label)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		emit_signal("interaction_pressed", _interact_action_type)
	)
	_interact_prompt_panel.add_child(btn)

	_interact_prompt_panel.visible = false
	_interact_prompt_panel.modulate.a = 0.0
	root_control.add_child(_interact_prompt_panel)
	if is_instance_valid(dialogue_container):
		root_control.move_child(_interact_prompt_panel, dialogue_container.get_index())
	elif is_instance_valid(pause_overlay):
		root_control.move_child(_interact_prompt_panel, pause_overlay.get_index())


func is_any_menu_open() -> bool:
	if is_instance_valid(pause_overlay) and pause_overlay.visible:
		return true
	if is_instance_valid(save_confirm_modal) and save_confirm_modal.visible:
		return true
	if _is_dialogue_active:
		return true
	return false


func show_interact_prompt(prompt_text: String = "Masuk ke Aula Kastil", key_str: String = "E", action_type: String = "") -> void:
	if not is_instance_valid(_interact_prompt_panel) or _is_dialogue_active or is_any_menu_open() or get_tree().paused:
		if is_instance_valid(_interact_prompt_panel) and _interact_prompt_panel.visible:
			_interact_prompt_panel.visible = false
			_interact_prompt_panel.modulate.a = 0.0
		return
	_interact_action_type = action_type if action_type != "" else prompt_text
	if is_instance_valid(_interact_prompt_label):
		_interact_prompt_label.text = prompt_text
	if is_instance_valid(_interact_key_label):
		_interact_key_label.text = "[%s]" % key_str

	if not _interact_prompt_panel.visible or _interact_prompt_panel.modulate.a < 0.9:
		_interact_prompt_panel.visible = true
		var t := create_tween()
		t.tween_property(_interact_prompt_panel, "modulate:a", 1.0, 0.15)


func hide_interact_prompt(instant: bool = false) -> void:
	if not is_instance_valid(_interact_prompt_panel):
		return
	if instant or _is_dialogue_active:
		_interact_prompt_panel.visible = false
		_interact_prompt_panel.modulate.a = 0.0
		return
	if not _interact_prompt_panel.visible:
		return
	var t := create_tween()
	t.tween_property(_interact_prompt_panel, "modulate:a", 0.0, 0.12)
	t.tween_callback(func():
		if is_instance_valid(_interact_prompt_panel):
			_interact_prompt_panel.visible = false
	)


func _setup_quest_navigation_ui() -> void:
	if not is_instance_valid(root_control):
		return

	var nav_row: Control = get_node_or_null("RootControl/QuestContainer/HBox/TextContainer/NavRow")
	if is_instance_valid(nav_row):
		_nav_tracker_panel = nav_row
		_nav_tracker_arrow = nav_row.get_node_or_null("NavArrow") as Label
		_nav_tracker_label = nav_row.get_node_or_null("NavLabel") as Label
		_nav_tracker_panel.visible = false
		return

	# Fallback if NavRow not yet in static scene
	var text_container = get_node_or_null("RootControl/QuestContainer/HBox/TextContainer")
	if is_instance_valid(text_container):
		var hbox := HBoxContainer.new()
		hbox.name = "NavRow"
		hbox.add_theme_constant_override("separation", 6)

		var font: Font = preload("res://assets/ui/fonts/beholden-bold.ttf")

		_nav_tracker_arrow = Label.new()
		_nav_tracker_arrow.name = "NavArrow"
		_nav_tracker_arrow.text = "▲"
		_nav_tracker_arrow.add_theme_font_override("font", font)
		_nav_tracker_arrow.add_theme_font_size_override("font_size", 13)
		_nav_tracker_arrow.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
		_nav_tracker_arrow.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.08, 0.8))
		_nav_tracker_arrow.add_theme_constant_override("shadow_offset_x", 1)
		_nav_tracker_arrow.add_theme_constant_override("shadow_offset_y", 1)
		hbox.add_child(_nav_tracker_arrow)

		_nav_tracker_label = Label.new()
		_nav_tracker_label.name = "NavLabel"
		_nav_tracker_label.text = "Menuju Kastil"
		_nav_tracker_label.add_theme_font_override("font", font)
		_nav_tracker_label.add_theme_font_size_override("font_size", 13)
		_nav_tracker_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.85, 1.0))
		_nav_tracker_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.08, 0.8))
		_nav_tracker_label.add_theme_constant_override("shadow_offset_x", 1)
		_nav_tracker_label.add_theme_constant_override("shadow_offset_y", 1)
		hbox.add_child(_nav_tracker_label)

		hbox.visible = false
		text_container.add_child(hbox)
		_nav_tracker_panel = hbox


func set_quest_navigation(target_pos: Vector2, target_name: String) -> void:
	if is_open_world_mode:
		hide_quest_navigation()
		return
	_nav_target_pos = target_pos
	_nav_target_name = target_name
	_is_nav_active = true
	if is_instance_valid(_nav_tracker_panel):
		_nav_tracker_panel.visible = true


func hide_quest_navigation() -> void:
	_is_nav_active = false
	if is_instance_valid(_nav_tracker_panel):
		_nav_tracker_panel.visible = false


func update_quest_navigation(leader_pos: Vector2) -> void:
	if is_open_world_mode or not _is_nav_active or not is_instance_valid(_nav_tracker_panel):
		if is_instance_valid(_nav_tracker_panel):
			_nav_tracker_panel.visible = false
		return
	var diff := _nav_target_pos - leader_pos
	var dist := diff.length()
	var dist_m := int(dist / 20.0)

	var arrow_char := "▲"
	var angle := diff.angle()
	var deg := rad_to_deg(angle)
	if deg >= -22.5 and deg < 22.5:
		arrow_char = "▶"
	elif deg >= 22.5 and deg < 67.5:
		arrow_char = "▼"
	elif deg >= 67.5 and deg < 112.5:
		arrow_char = "▼"
	elif deg >= 112.5 and deg < 157.5:
		arrow_char = "◀"
	elif deg >= 157.5 or deg < -157.5:
		arrow_char = "◀"
	elif deg >= -157.5 and deg < -112.5:
		arrow_char = "▲"
	elif deg >= -112.5 and deg < -67.5:
		arrow_char = "▲"
	elif deg >= -67.5 and deg < -22.5:
		arrow_char = "▲"

	if is_instance_valid(_nav_tracker_arrow):
		_nav_tracker_arrow.text = arrow_char

	if is_instance_valid(_nav_tracker_label):
		if dist <= 100.0:
			_nav_tracker_label.text = "%s (Tiba)" % _nav_target_name
			_nav_tracker_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
		else:
			_nav_tracker_label.text = "%s (%d m)" % [_nav_target_name, dist_m]
			_nav_tracker_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.85, 1.0))
