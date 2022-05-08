
for el in document.querySelectorAll("noscript")
	el.remove() # for screenreaders

midi_not_supported = document.getElementById("midi-not-supported")
midi_access_failed = document.getElementById("midi-access-failed")
midi_access_failed_pre = document.getElementById("midi-access-failed-pre")
fullscreen_target_el = document.getElementById("fullscreen-target")
canvas = document.getElementById("midi-viz-canvas")
no_notes_recorded_message_el = document.getElementById("no-notes-recorded-message")
no_midi_devices_message_el = document.getElementById("no-midi-devices-message")
loading_midi_devices_message_el = document.getElementById("loading-midi-devices-message")
export_midi_file_button = document.getElementById("export-midi-file-button")
recording_name_input = document.getElementById("recording-name-input")
clear_button = document.getElementById("clear-button")
undo_clear_button = document.getElementById("undo-clear-button")
show_recovery_button = document.querySelector(".show-recovery-button")
show_recovery_button_loading_indicator = document.querySelector(".show-recovery-button .loading-indicator")
recoverables_list = document.getElementById("recoverables")
recovery_empty_message_el = document.getElementById("recovery-empty-message")
recovery_error_message_el = document.getElementById("recovery-error-message")
fullscreen_button = document.getElementById("fullscreen-button")
visualization_enabled_checkbox = document.getElementById("visualization-enabled")
px_per_second_input = document.getElementById("note-gravity-pixels-per-second-input")
note_gravity_direction_select = document.getElementById("note-gravity-direction-select")
layout_radio_buttons = Array.from(document.getElementsByName("key-layout"))
theme_select = document.getElementById("theme-select")
perspective_rotate_vertically_input = document.getElementById("perspective-rotate-vertically-input")
perspective_distance_input = document.getElementById("perspective-distance-input")
scale_x_input = document.getElementById("scale-x-input")
hue_rotate_degrees_input = document.getElementById("hue-rotate-degrees-input")
midi_range_left_input = document.getElementById("midi-range-min-input")
midi_range_right_input = document.getElementById("midi-range-max-input")
learn_range_or_apply_button = document.getElementById("learn-range-or-apply-button")
learn_range_text_el = document.getElementById("learn-midi-range-button-text")
apply_text_el = document.getElementById("apply-midi-range-button-text")
cancel_learn_range_button = document.getElementById("cancel-learn-midi-range-button")
midi_devices_table = document.getElementById("midi-devices")
troubleshoot_midi_input_button = document.getElementById("troubleshoot-midi-input-button")
troubleshoot_midi_input_popover = document.getElementById("troubleshoot-midi-input-popover")
demo_button = document.getElementById("demo-button")
demo_button_stop_span = document.getElementById("demo-button-stop-text")
demo_button_start_span = document.getElementById("demo-button-start-text")

debounce = (func, timeout = 300)->
	tid = null
	return (...args)->
		clearTimeout(tid)
		tid = setTimeout((-> func(...args)), timeout)

nanoid = (length = 21) ->
	id = ''
	for n in crypto.getRandomValues(new Uint8Array(length))
		n = 63 & n
		id += if n < 36 then n.toString(36) else if n < 62 then (n - 26).toString(36).toUpperCase() else if n < 63 then '_' else '-'
	id

localforage.config({
	name: "MIDI Recorder"
})

# for filename
# - first note would be easier to keep track of but if you record more without clearing, it should be a new filename
# - time-of-save would be easiest, but then it's harder to know if you've already saved something
# - END of last note would cause problems if you hit save before releasing a note, or if a note gets stuck
# - so use START of last note
# - Date.now() is more performant than new Date()
last_note_datetime = Date.now()

# options are initialized from the URL & HTML later
visualization_enabled = true
theme = "white-and-accent-color"
hue_rotate_degrees = 0
layout = "equal"
px_per_second = 20
note_gravity_direction = "up"
perspective_rotate_vertically = 0
perspective_distance = 0
scale_x = 1
selected_range = [0, 128]

is_learning_range = false
learning_range = [null, null]
view_range_while_learning = [0, 128]

normalize_range = (range)->
	valid_int_0_to_128 = (value)->
		int = parseInt(value)
		return null if isNaN(int) or int < 0 or int > 128
		return int
	return [
		valid_int_0_to_128(range[0]) ? 0
		valid_int_0_to_128(range[1]) ? 128
	]

set_selected_range = (range, do_not_update_inputs)->
	selected_range = normalize_range(range)
	unless is_learning_range or do_not_update_inputs
		[midi_range_left_input.value, midi_range_right_input.value] = selected_range

first_save_to_url = true
hashchange_is_new_history_entry = false
save_options_immediately = ({update_even_focused_inputs}={})->
	[from_midi_val, to_midi_val] = selected_range
	data =
		"viz": if visualization_enabled then "on" else "off"
		"layout": layout
		"gravity-direction": note_gravity_direction
		"pixels-per-second": px_per_second
		"3d-vertical": perspective_rotate_vertically
		"3d-distance": perspective_distance
		"scale-x": scale_x
		"midi-range": "#{from_midi_val}..#{to_midi_val}"
		"theme": theme
		"hue-rotate": hue_rotate_degrees
	option_strings =
		for key, val of data
			"#{key}=#{val}"
	old_hash = location.hash
	hashchange_is_new_history_entry = true
	if first_save_to_url
		first_save_to_url = false
		# Note: for first URL update we don't need to load_options()
		# since it's loading defaults from elements on the page
		try
			# avoid hijacking the browser back button / creating an extra step to go back thru
			# when navigating to the app from another site
			history.replaceState(null, null, "##{option_strings.join("&")}")
		catch
			location.hash = option_strings.join("&")
	else
		location.hash = option_strings.join("&")
		if old_hash is location.hash
			# in this case, a hashchange won't occur
			# but we still want to normalize options, at least to be consistent (I'm not sure this is the best behavior, to apply normalization to invalid user inputs)
			# e.g. for MIDI range: 1.0 -> 1, 1.5 -> 1, 1000 -> 128
			load_options({update_even_focused_inputs})

