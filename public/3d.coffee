element_to_transform = document.getElementById('element-to-transform')
svg_root = document.getElementById('perspective-registration-svg')
polygon = document.getElementById('perspective-registration-polygon')
video = document.getElementById('video')
setup_3d_button = document.getElementById("setup-3d-button")
enable_camera_checkbox = document.getElementById("enable-camera")

setup_3d_button.onclick = ->
	

transform_2d = do ->
	# from https://jsfiddle.net/dFrHS/549
	adj = (m)-> # Compute the adjugate of m
		return [
			m[4]*m[8]-m[5]*m[7], m[2]*m[7]-m[1]*m[8], m[1]*m[5]-m[2]*m[4]
			m[5]*m[6]-m[3]*m[8], m[0]*m[8]-m[2]*m[6], m[2]*m[3]-m[0]*m[5]
			m[3]*m[7]-m[4]*m[6], m[1]*m[6]-m[0]*m[7], m[0]*m[4]-m[1]*m[3]
		]
	multmm = (a, b)-> # multiply two matrices
		c = Array(9)
		for i in [0...3]
			for j in [0...3]
				cij = 0
				for k in [0...3]
					cij += a[3*i + k]*b[3*k + j]
				c[3*i + j] = cij
		return c
	multmv = (m, v)-> # multiply matrix and vector
		return [
			m[0]*v[0] + m[1]*v[1] + m[2]*v[2]
			m[3]*v[0] + m[4]*v[1] + m[5]*v[2]
			m[6]*v[0] + m[7]*v[1] + m[8]*v[2]
		]
	pdbg = (m, v)->
		r = multmv(m, v)
		return "#{r} (#{r[0]/r[2]}, #{r[1]/r[2]})"
	basis_to_points = (x1, y1, x2, y2, x3, y3, x4, y4)->
		m = [
			x1, x2, x3
			y1, y2, y3
			1 , 1 , 1
		]
		v = multmv(adj(m), [x4, y4, 1])
		return multmm(m, [
			v[0], 0, 0
			0, v[1], 0
			0, 0, v[2]
		])
	general_2d_projection = (
		x1s, y1s, x1d, y1d
		x2s, y2s, x2d, y2d
		x3s, y3s, x3d, y3d
		x4s, y4s, x4d, y4d
	)->
		s = basis_to_points(x1s, y1s, x2s, y2s, x3s, y3s, x4s, y4s)
		d = basis_to_points(x1d, y1d, x2d, y2d, x3d, y3d, x4d, y4d)
		return multmm(d, adj(s))
	project = (m, x, y)->
		v = multmv(m, [x, y, 1])
		return [v[0]/v[2], v[1]/v[2]]
	transform_2d = (el, x1, y1, x2, y2, x3, y3, x4, y4)->
		w = el.offsetWidth
		h = el.offsetHeight
		t = general_2d_projection(0, 0, x1, y1, w, 0, x2, y2, 0, h, x3, y3, w, h, x4, y4)
		for i in [0...9]
			t[i] = t[i]/t[8]
		t = [
			t[0], t[3], 0, t[6]
			t[1], t[4], 0, t[7]
			0   , 0   , 1, 0   
			t[2], t[5], 0, t[8]
		]
		t = "matrix3d(#{t.join(", ")})"
		el.style.transform = t
		return t
	return transform_2d

init_polygon_ui = (on_points_change)->
	sns = "http://www.w3.org/2000/svg"
	xns = "http://www.w3.org/1999/xlink"
	root_matrix = null
	original_points = []
	transformed_points = []
	point_handles = []

	for i in [0...polygon.points.numberOfItems]
		handle = document.createElementNS(sns, 'use')
		point = polygon.points.getItem(i)
		newPoint = svg_root.createSVGPoint()

		handle.setAttributeNS(xns, 'href', '#point-handle')
		handle.setAttribute('class', 'point-handle')

		handle.x.baseVal.value = newPoint.x = point.x
		handle.y.baseVal.value = newPoint.y = point.y

		handle.setAttribute('data-index', i)

		original_points.push(newPoint)

		svg_root.appendChild(handle)

		point_handles.push(handle)

	apply_transforms = (event)->
		root_matrix = svg_root.getScreenCTM()

		transformed_points = original_points.map((point)->
			return point.matrixTransform(root_matrix)
		)

		interact('.point-handle', { context: document }).draggable()

	interact(svg_root, { context: document }).on('down', apply_transforms)

	interact('.point-handle', { context: document })
		.draggable(
			onstart: (event)->
				svg_root.setAttribute('class', 'dragging')
			onmove: (event)->
				i = event.target.getAttribute('data-index')|0
				point = polygon.points.getItem(i)

				point.x += event.dx / root_matrix.a
				point.y += event.dy / root_matrix.d

				event.target.x.baseVal.value = point.x
				event.target.y.baseVal.value = point.y

				on_points_change()
			onend: (event)->
				svg_root.setAttribute('class', '')
			restrict: { restriction: document.rootElement }
		)
		#.styleCursor(off)


	document.addEventListener('dragstart', (event)->
		event.preventDefault()
	)
	
	get_points = ->
		return point_handles.map((pointHandle)->
			x: pointHandle.x.baseVal.value
			y: pointHandle.y.baseVal.value
		)
	
	return get_points

updateTransform = ->
	pts = get_points()
	t = transform_2d(
		element_to_transform
		pts[0].x, pts[0].y
		pts[3].x, pts[3].y
		pts[1].x, pts[1].y
		pts[2].x, pts[2].y
	)

get_points = init_polygon_ui(updateTransform)
updateTransform()

init_video = ->
	# Prefer camera resolution nearest to 1280x720.
	constraints = { audio: false, video: { width: 1280, height: 720 } } 

	navigator.mediaDevices.getUserMedia(constraints)
	.then((mediaStream)->
		video = document.querySelector('video')
		video.srcObject = mediaStream
		video.onloadedmetadata = (e)->
			video.play()
	)
	.catch((err)->
		console.log(err.name + ": " + err.message)
		if err.name is "NotReadableError"
			alert("Can't access camera - it may be in use. If you're using it in OBS, go into the source's Properties and say Deactivate.")
	)

	### let videoPlaying = false, videoGotTimeupdate = false
	video.addEventListener('playing', ->
		videoPlaying = true
	, true)

	video.addEventListener('timeupdate', ->
		videoGotTimeupdate = true
	, true) ###

init_video()
