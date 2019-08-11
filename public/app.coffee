
for el in document.querySelectorAll("noscript")
	el.remove() # for screenreaders (maybe should be earlier than this asynchronously loaded coffeescript)

el_to_replace_content_of_on_error = document.querySelector(".replace-content-on-error") ? document.body
fullscreen_target_el = document.getElementById("fullscreen-target")
canvas = document.getElementById("midi-viz-canvas")
no_notes_recorded_message_el = document.getElementById("no-notes-recorded-message")
no_midi_devices_message_el = document.getElementById("no-midi-devices-message")
loading_midi_devices_message_el = document.getElementById("loading-midi-devices-message")
export_midi_file_button = document.getElementById("export-midi-file-button")
fullscreen_button = document.getElementById("fullscreen-button")
px_per_second_input = document.getElementById("note-gravity-pixels-per-second")
note_gravity_direction_select = document.getElementById("note-gravity-direction-select")
layout_select = document.getElementById("layout-select")
theme_select = document.getElementById("theme-select")
hue_rotate_degrees_input = document.getElementById("hue-rotate-degrees")
midi_range_left_input = document.getElementById("midi-range-min")
midi_range_right_input = document.getElementById("midi-range-max")
learn_range_or_apply_button = document.getElementById("learn-range-or-apply-button")
learn_range_text_el = document.getElementById("learn-midi-range-button-text")
apply_text_el = document.getElementById("apply-midi-range-button-text")
cancel_learn_range_button = document.getElementById("cancel-learn-midi-range-button")
midi_devices_table = document.getElementById("midi-devices")

# options are initialized from the URL & HTML later
theme = "white-and-accent-color"
hue_rotate_degrees = 0
layout = "equal"
px_per_second = 20
note_gravity_direction = "up"
selected_range = [0, 128]

is_learning_range = false
learning_range = [null, null]
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
		"layout": layout
		"gravity-direction": note_gravity_direction
		"pixels-per-second": px_per_second
		"midi-range": "#{from_midi_val}..#{to_midi_val}"
		"theme": theme
		"hue-rotate": hue_rotate_degrees
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
	# TODO: reset to original defaults when not in URL, in case you hit the back button
	if data["midi-range"]
		set_selected_range(data["midi-range"].split(".."))
	if data["pixels-per-second"]
		px_per_second = parseFloat(data["pixels-per-second"])
		px_per_second_input.value = px_per_second
	if data["gravity-direction"]
		note_gravity_direction = data["gravity-direction"].toLowerCase()
		note_gravity_direction_select.value = note_gravity_direction
	if data["layout"]
		layout = data["layout"].toLowerCase()
		layout_select.value = layout
	if data["theme"]
		theme = data["theme"].toLowerCase()
		theme_select.value = theme
	if data["hue-rotate"]
		hue_rotate_degrees = parseFloat(data["hue-rotate"])
		hue_rotate_degrees_input.value = hue_rotate_degrees

update_options_from_inputs = ->
	set_selected_range([midi_range_left_input.value, midi_range_right_input.value])
	px_per_second = parseFloat(px_per_second_input.value) || 20
	hue_rotate_degrees = parseFloat(hue_rotate_degrees_input.value) || 0
	note_gravity_direction = note_gravity_direction_select.value
	layout = layout_select.value
	theme = theme_select.value
	# TODO: debounce saving
	save_options()

# TODO: use oninput
midi_range_left_input.onchange = update_options_from_inputs
midi_range_right_input.onchange = update_options_from_inputs
px_per_second_input.onchange = update_options_from_inputs
note_gravity_direction_select.onchange = update_options_from_inputs
layout_select.onchange = update_options_from_inputs
theme_select.onchange = update_options_from_inputs
hue_rotate_degrees_input.onchange = update_options_from_inputs

load_options()
update_options_from_inputs()

addEventListener("hashchange", load_options)

midi_device_ids_to_rows = new Map

smi = new SimpleMidiInput()

loading_midi_devices_message_el.hidden = false

on_success = (midi)->
	smi.attach(midi)
#	console.log 'smi: ', smi
#	console.log 'inputs (as a Map): ', new Map(midi.inputs)

	loading_midi_devices_message_el.hidden = true
	no_midi_devices_message_el.hidden = false
	midi.onstatechange = (e)->
		if e.port.type is "input"
			no_midi_devices_message_el.hidden = true

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
current_sustain_active = off
global_sustain_periods = []

