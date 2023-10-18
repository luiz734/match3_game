extends TextureRect

var piece: Piece

func _can_drop_data(at_position, data):
    return true

func _get_drag_data(at_position):
    return piece

func _drop_data(at_position, data):
    Events.swap_requested.emit(piece, data)
    print("text dropped on piece_", piece.index, " from piece_", data.index)
        

