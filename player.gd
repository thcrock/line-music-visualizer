extends CharacterBody2D

func _physics_process(_delta):
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 300
	move_and_slide()
	
