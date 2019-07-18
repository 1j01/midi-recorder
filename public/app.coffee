
for el in document.querySelectorAll("noscript")
	el.remove() # for screenreaders (maybe should be earlier than this asynchronously loaded coffeescript)

el_to_replace_content_of_on_error = document.querySelector(".replace-content-on-error") ? document.body
fullscreen_target_el = document.getElementById("fullscreen-target")
canvas = document.getElementById("midi-viz-canvas")
no_notes_recorded_message_el = document.getElementById("no-notes-recorded-message")
export_midi_file_button = document.getElementById("export-midi-file-button")
fullscreen_button = document.getElementById("fullscreen-button")
midi_range_left_input = document.getElementById("midi-range-min")
midi_range_right_input = document.getElementById("midi-range-max")
learn_range_or_apply_button = document.getElementById("learn-range-or-apply-button")
learn_range_text_el = document.getElementById("learn-midi-range-button-text")
apply_text_el = document.getElementById("apply-midi-range-button-text")
cancel_learn_range_button = document.getElementById("cancel-learn-midi-range-button")
midi_devices_table = document.getElementById("midi-devices")

is_learning_range = false
learning_range = [null, null]
selected_range = [0, 128]
view_range_while_learning = [0, 128]

show_error_screen_replacing_ui = (message, error)->
	error_message_el = document.createElement("div")
	error_message_el.className = "error-message"
	error_message_el.textContent = message
	if error
		error_pre = document.createElement("pre")
		error_pre.textContent = error
		error_message_el.appendChild(error_pre)
	el_to_replace_content_of_on_error.innerHTML = ""
	el_to_replace_content_of_on_error.appendChild(error_message_el)

normalize_range = (range)->
	valid_int_0_to_128 = (value)->
		int = parseInt(value)
		return null if isNaN(int) or int < 0 or int > 128
		return int 
	return [
		valid_int_0_to_128(range[0]) ? 0
		valid_int_0_to_128(range[1]) ? 128
	]

set_selected_range = (range)->
	selected_range = normalize_range(range)
	unless is_learning_range
		[midi_range_left_input.value, midi_range_right_input.value] = selected_range

save_options = ->
	[from_midi_val, to_midi_val] = selected_range
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
	load_options()

