extends Label


func gain_level():
    text = str(int(text) + 1)
    
func lose_level():
    text = str(int(text) - 1)
