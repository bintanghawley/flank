extends Node2D

# =========================================================
# GAME CONTROLLER & 4-CHARACTER PARTY MANAGER
# =========================================================

@onready var camera: Camera2D = $Camera2D
@onready var gameplay_hud = get_node_or_null("GameplayHud")

static var pending_load_slot_id: int = -1
static var selected_game_mode: String = "story" # "story" atau "open_world"

var party_members: Array[CharacterBody2D] = []
var all_heroes: Dictionary = {}
var active_leader_index: int = 0
var inventory_items: Array[Dictionary] = []
var quest_list: Array[Dictionary] = []
var tracked_quest_id: String = "main_01"
const DEFAULT_START_LOCATION: String = "Istana Kerajaan"
var current_location_name: String = DEFAULT_START_LOCATION
var visited_locations: Array[String] = []
var total_playtime: float = 0.0
var is_prologue_completed: bool = false

# =========================================================
# LOKASI KASTIL & AULA RAPAT ISTANA
# =========================================================
const CASTLE_ENTRANCE_POS: Vector2 = Vector2(2533.0, 1035.0)
const CASTLE_HALL_SPAWN_POS: Vector2 = Vector2(2533.0, -1180.0)
const CASTLE_HALL_EXIT_POS: Vector2 = Vector2(2533.0, -1060.0)
const CASTLE_OUTSIDE_SPAWN_POS: Vector2 = Vector2(2533.0, 1090.0)
const CASTLE_MEETING_SEAT_GLOBAL_POS: Vector2 = Vector2(2457.0, -1375.0)
const CASTLE_MEETING_SIT_POS: Vector2 = Vector2(2457.0, -1385.0)
const CASTLE_MEETING_TABLE_CENTER: Vector2 = Vector2(2533.0, -1490.0)
const CASTLE_LIBRARY_POS: Vector2 = Vector2(2533.0, -1720.0) # deprecated, diganti konstanta library baru
# === SECRET LIBRARY ===
const LIBRARY_ENTRANCE_POS: Vector2 = Vector2(690.0, 1380.0)        # Pintu luar perpustakaan (toko ramuan sisi barat kota)
const SECRET_LIBRARY_EXIT_L1_POS: Vector2 = Vector2(4300.0, -1140.0) # Pintu keluar Lantai 1 perpustakaan
const SECRET_LIBRARY_WORLD_POS: Vector2 = Vector2(4300.0, -1500.0)
const SECRET_LIBRARY_L1_SPAWN: Vector2 = Vector2(4300.0, -1340.0)   # tengah lantai 1 (spawn masuk)
const SECRET_LIBRARY_L2_SPAWN: Vector2 = Vector2(4235.0, -1610.0)   # tengah karpet merah lantai 2 (menghadap rak buku utama)
const SECRET_LIBRARY_STAIR_POS: Vector2 = Vector2(3870.0, -1360.0)  # posisi tangga (kiri bawah L1)
var is_scene_4_in_progress: bool = false
var is_scene_4_completed: bool = false
var is_inside_secret_library: bool = false
var is_on_library_floor_2: bool = false

func _is_near_library_entrance(pos: Vector2) -> bool:
	if pos.distance_to(LIBRARY_ENTRANCE_POS) <= 130.0:
		return true
	return pos.x >= 600.0 and pos.x <= 800.0 and pos.y >= 1340.0 and pos.y <= 1490.0
const ALARIC_CAMP_POS: Vector2 = Vector2(6780.0, 1700.0)
const ARTHUR_CAMP_RETURN_POS: Vector2 = Vector2(6650.0, 1700.0)
const ARENA_KAMP_ARTHUR_POS: Vector2 = Vector2(7950.0, -1210.0)
const ARENA_KAMP_ALARIC_POS: Vector2 = Vector2(8350.0, -1210.0)
const ARENA_KAMP_CENTER_POS: Vector2 = Vector2(8155.0, -1210.0)
const GRAVEYARD_POS: Vector2 = Vector2(4400.0, 2900.0)
const FOREST_CABIN_DOOR_POS: Vector2 = Vector2(8650.0, 3840.0)
const FOREST_CAMP_STOP_POS: Vector2 = Vector2(8650.0, 4350.0)
const FOREST_CROW_SPAWN_POS: Vector2 = Vector2(9800.0, 3600.0)
const FOREST_CROW_PERCH_POS: Vector2 = Vector2(8820.0, 4171.0)
const FOREST_MAGNUS_POS: Vector2 = Vector2(8510.0, 4320.0)
const FOREST_MONSTER_ARENA_POS: Vector2 = Vector2(6740.0, 5500.0)

const CASTLE_APPROACH_START_POS: Vector2 = Vector2(2533.0, 3500.0)
const CASTLE_APPROACH_STOP_POS: Vector2 = Vector2(2533.0, 2400.0)

var _prologue_guards: Array[Node2D] = []
var _prologue_crow: Sprite2D = null
var _prologue_crow_flap_tween: Tween = null
var is_inside_castle_hall: bool = false
var is_in_arena_kamp: bool = false
var is_meeting_in_progress: bool = false
var _marker_bob_time: float = 0.0
var world_map_min: Vector2 = Vector2.ZERO
var world_map_max: Vector2 = Vector2.ZERO
var _nav_compass = null

# =========================================================
# NASKAH DIALOG CERITA PROLOG (CH0-SC02)
# Sesuai Storyboard FLK-002
# =========================================================
const PROLOGUE_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Hah... pegal juga seharian memeriksa kayu. Sebelum pulang, aku mau lemaskan badan sebentar ke arah tebing."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Hati-hati, Arthur. Pengawal bilang ada beberapa monster berkeliaran di dekat sana."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Tenang saja, hitung-hitung pemanasan. Tunggu sebentar di sini."
	}
]

# Sesuai Naskah Dialog 1B (Setelah Fight & Burung Gagak Tiba)
const PROLOGUE_POST_FIGHT_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Hah... sejuk juga di sini. Menurutku observasi kayu hari ini cukup sampai di sini saja. Tebing batu tadi kelihatannya cocok kalau kita jadikan pusat pertambangan. Menurutmu bagaimana, Magnus?"
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Perintahmu kan kewajiban bagi kami. Tapi sebagai kawan lamamu, dari dulu pilihan instingmu memang jarang meleset."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Hahaha! Ayolah Magnus, jangan kaku begitu. Mentang-mentang ayah dan ibu menyuruhku memimpin proyek ini, kalian jadi bicara formal sekali. Padahal dulu kita duduk di bangku yang sama waktu di akademi."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Ya mau bagaimana lagi, bagaimanapun kau itu pangeran. Tapi kalau kau maunya santai, ya baguslah. Soal tambang tadi aku setuju, tanahnya memang padat."
	},
	{
		"speaker": "Burung Gagak",
		"portrait": "raven",
		"text": "KROKK! KROK-KROKK!! KROKKK! KROK!!"
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Apa yang burung itu katakan? Dari tadi diam saja, sekarang malah membentak seperti sedang banyak masalah keluarga."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Tunggu sebentar, Arthur... Ini bukan gagak liar. Burung ini bawa pesan sihir dari dewan istana."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Pesan apa?"
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Ini gawat. Dunia kita terancam. Para peramal di istana baru saja mendapat ramalan buruk soal kiamat."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Ayo cepat kembali ke istana. Kita harus kumpulkan para petinggi dan laporkan ini ke Yang Mulia Raja dan Ratu!"
	}
]

# =========================================================
# NASKAH DIALOG AULA RAPAT KASTIL (CHAPTER 1.1 / CH1-SC05)
# Sesuai Storyboard FLK-005
# =========================================================
const CASTLE_MEETING_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Mungkin para peramal bisa menjelaskan, apa yang terjadi akhir-akhir ini."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Setidaknya, kami menyimpulkan bahwa akan ada bencana besar yang terjadi."
	},
	{
		"speaker": "Wizandy",
		"portrait": "wizandy",
		"text": "7 hari ke depan, akan terjadi seven deadly day. Hari kebangkitan 7 bangsa iblis secara berurutan melalui 7 tempat berbeda. Aku tidak tahu rupa iblis yang akan datang dan seperti apa mereka."
	},
	{
		"speaker": "Wizashley",
		"portrait": "wizashley",
		"text": "Hanya saja, aku mengetahui 7 bangsa ini dari ingatan leluhur kami:\n- Superbia (Pride) - Sombong\n- Avarizia (Greed) - Serakah\n- Lussuria (Lust) - Nafsu"
	},
	{
		"speaker": "Wizashley",
		"portrait": "wizashley",
		"text": "Dan bangsa iblis berikutnya:\n- Invidia (Envy) - Iri\n- Gola (Gluttony) - Rakus\n- Ira (Wrath) - Marah\n- Accidia (Sloth) - Malas"
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Beberapa dari mereka bersatu, beberapa dari mereka saling melahap satu sama lain. Pada intinya, jika kita tidak bertindak cepat, bumi ini akan menjadi sarang mereka berkembang biak."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Aku sudah menyimpulkan apa yang akan kita lakukan. Besok pagi kita akan melakukan pelatihan ketat, sekarang semuanya beristirahat dan tunggu perintah dariku untuk esok pagi."
	}
]

# =========================================================
# NASKAH DIALOG KAMAR KNIGHT (CHAPTER 1.2 / CH1-SC06)
# Sesuai Storyboard FLK-006
# =========================================================
const CH1_KNIGHT_ROOM_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Aku harus segera pergi berlatih, \"pelatih\" pasti sudah menungguku di sana."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Huft, semoga semua ini berjalan seperti semestinya."
	}
]

# =========================================================
# NASKAH DIALOG CAMP LATIHAN SEBELUM DUEL (CHAPTER 1.2)
# Sesuai Storyboard FLK-007
# =========================================================
const CH1_CAMP_TRAINING_PRE_FIGHT_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Alaric, aku cukup siap untuk ini. Aku akan melawanmu, kan?"
	},
	{
		"speaker": "Pelatih Alaric",
		"portrait": "alaric",
		"text": "Iya Yang Mulia, setidaknya cukup bertahan saja dariku ha-ha-ha."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Sedari dulu kau memang kesatria yang arogan, ayo kita lihat siapa yang lebih kuat!"
	}
]

# =========================================================
# NASKAH DIALOG PASCA LATIHAN & PETUNJUK PEMAKAMAN (CHAPTER 1.2)
# Sesuai Storyboard FLK-008
# =========================================================
const CH1_CAMP_TRAINING_POST_FIGHT_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Pelatih Alaric",
		"portrait": "alaric",
		"text": "Kau memang cukup tangguh Yang Mulia, sayangnya aku cukup lihai untuk melawanmu haha."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Astaga, kurasa kita cukup imbang..."
	},
	{
		"speaker": "Pelatih Alaric",
		"portrait": "alaric",
		"text": "Menurut saya, kau sudah cukup tangguh untuk perjalanan ini."
	},
	{
		"speaker": "Pelatih Alaric",
		"portrait": "alaric",
		"text": "Pergi ke daerah pemakaman, di situ terdapat makam prajurit terhebat yang pernah kulatih dahulu, Lancelot. Terdapat pedang yang pernah ditempa oleh penempa legendaris di sana."
	},
	{
		"speaker": "Pelatih Alaric",
		"portrait": "alaric",
		"text": "Gali saja makam itu dan ambil pedangnya, dia sudah mewariskan padaku sejak masa kritisnya, hanya saja aku menunggu saat yang tepat."
	}
]

# =========================================================
# NASKAH DIALOG MENEMUKAN PEDANG DI PEMAKAMAN (CHAPTER 1.2)
# Sesuai Storyboard FLK-009
# =========================================================
const CH1_GRAVEYARD_SWORD_FOUND_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Pedang ini terasa sangat kokoh. Hanya saja mungkin sedikit termakan oleh umur..."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Aku akan pergi untuk memperbaikinya."
	}
]

# =========================================================
# NASKAH DIALOG PERMINTAAN MAGNUS DI FORGE (CHAPTER 1.2)
# Sesuai Storyboard FLK-011
# =========================================================
const CH1_FORGE_MAGNUS_REQUEST_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Arthur, bisa bantu aku sebentar?"
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Memangnya ada apa sampai kamu perlu bantuanku?"
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Ibuku pernah bercerita kalau ada artefak kuno dari keturunan darah keluargaku."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Artefak itu sengaja disegel dan hanya boleh digunakan ketika ada hal genting seperti kondisi kita sekarang."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Katanya sih ada di dalam perpustakaan, dan ada ruang rahasia di sana."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Dengan senang hati! Lagipula kamu yang akan melindungiku dengan sihir-sihir kuatmu itu."
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Dasar..., baiklah ikuti aku."
	}
]

# =========================================================
# NASKAH DIALOG MEMASUKI PERPUSTAKAAN (CHAPTER 1.2)
# Sesuai Storyboard FLK-012
# =========================================================
# =========================================================
# NASKAH DIALOG SCENE 4: PERPUSTAKAAN ISTANA & MANTRA TERSEGEL
# =========================================================
const CH1_SCENE_04A_LIBRARY_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Arthur",
		"portrait": "arthur",
		"text": "Magnus, lihat sekelilingmu... penuh dengan buku ya!"
	},
	{
		"speaker": "Magnus",
		"portrait": "magnus",
		"text": "Ya karena ini perpustakaan, Arthur..."
	},
	{
		"speaker": "Anastasya",
		"portrait": "anastasya",
		"text": "Tempat ini luas sekali. Di mana peninggalan ibumu itu disimpan, Tuan Magnus?"
	},
	{
		"speaker": "Magnus",
		"portrait": "magnus",
		"text": "Lihat deretan rak di tengah itu. Ada susunan buku kuno yang tidak beraturan. Buku-buku itu membentuk suatu kode sandi mantra keluarga kami."
	}
]

const CH1_SCENE_04B_GOLDEN_BOOK_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Magnus",
		"portrait": "magnus",
		"text": "Buku ini... langsung menyatu ke ingatanku. Sekarang aku menguasai sihir serang area berskala besar."
	},
	{
		"speaker": "Arthur",
		"portrait": "arthur",
		"text": "Mantap. Sekarang kita punya senjata sihir cadangan."
	}
]

const CH1_SCENE_04C_ALARM_BELL_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Anastasya",
		"portrait": "anastasya",
		"text": "Lonceng peringatan! Ada keributan di gerbang depan istana!"
	},
	{
		"speaker": "Arthur",
		"portrait": "arthur",
		"text": "Ayo cepat ke sana!"
	}
]

const CH1_LIBRARY_ENTER_DIALOGUE: Array[Dictionary] = CH1_SCENE_04A_LIBRARY_DIALOGUE

# =========================================================
# NASKAH DIALOG PUZZLE PERPUSTAKAAN BAWAH TANAH (CHAPTER 1.2)
# Sesuai Storyboard FLK-013
# =========================================================
const CH1_LIBRARY_PUZZLE_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Buku-buku ini merangkai suatu kata..."
	}
]

# =========================================================
# NASKAH DIALOG BOSS FIGHT PERPUSTAKAAN - ARCHON (CHAPTER 1.2)
# Sesuai Storyboard FLK-014 (Library)
# =========================================================
const CH1_LIBRARY_BOSS_PRE_FIGHT_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Archon - The Mindfulness",
		"portrait": "archon",
		"text": "Berani-beraninya kalian menapakkan kaki di sini. Pergi sebelum aku mengubah kalian menjadi salah satu dari buku yang tersusun di rak-rak itu!"
	},
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Sebentar! Kami hanya ingin mencari artefak yang tersegel di tempat ini, bukankah itu diperbolehkan!?"
	},
	{
		"speaker": "Archon - The Mindfulness",
		"portrait": "archon",
		"text": "Kalian diperbolehkan jika berhasil mengalahkanku. Aku akan menguji kepantasan kalian untuk artefak itu!"
	}
]

# =========================================================
# NASKAH DIALOG KLAIM BUKU EMAS ARTEFAK (CHAPTER 1.3)
# Sesuai Storyboard FLK-015 (Buku Emas)
# =========================================================
const CH1_LIBRARY_GOLDEN_BOOK_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Pensatore Magnus",
		"portrait": "magnus",
		"text": "Buku ini bercahaya saat kusentuh..."
	}
]

# =========================================================
# NASKAH DIALOG SERBUAN GERBANG ISTANA (CHAPTER 1.2 CLEAR / CH1-SC07)
# Sesuai Storyboard FLK-017 (Gerbang)
# =========================================================
const CH1_GATE_INVASION_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "SERANGG!!!"
	}
]

# =========================================================
# NASKAH DIALOG KEMUNCULAN ASSASSIN (CHAPTER 1.3 / CH1-SC08)
# Sesuai Storyboard FLK-014 (Assassin)
# =========================================================
const CH1_ASSASSIN_APPEARANCE_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Carina Hellene",
		"portrait": "assassin",
		"text": "Akan kujelaskan nanti setelah mengalahkan raksasa ini bersama!"
	}
]

# =========================================================
# NASKAH DIALOG LEPAS TOPENG ASSASSIN & ALIANSI (CHAPTER 1.3 CLEAR / CH1-SC11)
# Sesuai Storyboard FLK-017 (Aliansi Assassin)
# =========================================================
const CH1_ASSASSIN_UNMASK_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "Carina Hellene",
		"portrait": "assassin",
		"text": "Aku adalah assassin dari kerajaan seberang. Aku bisa sampai ke sini karena menyamar saat aku dan pengawalku sedang berada di hutan."
	},
	{
		"speaker": "Carina Hellene",
		"portrait": "assassin",
		"text": "Pengawalku habis pada malam itu. Aku berhasil membunuh satu dari mereka dan menggunakan sebagian dari tubuhnya sebagai penyamaran ini."
	},
	{
		"speaker": "Carina Hellene",
		"portrait": "assassin",
		"text": "Saat ini aku yakin, tidak hanya kastilmu yang diserang, kastilku sedang dalam bahaya, esok hari akan ada iblis yang menyerang kastilku."
	},
	{
		"speaker": "Carina Hellene",
		"portrait": "assassin",
		"text": "Tolong bantu aku menyelesaikan masalah ini, kita perlu bersatu untuk menyelamatkan kehidupan manusia."
	},
	{
		"speaker": "Forzato Arthur",
		"portrait": "arthur",
		"text": "Aku tidak akan ikut denganmu, kau yang akan ikut dengan kita. Tunjukkan aku jalannya!"
	}
]

# =========================================================
# REGISTRI KAMUS DIALOG STORYBOARD LENGKAP (FLK-001 s/d FLK-017)
# =========================================================
const STORY_DIALOGUES: Dictionary = {
	"FLK-001": PROLOGUE_DIALOGUE,
	"FLK-002": PROLOGUE_DIALOGUE,
	"FLK-002-B": PROLOGUE_POST_FIGHT_DIALOGUE,
	"prologue_post_fight": PROLOGUE_POST_FIGHT_DIALOGUE,
	"CH0-SC02": PROLOGUE_DIALOGUE,
	"prologue_intro": PROLOGUE_DIALOGUE,
	"prologue": PROLOGUE_DIALOGUE,

	"FLK-004": CASTLE_MEETING_DIALOGUE,
	"FLK-005": CASTLE_MEETING_DIALOGUE,
	"CH1-SC04": CASTLE_MEETING_DIALOGUE,
	"CH1-SC05": CASTLE_MEETING_DIALOGUE,
	"castle_meeting": CASTLE_MEETING_DIALOGUE,

	"FLK-006": CH1_KNIGHT_ROOM_DIALOGUE,
	"CH1-SC06": CH1_KNIGHT_ROOM_DIALOGUE,
	"ch1_knight_room": CH1_KNIGHT_ROOM_DIALOGUE,

	"FLK-007": CH1_CAMP_TRAINING_PRE_FIGHT_DIALOGUE,
	"ch1_camp_training_pre": CH1_CAMP_TRAINING_PRE_FIGHT_DIALOGUE,

	"FLK-008": CH1_CAMP_TRAINING_POST_FIGHT_DIALOGUE,
	"ch1_camp_training_post": CH1_CAMP_TRAINING_POST_FIGHT_DIALOGUE,

	"FLK-009": CH1_GRAVEYARD_SWORD_FOUND_DIALOGUE,
	"ch1_graveyard_sword": CH1_GRAVEYARD_SWORD_FOUND_DIALOGUE,

	"FLK-011": CH1_FORGE_MAGNUS_REQUEST_DIALOGUE,
	"ch1_forge_magnus": CH1_FORGE_MAGNUS_REQUEST_DIALOGUE,

	"FLK-012": CH1_SCENE_04A_LIBRARY_DIALOGUE,
	"ch1_library_enter": CH1_SCENE_04A_LIBRARY_DIALOGUE,
	"scene_04a": CH1_SCENE_04A_LIBRARY_DIALOGUE,

	"FLK-013": CH1_LIBRARY_PUZZLE_DIALOGUE,
	"ch1_library_puzzle": CH1_LIBRARY_PUZZLE_DIALOGUE,

	"FLK-014": CH1_LIBRARY_BOSS_PRE_FIGHT_DIALOGUE,
	"ch1_library_boss": CH1_LIBRARY_BOSS_PRE_FIGHT_DIALOGUE,

	"FLK-015": CH1_SCENE_04B_GOLDEN_BOOK_DIALOGUE,
	"ch1_library_golden_book": CH1_SCENE_04B_GOLDEN_BOOK_DIALOGUE,
	"scene_04b": CH1_SCENE_04B_GOLDEN_BOOK_DIALOGUE,
	"scene_04c": CH1_SCENE_04C_ALARM_BELL_DIALOGUE,

	"FLK-017_GATE": CH1_GATE_INVASION_DIALOGUE,
	"CH1-SC07": CH1_GATE_INVASION_DIALOGUE,
	"ch1_gate_invasion": CH1_GATE_INVASION_DIALOGUE,

	"FLK-014_ASSASSIN": CH1_ASSASSIN_APPEARANCE_DIALOGUE,
	"CH1-SC08": CH1_ASSASSIN_APPEARANCE_DIALOGUE,
	"ch1_assassin_appearance": CH1_ASSASSIN_APPEARANCE_DIALOGUE,

	"FLK-017": CH1_ASSASSIN_UNMASK_DIALOGUE,
	"FLK-017_ASSASSIN": CH1_ASSASSIN_UNMASK_DIALOGUE,
	"CH1-SC11": CH1_ASSASSIN_UNMASK_DIALOGUE,
	"ch1_assassin_unmask": CH1_ASSASSIN_UNMASK_DIALOGUE
}

var is_castle_meeting_completed: bool = false
var is_knight_room_completed: bool = false
var is_knight_room_cutscene_in_progress: bool = false
var is_alaric_sparring_in_progress: bool = false
var is_alaric_sparring_completed: bool = false
var alaric_node: CharacterBody2D = null
var _alaric_sprite_frames_cache: SpriteFrames = null
var _alaric_boss_prompt_layer: CanvasLayer = null
var _alaric_boss_modal_input_cb: Callable = Callable()


# State Tempur Party ala Guardian Tales
enum PartyCombatState { EXPLORING, COMBAT }
var current_combat_state: PartyCombatState = PartyCombatState.EXPLORING
var active_combat_targets: Array[Node2D] = []
var aggro_check_timer: float = 0.0
const AGGRO_CHECK_INTERVAL: float = 0.15
var combat_winddown_timer: float = 0.0
const COMBAT_WINDDOWN_DELAY: float = 0.4

# =========================================================
# SISTEM ARENA LAPANGAN HIJAU (GUARDIAN TALES STYLE)
# =========================================================
enum ArenaState { INACTIVE, COMBAT, CLEARED }
var arena_state: ArenaState = ArenaState.INACTIVE
var arena_bounds: Rect2 = Rect2(Vector2(3020.0, 4160.0), Vector2(1920.0, 1080.0))
var arena_trigger_bounds: Rect2 = Rect2(Vector2(3400.0, 4200.0), Vector2(1150.0, 1000.0))
var arena_center: Vector2 = Vector2(3980.0, 4700.0)
var arena_enemies: Array[CharacterBody2D] = []
var arena_barrier_body: StaticBody2D = null

var arena_zones: Array[Dictionary] = [
	{
		"id": 1,
		"name": "Arena_1_Courtyard",
		"center": Vector2(3980.0, 4700.0),
		"trigger_bounds": Rect2(Vector2(3400.0, 4200.0), Vector2(1150.0, 1000.0)),
		"bounds": Rect2(Vector2(3020.0, 4160.0), Vector2(1920.0, 1080.0)),
		"enemies": [] as Array[CharacterBody2D],
		"is_cleared": false,
		"respawn_timer": 0.0,
	},
	{
		"id": 2,
		"name": "Arena_2_Forest",
		"center": Vector2(6740.0, 5500.0),
		"trigger_bounds": Rect2(Vector2(6290.0, 5150.0), Vector2(900.0, 700.0)),
		"bounds": Rect2(Vector2(5780.0, 4960.0), Vector2(1920.0, 1080.0)),
		"enemies": [] as Array[CharacterBody2D],
		"is_cleared": false,
		"respawn_timer": 0.0,
	}
]
var active_arena_idx: int = -1
const CAMERA_ZOOM_EXPLORE: Vector2 = Vector2(0.8, 0.8)
const CAMERA_ZOOM_ARENA: Vector2 = Vector2(0.6, 0.6)
var target_camera_zoom: Vector2 = CAMERA_ZOOM_EXPLORE
var is_camera_locked_to_arena: bool = false
var arena_clear_delay_timer: float = 0.0
var arena_group_respawn_timer: float = 0.0
const ARENA_GROUP_RESPAWN_DELAY: float = 7.0
var is_party_fading_out: bool = false
var _party_fade_tweens: Array[Tween] = []
var is_transitioning: bool = false

# =========================================================
# SISTEM KEKALAHAN ARENA & PUTAR MUNDUR WAKTU (TIME REWIND)
# =========================================================
var defeat_canvas: CanvasLayer = null
var defeat_rect: ColorRect = null
var defeat_title_lbl: Label = null
var defeat_subtitle_lbl: Label = null
var defeat_prompt_lbl: Label = null
var is_arena_defeat_active: bool = false
var is_awaiting_defeat_rewind_input: bool = false
var defeat_anim_time: float = 0.0
var pre_arena_snapshot: Dictionary = {}
var last_pre_arena_leader_pos: Vector2 = Vector2.ZERO
const SFX_HERO_RESPAWN = preload("res://assets/audio/sfx/characters/universal/hero_respawn.wav")
const UI_FONT_BEHOLDEN = preload("res://assets/ui/fonts/beholden-bold.ttf")

# =========================================================
# ARENA LATIHAN SEMENTARA (TRAINING DUMMY GROUND)
# =========================================================
const TRAINING_ARENA_BOUNDS: Rect2 = Rect2(Vector2(2360.0, 1740.0), Vector2(520.0, 640.0))
const TRAINING_DUMMY_SPAWN_POS: Vector2 = Vector2(2680.0, 2050.0)
var is_in_training_arena: bool = false
var training_dummy_enemy: CharacterBody2D = null

# =========================
# AUDIO SFX (TACTICAL PARTY)
# =========================
const SFX_PARTY_SWITCH_LEADER = preload("res://assets/audio/sfx/party/party_switch_leader.wav")
var _is_party_initialized: bool = false

# Sistem Musik Latar (BGM) Gameplay - Dual-Deck Equal-Power Seamless Crossfade
const BGM_GAMEPLAY = preload("res://assets/audio/bgm/game.ogg")
var _bgm_player_a: AudioStreamPlayer = null
var _bgm_player_b: AudioStreamPlayer = null
var _active_bgm_player: AudioStreamPlayer = null
var _next_bgm_player: AudioStreamPlayer = null
var _bgm_tween: Tween = null
var _is_crossfading: bool = false
const BGM_CROSSFADE_DURATION: float = 2.5
const BGM_BASE_VOLUME_DB: float = -4.0 # Dikalibrasi seimbang saat volume UI 100%

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.bus = &"SFX"
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()


# ==========================================
# BGM AUTO-FADE NATURAL LOOPING SYSTEM
# ==========================================

func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, &"Master")


func _init_and_play_bgm(fade_in_at_start: bool = true) -> void:
	if not BGM_GAMEPLAY:
		return
	_ensure_music_bus()
	
	if not is_instance_valid(_bgm_player_a):
		_bgm_player_a = AudioStreamPlayer.new()
		_bgm_player_a.name = "BgmPlayerA"
		_bgm_player_a.stream = BGM_GAMEPLAY
		_bgm_player_a.bus = &"Music"
		_bgm_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_bgm_player_a)
	
	if not is_instance_valid(_bgm_player_b):
		_bgm_player_b = AudioStreamPlayer.new()
		_bgm_player_b.name = "BgmPlayerB"
		_bgm_player_b.stream = BGM_GAMEPLAY
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


func _stop_all_bgm() -> void:
	_is_crossfading = false
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if is_instance_valid(_bgm_player_a):
		_bgm_player_a.stop()
		_bgm_player_a.volume_db = -80.0
	if is_instance_valid(_bgm_player_b):
		_bgm_player_b.stop()
		_bgm_player_b.volume_db = -80.0

# Pengaturan Camera Shake
var shake_intensity: float = 0.0
var shake_decay: float = 35.0

# Indikator segitiga kecil di atas kepala leader yang sedang aktif
const HERO_INDICATOR_OFFSETS: Dictionary = {
	"Knight_1": Vector2(2.5, -49.0),
	"Player_Knight": Vector2(2.5, -49.0),
	"Bandit_1": Vector2(0.0, -39.0),
	"Player_Bandit": Vector2(0.0, -39.0),
	"Archer_1": Vector2(0.0, -64.0),
	"Player_Archer": Vector2(0.0, -64.0),
	"Mage_1": Vector2(0.0, -49.0),
	"Player_Mage": Vector2(0.0, -49.0)
}
const DEFAULT_INDICATOR_OFFSET: Vector2 = Vector2(0.0, -46.0)
const HERO_INDICATOR_TIP_OFFSET_Y: Dictionary = {
	"Knight_1": -49.0,
	"Bandit_1": -39.0,
	"Archer_1": -64.0,
	"Mage_1": -49.0
}
const DEFAULT_INDICATOR_TIP_OFFSET_Y: float = -46.0
var _active_leader_indicator: Node2D = null
var _active_indicator_bob_time: float = 0.0


