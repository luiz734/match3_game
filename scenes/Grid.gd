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
    rng.randomize()
    var seed: int = rng.randi()
    seed(seed)
    print_debug("Seed:", seed) 
    
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
    
    var next_match: Match3Core.MatchData = match3_core.get_most_valuable_match(candidates, grid_size)
    match3_core.remove_from_poll(next_match.indexes)
    
    var type_name = match3_core.MatchType.keys()[next_match.type]
    Events.new_match_found.emit(type_name)
    Events.new_match_found.emit(next_match.indexes)
     

func cmp_func(a: Piece, b: Piece) -> bool:
    if a.used or b.used: return false
    
    var match_with = b._piece_res.matches.any(func (x):
        return x == a._piece_res.type
    )
    return match_with


  
        
        
    
 
