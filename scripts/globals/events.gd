extends Node

## Hold global signals. Mainly used as a global event bus.

class UserChoice:
    var button_value: int
    func _init(button_value):
        self.button_value = button_value

## when users skip a cutscene, dialog, etc
signal user_skip_talk

## when user send some input option on the gui (like choose yes or no)
signal user_confirm(data)