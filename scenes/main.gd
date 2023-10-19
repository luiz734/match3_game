extends Node2D


const UiGamePrefab = preload("res://game.tscn")
const UiGameOverPrefab = preload("res://game_over.tscn")
var ui_game = null
var ui_game_over = null
@onready var ui_menu = $MainMenu

func _ready():
    get_window().size *= 2
    get_window().position = Vector2.ZERO
    Events.game_over.connect(on_game_over)
    
func on_game_over(score):
    ui_game_over = UiGameOverPrefab.instantiate()
    ui_game_over.init(score)
    add_child(ui_game_over) 

func _on_btn_new_game_pressed():
    assert(not ui_game and not ui_game_over)
    ui_game = UiGamePrefab.instantiate()
    add_child(ui_game)

func _on_btn_exit_pressed():
    get_tree().quit()

func _input(event):
    if event.is_action_pressed("GoBack"):
#        if ui_game:
#            ui_game.queue_free()
#            ui_game = null
        if ui_game:
            ui_game.queue_free()
            ui_game = null
        else:
            get_tree().quit()
        