func _ready() -> void:
	# 1. Daftarkan seluruh hero referensi dari scene ke all_heroes
	all_heroes.clear()
	var names: Array[String] = ["Knight_1", "Bandit_1", "Archer_1", "Mage_1"]
	for n in names:
		var node := get_node_or_null(n) as CharacterBody2D
		if node:
			all_heroes[n] = node

	# Inisialisasi susunan party berdasarkan mode permainan:
	if selected_game_mode == "open_world":
		# Mode Jelajah: Seluruh 4 anggota party langsung aktif bersama sejak awal
		# Urutan default: Knight_1 (Arthur), Bandit_1 (Hellene), Archer_1 (Anastasya), Mage_1 (Magnus)
		for n in names:
			if all_heroes.has(n):
				party_members.append(all_heroes[n])
		if party_members.is_empty():
			for child in get_children():
				if child.is_in_group("player") and child is CharacterBody2D:
					party_members.append(child)
	else:
		# Mode Cerita: Sesuai alur cerita FLK, awal game Arthur (Knight_1) bertualang secara SOLO.
		# Anggota party lain (Magnus, Assassin, Archer) baru bergabung bertahap sesuai cerita (recruit_hero).
		if all_heroes.has("Knight_1"):
			party_members.append(all_heroes["Knight_1"])
		else:
			# Fallback pencarian fleksibel jika node bernama Player_Knight dsb
			for child in get_children():
				if child.is_in_group("player") and child is CharacterBody2D:
					party_members.append(child)
					break

		if not is_prologue_completed and pending_load_slot_id <= 0:
			var lead_node: CharacterBody2D = all_heroes.get("Knight_1")
			if is_instance_valid(lead_node):
				lead_node.global_position = FOREST_CABIN_DOOR_POS
				lead_node.velocity = Vector2.ZERO
				if "last_direction" in lead_node:
					lead_node.last_direction = Vector2.DOWN
				if lead_node.has_method("play_idle_animation"):
					lead_node.play_idle_animation()
			if is_instance_valid(camera):
				camera.global_position = FOREST_CABIN_DOOR_POS
				camera.reset_smoothing()

	# Copot hero non-party dari SceneTree agar tidak berkeliaran atau menghalangi map saat ada anggota yang belum bergabung
	for h_name in all_heroes.keys():
		var h_node: CharacterBody2D = all_heroes[h_name]
		if is_instance_valid(h_node) and h_node not in party_members and h_node.is_inside_tree():
			remove_child(h_node)

	# 2. Nonaktifkan tabrakan fisik antar-seluruh anggota party
	for i in range(party_members.size()):
		for j in range(i + 1, party_members.size()):
			party_members[i].add_collision_exception_with(party_members[j])
			party_members[j].add_collision_exception_with(party_members[i])

	# 3. Nonaktifkan tabrakan fisik antara anggota party dan musuh agar tidak saling menyeret / mengunci
	setup_party_enemy_collision_exceptions.call_deferred()
	_init_active_leader_indicator()

	# 4. Tentukan karakter awal sebagai Leader (Knight_1 = index 0)
	set_active_leader(0)
	_is_party_initialized = true

	# Pastikan sisa rekan yang tidak aktif benar-benar dicopot dari SceneTree di mode eksplorasi
	for i in range(party_members.size()):
		if i != active_leader_index:
			var member = party_members[i]
			if is_instance_valid(member) and member.is_inside_tree():
				remove_child(member)

	# Inisialisasi item inventory & quest starter
	_init_starter_inventory()
	_init_starter_quests()

	# Hubungkan Gameplay HUD
	if gameplay_hud:
		gameplay_hud.setup(party_members, active_leader_index, inventory_items, quest_list)
		gameplay_hud.skill_activated.connect(_on_hud_skill_activated)
		gameplay_hud.leader_switch_requested.connect(_on_hud_leader_switch_requested)
		if gameplay_hud.has_signal("pause_menu_requested"):
			gameplay_hud.pause_menu_requested.connect(_on_hud_pause_menu_requested)
		if gameplay_hud.has_signal("party_reordered"):
			gameplay_hud.party_reordered.connect(_on_hud_party_reordered)
		if gameplay_hud.has_signal("item_used"):
			gameplay_hud.item_used.connect(_on_hud_item_used)
		if gameplay_hud.has_signal("quest_tracked"):
			gameplay_hud.quest_tracked.connect(_on_hud_quest_tracked)
		if gameplay_hud.has_signal("quest_navigation_requested"):
			gameplay_hud.quest_navigation_requested.connect(_on_hud_quest_navigation_requested)
		if gameplay_hud.has_signal("save_game_requested"):
			gameplay_hud.save_game_requested.connect(_on_hud_save_game_requested)
		if gameplay_hud.has_signal("load_game_requested"):
			gameplay_hud.load_game_requested.connect(_on_hud_load_game_requested)
		if gameplay_hud.has_signal("return_to_title_requested"):
			gameplay_hud.return_to_title_requested.connect(_on_hud_return_to_title_requested)
		if gameplay_hud.has_signal("dialogue_started"):
			gameplay_hud.dialogue_started.connect(_on_hud_dialogue_started)
		if gameplay_hud.has_signal("dialogue_finished"):
			gameplay_hud.dialogue_finished.connect(_on_hud_dialogue_finished)
		if gameplay_hud.has_signal("interaction_pressed"):
			gameplay_hud.interaction_pressed.connect(_on_hud_interaction_pressed)

		# Sembunyikan elemen HUD pertarungan (Party & Skill) saat eksplorasi di luar arena
		if gameplay_hud.has_method("set_combat_hud_visible"):
			gameplay_hud.set_combat_hud_visible(false, false)

		if selected_game_mode == "open_world":
			if gameplay_hud.has_method("set_open_world_mode"):
				gameplay_hud.set_open_world_mode(true)
			if gameplay_hud.has_method("hide_quest_navigation"):
				gameplay_hud.hide_quest_navigation()
			tracked_quest_id = ""
			var marker = get_node_or_null("CastleObjectiveMarker")
			if marker:
				marker.visible = false
		else:
			# Sinkronisasi quest aktif pertama ke overlay HUD
			var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
			if not tracked_q.is_empty():
				gameplay_hud.update_hud_quest_display(tracked_q)

			if tracked_quest_id == "main_02" and not is_inside_castle_hall:
				if gameplay_hud.has_method("set_quest_navigation"):
					gameplay_hud.set_quest_navigation(CASTLE_ENTRANCE_POS, "Aula Kastil")
				var marker = get_node_or_null("CastleObjectiveMarker")
				if marker:
					marker.visible = true
			elif tracked_quest_id == "main_03" and not is_inside_castle_hall:
				if gameplay_hud.has_method("set_quest_navigation"):
					gameplay_hud.set_quest_navigation(ALARIC_CAMP_POS, "Camp Latihan Istana")
			elif tracked_quest_id == "main_04" and not is_inside_castle_hall:
				if gameplay_hud.has_method("set_quest_navigation"):
					gameplay_hud.set_quest_navigation(GRAVEYARD_POS, "Makam Ksatria Lancelot")

	# 5. Inisialisasi kamera dan batasan map
	update_arena_bounds_from_camera()
	setup_camera_and_boundaries.call_deferred()
	_init_arena_barrier.call_deferred()
	_init_arena_enemies.call_deferred()
	_init_nav_compass.call_deferred()
	_setup_meeting_participants.call_deferred()
	_setup_alaric_npc.call_deferred()
	_init_defeat_overlay.call_deferred()

	# 6. Jalankan efek pembukaan Circular Mask (Iris Open) saat masuk arena game
	_init_and_play_bgm()

	# Jika masuk melalui menu 'Lanjutkan' di Start Menu, muat save slot tertunda
	if pending_load_slot_id > 0:
		play_iris_opening_transition()
		var slot_to_load := pending_load_slot_id
		pending_load_slot_id = -1
		call_deferred("load_game_from_slot", slot_to_load)
	elif selected_game_mode == "open_world":
		play_iris_opening_transition()
		_setup_open_world_mode.call_deferred()
	elif not is_prologue_completed:
		# Mode Cerita baru: tampilkan narasi abad ke-7 di layar hitam sebelum masuk gameplay
		_show_story_prologue_intro_crawl(func():
			play_iris_opening_transition()
			_start_story_prologue_sequence.call_deferred()
		)
	else:
		play_iris_opening_transition()
		_start_story_prologue_sequence.call_deferred()


func setup_party_enemy_collision_exceptions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for p in party_members:
		if is_instance_valid(p) and p.is_inside_tree() and p is CollisionObject2D:
			for e in enemies:
				if is_instance_valid(e) and e is CollisionObject2D:
					p.add_collision_exception_with(e)
					e.add_collision_exception_with(p)


func _input(event: InputEvent) -> void:
	# Intersepsi input saat seluruh party gugur di arena (layar merah defeat)
	# Seluruh tombol keyboard, klik mouse, controller, dan sentuhan otomatis
	# menekan layar kematian (memicu rewind waktu) dan tidak tembus ke UI manapun.
	if is_arena_defeat_active:
		if is_awaiting_defeat_rewind_input:
			var is_trigger: bool = false
			if event is InputEventKey and event.pressed and not event.echo:
				is_trigger = true
			elif event is InputEventMouseButton and event.pressed:
				is_trigger = true
			elif event is InputEventJoypadButton and event.pressed:
				is_trigger = true
			elif event is InputEventScreenTouch and event.pressed:
				is_trigger = true

			if is_trigger:
				is_awaiting_defeat_rewind_input = false
				execute_arena_rewind()
				get_viewport().set_input_as_handled()
				return

		# Selama layar defeat aktif, telan seluruh input agar tombol UI / kontrol lain tidak terpencet
		if (event is InputEventKey) or (event is InputEventMouseButton) or (event is InputEventJoypadButton) or (event is InputEventScreenTouch):
			get_viewport().set_input_as_handled()
		return


func _unhandled_input(event: InputEvent) -> void:
	# Pengaman input saat seluruh party gugur di arena (layar merah defeat)
	if is_arena_defeat_active:
		get_viewport().set_input_as_handled()
		return

	# Tangani navigasi input keyboard ketika popup konfirmasi Boss Alaric sedang aktif
	if is_instance_valid(_alaric_boss_prompt_layer):
		if _alaric_boss_modal_input_cb.is_valid() and _alaric_boss_modal_input_cb.call(event):
			get_viewport().set_input_as_handled()
		return

	if is_transitioning:
		return
	# Tombol pintasan pergantian karakter di arena combat (1, 2, 3, 4) dan pause (ESC)
	if event is InputEventKey and event.pressed and not event.echo:
		var key_code: int = event.keycode
		if key_code == 0:
			key_code = event.physical_keycode

		# Menu Pause (ESC) harus selalu dapat diakses di mana pun, termasuk saat pertarungan / arena combat
		if key_code == KEY_ESCAPE:
			if gameplay_hud:
				_on_hud_pause_menu_requested()
				gameplay_hud.toggle_pause_menu()
				if get_viewport():
					get_viewport().set_input_as_handled()
				return

		# Shortcut debug testing: F7 untuk langsung menguji Cutscene Scene 4 (Perpustakaan)
		if key_code == KEY_F7:
			enter_secret_library()
			if get_viewport():
				get_viewport().set_input_as_handled()
			return

		if (arena_state == ArenaState.COMBAT or is_in_training_arena or is_in_arena_kamp or is_alaric_sparring_in_progress) and not is_party_fading_out:
			if key_code == KEY_1 or (InputMap.has_action("skill_1") and event.is_action_pressed("skill_1")):
				switch_to_character(0)
				get_viewport().set_input_as_handled()
				return
			elif key_code == KEY_2 or (InputMap.has_action("skill_2") and event.is_action_pressed("skill_2")):
				switch_to_character(1)
				get_viewport().set_input_as_handled()
				return
			elif key_code == KEY_3 or (InputMap.has_action("skill_3") and event.is_action_pressed("skill_3")):
				switch_to_character(2)
				get_viewport().set_input_as_handled()
				return
			elif key_code == KEY_4 or (InputMap.has_action("skill_4") and event.is_action_pressed("skill_4")):
				switch_to_character(3)
				get_viewport().set_input_as_handled()
				return
			elif key_code == KEY_Q:
				# Pergantian karakter di arena combat kini menggunakan tombol 1, 2, 3, 4 bukan Q
				get_viewport().set_input_as_handled()
				return
		elif key_code == KEY_E or (InputMap.has_action("interact") and event.is_action_pressed("interact")):
			if not is_transitioning:
				if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("is_dialogue_active") and gameplay_hud.is_dialogue_active():
					return
				if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("is_any_menu_open") and gameplay_hud.is_any_menu_open():
					return
				if is_instance_valid(_alaric_boss_prompt_layer):
					return
				var leader = get_active_leader()
				if leader:
					if not is_inside_castle_hall and not is_in_arena_kamp and not is_inside_secret_library:
						if leader.global_position.distance_to(CASTLE_ENTRANCE_POS) <= 120.0:
							enter_castle_hall()
							get_viewport().set_input_as_handled()
						elif leader.global_position.distance_to(ALARIC_CAMP_POS) <= 120.0 and not is_alaric_sparring_in_progress:
							_start_alaric_pre_fight_dialogue()
							get_viewport().set_input_as_handled()
						elif _is_near_library_entrance(leader.global_position):
							enter_secret_library()
							get_viewport().set_input_as_handled()
					elif is_inside_secret_library:
						if not is_on_library_floor_2:
							if leader.global_position.distance_to(SECRET_LIBRARY_STAIR_POS) <= 120.0:
								_go_to_library_floor_2()
								get_viewport().set_input_as_handled()
							elif leader.global_position.distance_to(SECRET_LIBRARY_EXIT_L1_POS) <= 120.0:
								exit_secret_library()
								get_viewport().set_input_as_handled()
					elif is_inside_castle_hall:
						if leader.global_position.distance_to(CASTLE_HALL_EXIT_POS) <= 100.0:
							exit_castle_hall()
							get_viewport().set_input_as_handled()
						elif not is_castle_meeting_completed and not is_meeting_in_progress:
							if leader.global_position.distance_to(CASTLE_MEETING_SEAT_GLOBAL_POS) <= 100.0:
								start_castle_meeting_cutscene()
								get_viewport().set_input_as_handled()


func is_character_alive(character: CharacterBody2D) -> bool:
	if not character or not is_instance_valid(character):
		return false
	if "is_dead" in character and character.is_dead:
		return false
	if "current_health" in character and character.current_health <= 0:
		return false
	return true


func switch_to_next_character(force: bool = false) -> void:
	if not force and arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress:
		return
	if party_members.is_empty():
		return

	var count := party_members.size()
	# Cari karakter hidup berikutnya secara siklis mulai dari anggota berikutnya
	for step in range(1, count):
		var target_idx := (active_leader_index + step) % count
		var candidate := party_members[target_idx]
		if is_character_alive(candidate):
			switch_to_character(target_idx, force)
			return

	print("Tidak ada anggota party lain yang masih hidup untuk dipilih.")
	if _active_leader_indicator and is_instance_valid(_active_leader_indicator):
		_active_leader_indicator.visible = false


func switch_to_character(idx: int, force: bool = false) -> void:
	if not force and arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress:
		return
	if idx < 0 or idx >= party_members.size() or idx == active_leader_index:
		return

	var target := party_members[idx]
	if not is_character_alive(target):
		print("Karakter [", idx + 1, "] sedang gugur. Pergantian Leader dibatalkan.")
		return

	set_active_leader(idx)


func rearrange_dead_members_to_back() -> void:
	if party_members.is_empty():
		return

	var alive_members: Array[CharacterBody2D] = []
	var dead_members: Array[CharacterBody2D] = []

	for member in party_members:
		if is_instance_valid(member):
			if is_character_alive(member):
				alive_members.append(member)
			else:
				dead_members.append(member)

	# Jika tidak ada yang gugur, atau seluruh anggota gugur, tidak ada reorganisasi
	if dead_members.is_empty() or alive_members.is_empty():
		return

	var old_active_leader: CharacterBody2D = get_active_leader()

	# Bentuk formasi roster baru: hero yang hidup maju ke depan, hero gugur mundur ke paling belakang
	var new_party: Array[CharacterBody2D] = []
	new_party.append_array(alive_members)
	new_party.append_array(dead_members)

	party_members = new_party

	# Sinkronkan ke HUD (kartu gameplay dan pause menu)
	if gameplay_hud:
		if gameplay_hud.has_method("update_party_order"):
			gameplay_hud.update_party_order(party_members, 0)
		else:
			gameplay_hud.party_members = party_members
			gameplay_hud.active_leader_index = 0
			gameplay_hud.update_party_hud()
			gameplay_hud.update_leader_indicator()

	# Karakter hidup terdepan (Slot 0) otomatis maju menjadi Leader baru
	set_active_leader(0, old_active_leader)
	print("Party Roster Reordered: Hero gugur mundur ke belakang, Leader baru: [1] ", party_members[0].name)


func recruit_hero(hero_id_or_name: String) -> bool:
	var target_hero: CharacterBody2D = null
	if all_heroes.has(hero_id_or_name):
		target_hero = all_heroes[hero_id_or_name]
	else:
		for h_name in all_heroes.keys():
			if hero_id_or_name.to_lower() in h_name.to_lower():
				target_hero = all_heroes[h_name]
				break

	if not is_instance_valid(target_hero) or target_hero in party_members:
		return false

	party_members.append(target_hero)

	# Nonaktifkan tabrakan fisik antar sesama anggota party
	for m in party_members:
		if m != target_hero and is_instance_valid(m):
			m.add_collision_exception_with(target_hero)
			target_hero.add_collision_exception_with(m)

	setup_party_enemy_collision_exceptions.call_deferred()

	if gameplay_hud:
		if gameplay_hud.has_method("update_party_order"):
			gameplay_hud.update_party_order(party_members, active_leader_index)
		else:
			gameplay_hud.party_members = party_members
			gameplay_hud.update_party_hud()
			gameplay_hud.update_leader_indicator()

	print("Hero direkrut ke party: ", target_hero.name, " | Ukuran party sekarang: ", party_members.size())
	return true


func set_active_leader(idx: int, prev_leader_override: CharacterBody2D = null) -> void:
	if idx < 0 or idx >= party_members.size():
		return

	var prev_leader: CharacterBody2D = prev_leader_override
	if not prev_leader and active_leader_index >= 0 and active_leader_index < party_members.size():
		prev_leader = party_members[active_leader_index]

	# Fallback eksplorasi: jika prev_leader tidak valid atau sama dengan target,
	# cari karakter lain yang saat ini masih aktif berada di dalam SceneTree
	if _is_party_initialized and arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress:
		var target_candidate := party_members[idx]
		if not prev_leader or prev_leader == target_candidate or not prev_leader.is_inside_tree():
			for member in party_members:
				if is_instance_valid(member) and member != target_candidate and member.is_inside_tree():
					prev_leader = member
					break

	active_leader_index = idx
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return
	leader.visible = true
	leader.modulate = Color.WHITE

	# Jika berganti karakter saat eksplorasi 1 karakter, posisikan karakter baru tepat di posisi karakter sebelumnya
	if arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress:
		if prev_leader and is_instance_valid(prev_leader) and prev_leader != leader:
			var prev_pos: Vector2 = prev_leader.global_position
			var prev_last_dir: Vector2 = prev_leader.last_direction if "last_direction" in prev_leader else Vector2.DOWN
			var prev_mov_dir: Vector2 = prev_leader.last_movement_direction if "last_movement_direction" in prev_leader else Vector2.DOWN

			if prev_leader.is_inside_tree() and not ("is_dead" in prev_leader and prev_leader.is_dead):
				remove_child(prev_leader)
			if not leader.is_inside_tree():
				add_child(leader)
			leader.global_position = prev_pos
			if "target_position" in leader:
				leader.target_position = prev_pos
			if "velocity" in leader:
				leader.velocity = Vector2.ZERO
			if "last_direction" in leader:
				leader.last_direction = prev_last_dir
			if "last_movement_direction" in leader:
				leader.last_movement_direction = prev_mov_dir
		elif not leader.is_inside_tree():
			add_child(leader)
		if camera:
			camera.global_position = leader.global_position
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

	# Berikan status Leader langsung ke karakter terpilih
	breadcrumbs.clear()
	if leader.has_method("set_as_leader"):
		leader.set_as_leader(true, null, 0)

	# Berikan referensi langsung ke Leader dan nomor urutan slot tetap (1, 2, 3)
	var slot_order: int = 1
	for step in range(1, party_members.size()):
		var follower_idx := (active_leader_index + step) % party_members.size()
		var follower := party_members[follower_idx]
		if is_instance_valid(follower):
			if follower.has_method("set_as_leader"):
				follower.set_as_leader(false, leader, slot_order)
			if arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress and follower.is_inside_tree() and not ("is_dead" in follower and follower.is_dead):
				remove_child(follower)
		slot_order += 1

	update_party_visibility()

	# Sinkronkan state combat jika pergantian karakter terjadi saat bertempur
	if current_combat_state == PartyCombatState.COMBAT:
		notify_party_combat_state(true)
	else:
		notify_party_combat_state(false)

	if _is_party_initialized:
		play_sfx(SFX_PARTY_SWITCH_LEADER, -2.0)

	if gameplay_hud:
		gameplay_hud.set_active_leader(idx)

	_update_active_leader_indicator(0.0)
	print("Party Switch -> Leader aktif: [", active_leader_index + 1, "] ", leader.name)


func _set_character_collision_active(char_node: CharacterBody2D, active: bool) -> void:
	if not char_node or not is_instance_valid(char_node) or not char_node.is_inside_tree():
		return
	var should_disable: bool = not active
	if char_node.has_node("CollisionShape2D"):
		var col = char_node.get_node("CollisionShape2D") as CollisionShape2D
		if col and col.disabled != should_disable:
			col.set_deferred("disabled", should_disable)
	if char_node.has_node("Hurtbox/CollisionShape2D"):
		var hurt_col = char_node.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D
		if hurt_col and hurt_col.disabled != should_disable:
			hurt_col.set_deferred("disabled", should_disable)


func update_party_visibility() -> void:
	var in_arena_combat: bool = (arena_state == ArenaState.COMBAT or is_in_training_arena or is_in_arena_kamp or is_alaric_sparring_in_progress)
	var show_all_library_cutscene: bool = (is_scene_4_in_progress and is_on_library_floor_2)
	for i in range(party_members.size()):
		var member = party_members[i]
		if not is_instance_valid(member):
			continue

		var is_dead_char: bool = ("is_dead" in member and member.is_dead) or ("current_health" in member and member.current_health <= 0)
		var is_active: bool = false
		if not is_dead_char:
			if i == active_leader_index:
				is_active = true
			elif in_arena_combat or show_all_library_cutscene:
				is_active = true

		if is_active:
			if not member.is_inside_tree():
				add_child(member)
			if member.process_mode != Node.PROCESS_MODE_INHERIT:
				member.process_mode = Node.PROCESS_MODE_INHERIT
			if not member.visible:
				member.visible = true
			if not is_party_fading_out or i == active_leader_index:
				member.modulate = Color.WHITE
				if not member.is_physics_processing() and not is_transitioning:
					member.set_physics_process(true)
				if not member.is_processing() and not is_transitioning:
					member.set_process(true)
			var should_input: bool = (i == active_leader_index) and not is_transitioning
			if member.is_processing_unhandled_input() != should_input:
				member.set_process_unhandled_input(should_input)
			if not is_party_fading_out or i == active_leader_index:
				_set_character_collision_active(member, true)
		elif is_dead_char and member.is_inside_tree():
			# Karakter yang gugur tetap berada di tree agar efek memudar dan timer respawn berjalan lancar.
			# Nonaktifkan physics, processing, input, dan collision tanpa me-remove node dari tree.
			member.visible = false
			member.modulate.a = 0.0
			if member.is_physics_processing():
				member.set_physics_process(false)
			if member.is_processing():
				member.set_process(false)
			if member.is_processing_unhandled_input():
				member.set_process_unhandled_input(false)
			if member.velocity != Vector2.ZERO:
				member.velocity = Vector2.ZERO
			_set_character_collision_active(member, false)
		else:
			if member.is_inside_tree():
				remove_child(member)
			member.visible = false
			if member.is_physics_processing():
				member.set_physics_process(false)
			if member.is_processing():
				member.set_process(false)
			if member.is_processing_unhandled_input():
				member.set_process_unhandled_input(false)
			if member.velocity != Vector2.ZERO:
				member.velocity = Vector2.ZERO


func trigger_hero_skill_by_slot(slot_idx: int) -> void:
	if arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress and current_combat_state != PartyCombatState.COMBAT:
		var has_nearby_enemy: bool = false
		var leader := get_active_leader()
		if is_instance_valid(leader):
			for e in get_tree().get_nodes_in_group("enemy"):
				if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
					if "wait_for_arena" in e and e.wait_for_arena:
						continue
					if leader.global_position.distance_to(e.global_position) <= 650.0:
						has_nearby_enemy = true
						break
		if not has_nearby_enemy:
			return
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	# Saat mode eksplorasi 1 karakter, tombol 1-4 tidak digunakan untuk memilih / beralih karakter
	if slot_idx != active_leader_index:
		return
	var target_hero := party_members[slot_idx]
	if not is_instance_valid(target_hero) or not is_character_alive(target_hero):
		return

	# Eksekusi skill jika slot yang ditekan adalah Leader aktif
	execute_hero_skill(target_hero)


func execute_hero_skill(hero: CharacterBody2D) -> void:
	if arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_in_arena_kamp and not is_alaric_sparring_in_progress and current_combat_state != PartyCombatState.COMBAT:
		var has_nearby_enemy: bool = false
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
				if "wait_for_arena" in e and e.wait_for_arena:
					continue
				if hero.global_position.distance_to(e.global_position) <= 650.0:
					has_nearby_enemy = true
					break
		if not has_nearby_enemy:
			return
	if not is_instance_valid(hero) or not is_character_alive(hero):
		return

	if hero.has_method("activate_shield"):
		hero.activate_shield()
	elif hero.has_method("activate_triple_slash"):
		var cd: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
		var is_att: bool = hero.get("is_attacking") if "is_attacking" in hero else false
		var is_sk: bool = hero.get("is_skill_active") if "is_skill_active" in hero else false
		var is_lunge: bool = hero.get("is_ambush_lunging") if "is_ambush_lunging" in hero else false
		if cd <= 0.0 and not is_att and not is_sk and not is_lunge:
			hero.activate_triple_slash()
	elif hero.has_method("activate_skill_mode"):
		if hero.has_method("can_activate_skill") and hero.can_activate_skill():
			hero.activate_skill_mode()
	elif hero.has_method("start_skill_aiming"):
		if hero.has_method("can_activate_skill"):
			if hero.can_activate_skill():
				hero.start_skill_aiming()
		else:
			var cd_m: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
			var is_aim: bool = hero.get("is_aiming_skill") if "is_aiming_skill" in hero else false
			var is_rel: bool = hero.get("is_skill_releasing") if "is_skill_releasing" in hero else false
			if not is_aim and not is_rel and cd_m <= 0.0:
				hero.start_skill_aiming()


func _on_hud_skill_activated(slot_idx: int) -> void:
	trigger_hero_skill_by_slot(slot_idx)


func _on_hud_leader_switch_requested(hero_idx: int) -> void:
	if hero_idx >= 0 and hero_idx < party_members.size() and is_character_alive(party_members[hero_idx]):
		switch_to_character(hero_idx)


func _on_hud_pause_menu_requested() -> void:
	if is_camera_locked_to_arena and arena_state == ArenaState.COMBAT:
		if is_instance_valid(camera):
			camera.global_position = arena_center
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()
		return

	var leader := get_active_leader()
	if is_instance_valid(leader) and is_instance_valid(camera):
		camera.global_position = leader.global_position
		if camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if camera.has_method("force_update_scroll"):
			camera.force_update_scroll()


func _on_hud_party_reordered(new_party: Array[CharacterBody2D]) -> void:
	if new_party.is_empty():
		return

	# Dapatkan leader lama yang saat ini sedang aktif dimainkan sebelum array party diperbarui
	var old_leader: CharacterBody2D = get_active_leader()
	if not old_leader or not old_leader.is_inside_tree():
		for member in party_members:
			if is_instance_valid(member) and member.is_inside_tree():
				old_leader = member
				break

	party_members = new_party
	# Karakter di slot pertama otomatis menjadi leader
	set_active_leader(0, old_leader)
	update_camera_target(0.0)


func _init_starter_inventory() -> void:
	inventory_items = [
		{
			"id": "apple",
			"name": "Apel Merah Hutan",
			"category": 0,
			"icon_path": "res://assets/ui/icons/items/items_sheets.png",
			"icon_rect": Rect2(48, 560, 16, 16),
			"description": "Buah apel merah manis dan segar dari perkebunan, memulihkan 150 HP karakter.",
			"quantity": 2,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 150
		},
		{
			"id": "bread",
			"name": "Roti Gandum",
			"category": 0,
			"icon_path": "res://assets/ui/icons/items/items_sheets.png",
			"icon_rect": Rect2(192, 528, 16, 16),
			"description": "Roti gandum berkah yang dapat membangkitkan (revive) anggota party yang gugur serta memulihkan 200 HP.",
			"quantity": 2,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 200,
			"is_revive": true
		}
	]


func _on_hud_item_used(item_data: Dictionary) -> void:
	var target_idx: int = int(item_data.get("target_index", active_leader_index))
	if target_idx < 0 or target_idx >= party_members.size():
		return
	var target_hero = party_members[target_idx]
	if not is_instance_valid(target_hero) or not ("current_health" in target_hero and "max_health" in target_hero):
		return

	var is_revive_item: bool = item_data.get("is_revive", false) or item_data.get("id") == "bread"
	var is_dead_char: bool = target_hero.get("is_dead") if "is_dead" in target_hero else false
	if "current_health" in target_hero and target_hero.current_health <= 0:
		is_dead_char = true

	var heal_val: int = item_data.get("heal_amount", 150)

	if is_dead_char:
		if is_revive_item:
			if target_hero.has_method("respawn"):
				target_hero.respawn()
				target_hero.current_health = mini(target_hero.max_health, heal_val)
			else:
				target_hero.is_dead = false
				target_hero.current_health = mini(target_hero.max_health, heal_val)
			print("ITEM REVIVE DIGUNAKAN: %s membangkitkan %s | HP: %d/%d" % [item_data.get("name", "Item"), target_hero.name, target_hero.current_health, target_hero.max_health])
		else:
			print("Karakter sedang gugur, butuh roti / item revive untuk membangkitkan.")
			return
	else:
		var old_hp: int = target_hero.current_health
		target_hero.current_health = mini(target_hero.max_health, target_hero.current_health + heal_val)
		var healed: int = target_hero.current_health - old_hp
		print("ITEM DIGUNAKAN: %s pada %s | +%d HP | Sisa HP: %d/%d" % [item_data.get("name", "Item"), target_hero.name, healed, target_hero.current_health, target_hero.max_health])


