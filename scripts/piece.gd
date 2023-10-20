extends Node2D
class_name Piece


@export var _piece_res: PieceRes
@onready var label_index = $Debug_index
@onready var texture_rect = $TextureRect
signal piece_clicked(piece: Piece)
signal action_animation_finished
var _interactable: bool = true
var _grid_size_x: int
var next_index = -1
var used = false


var index = -1:
    set(value):
        assert(_grid_size_x, "call init() first")
        index = value
        label_index.text = str(index)
        Events.piece_index_changed.emit(self)
        name = "piece_" + str(value)
        _interactable = index >= _grid_size_x

        




func init(piece_res: PieceRes, grid_size_x: int):
    self._piece_res = piece_res
    self._grid_size_x = grid_size_x

func _ready():
    assert(_piece_res, "call init() before instantiate")
    assert(label_index, "missing child label_index")
    texture_rect.texture = _piece_res.sprite
    
    texture_rect.piece = self

func on_score(multiplier):
    var score = _piece_res.points * multiplier
    Events.piece_scored.emit(int(score))
    return score
