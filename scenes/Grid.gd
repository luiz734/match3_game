extends Node2D

@export var grid_size = 8
@export var pieces_resources: Array[PieceRes] = []

const Match3Core = preload("res://scripts/standalone/match3_core.gd")

var pieces: Array[Piece] = []
@onready var match3_core = Match3Core.new(grid_size)
const Piece = preload("res://scenes/piece.tscn")

func on_piece_index_changed(piece: Piece):
    var spacement = 100
    var p_row = floor(piece.index / grid_size)
    var p_col = piece.index % grid_size
    var p_pos = Vector2(p_col * spacement, p_row * spacement)
    piece.position = p_pos
    
func create_piece(index) -> void:
    var new_piece = Piece.instantiate()
    var rand_piece_res = pieces_resources.pick_random()
    new_piece.init(rand_piece_res)
    pieces.push_back(new_piece)
    add_child(new_piece)
    new_piece.index = index

func create_pieces():
    for i in range(grid_size * grid_size):
        create_piece(i)
        
        
func piece_removed_from_poll(index: int) -> void:
    pieces[index].hide_all()

var rng = RandomNumberGenerator.new()

func _ready():
#    seed(9) # T
    rng.randomize()
    var seed = rng.randi()
    seed(2492608867)
#    print(seed)
    
    var current_seed = rng.get_seed()
    assert(not pieces_resources.is_empty(), "Add at least 1 piece resource")
    Events.connect("piece_index_changed", on_piece_index_changed)
    Events.connect("piece_removed_from_poll", piece_removed_from_poll)
    create_pieces()
    
func next_match():
    Events.new_match_found.emit("clear")
    var candidates = match3_core.get_candidate_matches_as_arrays(pieces, grid_size, cmp_func)
    
    Events.new_match_found.emit("candidates")
    for c in candidates:
        Events.new_match_found.emit(c)
    
    var next_match: Dictionary = get_next_valuable_match(candidates, grid_size)
    var type: String = next_match["type"]
    var to_remove: Array= next_match["indexes"]
    match3_core.remove_from_poll(to_remove)
#
#    for index in to_remove:
#        pieces[index].hide_all()
    Events.new_match_found.emit(type)
    Events.new_match_found.emit(to_remove)
     

func remove_used_matches(matches: Array, used: Array):
    var i = 0
    while i < len(matches):
        var m = matches[i]
        var remove_match = m.any(func(x):
            return used.any(func(y):
                return x == y
            )
        )
        if remove_match:
            matches.remove_at(i)
            i -= 1
        i +=  1

## Side effect: matches gets empty in the process
func get_next_valuable_match(matches: Array, grid_size):
   
    var match_5 = match3_core.find_match_N(5, matches, grid_size)
    if not match_5.is_empty(): return {"type": "5", "indexes": match_5 }     

    var h_matches = matches.filter(func(x): return abs(x[0] - x[1]) == 1)
    var v_matches = matches.filter(func(x): return abs(x[0] - x[1]) == grid_size)

    # T's pointing horizontal
    var match_T = match3_core.find_match_T(h_matches, v_matches, grid_size)
    if not match_T.is_empty(): return {"type": "T", "indexes": match_T }   

#    # T's pointing vertical
    var match_Tv = match3_core.find_match_T(v_matches, h_matches, grid_size)
    if not match_Tv.is_empty(): return {"type": "Tv", "indexes": match_Tv }   

    var match_4 = match3_core.find_match_N(4, matches, grid_size)
    if not match_4.is_empty(): return {"type": "4", "indexes": match_4 }   

    var match_3 = match3_core.find_match_N(3, matches, grid_size)
    if not match_3.is_empty(): return {"type": "3", "indexes": match_3 }     
    
    return {"type": "none", "indexes": [] }  


func cmp_func(a: Piece, b: Piece) -> bool:
#    if a._piece_res.type == PieceRes.PieceType.NONE\
#        or b._piece_res.type == PieceRes.PieceType.NONE: return false
    if a.used or b.used: return false
    
    var match_with = b._piece_res.matches.any(func (x):
        return x == a._piece_res.type
    )
    return match_with


  
        
        
    
 