func _init_starter_quests() -> void:
	quest_list = [
		{
			"id": "main_01",
			"category": "main",
			"title": "Pemanasan Sang Pangeran",
			"location": "Tebing Hutan Observasi",
			"objective": "Kalahkan monster liar di dekat tebing pondok kayu.",
			"description": "Sebelum kembali ke ibu kota, Arthur memutuskan untuk melakukan pemanasan dengan mengalahkan monster liar di dekat tebing.",
			"status": "completed" if is_prologue_completed else "active",
			"target_position": FOREST_MONSTER_ARENA_POS
		},
		{
			"id": "main_02",
			"category": "main",
			"title": "Chapter 1.1: Rapat Darurat Istana",
			"location": "Aula Kastil",
			"objective": "Menuju aula rapat kastil untuk menemui petinggi kerajaan.",
			"description": "Pangeran Arthur bersama pasukannya harus segera masuk ke aula kastil untuk menghadiri rapat darurat strategi menghadapi 7 jenis iblis.",
			"status": "completed" if is_castle_meeting_completed else ("active" if is_prologue_completed else "inactive"),
			"target_position": CASTLE_ENTRANCE_POS
		},
		{
			"id": "main_03",
			"category": "main",
			"title": "Chapter 1.2: Ujian Sang Pelatih",
			"location": "Camp Latihan Istana",
			"objective": "Buktikan ketangguhan beradu pedang melawan Pelatih Alaric.",
			"description": "Terbangun dari tidur yang resah, Arthur harus segera menuju camp pelatihan untuk beradu pedang dan membuktikan kesiapannya bertempur pada Pelatih Alaric.",
			"status": "completed" if is_alaric_sparring_completed else ("active" if is_knight_room_completed else "inactive"),
			"target_position": ALARIC_CAMP_POS,
			"rewards": {
				"exp": 150,
				"gold": 100,
				"items": [
					{
						"id": "apple",
						"name": "Apel Merah Hutan",
						"quantity": 2,
						"icon_path": "res://assets/ui/icons/items/items_sheets.png",
						"icon_rect": Rect2(48, 560, 16, 16)
					}
				]
			}
		},
		{
			"id": "main_04",
			"category": "main",
			"title": "Chapter 1.2: Pusaka Makam Ksatria",
			"location": "Pemakaman Kerajaan",
			"objective": "Gali makam ksatria Lancelot dan ambil pedang legendaris.",
			"description": "Pelatih Alaric mengakui ketangguhan Arthur dan menyuruhnya menggali makam Lancelot di area pemakaman untuk mengambil pedang pusaka yang pernah ditempa penempa legendaris.",
			"status": "active" if is_alaric_sparring_completed else "inactive",
			"target_position": GRAVEYARD_POS,
			"rewards": {
				"exp": 200,
				"items": [
					{
						"id": "ancient_coin",
						"name": "Koin Makam Kuno",
						"quantity": 1,
						"icon_path": "res://assets/ui/icons/items/items_sheets.png",
						"icon_rect": Rect2(16, 128, 16, 16)
					}
				]
			}
		},
		{
			"id": "main_05",
			"category": "main",
			"title": "Chapter 1.2: Penempaan Pedang & Panggilan Magnus",
			"location": "Tempat Forge Istana",
			"objective": "Tempa kembali pedang pusaka dan dengarkan permintaan bantuan Magnus.",
			"description": "Arthur memperbaiki pedang pusaka di ruang tempa. Magnus kemudian menghampiri dan meminta bantuan mencari artefak kuno rahasia milik keluarganya di dalam perpustakaan.",
			"status": "inactive",
			"target_position": Vector2(2100, 1600)
		},
		{
			"id": "main_06",
			"category": "main",
			"title": "Chapter 1.2: Rahasia Perpustakaan Kuno",
			"location": "Perpustakaan Bawah Tanah",
			"objective": "Pecahkan teka-teki buku dan kalahkan penjaga Archon - The Mindfulness.",
			"description": "Arthur dan Magnus memasuki ruang rahasia perpustakaan melalui teka-teki susunan kata di rak buku, lalu menghadapi ujian pertempuran melawan entitas penjaga Archon.",
			"status": "inactive",
			"target_position": Vector2(1900, 800)
		},
		{
			"id": "main_07",
			"category": "main",
			"title": "Chapter 1.3: Kekuatan Sihir Meteor",
			"location": "Halaman Luar Istana",
			"objective": "Serap ilmu sihir Buku Emas dan uji coba skill meteor di area terbuka.",
			"description": "Setelah Archon dikalahkan, Buku Emas bersinar dan mentransmisikan sihir penghancur meteor ke dalam diri Magnus. Mereka bergegas ke luar istana untuk menguji kekuatan baru ini.",
			"status": "inactive",
			"target_position": Vector2(2800, 1800)
		},
		{
			"id": "main_08",
			"category": "main",
			"title": "Chapter 1.3: Serbuan Gerbang Utama",
			"location": "Gerbang Utama Kastil",
			"objective": "Pertahankan istana dan tumpas gerombolan kroco iblis di gerbang utama.",
			"description": "Gerbang utama istana dijebol oleh serbuan iblis! Pangeran Arthur, Magnus, dan segenap prajurit istana bertarung menahan dan membasmi kroco-kroco iblis.",
			"status": "inactive",
			"target_position": CASTLE_ENTRANCE_POS
		},
		{
			"id": "main_09",
			"category": "main",
			"title": "Chapter 1.3: Raksasa Envy & Sekutu Assassin",
			"location": "Luar Gerbang Istana",
			"objective": "Tumbangkan Boss Raksasa Envy dan jalin aliansi bersama sang Assassin misterius.",
			"description": "Boss Raksasa Envy memangsa pasukannya dan membesar. Seorang assassin misterius berkulit iblis datang membantu menerkam titik lemah sang boss. Bersama-sama, mereka menyelamatkan kerajaan dan membentuk aliansi penyelamatan dunia.",
			"status": "inactive",
			"target_position": Vector2(2533, 1300)
		},
		{
			"id": "world_01",
			"category": "world",
			"title": "Bantuan Warga Desa",
			"location": "Desa Oakhaven",
			"objective": "Bicara dengan tetua desa mengenai suplai gandum.",
			"description": "Warga desa membutuhkan perlindungan dari gangguan monster liar di sekitar lumbung pangan.",
			"status": "active",
			"target_position": Vector2(1500, 3000),
			"rewards": {
				"exp": 100,
				"gold": 50,
				"items": [
					{
						"id": "bread",
						"name": "Roti Gandum",
						"quantity": 3,
						"icon_path": "res://assets/ui/icons/items/items_sheets.png",
						"icon_rect": Rect2(192, 528, 16, 16)
					}
				]
			}
		},
		{
			"id": "world_02",
			"category": "world",
			"title": "Perburuan Bandit",
			"location": "Lembah Berkabut",
			"objective": "Tumpas komplotan bandit di lembah.",
			"description": "Kafilah dagang kerajaan dihadang bandit. Pulihkan keamanan jalur perdagangan dari ancaman penjahat.",
			"status": "active",
			"target_position": Vector2(5000, 1800),
			"rewards": {
				"exp": 250,
				"gold": 150
			}
		}
	]


func get_quest_by_id(q_id: String) -> Dictionary:
	return _get_quest_by_id(q_id)


func _get_quest_by_id(q_id: String) -> Dictionary:
	for q in quest_list:
		if q.get("id", "") == q_id:
			return q
	return {}


func _on_hud_quest_tracked(quest: Dictionary) -> void:
	if selected_game_mode == "open_world":
		return
	tracked_quest_id = quest.get("id", "")
	if gameplay_hud:
		gameplay_hud.update_hud_quest_display(quest)
		if quest.has("target_position") and gameplay_hud.has_method("set_quest_navigation"):
			gameplay_hud.set_quest_navigation(quest["target_position"], quest.get("location", ""))


func _on_hud_quest_navigation_requested(quest: Dictionary) -> void:
	if selected_game_mode == "open_world":
		return
	tracked_quest_id = quest.get("id", "")
	if gameplay_hud:
		gameplay_hud.update_hud_quest_display(quest)
		if quest.has("target_position") and gameplay_hud.has_method("set_quest_navigation"):
			gameplay_hud.set_quest_navigation(quest["target_position"], quest.get("location", ""))


func enter_location(location_name: String) -> void:
	"""Menandai kunjungan lokasi dan memicu banner sekali saat pertama kali masuk."""
	var clean_loc := location_name.strip_edges()
	if clean_loc.is_empty():
		return

	current_location_name = clean_loc
	if visited_locations.has(clean_loc):
		return

	visited_locations.append(clean_loc)
	if gameplay_hud and gameplay_hud.has_method("show_location_banner"):
		gameplay_hud.show_location_banner(clean_loc)


func get_active_leader() -> CharacterBody2D:
	if not party_members.is_empty() and active_leader_index >= 0 and active_leader_index < party_members.size():
		return party_members[active_leader_index]
	return null


func _process(delta: float) -> void:
	total_playtime += delta
	handle_camera_shake(delta)
	update_camera_target(delta)
	update_party_skill_cooldowns(delta)
	check_training_arena()
	_update_bgm_loop()
	handle_arena_group_respawn(delta)
	if arena_state == ArenaState.INACTIVE:
		check_arena_trigger()
		var cur_lead := get_active_leader()
		if is_instance_valid(cur_lead):
			var outside_all: bool = true
			for zone in arena_zones:
				if not zone["is_cleared"] and (zone["trigger_bounds"] as Rect2).grow(40.0).has_point(cur_lead.global_position):
					outside_all = false
					break
			if outside_all:
				last_pre_arena_leader_pos = cur_lead.global_position
	elif arena_state == ArenaState.COMBAT:
		check_arena_completion(delta)
		check_arena_defeat(delta)

	if is_arena_defeat_active and defeat_prompt_lbl and is_instance_valid(defeat_prompt_lbl):
		defeat_anim_time += delta
		defeat_prompt_lbl.modulate.a = 0.55 + 0.45 * sin(defeat_anim_time * 5.0)
	handle_viewport_aggro_detection(delta)
	update_breadcrumbs()
	check_active_leader_status()
	_update_active_leader_indicator(delta)
	update_party_visibility()
	check_castle_interactions(delta)
	if is_alaric_sparring_in_progress:
		check_alaric_sparring_status(delta)


func update_party_skill_cooldowns(delta: float) -> void:
	for member in party_members:
		if not is_instance_valid(member):
			continue
		# Jika karakter sedang tidak di scene tree atau physics_process tidak aktif,
		# game controller yang melanjutkan countdown cooldown skill & perisai
		if not member.is_inside_tree() or not member.is_physics_processing():
			if "skill_cooldown_timer" in member and member.skill_cooldown_timer > 0.0:
				member.skill_cooldown_timer = maxf(0.0, member.skill_cooldown_timer - delta)
			if "shield_timer" in member and member.shield_timer > 0.0:
				member.shield_timer = maxf(0.0, member.shield_timer - delta)
				if member.shield_timer <= 0.0 and member.has_method("deactivate_shield"):
					member.deactivate_shield()


func _physics_process(_delta: float) -> void:
	if arena_state == ArenaState.COMBAT:
		# Fail-safe pembatas koordinat arena agar hero tidak tembus/glitch saat knockback keras
		var min_x := arena_bounds.position.x + 15.0
		var max_x := arena_bounds.end.x - 15.0
		var min_y := arena_bounds.position.y + 15.0
		var max_y := arena_bounds.end.y - 15.0
		for member in party_members:
			if is_instance_valid(member) and member.is_inside_tree() and member.visible:
				member.global_position.x = clampf(member.global_position.x, min_x, max_x)
				member.global_position.y = clampf(member.global_position.y, min_y, max_y)


func check_active_leader_status() -> void:
	var leader := get_active_leader()
	if is_instance_valid(leader) and not is_character_alive(leader):
		rearrange_dead_members_to_back()


# =========================================================
# CAMERA VIEWPORT AGGRO & COMBAT STATE ALA GUARDIAN TALES
# =========================================================

func get_camera_world_rect() -> Rect2:
	if not camera:
		return Rect2()
	var vp_size: Vector2 = get_viewport_rect().size / camera.zoom
	var center: Vector2 = camera.get_screen_center_position()
	# Buffer 50px agar musuh di tepian layar langsung terdeteksi
	return Rect2(center - vp_size * 0.5, vp_size).grow(50.0)


func handle_viewport_aggro_detection(delta: float) -> void:
	if arena_state != ArenaState.COMBAT and not is_in_training_arena and not is_alaric_sparring_in_progress:
		return

	aggro_check_timer -= delta
	if aggro_check_timer > 0.0:
		return
	aggro_check_timer = AGGRO_CHECK_INTERVAL

	if is_alaric_sparring_in_progress:
		if is_instance_valid(alaric_node) and not ("is_dead" in alaric_node and alaric_node.is_dead):
			active_combat_targets = [alaric_node]
		else:
			active_combat_targets = []
		return

	if is_in_training_arena:
		if is_instance_valid(training_dummy_enemy) and not ("is_dead" in training_dummy_enemy and training_dummy_enemy.is_dead):
			active_combat_targets = [training_dummy_enemy]
		else:
			active_combat_targets = []
		return

	var alive_arena_enemies: Array[Node2D] = []
	for enemy in arena_enemies:
		if is_instance_valid(enemy) and not ("is_dead" in enemy and enemy.is_dead):
			alive_arena_enemies.append(enemy)

	active_combat_targets = alive_arena_enemies


func notify_party_combat_state(in_combat: bool) -> void:
	for member in party_members:
		if is_instance_valid(member) and member.is_inside_tree() and member.has_method("set_party_combat_mode"):
			member.set_party_combat_mode(in_combat)


func update_camera_target(delta: float = 0.0) -> void:
	if not camera or party_members.is_empty():
		return
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return

	# Zoom smoothing dinamis
	if delta > 0.0:
		camera.zoom = camera.zoom.lerp(target_camera_zoom, clampf(delta * 3.0, 0.0, 1.0))
	else:
		camera.zoom = target_camera_zoom

	if is_meeting_in_progress:
		var cam_target: Vector2 = CASTLE_MEETING_TABLE_CENTER
		camera.global_position = camera.global_position.lerp(cam_target, clampf(delta * 5.0, 0.0, 1.0)) if delta > 0.0 else cam_target
	elif is_camera_locked_to_arena and arena_state == ArenaState.COMBAT:
		# Kunci posisi kamera langsung ke tengah arena
		camera.global_position = arena_center
	else:
		# Fokus 100% pada posisi Leader (tepat di pusat inti tubuh karakter)
		var camera_target: Vector2 = leader.global_position
		camera.global_position = camera_target
		if delta == 0.0:
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

func apply_camera_shake(intensity: float = 8.0) -> void:
	if is_in_training_arena:
		return
	shake_intensity = max(shake_intensity, intensity)


func handle_camera_shake(delta: float) -> void:
	if not camera:
		return

	if is_in_training_arena:
		shake_intensity = 0.0
		if camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO
		return

	if shake_intensity > 0.0:
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func setup_camera_and_boundaries() -> void:
	if not camera:
		return

	camera.zoom = CAMERA_ZOOM_EXPLORE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0

	var ground := get_node_or_null("map_region1/Ground")
	if not ground:
		ground = find_child("Ground", true, false)

	if not ground:
		return

	var map_min := Vector2.ZERO
	var map_max := Vector2.ZERO

	if ground is Sprite2D and ground.texture:
		var tex_size: Vector2 = ground.texture.get_size() * ground.scale
		map_min = ground.global_position
		map_max = ground.global_position + tex_size
	elif ground is TileMapLayer:
		var rect: Rect2i = ground.get_used_rect()
		if rect.size == Vector2i.ZERO:
			return
		map_min = ground.to_global(Vector2(rect.position.x * 16.0, rect.position.y * 16.0))
		map_max = ground.to_global(Vector2((rect.position.x + rect.size.x) * 16.0, (rect.position.y + rect.size.y) * 16.0))
	else:
		return

	world_map_min = map_min
	world_map_max = map_max
	camera.limit_left = int(map_min.x)
	camera.limit_top = int(map_min.y)
	camera.limit_right = int(map_max.x)
	camera.limit_bottom = int(map_max.y)

	if not has_node("WorldBorders"):
		var borders := StaticBody2D.new()
		borders.name = "WorldBorders"
		borders.collision_layer = 1
		borders.collision_mask = 0

		var thickness := 80.0
		var width := map_max.x - map_min.x
		var height := map_max.y - map_min.y

		_create_wall_shape(borders, Vector2(map_min.x + width / 2.0, map_min.y - thickness / 2.0), Vector2(width + thickness * 2.0, thickness))
		_create_wall_shape(borders, Vector2(map_min.x + width / 2.0, map_max.y + thickness / 2.0), Vector2(width + thickness * 2.0, thickness))
		_create_wall_shape(borders, Vector2(map_min.x - thickness / 2.0, map_min.y + height / 2.0), Vector2(thickness, height + thickness * 2.0))
		_create_wall_shape(borders, Vector2(map_max.x + thickness / 2.0, map_min.y + height / 2.0), Vector2(thickness, height + thickness * 2.0))

		call_deferred("add_child", borders)


func _create_wall_shape(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	col.position = pos
	parent.add_child(col)


# =========================================================
# ARENA HALAMAN ISTANA (INVISIBLE BARRIER & COMBAT TRIGGER)
# =========================================================

func update_arena_bounds_from_camera() -> void:
	var vp_size: Vector2 = Vector2(1152.0, 648.0)
	if is_inside_tree() and get_viewport():
		var actual_size: Vector2 = get_viewport_rect().size
		if actual_size.x > 0.0 and actual_size.y > 0.0:
			vp_size = actual_size
	var world_size: Vector2 = vp_size / CAMERA_ZOOM_ARENA
	arena_bounds = Rect2(arena_center - world_size * 0.5, world_size)


func _init_arena_barrier() -> void:
	if arena_barrier_body != null and is_instance_valid(arena_barrier_body):
		return

	update_arena_bounds_from_camera()

	arena_barrier_body = StaticBody2D.new()
	arena_barrier_body.name = "ArenaInvisibleBarrier"
	arena_barrier_body.collision_layer = 1
	arena_barrier_body.collision_mask = 0
	add_child(arena_barrier_body)

	_rebuild_arena_barrier_for_bounds(arena_bounds)
	_set_arena_barrier_enabled(false)


func _rebuild_arena_barrier_for_bounds(bounds: Rect2) -> void:
	if not arena_barrier_body or not is_instance_valid(arena_barrier_body):
		return

	for child in arena_barrier_body.get_children():
		arena_barrier_body.remove_child(child)
		child.queue_free()

	var thickness := 60.0
	var west_x := bounds.position.x
	var east_x := bounds.end.x
	var north_y := bounds.position.y
	var south_y := bounds.end.y
	var width := bounds.size.x
	var height := bounds.size.y

	# 4 Dinding pembatas arena tanpa visual (barrier invisible) tepat di 4 batas tepi layar kamera
	# Dinding barat (tepat di luar tepi layar kiri)
	_create_barrier_shape(arena_barrier_body, Vector2(west_x - thickness * 0.5, north_y + height * 0.5), Vector2(thickness, height + thickness * 2.0))
	# Dinding timur (tepat di luar tepi layar kanan)
	_create_barrier_shape(arena_barrier_body, Vector2(east_x + thickness * 0.5, north_y + height * 0.5), Vector2(thickness, height + thickness * 2.0))
	# Dinding utara (tepat di luar tepi layar atas)
	_create_barrier_shape(arena_barrier_body, Vector2(west_x + width * 0.5, north_y - thickness * 0.5), Vector2(width + thickness * 2.0, thickness))
	# Dinding selatan (tepat di luar tepi layar bawah)
	_create_barrier_shape(arena_barrier_body, Vector2(west_x + width * 0.5, south_y + thickness * 0.5), Vector2(width + thickness * 2.0, thickness))


func _create_barrier_shape(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	col.position = pos
	col.disabled = true
	parent.add_child(col)


func _set_arena_barrier_enabled(enabled: bool) -> void:
	if not arena_barrier_body or not is_instance_valid(arena_barrier_body):
		return
	for child in arena_barrier_body.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not enabled)


func _init_arena_enemies() -> void:
	arena_enemies.clear()
	for zone in arena_zones:
		(zone["enemies"] as Array[CharacterBody2D]).clear()

	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e) or not (e is CharacterBody2D):
			continue
		if "is_training_dummy" in e and e.is_training_dummy:
			continue
		if "is_alaric" in e and e.is_alaric:
			continue
		if "Alaric" in e.name:
			continue

		var assigned: bool = false
		for zone in arena_zones:
			var zone_bounds: Rect2 = zone["bounds"]
			if zone_bounds.grow(150.0).has_point(e.global_position):
				(zone["enemies"] as Array[CharacterBody2D]).append(e)
				assigned = true
				if "wait_for_arena" in e:
					e.wait_for_arena = true
				if "can_respawn" in e:
					e.can_respawn = false
				break

		# Fallback penempatan berdasarkan nama jika ada pergeseran posisi editor
		if not assigned:
			if "Archer" in e.name:
				(arena_zones[0]["enemies"] as Array[CharacterBody2D]).append(e)
				if "wait_for_arena" in e:
					e.wait_for_arena = true
				if "can_respawn" in e:
					e.can_respawn = false
			elif "Knight" in e.name:
				(arena_zones[1]["enemies"] as Array[CharacterBody2D]).append(e)
				if "wait_for_arena" in e:
					e.wait_for_arena = true
				if "can_respawn" in e:
					e.can_respawn = false

	print("[Arena] Inisialisasi Arena Zones:")
	for zone in arena_zones:
		print(" - ", zone["name"], " (ID: ", zone["id"], ") terdaftar ", (zone["enemies"] as Array).size(), " musuh.")


func _init_training_dummy() -> void:
	# Dummy arena sementara di tengah kota dinonaktifkan / dihapus sesuai permintaan
	pass


func check_training_arena() -> void:
	# Area latihan dummy dinonaktifkan
	return


func enter_training_arena() -> void:
	if is_in_training_arena or arena_state != ArenaState.INACTIVE:
		return
	is_in_training_arena = true
	shake_intensity = 0.0
	if camera and is_instance_valid(camera):
		camera.offset = Vector2.ZERO
	current_combat_state = PartyCombatState.COMBAT

	_deploy_party_for_combat()
	update_party_visibility()
	notify_party_combat_state(true)

	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(true, true)


func exit_training_arena() -> void:
	if not is_in_training_arena:
		return
	is_in_training_arena = false
	current_combat_state = PartyCombatState.EXPLORING

	rearrange_dead_members_to_back()
	if active_leader_index != 0 and party_members.size() > 0 and is_character_alive(party_members[0]):
		set_active_leader(0)

	for member in party_members:
		if is_instance_valid(member):
			if not ("is_dead" in member and member.is_dead):
				member.modulate.a = 1.0
			else:
				member.modulate.a = 0.0
				member.visible = false
			if member.has_method("reset_combat_skills"):
				member.reset_combat_skills()
	notify_party_combat_state(false)
	update_party_visibility()
	breadcrumbs.clear()

	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(false, false)


func check_arena_trigger() -> void:
	if arena_state != ArenaState.INACTIVE:
		return
	var leader := get_active_leader()
	if not leader or not is_instance_valid(leader):
		return
	for i in range(arena_zones.size()):
		var zone: Dictionary = arena_zones[i]
		if zone["is_cleared"]:
			continue
		var enemies_list: Array = zone.get("enemies", [])
		if enemies_list.is_empty():
			continue

		# Cek apakah masih ada musuh hidup di zona ini
		var has_alive_enemy: bool = false
		for e in enemies_list:
			if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
				has_alive_enemy = true
				break
		if not has_alive_enemy:
			zone["is_cleared"] = true
			continue

		var trig: Rect2 = zone["trigger_bounds"]
		if trig.has_point(leader.global_position):
			start_arena_battle(i)
			break


func start_arena_battle(zone_idx: int = 0) -> void:
	if arena_state != ArenaState.INACTIVE:
		return
	if zone_idx < 0 or zone_idx >= arena_zones.size():
		return

	active_arena_idx = zone_idx
	var zone: Dictionary = arena_zones[active_arena_idx]
	arena_center = zone["center"]
	arena_trigger_bounds = zone["trigger_bounds"]
	arena_enemies = zone["enemies"]

	update_arena_bounds_from_camera()
	zone["bounds"] = arena_bounds

	_take_pre_arena_snapshot()
	arena_state = ArenaState.COMBAT
	current_combat_state = PartyCombatState.COMBAT
	arena_clear_delay_timer = 0.0

	# 1. Update & aktifkan invisible barrier penutup arena untuk zona aktif
	_rebuild_arena_barrier_for_bounds(arena_bounds)
	_set_arena_barrier_enabled(true)

	# 2. Pindahkan target kamera ke tengah arena dan perbesar sudut pandang (zoom out)
	target_camera_zoom = CAMERA_ZOOM_ARENA
	is_camera_locked_to_arena = true

	# 3. Spawn / aktifkan 3 rekan party di sekitar leader
	_deploy_party_for_combat()
	update_party_visibility()
	notify_party_combat_state(true)

	# 4. Bangunkan seluruh musuh di arena aktif untuk langsung mengejar party
	var leader := get_active_leader()
	for enemy in arena_enemies:
		if is_instance_valid(enemy):
			if "wait_for_arena" in enemy:
				enemy.wait_for_arena = false
			if "in_arena_combat" in enemy:
				enemy.in_arena_combat = true
			if enemy.has_method("alert_to_combat"):
				enemy.alert_to_combat(leader)

	# Tampilkan elemen HUD pertarungan saat memasuki arena
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(true, true)

	print("Arena Battle Dimulai! Zona: ", zone["name"], ", Kamera fokus ke (", arena_center, "), musuh aktif: ", arena_enemies.size())


func get_hero_type_index(char_node: CharacterBody2D) -> int:
	if not is_instance_valid(char_node):
		return -1
	var script_path := ""
	if char_node.get_script():
		script_path = str(char_node.get_script().resource_path).to_lower()
	var n := str(char_node.name).to_lower()
	if "knight" in script_path or "knight" in n or "arthur" in n:
		return 0 # Arthur / Knight
	elif "bandit" in script_path or "bandit" in n or "hellene" in n:
		return 1 # Hellene / Bandit
	elif "archer" in script_path or "archer" in n or "anastasya" in n:
		return 2 # Anastasya / Archer
	elif "mage" in script_path or "mage" in n or "magnus" in n:
		return 3 # Magnus / Mage
	return -1


func _get_combat_deploy_offset(hero_type: int, leader_type: int, forward: Vector2, lateral: Vector2) -> Vector2:
	var leader_is_ranged: bool = (leader_type == 2 or leader_type == 3)

	if not leader_is_ranged:
		# Leader adalah petarung melee di garis depan (Arthur / Hellene)
		match hero_type:
			0: # Knight (off-tank) bersanding di samping depan
				return -forward * 20.0 + lateral * 50.0
			1: # Bandit (flanker) bersanding di samping depan
				return -forward * 20.0 - lateral * 50.0
			2: # Archer (Anastasya) di sayap kiri belakang
				return -forward * 70.0 - lateral * 65.0
			3: # Mage (Magnus) di sayap kanan belakang
				return -forward * 70.0 + lateral * 65.0
			_:
				return -forward * 60.0
	else:
		# Leader adalah karakter ranged di lini belakang (Anastasya / Magnus)
		match hero_type:
			0: # Knight maju ke depan kiri melindungi leader
				return forward * 65.0 - lateral * 45.0
			1: # Bandit maju ke depan kanan mengapit musuh
				return forward * 65.0 + lateral * 45.0
			2: # Archer berdiri di sayap kiri mendampingi rekan ranged
				return -forward * 15.0 - lateral * 70.0
			3: # Mage berdiri di sayap kanan mendampingi rekan ranged
				return -forward * 15.0 + lateral * 70.0
			_:
				return forward * 50.0


