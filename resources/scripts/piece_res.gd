extends Resource
class_name PieceRes

enum PieceType {
    NONE,
    PUMPKIN,
    HEART,
    GHOST,
}

@export var sprite: Texture2D
@export var points: int
@export var type: PieceType
@export var matches: Array[PieceType]
