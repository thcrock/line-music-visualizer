extends Line2D
class_name TrailSineGlitchy

var queue : Array
var saved_widths : Array
@export var max_height : int
@export var color : Color
@export var bus_id : int
var x_offset : float = 0
var point_every : float = 0.1
var time_since_last_point : float = 0
var y_offset : float = 50
var last_five_frames = {}
const VU_COUNT = 12
const FREQ_MAX = 8000.0
const MIN_DB = 60
var last_sign : bool = false;
var frequenciesLastFrame = {}
var frequenciesThisFrame = {}
var frequencyDiff = 0;
var queueOriginalValues : Array;
var queueRadians : Array;
var queueHowLongLived : Array;
var DEBUG = false;
var rng : RandomNumberGenerator;

var DELTA_MULTIPLIER = 90;

var spectrum


func _mutate_old_points(delta):
	for i in range(1, queue.size()):
		var point = queue[i]
		point.x = point.x - 2
		self.set_point_position(i, point)

		queueHowLongLived[i] += 1

		queue[i] = point

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# move old points to the left
	self._mutate_old_points(delta)
	time_since_last_point += delta
	# if ready, create a new point
	if time_since_last_point > point_every:
		time_since_last_point = 0
		var pos = _get_position()
		var impulse = get_parent().get_impulse()
		var new_angle;
		var unit_y;
		if not impulse:
			impulse = 0
		if queue.size() > 2:
			print('radians is ')
			print(queueRadians[0])
			new_angle = (queueRadians[0] + (delta*DELTA_MULTIPLIER))
			print("newAngle is ")
			print(new_angle)

			
			unit_y = sin(new_angle)
			print('result of sin is ')
			print(unit_y)

			if DEBUG:
				print("Y offset of new point, before scaling for impulse = " + str(unit_y))
		else:
			new_angle = 0
			unit_y = (sin(0 + (delta*DELTA_MULTIPLIER)))
		pos.y  = _get_position().y + unit_y * impulse

		queue.insert(0, pos)

		add_point(pos, 0)
		self.width_curve.bake()
		queueOriginalValues.insert(0, impulse)
		if DEBUG:
			print('pushing arcsin of impulse ' + str(asin(impulse)))
		queueRadians.insert(0, new_angle)
		queueHowLongLived.insert(0, 0)
		if DEBUG:
			print('starting queue')
		for i in range(queue.size()):
			if DEBUG:
				print(queue[i])
				print(queueRadians[i])
		if DEBUG:
			print('ending queue')

	width_curve.clear_points()
	var curve_increment : float = 1.0 / self.get_point_count()
	for i in range(0, self.get_point_count()):
		if saved_widths.size() > i:
			width_curve.add_point(Vector2(curve_increment*i, saved_widths[i]))
		else:
			var newwidth = rng.randf() * 5
			saved_widths.insert(i, newwidth)
			width_curve.add_point(Vector2(curve_increment*i, newwidth))
	width_curve.bake()

	
func _get_position():
	return get_parent().position	


func _ready():
	rng = RandomNumberGenerator.new()
	clear_points()
	#width_curve.clear_points()
