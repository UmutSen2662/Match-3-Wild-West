extends Node2D
# State machine
enum {wait, move, over}
var state

# Swap back variables
var piece_1 = null
var piece_2 = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Grid variables
@export var width: int
@export var height: int
@export var offset: int
@export var y_offset: int
var x_start = 64
var y_start = 42 + 256

# Piece array
var possibble_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/lime_piece.tscn"),
	preload("res://scenes/red_piece.tscn"),
	preload("res://scenes/purple_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/white_piece.tscn"),
	#preload("res://scenes/column_piece.tscn"),
	#preload("res://scenes/row_piece.tscn"),
	#preload("res://scenes/bomb_piece.tscn"),
	#preload("res://scenes/revolver_piece.tscn")
]
var column_bomb = preload("res://scenes/column_piece.tscn")
var row_bomb = preload("res://scenes/row_piece.tscn")
var area_bomb = preload("res://scenes/bomb_piece.tscn")
var revolver_preload = preload("res://scenes/revolver_piece.tscn")
var bullet_preload = preload("res://scenes/bullet_hole.tscn")
var smoke_column = preload("res://scenes/smoke_particles.tscn")
var explosion_preload = preload("res://scenes/explosion_particles.tscn")
var multiplier_preload = preload("res://scenes/streak.tscn")
var extra_move_preload = preload("res://scenes/extra_move.tscn")

# Audio variables
@export var revolver_sound: AudioStream
@export var explosion_sound: AudioStream
@export var cork_sound: AudioStream
@export var swipe_sounds: Array[AudioStream]
@export var positive_pop: Array[AudioStream]
@export var special_sound: Array[AudioStream]
var explosion_playing = false
var cork_pop_playing = false

# Current pieces in the scene
var all_pieces = []
var exploding_bombs = {
	"revolver": [],
	"bomb": [],
	"column": [],
	"row": []
}

# Touch variables
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false

# Score variables
signal update_score
@export var piece_value: int
var current_score = 0
var streak = 1

# Counter variables
signal update_moves
var current_moves = 20
var extra_move_granted = false

# Revolver variavles
signal revolver_shot
signal revolver_end
var revolver_time = 0
var revolver_shot_count = 0
var revolver_shooting = false
var hit_list = []
var bullet_holes = []

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	emit_signal("update_moves", current_moves)
	all_pieces = make_2D_array()
	spawn_pieces()
	state = move

func make_2D_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(0)
	return array

func spawn_pieces():
	for i in width:
		for j in height:
			var piece = possibble_pieces.pick_random().instantiate()
			var loops = 0
			while match_at(i, j, piece.color) and loops < 10:
				piece = possibble_pieces.pick_random().instantiate()
				loops+=1
			piece.position = grid_to_pixel(i, j)
			add_child(piece)
			all_pieces[i][j] = piece

func match_at(i, j, color):
	if i > 1:
		if all_pieces[i-1][j] != null and all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].color == color and all_pieces[i-2][j].color == color:
				return true
	if j > 1:
		if all_pieces[i][j-1] != null and all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].color == color and all_pieces[i][j-2].color == color:
				return true

func grid_to_pixel(column, row):
	var new_x = x_start + (offset * column)
	var new_y = y_start + (offset * row)
	return Vector2(new_x, new_y)

func pixel_to_grid(pos):
	var column = round((pos.x - x_start) / offset)
	var row = round((pos.y - y_start) / offset)
	return Vector2(max(0, min(width-1, column)), max(0, min(height-1, row)))

func is_in_grid(pos):
	var surface_margin = get_parent().get_node("ui_elements/play_position")
	if pos.x >= 0 and pos.x <= 576:
		if pos.y >= 250 - 10 and pos.y < surface_margin.size.y + 10:
			return true
	return false

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(get_global_mouse_position()):
			first_touch = pixel_to_grid(get_global_mouse_position())
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		if controlling:
			final_touch = pixel_to_grid(get_global_mouse_position())
			touch_difference(first_touch, final_touch)
		controlling = false

func swap_pieces(column, row, direction):
	AudioManager.play_sound(swipe_sounds.pick_random())
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece != null and other_piece != null:
		store_info(first_piece, other_piece, Vector2(column, row), direction)
		state = wait
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_piece.move(grid_to_pixel(column, row))
		if !move_checked:
			find_matches()

