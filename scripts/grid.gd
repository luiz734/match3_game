extends Node2D

@export var grid_size = 8
@export var pieces_resources: Array[PieceRes] = []

const Match3Core = preload("res://scripts/standalone/match3_core.gd")


var action_locked = false

func lock_actions():
    action_locked = true
func unlock_actions():
    action_locked = false

var pieces: Array[Piece] = []
@onready var match3_core = Match3Core.new(grid_size)
const PiecePrefab = preload("res://scenes/piece.tscn")

func _ready():
    rng.randomize()
    var seed: int = rng.randi()
    seed(1)
    print_debug("Seed:", seed) 
    
    assert(not pieces_resources.is_empty(), "Add at least 1 piece resource")
    Events.connect("piece_index_changed", on_piece_index_changed)
    Events.connect("piece_removed_from_poll", on_piece_removed_from_poll)
    create_pieces()
    
func on_piece_index_changed(piece: Piece):
    var spacement = 100
    var p_row = floor(piece.index / grid_size)
    var p_col = piece.index % grid_size
    var p_pos = Vector2(p_col * spacement, p_row * spacement)
    piece.play_change_position_animation(p_pos)
    lock_actions()
    await piece.action_animation_finished
    unlock_actions()
    
func create_piece_as_child(index) -> Piece:
    var new_piece = PiecePrefab.instantiate()
    var rand_piece_res = pieces_resources.pick_random()
    new_piece.init(rand_piece_res)
    # todo: create a single function for position
    var spacement = 100
    
    var p_col = (index % grid_size)
    var p_row = -1
    var p_pos = Vector2(p_col * spacement, p_row * spacement)
    new_piece.position = p_pos
    add_child(new_piece)
    new_piece.index = index
    
    return new_piece

func create_pieces():
    for i in range(grid_size * grid_size):
        var p = create_piece_as_child(i)
        pieces.push_back(p)
        
func on_piece_removed_from_poll(index: int) -> void:
    pieces[index].play_score_animation()
    lock_actions()
    await pieces[index].action_animation_finished
    unlock_actions()

var rng = RandomNumberGenerator.new()


func make_action() -> Array:
    Events.new_match_found.emit("clear")
    var candidates = match3_core.get_candidate_matches_as_arrays(pieces, grid_size, cmp_func)
    
#    while not candidates.is_empty():
    Events.new_match_found.emit("candidates")
    for c in candidates:
        Events.new_match_found.emit(c)
    
    var next_match: Match3Core.MatchData = match3_core.get_most_valuable_match(candidates, grid_size)
    match3_core.remove_from_poll(next_match.indexes)
    await get_tree().create_timer(Piece.score_animation_sec).timeout
    for x in match3_core.get_removed_from_poll_indexes(grid_size):
        pieces[x].queue_free()
        pieces[x] = null
    smash_all_lines()
    await get_tree().create_timer(Piece.change_position_animation_sec).timeout
    fill_null_spots()
    await get_tree().create_timer(Piece.change_position_animation_sec).timeout
    match3_core.reset_removed_from_poll()
    
    var type_name = match3_core.MatchType.keys()[next_match.type]
    Events.new_match_found.emit(type_name)
    Events.new_match_found.emit(next_match.indexes)
    
    return candidates

func next_match():
    if action_locked:
        return
        
    lock_actions()
    var candidates = await make_action()
    while true:
        candidates = await make_action()
        if candidates.is_empty():
            var a = pieces.pick_random()
            var b = pieces.pick_random()
        
            pieces[a.index] = b
            pieces[b.index] = a 
            var tmp = a.index
            a.index = b.index
            b.index = tmp
            await get_tree().create_timer(Piece.change_position_animation_sec).timeout

    
    
#    Events.new_match_found.emit("clear")
#    candidates = match3_core.get_candidate_matches_as_arrays(pieces, grid_size, cmp_func)
        
    unlock_actions()
     
func cmp_func(a: Piece, b: Piece) -> bool:
    if a.used or b.used: return false
    
    var match_with = b._piece_res.matches.any(func (x):
        return x == a._piece_res.type
    )
    return match_with


## This method make changes INPLACE
func smash_all_lines():        
    for col in range(0, grid_size, 1):
        var start = grid_size * (grid_size - 1) + col
        var end = col - grid_size
        var step = -grid_size
        var smashed = match3_core.get_notnull_first(pieces, grid_size, start, end, step)
        
        var count = 0
        for i in range(start, end, step):
            pieces[i] = smashed[count]
            if pieces[i]:
                pieces[i].index = i
            count += 1
    
func fill_null_spots():
    for i in range(grid_size * grid_size):
        if pieces[i] == null:
            pieces[i] = create_piece_as_child(i)
        
        
    
 
