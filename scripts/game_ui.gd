extends Control

## Handle the UI for the game scene. Not cover the pieces (see grid.gd).

@onready var grid = $CanvasGroup/Grid

func _ready():
    if not grid.is_node_ready():
        await grid.ready
    grid.try_next_match()
    Events.current_level = 1
    
    Events.game_over.connect(func(_score): self.queue_free())
    
func _on_btn_swap_pressed():
    grid.swap_all_random()