func _deploy_party_for_combat() -> void:
	var leader := get_active_leader()
	if not leader or not is_instance_valid(leader):
		return

	# Tentukan arah hadap formasi ke pusat arena pertempuran
	var target_center: Vector2 = TRAINING_DUMMY_SPAWN_POS if is_in_training_arena else arena_center
	var forward_dir: Vector2 = (target_center - leader.global_position).normalized()
	if forward_dir.length_squared() < 0.01:
		forward_dir = Vector2.RIGHT
	var lateral_dir: Vector2 = Vector2(-forward_dir.y, forward_dir.x)

	var leader_type := get_hero_type_index(leader)

	var deploy_members: Array[CharacterBody2D] = []
	var deploy_positions: Array[Vector2] = []

	var active_bounds: Rect2 = TRAINING_ARENA_BOUNDS if is_in_training_arena else arena_bounds
	var padding: float = 20.0 if is_in_training_arena else 45.0
	var min_x := active_bounds.position.x + padding
	var max_x := active_bounds.end.x - padding
	var min_y := active_bounds.position.y + padding
	var max_y := active_bounds.end.y - padding

	for i in range(party_members.size()):
		if i == active_leader_index:
			continue
		var member = party_members[i]
		if not is_instance_valid(member):
			continue
		if "is_dead" in member and member.is_dead:
			continue

		if not member.is_inside_tree():
			add_child(member)

		var h_type := get_hero_type_index(member)
		var offset := _get_combat_deploy_offset(h_type, leader_type, forward_dir, lateral_dir)
		var spawn_pos: Vector2 = leader.global_position + offset
		spawn_pos.x = clampf(spawn_pos.x, min_x, max_x)
		spawn_pos.y = clampf(spawn_pos.y, min_y, max_y)

		deploy_members.append(member)
		deploy_positions.append(spawn_pos)

	# Iterative Relaxation Pass: Jaga jarak alami antar karakter agar tidak saling menumpuk
	const MIN_MEMBER_DISTANCE: float = 65.0
	const MIN_LEADER_DISTANCE: float = 55.0
	var leader_pos := leader.global_position

	for _iter in range(8):
		for i in range(deploy_positions.size()):
			# 1. Jaga jarak dari Leader
			var d_leader := deploy_positions[i].distance_to(leader_pos)
			if d_leader < MIN_LEADER_DISTANCE:
				var push_dir := (deploy_positions[i] - leader_pos).normalized()
				if push_dir.length_squared() < 0.01:
					push_dir = -forward_dir
				deploy_positions[i] = leader_pos + push_dir * MIN_LEADER_DISTANCE

			# 2. Jaga jarak antar rekan party satu sama lain
			for j in range(i + 1, deploy_positions.size()):
				var d_pair := deploy_positions[i].distance_to(deploy_positions[j])
				if d_pair < MIN_MEMBER_DISTANCE:
					var sep_dir := (deploy_positions[i] - deploy_positions[j]).normalized()
					if sep_dir.length_squared() < 0.01:
						sep_dir = lateral_dir
					var overlap := (MIN_MEMBER_DISTANCE - d_pair) * 0.5
					deploy_positions[i] += sep_dir * overlap
					deploy_positions[j] -= sep_dir * overlap

			# 3. Batasi posisi tetap di dalam batas arena
			deploy_positions[i].x = clampf(deploy_positions[i].x, min_x, max_x)
			deploy_positions[i].y = clampf(deploy_positions[i].y, min_y, max_y)

	# Terapkan posisi akhir ke masing-masing anggota party
	for k in range(deploy_members.size()):
		var member = deploy_members[k]
		var spawn_pos = deploy_positions[k]
		member.global_position = spawn_pos
		member.modulate.a = 1.0
		if "target_position" in member:
			member.target_position = spawn_pos
		if "velocity" in member:
			member.velocity = Vector2.ZERO
		if member.has_method("get_cardinal_direction"):
			member.last_direction = member.get_cardinal_direction(forward_dir)
		if member.has_method("play_idle_animation"):
			member.play_idle_animation()


func check_arena_completion(_delta: float) -> void:
	if arena_state != ArenaState.COMBAT:
		return

	if is_party_fading_out or is_arena_defeat_active:
		return

	var all_dead: bool = true
	var leader := get_active_leader()
	for e in arena_enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and e.is_in_group("enemy"):
			all_dead = false
			# Pastikan seluruh musuh arena yang masih hidup selalu aktif mengejar party
			if "in_arena_combat" in e and not e.in_arena_combat:
				e.in_arena_combat = true
			if "current_state" in e and e.current_state != 1: # State.CHASE
				if e.has_method("alert_to_combat"):
					e.alert_to_combat(leader)

	if all_dead:
		_start_party_combat_fade_out()
	else:
		arena_clear_delay_timer = 0.0


func _start_party_combat_fade_out() -> void:
	if is_party_fading_out or is_arena_defeat_active:
		return
	is_party_fading_out = true

	# Reset seketika seluruh skill aktif dan cooldown pada seluruh hero (termasuk Leader)
	for member in party_members:
		if is_instance_valid(member) and member.has_method("reset_combat_skills"):
			member.reset_combat_skills()

	# Pemicu fade out UI tempur secara bersamaan dan serentak dengan rekan party
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(false, true)

	# Bersihkan tween fade sebelumnya jika ada
	for tw in _party_fade_tweens:
		if is_instance_valid(tw) and tw.is_valid():
			tw.kill()
	_party_fade_tweens.clear()

	# 1. Reorganisasi party roster saat pertarungan selesai:
	# Hero yang gugur TIDAK dipulihkan dan dipindahkan ke posisi paling belakang.
	# Karakter hidup berikutnya (misal Hellene / Karakter 2) otomatis maju menjadi Leader utama di Slot 0.
	rearrange_dead_members_to_back()
	if active_leader_index != 0 and party_members.size() > 0 and is_character_alive(party_members[0]):
		set_active_leader(0)

	# 2. Kembalikan kamera secara natural ke Leader utama (zoom explore dan smoothing glide)
	is_camera_locked_to_arena = false
	target_camera_zoom = CAMERA_ZOOM_EXPLORE

	var fade_duration: float = 0.5
	var _has_companion_to_fade: bool = false

	for i in range(party_members.size()):
		if i == 0:
			continue
		var member = party_members[i]
		if not is_instance_valid(member) or not member.is_inside_tree():
			continue

		# Hentikan seketika agar tidak melangkah atau mengikuti leader saat musuh gugur
		if "velocity" in member:
			member.velocity = Vector2.ZERO
		if "is_moving" in member:
			member.is_moving = false
		if member.has_method("play_idle_animation") and not ("is_dead" in member and member.is_dead):
			member.play_idle_animation()

		# Matikan physics dan collision agar rekan party tetap diam di tempat selama proses fade
		member.set_physics_process(false)
		member.set_process(false)
		_set_character_collision_active(member, false)

		_has_companion_to_fade = true
		var tw := create_tween()
		tw.tween_property(member, "modulate:a", 0.0, fade_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_party_fade_tweens.append(tw)

	get_tree().create_timer(fade_duration).timeout.connect(func():
		if arena_state == ArenaState.COMBAT:
			end_arena_battle()
	, CONNECT_ONE_SHOT)


func end_arena_battle() -> void:
	if arena_state != ArenaState.COMBAT:
		return

	if active_arena_idx >= 0 and active_arena_idx < arena_zones.size():
		arena_zones[active_arena_idx]["is_cleared"] = true
		arena_zones[active_arena_idx]["respawn_timer"] = ARENA_GROUP_RESPAWN_DELAY
		print("[Arena] Zona selesai dibersihkan: ", arena_zones[active_arena_idx]["name"], ". Musuh akan spawn lagi dalam ", ARENA_GROUP_RESPAWN_DELAY, " detik.")

	# Cek apakah seluruh zona arena cerita telah diselesaikan
	var has_remaining_arena: bool = false
	for zone in arena_zones:
		if not zone["is_cleared"]:
			has_remaining_arena = true
			break

	if has_remaining_arena:
		arena_state = ArenaState.INACTIVE
	else:
		arena_state = ArenaState.CLEARED

	is_party_fading_out = false
	current_combat_state = PartyCombatState.EXPLORING
	arena_group_respawn_timer = ARENA_GROUP_RESPAWN_DELAY

	# 1. Buka batas arena (nonaktifkan barrier)
	_set_arena_barrier_enabled(false)

	# 2. Kembalikan kamera ke mode eksplorasi (zoom explore dan ikuti leader)
	target_camera_zoom = CAMERA_ZOOM_EXPLORE
	is_camera_locked_to_arena = false

	# 3. Bersihkan seluruh tween fade dan kembalikan alpha seluruh member menjadi 1.0 (kecuali yang gugur)
	for tw in _party_fade_tweens:
		if is_instance_valid(tw) and tw.is_valid():
			tw.kill()
	_party_fade_tweens.clear()

	for member in party_members:
		if is_instance_valid(member):
			if not ("is_dead" in member and member.is_dead):
				member.modulate.a = 1.0
			else:
				member.modulate.a = 0.0
				member.visible = false

	# 4. Kembalikan party ke mode 1 karakter dan pastikan seluruh skill & cooldown ter-reset
	if active_leader_index != 0 and party_members.size() > 0 and is_character_alive(party_members[0]):
		set_active_leader(0)
	for member in party_members:
		if is_instance_valid(member) and member.has_method("reset_combat_skills"):
			member.reset_combat_skills()
	notify_party_combat_state(false)
	update_party_visibility()
	breadcrumbs.clear()

	# Pastikan status HUD pertarungan tersembunyi jika masih aktif
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		if gameplay_hud.get("is_combat_hud_visible") == true:
			gameplay_hud.set_combat_hud_visible(false, false)

	# Matikan mode tempur arena pada musuh arena yang tersisa
	for e in arena_enemies:
		if is_instance_valid(e) and "in_arena_combat" in e:
			e.in_arena_combat = false

	active_arena_idx = -1
	print("Arena Battle Selesai! Kamera kembali ke Leader, party kembali ke mode eksplorasi.")


func handle_arena_group_respawn(delta: float) -> void:
	for zone in arena_zones:
		if zone.get("is_cleared", false):
			zone["respawn_timer"] -= delta
			if zone["respawn_timer"] <= 0.0:
				_respawn_zone_enemies(zone)


func _respawn_zone_enemies(zone: Dictionary) -> void:
	zone["is_cleared"] = false
	zone["respawn_timer"] = 0.0
	var z_enemies: Array = zone.get("enemies", [])
	for e in z_enemies:
		if is_instance_valid(e):
			if "wait_for_arena" in e:
				e.wait_for_arena = true
			if "in_arena_combat" in e:
				e.in_arena_combat = false
			if e.has_method("respawn"):
				e.respawn()

	if arena_state == ArenaState.CLEARED:
		arena_state = ArenaState.INACTIVE

	print("[Arena] Musuh di zona ", zone["name"], " telah spawn kembali setelah 7 detik!")


func _respawn_arena_enemy_group() -> void:
	for zone in arena_zones:
		_respawn_zone_enemies(zone)


# =========================================================
# HELPER KEKALAHAN ARENA & PUTAR MUNDUR WAKTU (TIME REWIND)
# =========================================================

func _init_defeat_overlay() -> void:
	if defeat_canvas != null and is_instance_valid(defeat_canvas):
		return

	defeat_canvas = CanvasLayer.new()
	defeat_canvas.name = "ArenaDefeatCanvas"
	defeat_canvas.layer = 120
	defeat_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	defeat_canvas.visible = false

	# 1. Overlay merah transparan yang menyelimuti seluruh layar
	defeat_rect = ColorRect.new()
	defeat_rect.name = "DefeatOverlay"
	defeat_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	defeat_rect.color = Color(0.65, 0.05, 0.05, 0.42)
	defeat_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	defeat_rect.gui_input.connect(_on_defeat_overlay_gui_input)
	defeat_canvas.add_child(defeat_rect)

	# 2. Kontainer teks persis di tengah layar
	var center_container := CenterContainer.new()
	center_container.name = "CenterContainer"
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	defeat_canvas.add_child(center_container)

	var center_box := VBoxContainer.new()
	center_box.name = "CenterBox"
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_theme_constant_override("separation", 14)
	center_container.add_child(center_box)

	# 3. Label Judul
	defeat_title_lbl = Label.new()
	defeat_title_lbl.name = "TitleLabel"
	defeat_title_lbl.text = "SELURUH ANGGOTA TELAH GUGUR"
	defeat_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defeat_title_lbl.add_theme_font_override("font", UI_FONT_BEHOLDEN)
	defeat_title_lbl.add_theme_font_size_override("font_size", 28)
	defeat_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85, 1.0))
	defeat_title_lbl.add_theme_color_override("font_shadow_color", Color(0.35, 0.02, 0.02, 0.9))
	defeat_title_lbl.add_theme_constant_override("shadow_offset_x", 2)
	defeat_title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	center_box.add_child(defeat_title_lbl)

	# 4. Label Subjudul
	defeat_subtitle_lbl = Label.new()
	defeat_subtitle_lbl.name = "SubtitleLabel"
	defeat_subtitle_lbl.text = "Waktu terhenti di ambang batas arena..."
	defeat_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_subtitle_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defeat_subtitle_lbl.add_theme_font_override("font", UI_FONT_BEHOLDEN)
	defeat_subtitle_lbl.add_theme_font_size_override("font_size", 14)
	defeat_subtitle_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.8, 0.85))
	center_box.add_child(defeat_subtitle_lbl)

	# 5. Spacer kecil
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	center_box.add_child(spacer)

	# 6. Label Prompt Berdenyut
	defeat_prompt_lbl = Label.new()
	defeat_prompt_lbl.name = "PromptLabel"
	defeat_prompt_lbl.text = "[ TEKAN TOMBOL APA SAJA ]"
	defeat_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_prompt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defeat_prompt_lbl.add_theme_font_override("font", UI_FONT_BEHOLDEN)
	defeat_prompt_lbl.add_theme_font_size_override("font_size", 16)
	defeat_prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	defeat_prompt_lbl.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.0, 0.8))
	defeat_prompt_lbl.add_theme_constant_override("shadow_offset_x", 1)
	defeat_prompt_lbl.add_theme_constant_override("shadow_offset_y", 1)
	center_box.add_child(defeat_prompt_lbl)

	add_child(defeat_canvas)


func _on_defeat_overlay_gui_input(event: InputEvent) -> void:
	if not is_arena_defeat_active:
		return
	if is_awaiting_defeat_rewind_input:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			is_awaiting_defeat_rewind_input = false
			execute_arena_rewind()
			get_viewport().set_input_as_handled()
			return
	get_viewport().set_input_as_handled()


func _take_pre_arena_snapshot() -> void:
	pre_arena_snapshot.clear()
	var leader := get_active_leader()
	var fallback_pos: Vector2 = Vector2(arena_trigger_bounds.position.x - 60.0, arena_center.y)
	var snap_pos: Vector2 = fallback_pos
	if last_pre_arena_leader_pos != Vector2.ZERO and not arena_trigger_bounds.grow(10.0).has_point(last_pre_arena_leader_pos):
		snap_pos = last_pre_arena_leader_pos
	elif is_instance_valid(leader) and leader.global_position.x < arena_trigger_bounds.position.x:
		snap_pos = leader.global_position

	var party_data: Array[Dictionary] = []
	for member in party_members:
		if is_instance_valid(member):
			var cur_hp: int = member.current_health if "current_health" in member else 100
			var is_d: bool = ("is_dead" in member and member.is_dead) or (cur_hp <= 0)
			var slot: int = member.queue_slot_index if "queue_slot_index" in member else 0
			party_data.append({
				"node": member,
				"name": member.name,
				"hp": cur_hp,
				"is_dead": is_d,
				"slot_idx": slot
			})

	pre_arena_snapshot = {
		"restore_pos": snap_pos,
		"active_leader_index": active_leader_index,
		"roster_order": party_members.duplicate(),
		"party_state": party_data
	}
	print("Pre-Arena Snapshot Disimpan: Titik kembali ", snap_pos, ", Leader index: ", active_leader_index)


func are_all_party_members_dead() -> bool:
	if party_members.is_empty():
		return false
	for m in party_members:
		if is_instance_valid(m):
			var is_d: bool = ("is_dead" in m and m.is_dead) or ("current_health" in m and m.current_health <= 0)
			if not is_d:
				return false
	return true


func check_arena_defeat(_delta: float) -> void:
	if arena_state != ArenaState.COMBAT:
		return
	if is_arena_defeat_active or is_party_fading_out:
		return
	if are_all_party_members_dead():
		trigger_arena_defeat()


