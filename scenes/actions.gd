extends VBoxContainer

const DebugLabel = preload("res://debug/debug_label.tscn")

func _ready():
    Events.connect("new_match_found", on_new_match_found)

func on_new_match_found(m):
    var dl: Label = DebugLabel.instantiate()
    dl.text = str(m)
    add_child(dl)
