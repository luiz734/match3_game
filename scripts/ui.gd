extends Control

@onready var show_dialog = $BottomBar2/UIMarginContainer/hbox/btn_Match
@onready var swap_random = $BottomBar2/UIMarginContainer/hbox/btn_Swap
@onready var grid = $Grid
const DialogContainer = preload("res://scenes/dialog_container.tscn")

@export var dialogs: Array[DialogRes]
var _current_dialog: DialogContainer = null

    
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
    

