@tool
extends MarginContainer
class_name UIMarginContainer

## A easy-to-configure margin.

@export var margin_width: Res.Width:
    set(value):
        margin_width = value
        var margin_value: int = Res.get_margin_width(margin_width)
        set("theme_override_constants/margin_left", margin_value)
        set("theme_override_constants/margin_top", margin_value)
        set("theme_override_constants/margin_bottom", margin_value)
        set("theme_override_constants/margin_right", margin_value)
    get:
        return margin_width
