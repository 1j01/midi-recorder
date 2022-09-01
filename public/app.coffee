
for el in document.querySelectorAll("noscript")
	el.remove() # for screenreaders

fullscreen_target_el = document.getElementById("fullscreen-target")
canvas = document.getElementById("midi-viz-canvas")
export_midi_file_button = document.getElementById("export-midi-file-button")
file_input = document.getElementById("file-input")
textarea = document.getElementById("textarea")
# format_select = document.getElementById("format-select")
lowest_note_input = document.getElementById("lowest-note-input")
# bpm_input = document.getElementById("bpm-input")
# arpeggiation_input = document.getElementById("arpeggiation-input")
song_name_input = document.getElementById("song-name-input")
clear_button = document.getElementById("clear-button")
undo_clear_button = document.getElementById("undo-clear-button")
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

debounce = (func, timeout = 300)->
	tid = null
	return (...args)->
		clearTimeout(tid)
		tid = setTimeout((-> func(...args)), timeout)

last_note_datetime = Date.now()

# options are initialized from the URL & HTML later

# format = "auto"
lowest_note = 100
# bpm = 120
# arpeggiation = 0

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
		# "format": format
		"lowest-note": lowest_note
		# "bpm": bpm
		# "arpeggiation": arpeggiation
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

	# if data["format"]
	# 	format = data["format"].toLowerCase()
	# 	format_select.value = format
	if data["lowest-note"]
		lowest_note = parseFloat(data["lowest-note"])
		if update_even_focused_inputs or document.activeElement isnt lowest_note_input
			lowest_note_input.value = lowest_note
	# if data["bpm"]
	# 	bpm = parseFloat(data["bpm"])
	# 	if update_even_focused_inputs or document.activeElement isnt bpm_input
	# 		bpm_input.value = bpm
	# if data["arpeggiation"]
	# 	arpeggiation = parseFloat(data["arpeggiation"])
	# 	if update_even_focused_inputs or document.activeElement isnt arpeggiation_input
	# 		arpeggiation_input.value = arpeggiation
	
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
	# format = format_select.value
	lowest_note = parseFloat(lowest_note_input.value)
	lowest_note = 100 if isNaN(lowest_note)
	# bpm = parseFloat(bpm_input.value) || 120
	# arpeggiation = parseFloat(arpeggiation_input.value)
	# arpeggiation = 100 if isNaN(arpeggiation)

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
	ascii_to_midi(textarea.value)

for control_element in [
	# format_select

	visualization_enabled_checkbox
	note_gravity_direction_select
	theme_select
	layout_radio_buttons...
]
	control_element.onchange = update_options_from_inputs
for input_element in [
	lowest_note_input
	# bpm_input
	# arpeggiation_input

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

addEventListener "hashchange", ->
	load_options({update_even_focused_inputs: not hashchange_is_new_history_entry})
	hashchange_is_new_history_entry = false

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
		song_name: song_name_input.value
		last_note_datetime
		active_chunk_n
		active_chunk_events
	}))
	state.current_notes = new Map(current_notes)
	state

restore_state = (state)->
	# Need to clone when restoring as well (not set by reference),
	# so that if you restore initial_state it's not going to then mutate initial_state.
	# This way it should work if you clear a second time (modify, clear, modify, clear.)

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
		active_chunk_n
		active_chunk_events
	} = JSON.parse(JSON.stringify(state))
	current_notes = new Map(state.current_notes)
	song_name_input.value = state.song_name

initial_state = save_state()
undo_state = save_state()

clear_notes = ->
	undo_state = save_state()
	restore_state(initial_state)

	export_midi_file_button.disabled = true
	clear_button.hidden = true
	undo_clear_button.hidden = false
	undo_clear_button.focus()

	active_chunk_n = 1

undo_clear_notes = ->
	restore_state(undo_state)
	export_midi_file_button.disabled = notes.length is 0
	clear_button.disabled = false
	clear_button.hidden = false
	undo_clear_button.hidden = true
	clear_button.focus()

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
# ASCII To MIDI (Parsing)
##############################

