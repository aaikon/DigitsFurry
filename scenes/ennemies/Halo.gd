extends Node2D

@export var radius := 55.0
@export var point_count := 8
@export var point_radius := 4.0
@export var rotation_speed := 1.5 # radians/sec
@export var color := Color(1.0, 0.85, 0.2, 0.9)

func _process(delta):
	rotation += rotation_speed * delta
	queue_redraw()

func _draw():
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(color.r, color.g, color.b, 0.35), 2.0)
	for i in point_count:
		var angle = TAU * i / point_count
		draw_circle(Vector2(cos(angle), sin(angle)) * radius, point_radius, color)
