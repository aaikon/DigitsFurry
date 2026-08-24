extends Node

## Global SFX player: gameplay code just calls e.g. Sfx.play_launch(),
## Sfx.play_impact("wood") -- no AudioStreamPlayer wiring needed per scene.

const STRETCH = preload("res://assets/audio/sfx/stretch.ogg")
const LAUNCH = preload("res://assets/audio/sfx/launch.ogg")
const IMPACT_WOOD = preload("res://assets/audio/sfx/impact_wood.ogg")
const DESTROY_WOOD = preload("res://assets/audio/sfx/destroy_wood.ogg")
const IMPACT_SOFT = preload("res://assets/audio/sfx/impact_soft.ogg")
const DESTROY_SOFT = preload("res://assets/audio/sfx/destroy_soft.ogg")
const LEVEL_WIN = preload("res://assets/audio/sfx/level_win.ogg")
const LEVEL_LOSE = preload("res://assets/audio/sfx/level_lose.ogg")

const POOL_SIZE = 8

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready():
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

func _play(stream: AudioStream, pitch := 1.0, volume_db := 0.0) -> void:
	var player = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()

func play_stretch() -> void:
	_play(STRETCH, randf_range(0.95, 1.05))

func play_launch() -> void:
	_play(LAUNCH, randf_range(0.95, 1.05))

## material is "wood" (blocks/birds) or "soft" (pigs)
func play_impact(material: String) -> void:
	_play(IMPACT_SOFT if material == "soft" else IMPACT_WOOD, randf_range(0.9, 1.1), -4.0)

func play_destroy(material: String, pitch := 1.0) -> void:
	_play(DESTROY_SOFT if material == "soft" else DESTROY_WOOD, pitch * randf_range(0.95, 1.05))

func play_level_win() -> void:
	_play(LEVEL_WIN)

func play_level_lose() -> void:
	_play(LEVEL_LOSE)
