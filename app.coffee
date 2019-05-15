
for el in document.querySelectorAll("noscript")
	el.remove()

elToReplaceContentOfOnError = document.getElementById("replace-content-on-error")
cantExportMidiEl = document.getElementById("cant-export-midi")
exportMidiButton = document.getElementById("export-midi-file")

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

#			console.log(e.port, e.port.name, e.port.state, e.port.connection);


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
cantExportMidiEl.textContent = "- No notes recorded yet"

current_pitch_bend_value = 0
global_pitch_bends = []

smi.on 'noteOn', (data)->
	{event, key, velocity} = data
	old_note = current_notes.get(key)
	start_time = performance.now()
	return if old_note
	note = {key, velocity, start_time, pitch_bends: [{time: start_time, value: current_pitch_bend_value}]}
	current_notes.set(key, note)
	notes.push(note)

	cantExportMidiEl.textContent = ""
	exportMidiButton.disabled = false

smi.on 'noteOff', (data)->
	{event, key} = data
	note = current_notes.get(key)
	if note
		note.end_time = performance.now()
		note.length = note.end_time - note.start_time
	current_notes.delete(key)

smi.on 'pitchWheel', (data)->
	{event, value} = data
	current_pitch_bend_value = value
	pitch_bend = {time: performance.now(), value: value}
	global_pitch_bends.push(pitch_bend)
	current_notes.forEach (note, key)->
		note.pitch_bends.push(pitch_bend)

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
			ctx.fillRect(x + pitch_bend.value / 0x2000 * w * 2, y, w, h)
			# console.log x, y, w, h
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
			# TODO: refactor so pitch_bend.value is in the range of -1 to +1
			param2: (pitch_bend.value / 0x2000 + 1) * 64
#			param2: (pitch_bend.value + 0x2000) / 128
#			param2: pitch_bend.value / 128 + 64
		})

	events.sort((a, b)-> a._time - b._time)
	total_track_time = events[events.length - 1]._time
	# TODO: fix track length (end time)?
#	console.log({total_track_time})
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
#			length: 0 # TODO: "Tempo track" name
#		}
		# ...or, remove this "tempo track" if we don't need it
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
	
	blob = new Blob([outputArrayBuffer], {type: "audio/midi"});
	saveAs(blob, "recording.midi");