func store_info(first, other, place, direction):
	piece_1 = first
	piece_2 = other
	last_place = place
	last_direction = direction

func swap_back():
	if piece_1 != null and piece_2 != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	move_checked = false
	state = move
	if current_moves < 1:
		state = over
		emit_signal("end_game", current_score)

func touch_difference(grid_1, grid_2):
	var difference = grid_1 - grid_2
	if abs(difference.x) > abs(difference.y):
		current_moves-=1
		streak = 1
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1,0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1,0))
	elif abs(difference.x) < abs(difference.y):
		current_moves-=1
		streak = 1
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,-1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,1))
	elif all_pieces[grid_1.x][grid_1.y].color in ["bomb", "column", "row", "revolver"]:
		current_moves-=1
		streak = 1
		exploding_bombs[all_pieces[grid_1.x][grid_1.y].color].append(Vector2(grid_1.x, grid_1.y))
		handle_bombs()
	emit_signal("update_moves", current_moves)

func handle_bombs():
	var type = null
	if !exploding_bombs["bomb"].is_empty():
		type = "bomb"
	elif !exploding_bombs["column"].is_empty():
		type = "column"
	elif !exploding_bombs["row"].is_empty():
		type = "row"
	elif !exploding_bombs["revolver"].is_empty():
		type = "revolver"
	if type != null:
		var vec = exploding_bombs[type].pop_front()
		while all_pieces[vec.x][vec.y] == null and !exploding_bombs[type].is_empty():
			vec = exploding_bombs[type].pop_front()
		if all_pieces[vec.x][vec.y] != null:
			explode_bomb(vec.x, vec.y)
			return
	explosion_playing = false
	cork_pop_playing = false
	get_parent().get_node("Destroy_Timer").start()

func explode_bomb(col, row):
	streak+=1
	state = wait
	var type = all_pieces[col][row].color
	all_pieces[col][row].queue_free()
	all_pieces[col][row] = null
	if type == "column" or type == "row":
		var smoke = smoke_column.instantiate()
		add_child(smoke)
		if !cork_pop_playing:
			AudioManager.play_sound(cork_sound)
			AudioManager.play_sound(cork_sound)
		cork_pop_playing = true
		smoke.position = grid_to_pixel(col, row)
		if type == "row":
			smoke.rotation_degrees = 90
		current_score = current_score + piece_value * 10 * streak
	elif type == "bomb":
		var explosion = explosion_preload.instantiate()
		add_child(explosion)
		if !explosion_playing:
			AudioManager.play_sound(explosion_sound)
		explosion_playing = true
		explosion.position = grid_to_pixel(col, row)
		current_score = current_score + piece_value * 12 * streak
	elif type == "revolver":
		current_score = current_score + piece_value * 15 * streak
	emit_signal("update_score", current_score)
	match type:
		"revolver":
			revolver_shooting = true
			await revolver_end
		"bomb":
			for i in range(max(col-2, 0), min(col+3, width)):
				for j in range(max(row-2, 0), min(row+3, height)):
					if all_pieces[i][j] != null:
						if all_pieces[i][j].color in ["bomb", "column", "row", "revolver"] and !all_pieces[i][j].matched:
							exploding_bombs[all_pieces[i][j].color].append(Vector2(i, j))
						match_and_dim(i, j)
		"column":
			for i in height:
				if all_pieces[col][i] != null:
					if all_pieces[col][i].color in ["bomb", "column", "row", "revolver"] and !all_pieces[col][i].matched:
						exploding_bombs[all_pieces[col][i].color].append(Vector2(col, i))
					match_and_dim(col, i)
		"row":
			for i in width:
				if all_pieces[i][row] != null:
					if all_pieces[i][row].color in ["bomb", "column", "row", "revolver"] and !all_pieces[i][row].matched:
						exploding_bombs[all_pieces[i][row].color].append(Vector2(i, row))
					match_and_dim(i, row)
	handle_bombs()

func revolver_one_shot():
	var i = randi() % width
	var j = randi() % height
	if all_pieces[i][j] != null:
		if !all_pieces[i][j].matched:
			var bullet_hole = bullet_preload.instantiate()
			add_child(bullet_hole)
			AudioManager.play_sound(revolver_sound)
			bullet_hole.position = grid_to_pixel(i, j)
			bullet_hole.rotation_degrees = randi() % 360
			bullet_holes.append(bullet_hole)
			hit_list.append(Vector2(i, j))
			return true
	return false

