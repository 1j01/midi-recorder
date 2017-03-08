smi = new SimpleMidiInput()

onsuccesscallback = (midi)->
	smi.attach(midi)
	console.log 'smi: ', smi

onerrorcallback = (err)->
	console.log 'ERROR: ', err

navigator.requestMIDIAccess().then onsuccesscallback, onerrorcallback

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