set_pitch_bend = (value)->
	current_pitch_bend_value = value
	pitch_bend = {time: performance.now(), value}
	global_pitch_bends.push(pitch_bend)
	current_notes.forEach (note, key)->
		note.pitch_bends.push(pitch_bend)

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

		# if Math.sin(t * 29) < 0
		# 	set_pitch_bend(Math.sin(t * 4))

		no_notes_recorded_message_el.hidden = true
		export_midi_file_button.disabled = false

	, 10

# do demo
window.demo = demo

smi.on 'noteOn', ({event, key, velocity})->
	old_note = current_notes.get(key)
	start_time = performance.now()
	return if old_note
	note = {
		key, velocity, start_time,
		pitch_bends: [{
			time: start_time,
			value: current_pitch_bend_value,
		}],
	}
	current_notes.set(key, note)
	notes.push(note)

	no_notes_recorded_message_el.hidden = true
	export_midi_file_button.disabled = false

	if is_learning_range
		learning_range[0] = Math.min(learning_range[0] ? key, key)
		learning_range[1] = Math.max(learning_range[1] ? key, key)
		[midi_range_left_input.value, midi_range_right_input.value] = learning_range

smi.on 'noteOff', ({event, key})->
	note = current_notes.get(key)
	if note
		note.end_time = performance.now()
		note.length = note.end_time - note.start_time
	current_notes.delete(key)

smi.on 'pitchWheel', ({event, value})->
	set_pitch_bend(value / 0x2000)

smi.on 'global', (data)->
	# if data.event not in ['clock', 'activeSensing']
	# 	console.log(data)
	if data.event is "cc" and data.cc is 64
		active = data.value >= 64 # ≤63 off, ≥64 on https://www.midi.org/specifications-old/item/table-3-control-change-messages-data-bytes-2
		if current_sustain_active and not active
			global_sustain_periods[global_sustain_periods.length - 1]?.end_time = performance.now()
		else if active and not current_sustain_active
			global_sustain_periods.push({
				start_time: performance.now(),
				end_time: undefined,
			})
		current_sustain_active = active

piano_accidental_pattern = [0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0].map((bit_num)-> bit_num > 0)

# accidental refers to the black keys
# natural refers to the white keys
nth_accidentals = []
nth_naturals = []
nth_accidental = 0
nth_natural = 0
for is_accidental, i in piano_accidental_pattern
	if is_accidental
		nth_accidental += 1
	else
		nth_natural += 1
	nth_accidentals.push(nth_accidental)
	nth_naturals.push(nth_natural)

# measurements of a keyboard
# octave_width_inches = 6 + 1/4 + 1/16
# natural_key_width_inches = octave_width_inches / 7
# accidental_key_width_inches = 1/2 + 1/16 # measured by the hole that the keys sticks up out of
# group_of_3_span_inches = 2 + 1/2 + 1/8
# group_of_2_span_inches = 1 + 3/4 - 1/16

# group_of_3_span_size = group_of_3_span_inches / octave_width_inches * 12
# group_of_2_span_size = group_of_2_span_inches / octave_width_inches * 12
# natural_key_size = 12 / 7
# accidental_key_size = natural_key_size * accidental_key_width_inches / natural_key_width_inches

# console.log {group_of_2_span_size, group_of_3_span_size, accidental_key_size}
# console.log group_of_2_span_size/natural_key_size, group_of_3_span_size/natural_key_size, accidental_key_size/natural_key_size
# 1.8712871287128714 2.9108910891089113 0.6237623762376237

natural_key_size = 12 / 7
accidental_key_size = natural_key_size * 0.6
group_of_2_span_size = natural_key_size * 1.87
group_of_3_span_size = natural_key_size * 2.91

piano_layout = for is_accidental, octave_key_index in piano_accidental_pattern
	if is_accidental
		nth_accidental = nth_accidentals[octave_key_index]
		is_group_of_3 = nth_accidental > 2
		accidentals_in_group = if is_group_of_3 then 3 else 2
		gaps_in_group = accidentals_in_group - 1
		nth_accidental_in_group = if is_group_of_3 then nth_accidental - 2 else nth_accidental
		group_center = natural_key_size * (if is_group_of_3 then 5 else 1.5)
		group_span_size = if is_group_of_3 then group_of_3_span_size else group_of_2_span_size
		gap_size = (group_span_size - accidentals_in_group * accidental_key_size) / gaps_in_group
		space_between_key_centers = accidental_key_size + gap_size
		key_center_x =
			group_center +
			(nth_accidental_in_group - (accidentals_in_group + 1) / 2) * space_between_key_centers
		x1 = key_center_x - accidental_key_size / 2
		x2 = key_center_x + accidental_key_size / 2
	else
		nth_natural = nth_naturals[octave_key_index]
		x1 = (nth_natural - 1) * natural_key_size
		x2 = (nth_natural + 0) * natural_key_size
	{x1, x2}

