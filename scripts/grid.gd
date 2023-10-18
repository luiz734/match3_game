extends Node2D

@export var grid_size_x = 6
@export var grid_size_y = 9
@export var spacement = 0
@export var pieces_resources: Array[PieceRes] = []
@export var multipliers: Array[int] = []

const SPRITE_SIZE = 32

const Match3Core = preload("res://scripts/standalone/match3_core.gd")

@onready var pieces_tweener: PieceGroupTweener = $PieceGroupTweener

var action_locked = false
var require_update = true
var rng = RandomNumberGenerator.new()
var _last_match_type: Match3Core.MatchType
var combo_count = 0

func lock_actions():
    action_locked = true
func unlock_actions():
    action_locked = false

var pieces: Array[Piece] = []
var match3_core: Match3Core
const PiecePrefab = preload("res://scenes/piece.tscn")

func _ready():
    rng.randomize()
    var seed: int = rng.randi()
#    seed(2)
    seed(seed)
    print_debug("Seed:", seed) 
    assert(len(multipliers) == 4)
    assert(not pieces_resources.is_empty(), "Add at least 1 piece resource")
    Events.connect("piece_index_changed", on_piece_index_changed)
    Events.connect("swap_requested", on_swap_requested)
#    Events.connelesect("piece_removed_from_poll", on_piece_removed_from_poll)

    for i in range(grid_size_x * grid_size_y):
        pieces.push_back(null)
        
    match3_core = Match3Core.new(grid_size_x, grid_size_y)
    
func on_piece_index_changed(piece: Piece):
    return
    
func swap_pieces(a, b):
    a.next_index = b.index
    b.next_index = a.index
    pieces[a.index] = b
    pieces[b.index] = a
    var both = [a, b]
    pieces_tweener.animate_position(both, grid_size_x, grid_size_y, spacement, SPRITE_SIZE)
    await pieces_tweener.animate_position_finished 

func on_swap_requested(a, b) -> void:
    if action_locked:
        return
    if not are_neighbors(a.index, b.index):
        return
    if not (a._interactable and b._interactable):
        return
        
    lock_actions()
    await swap_pieces(a, b)
    var candidates = match3_core.get_candidate_matches_as_arrays(pieces, cmp_func)
    if candidates.is_empty():
        await swap_pieces(a, b)
        
        
    unlock_actions()
    next_match()
    
    
func create_piece_as_child(index) -> Piece:
    var new_piece = PiecePrefab.instantiate()
    var rand_piece_res = pieces_resources.pick_random()
    new_piece.init(rand_piece_res, grid_size_x)
    # todo: create a single function for position
    
    var p_col = (index % grid_size_x)
    var p_row = 0
    var p_pos = Vector2(p_col * (SPRITE_SIZE + spacement), p_row * (SPRITE_SIZE + spacement))
    new_piece.position = p_pos
    add_child(new_piece)
    new_piece.index = index
    
    return new_piece

func try_move_all_pieces_1_down() -> Array:
    # first row is dispenser
    # last row ignored
    var moved_pieces = []
    var start = grid_size_x * (grid_size_y - 1) - 1
    var end = -1
    var step = -1
    for i in range(start, end, step):
        var row = floor(i / grid_size_x)
        var col = i % grid_size_x
        var index_bellow = (row + 1) * grid_size_x + col
        assert(index_bellow >= 0 and index_bellow < grid_size_x * grid_size_y)
        if pieces[index_bellow] == null and pieces[i] != null:
            moved_pieces.push_back(pieces[i])
            pieces[i].next_index = index_bellow
            pieces[index_bellow] = pieces[i]
            pieces[i] = null
    return moved_pieces
        
func fill_dispenser() -> bool:
    var one_or_more_filled = false
    for i in range(0, grid_size_x):
        if pieces[i] == null:
            var p = create_piece_as_child(i)
            pieces[i] = p
            one_or_more_filled = true
            
    return one_or_more_filled


var __debug_match_call_count = 0
func next_match():

    # This should ALWAYS be true or bad things will happen.
    # If it's more that 1, that means that this function was called some 
    # other place and it's still awaiting some signal. Calling again may 
    # queue_free() nodes that are being awaited, so don't.
    __debug_match_call_count += 1
    assert(__debug_match_call_count == 1)
    # VERY IMPORTANT. NOT USE BEFORE READ.
    
    if action_locked:
        return
    
    lock_actions()
    require_update = true
    combo_count = -1
    while require_update:
        combo_count += 1
        while true:
            fill_dispenser()
            var dropped_pieces = try_move_all_pieces_1_down()
            if dropped_pieces.is_empty():
                break
            else:
                pieces_tweener.animate_position(dropped_pieces, grid_size_x, grid_size_y, spacement, SPRITE_SIZE)
                await pieces_tweener.animate_position_finished
 
        match3_core.reset_removed_from_poll()
        var candidates = match3_core.get_candidate_matches_as_arrays(pieces, cmp_func)
        
        var next_match: Match3Core.MatchData = match3_core.get_most_valuable_match(candidates)
        match3_core.remove_from_poll(next_match.indexes)
        
        require_update = not candidates.is_empty()
        
        var scored_pieces: Array = next_match.indexes.map(func(x): return pieces[x])
        if not scored_pieces.is_empty():
            _last_match_type = next_match.type
            var multiplier = multipliers[4 - _last_match_type] # skip "NO_MATCH"
            multiplier = multiplier + combo_count
            print(_last_match_type)
            pieces_tweener.animate_score(scored_pieces, multiplier, combo_count)
            await pieces_tweener.animate_score_finished
        
        
        var indexes_removed_from_poll = match3_core.get_removed_from_poll_indexes()
        
        for i in indexes_removed_from_poll:
            pieces[i].queue_free()
            pieces[i] = null
        
    unlock_actions()
    
    __debug_match_call_count -= 1
        
     
func cmp_func(a: Piece, b: Piece) -> bool:
    if a.used or b.used: return false
    
    var match_with = b._piece_res.matches.any(func (x):
        return x == a._piece_res.type
    )
    return match_with

func are_neighbors(a, b):
    var col_a = a % grid_size_x
    var col_b = b % grid_size_x
    var row_a = floor(a / grid_size_x)
    var row_b = floor(b / grid_size_x)
    
    var v_neighbor = (col_a == col_b) and (abs(row_a - row_b) == 1)
    var h_neighbor = (row_a == row_b) and (abs(col_a - col_b) == 1)
    
    return v_neighbor or h_neighbor
    

## This method make changes INPLACE
func smash_all_lines():        
    for col in range(0, grid_size_x, 1):
        var start = grid_size_x * (grid_size_y - 1) + col
        var end = col - grid_size_x
        var step = -grid_size_x
        var smashed = match3_core.get_notnull_first(pieces, start, end, step)
        
        var count = 0
        for i in range(start, end, step):
            pieces[i] = smashed[count]
            if pieces[i]:
                pieces[i].index = i
            count += 1
    
func fill_null_spots():
    for i in range(grid_size_x * grid_size_y):
        if pieces[i] == null:
            pieces[i] = create_piece_as_child(i)
        
        
    
 
