extends ProgressBar

signal reached_zero

func change_value_to(new_value):
    value = new_value
    
func add_value(amount):
    value += amount
    
func _physics_process(delta):
    value -= (5 + Events.current_level) * delta


func _on_value_changed(value):
    if value <= 1:
        reached_zero.emit()
