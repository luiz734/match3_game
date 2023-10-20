extends Control

@onready var score_label: Label = $Background/MarginContainer/ScoreLabel
var _score_value: String = ""

func _ready():
    assert(not _score_value.is_empty(), "call init() first")
    score_label.text = _score_value

func init(score):
    _score_value= str(score)

func _on_button_pressed():
    self.queue_free()
