
do ->
	
	RTTTL = {}
	
	pitches = "c, c#, d, d#, e, f, f#, g, g#, a, a#, b".split ", "
	
	RTTTL.parse = (str)->
		
		ringtone =
			name: ""
			controls:
				defaultNoteScale: 6
				defaultNoteDuration: 1/4
				beatsPerMinute: 63
			notes: []
			warnings: []
		
		warn = (message)-> ringtone.warnings.push message
		error = (message)-> e = new Error message; e.sourceRTTTL = str; throw e
		
		sections = str.split ":"
		
		if sections.length isnt 3
			error "expected 3 sections but got #{sections.length}"
		
		nameSection = sections[0]
		controlSection = sections[1].toLowerCase().replace /\s/g, ""
		dataSection = sections[2].toLowerCase().replace /\s/g, ""
		
		
		# I should probably make the sections of code for parsing the sections into functions
		# and the code for parsing control statements, probably, and allow control statements in the main data section
		
		
		# parse name section
		ringtone.name = nameSection.trim()
		
		# parse control section
		for assignment in controlSection.split ","
			[opt, val] = assignment.split "="
			value = parseInt val
			switch opt
				when "o"
					ringtone.controls.defaultNoteScale = value
					unless value in [4, 5, 6, 7]
						warn "Not-very-valid default note scale in control section: #{value}"
				when "d"
					ringtone.controls.defaultNoteDuration = 1/value
					unless value in [1, 2, 4, 8, 16, 32]
						warn "Not-very-valid default note duration in control section: #{value}"
				when "b"
					ringtone.controls.beatsPerMinute = value
					unless 10 <= value <= 500
						warn "Absurd beats per minute in control section: #{value}"
				# @TODO: retain unknown control options
				# I mean, technically the spec says to "ignore" them, but...
		
		# parse data section
		ringtone.notes = []
		# <note> := [<duration>] <note> [<scale>] [<special-duration>]
		for noteString in dataSection.split /[,;]/ # <delimiter> should be a comma
			do (noteString)->
				
				dots = (noteString.match /\./g) ? [] # [<special-duration>]
				
				match = noteString.replace(/\./g, "").match ///^
					(1 | 2 | 4 | 8 | 16 | 32)? # [<duration>]
					(P | C | C\# | D | D\# | E | F | F\# | G | G\# | A | A\# | B) # <note-name>
					(4 | 5 | 6 | 7)? # [<scale>]
				$///i
				
				if not match
					
					match = noteString.replace(/\./g, "").match ///^
						(\d+)? # lenient [<duration>]
						(P | C | C\# | D | D\# | E | F | F\# | G | G\# | A | A\# | B) # <note-name>
						(\d)? # lenient [<scale>]
					$///i
					
					if match
						warn "Not-very-valid note octave or duration: #{noteString}"
					else
						error "Invalid note: #{noteString}"
				
				if match
					[m, duration, name, scale] = match
					
					original = {
						string: noteString
						dots: ("." for dot in dots).join ""
						duration
						scale
					}
					
					rest = name is "p"
					
					if duration?
						duration = 1 / parseInt duration
					else
						duration = ringtone.controls.defaultNoteDuration
					
					if scale?
						scale = parseInt scale
					else
						scale = ringtone.controls.defaultNoteScale
					
					duration *= 1.5 for dot in dots
					
					seconds = (duration * 4) * (60 / ringtone.controls.beatsPerMinute)
					#seconds = (duration / ringtone.controls.defaultNoteDuration) * (60 / ringtone.controls.beatsPerMinute)
					
					unless rest
						pitchNumber = (scale - 4) * 12 + pitches.indexOf(name)
						frequency = 440 * 2 ** (pitchNumber / 12)
					
					ringtone.notes.push {
						name
						scale
						duration
						rest
						
						seconds
						midiPitch: pitchNumber + 69
						frequency
						
						original
						toString: ->
							(original.duration ? "") +
							name +
							(original.scale ? "") +
							original.dots
					}
		
		# provide ways of getting RTTTL back
		
		ringtone.original = str
		
		ringtone.notes.toString = -> (
				note.toString() for note in ringtone.notes
			).join ","
		
		ringtone.controls.toString = -> (
				for option, value of ringtone.controls
					switch option
						when "defaultNoteScale" then opt = "o"; val = value
						when "defaultNoteDuration" then opt = "d"; val = 1/value
						when "beatsPerMinute" then opt = "b"; val = value
					"#{opt}=#{val}"
			).join ","
		
		ringtone.toString = -> "#{ringtone.name}:#{ringtone.controls}:#{ringtone.notes}"
		
		
		return ringtone
	
	
	
	if module?.exports
		module.exports = RTTTL
	else
		window.RTTTL = RTTTL
	
	
	
	#ringtone = RTTTL.parse "Never Go:d=4,o=6,b=125:g#5, a#5, c#5, a#5, 8f.5, 8f.5, d#.5, g#5, a#5, c#5, a#5, 8d#.5, 8d#.5, 8c#.5, c5, 8a#5, g#5, a#5, c#5, a#5, c#5, 8d#5, 8c.5, a#5, g#5, 8g#5, 8d#5, 8c#5, 2c#5, g#5, a#5, c#5, a#5, f5, 8f5, d#.5, g#5, a#5, c#5, a#5, g#5, 8c#5, 8c#.5, c5, 8a#5, g#5, a#5, c#5, a#5, c#5, 8d#5, 8c.5, a#5, g#5, 8g#5, d#5, c#5"
	#console.log ringtone
	
	#ringtone = RTTTL.parse "Indiana Jones:d=4,o=5,b=250:e,8p,8f,8g,8p,1c6,8p.,d,8p,8e,1f,p.,g,8p,8a,8b,8p,1f6,p,a,8p,8b,2c6,2d6,2e6,e,8p,8f,8g,8p,1c6,p,d6,8p,8e6,1f.6,g,8p,8g,e.6,8p,d6,8p,8g,e.6,8p,d6,8p,8g,f.6,8p,e6,8p,8d6,2c6"
	#console.log ringtone


