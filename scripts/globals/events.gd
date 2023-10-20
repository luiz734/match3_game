extends Node

## Holds global signals. Mainly used as a global event bus.

signal new_match_found(m)
signal piece_index_changed(piece: Piece)
signal piece_removed_from_poll(index: int)
signal swap_requested(a, b)
signal piece_scored(pontuation: int)
signal combo_started()
signal combo_changed(value)
signal combo_ended(amount)
signal medium_dificulty_reached
signal hard_dificulty_reached
signal shuffle_requested
signal game_over(score)

# todo: remove all of them and work with signals.
## Gobal variables.
var current_level = 1
var current_score: int = 0
var input_locket = false