func trigger_arena_defeat() -> void:
	if is_arena_defeat_active:
		return
	is_arena_defeat_active = true
	is_awaiting_defeat_rewind_input = false
	defeat_anim_time = 0.0

	# 1. Hentikan aksi seluruh musuh arena
	for e in arena_enemies:
		if is_instance_valid(e):
			if "velocity" in e:
				e.velocity = Vector2.ZERO
			if "is_moving" in e:
				e.is_moving = false
			if e.has_method("play_idle_animation"):
				e.play_idle_animation()

	# 2. Tutup modal/menu pause jika terbuka dan blokir interaksi UI
	if gameplay_hud and is_instance_valid(gameplay_hud):
		if gameplay_hud.has_method("_close_confirm_modal"):
			gameplay_hud._close_confirm_modal()
		if "pause_overlay" in gameplay_hud and is_instance_valid(gameplay_hud.pause_overlay) and gameplay_hud.pause_overlay.visible:
			if gameplay_hud.has_method("_close_pause_book"):
				gameplay_hud._close_pause_book()
			elif gameplay_hud.has_method("toggle_pause_menu"):
				gameplay_hud.toggle_pause_menu()
			if is_instance_valid(gameplay_hud.pause_overlay):
				gameplay_hud.pause_overlay.visible = false
		if get_tree().paused:
			get_tree().paused = false
		gameplay_hud.is_hud_input_blocked = true

	# 3. Tunda sejenak 0.6 detik agar animasi kekalahan karakter selesai
	get_tree().create_timer(0.6).timeout.connect(func():
		if not is_arena_defeat_active or arena_state != ArenaState.COMBAT:
			return
		if defeat_canvas and is_instance_valid(defeat_canvas):
			defeat_canvas.visible = true
			if defeat_rect:
				defeat_rect.modulate.a = 0.0
			if defeat_title_lbl:
				defeat_title_lbl.modulate.a = 0.0
			if defeat_subtitle_lbl:
				defeat_subtitle_lbl.modulate.a = 0.0
			if defeat_prompt_lbl:
				defeat_prompt_lbl.modulate.a = 0.0

			var tw := create_tween()
			if defeat_rect:
				tw.tween_property(defeat_rect, "modulate:a", 1.0, 0.45)
			if defeat_title_lbl:
				tw.parallel().tween_property(defeat_title_lbl, "modulate:a", 1.0, 0.45)
			if defeat_subtitle_lbl:
				tw.parallel().tween_property(defeat_subtitle_lbl, "modulate:a", 1.0, 0.45)
			if defeat_prompt_lbl:
				tw.parallel().tween_property(defeat_prompt_lbl, "modulate:a", 1.0, 0.45)

			# Berikan jeda toleransi 0.2 detik sebelum menerima input rewind agar tidak terpicu klik tak sengaja
			get_tree().create_timer(0.2).timeout.connect(func():
				if is_arena_defeat_active:
					is_awaiting_defeat_rewind_input = true
			, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func execute_arena_rewind() -> void:
	if pre_arena_snapshot.is_empty():
		is_arena_defeat_active = false
		if gameplay_hud and is_instance_valid(gameplay_hud):
			gameplay_hud.is_hud_input_blocked = false
		return

	# Mainkan audio respawn / rewind waktu
	play_sfx(SFX_HERO_RESPAWN, 0.0)

	# 1. Nonaktifkan barrier arena seketika
	_set_arena_barrier_enabled(false)

	# 2. Reset status arena dan kamera
	arena_state = ArenaState.INACTIVE
	current_combat_state = PartyCombatState.EXPLORING
	is_party_fading_out = false
	arena_clear_delay_timer = 0.0
	target_camera_zoom = CAMERA_ZOOM_EXPLORE
	is_camera_locked_to_arena = false

	# 3. Pulihkan dan hidupkan kembali seluruh musuh arena di posisi awal
	for e in arena_enemies:
		if is_instance_valid(e):
			if "wait_for_arena" in e:
				e.wait_for_arena = true
			if "in_arena_combat" in e:
				e.in_arena_combat = false
			if e.has_method("respawn"):
				e.respawn()

	if active_arena_idx >= 0 and active_arena_idx < arena_zones.size():
		arena_zones[active_arena_idx]["is_cleared"] = false
	active_arena_idx = -1

	# 4. Kembalikan urutan party dari snapshot
	if pre_arena_snapshot.has("roster_order"):
		var saved_roster: Array = pre_arena_snapshot["roster_order"]
		var restored_party: Array[CharacterBody2D] = []
		for m in saved_roster:
			if is_instance_valid(m) and m is CharacterBody2D:
				restored_party.append(m)
		if not restored_party.is_empty():
			party_members = restored_party

	var restore_pos: Vector2 = pre_arena_snapshot.get("restore_pos", Vector2(arena_trigger_bounds.position.x - 60.0, arena_center.y))

	# 5. Pulihkan kondisi hero dari snapshot
	var party_data: Array = pre_arena_snapshot.get("party_state", [])
	for m_data in party_data:
		var hero: CharacterBody2D = m_data.get("node")
		if not is_instance_valid(hero):
			continue
		var hp: int = m_data.get("hp", 100)
		var was_dead: bool = m_data.get("is_dead", false)

		hero.global_position = restore_pos
		if "target_position" in hero:
			hero.target_position = restore_pos
		if "velocity" in hero:
			hero.velocity = Vector2.ZERO
		if "knockback_velocity" in hero:
			hero.knockback_velocity = Vector2.ZERO

		if was_dead or hp <= 0:
			hero.is_dead = true
			hero.current_health = 0
			hero.visible = false
			hero.modulate = Color(1.0, 1.0, 1.0, 0.0)
			if hero.is_in_group("player"):
				hero.remove_from_group("player")
			if hero.has_node("CollisionShape2D"):
				hero.get_node("CollisionShape2D").set_deferred("disabled", true)
			if hero.has_node("Hurtbox/CollisionShape2D"):
				hero.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", true)
		else:
			hero.is_dead = false
			hero.current_health = hp
			hero.visible = true
			hero.modulate = Color.WHITE
			if not hero.is_in_group("player"):
				hero.add_to_group("player")
			if not hero.is_inside_tree():
				add_child(hero)
			if hero.has_node("CollisionShape2D"):
				hero.get_node("CollisionShape2D").set_deferred("disabled", false)
			if hero.has_node("Hurtbox/CollisionShape2D"):
				hero.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", false)
			if hero.has_method("play_idle_animation"):
				hero.play_idle_animation()

		if hero.has_method("reset_combat_skills"):
			hero.reset_combat_skills()

	# 6. Tentukan Leader aktif yang hidup
	var saved_leader_idx: int = pre_arena_snapshot.get("active_leader_index", 0)
	if saved_leader_idx < 0 or saved_leader_idx >= party_members.size() or not is_character_alive(party_members[saved_leader_idx]):
		saved_leader_idx = 0
		for i in range(party_members.size()):
			if is_character_alive(party_members[i]):
				saved_leader_idx = i
				break

	set_active_leader(saved_leader_idx)
	var active_hero := get_active_leader()
	if active_hero:
		active_hero.global_position = restore_pos
		if "target_position" in active_hero:
			active_hero.target_position = restore_pos
		if camera:
			camera.global_position = active_hero.global_position
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

	notify_party_combat_state(false)
	update_party_visibility()
	breadcrumbs.clear()

	# 7. Sembunyikan combat HUD
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(false, false)

	# 8. Sinkronkan urutan dan status ke HUD
	if gameplay_hud:
		if gameplay_hud.has_method("update_party_order"):
			gameplay_hud.update_party_order(party_members, active_leader_index)
		else:
			gameplay_hud.party_members = party_members
			gameplay_hud.active_leader_index = active_leader_index
			gameplay_hud.update_party_hud()
			gameplay_hud.update_leader_indicator()

	# 9. Fade out layar defeat secara halus
	if defeat_canvas and is_instance_valid(defeat_canvas):
		var tw := create_tween()
		if defeat_rect:
			tw.tween_property(defeat_rect, "modulate:a", 0.0, 0.35)
		if defeat_title_lbl:
			tw.parallel().tween_property(defeat_title_lbl, "modulate:a", 0.0, 0.35)
		if defeat_subtitle_lbl:
			tw.parallel().tween_property(defeat_subtitle_lbl, "modulate:a", 0.0, 0.35)
		if defeat_prompt_lbl:
			tw.parallel().tween_property(defeat_prompt_lbl, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func():
			if defeat_canvas and is_instance_valid(defeat_canvas):
				defeat_canvas.visible = false
			is_arena_defeat_active = false
			if gameplay_hud and is_instance_valid(gameplay_hud):
				gameplay_hud.is_hud_input_blocked = false
		)
	else:
		is_arena_defeat_active = false
		if gameplay_hud and is_instance_valid(gameplay_hud):
			gameplay_hud.is_hud_input_blocked = false


# =========================================================
# BREADCRUMB HISTORY & SNAKE FORMATION (CASCADE SWAP 180°)
# =========================================================

var breadcrumbs: Array[Dictionary] = []
const BREADCRUMB_INTERVAL: float = 8.0
const QUEUE_DIST: float = 85.0

func update_breadcrumbs() -> void:
	if party_members.is_empty() or active_leader_index >= party_members.size():
		return
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader) or ("is_dead" in leader and leader.is_dead):
		return

	var leader_pos: Vector2 = leader.global_position
	var leader_dir: Vector2 = Vector2.DOWN
	if "last_movement_direction" in leader and leader.last_movement_direction != Vector2.ZERO:
		leader_dir = leader.last_movement_direction
	elif "last_direction" in leader and leader.last_direction != Vector2.ZERO:
		leader_dir = leader.last_direction

	if breadcrumbs.is_empty():
		breadcrumbs.append({"pos": leader_pos, "dir": leader_dir})
		for i in range(1, 60):
			breadcrumbs.append({
				"pos": leader_pos - leader_dir * (i * BREADCRUMB_INTERVAL),
				"dir": leader_dir
			})
		return

	var head_pos: Vector2 = breadcrumbs[0]["pos"]
	var dist_from_head := leader_pos.distance_to(head_pos)

	if dist_from_head >= BREADCRUMB_INTERVAL:
		var step_dir := (leader_pos - head_pos).normalized()
		var last_trail_dir := leader_dir
		if breadcrumbs.size() >= 2:
			last_trail_dir = (breadcrumbs[0]["pos"] - breadcrumbs[1]["pos"]).normalized()

		# Deteksi putar balik 180° (Cascade Swap)
		if last_trail_dir != Vector2.ZERO and step_dir.dot(last_trail_dir) < -0.7:
			# Leader berbalik 180° melewati barisannya sendiri!
			# Balikkan jalur antrean ke belakang titik belok secara estafet
			var turn_pt := head_pos
			breadcrumbs.clear()
			breadcrumbs.append({"pos": leader_pos, "dir": step_dir})
			breadcrumbs.append({"pos": turn_pt, "dir": step_dir})
			for k in range(1, 60):
				breadcrumbs.append({
					"pos": turn_pt - step_dir * (k * BREADCRUMB_INTERVAL),
					"dir": step_dir
				})
		else:
			# Gerakan biasa atau belok 90° (Snake Corner Turn)
			breadcrumbs.push_front({"pos": leader_pos, "dir": step_dir})
			if breadcrumbs.size() > 300:
				breadcrumbs.pop_back()


func get_follower_trail_slot(slot_index: int) -> Dictionary:
	if party_members.is_empty() or active_leader_index >= party_members.size():
		return {}
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return {}

	var target_dist: float = slot_index * QUEUE_DIST
	if breadcrumbs.is_empty():
		return {"pos": leader.global_position - Vector2.DOWN * target_dist, "dir": Vector2.DOWN}

	var accumulated_dist: float = 0.0
	var prev_pt: Vector2 = leader.global_position

	for i in range(breadcrumbs.size()):
		var cur_pt: Vector2 = breadcrumbs[i]["pos"]
		var seg_len: float = prev_pt.distance_to(cur_pt)
		if accumulated_dist + seg_len >= target_dist:
			var remain := target_dist - accumulated_dist
			var t := remain / maxf(seg_len, 0.001)
			var interp_pos := prev_pt.lerp(cur_pt, t)
			var seg_dir: Vector2 = cur_pt.direction_to(prev_pt)
			if seg_dir == Vector2.ZERO:
				seg_dir = breadcrumbs[i]["dir"]
			return {"pos": interp_pos, "dir": seg_dir}
		accumulated_dist += seg_len
		prev_pt = cur_pt

	var last_bc: Dictionary = breadcrumbs.back()
	var fallback_dir: Vector2 = last_bc.get("dir", Vector2.DOWN)
	var needed: float = target_dist - accumulated_dist
	return {
		"pos": prev_pt - fallback_dir * needed,
		"dir": fallback_dir
	}


func get_follower_nav_target(slot_index: int, follower_pos: Vector2, space_state: PhysicsDirectSpaceState2D = null) -> Dictionary:
	var slot_info := get_follower_trail_slot(slot_index)
	if slot_info.is_empty():
		return {}

	var final_pos: Vector2 = slot_info["pos"]
	var facing_dir: Vector2 = slot_info.get("dir", Vector2.DOWN)

	# Jika jarak sudah sangat dekat atau tidak ada space_state, langsung ke final_pos
	if follower_pos.distance_to(final_pos) <= 24.0 or not space_state:
		return {
			"target_pos": final_pos,
			"final_slot": final_pos,
			"dir": facing_dir,
			"is_corner_waypoint": false
		}

	# Cek apakah garis langsung ke final_pos terhalang oleh Collision Layer 1 (dinding / bangunan)
	var ray := PhysicsRayQueryParameters2D.create(follower_pos, final_pos)
	ray.collision_mask = 1
	var hit := space_state.intersect_ray(ray)

	if hit.is_empty():
		# Jalur langsung bersih tanpa rintangan
		return {
			"target_pos": final_pos,
			"final_slot": final_pos,
			"dir": facing_dir,
			"is_corner_waypoint": false
		}

	# Jalur terhalang rintangan/sudut bangunan:
	# Cari titik sudut pada breadcrumbs yang terlihat jelas oleh follower (Clear LoS)
	var best_waypoint := final_pos
	var found_clear := false

	var target_dist: float = slot_index * QUEUE_DIST
	var accumulated: float = 0.0
	var prev: Vector2 = party_members[active_leader_index].global_position if (active_leader_index < party_members.size() and is_instance_valid(party_members[active_leader_index])) else Vector2.ZERO
	var slot_bc_index: int = 0

	for i in range(breadcrumbs.size()):
		var cur: Vector2 = breadcrumbs[i]["pos"]
		accumulated += prev.distance_to(cur)
		prev = cur
		if accumulated >= target_dist:
			slot_bc_index = i
			break

	var start_idx: int = clampi(slot_bc_index + 12, 0, breadcrumbs.size() - 1)
	for i in range(start_idx, -1, -1):
		var candidate: Vector2 = breadcrumbs[i]["pos"]
		if candidate.distance_to(follower_pos) < 20.0:
			continue
		var check_ray := PhysicsRayQueryParameters2D.create(follower_pos, candidate)
		check_ray.collision_mask = 1
		if space_state.intersect_ray(check_ray).is_empty():
			best_waypoint = candidate
			found_clear = true
			break

	return {
		"target_pos": best_waypoint if found_clear else final_pos,
		"final_slot": final_pos,
		"dir": facing_dir,
		"is_corner_waypoint": found_clear
	}


func play_iris_opening_transition() -> void:
	var transition_layer := get_node_or_null("TransitionLayer")
	var iris: ColorRect = transition_layer.get_node_or_null("IrisMask") as ColorRect if transition_layer else null
	if iris and (iris.material is ShaderMaterial):
		is_transitioning = true
		if is_instance_valid(gameplay_hud):
			gameplay_hud.is_hud_input_blocked = true
		for p in party_members:
			if is_instance_valid(p):
				p.set_physics_process(false)
				p.set_process_unhandled_input(false)
				p.velocity = Vector2.ZERO
				if p.has_method("play_idle_animation"):
					p.play_idle_animation()

		var mat := iris.material as ShaderMaterial
		mat.set_shader_parameter("center", Vector2(0.5, 0.5))
		mat.set_shader_parameter("radius", 0.0)
		mat.set_shader_parameter("softness", 0.015)

		# Tunggu inisialisasi engine dan scene stabil agar bebas dari frame-drop awal
		await get_tree().process_frame
		await get_tree().process_frame

		# Kunci posisi kamera langsung ke leader tanpa lag smoothing awal
		if is_instance_valid(camera):
			camera.reset_smoothing()

		# Jeda bernapas halus sebelum lingkaran mulai mekar
		await get_tree().create_timer(0.08).timeout

		# Buka circular mask dengan kurva sinusoidal alami (EASE_IN_OUT) yang sangat lembut
		var sfx_iris_open: AudioStream = load("res://assets/audio/sfx/ui/transition_iris_open.wav")
		if sfx_iris_open:
			var sfx_player := AudioStreamPlayer.new()
			sfx_player.bus = &"SFX"
			sfx_player.stream = sfx_iris_open
			sfx_player.volume_db = -3.0
			add_child(sfx_player)
			sfx_player.finished.connect(sfx_player.queue_free)
			sfx_player.play()

		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(mat, "shader_parameter/radius", 1.5, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	else:
		await get_tree().process_frame

	# Hapus node transisi setelah selesai agar memori dan render pass bersih
	if is_instance_valid(transition_layer):
		transition_layer.queue_free()

	is_transitioning = false
	if is_instance_valid(gameplay_hud):
		gameplay_hud.is_hud_input_blocked = false
	for i in range(party_members.size()):
		var p = party_members[i]
		if is_instance_valid(p):
			p.set_physics_process(true)
			var should_input: bool = (i == active_leader_index)
			p.set_process_unhandled_input(should_input)

	if not is_inside_tree():
		return

	# Munculkan banner lokasi sekali setelah arena terbuka pada kunjungan pertama
	if not visited_locations.has(current_location_name):
		enter_location(current_location_name)


# ==========================================
# SAVE & LOAD GAME SYSTEM (TASK 05C)
# ==========================================

func _on_hud_save_game_requested(slot_id: int) -> void:
	save_game_to_slot(slot_id)


func _on_hud_load_game_requested(slot_id: int) -> void:
	load_game_from_slot(slot_id)


func _on_hud_return_to_title_requested() -> void:
	get_tree().paused = false
	if gameplay_hud and is_instance_valid(gameplay_hud.pause_overlay):
		gameplay_hud.pause_overlay.visible = false
	_stop_all_bgm()
	get_tree().change_scene_to_file("res://scene/ui/menus/start_menu.tscn")


func _on_hud_dialogue_started(_dialogue_id: String) -> void:
	set_party_movement_locked(true)
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)


func _on_hud_dialogue_finished(_dialogue_id: String) -> void:
	if is_scene_4_in_progress and is_on_library_floor_2:
		set_party_movement_locked(true)
		return
	set_party_movement_locked(false)


func _show_story_prologue_intro_crawl(on_completed: Callable) -> void:
	is_transitioning = true
	set_party_movement_locked(true)
	if is_instance_valid(gameplay_hud):
		gameplay_hud.is_hud_input_blocked = true
		gameplay_hud.visible = false

	var crawl_canvas := CanvasLayer.new()
	crawl_canvas.name = "PrologueIntroCrawl"
	crawl_canvas.layer = 125

	# Latar belakang hitam pekat
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.05, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bg.grow_vertical = Control.GROW_DIRECTION_BOTH
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	crawl_canvas.add_child(bg)

	# Container konten
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_bottom", 35)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crawl_canvas.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var font: Font = load("res://assets/ui/fonts/beholden-bold.ttf")

	var paragraphs: Array[String] = [
		"Tepat siang hari pada abad ke-7, sebelum \"satu minggu kebangkitan adanya yang tiada\" terjadi.",
		"Hari di mana kematian terganggu dan kehidupan mulai diusik.",
		"Mereka yang telah pergi, kembali untuk menghukum mereka yang masih hidup.",
		"Menjalankan titah dari sang Raja, Pangeran \"Arthur\" sedang melakukan observasi di lumbung pengolahan kayu bersama kawan lamanya.",
		"Tepat di hari itu, sebuah panggilan tak terduga datang... membawa kabar buruk yang akan mengguncang seluruh kerajaan."
	]

	var sfx_click: AudioStream = preload("res://assets/audio/sfx/ui/book_tab_select.wav")
	var sfx_finish: AudioStream = preload("res://assets/audio/sfx/ui/book_page_flip.wav")

	var labels: Array[Label] = []
	for p_text in paragraphs:
		var lbl := Label.new()
		lbl.text = p_text
		if font:
			lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.visible_characters = 0
		vbox.add_child(lbl)
		labels.append(lbl)

	# Indikator petunjuk lanjut di bagian bawah
	var hint_lbl := Label.new()
	hint_lbl.text = "[ Tekan Spasi / Klik untuk Lanjut ]"
	if font:
		hint_lbl.add_theme_font_override("font", font)
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.58, 0.8))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_lbl.modulate.a = 0.0
	vbox.add_child(hint_lbl)

	# Tombol transparan penangkap klik layar penuh (menjamin klik mouse di mana saja selalu terdeteksi)
	var click_btn := Button.new()
	click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.focus_mode = Control.FOCUS_ALL
	click_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_sb := StyleBoxEmpty.new()
	click_btn.add_theme_stylebox_override("normal", empty_sb)
	click_btn.add_theme_stylebox_override("hover", empty_sb)
	click_btn.add_theme_stylebox_override("pressed", empty_sb)
	click_btn.add_theme_stylebox_override("focus", empty_sb)
	click_btn.add_theme_stylebox_override("disabled", empty_sb)
	crawl_canvas.add_child(click_btn)

	add_child(crawl_canvas)

	# Fade in pembuka latar belakang
	bg.modulate.a = 0.0
	margin.modulate.a = 0.0
	var in_tween := create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(bg, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	in_tween.tween_property(margin, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	await in_tween.finished

	# Sistem deteksi input pemain (Klik mouse / Spasi / Enter)
	var advance_pressed: Array[bool] = [false]
	click_btn.pressed.connect(func():
		advance_pressed[0] = true
	)
	click_btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			advance_pressed[0] = true
	)

	var last_key_state: Array[bool] = [true]
	var last_mouse_state: Array[bool] = [true]
	await get_tree().create_timer(0.05).timeout
	last_key_state[0] = false
	last_mouse_state[0] = false

	var check_advance_pressed = func() -> bool:
		if advance_pressed[0]:
			advance_pressed[0] = false
			return true

		# 1. Deteksi klik mouse langsung via Input
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not last_mouse_state[0]:
				last_mouse_state[0] = true
				return true
		else:
			last_mouse_state[0] = false

		# 2. Deteksi tombol keyboard (Spasi / Enter / Action)
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			return true
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
			if not last_key_state[0]:
				last_key_state[0] = true
				return true
		else:
			last_key_state[0] = false

		return false

	# Tampilkan kalimat bertumpuk satu per satu (tekan klik/spasi untuk langsung menyelesaikan 1 baris aktif)
	for p_idx in range(labels.size()):
		var lbl: Label = labels[p_idx]
		var total_chars: int = lbl.text.length()
		var current_chars: float = 0.0
		var chars_per_sec: float = 40.0
		var instant_cleared: bool = false

		# Efek ketik berjalan pada baris aktif
		while current_chars < total_chars:
			var delta: float = get_process_delta_time()
			current_chars += chars_per_sec * delta
			lbl.visible_characters = int(current_chars)

			if check_advance_pressed.call():
				# Jika ditekan saat sedang mengetik -> langsung selesaikan 1 baris ini seketika
				lbl.visible_characters = -1
				instant_cleared = true
				play_sfx(sfx_click, -3.5)
				break

			await get_tree().process_frame

		lbl.visible_characters = -1

		# Debounce input agar klik yang menyelesaikan baris aktif tidak sengaja melewati baris berikutnya
		if instant_cleared:
			await get_tree().create_timer(0.16).timeout
			advance_pressed[0] = false
			last_mouse_state[0] = true
			last_key_state[0] = true
		elif p_idx < labels.size() - 1:
			# Jeda membaca natural jika tidak di-skip pemain (1.2s)
			var read_timer: float = 0.0
			var max_read_delay: float = 1.2
			while read_timer < max_read_delay:
				if check_advance_pressed.call():
					play_sfx(sfx_click, -3.5)
					break
				var dt: float = get_process_delta_time()
				read_timer += dt
				await get_tree().process_frame

	# Semua kalimat selesai muncul penuh di layar -> aktifkan petunjuk lanjut berkedip di bawah
	hint_lbl.modulate.a = 1.0
	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(hint_lbl, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(hint_lbl, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Tunggu konfirmasi klik / spasi terakhir dari pemain untuk lanjut ke gameplay
	while true:
		if check_advance_pressed.call():
			play_sfx(sfx_finish, -3.0)
			break
		await get_tree().process_frame

	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()

	# Fade out penutup teks
	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(bg, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	out_tween.tween_property(margin, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await out_tween.finished

	crawl_canvas.queue_free()

	if is_instance_valid(gameplay_hud):
		gameplay_hud.visible = true
		gameplay_hud.is_hud_input_blocked = false

	if on_completed.is_valid():
		on_completed.call()


func _trigger_prologue_cutscene() -> void:
	_start_story_prologue_sequence()


func _start_story_prologue_sequence() -> void:
	if is_prologue_completed or selected_game_mode == "open_world":
		return

	# Pastikan transisi pembuka awal (jika ada) selesai sebelum pergerakan cutscene dimulai
	while is_transitioning:
		await get_tree().process_frame

	set_party_movement_locked(true)

	var lead := get_active_leader()
	if is_instance_valid(lead):
		lead.set_physics_process(false)
		lead.set_process_unhandled_input(false)
		_set_character_collision_active(lead, false)
		lead.global_position = FOREST_CABIN_DOOR_POS
		lead.velocity = Vector2.ZERO
		if "last_direction" in lead:
			lead.last_direction = Vector2.DOWN
		if lead.has_method("play_idle_animation"):
			lead.play_idle_animation()

	if is_instance_valid(camera):
		camera.global_position = FOREST_CABIN_DOOR_POS
		camera.reset_smoothing()

	# 1. Tampilkan Magnus (Wizard) di camp observasi hutan
	var mage = all_heroes.get("Mage_1")
	if is_instance_valid(mage):
		if not mage.is_inside_tree():
			add_child(mage)
		mage.global_position = FOREST_MAGNUS_POS
		mage.set_physics_process(false)
		mage.set_process_unhandled_input(false)
		if "last_direction" in mage:
			mage.last_direction = Vector2.RIGHT
		if mage.has_method("play_idle_animation"):
			mage.play_idle_animation()
		mage.visible = true

	# 2. Spawn 3 NPC Pengawal Kerajaan di camp observasi hutan
	_cleanup_prologue_entities()
	var guard_scene: PackedScene = load("res://scene/npc/npc_guard.tscn")
	if guard_scene:
		var guard_data: Array[Dictionary] = [
			{"pos": Vector2(8420.0, 4240.0), "dir": "e"},
			{"pos": Vector2(8720.0, 4220.0), "dir": "w"},
			{"pos": Vector2(8780.0, 4360.0), "dir": "w"}
		]
		for idx in range(guard_data.size()):
			var g = guard_scene.instantiate() as CharacterBody2D
			if g:
				g.name = "PrologueGuard_%d" % (idx + 1)
				g.global_position = guard_data[idx]["pos"]
				g.patrol_points.clear()
				g.facing_direction = guard_data[idx].get("dir", "w")
				g.set_physics_process(false)
				add_child(g)
				var spr = g.get_node_or_null("AnimatedSprite2D")
				if spr:
					spr.play("idle_" + g.facing_direction)
				_prologue_guards.append(g)

	# 3. Spawn Burung Gagak bertengger di atas tiang lampu kayu sejak awal
	_prologue_crow = Sprite2D.new()
	_prologue_crow.name = "PrologueCrow"
	_prologue_crow.texture = load("res://assets/characters/animal/raven/raven.png")
	_prologue_crow.hframes = 2
	_prologue_crow.vframes = 1
	_prologue_crow.frame = 0
	_prologue_crow.scale = Vector2(2.5, 2.5)
	_prologue_crow.z_index = 8
	_prologue_crow.global_position = FOREST_CROW_PERCH_POS
	add_child(_prologue_crow)

	# Animasi idle bertengger gagak (gerakan menoleh / bobbing frame 0 dan 1)
	if _prologue_crow_flap_tween and _prologue_crow_flap_tween.is_valid():
		_prologue_crow_flap_tween.kill()
	_prologue_crow_flap_tween = create_tween().set_loops()
	_prologue_crow_flap_tween.tween_callback(func():
		if is_instance_valid(_prologue_crow):
			_prologue_crow.frame = (_prologue_crow.frame + 1) % 2
	).set_delay(0.4)

	enter_location("Hutan Observasi")

	await get_tree().create_timer(0.5).timeout

	# 4. Arthur berjalan keluar pondok menuju titik henti (S)
	if is_instance_valid(lead):
		if "last_direction" in lead:
			lead.last_direction = Vector2.DOWN
		if lead.has_method("play_walk_animation"):
			lead.play_walk_animation()

	var arthur_tween := create_tween()
	arthur_tween.tween_property(lead, "global_position", FOREST_CAMP_STOP_POS, 3.4).set_trans(Tween.TRANS_LINEAR)

	await arthur_tween.finished
	if is_instance_valid(lead) and lead.has_method("play_idle_animation"):
		lead.play_idle_animation()

	await get_tree().create_timer(0.4).timeout

	# 5. Mulai dialog pembuka pemanasan Arthur & Magnus (Naskah Dialog 1A)
	play_story_dialogue("FLK-002", func():
		set_party_movement_locked(false)
		var lead_char := get_active_leader()
		if is_instance_valid(lead_char):
			lead_char.set_physics_process(true)
			lead_char.set_process_unhandled_input(true)
			_set_character_collision_active(lead_char, true)
		if is_instance_valid(gameplay_hud):
			gameplay_hud.visible = true
			gameplay_hud.is_hud_input_blocked = false
			var quest_main1 := _get_quest_by_id("main_01")
			if not quest_main1.is_empty():
				gameplay_hud.update_hud_quest_display(quest_main1)
				if gameplay_hud.has_method("set_quest_navigation"):
					gameplay_hud.set_quest_navigation(FOREST_MONSTER_ARENA_POS, "Tebing Hutan Observasi")
		_start_monitoring_prologue_fight()
	)


var _is_prologue_fight_active: bool = false
var _is_prologue_fight_done: bool = false
var _is_waiting_prologue_return: bool = false


func _start_monitoring_prologue_fight() -> void:
	_is_prologue_fight_active = true
	_is_prologue_fight_done = false
	_is_waiting_prologue_return = false

	# Pastikan ketiga monster di tebing aktif dan siap dilawan
	for e_name in ["Enemy_Knight_1", "Enemy_Knight_2", "Enemy_Archer_1"]:
		var e = get_node_or_null(e_name)
		if is_instance_valid(e):
			e.visible = true
			e.set_physics_process(true)
			if "is_dead" in e:
				e.is_dead = false

	# Pantau sampai ketiga monster dilumpuhkan oleh Arthur
	while _is_prologue_fight_active and not _is_prologue_fight_done and not is_prologue_completed:
		await get_tree().create_timer(0.4).timeout
		var alive_count := 0
		for e_name in ["Enemy_Knight_1", "Enemy_Knight_2", "Enemy_Archer_1"]:
			var e = get_node_or_null(e_name)
			if is_instance_valid(e) and not bool(e.get("is_dead")):
				alive_count += 1
		if alive_count == 0:
			_is_prologue_fight_done = true
			_on_prologue_monsters_cleared()
			break


func _on_prologue_monsters_cleared() -> void:
	if _is_waiting_prologue_return:
		return
	_is_waiting_prologue_return = true

	# Perbarui quest & arah navigasi kompas untuk kembali ke Magnus di lumbung kayu
	for q in quest_list:
		if q.get("id") == "main_01":
			q["objective"] = "Kembali ke Magnus di lumbung pengolahan kayu."
			q["target_position"] = FOREST_CAMP_STOP_POS
			if is_instance_valid(gameplay_hud):
				gameplay_hud.update_hud_quest_display(q)
				if gameplay_hud.has_method("set_quest_navigation"):
					gameplay_hud.set_quest_navigation(FOREST_CAMP_STOP_POS, "Lumbung Kayu")
			break

	# Pantau saat Arthur berjalan kembali mendekati Magnus
	while _is_waiting_prologue_return and not is_prologue_completed:
		await get_tree().create_timer(0.3).timeout
		var lead := get_active_leader()
		if is_instance_valid(lead):
			var dist: float = lead.global_position.distance_to(FOREST_CAMP_STOP_POS)
			if dist < 200.0:
				_is_waiting_prologue_return = false
				_start_prologue_crow_dialogue_sequence()
				break


func _start_prologue_crow_dialogue_sequence() -> void:
	set_party_movement_locked(true)
	var lead := get_active_leader()
	if is_instance_valid(lead):
		lead.velocity = Vector2.ZERO
		if lead.has_method("play_idle_animation"):
			lead.play_idle_animation()

	# Mainkan Naskah Dialog 1B (Setelah Fight & Burung Gagak Tiba)
	play_story_dialogue("FLK-002-B", func():
		_transition_prologue_to_castle_gate()
	)


func _transition_prologue_to_castle_gate() -> void:
	play_black_fade_transition(
		func():
			_cleanup_prologue_entities()

			# Di depan gerbang kastil sisa Arthur saja (solo)
			var mage = all_heroes.get("Mage_1")
			if is_instance_valid(mage) and mage.is_inside_tree():
				remove_child(mage)

			party_members.clear()
			if all_heroes.has("Knight_1"):
				party_members.append(all_heroes["Knight_1"])
			set_active_leader(0)

			if is_instance_valid(gameplay_hud):
				if gameplay_hud.has_method("update_party_order"):
					gameplay_hud.update_party_order(party_members, active_leader_index)
				elif gameplay_hud.has_method("update_party_hud"):
					gameplay_hud.party_members = party_members
					gameplay_hud.update_party_hud()

			var lead := get_active_leader()
			if is_instance_valid(lead):
				lead.global_position = CASTLE_APPROACH_START_POS
				lead.velocity = Vector2.ZERO
				if "last_direction" in lead:
					lead.last_direction = Vector2.UP
				if lead.has_method("play_idle_animation"):
					lead.play_idle_animation()

			update_camera_limits_for_location("outdoor")
			if is_instance_valid(camera):
				camera.global_position = CASTLE_APPROACH_START_POS
				camera.reset_smoothing()
				if camera.has_method("force_update_scroll"):
					camera.force_update_scroll()

			enter_location("Jalan Menuju Istana"),
		func():
			_run_castle_gate_approach_cutscene()
	)


func _run_castle_gate_approach_cutscene() -> void:
	set_party_movement_locked(true)
	var lead := get_active_leader()
	if is_instance_valid(lead):
		lead.set_physics_process(false)
		lead.set_process_unhandled_input(false)
		_set_character_collision_active(lead, false)
		if "last_direction" in lead:
			lead.last_direction = Vector2.UP
		if lead.has_method("play_walk_animation"):
			lead.play_walk_animation()

		var tw := create_tween()
		tw.tween_property(lead, "global_position", CASTLE_APPROACH_STOP_POS, 5.0).set_trans(Tween.TRANS_LINEAR)
		await tw.finished

		if is_instance_valid(lead) and lead.has_method("play_idle_animation"):
			lead.play_idle_animation()

	set_party_movement_locked(false)
	if is_instance_valid(lead):
		_set_character_collision_active(lead, true)
		lead.set_physics_process(true)
		lead.set_process_unhandled_input(true)

	is_prologue_completed = true

	# Selesaikan quest main_01 dan aktifkan main_02
	for q in quest_list:
		if q.get("id") == "main_01":
			q["status"] = "completed"
		elif q.get("id") == "main_02":
			q["status"] = "active"

	tracked_quest_id = "main_02"
	if is_instance_valid(gameplay_hud):
		if gameplay_hud.has_method("set_quests"):
			gameplay_hud.set_quests(quest_list, tracked_quest_id)
		var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
		if not tracked_q.is_empty() and gameplay_hud.has_method("update_hud_quest_display"):
			gameplay_hud.update_hud_quest_display(tracked_q)
		if gameplay_hud.has_method("set_quest_navigation"):
			gameplay_hud.set_quest_navigation(CASTLE_ENTRANCE_POS, "Aula Kastil")

	var marker = get_node_or_null("CastleObjectiveMarker")
	if is_instance_valid(marker):
		marker.visible = true

	save_game_to_slot(1)


func _cleanup_prologue_entities() -> void:
	for g in _prologue_guards:
		if is_instance_valid(g):
			g.queue_free()
	_prologue_guards.clear()

	if _prologue_crow_flap_tween and _prologue_crow_flap_tween.is_valid():
		_prologue_crow_flap_tween.kill()
		_prologue_crow_flap_tween = null

	if is_instance_valid(_prologue_crow):
		_prologue_crow.queue_free()
		_prologue_crow = null


func get_story_dialogue(story_code_or_id: String) -> Array[Dictionary]:
	var key: String = story_code_or_id.strip_edges()
	var raw_dialogue = null
	if STORY_DIALOGUES.has(key):
		raw_dialogue = STORY_DIALOGUES[key]
	elif STORY_DIALOGUES.has(key.to_upper()):
		raw_dialogue = STORY_DIALOGUES[key.to_upper()]
	elif STORY_DIALOGUES.has(key.to_lower()):
		raw_dialogue = STORY_DIALOGUES[key.to_lower()]

	if raw_dialogue == null:
		return []

	var dialogue_data: Array[Dictionary] = []
	dialogue_data.assign(raw_dialogue)
	return dialogue_data


func play_story_dialogue(story_code_or_id: String, on_complete: Callable = Callable()) -> bool:
	var dialogue_data: Array[Dictionary] = get_story_dialogue(story_code_or_id)
	if dialogue_data.is_empty():
		push_warning("play_story_dialogue: Naskah dialog '%s' tidak ditemukan dalam STORY_DIALOGUES!" % story_code_or_id)
		if on_complete.is_valid():
			on_complete.call()
		return false

	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_dialogue"):
		gameplay_hud.show_dialogue(story_code_or_id, dialogue_data, func():
			if on_complete.is_valid():
				on_complete.call()
		)
		return true
	elif on_complete.is_valid():
		on_complete.call()
	return false


func trigger_castle_meeting_dialogue(on_completed: Callable = Callable()) -> void:
	play_story_dialogue("castle_meeting", on_completed)


func start_castle_meeting_cutscene() -> void:
	if is_meeting_in_progress or is_castle_meeting_completed or is_transitioning:
		return
	is_meeting_in_progress = true

	# Sembunyikan prompt interaksi HUD
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt()

	# Kunci kontrol player
	set_party_movement_locked(true)

	var leader := get_active_leader()
	if not is_instance_valid(leader):
		is_meeting_in_progress = false
		set_party_movement_locked(false)
		return

	# Nonaktifkan physics & input leader sementara agar animasi cutscene jalan mulus tanpa terinterupsi
	leader.set_physics_process(false)
	leader.set_process_unhandled_input(false)
	_set_character_collision_active(leader, false)
	leader.z_index = 6

	# Hitung durasi jalan berdasarkan jarak agar tempo langkah konsisten dan alami
	var dist: float = leader.global_position.distance_to(CASTLE_MEETING_SIT_POS)
	var walk_duration: float = clampf(dist / 140.0, 0.6, 2.2)

	# Mainkan animasi berjalan menghadap utara menuju meja rapat
	if "last_direction" in leader:
		leader.last_direction = Vector2.UP
	if leader.has_node("AnimatedSprite2D"):
		var anim_spr = leader.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim_spr:
			anim_spr.play("walk_n")

	# Arthur otomatis berjalan sendiri menuju posisi berdirinya di meja rapat
	var move_tween := create_tween()
	move_tween.tween_property(leader, "global_position", CASTLE_MEETING_SIT_POS, walk_duration).set_trans(Tween.TRANS_LINEAR)
	await move_tween.finished

	# Begitu sampai di depan meja, Arthur berhenti dan menghadap ke raja (Utara)
	if "last_direction" in leader:
		leader.last_direction = Vector2.UP
	if leader.has_node("AnimatedSprite2D"):
		var anim_spr = leader.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim_spr:
			anim_spr.play("idle_n")

	# Jeda bernapas singkat sebelum dialog dimulai
	await get_tree().create_timer(0.4).timeout

	# Jalankan dialog rapat istana (kendali dialog Space/Enter/Klik berada di tangan player melalui HUD)
	trigger_castle_meeting_dialogue(func():
		_on_castle_meeting_finished()
	)


func _on_castle_meeting_finished() -> void:
	# Arthur melangkah mundur sedikit dari meja ke area bebas setelah rapat selesai
	var leader := get_active_leader()
	if is_instance_valid(leader):
		var stand_tween := create_tween()
		stand_tween.tween_property(leader, "global_position", CASTLE_MEETING_SEAT_GLOBAL_POS, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await stand_tween.finished

		leader.z_index = 4
		if "last_direction" in leader:
			leader.last_direction = Vector2.DOWN
		if leader.has_node("AnimatedSprite2D"):
			var anim_spr = leader.get_node("AnimatedSprite2D") as AnimatedSprite2D
			if anim_spr:
				anim_spr.play("idle_s")

		_set_character_collision_active(leader, true)
		leader.set_physics_process(true)
		leader.set_process_unhandled_input(true)

	breadcrumbs.clear()
	is_meeting_in_progress = false
	is_castle_meeting_completed = true

	# Buka jeda sejenak sebelum transisi sinematik ke FLK-006 (Kamar Arthur)
	await get_tree().create_timer(0.4).timeout
	start_knight_room_cutscene()


func start_knight_room_cutscene() -> void:
	if is_knight_room_cutscene_in_progress or is_knight_room_completed:
		return
	is_knight_room_cutscene_in_progress = true

	# Kunci pergerakan party selama cutscene narasi kamar berlangsung
	set_party_movement_locked(true)
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt()

	var leader := get_active_leader()
	if is_instance_valid(leader):
		leader.set_physics_process(false)
		leader.set_process_unhandled_input(false)
		leader.velocity = Vector2.ZERO
		if leader.has_method("play_idle_animation"):
			leader.play_idle_animation()

	# CanvasLayer untuk transisi pudar hitam sinematik & teks narasi waktu
	var fade_canvas := CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fade_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_canvas.add_child(fade_rect)

	# Container teks narasi transisi (Keesokan Paginya...)
	var label_container := VBoxContainer.new()
	label_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	label_container.alignment = BoxContainer.ALIGNMENT_CENTER
	label_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_container.modulate.a = 0.0

	var title_lbl := Label.new()
	title_lbl.text = "Keesokan Paginya..."
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65, 1.0))

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Kamar Pangeran Arthur"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82, 0.85))

	label_container.add_child(title_lbl)
	label_container.add_child(subtitle_lbl)
	fade_canvas.add_child(label_container)
	add_child(fade_canvas)

	# 1. Efek Fade to Black halus (0.5 detik)
	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween_in.finished

	# 2. Fade In Teks Narasi "Keesokan Paginya..."
	var tween_txt_in := create_tween()
	tween_txt_in.tween_property(label_container, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	await tween_txt_in.finished

	await get_tree().create_timer(1.2).timeout

	# 3. Fade Out Teks Narasi
	var tween_txt_out := create_tween()
	tween_txt_out.tween_property(label_container, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween_txt_out.finished
	label_container.queue_free()

	# 4. Selesaikan Quest Chapter 1.1 (main_02) dan Aktifkan Quest Chapter 1.2 (main_03)
	for q in quest_list:
		if q.get("id") == "main_02":
			q["status"] = "completed"
		elif q.get("id") == "main_03":
			q["status"] = "active"
	tracked_quest_id = "main_03"
	if is_instance_valid(gameplay_hud):
		if gameplay_hud.has_method("set_quests"):
			gameplay_hud.set_quests(quest_list, tracked_quest_id)
		var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
		if not tracked_q.is_empty() and gameplay_hud.has_method("update_hud_quest_display"):
			gameplay_hud.update_hud_quest_display(tracked_q)

	# Ubah layer canvas ke 12 (di bawah HUD layer 15) agar kotak dialog tampil di atas latar hitam
	fade_canvas.layer = 12

	# 5. Putar Dialog Narasi Batin Arthur (FLK-006)
	play_story_dialogue("FLK-006", func():
		_on_knight_room_dialogue_finished(fade_canvas, fade_rect)
	)


func _on_knight_room_dialogue_finished(fade_canvas: CanvasLayer, fade_rect: ColorRect) -> void:
	is_knight_room_completed = true
	is_knight_room_cutscene_in_progress = false

	# 1. Pindahkan Arthur dan seluruh party ke luar aula rapat (Halaman Depan Kastil)
	is_inside_castle_hall = false
	for i in range(party_members.size()):
		var member = party_members[i]
		if is_instance_valid(member):
			var offset := Vector2.ZERO
			match i:
				0: offset = Vector2(0, 0)
				1: offset = Vector2(-40, 36)
				2: offset = Vector2(40, 36)
				3: offset = Vector2(0, 70)
			member.global_position = CASTLE_OUTSIDE_SPAWN_POS + offset
			member.velocity = Vector2.ZERO
			if "last_direction" in member:
				member.last_direction = Vector2.DOWN
			if member.has_method("play_idle_animation"):
				member.play_idle_animation()

	# 2. Reset batasan kamera untuk area luar dan pusatkan langsung ke Arthur
	update_camera_limits_for_hall(false)
	if is_instance_valid(camera):
		camera.global_position = CASTLE_OUTSIDE_SPAWN_POS
		camera.reset_smoothing()
		if camera.has_method("force_update_scroll"):
			camera.force_update_scroll()

	await get_tree().process_frame
	await get_tree().process_frame

	enter_location("Halaman Depan Kastil")

	# 3. Perbarui navigasi quest menuju Camp Latihan
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_quest_navigation"):
		gameplay_hud.set_quest_navigation(ALARIC_CAMP_POS, "Camp Latihan Istana")

	# Pastikan NPC Pelatih Alaric telah diinstansiasi di Camp Latihan
	_setup_alaric_npc()

	# 4. Efek Fade Out layar gelap kembali ke tampilan gameplay luar istana
	if is_instance_valid(fade_rect):
		var tween_out := create_tween()
		tween_out.tween_property(fade_rect, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween_out.finished

	if is_instance_valid(fade_canvas):
		fade_canvas.queue_free()

	# Kembalikan kontrol kepada player sepenuhnya
	set_party_movement_locked(false)
	var leader := get_active_leader()
	if is_instance_valid(leader):
		_set_character_collision_active(leader, true)
		leader.set_physics_process(true)
		leader.set_process_unhandled_input(true)

	# Simpan autosave progress
	save_game_to_slot(1)


# =========================================================
# CHAPTER 1 - SCENE 4: PERPUSTAKAAN ISTANA & MANTRA TERSEGEL
# =========================================================

func setup_party_for_scene_4() -> void:
	party_members.clear()
	var needed: Array[String] = ["Knight_1", "Mage_1", "Archer_1"]
	for n in needed:
		var hero: CharacterBody2D = all_heroes.get(n)
		if is_instance_valid(hero):
			if not hero.is_inside_tree():
				add_child(hero)
			hero.visible = true
			hero.modulate.a = 1.0
			hero.is_dead = false
			hero.current_health = hero.max_health if "max_health" in hero else 100
			hero.set_physics_process(true)
			hero.set_process_unhandled_input(true)
			_set_character_collision_active(hero, true)
			party_members.append(hero)

	# Pastikan Bandit (Assassin) belum muncul sampai Scene 5
	var bandit: CharacterBody2D = all_heroes.get("Bandit_1")
	if is_instance_valid(bandit):
		bandit.visible = false
		bandit.set_physics_process(false)
		bandit.set_process_unhandled_input(false)
		_set_character_collision_active(bandit, false)
		if bandit.is_inside_tree():
			remove_child(bandit)

	set_active_leader(0)
	setup_party_enemy_collision_exceptions()
	if gameplay_hud and gameplay_hud.has_method("update_party_order"):
		gameplay_hud.update_party_order(party_members, active_leader_index)


func start_story_scene_4() -> void:
	if is_scene_4_in_progress:
		return
	is_scene_4_in_progress = true
	is_inside_castle_hall = false
	is_inside_secret_library = true
	is_on_library_floor_2 = false
	set_party_movement_locked(true)

	if gameplay_hud and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt()

	# 1. Konfigurasi 3 Hero: Arthur, Magnus, Anastasya
	setup_party_for_scene_4()

	# 2. Aktifkan Lantai 1 library, sembunyikan Lantai 2
	var lib_node := get_node_or_null("SecretLibrary")
	if is_instance_valid(lib_node):
		var floor1 := lib_node.get_node_or_null("LibraryFloor1")
		var floor2 := lib_node.get_node_or_null("LibraryFloor2")
		if floor1: floor1.visible = true
		if floor2: floor2.visible = false

	# 3. Update camera limits ke perpustakaan SEBELUM teleport
	update_camera_limits_for_location("library")

	# 4. Posisikan hero di Lantai 1 (dekat pintu masuk)
	var arthur: CharacterBody2D = all_heroes.get("Knight_1")
	var magnus: CharacterBody2D = all_heroes.get("Mage_1")
	var anastasya: CharacterBody2D = all_heroes.get("Archer_1")

	if is_instance_valid(arthur):
		arthur.global_position = SECRET_LIBRARY_L1_SPAWN
		if "last_direction" in arthur:
			arthur.last_direction = Vector2.UP
		if arthur.has_method("play_idle_animation"):
			arthur.play_idle_animation()

	if is_instance_valid(magnus):
		magnus.global_position = Vector2(SECRET_LIBRARY_L1_SPAWN.x - 70.0, SECRET_LIBRARY_L1_SPAWN.y + 15.0)
		if "last_direction" in magnus:
			magnus.last_direction = Vector2.UP
		if magnus.has_method("play_idle_animation"):
			magnus.play_idle_animation()

	if is_instance_valid(anastasya):
		anastasya.global_position = Vector2(SECRET_LIBRARY_L1_SPAWN.x + 70.0, SECRET_LIBRARY_L1_SPAWN.y + 15.0)
		if "last_direction" in anastasya:
			anastasya.last_direction = Vector2.UP
		if anastasya.has_method("play_idle_animation"):
			anastasya.play_idle_animation()

	# 5. Kunci kamera ke Lantai 1 (force teleport)
	if is_instance_valid(camera):
		camera.global_position = SECRET_LIBRARY_L1_SPAWN
		if camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if camera.has_method("force_update_scroll"):
			camera.force_update_scroll()

	print("[Story] Scene 4: Memasuki Perpustakaan Lantai 1 — menuju tangga.")

	# 6. Buka kontrol agar pemain berjalan ke tangga lalu interact [E]
	_show_library_stair_prompt()


func _show_library_stair_prompt() -> void:
	# Buka gerakan agar pemain bisa jalan ke tangga dan tekan [E]
	set_party_movement_locked(false)
	print("[Story] Scene 4: Silakan berjalan ke tangga kiri dan tekan [E].")


func _pose_scene_4_heroes_looking_at_bookshelf() -> void:
	var arthur: CharacterBody2D = all_heroes.get("Knight_1")
	var magnus: CharacterBody2D = all_heroes.get("Mage_1")
	var anastasya: CharacterBody2D = all_heroes.get("Archer_1")

	var hero_poses: Array[Dictionary] = [
		{"node": magnus, "pos": Vector2(SECRET_LIBRARY_L2_SPAWN.x - 65.0, SECRET_LIBRARY_L2_SPAWN.y + 10.0)},
		{"node": arthur, "pos": SECRET_LIBRARY_L2_SPAWN},
		{"node": anastasya, "pos": Vector2(SECRET_LIBRARY_L2_SPAWN.x + 65.0, SECRET_LIBRARY_L2_SPAWN.y + 10.0)},
	]

	for entry in hero_poses:
		var hero: CharacterBody2D = entry["node"]
		if not is_instance_valid(hero):
			continue
		if not hero.is_inside_tree():
			add_child(hero)
		hero.visible = true
		hero.modulate = Color.WHITE
		hero.global_position = entry["pos"]
		if "velocity" in hero:
			hero.velocity = Vector2.ZERO
		if "last_direction" in hero:
			hero.last_direction = Vector2.UP
		hero.set("is_movement_locked", true)
		if hero.has_method("play_idle_animation"):
			hero.play_idle_animation()


func _go_to_library_floor_2() -> void:
	if is_on_library_floor_2 or is_transitioning:
		return
	set_party_movement_locked(true)

	if gameplay_hud and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)

	var on_midpoint := func() -> void:
		is_on_library_floor_2 = true

		# Tukar lantai: sembunyikan L1, tampilkan L2
		var lib_node := get_node_or_null("SecretLibrary")
		if is_instance_valid(lib_node):
			var floor1 := lib_node.get_node_or_null("LibraryFloor1")
			var floor2 := lib_node.get_node_or_null("LibraryFloor2")
			if floor1: floor1.visible = false
			if floor2: floor2.visible = true

		# Pastikan ketiga hero muncul & berdiri menghadap utara (melihat rak buku)
		update_party_visibility()
		_pose_scene_4_heroes_looking_at_bookshelf()

		# Fokuskan kamera ke Lantai 2
		update_camera_limits_for_location("library")
		if is_instance_valid(camera):
			camera.global_position = SECRET_LIBRARY_L2_SPAWN
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

	var on_completed := func() -> void:
		# Kunci gerak dan pastikan ketiga karakter tetap berdiri menghadap utara
		set_party_movement_locked(true)
		_pose_scene_4_heroes_looking_at_bookshelf()
		print("[Story] Scene 4: Tiba di Lantai 2 — 3 karakter melihat rak buku, mulai Dialog 4A.")

		# Mulai dialog 4A -> Puzzle layar hitam -> Klaim Skill + Dialog 4B -> Lonceng + Dialog 4C
		play_story_dialogue("scene_04a", func():
			_play_scene_4_puzzle_black_screen(func():
				_play_scene_4_claim_skill_and_bell()
			)
		)

	# Transisi fade hitam dari tangga Lantai 1 ke cutscene Lantai 2
	play_black_fade_transition(on_midpoint, on_completed)


func _play_scene_4_puzzle_black_screen(on_done: Callable) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Scene4PuzzleCrawl"
	canvas.layer = 125

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.05, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	vbox.modulate.a = 0.0
	center.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "— MANTRA WARISAN KELUARGA —"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Arthur, Magnus, dan Anastasya menelusuri deretan rak buku kuno...\nBuku-buku bergeser ke susunan yang tepat.\n\nSegel mantra keluarga Magnus berhasil dipecahkan!"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	vbox.add_child(desc_lbl)

	var prompt_lbl := Label.new()
	prompt_lbl.text = "[ Tekan Spasi / Klik untuk Lanjut ]"
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 12)
	prompt_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	vbox.add_child(prompt_lbl)

	add_child(canvas)

	var tw_in := create_tween()
	tw_in.tween_property(bg, "color:a", 1.0, 0.45)
	tw_in.parallel().tween_property(vbox, "modulate:a", 1.0, 0.55)

	var is_closed: Array[bool] = [false]
	var advance_crawl: Callable
	advance_crawl = func():
		if is_closed[0]:
			return
		is_closed[0] = true
		play_sfx(preload("res://assets/audio/sfx/ui/ui_click.wav"), -3.0)
		var tw_out := create_tween()
		tw_out.tween_property(bg, "color:a", 0.0, 0.4)
		tw_out.parallel().tween_property(vbox, "modulate:a", 0.0, 0.3)
		tw_out.tween_callback(func():
			if is_instance_valid(canvas):
				canvas.queue_free()
			if on_done.is_valid():
				on_done.call()
		)

	bg.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			advance_crawl.call()
	)

	var auto_timer := Timer.new()
	auto_timer.wait_time = 3.5
	auto_timer.one_shot = true
	auto_timer.autostart = true
	canvas.add_child(auto_timer)
	auto_timer.timeout.connect(func():
		advance_crawl.call()
	)


func _play_scene_4_claim_skill_and_bell() -> void:
	var magnus: CharacterBody2D = all_heroes.get("Mage_1")
	# Efek visual pendar emas saat Magnus menyerap ilmu Kitab Emas
	if is_instance_valid(magnus):
		var anim_sprite = magnus.get_node_or_null("AnimatedSprite2D")
		if is_instance_valid(anim_sprite):
			var tw_glow := create_tween()
			tw_glow.tween_property(anim_sprite, "modulate", Color(2.5, 2.2, 0.5, 1.0), 0.3)
			tw_glow.tween_property(anim_sprite, "modulate", Color.WHITE, 0.4)

	# Buka skill Meteor Strike pada Magnus
	if is_instance_valid(magnus) and "is_skill_unlocked" in magnus:
		magnus.is_skill_unlocked = true

	# Tampilkan notifikasi pencapaian / unlock skill
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_quest_banner"):
		gameplay_hud.show_quest_banner("SKILL BARU DIBUKA!", "Magnus menyerap Kitab Emas: Meteor Strike!")

	# Dialog 4B: Magnus & Arthur
	play_story_dialogue("scene_04b", func():
		# Mainkan dentang lonceng darurat 3 kali
		_play_emergency_bell_sequence(func():
			# Dialog 4C: Anastasya & Arthur
			play_story_dialogue("scene_04c", func():
				_complete_story_scene_4()
			)
		)
	)


func _play_emergency_bell_sequence(on_finished: Callable) -> void:
	var sfx_bell: AudioStream = preload("res://assets/audio/sfx/ui/start_sword_raise.wav")
	var sfx_alert: AudioStream = preload("res://assets/audio/sfx/enemy/enemy_alert.wav")

	apply_camera_shake(5.0)
	play_sfx(sfx_bell, 2.0)
	play_sfx(sfx_alert, -1.0)

	get_tree().create_timer(0.65).timeout.connect(func():
		apply_camera_shake(6.0)
		play_sfx(sfx_bell, 3.0)
		get_tree().create_timer(0.65).timeout.connect(func():
			apply_camera_shake(7.0)
			play_sfx(sfx_bell, 4.0)
			if on_finished.is_valid():
				on_finished.call()
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func _complete_story_scene_4() -> void:
	var on_midpoint := func() -> void:
		is_scene_4_in_progress = false
		is_scene_4_completed = true
		is_inside_secret_library = false
		is_on_library_floor_2 = false
		is_inside_castle_hall = false
		var spawn_pos := LIBRARY_ENTRANCE_POS + Vector2(0.0, 30.0)
		for i in range(party_members.size()):
			var member = party_members[i]
			if is_instance_valid(member):
				member.global_position = spawn_pos + Vector2(i * 30.0 - 30.0, 0.0)
				member.velocity = Vector2.ZERO
				if "last_direction" in member:
					member.last_direction = Vector2.DOWN
				if member.has_method("play_idle_animation"):
					member.play_idle_animation()
		update_party_visibility()
		update_camera_limits_for_location("outdoor")
		if is_instance_valid(camera):
			camera.global_position = spawn_pos
			camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

	var on_completed := func() -> void:
		set_party_movement_locked(false)
		print("[Story] Scene 4: Perpustakaan Istana selesai! Lonceng berbunyi, bersiap menuju Scene 5 (Gerbang).")
		tracked_quest_id = "main_08"
		if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_quest_navigation"):
			gameplay_hud.set_quest_navigation(CASTLE_ENTRANCE_POS, "Gerbang Depan Istana")

	play_black_fade_transition(on_midpoint, on_completed)


# =========================================================
# PELATIH ALARIC & SISTEM SPARRING CAMP LATIHAN (FLK-007 & FLK-008)
# =========================================================

func _get_or_create_alaric_sprite_frames() -> SpriteFrames:
	if _alaric_sprite_frames_cache != null:
		return _alaric_sprite_frames_cache

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	var anim_configs: Array[Dictionary] = [
		{"name": &"idle_s", "path": "res://assets/characters/npc/alaric/idle-s.png", "count": 4, "speed": 6.0, "loop": true},
		{"name": &"idle_n", "path": "res://assets/characters/npc/alaric/idle-n.png", "count": 4, "speed": 6.0, "loop": true},
		{"name": &"idle_w", "path": "res://assets/characters/npc/alaric/idle-w.png", "count": 4, "speed": 6.0, "loop": true},
		{"name": &"idle_e", "path": "res://assets/characters/npc/alaric/idle-e.png", "count": 4, "speed": 6.0, "loop": true},
		{"name": &"walk_s", "path": "res://assets/characters/npc/alaric/walk-s.png", "count": 8, "speed": 10.0, "loop": true},
		{"name": &"walk_n", "path": "res://assets/characters/npc/alaric/walk-n.png", "count": 8, "speed": 10.0, "loop": true},
		{"name": &"walk_w", "path": "res://assets/characters/npc/alaric/walk-w.png", "count": 8, "speed": 10.0, "loop": true},
		{"name": &"walk_e", "path": "res://assets/characters/npc/alaric/walk-e.png", "count": 8, "speed": 10.0, "loop": true},
		# Serangan Combo 1 (Tebasan Pertama)
		{"name": &"atk_s", "path": "res://assets/characters/npc/alaric/atk-s-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_s_1", "path": "res://assets/characters/npc/alaric/atk-s-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_n", "path": "res://assets/characters/npc/alaric/atk-n-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_n_1", "path": "res://assets/characters/npc/alaric/atk-n-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_w", "path": "res://assets/characters/npc/alaric/atk-w-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_w_1", "path": "res://assets/characters/npc/alaric/atk-w-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_e", "path": "res://assets/characters/npc/alaric/atk-e-1.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_e_1", "path": "res://assets/characters/npc/alaric/atk-e-1.png", "count": 8, "speed": 14.0, "loop": false},
		# Serangan Combo 2 (Tebasan Lanjutan)
		{"name": &"atk_s_2", "path": "res://assets/characters/npc/alaric/atk-s-2.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_n_2", "path": "res://assets/characters/npc/alaric/atk-n-2.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_w_2", "path": "res://assets/characters/npc/alaric/atk-w-2.png", "count": 8, "speed": 14.0, "loop": false},
		{"name": &"atk_e_2", "path": "res://assets/characters/npc/alaric/atk-e-2.png", "count": 8, "speed": 14.0, "loop": false},
		# Skill Khusus Pelatih Tempur
		{"name": &"skill_s", "path": "res://assets/characters/npc/alaric/skill-s.png", "count": 9, "speed": 12.0, "loop": false},
		{"name": &"skill_n", "path": "res://assets/characters/npc/alaric/skill-n.png", "count": 9, "speed": 12.0, "loop": false},
		{"name": &"skill_w", "path": "res://assets/characters/npc/alaric/skill-w.png", "count": 9, "speed": 12.0, "loop": false},
		{"name": &"skill_e", "path": "res://assets/characters/npc/alaric/skill-e.png", "count": 9, "speed": 12.0, "loop": false},
	]

	for cfg in anim_configs:
		var tex := load(cfg["path"]) as Texture2D
		if tex:
			var anim_name: StringName = cfg["name"]
			if not frames.has_animation(anim_name):
				frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, cfg["speed"])
			frames.set_animation_loop(anim_name, cfg["loop"])
			var count: int = cfg["count"]
			for i in range(count):
				var atlas_tex := AtlasTexture.new()
				atlas_tex.atlas = tex
				atlas_tex.region = Rect2(i * 96, 0, 96, 64)
				frames.add_frame(anim_name, atlas_tex)

	_alaric_sprite_frames_cache = frames
	return _alaric_sprite_frames_cache


func _clear_alaric_player_collision_exceptions() -> void:
	if not is_instance_valid(alaric_node):
		return
	var party := get_tree().get_nodes_in_group("player")
	for p in party:
		if is_instance_valid(p) and p is CollisionObject2D:
			alaric_node.remove_collision_exception_with(p)
			p.remove_collision_exception_with(alaric_node)


func _setup_alaric_npc() -> void:
	if is_instance_valid(alaric_node):
		for child in alaric_node.get_children():
			if child is Label or child.name == "AlaricNameplate":
				child.queue_free()
		if not is_alaric_sparring_in_progress:
			alaric_node.global_position = ALARIC_CAMP_POS
			alaric_node.velocity = Vector2.ZERO
			alaric_node.set_physics_process(false)
			alaric_node.last_direction = Vector2.DOWN
			alaric_node.scale = Vector2(5.0, 5.0)
			alaric_node.modulate = Color.WHITE
			alaric_node.y_sort_enabled = true
			alaric_node.z_index = 4
			alaric_node.collision_layer = 1
			alaric_node.collision_mask = 1
			_clear_alaric_player_collision_exceptions.call_deferred()
			var spr = alaric_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if is_instance_valid(spr):
				spr.modulate = Color.WHITE
				spr.sprite_frames = _get_or_create_alaric_sprite_frames()
				spr.offset = Vector2(0, 5)
			if alaric_node.has_method("play_idle_animation"):
				alaric_node.play_idle_animation()
		return

	var knight_scene: PackedScene = load("res://scene/enemy/enemy_knight.tscn")
	if not knight_scene:
		return

	var inst := knight_scene.instantiate() as CharacterBody2D
	if not inst:
		return

	alaric_node = inst
	alaric_node.name = "AlaricTrainerNPC"
	alaric_node.global_position = ALARIC_CAMP_POS
	alaric_node.scale = Vector2(5.0, 5.0)
	alaric_node.modulate = Color.WHITE
	alaric_node.y_sort_enabled = true
	alaric_node.z_index = 4
	alaric_node.collision_layer = 1
	alaric_node.collision_mask = 1
	alaric_node.can_respawn = false
	alaric_node.wait_for_arena = false
	alaric_node.max_health = 600
	alaric_node.current_health = 600
	alaric_node.melee_damage = 25
	alaric_node.melee_attack_range = 100.0

	var anim_spr = alaric_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if is_instance_valid(anim_spr):
		anim_spr.modulate = Color.WHITE
		anim_spr.sprite_frames = _get_or_create_alaric_sprite_frames()
		anim_spr.offset = Vector2(0, 5)

	add_child(alaric_node)

	if not is_alaric_sparring_in_progress:
		alaric_node.remove_from_group("enemy")
		alaric_node.add_to_group("npc")
		alaric_node.set_physics_process(false)
		alaric_node.velocity = Vector2.ZERO
		alaric_node.last_direction = Vector2.DOWN
		_clear_alaric_player_collision_exceptions.call_deferred()
		if alaric_node.has_method("play_idle_animation"):
			alaric_node.play_idle_animation()
		if "health_bar" in alaric_node and is_instance_valid(alaric_node.health_bar):
			alaric_node.health_bar.visible = false
		if "damage_bar" in alaric_node and is_instance_valid(alaric_node.damage_bar):
			alaric_node.damage_bar.visible = false


func _show_alaric_boss_challenge_prompt() -> void:
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)

	if is_instance_valid(_alaric_boss_prompt_layer):
		_alaric_boss_prompt_layer.queue_free()
		_alaric_boss_prompt_layer = null

	set_party_movement_locked(true)

	var cl := CanvasLayer.new()
	cl.layer = 120
	cl.name = "AlaricBossPromptLayer"
	_alaric_boss_prompt_layer = cl
	add_child(cl)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	cl.add_child(root)

	# 1. Dimmer background transparan gelap (Color(0, 0, 0, 0.45) identik SaveConfirmModal)
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.45)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dimmer)

	# 2. Control container center untuk menampung shadow dan kotak dialog
	var center := Control.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	# 3. Shadow Panel (StyleBoxFlat_modal_shadow)
	var shadow := Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.anchor_left = 0.5
	shadow.anchor_top = 0.5
	shadow.anchor_right = 0.5
	shadow.anchor_bottom = 0.5
	shadow.offset_left = -242.0
	shadow.offset_top = -108.0
	shadow.offset_right = 242.0
	shadow.offset_bottom = 114.0
	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = Color(0, 0, 0, 0)
	shadow_sb.shadow_color = Color(0, 0, 0, 0.45)
	shadow_sb.shadow_size = 14
	shadow_sb.shadow_offset = Vector2(0, 6)
	shadow_sb.set_corner_radius_all(6)
	shadow.add_theme_stylebox_override("panel", shadow_sb)
	center.add_child(shadow)

	# 4. DialogBox (NinePatchRect persis Atlas_modal_dialog_frame Rect2(0, 500, 32, 32))
	var ui_sheet: Texture2D = load("res://assets/ui/menus/common/ui_menu_sheet.png")
	var arrow_tex: Texture2D = load("res://assets/ui/menus/common/ui_arrow_indicator.png")

	var dialog_box := NinePatchRect.new()
	dialog_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dialog_box.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_box.anchor_left = 0.5
	dialog_box.anchor_top = 0.5
	dialog_box.anchor_right = 0.5
	dialog_box.anchor_bottom = 0.5
	dialog_box.offset_left = -240.0
	dialog_box.offset_top = -110.0
	dialog_box.offset_right = 240.0
	dialog_box.offset_bottom = 110.0
	dialog_box.patch_margin_left = 10
	dialog_box.patch_margin_top = 10
	dialog_box.patch_margin_right = 10
	dialog_box.patch_margin_bottom = 10
	if ui_sheet:
		var frame_atlas := AtlasTexture.new()
		frame_atlas.atlas = ui_sheet
		frame_atlas.region = Rect2(0, 500, 32, 32)
		dialog_box.texture = frame_atlas
	center.add_child(dialog_box)

	# 5. DialogTitle ("Konfirmasi" persis SaveConfirmModal)
	var title_lbl := Label.new()
	title_lbl.anchor_left = 0.0
	title_lbl.anchor_right = 1.0
	title_lbl.offset_top = 18.0
	title_lbl.offset_bottom = 46.0
	title_lbl.text = "Konfirmasi"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
	if UI_FONT_BEHOLDEN:
		title_lbl.add_theme_font_override("font", UI_FONT_BEHOLDEN)
	dialog_box.add_child(title_lbl)

	# 6. HeaderDivider (Dots Divider ala SaveConfirmModal)
	var div_row := HBoxContainer.new()
	div_row.anchor_left = 0.0
	div_row.anchor_right = 1.0
	div_row.offset_top = 47.0
	div_row.offset_bottom = 56.0
	div_row.alignment = BoxContainer.ALIGNMENT_CENTER
	div_row.set("theme_override_constants/separation", 8)
	div_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ui_sheet:
		var dots_atlas := AtlasTexture.new()
		dots_atlas.atlas = ui_sheet
		dots_atlas.region = Rect2(65, 263, 30, 3)

		var dots_l := TextureRect.new()
		dots_l.texture = dots_atlas
		dots_l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dots_l.custom_minimum_size = Vector2(48, 9)
		dots_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dots_l.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dots_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		div_row.add_child(dots_l)

		var dots_r := TextureRect.new()
		dots_r.texture = dots_atlas
		dots_r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dots_r.custom_minimum_size = Vector2(48, 9)
		dots_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dots_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dots_r.flip_h = true
		dots_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		div_row.add_child(dots_r)
	dialog_box.add_child(div_row)

	# 7. DialogMessage (Dinaikkan agar berjarak proporsional dengan tombol Ya & Tidak)
	var desc_lbl := Label.new()
	desc_lbl.anchor_left = 0.0
	desc_lbl.anchor_right = 1.0
	desc_lbl.anchor_top = 0.5
	desc_lbl.anchor_bottom = 0.5
	desc_lbl.offset_left = 20.0
	desc_lbl.offset_top = -52.0
	desc_lbl.offset_right = -20.0
	desc_lbl.offset_bottom = 10.0
	desc_lbl.text = "Pelatih Alaric adalah ksatria veteran berilmu tinggi (Boss)!\nApakah kau siap menantangnya bertarung di arena tempur?"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_constant_override("line_spacing", 2)
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.26, 1.0))
	if UI_FONT_BEHOLDEN:
		desc_lbl.add_theme_font_override("font", UI_FONT_BEHOLDEN)
	dialog_box.add_child(desc_lbl)

	# 8. ButtonsRow (HBoxContainer)
	var btn_row := HBoxContainer.new()
	btn_row.anchor_left = 0.0
	btn_row.anchor_right = 1.0
	btn_row.anchor_top = 1.0
	btn_row.anchor_bottom = 1.0
	btn_row.offset_top = -64.0
	btn_row.offset_bottom = -24.0
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.set("theme_override_constants/separation", 32)
	dialog_box.add_child(btn_row)

	var btn_normal_atlas: AtlasTexture = null
	var btn_hover_atlas: AtlasTexture = null
	if ui_sheet:
		btn_normal_atlas = AtlasTexture.new()
		btn_normal_atlas.atlas = ui_sheet
		btn_normal_atlas.region = Rect2(145, 433, 62, 14)

		btn_hover_atlas = AtlasTexture.new()
		btn_hover_atlas.atlas = ui_sheet
		btn_hover_atlas.region = Rect2(65, 449, 62, 14)

	var create_modal_btn = func(text_label: String) -> Dictionary:
		var btn_box := NinePatchRect.new()
		btn_box.custom_minimum_size = Vector2(104, 38)
		btn_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn_box.texture = btn_normal_atlas
		btn_box.patch_margin_left = 5
		btn_box.patch_margin_top = 4
		btn_box.patch_margin_right = 5
		btn_box.patch_margin_bottom = 4

		var lbl := Label.new()
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.text = text_label
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
		if UI_FONT_BEHOLDEN:
			lbl.add_theme_font_override("font", UI_FONT_BEHOLDEN)
		btn_box.add_child(lbl)

		var arrow := TextureRect.new()
		arrow.texture = arrow_tex
		arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arrow.position = Vector2(-18.0, 13.5)
		arrow.size = Vector2(9.0, 11.0)
		arrow.stretch_mode = TextureRect.STRETCH_KEEP
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.visible = false
		btn_box.add_child(arrow)

		var click_btn := TextureButton.new()
		click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_box.add_child(click_btn)

		return {
			"box": btn_box,
			"label": lbl,
			"arrow": arrow,
			"click": click_btn
		}

	var btn_yes_data: Dictionary = create_modal_btn.call("Ya")
	var btn_no_data: Dictionary = create_modal_btn.call("Tidak")

	btn_row.add_child(btn_yes_data["box"])
	btn_row.add_child(btn_no_data["box"])

	var buttons: Array = [btn_yes_data, btn_no_data]
	var selected_idx: Array = [0]

	var update_btn_visuals = func():
		for i in range(buttons.size()):
			var b_data: Dictionary = buttons[i]
			var is_sel: bool = (i == selected_idx[0])
			var box: NinePatchRect = b_data["box"]
			var lbl: Label = b_data["label"]
			var arrow: TextureRect = b_data["arrow"]
			if is_sel:
				box.texture = btn_hover_atlas if btn_hover_atlas else btn_normal_atlas
				box.modulate = Color(1.0, 1.0, 1.0, 1.0)
				lbl.add_theme_color_override("font_color", Color(0.24, 0.15, 0.16, 1.0))
				arrow.visible = true
			else:
				box.texture = btn_normal_atlas
				box.modulate = Color(0.85, 0.82, 0.78, 1.0)
				lbl.add_theme_color_override("font_color", Color(0.48, 0.38, 0.38, 1.0))
				arrow.visible = false

	update_btn_visuals.call()

	var sfx_hover: AudioStream = load("res://assets/audio/sfx/ui/ui_hover.wav")
	var sfx_click: AudioStream = load("res://assets/audio/sfx/ui/ui_click.wav")
	var sfx_book_select: AudioStream = load("res://assets/audio/sfx/ui/book_tab_select.wav")

	var close_popup = func():
		_alaric_boss_modal_input_cb = Callable()
		if is_instance_valid(_alaric_boss_prompt_layer):
			_alaric_boss_prompt_layer.queue_free()
			_alaric_boss_prompt_layer = null
		set_party_movement_locked(false)
		var lead := get_active_leader()
		if is_instance_valid(lead):
			_set_character_collision_active(lead, true)
			lead.set_physics_process(true)
			lead.set_process_unhandled_input(true)

	var confirm_action = func():
		if sfx_click and has_method("play_sfx"):
			play_sfx(sfx_click, -2.0)
		close_popup.call()
		_teleport_to_arena_kamp_and_fight()

	var cancel_action = func():
		if sfx_book_select and has_method("play_sfx"):
			play_sfx(sfx_book_select, -3.5)
		elif sfx_click and has_method("play_sfx"):
			play_sfx(sfx_click, -2.0)
		close_popup.call()

	(btn_yes_data["click"] as TextureButton).pressed.connect(confirm_action)
	(btn_no_data["click"] as TextureButton).pressed.connect(cancel_action)

	(btn_yes_data["click"] as TextureButton).mouse_entered.connect(func():
		if selected_idx[0] != 0:
			selected_idx[0] = 0
			update_btn_visuals.call()
			if sfx_hover and has_method("play_sfx"):
				play_sfx(sfx_hover, -4.0)
	)
	(btn_no_data["click"] as TextureButton).mouse_entered.connect(func():
		if selected_idx[0] != 1:
			selected_idx[0] = 1
			update_btn_visuals.call()
			if sfx_hover and has_method("play_sfx"):
				play_sfx(sfx_hover, -4.0)
	)

	dimmer.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := event as InputEventMouseButton
			if is_instance_valid(dialog_box) and not dialog_box.get_global_rect().has_point(mb.global_position):
				cancel_action.call()
	)

	_alaric_boss_modal_input_cb = func(event: InputEvent) -> bool:
		if not (event is InputEventKey):
			return false
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return false
		var kc: int = ke.keycode
		if kc == 0:
			kc = ke.physical_keycode
		if kc == KEY_LEFT or kc == KEY_A:
			if selected_idx[0] != 0:
				selected_idx[0] = 0
				update_btn_visuals.call()
				if sfx_hover and has_method("play_sfx"):
					play_sfx(sfx_hover, -4.0)
			return true
		elif kc == KEY_RIGHT or kc == KEY_D:
			if selected_idx[0] != 1:
				selected_idx[0] = 1
				update_btn_visuals.call()
				if sfx_hover and has_method("play_sfx"):
					play_sfx(sfx_hover, -4.0)
			return true
		elif kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE or kc == KEY_E:
			if selected_idx[0] == 0:
				confirm_action.call()
			else:
				cancel_action.call()
			return true
		elif kc == KEY_ESCAPE:
			cancel_action.call()
			return true
		return true


