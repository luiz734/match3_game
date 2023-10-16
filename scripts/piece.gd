extends TextureRect
class_name Piece

static var score_animation_sec = 0.5
static var change_position_animation_sec = 0.5

@onready var label_index = $Index
@export var _piece_res: PieceRes
var index = -1:
    set(value):
        index = value
        label_index.text = str(index)
        Events.piece_index_changed.emit(self)
        name = "piece_" + str(value)
        
signal piece_clicked(piece: Piece)
signal action_animation_finished

var used = false

func init(piece_res: PieceRes):
    self._piece_res = piece_res

func _ready():
    assert(_piece_res, "call init() before instantiate")
    assert(label_index, "missing child label_index")
    texture = _piece_res.sprite

func play_score_animation():
    var t = create_tween().tween_property(self, "scale", Vector2(0, 0), score_animation_sec)
    used = true
    await t.finished
    action_animation_finished.emit()

func play_change_position_animation(new_pos: Vector2):
    var t = create_tween().tween_property(self, "position", new_pos, change_position_animation_sec)
    await t.finished
    action_animation_finished.emit()

func _get_drag_data(position):
    return {"other": self}

func _can_drop_data(at_position, data):
    return true
    
func _drop_data(at_position, data):
    print(data)
