extends GridContainer

@export var grid_size = 5
@export var pieces_resources: Array[PieceRes] = []

var pieces: Array[Piece] = []
const Piece = preload("res://scenes/piece.tscn")

func _ready():
#    seed(0)
    assert(not pieces_resources.is_empty(), "Add at least 1 piece resource")
    
    columns = grid_size
    for i in range(grid_size * grid_size):
        var new_piece = Piece.instantiate()
        new_piece.name = "piece_" + str(i)
        var rand_piece_res = pieces_resources.pick_random()
        new_piece.init(rand_piece_res)
        pieces.push_back(new_piece)
        add_child(new_piece)
        new_piece.index = i
    
    var matches = get_max_seq_all_lines(pieces)
    matches.sort_custom(func(x, y):
        return x["length"] > y["length"]
    )
    print(matches)
    
    
func get_max_seq_all_lines(grid):
    var grid_size = 5
    
    var matches: Array[Dictionary] = []
    
    # horizontal
    for i in range(5):
        var start = i * grid_size
        var end = (i + 1) * grid_size
        var step = 1
        var max_subseq = max_subseq(grid, start, end, step)
        matches.push_back({
            "length": max_subseq[0],
            "index": max_subseq[1],
            "direction": "h"
        })
        
    # vertical
    for i in range(grid_size):
        var start = i
        var end = (grid_size * grid_size) + i
        var step = grid_size
        var max_subseq = max_subseq(grid, start, end, step)
        matches.push_back({
            "length": max_subseq[0],
            "index": max_subseq[1],
            "direction": "v"
        })
    
    return matches


# returns [length, start_idx]
# end is NOT INCLUSIVE
func max_subseq(grid, start, end, step):
    var last_piece: Piece = grid[start]
    start = start + step
    var count = 1
    for i in range(start, end, step):
        var cur_piece: Piece = grid[i]
        if cur_piece.matches_with(last_piece):
            count += 1
        else:
#            var cur_max = i - start + 1
            var subseq = max_subseq(grid, i, end, step)
            if subseq[0] > count:
                return subseq
            else:
                return [count, start - step]
        last_piece = cur_piece
            
    return [count, start - step]
        
        
        
    
 
