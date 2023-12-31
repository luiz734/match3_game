extends Node
class_name PieceGroupTweener

## Handle tween animations for a group of pieces.
## Can only handle 1 animations per time. Calling it
## twice will generates and assertion errors.
## Insted, it should be await for animations to finish.

signal animate_score_finished
signal animate_position_finished
const ScoreLabelPrefab = preload("res://scenes/floating_score_label.tscn")
const SCORE_DURATION_SEC = 0.1
const POSITION_DURATION_SEC = 0.1
var _active_count = 0

func any_animation_playing():
    return _active_count > 0

func animate_score(pieces: Array, multiplier, combo):
    assert(not pieces.is_empty(), "At least one piece is required.")
    assert(_active_count == 0, "Other animation is playing.")
    for p in pieces:
        var t = get_tree().create_tween()
        t.tween_property(p, "scale", Vector2(0, 0), SCORE_DURATION_SEC)
        _active_count += 1
        t.connect("finished", func():
            var score = p.on_score(multiplier)
            var score_label = ScoreLabelPrefab.instantiate()
            score_label.init(score, combo)
            score_label.global_position = p.global_position
            get_tree().get_root().add_child(score_label)
            await get_tree().create_timer(0.3).timeout
            _active_count -= 1
            if _active_count == 0: animate_score_finished.emit()
        )

func animate_position(pieces: Array, len_x: int, spacement: int, sprite_size: int):
    if _active_count != 0: return
    assert(not pieces.is_empty(), "At least one piece is required.")
    assert(_active_count == 0, "Other animation is playing.")
    for p in pieces:
        var t = get_tree().create_tween()
        var p_row = int(p.next_index / len_x)
        var p_col = p.next_index % len_x
        var p_pos = Vector2(p_col * (sprite_size + spacement), p_row * (sprite_size + spacement))
        t.tween_property(p, "position", p_pos, POSITION_DURATION_SEC)
        _active_count += 1
        t.connect("finished", func():
            _active_count -= 1
            p.index = p.next_index
            p.next_index = -1
            if _active_count == 0: animate_position_finished.emit()
        )
