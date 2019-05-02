
for el in document.querySelectorAll("noscript")
	el.remove()

midiDevicesTable = document.getElementById("midi-devices")
midiDeviceIDsToRows = new Map

smi = new SimpleMidiInput()

onSuccess = (midi)->
	smi.attach(midi)
#	console.log 'smi: ', smi
#	console.log 'inputs (as a Map): ', new Map(midi.inputs)

	midi.onstatechange = (e)->
		if e.port.type is "input"
			tr = midiDeviceIDsToRows.get(e.port.id)
			unless tr
				tr = document.createElement("tr")
				midiDevicesTable.appendChild(tr)
				midiDeviceIDsToRows.set(e.port.id, tr)
			tr.innerHTML = ""
			tr.className = "midi-device-#{e.port.state}"

			td = document.createElement("td")
			td.setAttribute("aria-label", e.port.state)
			td.className = "midi-device-status"
			tr.appendChild(td)

			td = document.createElement("td")
			td.textContent = e.port.name
			tr.appendChild(td)

#			console.log(e.port.name, e.port.manufacturer, e.port.state);


onError = (err)->
	console.log 'ERROR: ', err
	# TODO: better message (on the page)
	alert("Failed to get MIDI access\n\n#{err}")

if navigator.requestMIDIAccess
	navigator.requestMIDIAccess().then onSuccess, onError
else
	# TODO: better message (on the page)
	alert("Your browser doesn't support MIDI access")

notes = []
current_notes = new Map

current_pitch_bend_value = 0

smi.on 'noteOn', (data)->
	{event, key, velocity} = data
	old_note = current_notes.get(key)
	# current_notes.delete(key)
	start_time = performance.now()
	if old_note
		# console.log("double noteOn?")
		# note = old_note
		return
	note = {key, velocity, start_time, pitch_bends: [{time: start_time, value: current_pitch_bend_value}]}
	current_notes.set(key, note)
	notes.push(note)
	# console.log(event, note)

smi.on 'noteOff', (data)->
	{event, key} = data
	note = current_notes.get(key)
	if note
		# console.log(event, note)
		note.end_time = performance.now()
		note.length = note.end_time - note.start_time
	current_notes.delete(key)

smi.on 'pitchWheel', (data)->
	{event, value} = data
	current_pitch_bend_value = value
	# note = current_notes.get(key)
	# if note
	current_notes.forEach (note, key)->
		# console.log key, note
		# note.pitch_bends ?= []
		note.pitch_bends.push({time: performance.now(), value: value})
		# console.log(event, note)

canvas = document.createElement "canvas"
ctx = canvas.getContext "2d"

document.body.appendChild canvas

px_per_second = 20
do animate = ->
	requestAnimationFrame animate
	now = performance.now()
	canvas.width = innerWidth if canvas.width isnt innerWidth
	canvas.height = innerHeight if canvas.height isnt innerHeight
	ctx.clearRect(0, 0, canvas.width, canvas.height)
	ctx.save()
	ctx.translate(0, canvas.height*4/5)
	ctx.fillStyle = "red"
	ctx.fillRect(0, 1, canvas.width, 1)
	# ctx.globalAlpha = 0.2
	for note in notes
		w = canvas.width / 128
		x = note.key * w
		unless note.length?
			ctx.fillStyle = "#800"
			ctx.fillRect(x, 2, w, 50000)
			# TODO: maybe bend this
		ctx.fillStyle = if note.length then "yellow" else "lime"
		# ctx.strokeStyle = if note.length then "yellow" else "lime"
		for pitch_bend, i in note.pitch_bends
			next_pitch_bend = note.pitch_bends[i + 1]
			y = (pitch_bend.time - now) / 1000 * px_per_second
			# h = (note.length ? now - note.start_time) / 1000 * px_per_second
			end = next_pitch_bend?.time ? note.end_time ? now
			h = (end - pitch_bend.time) / 1000 * px_per_second + 0.5
			ctx.fillRect(x + pitch_bend.value / 1000 * 2, y, w, h)
			# ctx.strokeRect(x + pitch_bend.value / 500, y, w, h)
			# console.log x, y, w, h
	ctx.restore()

document.getElementById("export-midi-file").onclick = ->
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

		max = -Infinity
		min = Infinity
		for pitch_bend in note.pitch_bends
			max = Math.max(pitch_bend.value)
			min = Math.min(pitch_bend.value)
			events.push({
				# delta: <computed later>
				_time: pitch_bend.time
				type: MIDIEvents.EVENT_MIDI
				subtype: MIDIEvents.EVENT_MIDI_PITCH_BEND
				channel: 0
				param1: note.key
#				param2: pitch_bend.value # TODO: range
#				param2: 127 + 127 * pitch_bend.value # TODO: range
#				param2: 127 + 127*2 * pitch_bend.value # TODO: range
#				param2: pitch_bend.value - 1000 # TODO: range
#				param2: pitch_bend.value / 1000 * 2	# TODO: range
				param2: Math.random() * 127	# TODO: range
			})
		console.log({min, max})
		# TODO: EVENT_MIDI_CHANNEL_AFTERTOUCH

	events.sort((a, b)-> a._time - b._time) # TODO: is this right?
	# events.sort((a, b)-> b._time - a._time) # TODO: is this right?
	total_track_time = events[events.length - 1]._time
	console.log({total_track_time})
	# events = .concat(events)
	last_time = null
	# TODO: is this needed?
	BPM = 120
	PPQ = 192
	ms_per_tick = 60000 / (BPM * PPQ)
	for event in events
		unless event.delta?
			if last_time?
				event.delta = (event._time - last_time) / ms_per_tick
			else
				event.delta = 0
				console.log event._time, event.delta
			last_time = event._time
		delete event._time

	events.push({
		delta: 0
		type: MIDIEvents.EVENT_META
		subtype: MIDIEvents.EVENT_META_END_OF_TRACK
		length: 0
	})

	# midiFile.setTrackEvents(0, events)

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
#			length: 0 # TODO: "Tempo track" name
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

	console.log({first_track_events, events})

	outputArrayBuffer = midiFile.getContent()
	
	blob = new Blob([outputArrayBuffer], {type: "audio/midi"});
	saveAs(blob, "recording.midi");