func revolver_process_helper(_delta):
	revolver_time += _delta
	if revolver_time > 0.12:
		var count = 0
		var shot = revolver_one_shot()
		while !shot and count < 8:
			shot = revolver_one_shot()
			revolver_shot_count+=1
			count += 1
		if count == 8:
			revolver_shot_count = 20
		revolver_shot_count+=1
		revolver_time = 0
	if revolver_shot_count > 20:
		revolver_shooting = false
		revolver_shot_count = 0
		emit_signal("revolver_shot")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if revolver_shooting:
		revolver_process_helper(_delta)
	if state == move:
		touch_input()

func find_matches():
	var streak_displayed = false 
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var color_match = all_pieces[i][j].color
				if color_match not in ["bomb", "column", "row", "revolver"]:
					if i > 0 and i < width-1:
						if all_pieces[i-1][j] != null and all_pieces[i+1][j] != null:
							if all_pieces[i-1][j].color == color_match and all_pieces[i+1][j].color == color_match:
								AudioManager.play_sound(positive_pop.pick_random())
								match_and_dim(i-1, j)
								match_and_dim(i, j)
								match_and_dim(i+1, j)
								if !streak_displayed and streak > 1:
									streak_displayed = true
									var mutiplier = multiplier_preload.instantiate()
									add_child(mutiplier)
									mutiplier.display_multiplier(grid_to_pixel(max(1, min(width-2, i)), max(1, min(height-2, j))), streak)
					if j > 0 and j < height-1:
						if all_pieces[i][j-1] != null and all_pieces[i][j+1] != null:
							if all_pieces[i][j-1].color == color_match and all_pieces[i][j+1].color == color_match:
								AudioManager.play_sound(positive_pop.pick_random())
								match_and_dim(i, j-1)
								match_and_dim(i, j)
								match_and_dim(i, j+1)
								if !streak_displayed and streak > 1:
									streak_displayed = true
									var mutiplier = multiplier_preload.instantiate()
									add_child(mutiplier)
									mutiplier.display_multiplier(grid_to_pixel(max(1, min(width-2, i)), max(1, min(height-2, j))), streak)
	get_parent().get_node("Destroy_Timer").start()

func match_and_dim(i, j):
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func add_to_array(value, arr):
	if !arr.has(value):
		arr.append(value)

func make_bomb(bomb_type, col, row):
	all_pieces[col][row].queue_free()
	var bomb = null
	match bomb_type:
		"bomb":
			bomb = area_bomb.instantiate()
		"column":
			bomb = column_bomb.instantiate()
		"row":
			bomb = row_bomb.instantiate()
		"revolver":
			bomb = revolver_preload.instantiate()
	if bomb != null:
		AudioManager.play_sound(special_sound.pick_random())
		all_pieces[col][row] = bomb
		add_child(bomb)
		bomb.position = grid_to_pixel(col, row)
		if piece_1 != null and !extra_move_granted and streak == 1:
			var extra_move = extra_move_preload.instantiate()
			add_child(extra_move)
			extra_move.extra_move(piece_1.position)
			extra_move_granted = true
			current_moves+=1
			emit_signal("update_moves", current_moves)

