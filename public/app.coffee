
for el in document.querySelectorAll("noscript")
	el.remove() # for screenreaders (maybe should be earlier than this asynchronously loaded coffeescript)

elToReplaceContentOfOnError = document.querySelector(".replace-content-on-error") ? document.body
fullscreenTarget = document.getElementById("fullscreen-target")
canvas = document.getElementById("midi-viz-canvas")
noNotesRecordedMessageEl = document.getElementById("no-notes-recorded-message")
exportMidiButton = document.getElementById("export-midi-file")
fullscreenButton = document.getElementById("fullscreen-button")
midiRangeMinInput = document.getElementById("midi-range-min")
midiRangeMaxInput = document.getElementById("midi-range-max")
learnMidiRangeButton = document.getElementById("learn-midi-range")
learnMidiRangeButtonLabel = document.getElementById("learn-midi-range-button-text")
applyMidiRangeButtonLabel = document.getElementById("apply-midi-range-button-text")
cancelLearnMidiRangeButton = document.getElementById("cancel-learn-midi-range")

isLearningRange = false
learningRange = [null, null]
selectedRange = [0, 128]
viewRangeWhileLearning = [0, 128]

showErrorReplacingUI = (message, error)->
	errorMessageEl = document.createElement("div")
	errorMessageEl.className = "error-message"
	errorMessageEl.textContent = message
	if error
		errorPre = document.createElement("pre")
		errorPre.textContent = error
		errorMessageEl.appendChild(errorPre)
	elToReplaceContentOfOnError.innerHTML = ""
	elToReplaceContentOfOnError.appendChild(errorMessageEl)

normalize_range = (range)->
	valid_int_0_to_128 = (value)->
		int = parseInt(value)
		return null if isNaN(int) or int < 0 or int > 128
		return int 
	return [
		valid_int_0_to_128(range[0]) ? 0
		valid_int_0_to_128(range[1]) ? 128
	]

setSelectedRange = (range)->
	selectedRange = normalize_range(range)
	unless isLearningRange
		[midiRangeMinInput.value, midiRangeMaxInput.value] = selectedRange

saveOptions = ->
	[from_midi_val, to_midi_val] = selectedRange
	data =
		"midi-range": "#{from_midi_val}..#{to_midi_val}"
	keyvals =
		for key, val of data
			"#{key}=#{val}"
	location.hash = keyvals.join("&")
	
	# NOTE: (sort of) redundantly loading options from hash on hashchange after setting hash
	# This actually applies the normalization tho so it's kind of nice
	# e.g. 1.0 -> 1, 1.5 -> 1, 1000 -> 128
	# altho it's inconsistent in when it gets applied - if the hash is the same (i.e. because the normalized values are the same), it doesn't update
	# so for example 1.0 -> 1 followed by 1.5 -> 1 doesn't actually normalize, and gets left on the invalid value 1.5

	# I'm not sure this is the best behavior, to apply normalization to invalid user inputs, but let's at least be consistent
	# (and further redundant in the case that a hashchange will occur)
	loadOptions()