load_options = ->
	data = {}
	for keyval in location.hash.replace(/^#/, "").split("&") when keyval.match(/=/)
		[key, val] = keyval.split("=")
		key = key.trim()
		val = val.trim()
		data[key] = val
	if data["midi-range"]
		set_selected_range(data["midi-range"].split(".."))

load_options()

addEventListener("hashchange", load_options)

update_selected_range_from_inputs = ->
	set_selected_range([midi_range_left_input.value, midi_range_right_input.value])
	save_options()

midi_range_left_input.onchange = update_selected_range_from_inputs
midi_range_right_input.onchange = update_selected_range_from_inputs


midi_device_ids_to_rows = new Map

smi = new SimpleMidiInput()

on_success = (midi)->
	smi.attach(midi)
#	console.log 'smi: ', smi
#	console.log 'inputs (as a Map): ', new Map(midi.inputs)

	midi.onstatechange = (e)->
		if e.port.type is "input"
			connected = e.port.state is "connected" and e.port.connection is "open"

			tr = midi_device_ids_to_rows.get(e.port.id)
			unless tr
				tr = document.createElement("tr")
				midi_devices_table.appendChild(tr)
				midi_device_ids_to_rows.set(e.port.id, tr)
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
			# 			set_selected_range([28, 103])

#			console.log(e.port, e.port.name, e.port.state, e.port.connection)


on_error = (error)->
	show_error_screen_replacing_ui("Failed to get MIDI access", error)
	console.log "requestMIDIAccess failed:", error

if navigator.requestMIDIAccess
	navigator.requestMIDIAccess().then on_success, on_error
else
	show_error_screen_replacing_ui("Your browser doesn't support MIDI access.")

notes = []
current_notes = new Map
export_midi_file_button.disabled = true

current_pitch_bend_value = 0
global_pitch_bends = []

demo = ->
	iid = setInterval ->
		velocity = 127 # ??? range TBD - my MIDI keyboard isn't working right now haha, I'll have to restart my computer

		start_time = performance.now()

		# keys_to_be_held = [
		# 	Math.round(((+Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) * 128)
		# 	Math.round(((-Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) * 128)
		# ]
		# keys_to_be_held =
			# n for n in [0...128] when (start_time / 500 % n) < 4
			# n for n in [0...128] when ((start_time / 100) % (n * Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) < 4
			# n for n in [0...128] when ((start_time / 100) % (n * Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) < 4 and (Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) > 0)
			# n for n in [0...128] when ((start_time / 100) % (n * Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) < 4 and (Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) > ((n / 128) - 0.5))
			# n for n in [0...128] when ((start_time / 100) % (((n / 128) - 0.5) * Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) < 0.1
			# n for n in [0...128] when ((start_time / 1000) % (((n / 128) - 0.5) * Math.sin(start_time / 64000 + Math.sin(start_time / 23450)) + 1) / 2) < 0.1
			# n for n in [0...128] when (
			# 	((start_time / 100) % (((n / 128) - 0.5) * Math.sin(start_time / 6400 + Math.sin(start_time / 2345)) + 1) / 2) < 0.1 and
			# 	Math.abs(Math.sin(start_time / 640 + Math.sin(start_time / 250)) - ((n / 128) - 0.5)) < 0.5
			# )
		# t = start_time / 1000
		# keys_to_be_held =
			# n for n in [0...128] when (
			# 	((t / 1) % (((n / 128) - 0.5) * Math.sin(t / 64 + Math.sin(t / 23)) + 1) / 2) < 0.1 and
			# 	Math.abs(Math.sin(t / 6 + Math.sin(t / 2)) - ((n / 128) - 0.5)) < 0.5
			# )
		t = start_time / 1000
		# t = t % 4 if t % 16 < 4
		# root = 60 + Math.floor(t / 4) % 4
		# root = 60 + [0, 5, 3, 6][(Math.floor(t / 4) % 4)]
		root = 60 + [0, 5, 3, 6][(Math.floor(t / 4) % 4)]
		keys_to_be_held =
			# n for n in [0...128] when (
			# 	((t / 1) % (((n / 128) - 0.5) * Math.sin(t / 64 + Math.sin(t / 24)) + 1) / 2) < 0.1 and
			# 	Math.abs(Math.sin(t / 8 + Math.sin(t / 2)) - ((n / 128) - 0.5)) < 0.5
			# )
			n for n in [0...128] when (
				# (n - root) %% 12 < 1
				# (n - root) %% 12 < Math.abs(Math.sin(t / 8 + Math.sin(t / 2)) - ((n / 128) - 0.5)) 
				# ((n - root) %% 12) % Math.abs(Math.sin(t / 8 + Math.sin(t / 2)) - ((n / 128) - 0.5)) > 1

				# ((n - root) %% 12) % Math.abs(Math.sin(t / 8 + Math.sin(t / 2)) - ((n / 128) - 0.5)) %% 0.5 < 0.1 and
				# ((n - root)) % Math.abs(Math.sin(t / 8 + Math.sin(t / 2)) - ((n / 128) - 0.5)) %% 0.5 < 0.1

				# ((n - root) %% 12) %% (n - t) %% 0.5 < 0.1
				# ((n - root) %% 12) %% (-n + t) %% 0.5 < 0.1
				((n - root) %% 12) %% (n & (t / 4)) < (t / 16) %% 1 and
				((n - root)) % Math.abs(Math.sin(t / 80 + Math.sin(t / 20)) - ((n / 128) - 0.5)) %% 0.5 < 0.1
			)

		current_notes.forEach (note, note_key)->
			unless note_key in keys_to_be_held
				note.end_time = performance.now()
				note.length = note.end_time - note.start_time
				current_notes.delete(note_key)

		for key in keys_to_be_held
			old_note = current_notes.get(key)
			unless old_note
				note = {key, velocity, start_time, pitch_bends: [{
					time: start_time,
					value: current_pitch_bend_value,
				}]}
				current_notes.set(key, note)
				notes.push(note)


		no_notes_recorded_message_el.hidden = true
		export_midi_file_button.disabled = false

	, 10

# do demo
window.demo = demo

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

	no_notes_recorded_message_el.hidden = true
	export_midi_file_button.disabled = false

	if is_learning_range
		learning_range[0] = Math.min(learning_range[0] ? key, key)
		learning_range[1] = Math.max(learning_range[1] ? key, key)
		[midi_range_left_input.value, midi_range_right_input.value] = learning_range

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
	if is_learning_range
		[min_midi_val, max_midi_val] = view_range_while_learning
	else
		[left_midi_val, right_midi_val] = selected_range
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
	if is_learning_range
		for extremity_midi_val, i in learning_range
			if extremity_midi_val?
				w = canvas.width / (max_midi_val - min_midi_val + 1)
				x = (extremity_midi_val - min_midi_val) * w
				ctx.fillStyle = "red"
				ctx.fillRect(x, 0, w, canvas.height)
	ctx.restore()

export_midi_file_button.onclick = ->
	midi_file = new MIDIFile()

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
	midi_file.setTrackEvents(0, first_track_events)
	midi_file.addTrack(1)
	midi_file.setTrackEvents(1, events)

#	console.log({first_track_events, events})

	output_array_buffer = midi_file.getContent()
	
	blob = new Blob([output_array_buffer], {type: "audio/midi"})
	saveAs(blob, "recording.midi")


fullscreen_button.onclick = ->
	if fullscreen_target_el.requestFullscreen
		fullscreen_target_el.requestFullscreen()
	else if fullscreen_target_el.mozRequestFullScreen
		fullscreen_target_el.mozRequestFullScreen()
	else if fullscreen_target_el.webkitRequestFullScreen
		fullscreen_target_el.webkitRequestFullScreen()

end_learn_range = ->
	is_learning_range = false
	cancel_learn_range_button.hidden = true
	apply_text_el.hidden = true
	learn_range_text_el.hidden = false
	learning_range = [null, null]
	midi_range_left_input.disabled = false
	midi_range_right_input.disabled = false
	[midi_range_left_input.value, midi_range_right_input.value] = selected_range

learn_range_or_apply_button.onclick = ->
	if is_learning_range
		set_selected_range(learning_range)
		save_options()
		end_learn_range()
	else
		is_learning_range = true
		cancel_learn_range_button.hidden = false
		apply_text_el.hidden = false
		learn_range_text_el.hidden = true
		learning_range = [null, null]
		midi_range_left_input.disabled = true
		midi_range_right_input.disabled = true
		[midi_range_left_input.value, midi_range_right_input.value] = view_range_while_learning

cancel_learn_range_button.onclick = end_learn_range

KEYCODE_ESC = 27

# supposedly keydown doesn't work consistently in all browsers
document.body.addEventListener "keydown", (event)->
	if event.keyCode is KEYCODE_ESC
		end_learn_range()
document.body.addEventListener "keyup", (event)->
	if event.keyCode is KEYCODE_ESC
		end_learn_range()
