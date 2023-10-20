extends TextureRect

## Drag and drop events for pieces.

var piece: Piece

func _can_drop_data(_at_position, _data):
    return true

func _get_drag_data(_at_position):
    return piece

func _drop_data(_at_position, data):
    Events.swap_requested.emit(piece, data)
#    print("text dropped on piece_", piece.index, " from piece_", data.index)
        

