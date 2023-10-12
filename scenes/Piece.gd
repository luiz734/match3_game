extends TextureRect
class_name Piece

@onready var label_index = $Index

@export var _piece_res: PieceRes
var index = -1:
    set(value):
        index = value
        label_index.text = str(index)
        
signal piece_clicked(piece: Piece)

func init(piece_res: PieceRes):
    self._piece_res = piece_res

func _ready():
    assert(_piece_res, "call init() before instantiate")
    assert(label_index, "missing child label_index")
    texture = _piece_res.sprite

func _get_drag_data(position):
    return {"other": self}

func _can_drop_data(at_position, data):
    return true
    
func _drop_data(at_position, data):
    print(data)

func matches_with(other: Piece):
    var match_with = other._piece_res.matches.any(func (x):
        return x == self._piece_res.type
    )
    return match_with
