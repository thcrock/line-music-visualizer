extends Node2D
class_name Trails

@export var width_multiplier : float = 1.0
var queue : Array
var saved_widths : Array
@export var MAX_LENGTH : int
@export var bus_id : int
@export var max_height : int
@export var color : Color
var x_offset : float = 0
var point_every : float = 0.05
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

var DELTA_MULTIPLIER = 4;
var last_parent : Line2D;
var last_point : Vector2;
enum DIRECTION { INC, DEC, EQU }
var current_width_direction : DIRECTION = DIRECTION.EQU;
var last_width = 2.4;
var points_left_in_direction : int = 4;

var spectrum


func _mutate_point(child: Node2D):
	var l = child as Line2D;
	if l.get_point_position(0).x < -200:
		#print('reparenting children of ' + str(child))
		for c2 in child.get_children():
			c2.reparent(self)
			#print('reparented child ' + str(c2))
		child.queue_free()
	else:
		var p1 = l.get_point_position(0)
		p1.x = p1.x - 2
		l.set_point_position(0, p1)
		var p2 = l.get_point_position(1)
		p2.x = p2.x - 2
		l.set_point_position(1, p2)
		for c in child.get_children():
			_mutate_point(c)
		
		
func _mutate_old_points(delta):
	for child in self.get_children():
		_mutate_point(child)

		
		
	for i in range(1, queue.size()):
		var point = queue[i]
		point.x = point.x - 2
		#self.set_point_position(i, point)
		
		var reductionConstant = 0.0
		var reductionFactor = queueHowLongLived[i] * reductionConstant
		var new_amplitude = queueOriginalValues[i] / (1 + reductionFactor)
		#if DEBUG:
			#print("penultimate point amp is " + str(queueOriginalValues[i]))
			#print("new amp is " + str(new_amplitude))
			#print("radians was " + str(queueRadians[i]))
			#print("old point was " + str(point.y))
		if new_amplitude < 0:
			new_amplitude = 0
#		queueRadians[i] += delta * DELTA_MULTIPLIER
#		if DEBUG:
#			print("new radians is " + str(queueRadians[i]))
#		point.y = _get_position().y + (sin(queueRadians[i]) * new_amplitude)
#		if DEBUG:
#			print("new y is " + str(point.y))
		queueHowLongLived[i] += 1

		queue[i] = point
		
		#set_point_position(i,  Vector2(point.x, point.y))	
func _compute_new_width(direction : DIRECTION):
	var new_width;
	if direction == DIRECTION.INC:
		new_width = self.last_width + ((self.points_left_in_direction/2) + rng.randf());
	elif direction == DIRECTION.DEC:
		new_width = self.last_width - ((self.points_left_in_direction/2) + rng.randf());
	else:
		new_width = self.last_width	 + (-0.5 + rng.randf());
		
	var max = 10.0
	var min = 2.0;
	if new_width < min:
		new_width = min;
	if new_width > max:
		new_width = max;
	return new_width
	
func new_line(parent_line: Line2D, fromPos: Vector2, toPos: Vector2, radians: float):
	var line = Line2D.new()
	line.begin_cap_mode = 2
	line.end_cap_mode = 2
	line.joint_mode = 2
	var maxThick = 10
	var minThick = 2
	#print('radians = ' + str(radians))
	var shouldGetThick : bool = true if toPos.y > (fromPos.y + 10) else false
	if shouldGetThick and parent_line != null and parent_line.width < maxThick:
		line.width = parent_line.width + 1.5
	if parent_line == null:
		line.width = minThick
	if not shouldGetThick:
		line.width = minThick
	#print(line.width)
	line.width *= width_multiplier;
		
	self.last_width = line.width;
			
	line.antialiased = true;
	line.default_color = color;
	#line.default_color = Color(255.0/255, 16.0/255, 240.0/255, 1)
	if line.width > minThick:
		var fudgeFactor = line.width - minThick
		fromPos.y += fudgeFactor
		toPos.y += fudgeFactor
	var points = [
		fromPos,
		toPos		
	]
	line.points = points
	if parent_line != null:
		add_child(line)
	else:
		add_child(line)
	return line
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self._mutate_old_points(delta)

	time_since_last_point += delta
	if time_since_last_point > point_every:
		time_since_last_point = 0
		var pos = _get_position()
		#pos.y = get_global_mouse_position().y
		var impulseData = _get_impulse()
		var impulse = impulseData[0]
		var speed = impulseData[1]
		if not impulse:
			impulse = 0
		var impulseRadians = remap(impulse, 0, max_height, -1.0, 1.0)
		var newRadians = 0
		if queue.size() > 2:
			if DEBUG:
				print('prev radians = ' + str(queueRadians[0]))
				print('prev radians + delta = ' + str(queueRadians[0] + (delta*speed)))
				print('with sin = ' + str(sin(queueRadians[0] + (delta*speed))))
			newRadians = (sin(queueRadians[0] + (delta*speed)))
			if DEBUG:
				print("New Radians = " + str(newRadians))
			pos.y = _get_position().y + (newRadians * impulse)
		else:
			pos.y  = _get_position().y + (sin(0 + (delta*DELTA_MULTIPLIER)) * impulse)
			newRadians = 0
		if DEBUG:
			print("pushing impulse " + str(impulse) + " at y " + str(pos.y))


		var old_point = null;
		if last_parent != null:
			old_point = last_parent.get_point_position(1)
			var nl = new_line(last_parent, old_point, pos, newRadians)
			last_parent = nl;
		elif last_point != Vector2.ZERO:
			var nl = new_line(null, last_point, pos, newRadians)
			last_parent = nl;
		else:
			print('initial point = ' + str(pos))
			last_point = pos
		queueOriginalValues.insert(0, impulse)
		if DEBUG:
			print('pushing arcsin of impulse ' + str(asin(impulse)))
		queue.insert(0, pos)
		queueRadians.insert(0, asin(impulse))
		queueHowLongLived.insert(0, 0)
		if DEBUG:
			print('starting queue')
		for i in range(queue.size()):
			if DEBUG:
				print(queue[i])
				print(queueRadians[i])
		if DEBUG:
			print('ending queue')


