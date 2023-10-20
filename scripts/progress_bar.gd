extends ProgressBar

signal reached_zero

func change_value_to(new_value):
    value = new_value
    
func add_value(amount):
    value += amount
    
func _physics_process(delta):
#    var multiplier = (floor(Events.current_score) + Events.current_level) * 0.1
#    print(Events.current_score / 1000)
    value -= 15 * delta


func _on_value_changed(value):
    if value <= 1:
        reached_zero.emit()
