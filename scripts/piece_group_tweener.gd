extends Node
class_name PieceGroupTweener

const SCORE_DURATION_SEC = 0.3
const POSITION_DURATION_SEC = 0.1

signal animate_score_finished
signal animate_position_finished

var _active_count = 0

func animate_score(pieces: Array):
    assert(_active_count == 0, "Other animation is playing.")
    for p in pieces:
        var t = get_tree().create_tween()
        t.tween_property(p, "scale", Vector2(0, 0), SCORE_DURATION_SEC)
        _active_count += 1
        t.connect("finished", func(): 
            _active_count -= 1
            if _active_count == 0: animate_score_finished.emit()
        )

func animate_position(pieces: Array, grid_size: int, spacement: int):
    assert(_active_count == 0, "Other animation is playing.")
    for p in pieces:
        var t = get_tree().create_tween()
        var p_row = floor(p.next_index / grid_size)
        var p_col = p.next_index % grid_size
        var p_pos = Vector2(p_col * spacement, p_row * spacement)
        t.tween_property(p, "position", p_pos, POSITION_DURATION_SEC)
        _active_count += 1
        t.connect("finished", func(): 
            _active_count -= 1
            p.index = p.next_index
            p.next_index = -1
            if _active_count == 0: animate_position_finished.emit()
        )
    
