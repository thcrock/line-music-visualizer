extends Node
@export var bus_id : int
@export var max_impulse : int
var spectrum
var DEBUG : bool = true
const FREQUENCY_RANGES = [
	[0, 100],
	[100, 250],
	[250, 500],
	[500, 1000],
	[1000, 2000],
	[2000, 3000],
	[3000, 5000],
	[5000, 7500],
	[7500, 10000]
]
var frequenciesLastFrame = {}
var frequenciesThisFrame = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	spectrum = AudioServer.get_bus_effect_instance(bus_id, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _save_frequencies():
	var prev_hz = 0
	for band in FREQUENCY_RANGES:
		var lo = band[0]
		var hi = band[1]
		var magnitude = spectrum.get_magnitude_for_frequency_range(lo, hi).length()
		#print("from " + str(lo) + " to " + str(hi) + "  has raw magnitude of " + str(magnitude))
		self.frequenciesThisFrame[hi] = linear_to_db(magnitude)

func _frequency_diff():
	var totalFrequencyDiff : float = 0;
	var biggestFrequencyDiff : float = 0;
	var frequencyOfBiggestDiff : float = 0;
	for k in self.frequenciesThisFrame:
		var v = self.frequenciesThisFrame[k]
		var thisFrequencyDiff = 0;
		if k in self.frequenciesLastFrame:
			thisFrequencyDiff = v - self.frequenciesLastFrame[k]
			if DEBUG:
				print('band ' + str(k) + ' had change of ' + str(thisFrequencyDiff))
		else:
			thisFrequencyDiff = v
			if DEBUG:
				print('band ' + k + ' had new ' + str(thisFrequencyDiff))
		if thisFrequencyDiff > biggestFrequencyDiff:
			biggestFrequencyDiff = thisFrequencyDiff
			frequencyOfBiggestDiff = k
		if thisFrequencyDiff > 0:
			totalFrequencyDiff += thisFrequencyDiff
	if DEBUG:
		print("Total frequency diff: " + str(totalFrequencyDiff))
	return [totalFrequencyDiff, frequencyOfBiggestDiff]

func get_impulse():
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
	
	self.frequenciesLastFrame = self.frequenciesThisFrame.duplicate(true)
	if DEBUG:
		print("frequencyDiff = " + str(frequencyDiff))
	if is_inf(frequencyDiff) or is_nan(frequencyDiff):
		frequencyDiff = 0.0
	var impulse = remap(frequencyDiff, 0, 200, 0, max_impulse)	
	if impulse < 0:
		impulse = 0
	#impulse = 50
	#print('returning impulse of ' + str(impulse))
	#return 50
	return impulse
