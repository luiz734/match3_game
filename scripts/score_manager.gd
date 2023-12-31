extends Node2D

## Handles the score related logic.

@export var progress: ProgressBar
@export var level: Label
@export var button: Button
@export var score: Label
var _combo_length: int = 0
var _combo_sum: int = 0
var _can_gain_level: bool = true

func _ready():
    Events.combo_started.connect(self.on_combo_started)
    Events.combo_ended.connect(self.on_combo_ended)
    Events.combo_changed.connect(self.on_combo_changed)
    Events.piece_scored.connect(self.on_piece_scored)
    progress.reached_zero.connect(self.on_progess_reached_zero)

func on_combo_started():
#    print("combo started")
    _combo_sum = 0

func on_combo_changed(value):
    _combo_length = value
    
func on_combo_ended(_length):
    _can_gain_level = true
    
func on_piece_scored(amount):
    _combo_sum += amount
    score.add_score(amount)
    
    if progress.value >= 99:
        progress.value = 5
        Events.current_level += 1
        level.set_level(Events.current_level)
        score.add_score(200)
        
    button.disabled = Events.current_level <= 0
        
    progress.add_value(amount * (0.1 + 0.9 / (max(0, Events.current_level)) + 1))

func lose_level():
    Events.current_level -= 1
    if Events.current_level == -1:
        print("Game Over")
        Events.game_over.emit(int(score.text))
    level.set_level(Events.current_level)
    button.disabled = Events.current_level <= 0

func on_progess_reached_zero():
    progress.change_value_to(100)
    lose_level()

func _on_btn_shuffle_pressed():
    if Events.input_locket:
        return
    lose_level()
    Events.shuffle_requested.emit()
    