func find_bombs():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched and all_pieces[i][j].color not in ["bomb", "column", "row", "revolver"]:
					var color_match = all_pieces[i][j].color
					if i < width-4:
						if all_pieces[i+1][j] != null and all_pieces[i+2][j] != null and all_pieces[i+3][j] != null and all_pieces[i+4][j] != null:
							if all_pieces[i+1][j].color == color_match and all_pieces[i+2][j].color == color_match and all_pieces[i+3][j].color == color_match and all_pieces[i+4][j].color == color_match:
								make_bomb("revolver", i+2, j)
					if j < height-4:
						if all_pieces[i][j+1] != null and all_pieces[i][j+2] != null and all_pieces[i][j+3] != null and all_pieces[i][j+4] != null:
							if all_pieces[i][j+1].color == color_match and all_pieces[i][j+2].color == color_match and all_pieces[i][j+3].color == color_match and all_pieces[i][j+4].color == color_match:
								make_bomb("revolver", i, j+2)
					if i < width-2:
						if all_pieces[i+1][j] != null and all_pieces[i+2][j] != null:
							if all_pieces[i+1][j].color == color_match and all_pieces[i+2][j].color == color_match:
								var column = null
								for k in range(i, i+3):
									var col_match = 0
									for l in range(max(j-2, 0), min(j+3, height)):
										if all_pieces[k][l] != null:
											if all_pieces[k][l].color == color_match and all_pieces[k][l].matched:
												col_match+=1
									if col_match > 2:
										column = k
								if column != null:
									make_bomb("bomb", column, j)
					if i < width-3:
						if all_pieces[i+1][j] != null and all_pieces[i+2][j] != null and all_pieces[i+3][j] != null:
							if all_pieces[i+1][j].color == color_match and all_pieces[i+2][j].color == color_match and all_pieces[i+3][j].color == color_match:
								if piece_1 != null:
									if pixel_to_grid(piece_1.position).x == i+1:
										make_bomb("row", i+1, j)
									else:
										make_bomb("row", i+2, j)
								else:
									make_bomb("row", i+2, j)
					if j > 2:
						if all_pieces[i][j-1] != null and all_pieces[i][j-2] != null and all_pieces[i][j-3] != null:
							if all_pieces[i][j-1].color == color_match and all_pieces[i][j-2].color == color_match and all_pieces[i][j-3].color == color_match:
								if piece_1 != null:
									if pixel_to_grid(piece_1.position).y == j-1:
										make_bomb("column", i, j-1)
									else:
										make_bomb("column", i, j-2)
								else:
									make_bomb("column", i, j-2)

func destroy_matched():
	find_bombs()
	extra_move_granted = false
	var was_matched = false
	var board_empty = true
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				board_empty = false
				if all_pieces[i][j].matched:
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
					current_score = current_score + piece_value * streak
					emit_signal("update_score", current_score)
	move_checked = true
	if was_matched or board_empty:
		get_parent().get_node("Collapse_Timer").start()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in range(height - 1, -1, -1):
			if all_pieces[i][j] == null:
				for k in range(j - 1, -1, -1):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("Refill_Timer").start()

func refill_columns():
	streak+=1
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var piece = possibble_pieces.pick_random().instantiate()
				var loops = 0
				while match_at(i, j, piece.color) and loops < 10:
					piece = possibble_pieces.pick_random().instantiate()
					loops+=1
				all_pieces[i][j] = piece
				piece.position = grid_to_pixel(i, j - y_offset)
				add_child(piece)
				piece.move(grid_to_pixel(i, j))
	after_refill()

signal end_game
func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color):
					find_matches()
					get_parent().get_node("Destroy_Timer").start()
					return
			if i == width-1 and j == height-1:
				streak = 1
				state = move
				move_checked = false
				if current_moves < 1:
					state = over
					emit_signal("end_game", current_score)

func clear_and_store_board():
	var holder_arr = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				holder_arr.append(all_pieces[i][j])
				all_pieces[i][j] = null
	return holder_arr

func shuffle_board():
	var holder_arr = clear_and_store_board()
	for i in width:
		for j in height:
			var loops = 0
			var piece = holder_arr.pick_random()
			while match_at(i, j, piece.color) and loops < 10:
				loops+=1
				piece = holder_arr.pick_random()
			holder_arr.erase(piece)
			all_pieces[i][j] = piece
			piece.move(grid_to_pixel(i, j))

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func _on_shuffle_button_pressed():
	if state == move:
		AudioManager.play_sound(swipe_sounds.pick_random())
		shuffle_board()
		current_moves-=1
		streak = 1
		emit_signal("update_moves", current_moves)
		if current_moves < 1:
			state = over
			emit_signal("end_game", current_score)

signal pause_game
func _on_pause_button_pressed():
	AudioManager.button_click()
	emit_signal("pause_game")
	get_tree().paused = true

func _on_reload_button_pressed():
	AudioManager.button_click()
	get_tree().change_scene_to_file("res://scenes/game_space.tscn")

func _on_revolver_shot():
	for hole in bullet_holes:
		hole.queue_free()
	for vec in hit_list:
		if all_pieces[vec.x][vec.y] != null:
			if all_pieces[vec.x][vec.y].color in ["bomb", "column", "row", "revolver"] and !all_pieces[vec.x][vec.y].matched:
				exploding_bombs[all_pieces[vec.x][vec.y].color].append(Vector2(vec.x, vec.y))
			match_and_dim(vec.x, vec.y)
	bullet_holes.clear()
	hit_list.clear()
	cork_pop_playing = false
	explosion_playing = false
	emit_signal("revolver_end")