func _start_alaric_pre_fight_dialogue() -> void:
	if is_alaric_sparring_in_progress or is_transitioning:
		return

	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)

	if selected_game_mode == "open_world":
		_show_alaric_boss_challenge_prompt()
		return

	set_party_movement_locked(true)
	var leader := get_active_leader()
	if is_instance_valid(alaric_node) and is_instance_valid(leader):
		var dir: Vector2 = (leader.global_position - alaric_node.global_position).normalized()
		if alaric_node.has_method("get_8_direction"):
			alaric_node.last_direction = alaric_node.get_8_direction(dir)
		if alaric_node.has_method("play_idle_animation"):
			alaric_node.play_idle_animation()

	if is_alaric_sparring_completed:
		play_story_dialogue("FLK-008", func():
			set_party_movement_locked(false)
			var cur_lead := get_active_leader()
			if is_instance_valid(cur_lead):
				_set_character_collision_active(cur_lead, true)
				cur_lead.set_physics_process(true)
				cur_lead.set_process_unhandled_input(true)
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_quest_navigation"):
				gameplay_hud.set_quest_navigation(GRAVEYARD_POS, "Makam Ksatria Lancelot")
		)
		return

	# Dialog FLK-007 di Kamp Pelatihan, setelah selesai teleport ke Arena Kamp untuk duel
	play_story_dialogue("FLK-007", func():
		_teleport_to_arena_kamp_and_fight()
	)