parse_grid_notes = (text)->

	lines = text.split(/\r?\n/g)
	# TODO: use grapheme splitter
	# TODO: option to interpret horizontally vs vertically
	grid = (line.split("") for line in lines)
	grid.push([]) # so notes will all end
	# Pad the grid to even width (column count)
	column_count = 0
	for	row in grid
		if row.length > column_count
			column_count = row.length
	for	row in grid
		while row.length < column_count
			row.push(" ")

	for row, row_index in grid
		for char, column_index in row
			note_here = Boolean char.trim()
			key = column_index + lowest_note
			t = row_index * 400
			old_note = current_notes.get(key)

			if old_note and not note_here
				old_note.end_time = t
				old_note.length = old_note.end_time - old_note.start_time
				current_notes.delete(key)
			else if note_here and not old_note
				note = {key, velocity: 127, start_time: t, pitch_bends: [{
					time: t,
					value: current_pitch_bend_value,
				}]}
				current_notes.set(key, note)
				notes.push(note)


ascii_to_midi = (text)->

	restore_state(initial_state)

	try
		ringtone = RTTTL.parse(text)
	catch error
		# TODO: handle unexpected errors vs format errors (should change parser to throw special errors)
		console.log "Parsing as RTTTL failed:", error

	if ringtone
		# TODO: pull out BPM, song name information
		console.log ringtone
		t = 0
		for note in ringtone.notes
			if not note.rest
				notes.push({
					key: note.midiPitch
					velocity: 127
					start_time: t
					end_time: t + note.seconds * 1000
					length: note.seconds * 1000
					pitch_bends: [{
						time: t,
						value: 0,
					}]
				})
			t += note.seconds * 1000
	else
		parse_grid_notes(text) # mutates `notes` (and `current_notes`, which should be empty before and after hopefully)
	

	song_name_input.hidden = false
	export_midi_file_button.disabled = false
	enable_clearing()


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

	# now = performance.now()
	now = notes[notes.length - 1]?.end_time ? performance.now()

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
		if instrument_select.bank_msb or instrument_select.bank_lsb
			# Bank Select LSB is rarely used in practice, so don't show it unless it's set
			if instrument_select.bank_lsb
				text = "#{instrument_select.bank_lsb}:#{text}"
			text = "#{instrument_select.bank_msb or 0}:#{text}"

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
	export_midi_file()

export_midi_file = ->
	midi_file = new MIDIFile()

	if notes.length is 0
		alert "No notes to output!"
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
		song_name = song_name_input.value
		song_name = song_name.replace(/\//g, "⧸")
		song_name = song_name.replace(/\\/g, "⧹")
		song_name = song_name.replace(/</g, "ᐸ")
		song_name = song_name.replace(/>/g, "ᐳ")
		song_name = song_name.replace(/:/g, "꞉")
		song_name = song_name.replace(/\|/g, "∣")
		song_name = song_name.replace(/\?/g, "？")
		song_name = song_name.replace(/\*/g, "∗")
		song_name = song_name.replace(/(^|[-—\s(\["])'/g, "$1\u2018")  # opening singles
		song_name = song_name.replace(/'/g, "\u2019")                  # closing singles & apostrophes
		song_name = song_name.replace(/(^|[-—/\[(‘\s])"/g, "$1\u201c") # opening doubles
		song_name = song_name.replace(/"/g, "\u201d")                  # closing doubles
		song_name = song_name.replace(/--/g, "\u2014")                 # em-dashes
		song_name = song_name.replace(/\.\.\./g, "…")                  # ellipses
		song_name = song_name.replace(/~/g, "\u301C")                  # Chrome at least doesn't like tildes
		song_name = song_name.trim()

		file_name = "#{iso_date_string}#{if song_name.length then " - #{song_name}" else ""}.midi"

	saveAs(blob, file_name)

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
		export_midi_file()
		event.preventDefault()
document.body.addEventListener "keyup", (event)->
	if event.key is "Escape"
		end_learn_range()

file_input.onchange = ->
	textarea.value = await file_input.files[0].text()
	ascii_to_midi(textarea.value)

textarea.oninput = ->
	ascii_to_midi(textarea.value)

##############################
# Initialize options
##############################

load_options({update_even_focused_inputs: true})
update_options_from_inputs()