ctx = canvas.getContext "2d"

do animate = ->
	filter = "hue-rotate(#{hue_rotate_degrees}deg)"
	if canvas.style.filter isnt filter
		canvas.style.filter = filter

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

	if note_gravity_direction in ["down", "right"]
		# "that's downright backwards!" haha
		ctx.translate(0, canvas.height)
		ctx.scale(1, -1)
	
	if note_gravity_direction in ["left", "right"]
		ctx.translate(canvas.width/2, canvas.height/2)
		ctx.rotate(Math.PI / 2 * if note_gravity_direction is "left" then -1 else +1)
		ctx.translate(-canvas.height/2, -canvas.width/2)

	pitch_axis_canvas_length = if note_gravity_direction in ["left", "right"] then canvas.height else canvas.width
	time_axis_canvas_length = if note_gravity_direction in ["left", "right"] then canvas.width else canvas.height

	if left_midi_val > right_midi_val
		ctx.translate(pitch_axis_canvas_length, 0)
		ctx.scale(-1, 1)

	ctx.translate(0, time_axis_canvas_length*4/5)
	if theme in ["classic", "gaudy"]
		ctx.fillStyle = "red"
		ctx.fillRect(0, 1, pitch_axis_canvas_length, 1)
	# ctx.globalAlpha = 0.2
	
	get_note_location_midi_space = (note_midi_val)->
		octave_key_index = note_midi_val %% piano_accidental_pattern.length
		is_accidental = piano_accidental_pattern[octave_key_index]
		if layout is "piano"
			octave_start_midi_val = Math.floor(note_midi_val / 12) * 12
			{x1, x2} = piano_layout[octave_key_index]
			x1 += octave_start_midi_val
			x2 += octave_start_midi_val
		else
			x1 = note_midi_val
			x2 = note_midi_val + 1
		{x1, x2, is_accidental}
	
	if layout is "piano"
		midi_x1 = get_note_location_midi_space(min_midi_val).x1
		midi_x2 = get_note_location_midi_space(max_midi_val).x2
	else
		midi_x1 = min_midi_val
		midi_x2 = max_midi_val + 1

	midi_to_canvas_scalar = pitch_axis_canvas_length / (midi_x2 - midi_x1)
	get_note_location_canvas_space = (note_midi_val)->
		{x1, x2, is_accidental} = get_note_location_midi_space(note_midi_val)
		x1 = (x1 - midi_x1) * midi_to_canvas_scalar
		x2 = (x2 - midi_x1) * midi_to_canvas_scalar
		{x: x1, w: x2 - x1, is_accidental}

	for sustain_period, i in global_sustain_periods
		start_y = (sustain_period.start_time - now) / 1000 * px_per_second
		end_y = ((sustain_period.end_time ? now) - now) / 1000 * px_per_second
		ctx.fillStyle = "rgba(128, 128, 128, 0.3)"
		ctx.fillRect(0, start_y, pitch_axis_canvas_length, end_y - start_y)

	for note in notes
		{x, w, is_accidental} = get_note_location_canvas_space(note.key, pitch_axis_canvas_length)
		unless note.length?
			# for ongoing (held) notes, display a bar at the bottom like a key
			# TODO: maybe bend this?
			ctx.fillStyle =
			switch theme
				when "classic", "classic-gaudy"
					"#a00"
				when "white"
					"rgba(255, 255, 255, 0.2)"
				when "white-and-accent-color"
					if is_accidental
						"rgba(255, 0, 0, 0.5)"
					else
						"rgba(255, 255, 255, 0.2)"
			ctx.fillRect(x, 2, w, 50000)
		ctx.fillStyle =
			switch theme
				when "classic"
					if note.length then "yellow" else "lime"
				when "classic-gaudy"
					if is_accidental
						if note.length then "#f79" else "aqua"
					else
						if note.length then "yellow" else "lime"
				when "white"
					"white"
				when "white-and-accent-color"
					if is_accidental
						"rgb(255, 0, 0)"
					else
						"white"
		# ctx.strokeStyle = if note.length then "yellow" else "lime"
		smooth = no
		if smooth
			ctx.beginPath()
			points_to_get_back_around_to = []
			for pitch_bend, i in note.pitch_bends
				next_pitch_bend = note.pitch_bends[i + 1]
				segment_end_time = next_pitch_bend?.time ? note.end_time ? now
				y1 = (pitch_bend.time - now) / 1000 * px_per_second
				y2 = (segment_end_time - now) / 1000 * px_per_second
				h = y2 - y1 + 0.5
				bent_x = x + pitch_bend.value * 2 * midi_to_canvas_scalar
				segment_end_bent_x = x + (next_pitch_bend ? pitch_bend).value * 2 * midi_to_canvas_scalar
				ctx.lineTo(bent_x, y1)
				points_to_get_back_around_to.push({x: bent_x + w,y: y1})
				# if y2 - y1 > 5 # and Math.abs(pitch_bend.value - next_pitch_bend?.value) < 0.1
				# 	ctx.lineTo(bent_x, y2 - 4)
					# points_to_get_back_around_to.push({x: bent_x + w, y: y2 - 4})
				if y2 - y1 > 5
					ctx.lineTo((bent_x + segment_end_bent_x) / 2, y2 - 5)
					points_to_get_back_around_to.push({x: bent_x + w, y: y2 - 5})
				if y2 - y1 > 10
					ctx.lineTo((bent_x * 2 + segment_end_bent_x) / 3, y2 - 10)
					points_to_get_back_around_to.push({x: bent_x + w, y: y2 - 10})
				if y2 - y1 > 20
					ctx.lineTo(bent_x, y2 - 20)
					points_to_get_back_around_to.push({x: bent_x + w, y: y2 - 20})
			ctx.lineTo(bent_x, y2)
			ctx.lineTo(bent_x + w, y2)

			# for pitch_bend, i in note.pitch_bends by -1
			# 	next_pitch_bend = note.pitch_bends[i - 1]
			# 	segment_end_time = next_pitch_bend?.time ? note.start_time
			# 	y1 = (pitch_bend.time - now) / 1000 * px_per_second
			# 	y2 = (segment_end_time - now) / 1000 * px_per_second
			# 	bent_x = x + pitch_bend.value * 2 * midi_to_canvas_scalar
			# 	if y2 - y1 < -5
			# 		ctx.lineTo(bent_x + w, y1 - 4)
			# 	ctx.lineTo(bent_x + w, y1)

			for point in points_to_get_back_around_to by -1
				ctx.lineTo(point.x, point.y)

			ctx.fill()
		else
			for pitch_bend, i in note.pitch_bends
				next_pitch_bend = note.pitch_bends[i + 1]
				segment_end_time = next_pitch_bend?.time ? note.end_time ? now
				y1 = (pitch_bend.time - now) / 1000 * px_per_second
				y2 = (segment_end_time - now) / 1000 * px_per_second
				h = y2 - y1 + 0.5
				bent_x = x + pitch_bend.value * 2 * midi_to_canvas_scalar
				ctx.fillRect(bent_x, y1, w, h)
	if is_learning_range
		for extremity_midi_val, i in learning_range
			if extremity_midi_val?
				{x, w} = get_note_location_canvas_space(extremity_midi_val, pitch_axis_canvas_length)
				ctx.fillStyle = "red"
				ctx.fillRect(x, 0, w, time_axis_canvas_length)
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
			param1: 0
			param2: (pitch_bend.value + 1) * 64
#			param2: ((pitch_bend.value + 1) * 0x2000) / 128
#			param2: pitch_bend.value * 0x2000 / 128 + 64
#			param2: pitch_bend.value * 0x1000 / 64 + 64
		})

	for sustain_period in global_sustain_periods
		events.push({
			# delta: <computed later>
			_time: sustain_period.start_time
			type: MIDIEvents.EVENT_MIDI
			subtype: MIDIEvents.EVENT_MIDI_CONTROLLER
			channel: 0
			param1: 64
			param2: 127
		})
		events.push({
			# delta: <computed later>
			_time: sustain_period.end_time ? performance.now()
			type: MIDIEvents.EVENT_MIDI
			subtype: MIDIEvents.EVENT_MIDI_CONTROLLER
			channel: 0
			param1: 64
			param2: 0
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