func _teleport_to_arena_kamp_and_fight() -> void:
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)

	# Mode Cerita & Mode Jelajah: Hanya Knight_1 (Arthur) yang berduel melawan Pelatih Alaric di arena!
	var knight_hero: CharacterBody2D = all_heroes.get("Knight_1")
	party_members.clear()
	if is_instance_valid(knight_hero):
		if not knight_hero.is_inside_tree():
			add_child(knight_hero)
		party_members.append(knight_hero)
		knight_hero.visible = true
		knight_hero.modulate.a = 1.0
		knight_hero.is_dead = false
		if "current_health" in knight_hero and "max_health" in knight_hero and knight_hero.current_health <= 0:
			knight_hero.current_health = knight_hero.max_health
		knight_hero.set_physics_process(true)
		knight_hero.set_process_unhandled_input(true)
		_set_character_collision_active(knight_hero, true)
		if knight_hero.has_method("set_as_leader"):
			knight_hero.set_as_leader(true, null, 0)
	active_leader_index = 0

	# Keluarkan karakter lain dari arena dan scene tree agar tidak ikut bertarung
	var other_hero_names: Array[String] = ["Bandit_1", "Archer_1", "Mage_1"]
	for oh_name in other_hero_names:
		var oh: CharacterBody2D = all_heroes.get(oh_name)
		if is_instance_valid(oh):
			if oh.has_method("set_as_leader"):
				oh.set_as_leader(false, knight_hero, 1)
			if oh.has_method("set_party_combat_mode"):
				oh.set_party_combat_mode(false)
			oh.visible = false
			oh.set_physics_process(false)
			oh.set_process_unhandled_input(false)
			_set_character_collision_active(oh, false)
			if oh.is_inside_tree():
				remove_child(oh)

	setup_party_enemy_collision_exceptions.call_deferred()

	if is_instance_valid(gameplay_hud):
		if gameplay_hud.has_method("update_party_order"):
			gameplay_hud.update_party_order(party_members, 0)
		elif gameplay_hud.has_method("update_party_hud"):
			gameplay_hud.party_members = party_members
			gameplay_hud.update_party_hud()
			if gameplay_hud.has_method("update_leader_indicator"):
				gameplay_hud.update_leader_indicator()

	play_black_fade_transition(
		func():
			is_in_arena_kamp = true
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt(true)

			for i in range(party_members.size()):
				var member: CharacterBody2D = party_members[i]
				if is_instance_valid(member):
					if not member.is_inside_tree():
						add_child(member)
					member.visible = true
					member.modulate.a = 1.0
					var offset_pos := Vector2(-70.0 * i, 30.0 * (1 if i % 2 == 1 else -1)) if i > 0 else Vector2.ZERO
					member.global_position = ARENA_KAMP_ARTHUR_POS + offset_pos
					member.velocity = Vector2.ZERO
					if "last_direction" in member:
						member.last_direction = Vector2.RIGHT
					if member.has_method("play_idle_animation"):
						member.play_idle_animation()
					_set_character_collision_active(member, true)
					member.set_physics_process(true)
					if member.has_method("set_party_combat_mode"):
						member.set_party_combat_mode(true)

			if is_instance_valid(alaric_node):
				alaric_node.global_position = ARENA_KAMP_ALARIC_POS
				alaric_node.velocity = Vector2.ZERO
				alaric_node.last_direction = Vector2.LEFT
				if alaric_node.has_method("play_idle_animation"):
					alaric_node.play_idle_animation()
				_clear_alaric_player_collision_exceptions.call_deferred()

			update_camera_limits_for_location("arena_kamp")
			if is_instance_valid(camera):
				camera.global_position = ARENA_KAMP_CENTER_POS
				camera.reset_smoothing()
				if camera.has_method("force_update_scroll"):
					camera.force_update_scroll()

			enter_location("Arena Kamp Pelatihan"),
		func():
			_start_alaric_sparring_match()
	)


func _start_alaric_sparring_match() -> void:
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)
	set_party_movement_locked(false)
	var leader := get_active_leader()
	for member in party_members:
		if is_instance_valid(member):
			_set_character_collision_active(member, true)
			member.set_physics_process(true)
			member.set_process_unhandled_input(true)
			if member.has_method("set_party_combat_mode"):
				member.set_party_combat_mode(true)

	is_alaric_sparring_in_progress = true

	if is_instance_valid(alaric_node):
		alaric_node.remove_from_group("npc")
		alaric_node.add_to_group("enemy")
		alaric_node.set_physics_process(true)
		alaric_node.current_health = alaric_node.max_health
		if "health_bar" in alaric_node and is_instance_valid(alaric_node.health_bar):
			alaric_node.health_bar.visible = true
			alaric_node.health_bar.max_value = alaric_node.max_health
			alaric_node.health_bar.value = alaric_node.current_health
		if "damage_bar" in alaric_node and is_instance_valid(alaric_node.damage_bar):
			alaric_node.damage_bar.visible = true
			alaric_node.damage_bar.max_value = alaric_node.max_health
			alaric_node.damage_bar.value = alaric_node.current_health
		if leader and alaric_node.has_method("alert_to_combat"):
			alaric_node.alert_to_combat(leader)

	notify_party_combat_state(true)
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(true, true)


func check_alaric_sparring_status(_delta: float) -> void:
	if not is_alaric_sparring_in_progress or not is_instance_valid(alaric_node) or is_transitioning:
		return

	var hp_threshold: int = int(alaric_node.max_health * 0.2)
	var is_alaric_down: bool = false
	if "is_dead" in alaric_node and alaric_node.is_dead:
		is_alaric_down = true
	elif "current_health" in alaric_node and alaric_node.current_health <= hp_threshold:
		is_alaric_down = true

	var leader := get_active_leader()
	var is_leader_low: bool = false
	if is_instance_valid(leader):
		var leader_threshold: int = int(leader.max_health * 0.2) if "max_health" in leader else 100
		if "is_dead" in leader and leader.is_dead:
			is_leader_low = true
		elif "current_health" in leader and leader.current_health <= leader_threshold:
			is_leader_low = true

	if is_alaric_down or is_leader_low:
		_end_alaric_sparring_match()


func _end_alaric_sparring_match() -> void:
	is_alaric_sparring_in_progress = false
	is_alaric_sparring_completed = true
	active_combat_targets = []

	if is_instance_valid(alaric_node):
		alaric_node.remove_from_group("enemy")
		alaric_node.add_to_group("npc")
		alaric_node.is_dead = false
		alaric_node.visible = true
		alaric_node.modulate = Color.WHITE
		var anim_spr := alaric_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if is_instance_valid(anim_spr):
			anim_spr.modulate = Color.WHITE
		alaric_node.current_health = alaric_node.max_health
		alaric_node.velocity = Vector2.ZERO
		alaric_node.set_physics_process(false)
		alaric_node.collision_layer = 1
		alaric_node.collision_mask = 1
		_clear_alaric_player_collision_exceptions.call_deferred()
		if "collision_shape" in alaric_node and is_instance_valid(alaric_node.collision_shape):
			alaric_node.collision_shape.set_deferred("disabled", false)
		if "health_bar" in alaric_node and is_instance_valid(alaric_node.health_bar):
			alaric_node.health_bar.visible = false
		if "damage_bar" in alaric_node and is_instance_valid(alaric_node.damage_bar):
			alaric_node.damage_bar.visible = false

	notify_party_combat_state(false)
	for member in party_members:
		if is_instance_valid(member):
			if member.has_method("reset_combat_skills"):
				member.reset_combat_skills()
			if "current_health" in member and "max_health" in member and member.current_health <= 0:
				member.current_health = member.max_health
				member.is_dead = false
				member.visible = true
				member.modulate.a = 1.0

	var leader := get_active_leader()
	if is_instance_valid(leader):
		if "current_health" in leader and "max_health" in leader:
			leader.current_health = leader.max_health
		leader.velocity = Vector2.ZERO

	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(false, false)

	set_party_movement_locked(true)
	_teleport_back_to_training_camp()


func _teleport_back_to_training_camp() -> void:
	play_black_fade_transition(
		func():
			is_in_arena_kamp = false
			if selected_game_mode == "open_world":
				# Mode Jelajah: Kembalikan seluruh 4 anggota party setelah duel solo Knight selesai
				var all_hero_names: Array[String] = ["Knight_1", "Bandit_1", "Archer_1", "Mage_1"]
				for h_name in all_hero_names:
					var hero: CharacterBody2D = all_heroes.get(h_name)
					if is_instance_valid(hero):
						if hero not in party_members:
							party_members.append(hero)
						hero.modulate.a = 1.0
						hero.is_dead = false
						if "current_health" in hero and "max_health" in hero and hero.current_health <= 0:
							hero.current_health = hero.max_health
						if hero.has_method("reset_combat_skills"):
							hero.reset_combat_skills()
				for i in range(party_members.size()):
					for j in range(i + 1, party_members.size()):
						party_members[i].add_collision_exception_with(party_members[j])
						party_members[j].add_collision_exception_with(party_members[i])
				setup_party_enemy_collision_exceptions.call_deferred()
				if is_instance_valid(gameplay_hud):
					if gameplay_hud.has_method("update_party_order"):
						gameplay_hud.update_party_order(party_members, active_leader_index)
					elif gameplay_hud.has_method("update_party_hud"):
						gameplay_hud.party_members = party_members
						gameplay_hud.update_party_hud()
						if gameplay_hud.has_method("update_leader_indicator"):
							gameplay_hud.update_leader_indicator()

			for i in range(party_members.size()):
				var member: CharacterBody2D = party_members[i]
				if is_instance_valid(member):
					var offset_pos := Vector2(-70.0 * i, 0.0) if i > 0 else Vector2.ZERO
					member.global_position = ARTHUR_CAMP_RETURN_POS + offset_pos
					member.velocity = Vector2.ZERO
					if "last_direction" in member:
						member.last_direction = Vector2.RIGHT
					if member.has_method("play_idle_animation"):
						member.play_idle_animation()

			if is_instance_valid(alaric_node):
				alaric_node.global_position = ALARIC_CAMP_POS
				alaric_node.velocity = Vector2.ZERO
				alaric_node.last_direction = Vector2.LEFT
				alaric_node.modulate = Color.WHITE
				var anim_spr := alaric_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
				if is_instance_valid(anim_spr):
					anim_spr.modulate = Color.WHITE
				if alaric_node.has_method("play_idle_animation"):
					alaric_node.play_idle_animation()
				_clear_alaric_player_collision_exceptions.call_deferred()

			update_camera_limits_for_location("outdoor")
			if is_instance_valid(camera):
				camera.global_position = ARTHUR_CAMP_RETURN_POS
				camera.reset_smoothing()
				if camera.has_method("force_update_scroll"):
					camera.force_update_scroll()

			enter_location("Camp Latihan Istana"),
		func():
			if selected_game_mode == "open_world":
				set_party_movement_locked(false)
				var leader := get_active_leader()
				if is_instance_valid(leader):
					_set_character_collision_active(leader, true)
					leader.set_physics_process(true)
					leader.set_process_unhandled_input(true)
				update_party_visibility()
			else:
				set_party_movement_locked(true)
				play_story_dialogue("FLK-008", func():
					_on_alaric_post_fight_dialogue_finished()
				)
	)


func _on_alaric_post_fight_dialogue_finished() -> void:
	set_party_movement_locked(false)
	var leader := get_active_leader()
	if is_instance_valid(leader):
		_set_character_collision_active(leader, true)
		leader.set_physics_process(true)
		leader.set_process_unhandled_input(true)
	if is_instance_valid(alaric_node):
		alaric_node.modulate = Color.WHITE
		var anim_spr := alaric_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if is_instance_valid(anim_spr):
			anim_spr.modulate = Color.WHITE

	for q in quest_list:
		if q.get("id") == "main_03":
			q["status"] = "completed"
		elif q.get("id") == "main_04":
			q["status"] = "active"
	tracked_quest_id = "main_04"

	if is_instance_valid(gameplay_hud):
		if gameplay_hud.has_method("set_quests"):
			gameplay_hud.set_quests(quest_list, tracked_quest_id)
		var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
		if not tracked_q.is_empty() and gameplay_hud.has_method("update_hud_quest_display"):
			gameplay_hud.update_hud_quest_display(tracked_q)
		if gameplay_hud.has_method("set_quest_navigation"):
			gameplay_hud.set_quest_navigation(GRAVEYARD_POS, "Makam Ksatria Lancelot")

	save_game_to_slot(1)


func _setup_meeting_participants() -> void:
	var hall := get_node_or_null("CastleMeetingHall") as Node2D
	if not hall:
		return

	# Jangan duplikasi jika sudah diinstansiasi
	if hall.has_node("Participant_King"):
		return

	# Tekstur sprite karakter
	var tex_king: Texture2D = load("res://assets/characters/npc/king/idle-s.png")
	var tex_queen: Texture2D = load("res://assets/characters/npc/queen/idle-s.png")
	var tex_mage_e: Texture2D = load("res://assets/characters/mage/idle/idle-e.png")
	var tex_archer_w: Texture2D = load("res://assets/characters/archer/idle/idle-w.png")

	# 1. Raja (TopChair2 - Atas Tengah)
	# Disortir di Y = -50 (di depan TopChair Y = -92.5 dan di belakang Meja Y = 12.5)
	# offset.y = -3.6 menggeser visual 18px ke atas agar pas di bantalan kursi
	if tex_king:
		var king := _create_meeting_npc(tex_king, 96, 64, 4, Vector2(0, -50), "idle_s", Color.WHITE, Vector2(0, -3.6))
		king.name = "Participant_King"
		hall.add_child(king)

	# 2. Ratu (TopChair1 - Atas Kiri)
	if tex_queen:
		var queen := _create_meeting_npc(tex_queen, 96, 64, 4, Vector2(-220, -50), "idle_s", Color.WHITE, Vector2(0, -3.6))
		queen.name = "Participant_Queen"
		hall.add_child(queen)

	# 3. Peramal 1 - Wizandy (Di sebelah kanan pilar besar kiri)
	var tex_wizandy: Texture2D = load("res://assets/characters/npc/seer/Wizandy.png")
	if tex_wizandy:
		var seer1 := Sprite2D.new()
		seer1.texture = tex_wizandy
		seer1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		seer1.scale = Vector2(5.0, 5.0)
		seer1.position = Vector2(-360.0, -180.0)
		seer1.name = "Participant_Peramal1"
		seer1.z_index = 5
		hall.add_child(seer1)

	# 4. Magnus / Wizard (SideChairLeft - Samping Kiri)
	# Disortir di Y = 15 (di depan SideChair Y = -7.5)
	# offset.y = -7.0 menggeser visual agar duduk pas di atas alas kursi
	if tex_mage_e:
		var magnus := _create_meeting_npc(tex_mage_e, 96, 64, 4, Vector2(-345, 15), "idle_e", Color.WHITE, Vector2(-0.5, -7.0))
		magnus.name = "Participant_Magnus"
		hall.add_child(magnus)

	# 5. Anastasya / Archer (SideChairRight - Samping Kanan)
	# offset.y = -7.0 menggeser visual agar duduk pas di atas alas kursi
	if tex_archer_w:
		var anastasya := _create_meeting_npc(tex_archer_w, 32, 32, 4, Vector2(340, 15), "idle_w", Color.WHITE, Vector2(-1, -7.0))
		anastasya.name = "Participant_Anastasya"
		hall.add_child(anastasya)

	# Pastikan kursi dan furnitur baris bawah berada di z_index = 5 agar sandaran kursi menutupi karakter di baliknya
	var table_bottom = hall.get_node_or_null("TableBottomFurniture") as CanvasItem
	if is_instance_valid(table_bottom):
		table_bottom.z_index = 5
	var table_main = hall.get_node_or_null("MeetingTableFurniture") as CanvasItem
	if is_instance_valid(table_main):
		table_main.z_index = 5
	for chair_name in ["BottomChair1", "BottomChair2", "BottomChair3"]:
		var chair = hall.get_node_or_null(chair_name) as CanvasItem
		if is_instance_valid(chair):
			chair.z_index = 5

	# 6. Peramal 2 - Wizashley (Di sebelah kiri pilar besar kanan)
	var tex_wizashley: Texture2D = load("res://assets/characters/npc/seer/Wizashley.png")
	if tex_wizashley:
		var seer2 := Sprite2D.new()
		seer2.texture = tex_wizashley
		seer2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		seer2.scale = Vector2(5.0, 5.0)
		seer2.position = Vector2(360.0, -180.0)
		seer2.name = "Participant_Peramal2"
		seer2.z_index = 5
		hall.add_child(seer2)


func _create_meeting_npc(
	tex: Texture2D,
	frame_w: int,
	frame_h: int,
	frame_count: int,
	pos: Vector2,
	anim_name: String,
	mod_color: Color = Color.WHITE,
	spr_offset: Vector2 = Vector2.ZERO
) -> AnimatedSprite2D:
	var anim_spr := AnimatedSprite2D.new()
	anim_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_spr.scale = Vector2(5.0, 5.0)
	anim_spr.position = pos
	anim_spr.modulate = mod_color
	anim_spr.offset = spr_offset
	anim_spr.z_index = 4

	var frames := SpriteFrames.new()
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, 6.0)

	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		frames.add_frame(anim_name, atlas)

	anim_spr.sprite_frames = frames
	anim_spr.play(anim_name)
	return anim_spr



func _setup_open_world_mode() -> void:
	is_prologue_completed = true
	tracked_quest_id = ""

	# Pastikan seluruh 4 hero terdaftar di party_members di mode jelajah
	var names: Array[String] = ["Knight_1", "Bandit_1", "Archer_1", "Mage_1"]
	var roster_changed: bool = false
	for n in names:
		if all_heroes.has(n) and all_heroes[n] not in party_members:
			party_members.append(all_heroes[n])
			roster_changed = true

	if roster_changed:
		for i in range(party_members.size()):
			for j in range(i + 1, party_members.size()):
				party_members[i].add_collision_exception_with(party_members[j])
				party_members[j].add_collision_exception_with(party_members[i])
		setup_party_enemy_collision_exceptions.call_deferred()
		update_party_visibility()
		if gameplay_hud:
			if gameplay_hud.has_method("update_party_order"):
				gameplay_hud.update_party_order(party_members, active_leader_index)
			else:
				gameplay_hud.party_members = party_members
				gameplay_hud.update_party_hud()
				gameplay_hud.update_leader_indicator()

	if gameplay_hud:
		if gameplay_hud.has_method("set_open_world_mode"):
			gameplay_hud.set_open_world_mode(true)
		if gameplay_hud.has_method("hide_quest_navigation"):
			gameplay_hud.hide_quest_navigation()

	var marker = get_node_or_null("CastleObjectiveMarker")
	if marker:
		marker.visible = false
	if is_instance_valid(_nav_compass):
		_nav_compass.visible = false


func set_party_movement_locked(locked: bool) -> void:
	for member in party_members:
		if is_instance_valid(member):
			member.set("is_movement_locked", locked)
			if locked:
				if "velocity" in member:
					member.velocity = Vector2.ZERO
				if member.has_method("play_idle_animation"):
					member.play_idle_animation()


func save_game_to_slot(slot_id: int) -> bool:
	var path_tmp := "user://save_slot_%d.json.tmp" % slot_id
	var _path_final := "user://save_slot_%d.json" % slot_id

	var data := _collect_save_data(slot_id)
	var json_str := JSON.stringify(data, "\t")

	var f := FileAccess.open(path_tmp, FileAccess.WRITE)
	if not f:
		push_error("Gagal membuka file temporary save: " + path_tmp)
		return false
	f.store_string(json_str)
	f.close()

	var dir := DirAccess.open("user://")
	if dir:
		if dir.file_exists("save_slot_%d.json" % slot_id):
			dir.remove("save_slot_%d.json" % slot_id)
		var err := dir.rename("save_slot_%d.json.tmp" % slot_id, "save_slot_%d.json" % slot_id)
		if err != OK:
			push_error("Gagal rename save file: %d" % err)
			return false

	print("GAME SAVED: Slot %d | %s | %s" % [slot_id, data.get("chapter"), data.get("save_time_str")])
	if gameplay_hud and gameplay_hud.has_method("on_save_completed"):
		gameplay_hud.on_save_completed(slot_id, data)
	return true


func load_game_from_slot(slot_id: int) -> bool:
	var path := "user://save_slot_%d.json" % slot_id
	if not FileAccess.file_exists(path):
		push_error("File save tidak ditemukan: " + path)
		return false

	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_error("Gagal membuka file save: " + path)
		return false
	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or not (json.data is Dictionary):
		push_error("Data save rusak atau tidak valid pada Slot %d" % slot_id)
		return false

	var data: Dictionary = json.data
	if not data.has("party") or not data.has("chapter"):
		push_error("Struktur data save tidak lengkap pada Slot %d" % slot_id)
		return false

	# Restore Game Mode
	if data.has("game_mode"):
		selected_game_mode = str(data["game_mode"])
	elif str(data.get("chapter", "")) == "Mode Jelajah":
		selected_game_mode = "open_world"
	else:
		selected_game_mode = "story"

	# Restore Playtime
	total_playtime = float(data.get("playtime", 0.0))
	is_prologue_completed = bool(data.get("is_prologue_completed", true))
	if is_prologue_completed:
		_cleanup_prologue_entities()
	is_castle_meeting_completed = bool(data.get("is_castle_meeting_completed", false))
	is_knight_room_completed = bool(data.get("is_knight_room_completed", false))
	is_alaric_sparring_completed = bool(data.get("is_alaric_sparring_completed", false))

	# Restore Party Order, Positions, Health
	var restored_party: Array[CharacterBody2D] = []
	for p_info in data.get("party", []):
		var char_name: String = p_info.get("name", "")
		var target_hero: CharacterBody2D = null
		if all_heroes.has(char_name):
			target_hero = all_heroes[char_name]
		else:
			for child in get_children():
				if child is CharacterBody2D and child.name == char_name:
					target_hero = child
					break
		if is_instance_valid(target_hero):
			var child := target_hero
			restored_party.append(child)
			if p_info.has("position"):
				var pos_dict: Dictionary = p_info["position"]
				child.global_position = Vector2(float(pos_dict.get("x", child.global_position.x)), float(pos_dict.get("y", child.global_position.y)))
			if "target_position" in child:
				child.target_position = child.global_position
			if "velocity" in child:
				child.velocity = Vector2.ZERO
			if "max_health" in child and p_info.has("max_hp"):
				child.max_health = int(p_info["max_hp"])
			if "current_health" in child and p_info.has("hp"):
				child.current_health = int(p_info["hp"])
			if "current_health" in child and "is_dead" in child:
				if child.current_health <= 0:
					child.is_dead = true
					child.visible = false
					child.modulate = Color(0.8, 0.2, 0.2, 0.0)
					if "collision_shape" in child and child.collision_shape:
						child.collision_shape.set_deferred("disabled", true)
					if child.has_node("Hurtbox/CollisionShape2D"):
						child.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", true)
				else:
					child.is_dead = false
					child.visible = true
					child.modulate = Color.WHITE
					if "collision_shape" in child and child.collision_shape:
						child.collision_shape.set_deferred("disabled", false)
					if child.has_node("Hurtbox/CollisionShape2D"):
						child.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", false)
					if not child.is_in_group("player"):
						child.add_to_group("player")
			if "skill_cooldown_timer" in child:
				child.skill_cooldown_timer = 0.0

	if not restored_party.is_empty():
		party_members = restored_party

	# Restore Leader
	var lead_idx: int = clampi(int(data.get("active_leader_index", 0)), 0, party_members.size() - 1)
	set_active_leader(lead_idx)

	# Reset breadcrumbs and camera smoothing around restored leader position
	var leader := get_active_leader()
	if is_instance_valid(leader):
		breadcrumbs.clear()
		if is_instance_valid(camera):
			camera.reset_smoothing()

	# Restore Inventory
	if data.has("inventory_items") and data["inventory_items"] is Array:
		inventory_items = _deserialize_inventory(data["inventory_items"])

	# Restore Quests
	if data.has("quest_list") and data["quest_list"] is Array:
		quest_list = _deserialize_quests(data["quest_list"])
	for q in quest_list:
		if q.get("id") == "main_03":
			q["target_position"] = ALARIC_CAMP_POS
		elif q.get("id") == "main_04":
			q["target_position"] = GRAVEYARD_POS
	if data.has("tracked_quest_id"):
		tracked_quest_id = str(data["tracked_quest_id"])

	# Restore Location & Visited History
	current_location_name = str(data.get("current_location_name", DEFAULT_START_LOCATION)).strip_edges()
	if current_location_name.is_empty():
		current_location_name = DEFAULT_START_LOCATION
	visited_locations.clear()
	if data.has("visited_locations") and data["visited_locations"] is Array:
		for v_loc in data["visited_locations"]:
			var loc_str := str(v_loc).strip_edges()
			if not loc_str.is_empty() and not visited_locations.has(loc_str):
				visited_locations.append(loc_str)
	else:
		visited_locations.append(current_location_name)

	# Sync HUD & Unpause
	get_tree().paused = false
	if gameplay_hud:
		if gameplay_hud.has_method("hide_location_banner"):
			gameplay_hud.hide_location_banner()
		gameplay_hud.setup(party_members, active_leader_index, inventory_items, quest_list)
		if selected_game_mode == "open_world":
			if gameplay_hud.has_method("set_open_world_mode"):
				gameplay_hud.set_open_world_mode(true)
			if gameplay_hud.has_method("hide_quest_navigation"):
				gameplay_hud.hide_quest_navigation()
			tracked_quest_id = ""
			var marker = get_node_or_null("CastleObjectiveMarker")
			if marker:
				marker.visible = false
		else:
			gameplay_hud.set_quests(quest_list, tracked_quest_id)
			var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
			if not tracked_q.is_empty():
				gameplay_hud.update_hud_quest_display(tracked_q)
			if not is_inside_castle_hall:
				if tracked_quest_id == "main_02":
					if gameplay_hud.has_method("set_quest_navigation"):
						gameplay_hud.set_quest_navigation(CASTLE_ENTRANCE_POS, "Aula Kastil")
				elif tracked_quest_id == "main_03":
					if gameplay_hud.has_method("set_quest_navigation"):
						gameplay_hud.set_quest_navigation(ALARIC_CAMP_POS, "Camp Latihan Istana")
				elif tracked_quest_id == "main_04":
					if gameplay_hud.has_method("set_quest_navigation"):
						gameplay_hud.set_quest_navigation(GRAVEYARD_POS, "Makam Ksatria Lancelot")
		gameplay_hud.pause_overlay.visible = false
		gameplay_hud.on_load_completed(slot_id, data)

	if not visited_locations.has(current_location_name):
		enter_location(current_location_name)

	# Restore Arena State
	if data.has("arena_state"):
		var saved_arena_val: int = clampi(int(data["arena_state"]), 0, ArenaState.values().size() - 1)
		arena_state = ArenaState.values()[saved_arena_val]
		if arena_state == ArenaState.CLEARED:
			_set_arena_barrier_enabled(false)
			target_camera_zoom = CAMERA_ZOOM_EXPLORE
			is_camera_locked_to_arena = false
		elif arena_state == ArenaState.COMBAT:
			_set_arena_barrier_enabled(true)
			target_camera_zoom = CAMERA_ZOOM_ARENA
			is_camera_locked_to_arena = true

	# Sinkronisasi status HUD pertarungan sesuai arena_state dari save data
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(arena_state == ArenaState.COMBAT, false)

	_setup_alaric_npc()

	print("GAME LOADED: Slot %d | Leader: %s | HP: %d | Playtime: %f" % [slot_id, String(leader.name) if leader else "None", int(leader.current_health) if (leader and "current_health" in leader) else 0, total_playtime])
	return true


