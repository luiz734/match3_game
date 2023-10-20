extends Label

const MEDIUM_DIFFICULTY_TRESHHOLD = 2000
const HARD_DIFFICULTY_TRESHHOLD = 7000

var _done_medium = false
var _done_hard = false

func add_score(amount):
    var new_score = int(text) + amount
    text = str(new_score)
    if not _done_medium and new_score >= MEDIUM_DIFFICULTY_TRESHHOLD:
        _done_medium = true
        Events.medium_dificulty_reached.emit()
    elif not _done_hard and new_score >= HARD_DIFFICULTY_TRESHHOLD:
        _done_hard = true
        Events.hard_dificulty_reached.emit()
