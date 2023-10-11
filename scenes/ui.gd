extends Control

@onready var show_dialog = $btn_ShowDialog
const DialogContainer = preload("res://scenes/dialog_container.tscn")

@export var dialogs: Array[DialogRes]
var _current_dialog: DialogContainer = null

    
func on_dialog_finished(choice):
    pass

func _on_button_pressed():
    if _current_dialog:
        return
        
    if not dialogs.is_empty():
        _current_dialog = DialogContainer.instantiate()
        _current_dialog.connect("dialog_finished", on_dialog_finished)
        add_child(_current_dialog)
        
        _current_dialog.start_dialog(dialogs.pop_back())
        await _current_dialog.dialog_finished
        
        _current_dialog = null
        print_debug('dialog done')
    
