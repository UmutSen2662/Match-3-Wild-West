extends Node

@onready var path = "user://config.ini"
var sound_on = true
var music_on = true
var highscore = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	load_config()

func save_config():
	var config = ConfigFile.new()
	config.set_value("user", "sound", sound_on)
	config.set_value("user", "music", music_on)
	config.set_value("user", "highscore", highscore)
	var err = config.save(path)
	if err != OK:
		print("could not save")

func load_config():
	var config = ConfigFile.new()
	var default_options = {"user": {"sound": true, "music": true, "highscore": 0}}
	var err = config.load(path)
	if err != OK:
		return default_options
	sound_on = config.get_value("user", "sound", default_options.user.sound)
	music_on = config.get_value("user", "music", default_options.user.music)
	highscore = config.get_value("user", "highscore", default_options.user.highscore)

