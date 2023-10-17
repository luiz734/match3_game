extends Node2D

@export var grid_size = 8
@export var pieces_resources: Array[PieceRes] = []

const Match3Core = preload("res://scripts/standalone/match3_core.gd")

@onready var pieces_tweener: PieceGroupTweener = $PieceGroupTweener

var action_locked = false
var require_update = true

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
    seed(seed)
    print_debug("Seed:", seed) 
    
    assert(not pieces_resources.is_empty(), "Add at least 1 piece resource")
    Events.connect("piece_index_changed", on_piece_index_changed)
#    Events.connect("piece_removed_from_poll", on_piece_removed_from_poll)

    for i in range(grid_size * grid_size):
        pieces.push_back(null)
    
func on_piece_index_changed(piece: Piece):
    return
#    var spacement = 100
#    var p_row = floor(piece.index / grid_size)
#    var p_col = piece.index % grid_size
#    var p_pos = Vector2(p_col * spacement, p_row * spacement)
#    piece.play_change_position_animation(p_pos)
#    lock_actions()
#    await piece.action_animation_finished
#    unlock_actions()
    
func create_piece_as_child(index) -> Piece:
    var new_piece = PiecePrefab.instantiate()
    var rand_piece_res = pieces_resources.pick_random()
    new_piece.init(rand_piece_res)
    # todo: create a single function for position
    var spacement = 100
    
    var p_col = (index % grid_size)
    var p_row = 0
    var p_pos = Vector2(p_col * spacement, p_row * spacement)
    new_piece.position = p_pos
    add_child(new_piece)
    new_piece.index = index
    
    return new_piece

        
#func on_piece_removed_from_poll(index: int) -> void:
#    pieces[index].play_score_animation()
#    lock_actions()
#    await pieces[index].action_animation_finished
#    unlock_actions()

var rng = RandomNumberGenerator.new()

func try_move_all_pieces_1_down() -> Array:
    # first row is dispenser
    # last row ignored
    var moved_pieces = []
    var start = grid_size * (grid_size - 1) - 1
    var end = -1
    var step = -1
    for i in range(start, end, step):
        var row = floor(i / grid_size)
        var col = i % grid_size
        var index_bellow = (row + 1) * grid_size + col
        assert(index_bellow >= 0 and index_bellow < grid_size * grid_size)
        if pieces[index_bellow] == null and pieces[i] != null:
            moved_pieces.push_back(pieces[i])
            pieces[i].next_index = index_bellow
            pieces[index_bellow] = pieces[i]
            pieces[i] = null
    return moved_pieces
        
func fill_dispenser() -> bool:
    var one_or_more_filled = false
    for i in range(0, grid_size):
        if pieces[i] == null:
            var p = create_piece_as_child(i)
            pieces[i] = p
            one_or_more_filled = true
            
    return one_or_more_filled


func next_match():
    if action_locked:
        return
    
    while require_update:
        while true:
            fill_dispenser()
            var dropped_pieces = try_move_all_pieces_1_down()
            if dropped_pieces.is_empty():
                break
            else:
                pieces_tweener.animate_position(dropped_pieces, grid_size, 100)
                await pieces_tweener.animate_position_finished
 
        match3_core.reset_removed_from_poll()
        var candidates = match3_core.get_candidate_matches_as_arrays(pieces, grid_size, cmp_func)
        
        var next_match: Match3Core.MatchData = match3_core.get_most_valuable_match(candidates, grid_size)
        match3_core.remove_from_poll(next_match.indexes)
        
        require_update = not candidates.is_empty()
        
        var scored_pieces: Array = next_match.indexes.map(func(x): return pieces[x])
        pieces_tweener.animate_score(scored_pieces)
        await pieces_tweener.animate_score_finished
        
        var indexes_removed_from_poll = match3_core.get_removed_from_poll_indexes(grid_size)
        for i in indexes_removed_from_poll:
            pieces[i].queue_free()
            pieces[i] = null
        
        
     
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
        
        
    
 
