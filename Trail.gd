extends Line2D
class_name Trails

var queue : Array
var saved_widths : Array
@export var MAX_LENGTH : int
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

var DELTA_MULTIPLIER = 4;

var spectrum


func _mutate_old_points(delta):
	for i in range(1, queue.size()):
		var point = queue[i]
		point.x = point.x - 2
		self.set_point_position(i, point)
		
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
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self._mutate_old_points(delta)
	#if not queue:
	#	var pos = _get_position()
	#	pos.x = pos.x + 15
	#	queue.push_front(pos)
	#	queueRadians.push_front(0)
	#	queueHowLongLived.push_front(0)
	#	queueOriginalValues.push_front(0)
	#	time_since_last_point = 0
	time_since_last_point += delta
	if time_since_last_point > point_every:
		time_since_last_point = 0
		var pos = _get_position()
		#pos.y = get_global_mouse_position().y
		var impulse = _get_impulse()
		if not impulse:
			impulse = 0
		var impulseRadians = remap(impulse, 0, 200, -1.0, 1.0)
		#print("adding height " + str(energied_height))
		#if last_sign:
			#pos.y += impulse
			#last_sign = false
		#else:
		if queue.size() > 2:
			if DEBUG:
				print('prev radians = ' + str(queueRadians[0]))
				print('prev radians + delta = ' + str(queueRadians[0] + (delta*DELTA_MULTIPLIER)))
				print('with sin = ' + str(sin(queueRadians[0] + (delta*DELTA_MULTIPLIER))))
			var newRadians = (sin(queueRadians[0] + (delta*DELTA_MULTIPLIER)))
			if DEBUG:
				print("New Radians = " + str(newRadians))
			pos.y = _get_position().y + (newRadians * impulse)
			#if impulse:
			#	pos.y = pos.y + (sin(queueRadians[-1] - (delta*3)))
			#else:
				#pos.y = pos.y + (sin(queueRadians[-1] - (delta*3)))
		else:
			pos.y  = _get_position().y + (sin(0 + (delta*DELTA_MULTIPLIER)) * impulse)
		if DEBUG:
			print("pushing impulse " + str(impulse) + " at y " + str(pos.y))
			#last_sign = true
		queue.insert(0, pos)
		add_point(pos, 0)
		width_curve.clear_points()
		#print('point count = ' + str(self.get_point_count()))
		#print('saved width count = ' + str(saved_widths.size()))
		var curve_increment : float = 1.0 / self.get_point_count()
		for i in range(0, self.get_point_count()):
			if saved_widths.size() > i:
				width_curve.add_point(Vector2(curve_increment*i, saved_widths[i]))
			else:
				var newwidth = rng.randf() * 5
				saved_widths.insert(i, newwidth)
				width_curve.add_point(Vector2(curve_increment*i, newwidth))
			#print('added at curve increment ' + str(curve_increment*i))
		#print(saved_widths)
		width_curve.bake()
		queueOriginalValues.insert(0, impulse)
		if DEBUG:
			print('pushing arcsin of impulse ' + str(asin(impulse)))
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
		
	#clear_points()
	#if queue.size() > 0:
		#add_point(queue[0])
	#if DEBUG:
	#	print('starting queue')
	#add_point(Vector2(630, 300))
	#self.width_curve.clear_points()
	#for point in queue:
	#	self.width_curve.add_point(point)
	#self.width_curve.bake()
	#for i in range(0, queue.size()):
	#	add_point(self.queue[i])
	#if DEBUG:
	#	print('ending queue')
	#var p = self.width_curve.get_baked_points
	#print(p)


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
	for k in self.frequenciesThisFrame:
		var v = self.frequenciesThisFrame[k]
		var thisFrequencyDiff = 0;
		if k in self.frequenciesLastFrame:
			thisFrequencyDiff = v - self.frequenciesLastFrame[k]
			#print('change of ' + str(thisFrequencyDiff))
		else:
			thisFrequencyDiff = v
			#print('new of ' + str(thisFrequencyDiff))
		totalFrequencyDiff += thisFrequencyDiff
	#print("Total frequency diff: " + str(totalFrequencyDiff))
	return totalFrequencyDiff
			

func _get_impulse():
	var data = []
	var total_magnitude = 0
	var prev_hz = 0
	var highest_magnitude = 0
	var highest_hz = 0
	var pstr = ''
	self._save_frequencies()
	var frequencyDiff = self._frequency_diff()
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
	var impulse = remap(frequencyDiff, -200, 200, 0, 200)
	if impulse < 0:
		impulse = 0
	#if DEBUG:
		#print("impulse = " + str(impulse))
	#impulse = 50
	return impulse

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	rng = RandomNumberGenerator.new()
	width_curve.clear_points()
