extends TextureRect
class_name Piece



@onready var label_index = $Index
@export var _piece_res: PieceRes
var index = -1:
    set(value):
        index = value
        label_index.text = str(index)
        Events.piece_index_changed.emit(self)
        name = "piece_" + str(value)
        
        
signal piece_clicked(piece: Piece)

var used = false

func init(piece_res: PieceRes):
    self._piece_res = piece_res

func hide_all():
    modulate = Color(0.4, 0.4, 0.4)
    used = true


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