func _collect_save_data(slot_id: int) -> Dictionary:
	var party_data: Array = []
	for p in party_members:
		if is_instance_valid(p):
			var hp_val: int = 100
			var max_hp_val: int = 100
			if "current_health" in p:
				hp_val = p.current_health
			if "max_health" in p:
				max_hp_val = p.max_health
			party_data.append({
				"name": p.name,
				"hp": hp_val,
				"max_hp": max_hp_val,
				"position": {
					"x": p.global_position.x,
					"y": p.global_position.y
				}
			})

	var now_dict := Time.get_datetime_dict_from_system()
	const MONTH_NAMES_ID: Array[String] = [
		"", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
	]
	var month_idx: int = clampi(int(now_dict.get("month", 1)), 1, 12)
	var month_str: String = MONTH_NAMES_ID[month_idx]
	var time_str := "%d %s %d, %02d.%02d" % [
		now_dict.get("day", 1),
		month_str,
		now_dict.get("year", 2026),
		now_dict.get("hour", 0),
		now_dict.get("minute", 0)
	]

	var current_location: String = DEFAULT_START_LOCATION
	var cur_q := _get_quest_by_id(tracked_quest_id)
	if not cur_q.is_empty() and cur_q.get("location", "") != "":
		current_location = cur_q.get("location")
	elif not current_location_name.is_empty():
		current_location = current_location_name

	var thumb_b64: String = ""
	if is_instance_valid(gameplay_hud):
		if "last_gameplay_thumbnail_b64" in gameplay_hud and not str(gameplay_hud.last_gameplay_thumbnail_b64).is_empty():
			thumb_b64 = str(gameplay_hud.last_gameplay_thumbnail_b64)
		elif gameplay_hud.has_method("_capture_gameplay_screenshot"):
			gameplay_hud.call("_capture_gameplay_screenshot")
			if "last_gameplay_thumbnail_b64" in gameplay_hud:
				thumb_b64 = str(gameplay_hud.last_gameplay_thumbnail_b64)

	var raw_mode := selected_game_mode
	var is_explore := (raw_mode == "open_world" or raw_mode == "jelajah")
	return {
		"slot_id": slot_id,
		"chapter": "Mode Jelajah" if is_explore else ("Chapter 1.2" if is_knight_room_completed else "Chapter 1.1"),
		"game_mode": raw_mode,
		"is_prologue_completed": is_prologue_completed,
		"is_castle_meeting_completed": is_castle_meeting_completed,
		"is_knight_room_completed": is_knight_room_completed,
		"is_alaric_sparring_completed": is_alaric_sparring_completed,
		"arena_state": int(arena_state),
		"location": current_location,
		"current_location_name": current_location_name,
		"visited_locations": visited_locations.duplicate(),
		"playtime": total_playtime,
		"save_time_str": time_str,
		"timestamp": int(Time.get_unix_time_from_system()),
		"active_leader_index": active_leader_index,
		"party": party_data,
		"inventory_items": _serialize_inventory(inventory_items),
		"quest_list": _serialize_quests(quest_list),
		"tracked_quest_id": tracked_quest_id,
		"thumbnail_b64": thumb_b64
	}


func _serialize_inventory(items: Array) -> Array:
	var out: Array = []
	for it in items:
		var d: Dictionary = it.duplicate(true)
		if d.has("icon_rect") and d["icon_rect"] is Rect2:
			var r: Rect2 = d["icon_rect"]
			d["icon_rect"] = [r.position.x, r.position.y, r.size.x, r.size.y]
		out.append(d)
	return out


func _deserialize_inventory(items: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it in items:
		if not (it is Dictionary):
			continue
		var d: Dictionary = it.duplicate(true)
		if d.has("quantity"):
			d["quantity"] = int(d["quantity"])
		if d.has("icon_rect"):
			if d["icon_rect"] is Array and d["icon_rect"].size() == 4:
				var a = d["icon_rect"]
				d["icon_rect"] = Rect2(a[0], a[1], a[2], a[3])
		out.append(d)
	return out


func _serialize_quests(quests: Array) -> Array:
	var out: Array = []
	for q in quests:
		var d: Dictionary = q.duplicate(true)
		if d.has("target_position") and d["target_position"] is Vector2:
			var v: Vector2 = d["target_position"]
			d["target_position"] = [v.x, v.y]
		out.append(d)
	return out


func _deserialize_quests(quests: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for q in quests:
		if not (q is Dictionary):
			continue
		var d: Dictionary = q.duplicate(true)
		if d.has("target_position"):
			if d["target_position"] is Array and d["target_position"].size() == 2:
				var a = d["target_position"]
				d["target_position"] = Vector2(a[0], a[1])
		out.append(d)
	return out


func _init_active_leader_indicator() -> void:
	"""Membuat node segitiga kecil di world space untuk menandai karakter aktif."""
	if _active_leader_indicator != null and is_instance_valid(_active_leader_indicator):
		return

	var indicator := Node2D.new()
	indicator.name = "ActiveLeaderIndicator"
	indicator.z_index = 10
	indicator.visible = false

	var outline := Polygon2D.new()
	outline.name = "TriangleOutline"
	outline.polygon = PackedVector2Array([
		Vector2(-13.0, -15.5),
		Vector2(13.0, -15.5),
		Vector2(0.0, 3.0)
	])
	outline.color = Color(0.11, 0.07, 0.08, 1.0)
	indicator.add_child(outline)

	var fill := Polygon2D.new()
	fill.name = "TriangleFill"
	fill.polygon = PackedVector2Array([
		Vector2(-10.0, -13.0),
		Vector2(10.0, -13.0),
		Vector2(0.0, 0.0)
	])
	fill.color = Color(1.0, 0.88, 0.36, 1.0)
	indicator.add_child(fill)

	add_child(indicator)
	_active_leader_indicator = indicator


func _get_leader_indicator_offset(leader: CharacterBody2D) -> Vector2:
	"""Mengambil koordinat offset ujung segitiga agar pas dan presisi di tengah-tengah atas kepala masing-masing karakter."""
	if leader == null:
		return DEFAULT_INDICATOR_OFFSET
	if HERO_INDICATOR_OFFSETS.has(leader.name):
		return HERO_INDICATOR_OFFSETS[leader.name]
	var lname := leader.name.to_lower()
	if "knight" in lname:
		return HERO_INDICATOR_OFFSETS["Knight_1"]
	elif "bandit" in lname:
		return HERO_INDICATOR_OFFSETS["Bandit_1"]
	elif "archer" in lname:
		return HERO_INDICATOR_OFFSETS["Archer_1"]
	elif "mage" in lname:
		return HERO_INDICATOR_OFFSETS["Mage_1"]
	return DEFAULT_INDICATOR_OFFSET


func _get_leader_indicator_offset_y(leader: CharacterBody2D) -> float:
	"""Mengambil jarak vertikal ujung segitiga agar pas di atas kepala masing-masing karakter."""
	return _get_leader_indicator_offset(leader).y


func _update_active_leader_indicator(delta: float) -> void:
	"""Menyinkronkan posisi, bobbing halus, dan visibilitas segitiga ke leader yang aktif."""
	if _active_leader_indicator == null or not is_instance_valid(_active_leader_indicator):
		return

	var leader := get_active_leader()
	if leader == null or not is_instance_valid(leader) or not is_character_alive(leader) or not leader.visible:
		_active_leader_indicator.visible = false
		return

	if delta > 0.0:
		_active_indicator_bob_time = fmod(_active_indicator_bob_time + delta * 4.0, TAU)

	var bob_offset: float = sin(_active_indicator_bob_time) * 2.5
	var base_offset: Vector2 = _get_leader_indicator_offset(leader)
	_active_leader_indicator.global_position = leader.global_position + Vector2(base_offset.x, base_offset.y + bob_offset)
	_active_leader_indicator.visible = true


# =========================================================
# CASTLE ENTRANCE, INTERACTION & HALL TRANSITIONS
# =========================================================

func check_castle_interactions(delta: float) -> void:
	if is_transitioning or is_in_arena_kamp or is_alaric_sparring_in_progress:
		if is_in_arena_kamp or is_alaric_sparring_in_progress:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt(true)
		return
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("is_dialogue_active") and gameplay_hud.is_dialogue_active():
		if gameplay_hud.has_method("hide_interact_prompt"):
			gameplay_hud.hide_interact_prompt(true)
		return
	var leader := get_active_leader()
	if leader == null or not is_instance_valid(leader):
		return

	# Update objective marker bobbing di luar gerbang
	var marker := get_node_or_null("CastleObjectiveMarker")
	if selected_game_mode == "open_world":
		if is_instance_valid(marker) and marker.visible:
			marker.visible = false
	elif is_instance_valid(marker) and marker.visible:
		_marker_bob_time = fmod(_marker_bob_time + delta * 3.5, TAU)
		marker.position.y = 940.0 + sin(_marker_bob_time) * 6.0

	# Update quest navigation di HUD jika sedang aktif
	if selected_game_mode != "open_world" and not is_inside_castle_hall and not is_in_arena_kamp and not is_alaric_sparring_in_progress:
		var cur_q := _get_quest_by_id(tracked_quest_id)
		if not cur_q.is_empty() and cur_q.get("status", "") == "active":
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("update_quest_navigation"):
				gameplay_hud.update_quest_navigation(leader.global_position)

	# Update visual arrow kompas navigasi yang mengorbit dan mengikuti karakter
	update_nav_compass(delta)

	# Cek kedekatan interaksi pintu masuk / keluar & NPC Pelatih Alaric
	if not is_inside_castle_hall and not is_in_arena_kamp and not is_inside_secret_library:
		if get_tree().paused or (is_instance_valid(gameplay_hud) and gameplay_hud.has_method("is_any_menu_open") and gameplay_hud.is_any_menu_open()) or is_instance_valid(_alaric_boss_prompt_layer):
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt(true)
			return

		var dist_castle := leader.global_position.distance_to(CASTLE_ENTRANCE_POS)
		var dist_alaric := leader.global_position.distance_to(ALARIC_CAMP_POS)
		if dist_castle <= 110.0:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_interact_prompt"):
				gameplay_hud.show_interact_prompt("Masuk ke Aula Kastil", "E", "enter_castle")
		elif dist_alaric <= 110.0 and not is_alaric_sparring_in_progress:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_interact_prompt"):
				var prompt_title := "Tantang Pelatih Alaric" if selected_game_mode == "open_world" else "Bicara dengan Pelatih Alaric"
				gameplay_hud.show_interact_prompt(prompt_title, "E", "talk_alaric")
		elif _is_near_library_entrance(leader.global_position):
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_interact_prompt"):
				gameplay_hud.show_interact_prompt("Masuk ke Perpustakaan", "E", "enter_library")
		else:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt()
	elif is_inside_secret_library:
		if get_tree().paused or (is_instance_valid(gameplay_hud) and gameplay_hud.has_method("is_any_menu_open") and gameplay_hud.is_any_menu_open()):
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt(true)
			return

		if not is_on_library_floor_2:
			var dist_stair := leader.global_position.distance_to(SECRET_LIBRARY_STAIR_POS)
			var dist_exit := leader.global_position.distance_to(SECRET_LIBRARY_EXIT_L1_POS)
			if dist_stair <= 110.0:
				if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_interact_prompt"):
					gameplay_hud.show_interact_prompt("Naik ke Lantai 2", "E", "go_library_floor2")
			elif dist_exit <= 110.0:
				if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_interact_prompt"):
					gameplay_hud.show_interact_prompt("Keluar ke Kota", "E", "exit_library")
			else:
				if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
					gameplay_hud.hide_interact_prompt()
		else:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt()
	elif is_inside_castle_hall:
		if get_tree().paused or (is_instance_valid(gameplay_hud) and gameplay_hud.has_method("is_any_menu_open") and gameplay_hud.is_any_menu_open()) or is_instance_valid(_alaric_boss_prompt_layer):
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt(true)
			return

		var dist := leader.global_position.distance_to(CASTLE_HALL_EXIT_POS)
		if dist <= 75.0:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("show_interact_prompt"):
				gameplay_hud.show_interact_prompt("Keluar ke Gerbang Kastil", "E", "exit_castle")
		else:
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
				gameplay_hud.hide_interact_prompt()


func update_camera_limits_for_location(location: String) -> void:
	if not is_instance_valid(camera):
		return
	if location == "hall":
		# Ruang Rapat Aula Kastil (Center Vector2(2533, -1500), ukuran 960x960)
		camera.limit_left = 2533 - 520
		camera.limit_right = 2533 + 520
		camera.limit_top = -1500 - 520
		camera.limit_bottom = -1500 + 520
	elif location == "library":
		# Perpustakaan Rahasia (Center Vector2(4300, -1500), ukuran 1045x880)
		camera.limit_left = 4300 - 560
		camera.limit_right = 4300 + 560
		camera.limit_top = -1500 - 480
		camera.limit_bottom = -1500 + 480
	elif location == "arena_kamp":
		# Arena Kamp Pelatihan (Node Vector2(7000, -2000), ukuran 2530x1180)
		camera.limit_left = 7000
		camera.limit_top = -2000
		camera.limit_right = 9530
		camera.limit_bottom = -820
	else:
		# Kembalikan ke batasan world outdoor
		camera.limit_left = int(world_map_min.x)
		camera.limit_top = int(world_map_min.y)
		camera.limit_right = int(world_map_max.x)
		camera.limit_bottom = int(world_map_max.y)
	if camera.has_method("reset_smoothing"):
		camera.reset_smoothing()
	if camera.has_method("force_update_scroll"):
		camera.force_update_scroll()


func update_camera_limits_for_hall(inside: bool) -> void:
	update_camera_limits_for_location("hall" if inside else "outdoor")


func _on_hud_interaction_pressed(action_type: String) -> void:
	if action_type == "enter_castle" or action_type == "Masuk ke Aula Kastil":
		enter_castle_hall()
	elif action_type == "exit_castle" or action_type == "Keluar ke Gerbang Kastil":
		exit_castle_hall()
	elif action_type == "join_meeting" or action_type == "Ikut Rapat":
		start_castle_meeting_cutscene()
	elif action_type == "talk_alaric" or action_type == "Bicara dengan Pelatih Alaric":
		_start_alaric_pre_fight_dialogue()
	elif action_type == "go_library_floor2" or action_type == "Naik ke Lantai 2":
		_go_to_library_floor_2()
	elif action_type == "enter_library" or action_type == "Masuk ke Perpustakaan":
		enter_secret_library()
	elif action_type == "exit_library" or action_type == "Keluar ke Kota":
		exit_secret_library()


func enter_secret_library() -> void:
	if is_transitioning:
		return
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)

	var on_midpoint := func() -> void:
		if not is_scene_4_in_progress and not is_scene_4_completed:
			start_story_scene_4()
		else:
			is_inside_secret_library = true
			is_inside_castle_hall = false
			is_on_library_floor_2 = false
			var lib_node := get_node_or_null("SecretLibrary")
			if is_instance_valid(lib_node):
				var floor1 := lib_node.get_node_or_null("LibraryFloor1")
				var floor2 := lib_node.get_node_or_null("LibraryFloor2")
				if floor1: floor1.visible = true
				if floor2: floor2.visible = false
			update_camera_limits_for_location("library")
			for i in range(party_members.size()):
				var p = party_members[i]
				if is_instance_valid(p):
					p.global_position = SECRET_LIBRARY_L1_SPAWN + Vector2(i * 35.0 - 35.0, 0.0)
					p.velocity = Vector2.ZERO
					if "last_direction" in p:
						p.last_direction = Vector2.UP
					if p.has_method("play_idle_animation"):
						p.play_idle_animation()
			if is_instance_valid(camera):
				camera.global_position = SECRET_LIBRARY_L1_SPAWN
				camera.reset_smoothing()
				if camera.has_method("force_update_scroll"):
					camera.force_update_scroll()

	play_black_fade_transition(on_midpoint)


func exit_secret_library() -> void:
	if is_transitioning:
		return
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt(true)

	var on_midpoint := func() -> void:
		is_inside_secret_library = false
		is_on_library_floor_2 = false
		is_inside_castle_hall = false

		var spawn_pos := LIBRARY_ENTRANCE_POS + Vector2(0.0, 30.0)
		for i in range(party_members.size()):
			var member = party_members[i]
			if is_instance_valid(member):
				member.global_position = spawn_pos + Vector2(i * 30.0 - 30.0, 0.0)
				member.velocity = Vector2.ZERO
				if "last_direction" in member:
					member.last_direction = Vector2.DOWN
				if member.has_method("play_idle_animation"):
					member.play_idle_animation()

		update_camera_limits_for_location("outdoor")
		if is_instance_valid(camera):
			camera.global_position = spawn_pos
			camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

	play_black_fade_transition(on_midpoint)


func enter_castle_hall() -> void:
	if is_transitioning:
		return
	is_inside_castle_hall = true
	if is_instance_valid(gameplay_hud):
		if gameplay_hud.has_method("hide_interact_prompt"):
			gameplay_hud.hide_interact_prompt()
		if gameplay_hud.has_method("hide_quest_navigation"):
			gameplay_hud.hide_quest_navigation()

	var marker := get_node_or_null("CastleObjectiveMarker")
	if is_instance_valid(marker):
		marker.visible = false

	await transition_to_location(CASTLE_HALL_SPAWN_POS, "Aula Rapat Istana")

	if not is_castle_meeting_completed and not is_meeting_in_progress:
		start_castle_meeting_cutscene()


func exit_castle_hall() -> void:
	if is_transitioning:
		return
	is_inside_castle_hall = false
	if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("hide_interact_prompt"):
		gameplay_hud.hide_interact_prompt()

	if selected_game_mode != "open_world":
		if tracked_quest_id == "main_02":
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_quest_navigation"):
				gameplay_hud.set_quest_navigation(CASTLE_ENTRANCE_POS, "Aula Kastil")
			var marker := get_node_or_null("CastleObjectiveMarker")
			if is_instance_valid(marker):
				marker.visible = true
		elif tracked_quest_id == "main_03":
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_quest_navigation"):
				gameplay_hud.set_quest_navigation(ALARIC_CAMP_POS, "Camp Latihan Istana")
		elif tracked_quest_id == "main_04":
			if is_instance_valid(gameplay_hud) and gameplay_hud.has_method("set_quest_navigation"):
				gameplay_hud.set_quest_navigation(GRAVEYARD_POS, "Makam Ksatria Lancelot")

	transition_to_location(CASTLE_OUTSIDE_SPAWN_POS, "Halaman Depan Kastil")


func play_black_fade_transition(on_midpoint: Callable, on_completed: Callable = Callable()) -> void:
	is_transitioning = true
	if is_instance_valid(gameplay_hud):
		gameplay_hud.is_hud_input_blocked = true
	for p in party_members:
		if is_instance_valid(p):
			p.set_physics_process(false)
			p.set_process_unhandled_input(false)
			p.velocity = Vector2.ZERO
			if p.has_method("play_idle_animation"):
				p.play_idle_animation()

	var fade_canvas := CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fade_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_canvas.add_child(fade_rect)
	add_child(fade_canvas)

	var sfx_door: AudioStream = load("res://assets/audio/sfx/ui/transition_iris_open.wav")
	if sfx_door:
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.stream = sfx_door
		sfx_player.volume_db = -3.0
		add_child(sfx_player)
		sfx_player.finished.connect(sfx_player.queue_free)
		sfx_player.play()

	# 1. Efek pudar masuk ke hitam pekat (Fade in to black)
	var tween_in := create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(fade_rect, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween_in.finished

	await get_tree().create_timer(0.08).timeout

	# 2. Callback midpoint (teleportasi karakter & kamera saat layar gelap)
	if on_midpoint.is_valid():
		on_midpoint.call()

	await get_tree().process_frame
	await get_tree().process_frame

	# 3. Efek pudar keluar dari hitam pekat (Fade out from black)
	var tween_out := create_tween()
	tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_out.tween_property(fade_rect, "color:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_out.finished

	fade_canvas.queue_free()
	is_transitioning = false
	if is_instance_valid(gameplay_hud):
		gameplay_hud.is_hud_input_blocked = false

	if on_completed.is_valid():
		on_completed.call()


func transition_to_location(target_pos: Vector2, new_location_name: String = "") -> void:
	is_transitioning = true
	if is_instance_valid(gameplay_hud):
		gameplay_hud.is_hud_input_blocked = true
	for p in party_members:
		if is_instance_valid(p):
			p.set_physics_process(false)
			p.set_process_unhandled_input(false)
			p.velocity = Vector2.ZERO
			if p.has_method("play_idle_animation"):
				p.play_idle_animation()

	# Layer 120 di atas seluruh elemen gameplay dan HUD untuk efek pudar hitam pekat
	var fade_canvas := CanvasLayer.new()
	fade_canvas.layer = 120
	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fade_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_canvas.add_child(fade_rect)
	add_child(fade_canvas)

	var sfx_door: AudioStream = load("res://assets/audio/sfx/ui/transition_iris_open.wav")
	if sfx_door:
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = &"SFX"
		sfx_player.stream = sfx_door
		sfx_player.volume_db = -3.0
		add_child(sfx_player)
		sfx_player.finished.connect(sfx_player.queue_free)
		sfx_player.play()

	# 1. Efek pudar masuk ke hitam (Fade in to black)
	var tween_in := create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(fade_rect, "color:a", 1.0, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween_in.finished

	# Jeda bernapas halus saat layar hitam pekat
	await get_tree().create_timer(0.08).timeout

	# 2. Pindahkan seluruh anggota party & sinkronkan batas kamera
	for i in range(party_members.size()):
		var member = party_members[i]
		if is_instance_valid(member):
			var offset := Vector2.ZERO
			match i:
				0: offset = Vector2(0, 0)
				1: offset = Vector2(-40, 36)
				2: offset = Vector2(40, 36)
				3: offset = Vector2(0, 70)
			member.global_position = target_pos + offset
			member.velocity = Vector2.ZERO

	update_camera_limits_for_hall(is_inside_castle_hall)

	if is_instance_valid(camera):
		camera.global_position = target_pos
		camera.reset_smoothing()
		if camera.has_method("force_update_scroll"):
			camera.force_update_scroll()

	await get_tree().process_frame
	await get_tree().process_frame

	if new_location_name != "":
		enter_location(new_location_name)

	# 3. Efek pudar keluar dari hitam membuka ruangan baru (Fade out from black)
	var tween_out := create_tween()
	tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_out.tween_property(fade_rect, "color:a", 0.0, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_out.finished

	fade_canvas.queue_free()
	is_transitioning = false
	if is_instance_valid(gameplay_hud):
		gameplay_hud.is_hud_input_blocked = false
	for i in range(party_members.size()):
		var p = party_members[i]
		if is_instance_valid(p):
			p.set_physics_process(true)
			var should_input: bool = (i == active_leader_index)
			p.set_process_unhandled_input(should_input)


# =========================================================
# DYNAMIC NAVIGATION COMPASS ARROW (WORLD POINTER)
# =========================================================

class NavCompassNode extends Node2D:
	var arrow_rotation: float = 0.0

	func _draw() -> void:
		# Lingkaran luar transparan dengan aksen emas lembut
		draw_circle(Vector2.ZERO, 19.0, Color(0.08, 0.09, 0.14, 0.60))
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 32, Color(0.96, 0.82, 0.25, 0.65), 1.5)

		# Vektor arah rotasi panah
		var x_dir := Vector2.from_angle(arrow_rotation)
		var y_dir := Vector2(-x_dir.y, x_dir.x)

		# Bentuk segitiga panah kuning proporsional (sesuai referensi user)
		var tip := x_dir * 12.0
		var b_top := -x_dir * 8.0 - y_dir * 8.0
		var b_bot := -x_dir * 8.0 + y_dir * 8.0

		# Bayangan halus di bawah panah segitiga
		var s_offset := Vector2(1.5, 2.0)
		var shadow_poly := PackedVector2Array([tip + s_offset, b_top + s_offset, b_bot + s_offset])
		draw_colored_polygon(shadow_poly, Color(0.0, 0.0, 0.0, 0.40))

		# Outline gelap kontras agar segitiga kuning terbaca jelas di segala medan
		var border_poly := PackedVector2Array([tip + x_dir * 1.5, b_top - x_dir * 1.0 - y_dir * 1.5, b_bot - x_dir * 1.0 + y_dir * 1.5])
		draw_colored_polygon(border_poly, Color(0.12, 0.12, 0.15, 0.95))

		# Isi warna kuning emas murni (sesuai persis dengan gambar referensi user: RGB 246, 210, 63)
		var arrow_poly := PackedVector2Array([tip, b_top, b_bot])
		draw_colored_polygon(arrow_poly, Color(0.96, 0.82, 0.25, 1.0))


func _init_nav_compass() -> void:
	if _nav_compass != null and is_instance_valid(_nav_compass):
		return
	_nav_compass = NavCompassNode.new()
	_nav_compass.name = "NavigationCompass"
	_nav_compass.z_index = 100 # Di atas map, karakter, dan objek world
	_nav_compass.visible = false
	_nav_compass.modulate.a = 0.0
	add_child(_nav_compass)


func update_nav_compass(delta: float) -> void:
	if not is_instance_valid(_nav_compass):
		return

	if selected_game_mode == "open_world":
		if _nav_compass.visible:
			_nav_compass.visible = false
		return

	var leader := get_active_leader()
	var cur_q := _get_quest_by_id(tracked_quest_id)
	var has_target: bool = not cur_q.is_empty() and cur_q.has("target_position") and cur_q.get("status", "") == "active"
	var is_active: bool = has_target and not is_inside_castle_hall and not is_in_arena_kamp and not is_alaric_sparring_in_progress and not is_transitioning
	if not is_active or leader == null or not is_instance_valid(leader):
		if _nav_compass.visible:
			_nav_compass.modulate.a = lerpf(_nav_compass.modulate.a, 0.0, delta * 8.0)
			if _nav_compass.modulate.a <= 0.02:
				_nav_compass.visible = false
		return

	var target_pos: Vector2 = cur_q["target_position"]
	var to_target: Vector2 = target_pos - leader.global_position
	var dist: float = to_target.length()

	# Jika sudah dekat dengan tujuan (<= 110 px), pudar keluar
	if dist <= 110.0:
		if _nav_compass.visible:
			_nav_compass.modulate.a = lerpf(_nav_compass.modulate.a, 0.0, delta * 6.0)
			if _nav_compass.modulate.a <= 0.02:
				_nav_compass.visible = false
		return

	_nav_compass.visible = true
	_nav_compass.modulate.a = lerpf(_nav_compass.modulate.a, 1.0, delta * 6.0)

	# Ambil parameter kamera aktif untuk menghitung frame viewport layar
	var cam_center: Vector2 = camera.get_screen_center_position() if is_instance_valid(camera) else leader.global_position
	var cam_zoom: Vector2 = camera.zoom if is_instance_valid(camera) else Vector2(0.8, 0.8)
	if cam_zoom.x <= 0.001 or cam_zoom.y <= 0.001:
		cam_zoom = Vector2(0.8, 0.8)

	var vp_size: Vector2 = get_viewport_rect().size
	var half_w: float = (vp_size.x * 0.5) / cam_zoom.x
	var half_h: float = (vp_size.y * 0.5) / cam_zoom.y

	# Margin dari pinggir frame kamera (28 px di layar agar mepet rapi tanpa terpotong)
	var margin_w: float = 28.0 / cam_zoom.x
	var margin_h: float = 28.0 / cam_zoom.y
	var inner_half := Vector2(maxf(half_w - margin_w, 20.0), maxf(half_h - margin_h, 20.0))

	var diff_from_cam: Vector2 = target_pos - cam_center
	var dist_from_cam: float = diff_from_cam.length()
	var target_dir: Vector2 = diff_from_cam.normalized() if dist_from_cam > 0.001 else to_target.normalized()
	var target_angle: float = target_dir.angle()

	# Hitung perpotongan sinar arah target dengan batas frame kamera
	var t_x: float = (inner_half.x / absf(target_dir.x)) if absf(target_dir.x) > 0.0001 else 1e9
	var t_y: float = (inner_half.y / absf(target_dir.y)) if absf(target_dir.y) > 0.0001 else 1e9
	var t: float = minf(t_x, t_y)

	# Jika target berada di luar jangkauan kamera, jepit di pinggir frame kamera.
	# Jika target sudah masuk dalam frame kamera, arahkan mendekat ke titik target objektif.
	var clamped_dist: float = minf(t, dist_from_cam)
	var desired_pos: Vector2 = cam_center + target_dir * clamped_dist

	if _nav_compass.global_position == Vector2.ZERO or _nav_compass.modulate.a < 0.1:
		_nav_compass.global_position = desired_pos
		_nav_compass.arrow_rotation = target_angle
	else:
		_nav_compass.global_position = _nav_compass.global_position.lerp(desired_pos, clampf(delta * 18.0, 0.0, 1.0))
		_nav_compass.arrow_rotation = lerp_angle(_nav_compass.arrow_rotation, target_angle, clampf(delta * 14.0, 0.0, 1.0))

	_nav_compass.queue_redraw()
