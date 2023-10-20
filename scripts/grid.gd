extends Node2D

## Handle the UI for pieces. Any changing in the pieces happens or is called here.
## Has some important methods related to the Match 3 mechanics.
## Match 3 related methods here are methods that needs to 
## change state (movement, index, etc).

const SPRITE_SIZE = 32
const Match3Core = preload("res://scripts/standalone/match3_core.gd")
const PiecePrefab = preload("res://scenes/piece.tscn")
# grid dimensions
@export var grid_size_x = 6
@export var grid_size_y = 8
# ui spacement
@export var spacement = 0
# pieces that can generated
@export var pieces_resources: Array[PieceRes] = []
# multiplier for each piece type
# types are MATCH_5, MATCH_T, MATCH_4 and MATCH_3
@export var multipliers: Array[int] = []
@onready var pieces_tweener: PieceGroupTweener = $PieceGroupTweener
# can be 0, 1 or 2
var current_diffuculty = 0
var action_locked = false
var require_update = true
var rng = RandomNumberGenerator.new()
var _last_match_type: Match3Core.MatchType   
var _combo_count = 0
# the array containin the pieces
var pieces: Array[Piece] = []
# most of the "match_3 logic" goes in there
# if a function needs to change the state, it will be in 
# this script instead
var match3_core: Match3Core

func _ready() -> void:
    rng.randomize()
    var gen_seed: int = rng.randi()
    seed(gen_seed)
    Events.current_score = 0
    print_debug("Seed:", gen_seed) 
    assert(len(multipliers) == 4)
    assert(not pieces_resources.is_empty(), "Add at least 1 piece resource")
    Events.swap_requested.connect(on_swap_requested)
    Events.shuffle_requested.connect(on_shuffle_requested)
    Events.medium_dificulty_reached.connect(func(): current_diffuculty += 1)
    Events.hard_dificulty_reached.connect(func(): current_diffuculty += 1)

    for i in range(grid_size_x * grid_size_y):
        pieces.push_back(null)
        
    match3_core = Match3Core.new(grid_size_x, grid_size_y)

## When actios are locked the player cant send inputs, except for quit (Escape).
func lock_actions() -> void:
    action_locked = true
    Events.input_locket = true
func unlock_actions() -> void:
    action_locked = false
    Events.input_locket = false
 
## Swap 2 pieces, animating the swap. 
func swap_pieces(a, b) -> void:
    a.next_index = b.index
    b.next_index = a.index
    pieces[a.index] = b
    pieces[b.index] = a
    var both = [a, b]
    pieces_tweener.animate_position(both, grid_size_x, spacement, SPRITE_SIZE)
    await pieces_tweener.animate_position_finished 

## Swap all pieces. Each piece goes to a new random spot.
func on_shuffle_requested() -> void:
    assert(not action_locked)
    
    Events.current_level -= 1
    lock_actions()
    var total_pieces = grid_size_x * grid_size_y
    var to_swap: Array = []
    
    var shuffled_grid: Array = []
    for i in range(total_pieces): shuffled_grid.push_back(i)
    shuffled_grid.shuffle()

    var start = 0 if total_pieces % 2 == 0 else 1
    for i in range(start, total_pieces, 2):
        var index_a = shuffled_grid[i]
        var index_b = shuffled_grid[i+1]
        var a = pieces[index_a]
        var b = pieces[index_b]
        to_swap.push_back(a)
        to_swap.push_back(b)
        a.next_index = b.index
        b.next_index = a.index
        pieces[a.index] = b
        pieces[b.index] = a
    
    pieces_tweener.animate_position(to_swap, grid_size_x, spacement, SPRITE_SIZE)
    await pieces_tweener.animate_position_finished 
    unlock_actions()
    try_next_match()

## Emited when the user press the swap button. Can or cannot happen.
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
    try_next_match()

## Create a new piece and add it as a child.  
func create_piece_as_child(index) -> Piece:
    var new_piece = PiecePrefab.instantiate()
    
    var rand_piece_index = randi_range(0, 2 + current_diffuculty)
    var rand_piece_res = pieces_resources[rand_piece_index]
    
    new_piece.init(rand_piece_res, grid_size_x)
    # todo: create a single function for position
    var p_col = (index % grid_size_x)
    var p_row = 0
    var p_pos = Vector2(p_col * (SPRITE_SIZE + spacement), p_row * (SPRITE_SIZE + spacement))
    new_piece.position = p_pos
    add_child(new_piece)
    new_piece.index = index
    
    return new_piece

