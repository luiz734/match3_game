extends Control

@onready var grid = $CanvasGroup/Grid

func _ready():
    if not grid.is_node_ready():
        await grid.ready
    grid.next_match()
    
func _on_btn_swap_pressed():
    grid.swap_all_random()
 

