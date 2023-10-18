extends Node2D

const UiGamePrefab = preload("res://game.tscn")
var ui_game = null
@onready var ui_menu = $MainMenu

func _ready():
    # hack: use project config instead
    get_window().size *= 2
    get_window().position = Vector2.ZERO

func _on_btn_new_game_pressed():
    assert(not ui_game)
    ui_game = UiGamePrefab.instantiate()
    add_child(ui_game)

func _on_btn_exit_pressed():
    get_tree().quit()

func _input(event):
    if event.is_action_pressed("GoBack"):
        if ui_game:
            ui_game.queue_free()
            ui_game = null
        else:
            get_tree().quit()
        