## Starting from the 2nd row from bottom to top, try to move
## all pieces 1 row to the bottom.
func try_move_all_pieces_1_row_down() -> Array:
    # first row is dispenser
    # last row ignored
    var moved_pieces = []
    var start = grid_size_x * (grid_size_y - 1) - 1
    var end = -1
    var step = -1
    for i in range(start, end, step):
        @warning_ignore("integer_division")
        var row = int(i / grid_size_x) 
        var col = i % grid_size_x
        var index_bellow = (row + 1) * grid_size_x + col
        assert(index_bellow >= 0 and index_bellow < grid_size_x * grid_size_y)
        if pieces[index_bellow] == null and pieces[i] != null:
            moved_pieces.push_back(pieces[i])
            pieces[i].next_index = index_bellow
            pieces[index_bellow] = pieces[i]
            pieces[i] = null
    return moved_pieces

## The "Dispenser" is the first row where pieces are created.
## It's not visible in the UI. Pieces created there are moved to the bottom
## when necessary.
## For each piece in the dispenser, if it is empty (null),
## add a new piece.
func fill_dispenser() -> bool:
    var one_or_more_filled = false
    for i in range(0, grid_size_x):
        if pieces[i] == null:
            var p = create_piece_as_child(i)
            pieces[i] = p
            one_or_more_filled = true
            
    return one_or_more_filled

## Debug variable used to ensure that this method is not called twice
## before the first call finish.
var __debug_match_call_count = 0
## Try to find a new match (user score).
func try_next_match() -> void:
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
    _combo_count = -1
    # require update is triggered when there is "candidates"
    # candidates are matchable-pieces (pieces that can be scored)
    while require_update:
        _combo_count += 1
        Events.combo_changed.emit(_combo_count)
        if _combo_count == 1:
            Events.combo_started.emit()
        
        # continually move the pieces down until it can no longer
        while true:
            fill_dispenser()
            var dropped_pieces = try_move_all_pieces_1_row_down()
            if dropped_pieces.is_empty():
                break
            else:
                pieces_tweener.animate_position(dropped_pieces, grid_size_x, spacement, SPRITE_SIZE)
                await pieces_tweener.animate_position_finished
        
        # handles the match (score)
        match3_core.reset_removed_from_poll()
        var candidates = match3_core.get_candidate_matches_as_arrays(pieces, cmp_func)
        
        var next_match: Match3Core.MatchData = match3_core.get_most_valuable_match(candidates)
        match3_core.remove_from_poll(next_match.indexes)
        
        require_update = not candidates.is_empty()
        
        var scored_pieces: Array = next_match.indexes.map(func(x): return pieces[x])
        if not scored_pieces.is_empty():
            _last_match_type = next_match.type
            var multiplier = multipliers[4 - _last_match_type] # skip "NO_MATCH"
            multiplier = multiplier + _combo_count
            pieces_tweener.animate_score(scored_pieces, multiplier, _combo_count)
            await pieces_tweener.animate_score_finished
        
        var indexes_removed_from_poll = match3_core.get_removed_from_poll_indexes()
        
        for i in indexes_removed_from_poll:
            pieces[i].queue_free()
            pieces[i] = null
        
    unlock_actions()
    Events.combo_ended.emit(_combo_count)
    if Events.current_level < 0:
        Events.game_over.emit(Events.current_score)
    
    __debug_match_call_count -= 1

## Used to compare pieces. This method is passed to "match_3_core.gd" to 
## check for equality. 
func cmp_func(a: Piece, b: Piece) -> bool:
    if a.used or b.used: return false
    
    var match_with = b._piece_res.matches.any(func (x):
        return x == a._piece_res.type
    )
    return match_with

## Return true the pieces a and b are ajacent to each other (diagonally doesn't counts).
func are_neighbors(a, b) -> bool:
    var col_a = a % grid_size_x
    var col_b = b % grid_size_x
    var row_a = int(a / grid_size_x)
    var row_b = int(b / grid_size_x)
    
    var v_neighbor = (col_a == col_b) and (abs(row_a - row_b) == 1)
    var h_neighbor = (row_a == row_b) and (abs(col_a - col_b) == 1)
    
    return v_neighbor or h_neighbor
