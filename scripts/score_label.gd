extends Node2D

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
var _combo = 0
const MAX_COMBO_PITCH = 5

func init(score, combo):
    $ScoreLabel.text = str(score)
    _combo = combo
    
func _ready():
    assert($ScoreLabel.text != "0")
    audio.pitch_scale = 1 + min(self._combo, MAX_COMBO_PITCH) * 0.1
    audio.play()
    var t = get_tree().create_tween()
#    t.tween_property(self, "scale", Vector2(0, 0), 0.4)
    t.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
    await t.finished
    if audio.playing:
        await audio.finished
    self.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    self.position.y -= 20 * delta
