smi = new SimpleMidiInput()

onsuccesscallback = (midi)->
	smi.attach(midi)
	console.log 'smi: ', smi

onerrorcallback = (err)->
	console.log 'ERROR: ', err

navigator.requestMIDIAccess().then onsuccesscallback, onerrorcallback

notes = []
current_notes = new Map

smi.on 'noteOn', (data)->
	{event, key, velocity} = data
	old_note = current_notes.get(key)
	# current_notes.delete(key)
	start_time = performance.now()
	if old_note
		# console.log("double noteOn?")
		# note = old_note
		return
	note = {key, velocity, start_time}
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
	ctx.fillRect(0, 0, canvas.width, 1)
	for note in notes
		w = canvas.width / 128
		x = note.key * w
		# console.log note.length
		y = (note.start_time - now) / 1000 * px_per_second
		# h = (note.length ? 500000) / 1000 * px_per_second
		# ctx.fillStyle = if note.length then "yellow" else "blue"
		# ctx.fillRect(x, y, w, h)
		unless note.length?
			ctx.fillStyle = "#800"
			ctx.fillRect(x, y, w, 50000)
		h = (note.length ? now - note.start_time) / 1000 * px_per_second
		ctx.fillStyle = if note.length then "yellow" else "lime"
		ctx.fillRect(x, y, w, h)
		# ctx.fillRect(x, 50, w, 50)
	ctx.restore()
