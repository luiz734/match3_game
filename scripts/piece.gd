extends Node2D
class_name Piece

@onready var label_index = $Index
@onready var texture_rect = $TextureRect

@export var _piece_res: PieceRes
var index = -1:
    set(value):
        index = value
        label_index.text = str(index)
        Events.piece_index_changed.emit(self)
        name = "piece_" + str(value)
var next_index = -1
        
signal piece_clicked(piece: Piece)
signal action_animation_finished

var used = false

func init(piece_res: PieceRes):
    self._piece_res = piece_res

func _ready():
    assert(_piece_res, "call init() before instantiate")
    assert(label_index, "missing child label_index")
    texture_rect.texture = _piece_res.sprite
    
    texture_rect.piece = self
