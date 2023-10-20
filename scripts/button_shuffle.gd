extends Button

## Used to remove focus after the button is pressed and focus is gained.

func _on_focus_entered():
    release_focus()