loadOptions = ->
	data = {}
	for keyval in location.hash.replace(/^#/, "").split("&") when keyval.match(/=/)
		[key, val] = keyval.split("=")
		key = key.trim()
		val = val.trim()
		data[key] = val
	if data["midi-range"]
		setSelectedRange(data["midi-range"].split(".."))

loadOptions()

addEventListener("hashchange", loadOptions)

update_range_from_inputs = ->
	setSelectedRange([midiRangeMinInput.value, midiRangeMaxInput.value])
	saveOptions()

midiRangeMinInput.onchange = update_range_from_inputs
midiRangeMaxInput.onchange = update_range_from_inputs


midiDevicesTable = document.getElementById("midi-devices")
midiDeviceIDsToRows = new Map

smi = new SimpleMidiInput()

onSuccess = (midi)->
	smi.attach(midi)
#	console.log 'smi: ', smi
#	console.log 'inputs (as a Map): ', new Map(midi.inputs)

	midi.onstatechange = (e)->
		if e.port.type is "input"
			connected = e.port.state is "connected" and e.port.connection is "open"

			tr = midiDeviceIDsToRows.get(e.port.id)
			unless tr
				tr = document.createElement("tr")
				midiDevicesTable.appendChild(tr)
				midiDeviceIDsToRows.set(e.port.id, tr)
			tr.innerHTML = ""
			tr.className = "midi-port midi-device-is-#{e.port.state}#{if connected then " midi-port-is-open" else ""}"

			td = document.createElement("td")
			td.setAttribute("aria-label", (if connected then "connected" else "disconnected"))
			td.className = "midi-port-status"
			tr.appendChild(td)

			td = document.createElement("td")
			td.textContent = e.port.name
			tr.appendChild(td)

			# auto detect range based on device
			# not sure if I should do this, considering there are instruments that transpose up or down an octave
			# as well as user-explicit transposition
			# if connected
			# 	unless location.hash.match(/midi-range/)
			# 		if e.port.name is "Yamaha Portable G-1"
			# 			setSelectedRange([28, 103])

#			console.log(e.port, e.port.name, e.port.state, e.port.connection)


onError = (error)->
	showErrorReplacingUI("Failed to get MIDI access", error)
	console.log "requestMIDIAccess failed:", error

if navigator.requestMIDIAccess
	navigator.requestMIDIAccess().then onSuccess, onError
else
	showErrorReplacingUI("Your browser doesn't support MIDI access.")

notes = []
current_notes = new Map
exportMidiButton.disabled = true

current_pitch_bend_value = 0
global_pitch_bends = []

smi.on 'noteOn', (data)->
	{event, key, velocity} = data
	old_note = current_notes.get(key)
	start_time = performance.now()
	return if old_note
	note = {key, velocity, start_time, pitch_bends: [{
		time: start_time,
		value: current_pitch_bend_value,
	}]}
	current_notes.set(key, note)
	notes.push(note)

	noNotesRecordedMessageEl.hidden = true
	exportMidiButton.disabled = false

	if isLearningRange
		learningRange[0] = Math.min(learningRange[0] ? key, key)
		learningRange[1] = Math.max(learningRange[1] ? key, key)
		[midiRangeMinInput.value, midiRangeMaxInput.value] = learningRange

smi.on 'noteOff', (data)->
	{event, key} = data
	note = current_notes.get(key)
	if note
		note.end_time = performance.now()
		note.length = note.end_time - note.start_time
	current_notes.delete(key)

smi.on 'pitchWheel', (data)->
	{event, value} = data
	value /= 0x2000
	current_pitch_bend_value = value
	pitch_bend = {time: performance.now(), value}
	global_pitch_bends.push(pitch_bend)
	current_notes.forEach (note, key)->
		note.pitch_bends.push(pitch_bend)

ctx = canvas.getContext "2d"

px_per_second = 20
do animate = ->
	if isLearningRange
		[min_midi_val, max_midi_val] = viewRangeWhileLearning
	else
		[left_midi_val, right_midi_val] = selectedRange
		min_midi_val = Math.min(left_midi_val, right_midi_val)
		max_midi_val = Math.max(left_midi_val, right_midi_val)
	requestAnimationFrame animate
	now = performance.now()
	canvas.width = innerWidth if canvas.width isnt innerWidth
	canvas.height = innerHeight if canvas.height isnt innerHeight
	ctx.clearRect(0, 0, canvas.width, canvas.height)
	ctx.save()
	if left_midi_val > right_midi_val
		ctx.translate(canvas.width, 0)
		ctx.scale(-1, 1)
	ctx.translate(0, canvas.height*4/5)
	ctx.fillStyle = "red"
	ctx.fillRect(0, 1, canvas.width, 1)
	# ctx.globalAlpha = 0.2
	for note in notes
		w = canvas.width / (max_midi_val - min_midi_val + 1)
		x = (note.key - min_midi_val) * w
		unless note.length?
			# for ongoing (held) notes, display a bar at the bottom like a key
			# TODO: maybe bend this?
			ctx.fillStyle = "#800"
			ctx.fillRect(x, 2, w, 50000)
		ctx.fillStyle = if note.length then "yellow" else "lime"
		# ctx.strokeStyle = if note.length then "yellow" else "lime"
		for pitch_bend, i in note.pitch_bends
			next_pitch_bend = note.pitch_bends[i + 1]
			y = (pitch_bend.time - now) / 1000 * px_per_second
			# h = (note.length ? now - note.start_time) / 1000 * px_per_second
			end = next_pitch_bend?.time ? note.end_time ? now
			h = (end - pitch_bend.time) / 1000 * px_per_second + 0.5
			ctx.fillRect(x + pitch_bend.value * w * 2, y, w, h)
			# console.log x, y, w, h
	if isLearningRange
		for extremity_midi_val, i in learningRange
			if extremity_midi_val?
				w = canvas.width / (max_midi_val - min_midi_val + 1)
				x = (extremity_midi_val - min_midi_val) * w
				ctx.fillStyle = "red"
				ctx.fillRect(x, 0, w, canvas.height)
	ctx.restore()

exportMidiButton.onclick = ->
	midiFile = new MIDIFile()

	if notes.length is 0
		alert "No notes have been recorded!"
		return

	events = []
	for note in notes
		events.push({
			# delta: <computed later>
			_time: note.start_time
			type: MIDIEvents.EVENT_MIDI
			subtype: MIDIEvents.EVENT_MIDI_NOTE_ON
			channel: 0
			param1: note.key
			param2: note.velocity
		})
		events.push({
			# delta: <computed later>
			_time: note.end_time
			type: MIDIEvents.EVENT_MIDI
			subtype: MIDIEvents.EVENT_MIDI_NOTE_OFF
			channel: 0
			param1: note.key
			param2: 5 # TODO?
		})

	# TODO: EVENT_MIDI_CHANNEL_AFTERTOUCH

	for pitch_bend in global_pitch_bends
		events.push({
			# delta: <computed later>
			_time: pitch_bend.time
			type: MIDIEvents.EVENT_MIDI
			subtype: MIDIEvents.EVENT_MIDI_PITCH_BEND
			channel: 0
			param1: note.key
			param2: (pitch_bend.value + 1) * 64
#			param2: ((pitch_bend.value + 1) * 0x2000) / 128
#			param2: pitch_bend.value * 0x2000 / 128 + 64
#			param2: pitch_bend.value * 0x1000 / 64 + 64
		})

	events.sort((a, b)-> a._time - b._time)
	total_track_time = events[events.length - 1]._time
	last_time = null
	BPM = 120 # beats per minute
	PPQ = 192 # pulses per quarter note
	ms_per_tick = 60000 / (BPM * PPQ)
#	console.log({total_track_time, ms_per_tick})
	for event in events
		unless event.delta?
			if last_time?
				event.delta = (event._time - last_time) / ms_per_tick
			else
				event.delta = 0
			last_time = event._time
		delete event._time

	events.push({
		delta: 0
		type: MIDIEvents.EVENT_META
		subtype: MIDIEvents.EVENT_META_END_OF_TRACK
		length: 0
	})

	first_track_events = [
		{
			delta: 0
			type: MIDIEvents.EVENT_META
			subtype: MIDIEvents.EVENT_META_TIME_SIGNATURE
			length: 4
			data: [4, 2, 24, 8]
			param1: 4
			param2: 2
			param3: 24
			param4: 8
		}
		{
			delta: 0
			type: MIDIEvents.EVENT_META
			subtype: MIDIEvents.EVENT_META_SET_TEMPO
			length: 3
			tempo: 500000
			tempoBPM: 120 # not used
		}
#		{
#			delta: 0
#			type: MIDIEvents.EVENT_META
#			subtype: MIDIEvents.EVENT_META_TRACK_NAME
#			length: 0 # TODO: name "Tempo track" / "Meta track" / "Conductor track"
#		}
		{
			delta: ~~total_track_time
			type: MIDIEvents.EVENT_META
			subtype: MIDIEvents.EVENT_META_END_OF_TRACK
			length: 0
		}
	]
	midiFile.setTrackEvents(0, first_track_events)
	midiFile.addTrack(1)
	midiFile.setTrackEvents(1, events)

#	console.log({first_track_events, events})

	outputArrayBuffer = midiFile.getContent()
	
	blob = new Blob([outputArrayBuffer], {type: "audio/midi"})
	saveAs(blob, "recording.midi")


fullscreenButton.onclick = ->
	if fullscreenTarget.requestFullscreen
		fullscreenTarget.requestFullscreen()
	else if fullscreenTarget.mozRequestFullScreen
		fullscreenTarget.mozRequestFullScreen()
	else if fullscreenTarget.webkitRequestFullScreen
		fullscreenTarget.webkitRequestFullScreen()

endLearnMidiRange = ->
	isLearningRange = false
	cancelLearnMidiRangeButton.hidden = true
	applyMidiRangeButtonLabel.hidden = true
	learnMidiRangeButtonLabel.hidden = false
	learningRange = [null, null]
	midiRangeMinInput.disabled = false
	midiRangeMaxInput.disabled = false
	[midiRangeMinInput.value, midiRangeMaxInput.value] = selectedRange

learnMidiRangeButton.onclick = ->
	if isLearningRange
		setSelectedRange(learningRange)
		saveOptions()
		endLearnMidiRange()
	else
		isLearningRange = true
		cancelLearnMidiRangeButton.hidden = false
		applyMidiRangeButtonLabel.hidden = false
		learnMidiRangeButtonLabel.hidden = true
		learningRange = [null, null]
		midiRangeMinInput.disabled = true
		midiRangeMaxInput.disabled = true
		[midiRangeMinInput.value, midiRangeMaxInput.value] = viewRangeWhileLearning

cancelLearnMidiRangeButton.onclick = endLearnMidiRange

KEYCODE_ESC = 27

# supposedly keydown doesn't work consistently in all browsers
document.body.addEventListener "keydown", (event)->
	if event.keyCode is KEYCODE_ESC
		endLearnMidiRange()
document.body.addEventListener "keyup", (event)->
	if event.keyCode is KEYCODE_ESC
		endLearnMidiRange()
