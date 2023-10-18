extends Control

#const MenuPrefab = preload("res://main_menu.tscn") 
@onready var show_dialog = $BottomBar2/UIMarginContainer/hbox/btn_Match
@onready var swap_random = $BottomBar2/UIMarginContainer/hbox/btn_Swap
@onready var label_score: Label = $TopBar/hbox/Score
@onready var grid = $CanvasGroup/Grid
const DialogContainer = preload("res://scenes/dialog_container.tscn")

var _score = 0

@export var dialogs: Array[DialogRes]
var _current_dialog: DialogContainer = null

func _ready():
    Events.piece_scored.connect(func(x):
        _score += x
        label_score.text = str(_score))
        
    if not grid.is_node_ready():
        await grid.ready
    grid.next_match()
    
    
func on_dialog_finished(choice):
    pass
    


func _on_button_pressed():
    grid.next_match()
    
func _on_btn_swap_pressed():
    grid.swap_random()
 

    
#    if _current_dialog:
#        return
#
#    if not dialogs.is_empty():
#        _current_dialog = DialogContainer.instantiate()
#        _current_dialog.connect("dialog_finished", on_dialog_finished)
#        add_child(_current_dialog)
#
#        _current_dialog.start_dialog(dialogs.pop_back())
#        await _current_dialog.dialog_finished
#
#        _current_dialog = null
#        print_debug('dialog done')
    