save_options_soon = debounce save_options_immediately

load_options = ({update_even_focused_inputs}={})->
	data = {}
	for keyval in location.hash.replace(/^#/, "").split("&") when keyval.match(/=/)
		[key, val] = keyval.split("=")
		key = key.trim()
		val = val.trim()
		data[key] = val
	
	# For text based inputs, including number inputs,
	# in order to let you backspace and type a new value,
	# don't change the value while focused, only on blur.
	# Except, if you change the option OTHER than via the input,
	# such as if you go back/forward in history,
	# it should update the value of an input even if it's focused.

	# TODO: reset to original defaults when not in URL, in case you hit the back button
	# (maybe merge load_options and update_options_from_inputs in some way?)

	if data["viz"]
		visualization_enabled = data["viz"].toLowerCase() in ["on", "true", "1"]
		visualization_enabled_checkbox.checked = visualization_enabled
	if data["midi-range"]
		set_selected_range(data["midi-range"].split(".."), not update_even_focused_inputs)
	if data["pixels-per-second"]
		px_per_second = parseFloat(data["pixels-per-second"])
		if update_even_focused_inputs or document.activeElement isnt px_per_second_input
			px_per_second_input.value = px_per_second
	if data["3d-vertical"]
		perspective_rotate_vertically = parseFloat(data["3d-vertical"])
		if update_even_focused_inputs or document.activeElement isnt perspective_rotate_vertically_input
			perspective_rotate_vertically_input.value = perspective_rotate_vertically
	if data["3d-distance"]
		perspective_distance = parseFloat(data["3d-distance"])
		if update_even_focused_inputs or document.activeElement isnt perspective_distance_input
			perspective_distance_input.value = perspective_distance
	if data["scale-x"]
		scale_x = parseFloat(data["scale-x"])
		if update_even_focused_inputs or document.activeElement isnt scale_x_input
			scale_x_input.value = scale_x
	if data["gravity-direction"]
		note_gravity_direction = data["gravity-direction"].toLowerCase()
		note_gravity_direction_select.value = note_gravity_direction
	if data["layout"]
		layout = data["layout"].toLowerCase()
		layout_radio_buttons.find((radio)=> radio.value is layout)?.checked = true
	if data["theme"]
		theme = data["theme"].toLowerCase()
		theme_select.value = theme
	if data["hue-rotate"]
		hue_rotate_degrees = parseFloat(data["hue-rotate"])
		if update_even_focused_inputs or document.activeElement isnt hue_rotate_degrees_input
			hue_rotate_degrees_input.value = hue_rotate_degrees

update_options_from_inputs = ->
	visualization_enabled = visualization_enabled_checkbox.checked
	set_selected_range([midi_range_left_input.value, midi_range_right_input.value], true)
	px_per_second = parseFloat(px_per_second_input.value) || 20
	hue_rotate_degrees = parseFloat(hue_rotate_degrees_input.value) || 0
	note_gravity_direction = note_gravity_direction_select.value
	layout = layout_radio_buttons.find((radio)=> radio.checked)?.value ? "equal"
	theme = theme_select.value
	
	perspective_rotate_vertically = perspective_rotate_vertically_input.value || 0
	perspective_distance = perspective_distance_input.value || 100
	# canvas.style.transform = "translate(0, -20px) perspective(50vw) rotateX(-10deg) scale(0.9, 1)"
	# canvas.style.transformOrigin = "50% 0%"
	scale_x = scale_x_input.value || 1
	canvas.style.transform = "perspective(#{perspective_distance}vw) rotateX(-#{perspective_rotate_vertically}deg) scaleX(#{scale_x})"
	canvas.style.transformOrigin = "50% 0%"

	save_options_soon()

for control_element in [
	visualization_enabled_checkbox
	note_gravity_direction_select
	theme_select
	layout_radio_buttons...
]
	control_element.onchange = update_options_from_inputs
for input_element in [
	midi_range_left_input
	midi_range_right_input
	px_per_second_input
	perspective_rotate_vertically_input
	perspective_distance_input
	scale_x_input
	hue_rotate_degrees_input
]
	input_element.oninput = update_options_from_inputs
	# in case you backspaced an input, it shouldn't change the field while focused, but should when unfocused if still empty
	input_element.onblur = ->
		# since we're going to load options from the URL, we need to update the URL immediately
		# otherwise you'd need to wait for the debounce timer before unfocusing the input for the change to take
		save_options_immediately()
		load_options({update_even_focused_inputs: true}) # update_even_focused_inputs is probably not needed here

load_options({update_even_focused_inputs: true})
update_options_from_inputs()

addEventListener "hashchange", ->
	load_options({update_even_focused_inputs: not hashchange_is_new_history_entry})
	hashchange_is_new_history_entry = false

##############################
# Connecting to Devices
##############################

midi_device_ids_to_rows = new Map

smi = new SimpleMidiInput()

loading_midi_devices_message_el.hidden = false

connected_port_ids = new Set

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
			if connected then connected_port_ids.add(e.port.id) else connected_port_ids.delete(e.port.id)

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
	loading_midi_devices_message_el.hidden = true
	midi_access_failed_pre.textContent = error
	midi_access_failed.hidden = false
	console.log "requestMIDIAccess failed:", error

if navigator.requestMIDIAccess
	navigator.requestMIDIAccess().then on_success, on_error
else
	loading_midi_devices_message_el.hidden = true
	midi_not_supported.hidden = false

##############################
# State Handling
##############################

notes = []
current_notes = new Map
current_pitch_bend_value = 0
global_pitch_bends = []
current_sustain_active = off
global_sustain_periods = []
current_instrument = undefined
current_bank_msb = undefined
current_bank_lsb = undefined
global_instrument_selects = []
global_bank_msb_selects = []
global_bank_lsb_selects = []
active_recording_session_id = "recording_#{nanoid()}"
active_chunk_n = 1
active_chunk_events = []

export_midi_file_button.disabled = true
clear_button.disabled = true

save_state = ->
	# use JSON to (inefficiently) copy state so that it's not just saving references to mutable data structures
	# Map can't be JSON-stringified
	state = JSON.parse(JSON.stringify({
		notes
		current_notes: "placeholder for non-serializable Map object"
		current_pitch_bend_value
		global_pitch_bends
		current_sustain_active
		global_sustain_periods
		current_instrument
		global_instrument_selects
		global_bank_msb_selects
		global_bank_lsb_selects
		recording_name: recording_name_input.value
		last_note_datetime
		active_recording_session_id
		active_chunk_n
		active_chunk_events
	}))
	state.current_notes = new Map(current_notes)
	state

restore_state = (state)->
	# need to make data copy when restoring as well,
	# so that if you restore initial_state it's not going to then mutate that state
	# so that if you clear a second recording it'll work (play notes, clear, play notes, clear)

	# NOTE: these variables must all be declared ABOVE! else they will be local here
	{
		notes
		current_pitch_bend_value
		global_pitch_bends
		current_sustain_active
		global_sustain_periods
		current_instrument
		global_instrument_selects
		global_bank_msb_selects
		global_bank_lsb_selects
		last_note_datetime
		active_recording_session_id
		active_chunk_n
		active_chunk_events
	} = JSON.parse(JSON.stringify(state))
	current_notes = new Map(state.current_notes)
	recording_name_input.value = state.recording_name

initial_state = save_state()
undo_state = save_state()

clear_notes = ->
	try localStorage["to_delete:#{active_recording_session_id}"] = "cleared #{new Date().toISOString()}"

	undo_state = save_state()
	# TODO: keep current instrument and include instrument select at start of next recording
	# (and update caveat in caveats list)
	restore_state(initial_state)

	export_midi_file_button.disabled = true
	clear_button.hidden = true
	undo_clear_button.hidden = false
	undo_clear_button.focus()

	active_recording_session_id = "recording_#{nanoid()}"
	active_chunk_n = 1

undo_clear_notes = ->
	restore_state(undo_state)
	export_midi_file_button.disabled = notes.length is 0
	clear_button.disabled = false
	clear_button.hidden = false
	undo_clear_button.hidden = true
	clear_button.focus()

	# delete deletion flag to cancel deletion
	# TODO: what about if you already saved it? maybe I should get rid of the separate saving vs clearing?
	try delete localStorage["to_delete:#{active_recording_session_id}"]

enable_clearing = ->
	clear_button.disabled = false
	clear_button.hidden = false
	if undo_clear_button is document.activeElement
		export_midi_file_button.focus()
	undo_clear_button.hidden = true

clear_button.onclick = clear_notes
undo_clear_button.onclick = undo_clear_notes

set_pitch_bend = (value, time=performance.now())->
	current_pitch_bend_value = value
	pitch_bend = {time, value}
	global_pitch_bends.push(pitch_bend)
	current_notes.forEach (note, key)->
		note.pitch_bends.push(pitch_bend)
	enable_clearing()

##############################
# Demonstration Mode
##############################

demo_iid = null
stop_demo = ->
	clearInterval demo_iid
	demo_iid = null
	current_notes.forEach (note, note_key)->
		note.end_time = performance.now()
		note.length = note.end_time - note.start_time
		current_notes.delete(note_key)
	demo_button_stop_span.hidden = true
	demo_button_start_span.hidden = false
demo = ->
	if demo_iid
		stop_demo()
		return
	demo_button_stop_span.hidden = false
	demo_button_start_span.hidden = true
	demo_iid = setInterval ->
		velocity = 127 # range is 0-127, with 0 being equivalent to noteOff

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
		recording_name_input.hidden = false
		export_midi_file_button.disabled = false
		enable_clearing()

	, 10

window.demo = demo
window.stop_demo = stop_demo
demo_button.onclick = demo

##############################
# Recording
##############################

cancel_deletion_soon = debounce ->
	try delete localStorage["to_delete:#{active_recording_session_id}"]

smi.on 'noteOn', ({event, key, velocity, time})->
	# Note: noteOn with velocity of 0 is supposed to be equivalent to noteOff in MIDI,
	# but SimpleMidiInput abstracts that away for us, sending a noteOff instead,
	# so we don't need to handle noteOn of 0.
	old_note = current_notes.get(key)
	start_time = time
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
	recording_name_input.hidden = false
	export_midi_file_button.disabled = false
	enable_clearing()

	if is_learning_range
		learning_range[0] = Math.min(learning_range[0] ? key, key)
		learning_range[1] = Math.max(learning_range[1] ? key, key)
		[midi_range_left_input.value, midi_range_right_input.value] = learning_range
	
	last_note_datetime = Date.now()

	# clear delete flag in case you already exported and are playing more
	cancel_deletion_soon()

smi.on 'noteOff', ({event, key, time})->
	note = current_notes.get(key)
	if note
		note.end_time = time
		note.length = note.end_time - note.start_time
	current_notes.delete(key)

smi.on 'pitchWheel', ({event, value, time})->
	set_pitch_bend(value / 0x2000, time)

smi.on 'programChange', ({program, time})->
	current_instrument = program
	global_instrument_selects.push({time, value: program, bank_msb: current_bank_msb, bank_lsb: current_bank_lsb})
	enable_clearing()

smi.on 'global', ({event, cc, value, time, data})->
	if event not in ['clock', 'activeSensing']
		# console.log({event, cc, value, time, data})

		active_chunk_events.push {data, time}

	if event is "cc" and cc is 0
		current_bank_msb = value
		global_bank_msb_selects.push({time, value: value})
		enable_clearing()
	
	if event is "cc" and cc is 32
		current_bank_lsb = value
		global_bank_lsb_selects.push({time, value: value})
		enable_clearing()

	if event is "cc" and cc is 64
		active = value >= 64 # ≤63 off, ≥64 on https://www.midi.org/specifications-old/item/table-3-control-change-messages-data-bytes-2
		if current_sustain_active and not active
			global_sustain_periods[global_sustain_periods.length - 1]?.end_time = time
		else if active and not current_sustain_active
			global_sustain_periods.push({
				start_time: time
				end_time: undefined
			})
			enable_clearing()
		current_sustain_active = active

##############################
# Recording Recovery
##############################

save_chunk = ->
	# console.log "saving chunk", active_chunk_events
	if active_chunk_events.length is 0
		return
	saving_chunk_n = active_chunk_n
	saving_chunk_id = "chunk_#{saving_chunk_n.toString().padStart(5, "0")}"
	localforage.setItem("#{active_recording_session_id}:#{saving_chunk_id}", active_chunk_events)
	.catch (error)->
		# TODO: maybe restore active_chunk_events/active_chunk_n in case the error was a fluke (disk busy etc.)?
		# but what if some specific event caused it to fail? in that case it would be better if it could still save further chunks,
		# even if it has to drop some chunks; maybe try again once or twice and then give up on the chunk(s)?
		# That's probably too complicated to handle, creating more bugs than it solves.
		recovery_error_message_el.hidden = false
		recovery_error_message_el.textContent = "Failed to save recording chunk #{saving_chunk_n} (for recovery)"
		console.log "Failed to save recording chunk #{saving_chunk_n}"
	# Note: CANNOT do active_chunk_events.length = 0,
	# because localforage.setItem uses the object asynchronously
	# and would save chunks with no notes/events in them!
	active_chunk_events = []
	active_chunk_n += 1
	# DON'T CHANGE THIS without also changing code that assumes "name" is an iso datetime string
	try localStorage["name:#{active_recording_session_id}"] = new Date(last_note_datetime).toISOString()#.replace(/:/g, "").replace(/\..*Z/, "Z")

setInterval save_chunk, 1000

recover = (recoverable)->
	# TODO: separate concerns, avoid affecting app state
	# maybe ditch SimpleMidiInput.js
	original_state = save_state()
	original_focus = document.activeElement
	original_clear_button_hidden                 = clear_button.hidden
	original_clear_button_disabled               = clear_button.disabled
	original_undo_clear_button_hidden            = undo_clear_button.hidden
	original_no_notes_recorded_message_el_hidden = no_notes_recorded_message_el.hidden
	original_recording_name_input_hidden         = recording_name_input.hidden
	original_export_midi_file_button_disabled    = export_midi_file_button.disabled
	restore_state(initial_state)

	try
		# console.log "saved state; starting recover"
		active_recording_session_id = recoverable.recoverable_id

		recoverable.chunks.sort((a, b)-> a.n - b.n)

		# TODO: optimize with https://github.com/localForage/localForage-getItems
		# but make sure to keep order of chunks
		recovered_events = []
		for chunk in recoverable.chunks
			recovered_chunk_events = await localforage.getItem(chunk.key)
			recovered_events = recovered_events.concat(recovered_chunk_events)
			chunk.events = recovered_chunk_events
			for event in recovered_chunk_events
				event.timeStamp ?= event.time
		
		for event in recovered_events
			smi.processMidiMessage(event)

		# recording_name_input.value = "recovered"
		export_midi_file("recovered", (recoverable.name or "recording").replace(/:/g, "").replace(/\..*Z/, "Z") + " [recovered].midi")

	finally
		# console.log "restoring state from recover"

		# all of this could be avoided if UI concerns were separated from MIDI input and export
		restore_state(original_state)
		clear_button.hidden                 = original_clear_button_hidden
		clear_button.disabled               = original_clear_button_disabled
		undo_clear_button.hidden            = original_undo_clear_button_hidden
		no_notes_recorded_message_el.hidden = original_no_notes_recorded_message_el_hidden
		recording_name_input.hidden         = original_recording_name_input_hidden
		export_midi_file_button.disabled    = original_export_midi_file_button_disabled
		original_focus?.focus()
		# console.log "restored state from recover"

list_recoverable_recording = (recoverable)->
	li = document.createElement("li")
	li.classList.add("recoverable-recording")
	span = document.createElement("span")
	span.classList.add("recoverable-recording-name")
	span.textContent = recoverable.name ? recoverable.recoverable_id
	recoverables_list.appendChild(li)
	recover_button = document.createElement("button")
	recover_button.classList.add("button-functional")
	recover_button.innerHTML = """
		<span class="button-visual">
			<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
				<g stroke-width="48.857" transform="translate(-3.631 -5.26) scale(.02225)">
					<path class="fill-cc" d="M301.429 312.422l372.684-76v103.929l-372.684 76z"/>
					<path class="fill-cc" d="M301.429 312.342h60v388.5h-60z"/>
					<ellipse class="fill-cc" cx="-165" cy="470.362" rx="125" ry="78" transform="matrix(.77274 -.20706 .24886 .92877 273.331 240.338)"/>
					<path class="fill-cc" d="M614.113 248.877h60v388.5h-60z"/>
					<ellipse class="fill-cc" cx="-165" cy="470.362" rx="125" ry="78" transform="matrix(.77274 -.20706 .24886 .92877 586.016 176.873)"/>
				</g>
				<path class="fill-cc" fill-rule="evenodd" d="M12.613 9.426c-.125.561-.347 1.012-1.258 1.585v1.165H9.033l3.485 3.838L16 12.176h-2.322v-2.75z"/>
			</svg>
			Save MIDI File
		</span>
	"""
	dismiss_button = document.createElement("button")
	dismiss_button.classList.add("button-functional")
	dismiss_button.innerHTML = """
		<span class="button-visual">
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
				<path class="fill-cc" d="M39.294 63.922c-5.91-.629-11.383-2.047-16.826-4.362-1.553-.66-4.626-2.198-5.977-2.99-4.008-2.35-7.353-4.936-10.39-8.035-1.735-1.77-3.048-3.3-3.357-3.91-.179-.353-.194-.438-.194-1.068 0-.613.018-.722.177-1.046.253-.513.57-.856 1.008-1.09.475-.252.926-.324 2.336-.373 3.303-.113 6.816-.77 10.27-1.922 4.89-1.63 8.196-3.606 10.903-6.513.618-.663 1.02-1.184 1.91-2.475.359-.52.69-.953.69-.953l4.228 2.034s-1.344 2.408-2.02 3.307c-4.042 5.372-11.416 9.262-20.634 10.885-.538.095-1.033.195-1.101.222-.104.042-.01.155.62.743 1.15 1.075 4.54 3.748 4.994 3.94.338.141.788.103 1.687-.143 1.986-.544 3.686-1.4 5.189-2.614.564-.455.587-.438.266.204-.452.905-1.627 2.507-2.997 4.088-.333.384-.605.716-.605.738 0 .023.609.336 1.353.696.744.36 1.808.9 2.364 1.2 1.165.63 1.74.81 2.58.81 1.035 0 2.04-.292 3.53-1.023 2.286-1.122 4.338-2.58 7.467-5.306l.309-.268-.127.368c-.446 1.296-1.746 3.565-3.897 6.802-.626.944-1.129 1.726-1.116 1.738.14.134 6.29 1.275 6.87 1.275.363 0 .552-.184 1.181-1.147 2.265-3.465 4.403-7.518 6.223-11.797.612-1.438.874-2.117 1.927-4.981.48-1.306.9-2.712.921-2.733.021-.022 4.55 1.83 4.58 1.856.067.058-1.255 3.727-2.134 5.923-2.08 5.193-4.356 9.659-7.103 13.94-.827 1.289-1.915 2.807-2.283 3.187-.646.667-1.569.926-2.822.793z"/>
				<path class="fill-cc-if-disabled" fill="red" d="M43.467 30.744c-6.402-2.85-11.665-5.19-11.696-5.202-.08-.028.23-.628.663-1.282 1.021-1.545 2.807-2.714 4.856-3.178.674-.153 2.13-.153 2.852 0 .852.181 1.344.37 3.945 1.513 4.675 2.054 7.29 3.248 7.909 3.61a7.62 7.62 0 013.693 5.22c.13.69.132 1.969.002 2.715-.099.563-.474 1.789-.548 1.787-.02-.001-5.274-2.333-11.676-5.183z"/>
				<path class="fill-cc" d="M47.999 20.662c-2.008-.897-3.687-1.666-3.731-1.709-.063-.06.954-2.015 4.703-9.043C51.8 4.608 53.853.83 53.996.665c.382-.44.681-.565 1.339-.56a4 4 0 012.68 1.052c.494.457.71.89.71 1.421 0 .367-.296 1.221-3.45 9.925-3.1 8.556-3.56 9.805-3.61 9.793-.008-.002-1.658-.737-3.666-1.634z"/>
			</svg>
			Clear
		</span>
	"""
	li.appendChild(recover_button)
	li.appendChild(span)
	li.appendChild(dismiss_button)
	recover_button.onclick = ->
		try
			recover(recoverable)
			# don't remove if error occurred,
			# to let you retry and (probably) see there error message again,
			# and because it'd just be confusing for it to show up later
			li.remove()
			if recoverables_list.children.length is 0
				show_recovery_button.disabled = true
				recovery_empty_message_el.hidden = false
		catch error
			alert "An error occured.\n\n#{error}"
			console.log "Error during recovery:", error
	dismiss_button.onclick = ->
		try
			localStorage["to_delete:#{recoverable.recoverable_id}"] = "cleared_from_recovery #{new Date().toISOString()}"
			# don't remove if error occurred,
			# to let you retry and (probably) see there error message again,
			# and because it'd just be confusing for it to show up later
			li.remove()
			if recoverables_list.children.length is 0
				show_recovery_button.disabled = true
				recovery_empty_message_el.hidden = false
		catch error
			alert "Failed to dismiss recoverable recording.\n\n#{error}"
			console.log "Failed to dismiss recoverable recording:", error

# TODO: setTimeout based error handling; promise can neither resolve nor reject (an issue I experienced on Ubuntu, which resolved once I restarted my computer)
# Update: but it can also take a really long time and succeed :(
localforage.keys().then (keys)->
	recoverables = {}
	for key in keys
		match = key.match(/(recording_[^:]+):chunk_(\d+)/)
		if match
			recoverable_id = match[1]
			recoverable_chunk_n = parseInt(match[2], 10)
			recoverables[recoverable_id] ?= {chunks: [], recoverable_id}
			recoverables[recoverable_id].chunks.push({n: recoverable_chunk_n, key})
		# else
		# 	console.log "Not matching key:", key
	recoverables_to_delete = []
	for recoverable_id, recoverable of recoverables
		should_delete = try localStorage["to_delete:#{recoverable_id}"]
		recoverable.name = try localStorage["name:#{recoverable_id}"]
		if should_delete
			recoverables_to_delete.push(recoverable)
		else
			show_recovery_button.disabled = false
			recovery_empty_message_el.hidden = true
			list_recoverable_recording(recoverable)
	show_recovery_button_loading_indicator.hidden = true
	# after we've updated the screen (theoretically),
	# delete old recordings
	# TODO: don't delete until after some period after it's marked for deletion, like days maybe?
	# (note: make sure to consider delete flag clean up when implementing that)
	for recoverable in recoverables_to_delete
		for chunk in recoverable.chunks
			await localforage.removeItem(chunk.key)
		try delete localStorage["to_delete:#{recoverable_id}"]
		try delete localStorage["name:#{recoverable_id}"]
	
	# In case IndexedDB is cleared but not localStorage, or whatever,
	# clean up delete flags in localStorage.
	for key in Object.keys(localStorage)
		if key.match(/^to_delete:/)
			delete localStorage[key]

	# TODO: allow recovering all recordings at once? but always recover in serial in case of its too much to store all in memory
, (error)->
	show_recovery_button_loading_indicator.hidden = true
	recovery_error_message_el.hidden = false
	# recovery_error_message_el.textContent = "Failed to list recoverable recordings. #{error}"
	recovery_error_message_el.textContent = "Recovery not available. Make sure you have local storage enabled for this site. #{error}"
	# TODO: test what cases this applies to (disabled storage, etc.)
	console.error "Failed to list keys to look for recordings to recover", error


##############################
# Rendering (Visualization)
##############################

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
	requestAnimationFrame animate
	
	if is_learning_range
		[min_midi_val, max_midi_val] = view_range_while_learning
	else
		[left_midi_val, right_midi_val] = selected_range
		min_midi_val = Math.min(left_midi_val, right_midi_val)
		max_midi_val = Math.max(left_midi_val, right_midi_val)
	
	canvas_visible = canvas.style.display is ""
	if canvas_visible isnt visualization_enabled
		canvas.style.display = if visualization_enabled then "" else "none"
		
		for container_el in Array.from(document.querySelectorAll(".disable-if-viz-disabled"))
			form_el_selector = "input, button, textarea, select"
			form_els = Array.from(container_el.querySelectorAll(form_el_selector))
			if container_el.matches(form_el_selector)
				form_els.push(container_el)
			for form_el in form_els
				form_el.disabled = not visualization_enabled
			container_el.classList[if visualization_enabled then "remove" else "add"]("disabled")
	
	return unless visualization_enabled
	
	filter = "hue-rotate(#{hue_rotate_degrees}deg)"
	if canvas.style.filter isnt filter
		canvas.style.filter = filter

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

	for sustain_period in global_sustain_periods
		start_y = (sustain_period.start_time - now) / 1000 * px_per_second
		end_y = ((sustain_period.end_time ? now) - now) / 1000 * px_per_second
		ctx.fillStyle = "rgba(128, 128, 128, 0.3)"
		ctx.fillRect(0, start_y, pitch_axis_canvas_length, end_y - start_y)

	for instrument_select in global_instrument_selects
		y = (instrument_select.time - now) / 1000 * px_per_second
		instrument_name = JZZ.MIDI.programName(instrument_select.value, instrument_select.bank_msb, instrument_select.bank_lsb)
			.replace(/\s*\*$/, "") # I'm not sure why it has an asterisk at the end
			.replace(/:$/, "") # I'm also not sure why some names have a colon at the end
		text = "#{instrument_select.value}. #{instrument_name}"

		# bar line
		bar_thickness = 2
		ctx.fillStyle = "rgba(128, 128, 128, 0.6)"
		ctx.fillRect(0, y, pitch_axis_canvas_length, bar_thickness)

		# text metrics
		font_size = 16
		ctx.font = "#{font_size}px sans-serif"
		ctx.textBaseline = "top"
		text_width = ctx.measureText(text).width * 2
		text_background_y = y + bar_thickness
		text_y = y + 5

		# text background rectangle
		ctx.fillStyle = "rgba(0, 0, 0, 1)"
		ctx.fillRect(0, y + bar_thickness, text_width, font_size + (text_y - text_background_y))
		
		# text
		ctx.fillStyle = "rgba(128, 128, 128, 1)"
		ctx.fillText(text, 5, text_y)

	for note in notes
		{x, w, is_accidental} = get_note_location_canvas_space(note.key, pitch_axis_canvas_length)
		ctx.globalAlpha = note.velocity / 127
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
		smooth = yes
		if smooth
			ctx.beginPath()
			points = []
			# data_points = []
			for pitch_bend, i in note.pitch_bends
				next_pitch_bend = note.pitch_bends[i + 1]
				segment_end_time = next_pitch_bend?.time ? note.end_time ? now
				y1 = (pitch_bend.time - now) / 1000 * px_per_second
				y2 = (segment_end_time - now) / 1000 * px_per_second
				h = y2 - y1 + 0.5
				bent_x = x + pitch_bend.value * 2 * midi_to_canvas_scalar
				segment_end_bent_x = x + (next_pitch_bend ? pitch_bend).value * 2 * midi_to_canvas_scalar
				points.push({x: bent_x, y: y1})
				# data_points.push({x: bent_x, y: y1})

				if y2 - y1 > 10
					points.push({x: bent_x, y: y2 - 5})
				if i is note.pitch_bends.length - 1
					points.push({x: bent_x, y: y2})
			for point in points
				ctx.lineTo(point.x, point.y)
			for point in points by -1
				ctx.lineTo(point.x + w, point.y)

			ctx.closePath()
			ctx.fill()
			ctx.globalAlpha = 0.5
			ctx.strokeStyle = ctx.fillStyle
			ctx.stroke()

			# debug
			# ctx.globalAlpha = 1
			# ctx.fillStyle = "red"
			# for point in points
			# 	ctx.fillRect(point.x, point.y, 2, 2)
			# ctx.fillStyle = "lime"
			# for point in data_points
			# 	ctx.fillRect(point.x, point.y, 2, 2)
		else
			for pitch_bend, i in note.pitch_bends
				next_pitch_bend = note.pitch_bends[i + 1]
				segment_end_time = next_pitch_bend?.time ? note.end_time ? now
				y1 = (pitch_bend.time - now) / 1000 * px_per_second
				y2 = (segment_end_time - now) / 1000 * px_per_second
				h = y2 - y1 + 0.5
				bent_x = x + pitch_bend.value * 2 * midi_to_canvas_scalar
				ctx.fillRect(bent_x, y1, w, h)
	ctx.globalAlpha = 1
	if is_learning_range
		for extremity_midi_val, i in learning_range
			if extremity_midi_val?
				{x, w} = get_note_location_canvas_space(extremity_midi_val, pitch_axis_canvas_length)
				ctx.fillStyle = "red"
				ctx.fillRect(x, 0, w, time_axis_canvas_length)
	ctx.restore()

##############################
# MIDI File Export
##############################

export_midi_file_button.onclick = ->
	export_midi_file("saved")

export_midi_file = (delete_later_reason, file_name)->
	midi_file = new MIDIFile()

	if notes.length is 0
		if delete_later_reason is "recovered"
			# setTimeout to avoid current recording's notes gone while alert is shown
			setTimeout -> alert "No notes in recording!"
		else
			alert "No notes have been recorded!"
		try localStorage["to_delete:#{active_recording_session_id}"] = "no_notes #{new Date().toISOString()}"
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
		if note.end_time?
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

	for instrument_select in global_instrument_selects
		events.push({
			# delta: <computed later>
			_time: instrument_select.time
			type: MIDIEvents.EVENT_MIDI
			subtype: MIDIEvents.EVENT_MIDI_PROGRAM_CHANGE
			channel: 0
			param1: instrument_select.value
		})

	for bank_msb_select in global_bank_msb_selects
		events.push({
			# delta: <computed later>
			_time: bank_msb_select.time
			type: MIDIEvents.EVENT_MIDI
			subtype: 0, # Bank Select Coarse (MSB) (Most Significant Byte)
			channel: 0
			param1: bank_msb_select.value
		})
	
	for bank_lsb_select in global_bank_lsb_selects
		events.push({
			# delta: <computed later>
			_time: bank_lsb_select.time
			type: MIDIEvents.EVENT_MIDI
			subtype: 32, # Bank Select Fine (LSB) (Least Significant Byte)
			channel: 0
			param1: bank_lsb_select.value
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

	events = events.filter((event)-> isFinite(event._time))
	events.sort((a, b)-> a._time - b._time)
	total_track_time_ms = events[events.length - 1]._time - events[0]._time
	total_track_time_ms += 1000 # extra time for notes to ring out
	BPM = 120 # beats per minute
	PPQN = 192 # pulses per quarter note
	pulses_per_ms = PPQN * BPM / 60000
	total_track_time_seconds = total_track_time_ms / 1000
	last_time = null
	for event in events
		unless event.delta?
			if last_time?
				event.delta = (event._time - last_time) * pulses_per_ms
			else
				event.delta = 0
			last_time = event._time if isFinite(event._time)
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
			tempo: 60000000 / BPM
		}
#		{
#			delta: 0
#			type: MIDIEvents.EVENT_META
#			subtype: MIDIEvents.EVENT_META_TRACK_NAME
#			length: 0 # TODO: name "Tempo track" / "Meta track" / "Conductor track"
#		}
		{
			delta: ~~(total_track_time_ms * pulses_per_ms)
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
	
	unless file_name
		# Colons are optional in ISO 8601 format, and invalid in Windows filenames.
		# Sub-second precision is optional and unnecessary.
		iso_date_string = new Date(last_note_datetime).toISOString().replace(/:/g, "").replace(/\..*Z/, "Z")
		# Sanitize filename in a fun way
		# We don't need to worry about Windows reserved filenames, dot or space at end of filename, length, etc.
		# because the browser should take care of that,
		# but the browser will sanitize reserved characters in a bland way,
		# such as replacing with underscores.
		# I want to preserve the intention as much as possible, of the entered name.
		recording_name = recording_name_input.value
		recording_name = recording_name.replace(/\//g, "⧸")
		recording_name = recording_name.replace(/\\/g, "⧹")
		recording_name = recording_name.replace(/</g, "ᐸ")
		recording_name = recording_name.replace(/>/g, "ᐳ")
		recording_name = recording_name.replace(/:/g, "꞉")
		recording_name = recording_name.replace(/\|/g, "∣")
		recording_name = recording_name.replace(/\?/g, "？")
		recording_name = recording_name.replace(/\*/g, "∗")
		recording_name = recording_name.replace(/(^|[-—\s(\["])'/g, "$1\u2018")  # opening singles
		recording_name = recording_name.replace(/'/g, "\u2019")                  # closing singles & apostrophes
		recording_name = recording_name.replace(/(^|[-—/\[(‘\s])"/g, "$1\u201c") # opening doubles
		recording_name = recording_name.replace(/"/g, "\u201d")                  # closing doubles
		recording_name = recording_name.replace(/--/g, "\u2014")                 # em-dashes
		recording_name = recording_name.replace(/\.\.\./g, "…")                  # ellipses
		recording_name = recording_name.replace(/~/g, "\u301C")                  # Chrome at least doesn't like tildes
		recording_name = recording_name.trim()

		file_name = "#{iso_date_string}#{if recording_name.length then " - #{recording_name}" else ""}.midi"

	saveAs(blob, file_name)

	# TODO: timeout?? I wish there was a way to tell if and when the file was actually saved!
	# probably a multi-tier recovery system is needed, where possibly-saved/recovered recordings are hidden, but still recoverable, for some number of days
	try localStorage["to_delete:#{active_recording_session_id}"] = "#{delete_later_reason} #{new Date().toISOString()}"

##############################
# User Interface
##############################

fullscreen_button.onclick = ->
	if fullscreen_target_el.requestFullscreen
		fullscreen_target_el.requestFullscreen()
	else if fullscreen_target_el.mozRequestFullScreen
		fullscreen_target_el.mozRequestFullScreen()
	else if fullscreen_target_el.webkitRequestFullScreen
		fullscreen_target_el.webkitRequestFullScreen()


arrow_size = 10
troubleshoot_midi_input_popover.style.setProperty("--arrow-size", "#{arrow_size}px")
troubleshooting_popper = Popper.createPopper(troubleshoot_midi_input_button, troubleshoot_midi_input_popover,
	modifiers: [
		{
			name: 'offset'
			options: {
				offset: [0, arrow_size + 5]
			}
		}
	]
)

troubleshoot_midi_input_button.onclick = ->
	if troubleshoot_midi_input_button.getAttribute("aria-expanded") is "false"
		troubleshoot_midi_input_button.setAttribute("aria-expanded", "true")
		troubleshoot_midi_input_popover.hidden = false
		troubleshooting_popper.update()
	else
		troubleshoot_midi_input_button.setAttribute("aria-expanded", "false")
		troubleshoot_midi_input_popover.hidden = true

# close the popover when the user clicks outside of it
window.addEventListener "click", (event)->
	if troubleshoot_midi_input_button.getAttribute("aria-expanded") is "true" and not (
		troubleshoot_midi_input_button.contains(event.target) or
		troubleshoot_midi_input_popover.contains(event.target)
	)
		event.preventDefault() # won't prevent much, would need an overlay to prevent clicks from going through
		troubleshoot_midi_input_button.setAttribute("aria-expanded", "false")
		troubleshoot_midi_input_popover.hidden = true

# close popover when user presses escape
window.addEventListener "keydown", ->
	if event.key is "Escape" and troubleshoot_midi_input_button.getAttribute("aria-expanded") is "true"
		troubleshoot_midi_input_button.setAttribute("aria-expanded", "false")
		troubleshoot_midi_input_popover.hidden = true


end_learn_range = ->
	# in case of apply button, selected_range is already set to learning_range
	# in case of cancel button, selected_range is not set to learning_range so this does a reset

	cancel_learn_range_button_was_focused = cancel_learn_range_button is document.activeElement
	is_learning_range = false
	cancel_learn_range_button.hidden = true
	apply_text_el.hidden = true
	learn_range_text_el.hidden = false
	learning_range = [null, null]
	midi_range_left_input.disabled = not visualization_enabled
	midi_range_right_input.disabled = not visualization_enabled
	[midi_range_left_input.value, midi_range_right_input.value] = selected_range
	if cancel_learn_range_button_was_focused
		learn_range_or_apply_button.focus()

learn_range_or_apply_button.onclick = ->
	if is_learning_range
		# order matters here: set_selected_range uses is_learning_range,
		# end_learn_range uses selected_range
		is_learning_range = false
		set_selected_range(learning_range)
		end_learn_range()
		save_options_soon({update_even_focused_inputs: true})
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

# supposedly keydown doesn't work consistently in all browsers
document.body.addEventListener "keydown", (event)->
	if event.key is "Escape"
		end_learn_range()
	if (event.key is "s" or event.key is "S") and (event.ctrlKey or event.metaKey)
		export_midi_file("saved")
		event.preventDefault()
document.body.addEventListener "keyup", (event)->
	if event.key is "Escape"
		end_learn_range()

##############################
# Device Discovery Helper
##############################

midi_discovery_iframe = document.createElement("iframe")
midi_discovery_iframe.style.position = "absolute"
midi_discovery_iframe.style.top = "-100%"
midi_discovery_iframe.style.left = "-100%"
midi_discovery_iframe.style.opacity = 0
midi_discovery_iframe.style.pointerEvents = "none"
midi_discovery_iframe.tabIndex = -1
midi_discovery_iframe.setAttribute("aria-hidden", "true")
midi_discovery_iframe.title = "This iframe is for discovering MIDI devices, to work around devices not connecting, or not showing up, until the page is refreshed."
document.body.appendChild(midi_discovery_iframe)
midi_discovery_iframe.addEventListener "load", ->
	try
		iframe_window = midi_discovery_iframe.contentWindow
		setTimeout ->
			iframe_window.location.reload()
		, 5000
		on_success = (midi)->
			midi_inputs = [...new Map(midi.inputs).values()]
			# console.log 'From MIDI discovery iframe, inputs: ', midi_inputs

			handle_midi_input = (midi_input)->
				if midi_input.state is "connected"
					# give some time for the app to connect to the midi device
					setTimeout ->
						if not connected_port_ids.has(midi_input.id)
							# don't reload if notes have been recorded
							# TODO: now that notes are saved to IndexedDB, maybe reload
							# as long as you're not actively playing?
							if not notes.length
								location.reload() # reload the whole app so it'll get the new MIDI device
					, 500

			midi_inputs.forEach(handle_midi_input)

			midi.onstatechange = (e)->
				if e.port.type is "input"
					handle_midi_input(e.port)

		on_error = (error)->
			console.log "requestMIDIAccess for MIDI discovery iframe failed:", error

		if iframe_window.navigator.requestMIDIAccess
			iframe_window.navigator.requestMIDIAccess().then on_success, on_error
		# else
			# a message should already be shown

	catch error
		console.log "Failed to access iframe for MIDI discovery"
