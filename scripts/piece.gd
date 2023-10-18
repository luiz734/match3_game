extends Node2D
class_name Piece

@onready var label_index = $Index
@onready var texture_rect = $TextureRect
@export var _piece_res: PieceRes

var _interactable: bool = true
var _grid_size_x: int

var index = -1:
    set(value):
        assert(_grid_size_x, "call init() first")
        index = value
        label_index.text = str(index)
        Events.piece_index_changed.emit(self)
        name = "piece_" + str(value)
        _interactable = index >= _grid_size_x
var next_index = -1
        
signal piece_clicked(piece: Piece)
signal action_animation_finished

var used = false

func init(piece_res: PieceRes, grid_size_x: int):
    self._piece_res = piece_res
    self._grid_size_x = grid_size_x

func _ready():
    assert(_piece_res, "call init() before instantiate")
    assert(label_index, "missing child label_index")
    texture_rect.texture = _piece_res.sprite
    
    texture_rect.piece = self


func on_score():
    Events.piece_scored.emit(int(_piece_res.points))