func _get_position():
	return get_global_mouse_position()


func _save_frequencies():
	var prev_hz = 0
	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		#print(str(hz) + ", " + str(magnitude))
		self.frequenciesThisFrame[hz] = linear_to_db(magnitude)
		prev_hz = hz
	#print(self.frequenciesThisFrame)

func _frequency_diff():
	var totalFrequencyDiff : float = 0;
	var biggestFrequencyDiff : float = 0;
	var frequencyOfBiggestDiff : float = 0;
	for k in self.frequenciesThisFrame:
		var v = self.frequenciesThisFrame[k]
		var thisFrequencyDiff = 0;
		if k in self.frequenciesLastFrame:
			thisFrequencyDiff = v - self.frequenciesLastFrame[k]
			#print('change of ' + str(thisFrequencyDiff))
		else:
			thisFrequencyDiff = v
			#print('new of ' + str(thisFrequencyDiff))
		if thisFrequencyDiff > biggestFrequencyDiff:
			biggestFrequencyDiff = thisFrequencyDiff
			frequencyOfBiggestDiff = k
		totalFrequencyDiff += thisFrequencyDiff
	#print("Total frequency diff: " + str(totalFrequencyDiff))
	return [totalFrequencyDiff, frequencyOfBiggestDiff]
			

func _get_impulse():
	var data = []
	var total_magnitude = 0
	var prev_hz = 0
	var highest_magnitude = 0
	var highest_hz = 0
	var pstr = ''
	self._save_frequencies()
	var frequencyDiffInfo = self._frequency_diff()
	var frequencyDiff = frequencyDiffInfo[0]
	var frequencyWithBiggestDiff = frequencyDiffInfo[1]
	"""
	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		if hz == highest_hz:
			data.append([hz, energy])
		prev_hz = hz
	var final_hz = 0
	var final_energy = 0
	for row in data:
		final_hz += row[0]
		final_energy += row[1]
	var energy = clampf((MIN_DB + linear_to_db(final_energy)) / MIN_DB, 0, 1)
	if not data:
		return []
	"""
	
	self.frequenciesLastFrame = self.frequenciesThisFrame.duplicate(true)
	if DEBUG:
		print("frequencyDiff = " + str(frequencyDiff))
	if is_inf(frequencyDiff) or is_nan(frequencyDiff):
		frequencyDiff = 0.0
	var impulse = remap(frequencyDiff, -200, 200, 0, max_height)
	if impulse < 0:
		impulse = 0
	#if DEBUG:
		#print("impulse = " + str(impulse))
	#impulse = 50
	#print('frequency with biggest diff = ' + str(frequencyWithBiggestDiff))
	var speed = 0
	if frequencyWithBiggestDiff > 4000:
		speed = 10.0
	elif frequencyWithBiggestDiff > 1000:
		speed = 4.0
	else:
		speed = 1.0
	return [impulse, speed]

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(bus_id, 0)
	rng = RandomNumberGenerator.new()
	#width_curve.clear_points()
