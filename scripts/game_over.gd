extends Control

@onready var score: Label = $Background/MarginContainer/ScoreLabel
var _score_value: String = ""

func _ready():
    assert(not _score_value.is_empty(), "call init() first")
    score.text = _score_value

func init(score):
    _score_value= str(score)

func _process(delta):
    pass

func _on_button_pressed():
    self.queue_free()
