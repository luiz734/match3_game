extends Node2D

## Shows a floating score in each piece that disapears over time when the
## user scores. Alsoo has an AudioStreamPlayer for the sound effets.

const MAX_COMBO_PITCH = 5
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var score_label: Label = $ScoreLabel
var _combo = 0

func init(score, combo):
    $ScoreLabel.text = str(score)
    _combo = combo
    
func _ready():
    assert($ScoreLabel.text != "0")
    audio.pitch_scale = 1 + min(self._combo, MAX_COMBO_PITCH) * 0.1
    audio.play()
    var t = get_tree().create_tween()
    t.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
    await t.finished
    if audio.playing:
        await audio.finished
    self.queue_free()

func _process(delta):
    self.position.y -= 20 * delta
